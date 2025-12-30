//
//  OnboardingStoreV2.swift
//  I Do Blueprint
//
//  State management for onboarding flow
//

import Foundation
import SwiftUI
import Combine
import Dependencies
import Supabase

/// Store managing onboarding flow state and operations
@MainActor
class OnboardingStoreV2: ObservableObject {

    // MARK: - Dependencies

    @Dependency(\.onboardingRepository) var repository
    @Dependency(\.collaborationRepository) var collaborationRepository
    private let logger = AppLogger.ui
    
    // MARK: - Services
    
    private lazy var progressService: OnboardingProgressService = {
        OnboardingProgressService(repository: repository)
    }()
    
    private let settingsService = OnboardingSettingsService()
    
    private lazy var collaboratorService: OnboardingCollaboratorService = {
        OnboardingCollaboratorService(collaborationRepository: collaborationRepository)
    }()

    // MARK: - Published State

    @Published private(set) var loadingState: LoadingState<OnboardingProgress> = .idle
    @Published private(set) var currentStep: OnboardingStep = .welcome
    @Published private(set) var completedSteps: Set<OnboardingStep> = []
    @Published private(set) var isCompleted: Bool = false
    @Published private(set) var error: OnboardingError?

    // Step-specific state
    @Published var weddingDetails: WeddingDetails = WeddingDetails()
    @Published var defaultSettings: OnboardingDefaultSettings = OnboardingDefaultSettings()
    @Published var selectedMode: OnboardingMode = .guided

    // MARK: - Computed Properties

    var isLoading: Bool {
        loadingState.isLoading
    }

    var progress: OnboardingProgress? {
        loadingState.data
    }

    var progressPercentage: Double {
        OnboardingNavigationService.calculateProgress(
            completedSteps: completedSteps,
            mode: selectedMode
        )
    }

    var canMoveToNextStep: Bool {
        guard OnboardingNavigationService.getNextStep(currentStep: currentStep, mode: selectedMode) != nil else {
            return false
        }
        return validateCurrentStep()
    }

    var canMoveToPreviousStep: Bool {
        OnboardingNavigationService.getPreviousStep(currentStep: currentStep) != nil
    }

    // MARK: - Initialization

    init() {
        logger.info("OnboardingStoreV2 initialized")
    }

    // MARK: - Load Progress

    /// Loads existing onboarding progress or creates new progress
    func loadProgress() async {
        logger.info("Loading onboarding progress")
        loadingState = .loading
        error = nil

        do {
            if let existingProgress = try await progressService.loadProgress() {
                // Restore state from progress
                currentStep = existingProgress.currentStep
                completedSteps = existingProgress.completedSteps
                isCompleted = existingProgress.isCompleted

                if let details = existingProgress.weddingDetails {
                    weddingDetails = details
                }

                if let settings = existingProgress.defaultSettings {
                    defaultSettings = settings
                }

                loadingState = .loaded(existingProgress)
            } else {
                logger.info("No existing onboarding progress found")
                loadingState = .idle
            }
        } catch {
            logger.error("Failed to load onboarding progress", error: error)
            self.error = error as? OnboardingError ?? .fetchFailed(underlying: error)
            loadingState = .error(self.error!)
        }
    }

    // MARK: - Start Onboarding

    /// Starts a new onboarding flow
    func startOnboarding(mode: OnboardingMode) async {
        logger.info("Starting onboarding with mode: \(mode.rawValue)")

        // Update UI state immediately
        selectedMode = mode
        currentStep = .welcome
        completedSteps = []
        isCompleted = false
        error = nil

        // Apply express defaults if in express mode
        if mode == .express {
            logger.info("Applying express mode defaults")
            await applyExpressDefaults()
        }

        // Create initial progress in background
        guard let coupleId = await SessionManager.shared.currentTenantId else {
            logger.error("Cannot start onboarding: no tenant context")
            error = .tenantContextMissing
            return
        }

        // Save to database in background (don't block UI)
        Task {
            do {
                let saved = try await progressService.createProgress(coupleId: coupleId, mode: mode)
                await MainActor.run {
                    loadingState = .loaded(saved)
                }
                logger.info("Onboarding started successfully")
            } catch {
                logger.error("Failed to start onboarding", error: error)
                await MainActor.run {
                    self.error = error as? OnboardingError ?? .saveFailed(underlying: error)
                }
            }
        }
    }

    // MARK: - Apply Express Defaults

