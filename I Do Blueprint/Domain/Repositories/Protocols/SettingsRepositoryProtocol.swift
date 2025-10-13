//
//  SettingsRepositoryProtocol.swift
//  My Wedding Planning App
//
//  Repository protocol for settings management
//

import Dependencies
import Foundation

protocol SettingsRepositoryProtocol: Sendable {
    // MARK: - Settings CRUD

    func fetchSettings() async throws -> CoupleSettings
    func updateSettings(_ partialSettings: [String: Any]) async throws -> CoupleSettings

    // MARK: - Granular Settings Updates

    func updateGlobalSettings(_ settings: GlobalSettings) async throws
    func updateThemeSettings(_ settings: ThemeSettings) async throws
    func updateBudgetSettings(_ settings: BudgetSettings) async throws
    func updateCashFlowSettings(_ settings: CashFlowSettings) async throws
    func updateTasksSettings(_ settings: TasksSettings) async throws
    func updateVendorsSettings(_ settings: VendorsSettings) async throws
    func updateGuestsSettings(_ settings: GuestsSettings) async throws
    func updateDocumentsSettings(_ settings: DocumentsSettings) async throws
    func updateNotificationsSettings(_ settings: NotificationsSettings) async throws
    func updateLinksSettings(_ settings: LinksSettings) async throws

    // MARK: - Custom Vendor Categories

    func fetchCustomVendorCategories() async throws -> [CustomVendorCategory]
    func createVendorCategory(_ category: CustomVendorCategory) async throws -> CustomVendorCategory
    func createCustomVendorCategory(name: String, description: String?, typicalBudgetPercentage: String?) async throws -> CustomVendorCategory
    func updateVendorCategory(_ category: CustomVendorCategory) async throws -> CustomVendorCategory
    func updateCustomVendorCategory(id: String, name: String?, description: String?, typicalBudgetPercentage: String?) async throws -> CustomVendorCategory
    func deleteVendorCategory(id: String) async throws
    func deleteCustomVendorCategory(id: String) async throws
    func checkVendorsUsingCategory(categoryId: String) async throws -> [VendorUsingCategory]

    // MARK: - Utility Operations

    func formatPhoneNumbers() async throws -> PhoneFormatResult
    func resetData(keepBudgetSandbox: Bool, keepAffordability: Bool, keepCategories: Bool) async throws
}
