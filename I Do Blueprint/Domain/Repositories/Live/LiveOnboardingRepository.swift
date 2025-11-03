//
//  LiveOnboardingRepository.swift
//  I Do Blueprint
//
//  Live implementation of OnboardingRepositoryProtocol using Supabase
//

import Foundation
import Supabase

/// Live implementation of onboarding repository with caching and Supabase integration
actor LiveOnboardingRepository: OnboardingRepositoryProtocol {
    private let logger = AppLogger.database

    private var supabase: SupabaseClient {
        guard let client = SupabaseManager.shared.client else {
            fatalError("Supabase client not initialized")
        }
        return client
    }

    // MARK: - Tenant Context

    private func getTenantId() async throws -> UUID {
        try await TenantContextProvider.shared.requireTenantId()
    }

    // MARK: - Fetch Onboarding Progress

    func fetchOnboardingProgress() async throws -> OnboardingProgress? {
        let coupleId = try await getTenantId()
        let cacheKey = "onboarding_progress_\(coupleId.uuidString)"

        // Check cache first
        if let cached: OnboardingProgress = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: onboarding progress")
            return cached
        }

        logger.info("Fetching onboarding progress for couple: \(coupleId.uuidString)")

        do {
            struct SettingsRow: Decodable {
                let id: UUID
                let couple_id: UUID
                let onboarding_progress: OnboardingProgressDTO?
                let created_at: Date?
                let updated_at: Date?
            }

            let rows: [SettingsRow] = try await supabase.database
                .from("couple_settings")
                .select()
                .eq("couple_id", value: coupleId)
                .limit(1)
                .execute()
                .value

            guard let row = rows.first else {
                logger.info("No onboarding progress found for couple")
                return nil
            }

            guard let progressDTO = row.onboarding_progress else {
                logger.info("Onboarding progress column is null")
                return nil
            }

            let progress = progressDTO.toDomain(
                id: row.id,
                coupleId: row.couple_id,
                createdAt: row.created_at ?? Date(),
                updatedAt: row.updated_at ?? Date()
            )

            // Cache the result
            await RepositoryCache.shared.set(cacheKey, value: progress, ttl: 60)

            logger.info("Successfully fetched onboarding progress")
            return progress

        } catch {
            logger.error("Error fetching onboarding progress", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchOnboardingProgress",
                "repository": "LiveOnboardingRepository"
            ])
            throw OnboardingError.fetchFailed(underlying: error)
        }
    }

    // MARK: - Save Onboarding Progress

    func saveOnboardingProgress(_ progress: OnboardingProgress) async throws -> OnboardingProgress {
        let coupleId = try await getTenantId()

        guard progress.coupleId == coupleId else {
            logger.error("Couple ID mismatch in onboarding progress")
            throw OnboardingError.tenantContextMissing
        }

        logger.info("Saving onboarding progress for couple: \(coupleId.uuidString)")

        do {
            let dto = OnboardingProgressDTO.fromDomain(progress)

            struct UpdatePayload: Encodable {
                let onboarding_progress: OnboardingProgressDTO
                let updated_at: Date
            }

            let payload = UpdatePayload(
                onboarding_progress: dto,
                updated_at: Date()
            )

            struct SettingsRow: Decodable {
                let id: UUID
                let couple_id: UUID
                let onboarding_progress: OnboardingProgressDTO
                let created_at: Date?
                let updated_at: Date?
            }

            // Use upsert to handle both insert and update cases
            struct UpsertPayload: Encodable {
                let couple_id: String
                let onboarding_progress: OnboardingProgressDTO
                let updated_at: String
            }

            let upsertPayload = UpsertPayload(
                couple_id: coupleId.uuidString,
                onboarding_progress: dto,
                updated_at: Date().ISO8601Format()
            )

            let rows: [SettingsRow] = try await supabase.database
                .from("couple_settings")
                .upsert(upsertPayload, onConflict: "couple_id")
                .select()
                .execute()
                .value

            guard let row = rows.first else {
                logger.error("No settings row found after upsert")
                throw OnboardingError.saveFailed(underlying: NSError(domain: "OnboardingRepository", code: 404))
            }

            let savedProgress = row.onboarding_progress.toDomain(
                id: row.id,
                coupleId: row.couple_id,
                createdAt: row.created_at ?? Date(),
                updatedAt: row.updated_at ?? Date()
            )

            // Invalidate cache
            let cacheKey = "onboarding_progress_\(coupleId.uuidString)"
            await RepositoryCache.shared.remove(cacheKey)

            logger.info("Successfully saved onboarding progress")
            return savedProgress

        } catch {
            logger.error("Error saving onboarding progress", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "saveOnboardingProgress",
                "repository": "LiveOnboardingRepository"
            ])
            throw OnboardingError.saveFailed(underlying: error)
        }
    }

    // MARK: - Update Onboarding Progress

    func updateOnboardingProgress(_ progress: OnboardingProgress) async throws -> OnboardingProgress {
        // Update is the same as save for this implementation
        try await saveOnboardingProgress(progress)
    }

    // MARK: - Complete Onboarding

    func completeOnboarding() async throws -> OnboardingProgress {
        let coupleId = try await getTenantId()

        logger.info("Completing onboarding for couple: \(coupleId.uuidString)")

        // Fetch current progress
        guard var progress = try await fetchOnboardingProgress() else {
            logger.error("No onboarding progress found to complete")
            throw OnboardingError.progressNotFound
        }

        // Mark as completed
        progress.isCompleted = true
        progress.currentStep = .completion
        progress.updatedAt = Date()

        // Save the completed progress
        try await saveOnboardingProgress(progress)
    }

    // MARK: - Delete Onboarding Progress

    func deleteOnboardingProgress() async throws {
        let coupleId = try await getTenantId()

        logger.info("Deleting onboarding progress for couple: \(coupleId.uuidString)")

        do {
            struct UpdatePayload: Encodable {
                let onboarding_progress: String?
                let updated_at: Date

                init() {
                    self.onboarding_progress = nil
                    self.updated_at = Date()
                }
            }

            let payload = UpdatePayload()

            try await supabase.database
                .from("couple_settings")
                .update(payload)
                .eq("couple_id", value: coupleId)
                .execute()

            // Invalidate cache
            let cacheKey = "onboarding_progress_\(coupleId.uuidString)"
            await RepositoryCache.shared.remove(cacheKey)

            logger.info("Successfully deleted onboarding progress")

        } catch {
            logger.error("Error deleting onboarding progress", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteOnboardingProgress",
                "repository": "LiveOnboardingRepository"
            ])
            throw OnboardingError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Check Onboarding Completion

    func isOnboardingCompleted() async throws -> Bool {
        guard let progress = try await fetchOnboardingProgress() else {
            return false
        }
        return progress.isCompleted
    }
}

