//
//  MockSettingsRepository.swift
//  My Wedding Planning App
//
//  Mock implementation for testing
//

import Foundation

@MainActor
class MockSettingsRepository: SettingsRepositoryProtocol {
    // Storage
    var coupleSettings: CoupleSettings = .default
    var customVendorCategories: [CustomVendorCategory] = []

    // Error control
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: -1)

    // Call tracking
    var fetchSettingsCalled = false
    var updateSettingsCalled = false
    var updateGlobalSettingsCalled = false
    var updateThemeSettingsCalled = false
    var updateBudgetSettingsCalled = false
    var fetchVendorCategoriesCalled = false
    var createVendorCategoryCalled = false
    var updateVendorCategoryCalled = false
    var deleteVendorCategoryCalled = false
    var deleteAccountCalled = false

    // Delay simulation
    var delay: TimeInterval = 0

    // MARK: - Settings CRUD

    func fetchSettings() async throws -> CoupleSettings {
        fetchSettingsCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return coupleSettings
    }

    func updateSettings(_ partialSettings: [String: Any]) async throws -> CoupleSettings {
        updateSettingsCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        // Simple mock: just return current settings
        // Real implementation would merge partialSettings into coupleSettings
        return coupleSettings
    }

    // MARK: - Granular Settings Updates

    func updateGlobalSettings(_ settings: GlobalSettings) async throws {
        updateGlobalSettingsCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        coupleSettings.global = settings
    }

    func updateThemeSettings(_ settings: ThemeSettings) async throws {
        updateThemeSettingsCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        coupleSettings.theme = settings
    }

    func updateBudgetSettings(_ settings: BudgetSettings) async throws {
        updateBudgetSettingsCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        coupleSettings.budget = settings
    }

    func updateCashFlowSettings(_ settings: CashFlowSettings) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        coupleSettings.cashFlow = settings
    }

    func updateTasksSettings(_ settings: TasksSettings) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        coupleSettings.tasks = settings
    }

    func updateVendorsSettings(_ settings: VendorsSettings) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        coupleSettings.vendors = settings
    }

    func updateGuestsSettings(_ settings: GuestsSettings) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        coupleSettings.guests = settings
    }

    func updateDocumentsSettings(_ settings: DocumentsSettings) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        coupleSettings.documents = settings
    }

    func updateNotificationsSettings(_ settings: NotificationsSettings) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        coupleSettings.notifications = settings
    }

    func updateLinksSettings(_ settings: LinksSettings) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        coupleSettings.links = settings
    }

    // MARK: - Custom Vendor Categories

    func fetchCustomVendorCategories() async throws -> [CustomVendorCategory] {
        fetchVendorCategoriesCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return customVendorCategories
    }

    func createVendorCategory(_ category: CustomVendorCategory) async throws -> CustomVendorCategory {
        createVendorCategoryCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        customVendorCategories.append(category)
        return category
    }

    func createCustomVendorCategory(name: String, description: String?, typicalBudgetPercentage: String?) async throws -> CustomVendorCategory {
        createVendorCategoryCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }

        let category = CustomVendorCategory(
            id: UUID().uuidString,
            coupleId: UUID().uuidString,
            name: name,
            description: description,
            typicalBudgetPercentage: typicalBudgetPercentage,
            createdAt: Date(),
            updatedAt: Date()
        )
        customVendorCategories.append(category)
        return category
    }

    func updateCustomVendorCategory(id: String, name: String?, description: String?, typicalBudgetPercentage: String?) async throws -> CustomVendorCategory {
        updateVendorCategoryCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }

        guard let index = customVendorCategories.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "test", code: 404)
        }

        var updated = customVendorCategories[index]
        if let name = name {
            updated.name = name
        }
        updated.description = description
        updated.typicalBudgetPercentage = typicalBudgetPercentage
        updated.updatedAt = Date()

        customVendorCategories[index] = updated
        return updated
    }

    func updateVendorCategory(_ category: CustomVendorCategory) async throws -> CustomVendorCategory {
        updateVendorCategoryCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }

        guard let index = customVendorCategories.firstIndex(where: { $0.id == category.id }) else {
            throw NSError(domain: "test", code: 404)
        }

        customVendorCategories[index] = category
        return category
    }

    func deleteVendorCategory(id: String) async throws {
        deleteVendorCategoryCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        customVendorCategories.removeAll { $0.id == id }
    }

    func deleteCustomVendorCategory(id: String) async throws {
        deleteVendorCategoryCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        customVendorCategories.removeAll { $0.id == id }
    }

    func checkVendorsUsingCategory(categoryId: String) async throws -> [VendorUsingCategory] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return []
    }

    // MARK: - Utility Operations

    func formatPhoneNumbers() async throws -> PhoneFormatResult {
        if shouldThrowError { throw errorToThrow }
        return PhoneFormatResult(
            message: "Phone numbers formatted",
            vendors: nil,
            contacts: nil
        )
    }

    func resetData(keepBudgetSandbox: Bool, keepAffordability: Bool, keepCategories: Bool) async throws {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        // Reset mock data
        coupleSettings = .default
        if !keepCategories {
            customVendorCategories = []
        }
    }

    // MARK: - Account Deletion

    func deleteAccount() async throws {
        deleteAccountCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        // Mock: Reset all data to simulate account deletion
        coupleSettings = .default
        customVendorCategories = []
    }

    // MARK: - Testing Utilities

    /// Reset all call tracking flags
    func resetFlags() {
        fetchSettingsCalled = false
        updateSettingsCalled = false
        updateGlobalSettingsCalled = false
        updateThemeSettingsCalled = false
        updateBudgetSettingsCalled = false
        fetchVendorCategoriesCalled = false
        createVendorCategoryCalled = false
        updateVendorCategoryCalled = false
        deleteVendorCategoryCalled = false
        deleteAccountCalled = false
    }

    /// Reset all data to defaults
    func resetAllData() {
        coupleSettings = .default
        customVendorCategories = []
        resetFlags()
    }
}
