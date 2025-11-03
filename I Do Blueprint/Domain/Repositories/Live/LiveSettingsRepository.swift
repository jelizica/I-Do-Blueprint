//
//  LiveSettingsRepository.swift
//  My Wedding Planning App
//
//  Supabase implementation of settings repository
//

import Foundation
import Supabase

actor LiveSettingsRepository: SettingsRepositoryProtocol {
    private let logger = AppLogger.repository

    init() {
        // No initialization needed - we'll get the client when needed
    }

    private func getClient() async throws -> SupabaseClient {
        // Prefer immediate client if already available to avoid unnecessary waits
        if let c = await MainActor.run(resultType: SupabaseClient?.self, body: { SupabaseManager.shared.safeClient }) {
            return c
        }
        // Otherwise wait briefly for initialization
        return try await SupabaseManager.shared.waitForClient(timeout: 2.5)
    }

    // MARK: - Settings CRUD

    func fetchSettings() async throws -> CoupleSettings {
        logger.info("🔍 Starting fetchSettings query...")
        let overallStart = Date()

        struct SettingsRow: Decodable {
            let id: UUID
            let couple_id: UUID
            let settings: CoupleSettings
            let schema_version: Int?
            let created_at: Date?
            let updated_at: Date?
        }

        do {
            let tClientStart = Date()
            logger.debug("Getting Supabase client...")
            let client = try await getClient()
            let tClient = Date().timeIntervalSince(tClientStart)
            logger.debug("✅ Got Supabase client in \(String(format: "%.2f", tClient))s")

            // Get tenant ID (couple_id) from thread-safe context
            let tTenantStart = Date()
            logger.debug("Getting tenant ID from TenantContextProvider...")
            let tenantId = try await TenantContextProvider.shared.requireTenantId()
            let tTenant = Date().timeIntervalSince(tTenantStart)
            logger.debug("✅ Got tenantId in \(String(format: "%.2f", tTenant))s")

            logger.info("📍 Fetching settings for couple_id: \(tenantId.uuidString)")

            logger.debug("Building query...")
            let query = client
                .from("couple_settings")
                .select("*")
                .eq("couple_id", value: tenantId)
                .limit(1)

            logger.debug("Executing query...")
            let tQueryStart = Date()
            let rows: [SettingsRow] = try await query.execute().value
            let tQuery = Date().timeIntervalSince(tQueryStart)
            logger.info("✅ Query executed in \(String(format: "%.2f", tQuery))s, got \(rows.count) rows")

            guard let row = rows.first else {
                logger.error("❌ No settings found for couple_id: \(tenantId.uuidString)")
                throw NSError(domain: "SettingsRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "No settings found for this couple"])
            }

            logger.info("✅ Settings loaded successfully - wedding date: '\(row.settings.global.weddingDate)'")
            logger.info("✅ Custom meal options from DB: \(row.settings.guests.customMealOptions)")

            // Record performance details
            let total = Date().timeIntervalSince(overallStart)
            await PerformanceMonitor.shared.recordOperation("settings.fetchSettings.total", duration: total)
            await PerformanceMonitor.shared.recordOperation("settings.fetchSettings.client", duration: tClient)
            await PerformanceMonitor.shared.recordOperation("settings.fetchSettings.tenant", duration: tTenant)
            await PerformanceMonitor.shared.recordOperation("settings.fetchSettings.query", duration: tQuery)
            await MainActor.run {
                SentryService.shared.addBreadcrumb(
                    message: "settings.fetchSettings timings",
                    category: "settings",
                    data: [
                        "total_ms": Int(total * 1000),
                        "client_ms": Int(tClient * 1000),
                        "tenant_ms": Int(tTenant * 1000),
                        "query_ms": Int(tQuery * 1000),
                        "rows": rows.count
                    ]
                )
            }

            return row.settings
        } catch {
            logger.error("❌ Query failed with error: \(error)")
            logger.error("Error type: \(type(of: error))")
            logger.error("Error description: \(error.localizedDescription)")
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchSettings",
                "repository": "LiveSettingsRepository"
            ])
            throw error
        }
    }

    func updateSettings(_ partialSettings: [String: Any]) async throws -> CoupleSettings {
        do {
            struct SettingsRow: Decodable {
                let settings: CoupleSettings
            }

            let client = try await getClient()

            // Get tenant ID (couple_id) from thread-safe context
            let tenantId = try await TenantContextProvider.shared.requireTenantId()

            logger.debug("updateSettings - Couple ID: \(tenantId.uuidString)")

            // Fetch current settings
            let currentSettings = try await fetchSettings()

            // Deep merge partial settings into current settings
            let mergedSettings = deepMerge(current: currentSettings, updates: partialSettings)

            logger.debug("updateSettings - Merged settings tax rates: \(mergedSettings.budget.taxRates.count)")

            struct SettingsUpdate: Encodable {
                let settings: CoupleSettings
            }

            logger.debug("updateSettings - Attempting to update database...")

            // Update the settings
            let response: [SettingsRow] = try await client
                .from("couple_settings")
                .update(SettingsUpdate(settings: mergedSettings))
                .eq("couple_id", value: tenantId)
                .select("settings")
                .execute()
                .value

            logger.debug("updateSettings - Update returned \(response.count) rows")

            guard let firstResult = response.first else {
                logger.error("updateSettings - No rows returned from update")
                throw SettingsError.updateFailed(underlying: NSError(domain: "SettingsRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "No settings row found for this couple"]))
            }

            logger.info("updateSettings - Database updated successfully")
            logger.debug("updateSettings - Response tax rates: \(firstResult.settings.budget.taxRates.count)")
            return firstResult.settings
        } catch let error as SettingsError {
            throw error
        } catch {
            logger.error("updateSettings - Database update failed", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "updateSettings",
                "repository": "LiveSettingsRepository"
            ])
            throw SettingsError.updateFailed(underlying: error)
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
        logger.debug("updateBudgetSettings called")
        logger.debug("Tax rates count: \(settings.taxRates.count)")

        // Convert BudgetSettings to dictionary for proper merging
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(settings)

        logger.debug("Encoded budget settings data")

        guard let budgetDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            logger.error("Failed to convert to dictionary")
            throw NSError(domain: "SettingsRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert BudgetSettings to dictionary"])
        }

        logger.debug("Budget dict keys: \(budgetDict.keys.joined(separator: ", "))")
        if let taxRates = budgetDict["tax_rates"] as? [[String: Any]] {
            logger.debug("Tax rates in dict: \(taxRates.count)")
        } else {
            logger.warning("No tax_rates in dict or wrong type")
        }

        let payload: [String: Any] = ["budget": budgetDict]
        _ = try await updateSettings(payload)

        logger.info("Budget settings updated successfully")
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
        let client = try await getClient()
        let tenantId = try await TenantContextProvider.shared.requireTenantId()
        let cacheKey = "custom_vendor_categories_\(tenantId.uuidString)"
        let start = Date()

        if let cached: [CustomVendorCategory] = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            logger.info("Cache hit: custom vendor categories")
            return cached
        }

        let rows: [CustomVendorCategory] = try await client
            .from("vendor_custom_categories")
            .select()
            .eq("couple_id", value: tenantId)
            .order("name", ascending: true)
            .execute()
            .value

        await RepositoryCache.shared.set(cacheKey, value: rows, ttl: 300)
        await PerformanceMonitor.shared.recordOperation("settings.fetchCustomVendorCategories", duration: Date().timeIntervalSince(start))
        return rows
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
        do {
            struct CreateRequest: Encodable {
                let name: String
                let description: String?
                let typical_budget_percentage: String?
            }

            let request = CreateRequest(
                name: name,
                description: description,
                typical_budget_percentage: typicalBudgetPercentage)

            let client = try await getClient()
            let category: CustomVendorCategory = try await client
                .from("vendor_custom_categories")
                .insert(request)
                .select()
                .single()
                .execute()
                .value

            logger.info("Created custom vendor category: \(name)")
            return category
        } catch {
            logger.error("Failed to create custom vendor category", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "createCustomVendorCategory",
                "repository": "LiveSettingsRepository",
                "name": name
            ])
            throw SettingsError.categoryCreateFailed(underlying: error)
        }
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
        do {
            struct UpdateRequest: Encodable {
                let name: String?
                let description: String?
                let typical_budget_percentage: String?
            }

            let request = UpdateRequest(
                name: name,
                description: description,
                typical_budget_percentage: typicalBudgetPercentage)

            let client = try await getClient()
            let category: CustomVendorCategory = try await client
                .from("vendor_custom_categories")
                .update(request)
                .eq("id", value: id)
                .select()
                .single()
                .execute()
                .value

            logger.info("Updated custom vendor category: \(id)")
            return category
        } catch {
            logger.error("Failed to update custom vendor category", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "updateCustomVendorCategory",
                "repository": "LiveSettingsRepository",
                "id": id
            ])
            throw SettingsError.categoryUpdateFailed(underlying: error)
        }
    }

    func deleteVendorCategory(id: String) async throws {
        try await deleteCustomVendorCategory(id: id)
    }

    func deleteCustomVendorCategory(id: String) async throws {
        do {
            let client = try await getClient()
            try await client
                .from("vendor_custom_categories")
                .delete()
                .eq("id", value: id)
                .execute()

            logger.info("Deleted custom vendor category: \(id)")
        } catch {
            logger.error("Failed to delete custom vendor category", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteCustomVendorCategory",
                "repository": "LiveSettingsRepository",
                "id": id
            ])
            throw SettingsError.categoryDeleteFailed(underlying: error)
        }
    }

    func checkVendorsUsingCategory(categoryId: String) async throws -> [VendorUsingCategory] {
        let client = try await getClient()
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

        let client = try await getClient()
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

        let client = try await getClient()
        try await client
            .rpc("reset_user_data", params: params)
            .execute()
    }

    // MARK: - Account Deletion

    func deleteAccount() async throws {
        logger.info("🗑️ Starting complete account deletion process")

        do {
            let client = try await getClient()

            // Get current user ID from SupabaseManager
            let userId = await MainActor.run {
                SupabaseManager.shared.currentUser?.id
            }

            guard let userId = userId else {
                logger.error("No user logged in - cannot delete account")
                throw NSError(
                    domain: "SettingsRepository",
                    code: 401,
                    userInfo: [NSLocalizedDescriptionKey: "No user logged in"]
                )
            }

            logger.info("Deleting account for user: \(userId.uuidString)")

            // Step 1: Call database function to delete all data
            logger.debug("Step 1: Calling database function to delete all data")

            let params: [String: UUID] = ["user_id_to_delete": userId]
            try await client
                .rpc("delete_user_account", params: params)
                .execute()

            logger.info("✅ Database cleanup completed")

            // Step 2: Delete the auth user via Edge Function
            logger.debug("Step 2: Deleting auth user via Edge Function")

            do {
                try await deleteAuthUser(userId: userId, client: client)
                logger.info("✅ Auth user deleted")
            } catch {
                // Log the error but don't fail the entire operation
                // User data is already deleted, so we'll sign them out
                logger.warning("⚠️ Failed to delete auth user (will sign out anyway): \(error.localizedDescription)")
            }

            // Step 3: Sign out
            try await client.auth.signOut()
            logger.info("✅ User signed out")

            // Step 4: Clear local session
            await MainActor.run {
                SessionManager.shared.clearSession()
            }
            logger.info("✅ Local session cleared")

            // Step 5: Clear caches
            await RepositoryCache.shared.clearAll()
            logger.info("✅ Caches cleared")

            logger.info("🎉 Account deletion completed successfully")

        } catch {
            logger.error("❌ Account deletion failed", error: error)
            throw SettingsError.accountDeletionFailed(underlying: error)
        }
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
        logger.debug("mergeBudgetSettings called")
        logger.debug("Current tax rates: \(current.taxRates.count)")
        logger.debug("Updates keys: \(updates.keys.joined(separator: ", "))")

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
            logger.debug("Found tax_rates array with \(taxRatesArray.count) items")
            merged.taxRates = taxRatesArray.compactMap { taxRateDict in
                logger.debug("Processing tax rate: \(taxRateDict.keys.joined(separator: ", "))")
                guard let id = taxRateDict["id"] as? String,
                      let name = taxRateDict["name"] as? String,
                      let rate = taxRateDict["rate"] as? Double else {
                    logger.warning("Failed to parse tax rate from dict")
                    return nil
                }
                let isDefault = taxRateDict["is_default"] as? Bool ?? false
                logger.info("Parsed tax rate: \(name) - \(rate)%")
                return SettingsTaxRate(id: id, name: name, rate: rate, isDefault: isDefault)
            }
            logger.debug("Merged tax rates: \(merged.taxRates.count)")
        } else {
            logger.warning("No tax_rates found in updates or wrong type")
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

    // MARK: - Auth User Deletion

    /// Delete auth user via Edge Function
    private func deleteAuthUser(userId: UUID, client: SupabaseClient) async throws {
        struct DeleteUserRequest: Encodable {
            let userId: String
        }

        struct DeleteUserResponse: Decodable {
            let success: Bool
            let message: String?
            let error: String?
        }

        let request = DeleteUserRequest(userId: userId.uuidString)

        // Get Supabase configuration from Config.plist
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: configPath),
              let supabaseURLString = config["SUPABASE_URL"] as? String,
              let anonKey = config["SUPABASE_ANON_KEY"] as? String else {
            throw NSError(
                domain: "SettingsRepository",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Supabase configuration not available"]
            )
        }

        // Build the Edge Function URL
        let functionUrl = "\(supabaseURLString)/functions/v1/delete-auth-user"

        guard let url = URL(string: functionUrl) else {
            throw NSError(
                domain: "SettingsRepository",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid Edge Function URL"]
            )
        }

        // Get the auth token
        guard let session = try? await client.auth.session else {
            throw NSError(
                domain: "SettingsRepository",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "No active session"]
            )
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(anonKey, forHTTPHeaderField: "apikey")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "SettingsRepository",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response from Edge Function"]
            )
        }

        if httpResponse.statusCode != 200 {
            let decoder = JSONDecoder()
            if let errorResponse = try? decoder.decode(DeleteUserResponse.self, from: data) {
                throw NSError(
                    domain: "SettingsRepository",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorResponse.error ?? "Unknown error"]
                )
            } else {
                throw NSError(
                    domain: "SettingsRepository",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to delete auth user: HTTP \(httpResponse.statusCode)"]
                )
            }
        }

        logger.debug("Auth user deletion Edge Function returned success")
    }
}
