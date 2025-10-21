//
//  SettingsStoreV2.swift
//  My Wedding Planning App
//
//  New architecture version of settings management using repository pattern
//

import Auth
import Combine
import Dependencies
import Foundation
import SwiftUI

@MainActor
class SettingsStoreV2: ObservableObject {
    @Published private(set) var settings: CoupleSettings = .default
    @Published var localSettings: CoupleSettings = .default
    @Published private(set) var customVendorCategories: [CustomVendorCategory] = []

    @Published var isLoading = false
    @Published private(set) var hasLoaded = false
    @Published var error: SettingsError?
    @Published var successMessage: String?
    @Published var savingSections: Set<String> = []
    @Published var hasUnsavedChanges = false

    private let repository: any SettingsRepositoryProtocol

    init(repository: (any SettingsRepositoryProtocol)? = nil) {
        self.repository = repository ?? LiveSettingsRepository()
    }

    // MARK: - Helper Properties

    var coupleId: UUID? {
        SupabaseManager.shared.currentUser?.id
    }

    // MARK: - Load Settings

    func loadSettings() async {
        guard !hasLoaded else {
            return
        }
        
        AppLogger.ui.info("SettingsStoreV2.loadSettings: Starting to load settings")
        isLoading = true
        error = nil

        do {
            async let settingsResult = repository.fetchSettings()
            async let categoriesResult = repository.fetchCustomVendorCategories()

            settings = try await settingsResult
            localSettings = settings
            customVendorCategories = try await categoriesResult
            hasUnsavedChanges = false
            hasLoaded = true

            AppLogger.ui.info("SettingsStoreV2.loadSettings: Settings loaded successfully")
            AppLogger.ui.info("SettingsStoreV2: Wedding date from loaded settings: '\(settings.global.weddingDate)'")
        } catch let error as URLError where error.code == .notConnectedToInternet {
            self.error = .networkUnavailable
            settings = .default
            AppLogger.ui.error("SettingsStoreV2.loadSettings: Network unavailable")
        } catch {
            self.error = .fetchFailed(underlying: error)
            settings = .default
            AppLogger.ui.error("SettingsStoreV2.loadSettings: Failed to fetch settings: \(error)")
        }

        isLoading = false
    }

    func refreshSettings() async {
        await loadSettings()
    }

    // MARK: - Update Individual Sections

    func saveGlobalSettings() async {
        savingSections.insert("global")
        let original = settings.global

        do {
            let payload: [String: Any] = [
                "global": [
                    "currency": localSettings.global.currency,
                    "wedding_date": localSettings.global.weddingDate,
                    "timezone": localSettings.global.timezone,
                    "partner1_full_name": localSettings.global.partner1FullName,
                    "partner1_nickname": localSettings.global.partner1Nickname,
                    "partner2_full_name": localSettings.global.partner2FullName,
                    "partner2_nickname": localSettings.global.partner2Nickname
                ]
            ]

            let updated = try await repository.updateSettings(payload)
            settings = updated
            localSettings = updated
            checkUnsavedChanges()
            successMessage = "Global settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.global = original
            self.error = .networkUnavailable
        } catch {
            settings.global = original
            self.error = .updateFailed(underlying: error)
        }

        savingSections.remove("global")
    }

    func updateGlobalSettings(_ newSettings: GlobalSettings) async {
        let original = settings.global
        settings.global = newSettings

        do {
            try await repository.updateGlobalSettings(newSettings)
            localSettings.global = newSettings
            checkUnsavedChanges()
            successMessage = "Global settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.global = original
            self.error = .networkUnavailable
        } catch {
            settings.global = original
            self.error = .updateFailed(underlying: error)
        }
    }

    func saveThemeSettings() async {
        savingSections.insert("theme")
        let original = settings.theme
        settings.theme = localSettings.theme

        do {
            try await repository.updateThemeSettings(localSettings.theme)
            checkUnsavedChanges()
            successMessage = "Theme settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.theme = original
            self.error = .networkUnavailable
        } catch {
            settings.theme = original
            self.error = .updateFailed(underlying: error)
        }

        savingSections.remove("theme")
    }