    /// Applies smart defaults for express mode onboarding
    private func applyExpressDefaults() async {
        logger.info("Applying express mode smart defaults")

        // Auto-configure default settings with system locale and sensible defaults
        defaultSettings = OnboardingDefaultSettings(
            currency: Locale.current.currency?.identifier ?? "USD",
            timezone: TimeZone.current.identifier,
            themePreferences: ThemeSettings(
                colorScheme: "system",
                darkMode: false
            ),
            budgetPreferences: BudgetPreferences(
                totalBudget: nil, // User will set in budget step
                trackPayments: true,
                enableAlerts: true,
                alertThreshold: 0.9
            ),
            notificationPreferences: NotificationPreferences(
                emailEnabled: true,
                pushEnabled: true,
                taskReminders: true,
                paymentReminders: true,
                eventReminders: true
            ),
            featurePreferences: FeaturePreferences(
                tasks: TasksSettings.default,
                vendors: VendorsSettings.default,
                guests: GuestsSettings.default,
                documents: DocumentsSettings.default
            )
        )

        // Persist defaults immediately
        await updateProgress { progress in
            var updated = progress
            updated.defaultSettings = self.defaultSettings
            return updated
        }

        logger.info("Express defaults applied: currency=\(defaultSettings.currency), timezone=\(defaultSettings.timezone)")

        SentryService.shared.addBreadcrumb(
            message: "Express mode defaults applied",
            category: "onboarding",
            data: [
                "currency": defaultSettings.currency,
                "timezone": defaultSettings.timezone,
                "trackPayments": defaultSettings.budgetPreferences?.trackPayments ?? false
            ]
        )
    }

    // MARK: - Save Wedding Details

    /// Saves wedding details and updates progress
    func saveWeddingDetails(_ details: WeddingDetails) async {
        logger.info("Saving wedding details")
        logger.debug("Partner 1: '\(details.partner1Name)', Partner 2: '\(details.partner2Name)', Date: \(details.weddingDate?.description ?? "nil"), TBD: \(details.isWeddingDateTBD)")

        let validation = OnboardingValidationService.validateWeddingDetails(details)
        guard validation.isValid else {
            logger.warning("Wedding details validation failed")
            error = .validationFailed(validation.error ?? "Invalid wedding details")
            return
        }

        weddingDetails = details

        await updateProgress { progress in
            var updated = progress
            updated.weddingDetails = details
            return updated
        }

        SentryService.shared.trackAction(
            "save_wedding_details",
            category: "onboarding",
            metadata: [
                "hasDate": details.weddingDate != nil,
                "hasVenue": !details.venue.isEmpty,
                "hasStyle": details.weddingStyle != nil
            ]
        )
    }

    // MARK: - Save Default Settings

    /// Saves default settings and updates progress
    func saveDefaultSettings(_ settings: OnboardingDefaultSettings) async {
        logger.info("Saving default settings")

        defaultSettings = settings

        await updateProgress { progress in
            var updated = progress
            updated.defaultSettings = settings
            return updated
        }

        SentryService.shared.trackAction(
            "save_default_settings",
            category: "onboarding",
            metadata: [
                "currency": settings.currency,
                "timezone": settings.timezone
            ]
        )
    }

    // MARK: - Step Navigation

    /// Moves to the next step in the onboarding flow (mode-aware)
    func moveToNextStep() async {
        guard validateCurrentStep() else {
            logger.warning("Current step validation failed")
            error = .validationFailed("Please complete all required fields")
            return
        }

        guard let nextStep = OnboardingNavigationService.getNextStep(
            currentStep: currentStep,
            mode: selectedMode
        ) else {
            logger.info("Reached final step, completing onboarding")
            await completeOnboarding()
            return
        }

        logger.info("Moving from \(currentStep.rawValue) to \(nextStep.rawValue) (mode: \(selectedMode.rawValue))")

        // Update UI state immediately (synchronous)
        completedSteps.insert(currentStep)
        currentStep = nextStep
        error = nil

        // Save to database in background (don't await)
        Task {
            await updateProgress { progress in
                var updated = progress
                updated.currentStep = nextStep
                updated.completedSteps = self.completedSteps
                updated.updatedAt = Date()
                return updated
            }
        }

        SentryService.shared.addBreadcrumb(
            message: "Moved to next onboarding step",
            category: "onboarding",
            data: [
                "step": nextStep.rawValue,
                "mode": selectedMode.rawValue
            ]
        )
    }

    /// Moves to the previous step in the onboarding flow
    func moveToPreviousStep() async {
        guard let previousStep = OnboardingNavigationService.getPreviousStep(currentStep: currentStep) else {
            logger.info("Already at first step")
            return
        }

        logger.info("Moving from \(currentStep.rawValue) to \(previousStep.rawValue)")

        // Update UI state immediately (synchronous)
        currentStep = previousStep
        error = nil

        // Save to database in background (don't await)
        Task {
            await updateProgress { progress in
                var updated = progress
                updated.currentStep = previousStep
                updated.updatedAt = Date()
                return updated
            }
        }

        SentryService.shared.addBreadcrumb(
            message: "Moved to previous onboarding step",
            category: "onboarding",
            data: ["step": previousStep.rawValue]
        )
    }

    /// Skips the current step (if optional)
    func skipCurrentStep() async {
        guard OnboardingNavigationService.canSkipStep(currentStep) else {
            logger.warning("Cannot skip required step: \(currentStep.rawValue)")
            error = .invalidStep(currentStep)
            return
        }

        logger.info("Skipping optional step: \(currentStep.rawValue)")

        // Update UI state immediately (synchronous)
        completedSteps.insert(currentStep)

        if let nextStep = OnboardingNavigationService.getNextStep(
            currentStep: currentStep,
            mode: selectedMode
        ) {
            currentStep = nextStep

            // Save to database in background (don't await)
            Task {
                await updateProgress { progress in
                    var updated = progress
                    updated.currentStep = nextStep
                    updated.completedSteps = self.completedSteps
                    updated.updatedAt = Date()
                    return updated
                }
            }
        }

        SentryService.shared.trackAction(
            "skip_onboarding_step",
            category: "onboarding",
            metadata: ["step": currentStep.rawValue]
        )
    }

