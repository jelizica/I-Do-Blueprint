//
//  SettingsFlowTests.swift
//  I Do BlueprintTests
//
//  Integration tests for settings update propagation
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class SettingsFlowTests: XCTestCase {
    var settingsStore: SettingsStoreV2!
    var mockSettingsRepository: MockSettingsRepository!

    override func setUp() async throws {
        mockSettingsRepository = MockSettingsRepository()
        settingsStore = withDependencies {
            $0.settingsRepository = mockSettingsRepository
        } operation: {
            SettingsStoreV2()
        }
    }

    override func tearDown() async throws {
        settingsStore = nil
        mockSettingsRepository = nil
    }

    // MARK: - Settings Load and Update Propagation

    func testSettingsLoadAndUpdatePropagation() async throws {
        // Given: Initial settings
        let initialSettings = CoupleSettings(
            id: 1,
            coupleId: 1,
            global: GlobalSettings(
                currency: "USD",
                weddingDate: Date(),
                timezone: "America/New_York",
                partner1FullName: "John Doe",
                partner1Nickname: "John",
                partner2FullName: "Jane Smith",
                partner2Nickname: "Jane"
            ),
            theme: ThemeSettings(
                primaryColor: "#FF6B6B",
                secondaryColor: "#4ECDC4",
                accentColor: "#FFE66D",
                fontStyle: "Modern",
                isDarkMode: false
            ),
            budget: BudgetSettings(
                showBenchmarks: true,
                enableCategoryAlerts: true,
                alertThreshold: 80,
                trackCashGifts: true,
                trackMoneyOwed: true
            ),
            createdAt: Date(),
            updatedAt: Date()
        )

        mockSettingsRepository.coupleSettings = initialSettings

        // When: Load settings
        await settingsStore.loadSettings()

        // Then: Settings should be loaded
        XCTAssertTrue(mockSettingsRepository.fetchSettingsCalled, "Should fetch settings")
        XCTAssertEqual(settingsStore.settings.global.partner1FullName, "John Doe")
        XCTAssertEqual(settingsStore.settings.global.partner2FullName, "Jane Smith")
        XCTAssertFalse(settingsStore.hasUnsavedChanges, "Should have no unsaved changes")

        // When: Update global settings
        settingsStore.localSettings.global.partner1FullName = "Jonathan Doe"
        settingsStore.localSettings.global.partner2FullName = "Janet Smith"

        mockSettingsRepository.resetFlags()
        await settingsStore.saveGlobalSettings()

        // Then: Settings should be updated and propagated
        XCTAssertTrue(mockSettingsRepository.updateSettingsCalled, "Should update settings")
        XCTAssertEqual(settingsStore.settings.global.partner1FullName, "Jonathan Doe")
        XCTAssertEqual(settingsStore.settings.global.partner2FullName, "Janet Smith")
        XCTAssertFalse(settingsStore.hasUnsavedChanges, "Should have no unsaved changes after save")
        XCTAssertNil(settingsStore.error, "Should have no errors")
    }

    // MARK: - Theme Settings Propagation

    func testThemeSettingsPropagation() async throws {
        // Given: Default settings
        mockSettingsRepository.coupleSettings = .default
        await settingsStore.loadSettings()

        let initialTheme = settingsStore.settings.theme

        // When: Update theme settings
        settingsStore.localSettings.theme.primaryColor = "#FF0000"
        settingsStore.localSettings.theme.isDarkMode = true

        mockSettingsRepository.resetFlags()
        await settingsStore.saveThemeSettings()

        // Then: Theme should be updated
        XCTAssertTrue(mockSettingsRepository.updateSettingsCalled, "Should update settings")
        XCTAssertEqual(settingsStore.settings.theme.primaryColor, "#FF0000")
        XCTAssertTrue(settingsStore.settings.theme.isDarkMode)
        XCTAssertNotEqual(settingsStore.settings.theme.primaryColor, initialTheme.primaryColor)
        XCTAssertNotEqual(settingsStore.settings.theme.isDarkMode, initialTheme.isDarkMode)
        XCTAssertNil(settingsStore.error, "Should have no errors")
    }

    // MARK: - Budget Settings Propagation

    func testBudgetSettingsPropagation() async throws {
        // Given: Default settings
        mockSettingsRepository.coupleSettings = .default
        await settingsStore.loadSettings()

        // When: Update budget settings
        settingsStore.localSettings.budget.showBenchmarks = false
        settingsStore.localSettings.budget.alertThreshold = 90
        settingsStore.localSettings.budget.enableCategoryAlerts = false

        mockSettingsRepository.resetFlags()
        await settingsStore.saveBudgetSettings()

        // Then: Budget settings should be updated
        XCTAssertTrue(mockSettingsRepository.updateSettingsCalled, "Should update settings")
        XCTAssertFalse(settingsStore.settings.budget.showBenchmarks)
        XCTAssertEqual(settingsStore.settings.budget.alertThreshold, 90)
        XCTAssertFalse(settingsStore.settings.budget.enableCategoryAlerts)
        XCTAssertNil(settingsStore.error, "Should have no errors")
    }

    // MARK: - Multiple Settings Update Flow

    func testMultipleSettingsUpdateFlow() async throws {
        // Given: Clean state
        mockSettingsRepository.coupleSettings = .default
        await settingsStore.loadSettings()

        // When: Update multiple setting sections in sequence
        // 1. Update global settings
        settingsStore.localSettings.global.currency = "EUR"
        settingsStore.localSettings.global.timezone = "Europe/London"
        await settingsStore.saveGlobalSettings()

        // 2. Update theme settings
        settingsStore.localSettings.theme.primaryColor = "#00FF00"
        settingsStore.localSettings.theme.fontStyle = "Classic"
        await settingsStore.saveThemeSettings()

        // 3. Update budget settings
        settingsStore.localSettings.budget.trackCashGifts = false
        settingsStore.localSettings.budget.trackMoneyOwed = false
        await settingsStore.saveBudgetSettings()

        // Then: All settings should be updated
        XCTAssertEqual(settingsStore.settings.global.currency, "EUR")
        XCTAssertEqual(settingsStore.settings.global.timezone, "Europe/London")
        XCTAssertEqual(settingsStore.settings.theme.primaryColor, "#00FF00")
        XCTAssertEqual(settingsStore.settings.theme.fontStyle, "Classic")
        XCTAssertFalse(settingsStore.settings.budget.trackCashGifts)
        XCTAssertFalse(settingsStore.settings.budget.trackMoneyOwed)
        XCTAssertFalse(settingsStore.hasUnsavedChanges, "Should have no unsaved changes")
        XCTAssertNil(settingsStore.error, "Should have no errors")
    }

    // MARK: - Settings Update with Error Handling

    func testSettingsUpdateWithErrorHandling() async throws {
        // Given: Existing settings
        mockSettingsRepository.coupleSettings = .default
        await settingsStore.loadSettings()

        let originalSettings = settingsStore.settings

        // When: Update fails
        settingsStore.localSettings.global.partner1FullName = "New Name"
        mockSettingsRepository.shouldThrowError = true
        mockSettingsRepository.resetFlags()

        await settingsStore.saveGlobalSettings()

        // Then: Should have error and not update settings
        XCTAssertTrue(mockSettingsRepository.updateSettingsCalled, "Should attempt update")
        XCTAssertNotNil(settingsStore.error, "Should have error")
        XCTAssertEqual(settingsStore.settings.global.partner1FullName, originalSettings.global.partner1FullName, "Settings should not be updated on error")
    }

    // MARK: - Custom Vendor Categories Propagation

    func testCustomVendorCategoriesPropagation() async throws {
        // Given: Default settings with no custom categories
        mockSettingsRepository.coupleSettings = .default
        mockSettingsRepository.customVendorCategories = []
        await settingsStore.loadSettings()

        XCTAssertEqual(settingsStore.customVendorCategories.count, 0)

        // When: Create custom vendor category
        let newCategory = CustomVendorCategory(
            id: nil,
            coupleId: 1,
            name: "Live Band",
            icon: "music.note",
            colorHex: "#FF6B6B",
            isActive: true,
            sortOrder: 0,
            createdAt: Date(),
            updatedAt: Date()
        )

        mockSettingsRepository.resetFlags()
        await settingsStore.createVendorCategory(newCategory)

        // Then: Category should be created and propagated
        XCTAssertTrue(mockSettingsRepository.createVendorCategoryCalled, "Should create category")
        XCTAssertEqual(settingsStore.customVendorCategories.count, 1)
        XCTAssertEqual(settingsStore.customVendorCategories.first?.name, "Live Band")

        // When: Update category
        var updatedCategory = settingsStore.customVendorCategories[0]
        updatedCategory.name = "Live Entertainment"
        updatedCategory.colorHex = "#00FF00"

        mockSettingsRepository.resetFlags()
        await settingsStore.updateVendorCategory(updatedCategory)

        // Then: Category should be updated
        XCTAssertTrue(mockSettingsRepository.updateVendorCategoryCalled, "Should update category")
        XCTAssertEqual(settingsStore.customVendorCategories.first?.name, "Live Entertainment")
        XCTAssertEqual(settingsStore.customVendorCategories.first?.colorHex, "#00FF00")

        // When: Delete category
        mockSettingsRepository.resetFlags()
        await settingsStore.deleteVendorCategory(updatedCategory)

        // Then: Category should be deleted
        XCTAssertTrue(mockSettingsRepository.deleteVendorCategoryCalled, "Should delete category")
        XCTAssertEqual(settingsStore.customVendorCategories.count, 0)
        XCTAssertNil(settingsStore.error, "Should have no errors")
    }

    // MARK: - Settings Refresh Flow

    func testSettingsRefreshFlow() async throws {
        // Given: Initial settings loaded
        mockSettingsRepository.coupleSettings = .default
        await settingsStore.loadSettings()

        let initialPartner1Name = settingsStore.settings.global.partner1FullName

        // When: External update occurs (simulated by updating repository)
        var externallyUpdatedSettings = CoupleSettings.default
        externallyUpdatedSettings.global.partner1FullName = "Externally Updated Name"
        externallyUpdatedSettings.theme.primaryColor = "#EXTERNAL"
        mockSettingsRepository.coupleSettings = externallyUpdatedSettings
        mockSettingsRepository.resetFlags()

        // When: Refresh settings
        await settingsStore.refreshSettings()

        // Then: Should fetch latest data
        XCTAssertTrue(mockSettingsRepository.fetchSettingsCalled, "Should fetch settings on refresh")
        XCTAssertEqual(settingsStore.settings.global.partner1FullName, "Externally Updated Name")
        XCTAssertEqual(settingsStore.settings.theme.primaryColor, "#EXTERNAL")
        XCTAssertNotEqual(settingsStore.settings.global.partner1FullName, initialPartner1Name)
        XCTAssertNil(settingsStore.error, "Should have no errors")
    }

    // MARK: - Unsaved Changes Tracking

    func testUnsavedChangesTracking() async throws {
        // Given: Loaded settings
        mockSettingsRepository.coupleSettings = .default
        await settingsStore.loadSettings()

        XCTAssertFalse(settingsStore.hasUnsavedChanges, "Should have no unsaved changes initially")

        // When: Make local changes
        settingsStore.localSettings.global.partner1FullName = "Modified Name"
        settingsStore.checkUnsavedChanges()

        // Then: Should detect unsaved changes
        XCTAssertTrue(settingsStore.hasUnsavedChanges, "Should have unsaved changes")

        // When: Save changes
        await settingsStore.saveGlobalSettings()

        // Then: Should clear unsaved changes flag
        XCTAssertFalse(settingsStore.hasUnsavedChanges, "Should have no unsaved changes after save")
    }

    // MARK: - Settings Reset Flow

    func testSettingsResetFlow() async throws {
        // Given: Settings with custom values
        var customSettings = CoupleSettings.default
        customSettings.global.currency = "EUR"
        customSettings.theme.primaryColor = "#CUSTOM"
        customSettings.budget.alertThreshold = 75

        mockSettingsRepository.coupleSettings = customSettings
        await settingsStore.loadSettings()

        XCTAssertEqual(settingsStore.settings.global.currency, "EUR")
        XCTAssertEqual(settingsStore.settings.theme.primaryColor, "#CUSTOM")

        // When: Reset to defaults
        mockSettingsRepository.coupleSettings = .default
        await settingsStore.refreshSettings()

        // Then: Should revert to default values
        XCTAssertEqual(settingsStore.settings.global.currency, CoupleSettings.default.global.currency)
        XCTAssertEqual(settingsStore.settings.theme.primaryColor, CoupleSettings.default.theme.primaryColor)
        XCTAssertEqual(settingsStore.settings.budget.alertThreshold, CoupleSettings.default.budget.alertThreshold)
        XCTAssertNil(settingsStore.error, "Should have no errors")
    }
}