    func saveBudgetSettings() async {
        savingSections.insert("budget")
        let originalBudget = settings.budget
        let originalCashFlow = settings.cashFlow
        settings.budget = localSettings.budget
        settings.cashFlow = localSettings.cashFlow

        do {
            try await repository.updateBudgetSettings(localSettings.budget)
            try await repository.updateCashFlowSettings(localSettings.cashFlow)
            checkUnsavedChanges()
            successMessage = "Budget settings updated"
            
            // Notify other parts of the app that settings have changed
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.budget = originalBudget
            settings.cashFlow = originalCashFlow
            self.error = .networkUnavailable
        } catch {
            settings.budget = originalBudget
            settings.cashFlow = originalCashFlow
            self.error = .updateFailed(underlying: error)
        }

        savingSections.remove("budget")
    }

    func saveTasksSettings() async {
        savingSections.insert("tasks")
        let original = settings.tasks
        settings.tasks = localSettings.tasks

        do {
            try await repository.updateTasksSettings(localSettings.tasks)
            checkUnsavedChanges()
            successMessage = "Tasks settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.tasks = original
            self.error = .networkUnavailable
        } catch {
            settings.tasks = original
            self.error = .updateFailed(underlying: error)
        }

        savingSections.remove("tasks")
    }

    func saveVendorsSettings() async {
        savingSections.insert("vendors")
        let original = settings.vendors
        settings.vendors = localSettings.vendors

        do {
            try await repository.updateVendorsSettings(localSettings.vendors)
            checkUnsavedChanges()
            successMessage = "Vendors settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.vendors = original
            self.error = .networkUnavailable
        } catch {
            settings.vendors = original
            self.error = .updateFailed(underlying: error)
        }

        savingSections.remove("vendors")
    }

    func saveGuestsSettings() async {
        savingSections.insert("guests")
        let original = settings.guests
        settings.guests = localSettings.guests

        do {
            try await repository.updateGuestsSettings(localSettings.guests)
            checkUnsavedChanges()
            successMessage = "Guests settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.guests = original
            self.error = .networkUnavailable
        } catch {
            settings.guests = original
            self.error = .updateFailed(underlying: error)
        }

        savingSections.remove("guests")
    }

    func saveDocumentsSettings() async {
        savingSections.insert("documents")
        let original = settings.documents
        settings.documents = localSettings.documents

        do {
            try await repository.updateDocumentsSettings(localSettings.documents)
            checkUnsavedChanges()
            successMessage = "Documents settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.documents = original
            self.error = .networkUnavailable
        } catch {
            settings.documents = original
            self.error = .updateFailed(underlying: error)
        }

        savingSections.remove("documents")
    }

    func saveNotificationsSettings() async {
        savingSections.insert("notifications")
        let original = settings.notifications
        settings.notifications = localSettings.notifications

        do {
            try await repository.updateNotificationsSettings(localSettings.notifications)
            checkUnsavedChanges()
            successMessage = "Notifications settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.notifications = original
            self.error = .networkUnavailable
        } catch {
            settings.notifications = original
            self.error = .updateFailed(underlying: error)
        }

        savingSections.remove("notifications")
    }

    func saveLinksSettings() async {
        savingSections.insert("links")
        let original = settings.links
        settings.links = localSettings.links

        do {
            try await repository.updateLinksSettings(localSettings.links)
            checkUnsavedChanges()
            successMessage = "Links settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.links = original
            self.error = .networkUnavailable
        } catch {
            settings.links = original
            self.error = .updateFailed(underlying: error)
        }

        savingSections.remove("links")
    }

    func updateThemeSettings(_ newSettings: ThemeSettings) async {
        let original = settings.theme
        settings.theme = newSettings

        do {
            try await repository.updateThemeSettings(newSettings)
            successMessage = "Theme settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.theme = original
            self.error = .networkUnavailable
        } catch {
            settings.theme = original
            self.error = .updateFailed(underlying: error)
        }
    }

