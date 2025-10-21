//
//  SettingsAPI.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import Foundation
import Supabase

class SettingsAPI {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.api

    init(supabase: SupabaseClient? = SupabaseManager.shared.client) {
        self.supabase = supabase
    }

    private func getClient() throws -> SupabaseClient {
        guard let supabase = supabase else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return supabase
    }

    // MARK: - Settings CRUD

    /// Fetch settings for the current user
    func fetchSettings() async throws -> CoupleSettings {
        struct SettingsRow: Decodable {
            let settings: CoupleSettings
        }

        let startTime = Date()

        do {
            let client = try getClient()
            let response: SettingsRow = try await RepositoryNetwork.withRetry {
                try await client
                    .from("couple_settings")
                    .select("settings")
                    .limit(1)
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched settings in \(duration)s - darkMode: \(response.settings.theme.darkMode)")
            AnalyticsService.trackNetwork(operation: "fetchSettings", outcome: .success, duration: duration)

            return response.settings
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch settings after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchSettings", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    /// Update settings for the current user (partial update supported via deep merge)
    func updateSettings(_ partialSettings: [String: Any]) async throws -> CoupleSettings {
        struct SettingsRow: Decodable {
            let settings: CoupleSettings
        }

        logger.debug("Updating settings with partial data")
        let startTime = Date()

        do {
            let client = try getClient()
            // Get current authenticated user ID to use in WHERE clause
            let session = try await client.auth.session
            let userId = session.user.id
            logger.debug("User ID: \(userId)")

            // Fetch current settings
            let currentSettings = try await fetchSettings()

            // Deep merge partial settings into current settings
            let mergedSettings = deepMerge(current: currentSettings, updates: partialSettings)
            logger.debug("Merged settings - darkMode: \(mergedSettings.theme.darkMode)")

            struct SettingsUpdate: Encodable {
                let settings: CoupleSettings
            }

            let response: SettingsRow = try await RepositoryNetwork.withRetry {
                try await client
                    .from("couple_settings")
                    .update(SettingsUpdate(settings: mergedSettings))
                    .eq("couple_id", value: userId.uuidString)
                    .select("settings")
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Settings updated successfully in \(duration)s")
            AnalyticsService.trackNetwork(operation: "updateSettings", outcome: .success, duration: duration)

            return response.settings
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to update settings after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "updateSettings", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    /// Deep merge partial settings dictionary into CoupleSettings
    private func deepMerge(current: CoupleSettings, updates: [String: Any]) -> CoupleSettings {
        var merged = current

        for (key, value) in updates {
            switch key {
            case "global":
                if let globalDict = value as? [String: Any] {
                    merged.global = mergeGlobalSettings(current: merged.global, updates: globalDict)
                }
            case "theme":
                if let themeDict = value as? [String: Any] {
                    merged.theme = mergeThemeSettings(current: merged.theme, updates: themeDict)
                }
            case "budget":
                if let budgetDict = value as? [String: Any] {
                    merged.budget = mergeBudgetSettings(current: merged.budget, updates: budgetDict)
                }
            case "cash_flow":
                if let cashFlowDict = value as? [String: Any] {
                    merged.cashFlow = mergeCashFlowSettings(current: merged.cashFlow, updates: cashFlowDict)
                }
            case "tasks":
                if let tasksDict = value as? [String: Any] {
                    merged.tasks = mergeTasksSettings(current: merged.tasks, updates: tasksDict)
                }
            case "vendors":
                if let vendorsDict = value as? [String: Any] {
                    merged.vendors = mergeVendorsSettings(current: merged.vendors, updates: vendorsDict)
                }
            case "guests":
                if let guestsDict = value as? [String: Any] {
                    merged.guests = mergeGuestsSettings(current: merged.guests, updates: guestsDict)
                }
            case "documents":
                if let documentsDict = value as? [String: Any] {
                    merged.documents = mergeDocumentsSettings(current: merged.documents, updates: documentsDict)
                }
            case "notifications":
                if let notificationsDict = value as? [String: Any] {
                    merged.notifications = mergeNotificationsSettings(
                        current: merged.notifications,
                        updates: notificationsDict)
                }
            case "links":
                if let linksDict = value as? [String: Any] {
                    merged.links = mergeLinksSettings(current: merged.links, updates: linksDict)
                }
            default:
                break
            }
        }

        return merged
    }

    private func mergeGlobalSettings(current: GlobalSettings, updates: [String: Any]) -> GlobalSettings {
        var merged = current
        if let weddingDate = updates["wedding_date"] as? String { merged.weddingDate = weddingDate }
        if let partner1FullName = updates["partner1_full_name"] as? String { merged.partner1FullName = partner1FullName
        }
        if let partner1Nickname = updates["partner1_nickname"] as? String { merged.partner1Nickname = partner1Nickname }
        if let partner2FullName = updates["partner2_full_name"] as? String { merged.partner2FullName = partner2FullName
        }
        if let partner2Nickname = updates["partner2_nickname"] as? String { merged.partner2Nickname = partner2Nickname }
        if let currency = updates["currency"] as? String { merged.currency = currency }
        if let timezone = updates["timezone"] as? String { merged.timezone = timezone }
        return merged
    }

    private func mergeThemeSettings(current: ThemeSettings, updates: [String: Any]) -> ThemeSettings {
        var merged = current
        if let colorScheme = updates["color_scheme"] as? String { merged.colorScheme = colorScheme }
        if let darkMode = updates["dark_mode"] as? Bool { merged.darkMode = darkMode }
        return merged
    }

    private func mergeBudgetSettings(current: BudgetSettings, updates: [String: Any]) -> BudgetSettings {
        var merged = current
        if let totalBudget = updates["total_budget"] as? Double { merged.totalBudget = totalBudget }
        if let baseBudget = updates["base_budget"] as? Double { merged.baseBudget = baseBudget }
        if let includesEngagementRings = updates["includes_engagement_rings"] as? Bool {
            merged.includesEngagementRings = includesEngagementRings
        }
        if let engagementRingAmount = updates["engagement_ring_amount"] as? Double {
            merged.engagementRingAmount = engagementRingAmount
        }
        if let autoCategorize = updates["auto_categorize"] as? Bool { merged.autoCategorize = autoCategorize }
        if let paymentReminders = updates["payment_reminders"] as? Bool { merged.paymentReminders = paymentReminders }
        if let notes = updates["notes"] as? String { merged.notes = notes }
        return merged
    }

    private func mergeCashFlowSettings(current: CashFlowSettings, updates: [String: Any]) -> CashFlowSettings {
        var merged = current
        if let defaultPartner1Monthly = updates["default_partner1_monthly"] as? Double {
            merged.defaultPartner1Monthly = defaultPartner1Monthly
        }
        if let defaultPartner2Monthly = updates["default_partner2_monthly"] as? Double {
            merged.defaultPartner2Monthly = defaultPartner2Monthly
        }
        if let defaultInterestMonthly = updates["default_interest_monthly"] as? Double {
            merged.defaultInterestMonthly = defaultInterestMonthly
        }
        if let defaultGiftsMonthly = updates["default_gifts_monthly"] as? Double {
            merged.defaultGiftsMonthly = defaultGiftsMonthly
        }
        return merged
    }

    private func mergeTasksSettings(current: TasksSettings, updates: [String: Any]) -> TasksSettings {
        var merged = current
        if let defaultView = updates["default_view"] as? String { merged.defaultView = defaultView }
        if let showCompleted = updates["show_completed"] as? Bool { merged.showCompleted = showCompleted }
        if let notificationsEnabled = updates["notifications_enabled"] as? Bool {
            merged.notificationsEnabled = notificationsEnabled
        }
        return merged
    }

    private func mergeVendorsSettings(current: VendorsSettings, updates: [String: Any]) -> VendorsSettings {
        var merged = current
        if let defaultView = updates["default_view"] as? String { merged.defaultView = defaultView }
        if let showPaymentStatus = updates["show_payment_status"] as? Bool {
            merged.showPaymentStatus = showPaymentStatus
        }
        if let autoReminders = updates["auto_reminders"] as? Bool { merged.autoReminders = autoReminders }
        return merged
    }

    private func mergeGuestsSettings(current: GuestsSettings, updates: [String: Any]) -> GuestsSettings {
        var merged = current
        if let defaultView = updates["default_view"] as? String { merged.defaultView = defaultView }
        if let showMealPreferences = updates["show_meal_preferences"] as? Bool {
            merged.showMealPreferences = showMealPreferences
        }
        if let rsvpReminders = updates["rsvp_reminders"] as? Bool { merged.rsvpReminders = rsvpReminders }
        if let customMealOptions = updates["custom_meal_options"] as? [String] {
            merged.customMealOptions = customMealOptions
        }
        return merged
    }

    private func mergeDocumentsSettings(current: DocumentsSettings, updates: [String: Any]) -> DocumentsSettings {
        var merged = current
        if let autoOrganize = updates["auto_organize"] as? Bool { merged.autoOrganize = autoOrganize }
        if let cloudBackup = updates["cloud_backup"] as? Bool { merged.cloudBackup = cloudBackup }
        if let retentionDays = updates["retention_days"] as? Int { merged.retentionDays = retentionDays }
        return merged
    }

    private func mergeNotificationsSettings(
        current: NotificationsSettings,
        updates: [String: Any]) -> NotificationsSettings {
        var merged = current
        if let emailEnabled = updates["email_enabled"] as? Bool { merged.emailEnabled = emailEnabled }
        if let pushEnabled = updates["push_enabled"] as? Bool { merged.pushEnabled = pushEnabled }
        if let digestFrequency = updates["digest_frequency"] as? String { merged.digestFrequency = digestFrequency }
        return merged
    }

    private func mergeLinksSettings(current: LinksSettings, updates _: [String: Any]) -> LinksSettings {
        // LinksSettings only contains importantLinks array, which is complex
        // For now, return current since partial updates of arrays need special handling
        current
    }

    // MARK: - Vendor Custom Categories

    /// Fetch all custom vendor categories
    func fetchCustomVendorCategories() async throws -> [CustomVendorCategory] {
        let client = try getClient()
        return try await client
            .from("vendor_custom_categories")
            .select()
            .order("name", ascending: true)
            .execute()
            .value
    }

    /// Create a new custom vendor category
    func createCustomVendorCategory(
        name: String,
        description: String?,
        typicalBudgetPercentage: String?) async throws -> CustomVendorCategory {
        struct CreateRequest: Encodable {
            let name: String
            let description: String?
            let typical_budget_percentage: String?
        }

        let request = CreateRequest(
            name: name,
            description: description,
            typical_budget_percentage: typicalBudgetPercentage)

        let client = try getClient()
        return try await client
            .from("vendor_custom_categories")
            .insert(request)
            .select()
            .single()
            .execute()
            .value
    }

    /// Update an existing custom vendor category
    func updateCustomVendorCategory(
        id: String,
        name: String?,
        description: String?,
        typicalBudgetPercentage: String?) async throws -> CustomVendorCategory {
        struct UpdateRequest: Encodable {
            let name: String?
            let description: String?
            let typical_budget_percentage: String?
        }

        let request = UpdateRequest(
            name: name,
            description: description,
            typical_budget_percentage: typicalBudgetPercentage)

        let client = try getClient()
        return try await client
            .from("vendor_custom_categories")
            .update(request)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
    }

    /// Delete a custom vendor category
    func deleteCustomVendorCategory(id: String) async throws {
        let client = try getClient()
        try await client
            .from("vendor_custom_categories")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    /// Check if vendors are using a category
    func checkVendorsUsingCategory(categoryId: String) async throws -> [VendorUsingCategory] {
        struct VendorUsingCategory: Decodable {
            let id: Int
            let vendor_name: String
        }

        let client = try getClient()
        return try await client
            .from("vendor_information")
            .select("id, vendor_name")
            .eq("vendor_category_id", value: categoryId)
            .limit(5)
            .execute()
            .value
    }

    // MARK: - Phone Number Formatting

    /// Format all vendor and contact phone numbers
    func formatPhoneNumbers() async throws -> PhoneFormatResult {
        // Call the API endpoint for phone formatting
        // This would be a custom RPC or API route
        struct FormatResponse: Decodable {
            let message: String
            let vendors: PhoneFormatSection?
            let contacts: PhoneFormatSection?
        }

        let client = try getClient()
        let response: FormatResponse = try await client
            .rpc("format_phone_numbers")
            .execute()
            .value

        return PhoneFormatResult(
            message: response.message,
            vendors: response.vendors,
            contacts: response.contacts)
    }

    // MARK: - Data Deletion (Danger Zone)

    /// Delete all user data with options to preserve certain data
    func resetData(keepBudgetSandbox: Bool, keepAffordability: Bool, keepCategories: Bool) async throws {
        let params: [String: Bool] = [
            "keep_budget_sandbox": keepBudgetSandbox,
            "keep_affordability": keepAffordability,
            "keep_categories": keepCategories
        ]

        let client = try getClient()
        try await client
            .rpc("reset_user_data", params: params)
            .execute()
    }
}

// MARK: - Helper Models

struct VendorUsingCategory: Codable, Identifiable {
    let id: Int
    let vendorName: String

    enum CodingKeys: String, CodingKey {
        case id
        case vendorName = "vendor_name"
    }
}
