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
        let totalSteps: Int
        if selectedMode == .express {
            // Express flow has 4 steps: welcome, weddingDetails, budgetSetup, completion
            totalSteps = 4
        } else {
            // Guided flow has all steps
            totalSteps = OnboardingStep.allCases.count
        }
        
        let completed = completedSteps.count
        return Double(completed) / Double(totalSteps)
    }
    
    var canMoveToNextStep: Bool {
        guard let nextStep = currentStep.nextStep else { return false }
        return validateCurrentStep()
    }
    
    var canMoveToPreviousStep: Bool {
        currentStep.previousStep != nil
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
            if let existingProgress = try await repository.fetchOnboardingProgress() {
                logger.info("Found existing onboarding progress at step: \(existingProgress.currentStep.rawValue)")
                
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
                
                SentryService.shared.addBreadcrumb(
                    message: "Onboarding progress loaded",
                    category: "onboarding",
                    data: [
                        "currentStep": existingProgress.currentStep.rawValue,
                        "completedSteps": existingProgress.completedSteps.count,
                        "isCompleted": existingProgress.isCompleted
                    ]
                )
            } else {
                logger.info("No existing onboarding progress found")
                loadingState = .idle
            }
        } catch {
            logger.error("Failed to load onboarding progress", error: error)
            self.error = error as? OnboardingError ?? .fetchFailed(underlying: error)
            loadingState = .error(self.error!)
            
            SentryService.shared.captureError(error, context: [
                "operation": "loadOnboardingProgress"
            ])
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
        
        let progress = OnboardingProgress(
            coupleId: coupleId,
            currentStep: .welcome,
            completedSteps: [],
            isCompleted: false
        )
        
        // Save to database in background (don't block UI)
        Task {
            do {
                let saved = try await repository.saveOnboardingProgress(progress)
                await MainActor.run {
                    loadingState = .loaded(saved)
                }
                
                SentryService.shared.trackAction(
                    "start_onboarding",
                    category: "onboarding",
                    metadata: ["mode": mode.rawValue]
                )
                
                logger.info("Onboarding started successfully")
            } catch {
                logger.error("Failed to start onboarding", error: error)
                await MainActor.run {
                    self.error = error as? OnboardingError ?? .saveFailed(underlying: error)
                }
                
                SentryService.shared.captureError(error, context: [
                    "operation": "startOnboarding",
                    "mode": mode.rawValue
                ])
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
        
        guard details.isValid else {
            logger.warning("Wedding details validation failed")
            logger.warning("Partner 1 empty: \(details.partner1Name.trimmingCharacters(in: .whitespaces).isEmpty), Partner 2 empty: \(details.partner2Name.trimmingCharacters(in: .whitespaces).isEmpty), Date check: \(details.isWeddingDateTBD || details.weddingDate != nil)")
            error = .validationFailed("Please enter both partner names and either select a date or check TBD")
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
        
        guard let nextStep = getNextStep() else {
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
    
    /// Gets the next step based on the selected onboarding mode
    private func getNextStep() -> OnboardingStep? {
        if selectedMode == .express {
            // Express flow: welcome → weddingDetails → budgetSetup → completion
            let expressFlow: [OnboardingStep] = [
                .welcome,
                .weddingDetails,
                .budgetSetup,
                .completion
            ]
            
            guard let currentIndex = expressFlow.firstIndex(of: currentStep),
                  currentIndex < expressFlow.count - 1 else {
                return nil
            }
            
            return expressFlow[currentIndex + 1]
        } else {
            // Guided flow: all steps in order
            return currentStep.nextStep
        }
    }
    
    /// Moves to the previous step in the onboarding flow
    func moveToPreviousStep() async {
        guard let previousStep = currentStep.previousStep else {
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
        guard currentStep.isOptional else {
            logger.warning("Cannot skip required step: \(currentStep.rawValue)")
            error = .invalidStep(currentStep)
            return
        }
        
        logger.info("Skipping optional step: \(currentStep.rawValue)")
        
        // Update UI state immediately (synchronous)
        completedSteps.insert(currentStep)
        
        if let nextStep = currentStep.nextStep {
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
            let completed = try await repository.completeOnboarding()
            
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
            
            SentryService.shared.trackAction(
                "complete_onboarding",
                category: "onboarding",
                metadata: [
                    "mode": selectedMode.rawValue,
                    "totalSteps": OnboardingStep.allCases.count
                ]
            )
            
            logger.info("Onboarding completed successfully")
        } catch {
            logger.error("Failed to complete onboarding", error: error)
            self.error = error as? OnboardingError ?? .updateFailed(underlying: error)
            
            SentryService.shared.captureError(error, context: [
                "operation": "completeOnboarding"
            ])
        }
    }
    
    /// Creates initial settings from onboarding data
    private func createSettingsFromOnboardingData() async {
        logger.info("Creating settings from onboarding data")
        
        guard let coupleId = await SessionManager.shared.currentTenantId else {
            logger.error("No tenant ID - cannot create settings")
            return
        }
        
        // Build complete settings with onboarding data
        var settings = CoupleSettings.default
        
        // Update global settings
        settings.global.currency = defaultSettings.currency
        settings.global.timezone = defaultSettings.timezone
        
        if weddingDetails.isValid {
            settings.global.partner1FullName = weddingDetails.partner1Name
            settings.global.partner1Nickname = weddingDetails.partner1Nickname
            settings.global.partner2FullName = weddingDetails.partner2Name
            settings.global.partner2Nickname = weddingDetails.partner2Nickname
            
            // Save wedding date in YYYY-MM-DD format
            if let weddingDate = weddingDetails.weddingDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone(secondsFromGMT: 0) // Use UTC to avoid timezone shifts
                settings.global.weddingDate = formatter.string(from: weddingDate)
                settings.global.isWeddingDateTBD = false
                
                logger.info("Saving wedding date from onboarding: \(settings.global.weddingDate)")
            } else {
                // No date set - mark as TBD
                settings.global.weddingDate = ""
                settings.global.isWeddingDateTBD = true
                
                logger.info("No wedding date set - marking as TBD")
            }
            
            // Update wedding events from onboarding
            if !weddingDetails.weddingEvents.isEmpty {
                // Convert onboarding events to settings events
                settings.global.weddingEvents = weddingDetails.weddingEvents.enumerated().map { index, event in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    
                    return SettingsWeddingEvent(
                        id: event.id,
                        eventName: event.eventName,
                        eventDate: event.eventDate.map { formatter.string(from: $0) } ?? "",
                        eventTime: event.eventTime,
                        venueLocation: event.venueLocation,
                        description: "",
                        isMainEvent: event.isMainEvent,
                        eventOrder: index + 1
                    )
                }
                
                logger.info("Saved \(weddingDetails.weddingEvents.count) wedding events from onboarding")
            } else {
                // Keep default events if none configured in onboarding
                logger.info("No wedding events configured in onboarding, keeping defaults")
            }
        }
        
        // Update budget settings
        if let budgetPrefs = defaultSettings.budgetPreferences {
            if let totalBudget = budgetPrefs.totalBudget {
                settings.budget.totalBudget = totalBudget
                settings.budget.baseBudget = totalBudget
            }
            settings.budget.paymentReminders = budgetPrefs.trackPayments
        }
        
        // Update theme settings
        if let themePrefs = defaultSettings.themePreferences {
            settings.theme.colorScheme = themePrefs.colorScheme
            settings.theme.darkMode = themePrefs.darkMode
            
            logger.info("Saved theme preferences: \(themePrefs.colorScheme), dark mode: \(themePrefs.darkMode)")
        }
        
        // Update notification settings
        if let notifPrefs = defaultSettings.notificationPreferences {
            settings.notifications.emailEnabled = notifPrefs.emailEnabled
            settings.notifications.pushEnabled = notifPrefs.pushEnabled
            
            logger.info("Saved notification preferences")
        }
        
        // Update feature preferences
        if let featurePrefs = defaultSettings.featurePreferences {
            settings.tasks = featurePrefs.tasks
            settings.vendors = featurePrefs.vendors
            settings.guests = featurePrefs.guests
            settings.documents = featurePrefs.documents
            
            logger.info("Saved feature preferences: tasks(\(featurePrefs.tasks.defaultView)), vendors(\(featurePrefs.vendors.defaultView)), guests(\(featurePrefs.guests.defaultView))")
        }
        
        // Upsert the settings record (insert or update if exists)
        do {
            struct SettingsUpsert: Encodable {
                let couple_id: UUID
                let settings: CoupleSettings
                let schema_version: Int
            }
            
            let upsert = SettingsUpsert(
                couple_id: coupleId,
                settings: settings,
                schema_version: 1
            )
            
            guard let client = SupabaseManager.shared.client else {
                logger.error("Supabase client not available")
                return
            }
            
            try await client
                .from("couple_settings")
                .upsert(upsert, onConflict: "couple_id")
                .execute()
            
            logger.info("Successfully created/updated settings record from onboarding data")
        } catch {
            logger.error("Failed to create/update settings record", error: error)
            // Don't throw - onboarding is still complete, settings can be configured later
        }
    }
    
    /// Creates owner collaborator record for the user who completed onboarding
    private func createOwnerCollaboratorRecord() async {
        logger.info("Creating owner collaborator record")
        
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
        
        // Determine display name from wedding details
        // Use partner1's name as default (user can update later if they're partner2)
        let displayName = weddingDetails.partner1Name.isEmpty ? nil : weddingDetails.partner1Name
        
        do {
            // Use the class-level dependency
            let collaborator = try await collaborationRepository.createOwnerCollaborator(
                coupleId: coupleId,
                userId: userId,
                email: userEmail,
                displayName: displayName
            )
            
            logger.info("Owner collaborator created successfully: \(collaborator.id.uuidString)")
            
            SentryService.shared.addBreadcrumb(
                message: "Owner collaborator created during onboarding",
                category: "onboarding",
                data: [
                    "couple_id": coupleId.uuidString,
                    "user_id": userId.uuidString,
                    "has_display_name": displayName != nil
                ]
            )
        } catch {
            // Log error but don't fail onboarding
            // User can still use the app, just won't be able to invite others until this is fixed
            logger.error("Failed to create owner collaborator (non-blocking)", error: error)
            
            SentryService.shared.captureError(error, context: [
                "operation": "createOwnerCollaboratorRecord",
                "couple_id": coupleId.uuidString,
                "user_id": userId.uuidString,
                "blocking": "false"
            ])
        }
    }
    
    // MARK: - Validation
    
    /// Validates the current step's requirements
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case .welcome:
            return true // Always valid
            
        case .weddingDetails:
            return weddingDetails.isValid
            
        case .defaultSettings:
            return !defaultSettings.currency.isEmpty && !defaultSettings.timezone.isEmpty
            
        case .featurePreferences, .guestImport, .vendorImport:
            return true // Optional steps
            
        case .budgetSetup:
            return true // Will validate in budget wizard
            
        case .completion:
            return true
        }
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
            let saved = try await repository.updateOnboardingProgress(updated)
            loadingState = .loaded(saved)
            logger.info("Progress updated successfully")
        } catch {
            logger.error("Failed to update progress", error: error)
            self.error = error as? OnboardingError ?? .updateFailed(underlying: error)
            
            SentryService.shared.captureError(error, context: [
                "operation": "updateProgress",
                "currentStep": currentStep.rawValue
            ])
        }
    }
    
    // MARK: - Reset
    
    /// Resets onboarding state (for testing or restart)
    func reset() async {
        logger.info("Resetting onboarding state")
        
        do {
            try await repository.deleteOnboardingProgress()
            
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
            let completed = try await repository.isOnboardingCompleted()
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