    func updateBudgetSettings(_ newSettings: BudgetSettings) async {
        let original = settings.budget
        settings.budget = newSettings

        do {
            try await repository.updateBudgetSettings(newSettings)
            successMessage = "Budget settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.budget = original
            self.error = .networkUnavailable
        } catch {
            settings.budget = original
            self.error = .updateFailed(underlying: error)
        }
    }

    func updateCashFlowSettings(_ newSettings: CashFlowSettings) async {
        let original = settings.cashFlow
        settings.cashFlow = newSettings

        do {
            try await repository.updateCashFlowSettings(newSettings)
            successMessage = "Cash flow settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.cashFlow = original
            self.error = .networkUnavailable
        } catch {
            settings.cashFlow = original
            self.error = .updateFailed(underlying: error)
        }
    }

    func updateTasksSettings(_ newSettings: TasksSettings) async {
        let original = settings.tasks
        settings.tasks = newSettings

        do {
            try await repository.updateTasksSettings(newSettings)
            successMessage = "Tasks settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.tasks = original
            self.error = .networkUnavailable
        } catch {
            settings.tasks = original
            self.error = .updateFailed(underlying: error)
        }
    }

    func updateVendorsSettings(_ newSettings: VendorsSettings) async {
        let original = settings.vendors
        settings.vendors = newSettings

        do {
            try await repository.updateVendorsSettings(newSettings)
            successMessage = "Vendors settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.vendors = original
            self.error = .networkUnavailable
        } catch {
            settings.vendors = original
            self.error = .updateFailed(underlying: error)
        }
    }

    func updateGuestsSettings(_ newSettings: GuestsSettings) async {
        let original = settings.guests
        settings.guests = newSettings

        do {
            try await repository.updateGuestsSettings(newSettings)
            successMessage = "Guests settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.guests = original
            self.error = .networkUnavailable
        } catch {
            settings.guests = original
            self.error = .updateFailed(underlying: error)
        }
    }

    func updateDocumentsSettings(_ newSettings: DocumentsSettings) async {
        let original = settings.documents
        settings.documents = newSettings

        do {
            try await repository.updateDocumentsSettings(newSettings)
            successMessage = "Documents settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.documents = original
            self.error = .networkUnavailable
        } catch {
            settings.documents = original
            self.error = .updateFailed(underlying: error)
        }
    }

    func updateNotificationsSettings(_ newSettings: NotificationsSettings) async {
        let original = settings.notifications
        settings.notifications = newSettings

        do {
            try await repository.updateNotificationsSettings(newSettings)
            successMessage = "Notifications settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.notifications = original
            self.error = .networkUnavailable
        } catch {
            settings.notifications = original
            self.error = .updateFailed(underlying: error)
        }
    }

    func updateLinksSettings(_ newSettings: LinksSettings) async {
        let original = settings.links
        settings.links = newSettings

        do {
            try await repository.updateLinksSettings(newSettings)
            successMessage = "Links settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.links = original
            self.error = .networkUnavailable
        } catch {
            settings.links = original
            self.error = .updateFailed(underlying: error)
        }
    }

    // MARK: - Custom Vendor Categories

    func createVendorCategory(_ category: CustomVendorCategory) async {
        do {
            let created = try await repository.createVendorCategory(category)
            customVendorCategories.append(created)
            showSuccess("Category created successfully")
        } catch let error as URLError where error.code == .notConnectedToInternet {
            self.error = .networkUnavailable
            await handleError(error, operation: "create vendor category") { [weak self] in
                await self?.createVendorCategory(category)
            }
        } catch {
            self.error = .categoryCreateFailed(underlying: error)
            await handleError(error, operation: "create vendor category") { [weak self] in
                await self?.createVendorCategory(category)
            }
        }
    }