// MARK: - DTO Mapping

/// Data Transfer Object for onboarding progress (matches JSONB structure)
private struct OnboardingProgressDTO: Codable {
    let currentStep: String
    let completedSteps: [String]
    let isCompleted: Bool
    let weddingDetails: WeddingDetailsDTO?
    let defaultSettings: OnboardingDefaultSettingsDTO?
    let guestImportStatus: ImportStatusDTO?
    let vendorImportStatus: ImportStatusDTO?
    let budgetSetupStatus: BudgetSetupStatusDTO?

    func toDomain(id: UUID, coupleId: UUID, createdAt: Date, updatedAt: Date) -> OnboardingProgress {
        OnboardingProgress(
            id: id,
            coupleId: coupleId,
            currentStep: OnboardingStep(rawValue: currentStep) ?? .welcome,
            completedSteps: Set(completedSteps.compactMap { OnboardingStep(rawValue: $0) }),
            isCompleted: isCompleted,
            weddingDetails: weddingDetails?.toDomain(),
            defaultSettings: defaultSettings?.toDomain(),
            guestImportStatus: guestImportStatus?.toDomain(),
            vendorImportStatus: vendorImportStatus?.toDomain(),
            budgetSetupStatus: budgetSetupStatus?.toDomain(),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func fromDomain(_ progress: OnboardingProgress) -> OnboardingProgressDTO {
        OnboardingProgressDTO(
            currentStep: progress.currentStep.rawValue,
            completedSteps: progress.completedSteps.map { $0.rawValue },
            isCompleted: progress.isCompleted,
            weddingDetails: progress.weddingDetails.map { WeddingDetailsDTO.fromDomain($0) },
            defaultSettings: progress.defaultSettings.map { OnboardingDefaultSettingsDTO.fromDomain($0) },
            guestImportStatus: progress.guestImportStatus.map { ImportStatusDTO.fromDomain($0) },
            vendorImportStatus: progress.vendorImportStatus.map { ImportStatusDTO.fromDomain($0) },
            budgetSetupStatus: progress.budgetSetupStatus.map { BudgetSetupStatusDTO.fromDomain($0) }
        )
    }
}

private struct WeddingDetailsDTO: Codable {
    let weddingDate: Date?
    let venue: String
    let partner1Name: String
    let partner2Name: String
    let weddingStyle: String?
    let estimatedGuestCount: Int?

    func toDomain() -> WeddingDetails {
        WeddingDetails(
            weddingDate: weddingDate,
            venue: venue,
            partner1Name: partner1Name,
            partner2Name: partner2Name,
            weddingStyle: weddingStyle.flatMap { WeddingStyle(rawValue: $0) },
            estimatedGuestCount: estimatedGuestCount
        )
    }

    static func fromDomain(_ details: WeddingDetails) -> WeddingDetailsDTO {
        WeddingDetailsDTO(
            weddingDate: details.weddingDate,
            venue: details.venue,
            partner1Name: details.partner1Name,
            partner2Name: details.partner2Name,
            weddingStyle: details.weddingStyle?.rawValue,
            estimatedGuestCount: details.estimatedGuestCount
        )
    }
}

private struct OnboardingDefaultSettingsDTO: Codable {
    let currency: String
    let timezone: String
    let budgetPreferences: BudgetPreferencesDTO?
    let notificationPreferences: NotificationPreferencesDTO?

    func toDomain() -> OnboardingDefaultSettings {
        OnboardingDefaultSettings(
            currency: currency,
            timezone: timezone,
            budgetPreferences: budgetPreferences?.toDomain(),
            notificationPreferences: notificationPreferences?.toDomain()
        )
    }

    static func fromDomain(_ settings: OnboardingDefaultSettings) -> OnboardingDefaultSettingsDTO {
        OnboardingDefaultSettingsDTO(
            currency: settings.currency,
            timezone: settings.timezone,
            budgetPreferences: settings.budgetPreferences.map { BudgetPreferencesDTO.fromDomain($0) },
            notificationPreferences: settings.notificationPreferences.map { NotificationPreferencesDTO.fromDomain($0) }
        )
    }
}

private struct BudgetPreferencesDTO: Codable {
    let totalBudget: Double?
    let trackPayments: Bool
    let enableAlerts: Bool
    let alertThreshold: Double

    func toDomain() -> BudgetPreferences {
        BudgetPreferences(
            totalBudget: totalBudget,
            trackPayments: trackPayments,
            enableAlerts: enableAlerts,
            alertThreshold: alertThreshold
        )
    }

    static func fromDomain(_ prefs: BudgetPreferences) -> BudgetPreferencesDTO {
        BudgetPreferencesDTO(
            totalBudget: prefs.totalBudget,
            trackPayments: prefs.trackPayments,
            enableAlerts: prefs.enableAlerts,
            alertThreshold: prefs.alertThreshold
        )
    }
}

private struct NotificationPreferencesDTO: Codable {
    let emailEnabled: Bool
    let pushEnabled: Bool
    let taskReminders: Bool
    let paymentReminders: Bool
    let eventReminders: Bool

    func toDomain() -> NotificationPreferences {
        NotificationPreferences(
            emailEnabled: emailEnabled,
            pushEnabled: pushEnabled,
            taskReminders: taskReminders,
            paymentReminders: paymentReminders,
            eventReminders: eventReminders
        )
    }

    static func fromDomain(_ prefs: NotificationPreferences) -> NotificationPreferencesDTO {
        NotificationPreferencesDTO(
            emailEnabled: prefs.emailEnabled,
            pushEnabled: prefs.pushEnabled,
            taskReminders: prefs.taskReminders,
            paymentReminders: prefs.paymentReminders,
            eventReminders: prefs.eventReminders
        )
    }
}

private struct ImportStatusDTO: Codable {
    let isStarted: Bool
    let isCompleted: Bool
    let totalRows: Int
    let successfulRows: Int
    let failedRows: Int
    let errors: [ImportErrorDTO]

    func toDomain() -> ImportStatus {
        ImportStatus(
            isStarted: isStarted,
            isCompleted: isCompleted,
            totalRows: totalRows,
            successfulRows: successfulRows,
            failedRows: failedRows,
            errors: errors.map { $0.toDomain() }
        )
    }

    static func fromDomain(_ status: ImportStatus) -> ImportStatusDTO {
        ImportStatusDTO(
            isStarted: status.isStarted,
            isCompleted: status.isCompleted,
            totalRows: status.totalRows,
            successfulRows: status.successfulRows,
            failedRows: status.failedRows,
            errors: status.errors.map { ImportErrorDTO.fromDomain($0) }
        )
    }
}

private struct ImportErrorDTO: Codable {
    let id: String
    let lineNumber: Int
    let message: String
    let field: String?

    func toDomain() -> ImportError {
        ImportError(
            id: UUID(uuidString: id) ?? UUID(),
            lineNumber: lineNumber,
            message: message,
            field: field
        )
    }

    static func fromDomain(_ error: ImportError) -> ImportErrorDTO {
        ImportErrorDTO(
            id: error.id.uuidString,
            lineNumber: error.lineNumber,
            message: error.message,
            field: error.field
        )
    }
}

private struct BudgetSetupStatusDTO: Codable {
    let isStarted: Bool
    let isCompleted: Bool
    let totalBudget: Double?
    let categoriesCreated: Int

    func toDomain() -> BudgetSetupStatus {
        BudgetSetupStatus(
            isStarted: isStarted,
            isCompleted: isCompleted,
            totalBudget: totalBudget,
            categoriesCreated: categoriesCreated
        )
    }

    static func fromDomain(_ status: BudgetSetupStatus) -> BudgetSetupStatusDTO {
        BudgetSetupStatusDTO(
            isStarted: status.isStarted,
            isCompleted: status.isCompleted,
            totalBudget: status.totalBudget,
            categoriesCreated: status.categoriesCreated
        )
    }
}
