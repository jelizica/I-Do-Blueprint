//
//  SettingsViewModel.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import Auth
import Combine
import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var settings: CoupleSettings = .default
    @Published var localSettings: CoupleSettings = .default
    @Published var customCategories: [CustomVendorCategory] = []

    @Published var isLoading = false
    @Published var hasLoadedOnce = false
    @Published var isRefreshing = false
    @Published var isSaving = false
    @Published var error: SettingsError?
    @Published var successMessage: String?

    @Published var savingSections: Set<String> = []
    @Published var hasUnsavedChanges = false

    // MARK: - Dependencies

    let api: SettingsAPI
    private let logger = AppLogger.general

    init(api: SettingsAPI = SettingsAPI()) {
        self.api = api
    }

    // MARK: - Helper Properties

    var coupleId: UUID? {
        SupabaseManager.shared.currentUser?.id
    }

    // MARK: - Lifecycle

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        logger.debug("SettingsViewModel.load() started")

        do {
            // Fetch settings and custom categories in parallel
            async let settingsTask = api.fetchSettings()
            async let categoriesTask = api.fetchCustomVendorCategories()

            let (fetchedSettings, fetchedCategories) = try await (settingsTask, categoriesTask)

            logger.debug("Fetched settings - theme.darkMode: \(fetchedSettings.theme.darkMode)")

            settings = fetchedSettings
            localSettings = fetchedSettings
            customCategories = fetchedCategories
            hasUnsavedChanges = false
            hasLoadedOnce = true

            logger.info("Settings loaded successfully - theme.darkMode: \(settings.theme.darkMode)")
        } catch {
            logger.error("Failed to load settings", error: error)
            self.error = .fetchFailed(underlying: error)
            hasLoadedOnce = true
        }

        isLoading = false
        logger.debug("SettingsViewModel.load() completed")
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        error = nil

        do {
            let fetchedSettings = try await api.fetchSettings()
            settings = fetchedSettings
            localSettings = fetchedSettings
            hasUnsavedChanges = false
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isRefreshing = false
    }

    // MARK: - Section-Specific Saving

    func saveGlobalSettings() async {
        await saveSection(name: "global") {
            [
                "global": [
                    "currency": self.localSettings.global.currency,
                    "wedding_date": self.localSettings.global.weddingDate,
                    "timezone": self.localSettings.global.timezone,
                    "partner1_full_name": self.localSettings.global.partner1FullName,
                    "partner1_nickname": self.localSettings.global.partner1Nickname,
                    "partner2_full_name": self.localSettings.global.partner2FullName,
                    "partner2_nickname": self.localSettings.global.partner2Nickname,
                    "wedding_events": self.localSettings.global.weddingEvents.map { event in
                        [
                            "id": event.id,
                            "event_name": event.eventName,
                            "event_date": event.eventDate,
                            "event_time": event.eventTime,
                            "venue_location": event.venueLocation,
                            "description": event.description,
                            "is_main_event": event.isMainEvent,
                            "event_order": event.eventOrder
                        ]
                    }
                ]
            ]
        } updateLocal: {
            self.settings.global = self.localSettings.global
        }
    }

    func saveThemeSettings() async {
        logger.debug("Saving theme settings - darkMode: \(self.localSettings.theme.darkMode)")
        await saveSection(name: "theme") {
            [
                "theme": [
                    "color_scheme": self.localSettings.theme.colorScheme,
                    "dark_mode": self.localSettings.theme.darkMode
                ]
            ]
        } updateLocal: {
            logger.info("Theme settings saved successfully - darkMode: \(self.localSettings.theme.darkMode)")
            self.settings.theme = self.localSettings.theme
        }
    }

    func saveBudgetSettings() async {
        await saveSection(name: "budget") {
            [
                "budget": [
                    "total_budget": self.localSettings.budget.totalBudget,
                    "base_budget": self.localSettings.budget.baseBudget,
                    "includes_engagement_rings": self.localSettings.budget.includesEngagementRings,
                    "engagement_ring_amount": self.localSettings.budget.engagementRingAmount,
                    "auto_categorize": self.localSettings.budget.autoCategorize,
                    "payment_reminders": self.localSettings.budget.paymentReminders,
                    "notes": self.localSettings.budget.notes,
                    "tax_rates": self.localSettings.budget.taxRates.map { rate in
                        [
                            "id": rate.id,
                            "name": rate.name,
                            "rate": rate.rate,
                            "is_default": rate.isDefault
                        ]
                    }
                ],
                "cash_flow": [
                    "default_partner1_monthly": self.localSettings.cashFlow.defaultPartner1Monthly,
                    "default_partner2_monthly": self.localSettings.cashFlow.defaultPartner2Monthly,
                    "default_interest_monthly": self.localSettings.cashFlow.defaultInterestMonthly,
                    "default_gifts_monthly": self.localSettings.cashFlow.defaultGiftsMonthly
                ]
            ]
        } updateLocal: {
            self.settings.budget = self.localSettings.budget
            self.settings.cashFlow = self.localSettings.cashFlow
        }
    }

    func saveTasksSettings() async {
        await saveSection(name: "tasks") {
            [
                "tasks": [
                    "default_view": self.localSettings.tasks.defaultView,
                    "show_completed": self.localSettings.tasks.showCompleted,
                    "notifications_enabled": self.localSettings.tasks.notificationsEnabled,
                    "custom_responsible_parties": self.localSettings.tasks.customResponsibleParties ?? []
                ]
            ]
        } updateLocal: {
            self.settings.tasks = self.localSettings.tasks
        }
    }

    func saveVendorsSettings() async {
        await saveSection(name: "vendors") {
            [
                "vendors": [
                    "default_view": self.localSettings.vendors.defaultView,
                    "show_payment_status": self.localSettings.vendors.showPaymentStatus,
                    "auto_reminders": self.localSettings.vendors.autoReminders,
                    "hidden_standard_categories": self.localSettings.vendors.hiddenStandardCategories ?? []
                ]
            ]
        } updateLocal: {
            self.settings.vendors = self.localSettings.vendors
        }
    }

    func saveGuestsSettings() async {
        // Sanitize meal options before saving
        var sanitizedMealOptions = localSettings.guests.customMealOptions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) }
            .filter { !$0.isEmpty }

        // Remove duplicates (case-insensitive)
        var seen = Set<String>()
        sanitizedMealOptions = sanitizedMealOptions.filter { option in
            let lowercase = option.lowercased()
            if seen.contains(lowercase) {
                return false
            }
            seen.insert(lowercase)
            return true
        }

        // Title case
        sanitizedMealOptions = sanitizedMealOptions.map(\.localizedCapitalized)

        // Update local settings with sanitized options
        localSettings.guests.customMealOptions = sanitizedMealOptions

        await saveSection(name: "guests") {
            [
                "guests": [
                    "default_view": self.localSettings.guests.defaultView,
                    "show_meal_preferences": self.localSettings.guests.showMealPreferences,
                    "rsvp_reminders": self.localSettings.guests.rsvpReminders,
                    "custom_meal_options": sanitizedMealOptions
                ]
            ]
        } updateLocal: {
            self.settings.guests = self.localSettings.guests
        }
    }

    func saveDocumentsSettings() async {
        await saveSection(name: "documents") {
            [
                "documents": [
                    "auto_organize": self.localSettings.documents.autoOrganize,
                    "cloud_backup": self.localSettings.documents.cloudBackup,
                    "retention_days": self.localSettings.documents.retentionDays,
                    "vendor_behavior": [
                        "enforce_consistency": self.localSettings.documents.vendorBehavior.enforceConsistency,
                        "allow_inheritance": self.localSettings.documents.vendorBehavior.allowInheritance,
                        "prefer_expense_vendor": self.localSettings.documents.vendorBehavior.preferExpenseVendor,
                        "enable_validation_logging": self.localSettings.documents.vendorBehavior
                            .enableValidationLogging
                    ]
                ]
            ]
        } updateLocal: {
            self.settings.documents = self.localSettings.documents
        }
    }

    func saveNotificationsSettings() async {
        await saveSection(name: "notifications") {
            [
                "notifications": [
                    "email_enabled": self.localSettings.notifications.emailEnabled,
                    "push_enabled": self.localSettings.notifications.pushEnabled,
                    "digest_frequency": self.localSettings.notifications.digestFrequency
                ]
            ]
        } updateLocal: {
            self.settings.notifications = self.localSettings.notifications
        }
    }

    func saveLinksSettings() async {
        await saveSection(name: "links") {
            [
                "links": [
                    "important_links": self.localSettings.links.importantLinks.map { link in
                        [
                            "id": link.id,
                            "title": link.title,
                            "url": link.url,
                            "description": link.description as Any
                        ]
                    }
                ]
            ]
        } updateLocal: {
            self.settings.links = self.localSettings.links
        }
    }

    // MARK: - Helper Method

    private func saveSection(
        name: String,
        payload: () -> [String: Any],
        updateLocal: () -> Void) async {
        logger.debug("saveSection called for: \(name)")
        guard !savingSections.contains(name) else {
            logger.warning("Already saving \(name), skipping...")
            return
        }

        savingSections.insert(name)
        error = nil
        successMessage = nil

        do {
            let payloadData = payload()
            logger.debug("Payload: \(payloadData)")
            let updatedSettings = try await api.updateSettings(payloadData)
            logger.debug("API returned updated settings")
            updateLocal()
            logger.debug("Local settings updated")
            checkUnsavedChanges()
            successMessage = "\(name.capitalized) settings saved successfully"
            logger.info("Save completed successfully for: \(name)")

            // Clear success message after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if successMessage?.contains(name.capitalized) == true {
                successMessage = nil
            }
        } catch {
            logger.error("Error saving \(name)", error: error)
            self.error = .updateFailed(underlying: error)
        }

        savingSections.remove(name)
        logger.debug("Removed \(name) from savingSections")
    }

    // MARK: - Custom Vendor Categories

    func createCustomCategory(name: String, description: String?, typicalBudgetPercentage: String?) async {
        error = nil
        isSaving = true

        do {
            let newCategory = try await api.createCustomVendorCategory(
                name: name,
                description: description,
                typicalBudgetPercentage: typicalBudgetPercentage)
            customCategories.append(newCategory)
            customCategories.sort { $0.name < $1.name }
            successMessage = "Category '\(name)' created successfully"
        } catch {
            self.error = .categoryCreateFailed(underlying: error)
        }

        isSaving = false
    }

    func updateCustomCategory(id: String, name: String?, description: String?, typicalBudgetPercentage: String?) async {
        error = nil
        isSaving = true

        do {
            let updatedCategory = try await api.updateCustomVendorCategory(
                id: id,
                name: name,
                description: description,
                typicalBudgetPercentage: typicalBudgetPercentage)
            if let index = customCategories.firstIndex(where: { $0.id == id }) {
                customCategories[index] = updatedCategory
                customCategories.sort { $0.name < $1.name }
            }
            successMessage = "Category updated successfully"
        } catch {
            self.error = .categoryUpdateFailed(underlying: error)
        }

        isSaving = false
    }

    func deleteCustomCategory(id: String) async throws {
        error = nil
        isSaving = true

        do {
            try await api.deleteCustomVendorCategory(id: id)
            customCategories.removeAll { $0.id == id }
            successMessage = "Category deleted successfully"
        } catch {
            self.error = .categoryDeleteFailed(underlying: error)
            throw error
        }

        isSaving = false
    }

    func checkVendorsUsingCategory(categoryId: String) async throws -> [VendorUsingCategory] {
        try await api.checkVendorsUsingCategory(categoryId: categoryId)
    }

    // MARK: - Utility Functions

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

    func clearError() {
        error = nil
    }

    func clearSuccessMessage() {
        successMessage = nil
    }
}
