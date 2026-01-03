//
//  SettingsStoreV2.swift
//  My Wedding Planning App
//
//  New architecture version of settings management using repository pattern
//  Refactored with Store Composition Pattern
//

import Auth
import Combine
import Dependencies
import Foundation
import SwiftUI
import Sentry

@MainActor
class SettingsStoreV2: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var settings: CoupleSettings = .default
    @Published var localSettings: CoupleSettings = .default
    @Published private(set) var customVendorCategories: [CustomVendorCategory] = []
    
    @Published var isLoading = false
    @Published private(set) var hasLoaded = false
    @Published var error: SettingsError?
    @Published var successMessage: String?
    @Published var savingSections: Set<String> = []
    @Published var hasUnsavedChanges = false
    
    // MARK: - Sub-Stores
    
    private(set) lazy var vendorCategoryStore: VendorCategoryStore = {
        VendorCategoryStore(
            repository: repository,
            onSuccess: { [weak self] message in
                self?.showSuccess(message)
            },
            onError: { [weak self] error, operation in
                Task { @MainActor in
                    await self?.handleError(error, operation: operation)
                }
            }
        )
    }()
    
    // MARK: - Private Properties
    
    private let repository: any SettingsRepositoryProtocol
    private lazy var loadingService = SettingsLoadingService(repository: repository)
    private var loadTask: Task<Void, Never>?
    private var categoriesFetchCompleted = false
    
    // MARK: - Initialization
    
    init(repository: (any SettingsRepositoryProtocol)? = nil) {
        self.repository = repository ?? LiveSettingsRepository()
    }
    
    // MARK: - Helper Properties
    
    var coupleId: UUID? {
        SupabaseManager.shared.currentUser?.id
    }
    
    // MARK: - Load Settings
    
    func loadSettings(force: Bool = false) async {
        // Avoid duplicate concurrent loads unless forced
        if isLoading && !force { return }
        // Allow reloading if forced or if not already loaded
        if !force && hasLoaded { return }
        
        // Cancel any previous load task when forcing
        if force { loadTask?.cancel() }
        
        // Create new load task
        loadTask = Task { @MainActor in
            AppLogger.ui.info("SettingsStoreV2.loadSettings: Starting to load settings (force: \(force))")
            isLoading = true
            error = nil
            categoriesFetchCompleted = false
            
            do {
                try Task.checkCancellation()
                
                // Fetch base settings first and mark store as loaded for UI responsiveness
                let fetchedSettings = try await loadingService.loadSettings()
                try Task.checkCancellation()
                
                settings = fetchedSettings
                localSettings = fetchedSettings
                hasUnsavedChanges = false
                hasLoaded = true
                error = nil
                
                AppLogger.ui.info("SettingsStoreV2.loadSettings: Settings base loaded; fetching categories in background…")
                
                // Fetch categories without blocking
                Task { @MainActor in
                    let categories = await loadingService.loadCategoriesWithRetry()
                    self.customVendorCategories = categories
                    self.vendorCategoryStore.categories = categories
                    self.categoriesFetchCompleted = true
                }
                
                // Watchdog: log if categories still not loaded after 5s
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    if self.customVendorCategories.isEmpty && !self.categoriesFetchCompleted {
                        AppLogger.ui.warning("SettingsStoreV2.loadSettings: Categories still pending after 5s")
                        SentryService.shared.captureMessage("settings.categories.pending_5s", level: .info)
                    }
                }
            } catch is CancellationError {
                AppLogger.ui.debug("SettingsStoreV2.loadSettings: Load cancelled (expected during navigation)")
            } catch let error as URLError where error.code == .cancelled {
                AppLogger.ui.debug("SettingsStoreV2.loadSettings: Load cancelled (URLError)")
            } catch let error as URLError where error.code == .notConnectedToInternet {
                self.error = .networkUnavailable
                settings = .default
                hasLoaded = false
                AppLogger.ui.error("SettingsStoreV2.loadSettings: Network unavailable")
                ErrorHandler.shared.handle(
                    error,
                    context: ErrorContext(operation: "loadSettings", feature: "settings", metadata: ["reason": "notConnectedToInternet"])
                )
            } catch {
                self.error = .fetchFailed(underlying: error)
                settings = .default
                hasLoaded = false
                AppLogger.ui.error("SettingsStoreV2.loadSettings: Failed to fetch settings: \(error)")
                ErrorHandler.shared.handle(
                    error,
                    context: ErrorContext(operation: "loadSettings", feature: "settings")
                )
            }
            
            isLoading = false
        }
        
        await loadTask?.value
    }
    
    func refreshSettings() async {
        await loadSettings(force: true)
    }
    
    // MARK: - Update Individual Sections
    
    func saveGlobalSettings() async {
        await saveSetting(
            section: "global",
            getValue: { self.settings.global },
            setValue: { self.settings.global = $0 },
            localValue: localSettings.global,
            saveOperation: { try await self.repository.updateGlobalSettings($0) }
        )
    }
    
    func saveThemeSettings() async {
        await saveSetting(
            section: "theme",
            getValue: { self.settings.theme },
            setValue: { self.settings.theme = $0 },
            localValue: localSettings.theme,
            saveOperation: { try await self.repository.updateThemeSettings($0) }
        )

        // Notify ThemeManager to update all views with new theme
        let newTheme = AppTheme(from: localSettings.theme.colorScheme)
        ThemeManager.shared.setTheme(newTheme, animated: true)
    }
    
    func saveBudgetSettings() async {
        savingSections.insert("budget")
        defer { savingSections.remove("budget") }
        
        let originalBudget = settings.budget
        let originalCashFlow = settings.cashFlow
        settings.budget = localSettings.budget
        settings.cashFlow = localSettings.cashFlow
        
        do {
            try await repository.updateBudgetSettings(localSettings.budget)
            try await repository.updateCashFlowSettings(localSettings.cashFlow)
            checkUnsavedChanges()
            successMessage = "Budget settings updated"
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings.budget = originalBudget
            settings.cashFlow = originalCashFlow
            self.error = .networkUnavailable
            await handleError(error, operation: "saveBudgetSettings")
        } catch {
            settings.budget = originalBudget
            settings.cashFlow = originalCashFlow
            self.error = .updateFailed(underlying: error)
            await handleError(error, operation: "saveBudgetSettings")
        }
    }
    
    func saveTasksSettings() async {
        await saveSetting(
            section: "tasks",
            getValue: { self.settings.tasks },
            setValue: { self.settings.tasks = $0 },
            localValue: localSettings.tasks,
            saveOperation: { try await self.repository.updateTasksSettings($0) }
        )
    }
    
    func saveVendorsSettings() async {
        await saveSetting(
            section: "vendors",
            getValue: { self.settings.vendors },
            setValue: { self.settings.vendors = $0 },
            localValue: localSettings.vendors,
            saveOperation: { try await self.repository.updateVendorsSettings($0) }
        )
    }
    
    func saveGuestsSettings() async {
        await saveSetting(
            section: "guests",
            getValue: { self.settings.guests },
            setValue: { self.settings.guests = $0 },
            localValue: localSettings.guests,
            saveOperation: { try await self.repository.updateGuestsSettings($0) }
        )
    }
    
    func saveDocumentsSettings() async {
        await saveSetting(
            section: "documents",
            getValue: { self.settings.documents },
            setValue: { self.settings.documents = $0 },
            localValue: localSettings.documents,
            saveOperation: { try await self.repository.updateDocumentsSettings($0) }
        )
    }
    
    func saveNotificationsSettings() async {
        await saveSetting(
            section: "notifications",
            getValue: { self.settings.notifications },
            setValue: { self.settings.notifications = $0 },
            localValue: localSettings.notifications,
            saveOperation: { try await self.repository.updateNotificationsSettings($0) }
        )
    }
    
    func saveLinksSettings() async {
        await saveSetting(
            section: "links",
            getValue: { self.settings.links },
            setValue: { self.settings.links = $0 },
            localValue: localSettings.links,
            saveOperation: { try await self.repository.updateLinksSettings($0) }
        )
    }
    
    // MARK: - Generic Save Helper
    
    private func saveSetting<T>(
        section: String,
        getValue: () -> T,
        setValue: (T) -> Void,
        localValue: T,
        saveOperation: (T) async throws -> Void
    ) async {
        savingSections.insert(section)
        defer { savingSections.remove(section) }
        
        let original = getValue()
        setValue(localValue)
        
        do {
            try await saveOperation(localValue)
            checkUnsavedChanges()
            successMessage = "\(section.capitalized) settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            setValue(original)
            self.error = .networkUnavailable
            await handleError(error, operation: "save\(section.capitalized)Settings")
        } catch {
            setValue(original)
            self.error = .updateFailed(underlying: error)
            await handleError(error, operation: "save\(section.capitalized)Settings")
        }
    }
    
    // MARK: - Legacy Update Methods (for compatibility)
    
    func updateGlobalSettings(_ newSettings: GlobalSettings) async {
        await updateSetting(\.global, newSettings, "Global", repository.updateGlobalSettings)
    }
    
    func updateThemeSettings(_ newSettings: ThemeSettings) async {
        await updateSetting(\.theme, newSettings, "Theme", repository.updateThemeSettings)
    }
    
    func updateBudgetSettings(_ newSettings: BudgetSettings) async {
        await updateSetting(\.budget, newSettings, "Budget", repository.updateBudgetSettings)
    }
    
    func updateCashFlowSettings(_ newSettings: CashFlowSettings) async {
        await updateSetting(\.cashFlow, newSettings, "Cash flow", repository.updateCashFlowSettings)
    }
    
    func updateTasksSettings(_ newSettings: TasksSettings) async {
        await updateSetting(\.tasks, newSettings, "Tasks", repository.updateTasksSettings)
    }
    
    func updateVendorsSettings(_ newSettings: VendorsSettings) async {
        await updateSetting(\.vendors, newSettings, "Vendors", repository.updateVendorsSettings)
    }
    
    func updateGuestsSettings(_ newSettings: GuestsSettings) async {
        await updateSetting(\.guests, newSettings, "Guests", repository.updateGuestsSettings)
    }
    
    func updateDocumentsSettings(_ newSettings: DocumentsSettings) async {
        await updateSetting(\.documents, newSettings, "Documents", repository.updateDocumentsSettings)
    }
    
    func updateNotificationsSettings(_ newSettings: NotificationsSettings) async {
        await updateSetting(\.notifications, newSettings, "Notifications", repository.updateNotificationsSettings)
    }
    
    func updateLinksSettings(_ newSettings: LinksSettings) async {
        await updateSetting(\.links, newSettings, "Links", repository.updateLinksSettings)
    }
    
    private func updateSetting<T>(_ keyPath: WritableKeyPath<CoupleSettings, T>, _ newValue: T, _ name: String, _ save: (T) async throws -> Void) async {
        let original = settings[keyPath: keyPath]
        settings[keyPath: keyPath] = newValue
        do {
            try await save(newValue)
            successMessage = "\(name) settings updated"
        } catch let error as URLError where error.code == .notConnectedToInternet {
            settings[keyPath: keyPath] = original
            self.error = .networkUnavailable
        } catch {
            settings[keyPath: keyPath] = original
            self.error = .updateFailed(underlying: error)
        }
    }
    
    // MARK: - Custom Vendor Categories (Delegated to VendorCategoryStore)
    
    func createVendorCategory(_ category: CustomVendorCategory) async {
        await vendorCategoryStore.createCategory(category)
        customVendorCategories = vendorCategoryStore.categories
    }
    
    func updateVendorCategory(_ category: CustomVendorCategory) async {
        await vendorCategoryStore.updateCategory(category)
        customVendorCategories = vendorCategoryStore.categories
    }
    
    func deleteVendorCategory(_ category: CustomVendorCategory) async {
        await vendorCategoryStore.deleteCategory(category)
        customVendorCategories = vendorCategoryStore.categories
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
    }
    
    func deleteCustomCategory(id: String) async throws {
        guard let category = customVendorCategories.first(where: { $0.id == id }) else { return }
        await deleteVendorCategory(category)
        if let error = error {
            AppLogger.ui.error("Failed to delete custom category", error: error)
            SentryService.shared.captureError(error, context: [
                "operation": "deleteCustomCategory",
                "categoryId": id
            ])
            throw error
        }
    }
    
    func checkVendorsUsingCategory(categoryId: String) async throws -> [VendorUsingCategory] {
        try await vendorCategoryStore.checkVendorsUsingCategory(categoryId: categoryId)
    }
    
    // MARK: - Data Management
    
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
    
    // MARK: - Account Deletion
    
    /// Delete the entire user account and all associated data
    ///
    /// This is a destructive operation that:
    /// 1. Deletes all wedding planning data
    /// 2. Deletes couple profile and memberships
    /// 3. Deletes settings and onboarding progress
    /// 4. Signs the user out
    /// 5. Clears all local caches
    ///
    /// - Warning: This is irreversible. All data will be permanently deleted.
    /// - Throws: SettingsError.accountDeletionFailed if deletion fails
    func deleteAccount() async throws {
        AppLogger.ui.info("SettingsStoreV2: Starting account deletion")
        
        do {
            try await repository.deleteAccount()
            AppLogger.ui.info("SettingsStoreV2: Account deletion completed")
            
            // Track deletion event for audit trail
            SentryService.shared.trackAction(
                "account_deleted",
                category: "account",
                metadata: ["timestamp": Date().ISO8601Format()]
            )
            
        } catch {
            AppLogger.ui.error("SettingsStoreV2: Account deletion failed", error: error)
            SentryService.shared.captureError(error, context: [
                "operation": "deleteAccount"
            ])
            throw error
        }
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
    
    // MARK: - Helper Methods
    
    private func showSuccess(_ message: String) {
        successMessage = message
    }
    
    private func handleError(_ error: Error, operation: String) async {
        AppLogger.ui.error("SettingsStoreV2: Failed to \(operation)", error: error)
        ErrorHandler.shared.handle(error, context: ErrorContext(operation: operation, feature: "settings"))
    }
}
