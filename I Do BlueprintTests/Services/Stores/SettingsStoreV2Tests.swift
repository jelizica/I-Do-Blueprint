//
//  SettingsStoreV2Tests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for SettingsStoreV2
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class SettingsStoreV2Tests: XCTestCase {
    var store: SettingsStoreV2!
    var mockRepository: MockSettingsRepository!

    override func setUp() async throws {
        mockRepository = MockSettingsRepository()
        store = withDependencies {
            $0.settingsRepository = mockRepository
        } operation: {
            SettingsStoreV2()
        }
    }

    override func tearDown() async throws {
        store = nil
        mockRepository = nil
    }

    // MARK: - Load Settings Tests

    func testLoadSettings_Success() async throws {
        // Given
        var mockSettings = CoupleSettings.default
        mockSettings.global.weddingDate = "2025-06-15"
        mockSettings.global.currency = "USD"
        mockSettings.theme.colorScheme = "light"

        let mockCategories = [
            createMockVendorCategory(name: "Custom Category 1"),
            createMockVendorCategory(name: "Custom Category 2"),
        ]

        mockRepository.coupleSettings = mockSettings
        mockRepository.customVendorCategories = mockCategories

        // When
        await store.loadSettings()

        // Then
        XCTAssertEqual(store.settings.global.weddingDate, "2025-06-15")
        XCTAssertEqual(store.settings.global.currency, "USD")
        XCTAssertEqual(store.settings.theme.colorScheme, "light")
        XCTAssertEqual(store.customVendorCategories.count, 2)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertFalse(store.hasUnsavedChanges)
    }

    func testLoadSettings_Error() async throws {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await store.loadSettings()

        // Then
        XCTAssertNotNil(store.error)
        XCTAssertFalse(store.isLoading)
        XCTAssertEqual(store.settings, .default)
    }

    func testRefreshSettings() async throws {
        // Given
        var mockSettings = CoupleSettings.default
        mockSettings.global.currency = "EUR"
        mockRepository.coupleSettings = mockSettings

        // When
        await store.refreshSettings()

        // Then
        XCTAssertEqual(store.settings.global.currency, "EUR")
    }

    // MARK: - Global Settings Tests

    func testUpdateGlobalSettings_Success() async throws {
        // Given
        await store.loadSettings()

        var updatedGlobal = store.settings.global
        updatedGlobal.currency = "GBP"
        updatedGlobal.weddingDate = "2025-07-20"
        updatedGlobal.partner1FullName = "Updated Partner"

        // When
        await store.updateGlobalSettings(updatedGlobal)

        // Then
        XCTAssertEqual(store.settings.global.currency, "GBP")
        XCTAssertEqual(store.settings.global.weddingDate, "2025-07-20")
        XCTAssertEqual(store.settings.global.partner1FullName, "Updated Partner")
        XCTAssertEqual(store.localSettings.global.currency, "GBP")
        XCTAssertNil(store.error)
        XCTAssertNotNil(store.successMessage)
    }

    func testUpdateGlobalSettings_Rollback() async throws {
        // Given
        var originalSettings = CoupleSettings.default
        originalSettings.global.currency = "USD"
        mockRepository.coupleSettings = originalSettings
        await store.loadSettings()

        var updatedGlobal = store.settings.global
        updatedGlobal.currency = "EUR"
        mockRepository.shouldThrowError = true

        // When
        await store.updateGlobalSettings(updatedGlobal)

        // Then - Should rollback to original
        XCTAssertEqual(store.settings.global.currency, "USD")
        XCTAssertNotNil(store.error)
    }

    // MARK: - Theme Settings Tests

    func testUpdateThemeSettings_Success() async throws {
        // Given
        await store.loadSettings()

        var updatedTheme = store.settings.theme
        updatedTheme.colorScheme = "dark"
        updatedTheme.darkMode = true

        // When
        await store.updateThemeSettings(updatedTheme)

        // Then
        XCTAssertEqual(store.settings.theme.colorScheme, "dark")
        XCTAssertTrue(store.settings.theme.darkMode)
        XCTAssertNil(store.error)
        XCTAssertNotNil(store.successMessage)
    }

    func testUpdateThemeSettings_Rollback() async throws {
        // Given
        var originalSettings = CoupleSettings.default
        originalSettings.theme.colorScheme = "light"
        mockRepository.coupleSettings = originalSettings
        await store.loadSettings()

        var updatedTheme = store.settings.theme
        updatedTheme.colorScheme = "dark"
        mockRepository.shouldThrowError = true

        // When
        await store.updateThemeSettings(updatedTheme)

        // Then - Should rollback
        XCTAssertEqual(store.settings.theme.colorScheme, "light")
        XCTAssertNotNil(store.error)
    }

    // MARK: - Budget Settings Tests

    func testUpdateBudgetSettings_Success() async throws {
        // Given
        await store.loadSettings()

        var updatedBudget = store.settings.budget
        updatedBudget.totalBudget = 60000
        updatedBudget.baseBudget = 55000
        updatedBudget.includesEngagementRings = true

        // When
        await store.updateBudgetSettings(updatedBudget)

        // Then
        XCTAssertEqual(store.settings.budget.totalBudget, 60000)
        XCTAssertEqual(store.settings.budget.baseBudget, 55000)
        XCTAssertTrue(store.settings.budget.includesEngagementRings)
        XCTAssertNil(store.error)
    }

    func testUpdateBudgetSettings_Rollback() async throws {
        // Given
        var originalSettings = CoupleSettings.default
        originalSettings.budget.totalBudget = 50000
        mockRepository.coupleSettings = originalSettings
        await store.loadSettings()

        var updatedBudget = store.settings.budget
        updatedBudget.totalBudget = 70000
        mockRepository.shouldThrowError = true

        // When
        await store.updateBudgetSettings(updatedBudget)

        // Then - Should rollback
        XCTAssertEqual(store.settings.budget.totalBudget, 50000)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Custom Vendor Category Tests

    func testCreateVendorCategory_Success() async throws {
        // Given
        let newCategory = createMockVendorCategory(name: "Photography")
        mockRepository.customVendorCategories = []

        // When
        await store.createVendorCategory(newCategory)

        // Then
        XCTAssertEqual(store.customVendorCategories.count, 1)
        XCTAssertEqual(store.customVendorCategories[0].name, "Photography")
        XCTAssertNil(store.error)
        XCTAssertNotNil(store.successMessage)
    }

    func testCreateVendorCategory_Error() async throws {
        // Given
        let newCategory = createMockVendorCategory(name: "Flowers")
        mockRepository.shouldThrowError = true

        // When
        await store.createVendorCategory(newCategory)

        // Then
        XCTAssertTrue(store.customVendorCategories.isEmpty)
        XCTAssertNotNil(store.error)
    }

    func testUpdateVendorCategory_Success() async throws {
        // Given
        let originalCategory = createMockVendorCategory(name: "Original")
        mockRepository.customVendorCategories = [originalCategory]
        await store.loadSettings()

        var updatedCategory = originalCategory
        updatedCategory.name = "Updated"
        updatedCategory.description = "Updated description"

        // When
        await store.updateVendorCategory(updatedCategory)

        // Then
        XCTAssertEqual(store.customVendorCategories.count, 1)
        XCTAssertEqual(store.customVendorCategories[0].name, "Updated")
        XCTAssertEqual(store.customVendorCategories[0].description, "Updated description")
        XCTAssertNil(store.error)
    }

    func testUpdateVendorCategory_Rollback() async throws {
        // Given
        let originalCategory = createMockVendorCategory(name: "Original")
        mockRepository.customVendorCategories = [originalCategory]
        await store.loadSettings()

        var updatedCategory = originalCategory
        updatedCategory.name = "Failed Update"
        mockRepository.shouldThrowError = true

        // When
        await store.updateVendorCategory(updatedCategory)

        // Then - Should rollback
        XCTAssertEqual(store.customVendorCategories[0].name, "Original")
        XCTAssertNotNil(store.error)
    }

    func testDeleteVendorCategory_Success() async throws {
        // Given
        let category1 = createMockVendorCategory(name: "Category 1", id: "cat1")
        let category2 = createMockVendorCategory(name: "Category 2", id: "cat2")
        mockRepository.customVendorCategories = [category1, category2]
        await store.loadSettings()

        // When
        await store.deleteVendorCategory(category1)

        // Then
        XCTAssertEqual(store.customVendorCategories.count, 1)
        XCTAssertEqual(store.customVendorCategories[0].id, "cat2")
        XCTAssertNil(store.error)
    }

    func testDeleteVendorCategory_Rollback() async throws {
        // Given
        let category = createMockVendorCategory(name: "Category")
        mockRepository.customVendorCategories = [category]
        await store.loadSettings()

        mockRepository.shouldThrowError = true

        // When
        await store.deleteVendorCategory(category)

        // Then - Should rollback
        XCTAssertEqual(store.customVendorCategories.count, 1)
        XCTAssertEqual(store.customVendorCategories[0].id, category.id)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Unsaved Changes Tests

    func testHasUnsavedChanges_TracksCorrectly() async throws {
        // Given
        await store.loadSettings()
        XCTAssertFalse(store.hasUnsavedChanges)

        // When - Modify local settings
        store.localSettings.global.currency = "EUR"
        store.updateField(\.global.currency, value: "EUR")

        // Then
        XCTAssertTrue(store.hasUnsavedChanges)
    }

    func testDiscardChanges() async throws {
        // Given
        var originalSettings = CoupleSettings.default
        originalSettings.global.currency = "USD"
        mockRepository.coupleSettings = originalSettings
        await store.loadSettings()

        store.localSettings.global.currency = "EUR"
        store.updateField(\.global.currency, value: "EUR")
        XCTAssertTrue(store.hasUnsavedChanges)

        // When
        store.discardChanges()

        // Then
        XCTAssertFalse(store.hasUnsavedChanges)
        XCTAssertEqual(store.localSettings.global.currency, "USD")
    }

    // MARK: - Error and Success Message Tests

    func testClearError() async throws {
        // Given
        store.error = .fetchFailed(underlying: NSError(domain: "Test", code: 1))

        // When
        store.clearError()

        // Then
        XCTAssertNil(store.error)
    }

    func testClearSuccessMessage() async throws {
        // Given
        store.successMessage = "Test message"

        // When
        store.clearSuccessMessage()

        // Then
        XCTAssertNil(store.successMessage)
    }

    // MARK: - Helper Methods

    private func createMockVendorCategory(
        name: String,
        id: String = UUID().uuidString
    ) -> CustomVendorCategory {
        CustomVendorCategory(
            id: id,
            coupleId: UUID().uuidString,
            name: name,
            description: nil,
            typicalBudgetPercentage: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
