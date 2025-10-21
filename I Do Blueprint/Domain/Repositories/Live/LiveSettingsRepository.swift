//
//  LiveSettingsRepository.swift
//  My Wedding Planning App
//
//  Supabase implementation of settings repository
//

import Foundation
import Supabase

actor LiveSettingsRepository: SettingsRepositoryProtocol {
    private let supabase: SupabaseClient?

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

    func fetchSettings() async throws -> CoupleSettings {
        print("🔵 [SettingsRepo] Starting fetchSettings query...")
        
        struct SettingsRow: Decodable {
            let settings: CoupleSettings
        }

        do {
            let client = try getClient()
            
            // Get current authenticated user ID
            let session = try await client.auth.session
            let userId = session.user.id
            
            print("🔵 [SettingsRepo] Fetching settings for couple_id: \(userId.uuidString)")
            
            let response: SettingsRow = try await client
                .from("couple_settings")
                .select("settings")
                .eq("couple_id", value: userId.uuidString)
                .limit(1)
                .single()
                .execute()
                .value
            
            print("✅ [SettingsRepo] Query completed successfully")
            return response.settings
        } catch {
            print("❌ [SettingsRepo] Query failed: \(error)")
            throw error
        }
    }

    func updateSettings(_ partialSettings: [String: Any]) async throws -> CoupleSettings {
        struct SettingsRow: Decodable {
            let settings: CoupleSettings
        }

        let client = try getClient()
        // Get current authenticated user ID
        let session = try await client.auth.session
        let userId = session.user.id

        print("🔵 [SettingsRepo] updateSettings - User ID: \(userId.uuidString)")

        // Fetch current settings
        let currentSettings = try await fetchSettings()

        // Deep merge partial settings into current settings
        let mergedSettings = deepMerge(current: currentSettings, updates: partialSettings)
        
        print("🔵 [SettingsRepo] updateSettings - Merged settings tax rates: \(mergedSettings.budget.taxRates.count)")

        struct SettingsUpdate: Encodable {
            let settings: CoupleSettings
        }

        do {
            print("🔵 [SettingsRepo] updateSettings - Attempting to update database...")
            
            // Update the settings
            let response: [SettingsRow] = try await client
                .from("couple_settings")
                .update(SettingsUpdate(settings: mergedSettings))
                .eq("couple_id", value: userId.uuidString)
                .select("settings")
                .execute()
                .value

            print("🔵 [SettingsRepo] updateSettings - Update returned \(response.count) rows")
            
            guard let firstResult = response.first else {
                print("❌ [SettingsRepo] updateSettings - No rows returned from update")
                throw NSError(domain: "SettingsRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "No settings row found for user"])
            }

            print("✅ [SettingsRepo] updateSettings - Database updated successfully")
            print("🔵 [SettingsRepo] updateSettings - Response tax rates: \(firstResult.settings.budget.taxRates.count)")
            return firstResult.settings
        } catch {
            print("❌ [SettingsRepo] updateSettings - Database update failed: \(error)")
            throw error
        }
    }

    // MARK: - Granular Settings Updates

    func updateGlobalSettings(_ settings: GlobalSettings) async throws {
        let payload: [String: Any] = ["global": settings]
        _ = try await updateSettings(payload)
    }

    func updateThemeSettings(_ settings: ThemeSettings) async throws {
        let payload: [String: Any] = ["theme": settings]
        _ = try await updateSettings(payload)
    }

    func updateBudgetSettings(_ settings: BudgetSettings) async throws {
        print("🔵 [SettingsRepo] updateBudgetSettings called")
        print("🔵 [SettingsRepo] Tax rates count: \(settings.taxRates.count)")
        
        // Convert BudgetSettings to dictionary for proper merging
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(settings)
        
        print("🔵 [SettingsRepo] Encoded data: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        guard let budgetDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ [SettingsRepo] Failed to convert to dictionary")
            throw NSError(domain: "SettingsRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert BudgetSettings to dictionary"])
        }
        
        print("🔵 [SettingsRepo] Budget dict keys: \(budgetDict.keys)")
        if let taxRates = budgetDict["tax_rates"] as? [[String: Any]] {
            print("🔵 [SettingsRepo] Tax rates in dict: \(taxRates.count)")
        } else {
            print("❌ [SettingsRepo] No tax_rates in dict or wrong type")
        }
        
        let payload: [String: Any] = ["budget": budgetDict]
        _ = try await updateSettings(payload)
        
        print("✅ [SettingsRepo] Budget settings updated successfully")
    }

    func updateCashFlowSettings(_ settings: CashFlowSettings) async throws {
        let payload: [String: Any] = ["cash_flow": settings]
        _ = try await updateSettings(payload)
    }

    func updateTasksSettings(_ settings: TasksSettings) async throws {
        let payload: [String: Any] = ["tasks": settings]
        _ = try await updateSettings(payload)
    }

    func updateVendorsSettings(_ settings: VendorsSettings) async throws {
        let payload: [String: Any] = ["vendors": settings]
        _ = try await updateSettings(payload)
    }

    func updateGuestsSettings(_ settings: GuestsSettings) async throws {
        let payload: [String: Any] = ["guests": settings]
        _ = try await updateSettings(payload)
    }

    func updateDocumentsSettings(_ settings: DocumentsSettings) async throws {
        let payload: [String: Any] = ["documents": settings]
        _ = try await updateSettings(payload)
    }

    func updateNotificationsSettings(_ settings: NotificationsSettings) async throws {
        let payload: [String: Any] = ["notifications": settings]
        _ = try await updateSettings(payload)
    }

    func updateLinksSettings(_ settings: LinksSettings) async throws {
        let payload: [String: Any] = ["links": settings]
        _ = try await updateSettings(payload)
    }

    // MARK: - Custom Vendor Categories

    func fetchCustomVendorCategories() async throws -> [CustomVendorCategory] {
        let client = try getClient()
        return try await client
            .from("vendor_custom_categories")
            .select()
            .order("name", ascending: true)
            .execute()
            .value
    }

    func createVendorCategory(_ category: CustomVendorCategory) async throws -> CustomVendorCategory {
        return try await createCustomVendorCategory(
            name: category.name,
            description: category.description,
            typicalBudgetPercentage: category.typicalBudgetPercentage
        )
    }

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

    func updateVendorCategory(_ category: CustomVendorCategory) async throws -> CustomVendorCategory {
        return try await updateCustomVendorCategory(
            id: category.id,
            name: category.name,
            description: category.description,
            typicalBudgetPercentage: category.typicalBudgetPercentage
        )
    }

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

    func deleteVendorCategory(id: String) async throws {
        try await deleteCustomVendorCategory(id: id)
    }

    func deleteCustomVendorCategory(id: String) async throws {
        let client = try getClient()
        try await client
            .from("vendor_custom_categories")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func checkVendorsUsingCategory(categoryId: String) async throws -> [VendorUsingCategory] {
        let client = try getClient()
        return try await client
            .from("vendor_information")
            .select("id, vendor_name")
            .eq("vendor_category_id", value: categoryId)
            .limit(5)
            .execute()
            .value
    }

    // MARK: - Utility Operations

    func formatPhoneNumbers() async throws -> PhoneFormatResult {
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

    // MARK: - Private Helpers

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
        if let partner1FullName = updates["partner1_full_name"] as? String { merged.partner1FullName = partner1FullName }
        if let partner1Nickname = updates["partner1_nickname"] as? String { merged.partner1Nickname = partner1Nickname }
        if let partner2FullName = updates["partner2_full_name"] as? String { merged.partner2FullName = partner2FullName }
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
        print("🔵 [SettingsRepo] mergeBudgetSettings called")
        print("🔵 [SettingsRepo] Current tax rates: \(current.taxRates.count)")
        print("🔵 [SettingsRepo] Updates keys: \(updates.keys)")
        
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
        
        // Handle tax_rates array
        if let taxRatesArray = updates["tax_rates"] as? [[String: Any]] {
            print("🔵 [SettingsRepo] Found tax_rates array with \(taxRatesArray.count) items")
            merged.taxRates = taxRatesArray.compactMap { taxRateDict in
                print("🔵 [SettingsRepo] Processing tax rate: \(taxRateDict)")
                guard let id = taxRateDict["id"] as? String,
                      let name = taxRateDict["name"] as? String,
                      let rate = taxRateDict["rate"] as? Double else {
                    print("❌ [SettingsRepo] Failed to parse tax rate")
                    return nil
                }
                let isDefault = taxRateDict["is_default"] as? Bool ?? false
                print("✅ [SettingsRepo] Parsed tax rate: \(name) - \(rate)%")
                return SettingsTaxRate(id: id, name: name, rate: rate, isDefault: isDefault)
            }
            print("🔵 [SettingsRepo] Merged tax rates: \(merged.taxRates.count)")
        } else {
            print("❌ [SettingsRepo] No tax_rates found in updates or wrong type")
        }
        
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
        current
    }
}