    /// Jumps to a specific step
    func jumpToStep(_ step: OnboardingStep) async {
        logger.info("Jumping to step: \(step.rawValue)")

        currentStep = step
        error = nil

        await updateProgress { progress in
            var updated = progress
            updated.currentStep = step
            updated.updatedAt = Date()
            return updated
        }
    }

    // MARK: - Complete Onboarding

    /// Marks onboarding as completed
    func completeOnboarding() async {
        logger.info("Completing onboarding")

        do {
            let completed = try await progressService.completeOnboarding()

            isCompleted = true
            currentStep = .completion
            completedSteps = Set(OnboardingStep.allCases)
            loadingState = .loaded(completed)

            // Create settings from onboarding data
            await createSettingsFromOnboardingData()

            // Create owner collaborator record in detached task to prevent cancellation
            Task.detached { [weak self] in
                await self?.createOwnerCollaboratorRecord()
            }

            logger.info("Onboarding completed successfully")
        } catch {
            logger.error("Failed to complete onboarding", error: error)
            self.error = error as? OnboardingError ?? .updateFailed(underlying: error)
        }
    }

    /// Creates initial settings from onboarding data
    private func createSettingsFromOnboardingData() async {
        guard let coupleId = await SessionManager.shared.currentTenantId else {
            logger.error("No tenant ID - cannot create settings")
            return
        }

        do {
            try await settingsService.createSettings(
                coupleId: coupleId,
                weddingDetails: weddingDetails,
                defaultSettings: defaultSettings
            )
        } catch {
            logger.error("Failed to create/update settings record", error: error)
            // Don't throw - onboarding is still complete, settings can be configured later
        }
    }

    /// Creates owner collaborator record for the user who completed onboarding
    private func createOwnerCollaboratorRecord() async {
        guard let coupleId = await SessionManager.shared.currentTenantId else {
            logger.error("No tenant ID - cannot create owner collaborator")
            return
        }

        guard let userId = SupabaseManager.shared.currentUser?.id else {
            logger.error("No user ID - cannot create owner collaborator")
            return
        }

        guard let userEmail = SupabaseManager.shared.currentUser?.email else {
            logger.error("No user email - cannot create owner collaborator")
            return
        }

        do {
            try await collaboratorService.createOwnerCollaborator(
                coupleId: coupleId,
                userId: userId,
                userEmail: userEmail,
                weddingDetails: weddingDetails
            )
        } catch {
            // Error already logged in service
        }
    }

    // MARK: - Validation

    /// Validates the current step's requirements
    private func validateCurrentStep() -> Bool {
        OnboardingValidationService.validateStep(
            currentStep,
            weddingDetails: weddingDetails,
            defaultSettings: defaultSettings
        )
    }

    // MARK: - Update Progress Helper

    /// Updates progress with a transformation function
    private func updateProgress(_ transform: (OnboardingProgress) -> OnboardingProgress) async {
        guard let currentProgress = progress else {
            logger.warning("No progress to update")
            return
        }

        let updated = transform(currentProgress)

        do {
            let saved = try await progressService.updateProgress(updated)
            loadingState = .loaded(saved)
            logger.info("Progress updated successfully")
        } catch {
            logger.error("Failed to update progress", error: error)
            self.error = error as? OnboardingError ?? .updateFailed(underlying: error)
        }
    }

    // MARK: - Reset

    /// Resets onboarding state (for testing or restart)
    func reset() async {
        logger.info("Resetting onboarding state")

        do {
            try await progressService.deleteProgress()

            loadingState = .idle
            currentStep = .welcome
            completedSteps = []
            isCompleted = false
            error = nil
            weddingDetails = WeddingDetails()
            defaultSettings = OnboardingDefaultSettings()

            logger.info("Onboarding state reset successfully")
        } catch {
            logger.error("Failed to reset onboarding", error: error)
            self.error = error as? OnboardingError ?? .deleteFailed(underlying: error)
        }
    }

    // MARK: - Check Completion

    /// Checks if onboarding has been completed
    func checkIfCompleted() async -> Bool {
        do {
            let completed = try await progressService.isCompleted()
            isCompleted = completed
            return completed
        } catch {
            logger.error("Failed to check onboarding completion", error: error)
            return false
        }
    }

    /// Resets the store state when switching to a different wedding
    func resetForNewTenant() {
        logger.info("Resetting onboarding store for new tenant")
        loadingState = .idle
        currentStep = .welcome
        completedSteps = []
        isCompleted = false
        error = nil
        weddingDetails = WeddingDetails()
        defaultSettings = OnboardingDefaultSettings()
        selectedMode = .guided
    }
}
