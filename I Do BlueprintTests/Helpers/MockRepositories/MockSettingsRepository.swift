//
//  MockSettingsRepository.swift
//  I Do BlueprintTests
//
//  Mock implementation of SettingsRepositoryProtocol for testing
//

import Foundation
@testable import I_Do_Blueprint

class MockSettingsRepository: SettingsRepositoryProtocol {
    var settings: CoupleSettings = CoupleSettings.makeTest()
    var customVendorCategories: [CustomVendorCategory] = []
    var shouldThrowError = false
    var errorToThrow: SettingsError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchSettings() async throws -> CoupleSettings {
        if shouldThrowError { throw errorToThrow }
        return settings
    }

    func updateSettings(_ partialSettings: [String: Any]) async throws -> CoupleSettings {
        if shouldThrowError { throw errorToThrow }
        return settings
    }

    func updateGlobalSettings(_ newSettings: GlobalSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.global = newSettings
    }

    func updateThemeSettings(_ newSettings: ThemeSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.theme = newSettings
    }

    func updateBudgetSettings(_ newSettings: BudgetSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.budget = newSettings
    }

    func updateCashFlowSettings(_ newSettings: CashFlowSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.cashFlow = newSettings
    }

    func updateTasksSettings(_ newSettings: TasksSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.tasks = newSettings
    }

    func updateVendorsSettings(_ newSettings: VendorsSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.vendors = newSettings
    }

    func updateGuestsSettings(_ newSettings: GuestsSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.guests = newSettings
    }

    func updateDocumentsSettings(_ newSettings: DocumentsSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.documents = newSettings
    }

    func updateNotificationsSettings(_ newSettings: NotificationsSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.notifications = newSettings
    }

    func updateLinksSettings(_ newSettings: LinksSettings) async throws {
        if shouldThrowError { throw errorToThrow }
        settings.links = newSettings
    }

    func fetchCustomVendorCategories() async throws -> [CustomVendorCategory] {
        if shouldThrowError { throw errorToThrow }
        return customVendorCategories
    }

    func createVendorCategory(_ category: CustomVendorCategory) async throws -> CustomVendorCategory {
        if shouldThrowError { throw errorToThrow }
        customVendorCategories.append(category)
        return category
    }

    func createCustomVendorCategory(name: String, description: String?, typicalBudgetPercentage: String?) async throws -> CustomVendorCategory {
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

    func updateVendorCategory(_ category: CustomVendorCategory) async throws -> CustomVendorCategory {
        if shouldThrowError { throw errorToThrow }
        if let index = customVendorCategories.firstIndex(where: { $0.id == category.id }) {
            customVendorCategories[index] = category
        }
        return category
    }

    func updateCustomVendorCategory(id: String, name: String?, description: String?, typicalBudgetPercentage: String?) async throws -> CustomVendorCategory {
        if shouldThrowError { throw errorToThrow }
        guard let index = customVendorCategories.firstIndex(where: { $0.id == id }) else {
            throw errorToThrow
        }
        var category = customVendorCategories[index]
        if let name = name { category.name = name }
        if let description = description { category.description = description }
        if let typicalBudgetPercentage = typicalBudgetPercentage {
            category.typicalBudgetPercentage = typicalBudgetPercentage
        }
        customVendorCategories[index] = category
        return category
    }

    func deleteVendorCategory(id: String) async throws {
        if shouldThrowError { throw errorToThrow }
        customVendorCategories.removeAll(where: { $0.id == id })
    }

    func deleteCustomVendorCategory(id: String) async throws {
        if shouldThrowError { throw errorToThrow }
        customVendorCategories.removeAll(where: { $0.id == id })
    }

    func checkVendorsUsingCategory(categoryId: String) async throws -> [VendorUsingCategory] {
        if shouldThrowError { throw errorToThrow }
        return []
    }

    func formatPhoneNumbers() async throws -> PhoneFormatResult {
        if shouldThrowError { throw errorToThrow }
        return PhoneFormatResult(message: "Success", vendors: nil, contacts: nil)
    }

    func resetData(keepBudgetSandbox: Bool, keepAffordability: Bool, keepCategories: Bool) async throws {
        if shouldThrowError { throw errorToThrow }
    }
}