    func updateVendorCategory(_ category: CustomVendorCategory) async {
        guard let index = customVendorCategories.firstIndex(where: { $0.id == category.id }) else { return }
        let original = customVendorCategories[index]
        customVendorCategories[index] = category

        do {
            let updated = try await repository.updateVendorCategory(category)
            customVendorCategories[index] = updated
            showSuccess("Category updated successfully")
        } catch let error as URLError where error.code == .notConnectedToInternet {
            customVendorCategories[index] = original
            self.error = .networkUnavailable
            await handleError(error, operation: "update vendor category") { [weak self] in
                await self?.updateVendorCategory(category)
            }
        } catch {
            customVendorCategories[index] = original
            self.error = .categoryUpdateFailed(underlying: error)
            await handleError(error, operation: "update vendor category") { [weak self] in
                await self?.updateVendorCategory(category)
            }
        }
    }

    func deleteVendorCategory(_ category: CustomVendorCategory) async {
        guard let index = customVendorCategories.firstIndex(where: { $0.id == category.id }) else { return }
        let removed = customVendorCategories.remove(at: index)

        do {
            try await repository.deleteVendorCategory(id: category.id)
            showSuccess("Category deleted successfully")
        } catch let error as URLError where error.code == .notConnectedToInternet {
            customVendorCategories.insert(removed, at: index)
            self.error = .networkUnavailable
            await handleError(error, operation: "delete vendor category") { [weak self] in
                await self?.deleteVendorCategory(category)
            }
        } catch {
            customVendorCategories.insert(removed, at: index)
            self.error = .categoryDeleteFailed(underlying: error)
            await handleError(error, operation: "delete vendor category") { [weak self] in
                await self?.deleteVendorCategory(category)
            }
        }
    }

    // MARK: - Alternative Signatures for Compatibility

    func createCustomCategory(name: String, description: String?, typicalBudgetPercentage: String?) async {
        let category = CustomVendorCategory(
            id: UUID().uuidString,
            coupleId: UUID().uuidString,  // Will be set by repository
            name: name,
            description: description,
            typicalBudgetPercentage: typicalBudgetPercentage,
            createdAt: Date(),
            updatedAt: Date()
        )
        await createVendorCategory(category)
        customVendorCategories.sort { $0.name < $1.name }
    }

    func updateCustomCategory(id: String, name: String?, description: String?, typicalBudgetPercentage: String?) async {
        guard let index = customVendorCategories.firstIndex(where: { $0.id == id }) else { return }
        var category = customVendorCategories[index]

        if let name = name {
            category.name = name
        }
        category.description = description
        category.typicalBudgetPercentage = typicalBudgetPercentage

        await updateVendorCategory(category)
        customVendorCategories.sort { $0.name < $1.name }
    }

    func deleteCustomCategory(id: String) async throws {
        guard let category = customVendorCategories.first(where: { $0.id == id }) else { return }
        await deleteVendorCategory(category)
        if error != nil {
            throw error!
        }
    }

    func checkVendorsUsingCategory(categoryId: String) async throws -> [VendorUsingCategory] {
        try await repository.checkVendorsUsingCategory(categoryId: categoryId)
    }

    func resetData(keepBudgetSandbox: Bool, keepAffordability: Bool, keepCategories: Bool) async throws {
        try await repository.resetData(
            keepBudgetSandbox: keepBudgetSandbox,
            keepAffordability: keepAffordability,
            keepCategories: keepCategories
        )
    }

    func formatPhoneNumbers() async throws -> PhoneFormatResult {
        try await repository.formatPhoneNumbers()
    }

    // MARK: - Convenience Methods

    func clearSuccessMessage() {
        successMessage = nil
    }

    func clearError() {
        error = nil
    }

    func updateField<T>(_ keyPath: WritableKeyPath<CoupleSettings, T>, value: T) {
        localSettings[keyPath: keyPath] = value
        checkUnsavedChanges()
    }

    private func checkUnsavedChanges() {
        hasUnsavedChanges = localSettings != settings
    }

    func discardChanges() {
        localSettings = settings
        hasUnsavedChanges = false
    }

    func resetLoadedState() {
        hasLoaded = false
    }
}
