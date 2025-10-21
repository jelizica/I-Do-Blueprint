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
    var mockRepository: MockSettingsRepository!
    var coupleId: UUID!

    override func setUp() async throws {
        mockRepository = MockSettingsRepository()
        coupleId = UUID()
    }

    override func tearDown() {
        mockRepository = nil
        coupleId = nil
    }

    // MARK: - Load Tests

    func testLoadSettings_Success() async throws {
        // Given
        let testSettings = CoupleSettings.makeTest(currency: "USD", weddingDate: "2025-12-31", totalBudget: 50000)
        mockRepository.settings = testSettings

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.settings.global.currency, "USD")
        XCTAssertTrue(store.hasLoaded)
    }

    func testLoadSettings_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Update Tests

    func testUpdateGlobalSettings_Success() async throws {
        // Given
        let testSettings = CoupleSettings.makeTest()
        mockRepository.settings = testSettings

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        var newGlobal = store.settings.global
        newGlobal.currency = "EUR"
        await store.updateGlobalSettings(newGlobal)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.settings.global.currency, "EUR")
    }

    func testUpdateThemeSettings_Success() async throws {
        // Given
        let testSettings = CoupleSettings.makeTest()
        mockRepository.settings = testSettings

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        var newTheme = store.settings.theme
        newTheme.colorScheme = "dark"
        newTheme.darkMode = true
        await store.updateThemeSettings(newTheme)

        // Then
        XCTAssertNil(store.error)
    }

    func testUpdateBudgetSettings_Success() async throws {
        // Given
        let testSettings = CoupleSettings.makeTest()
        mockRepository.settings = testSettings

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        var newBudget = store.settings.budget
        newBudget.totalBudget = 60000
        await store.updateBudgetSettings(newBudget)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.settings.budget.totalBudget, 60000)
    }

    func testUpdateTasksSettings_Success() async throws {
        // Given
        let testSettings = CoupleSettings.makeTest()
        mockRepository.settings = testSettings

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        var newTasks = store.settings.tasks
        newTasks.defaultView = "list"
        newTasks.notificationsEnabled = false
        await store.updateTasksSettings(newTasks)

        // Then
        XCTAssertNil(store.error)
    }

    // MARK: - Nested Structure Tests

    func testNestedStructureUpdates() async throws {
        // Given
        let testSettings = CoupleSettings.makeTest()
        mockRepository.settings = testSettings

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        // Update nested budget settings
        var newSettings = store.settings
        newSettings.budget.totalBudget = 70000
        newSettings.budget.baseBudget = 70000

        store.localSettings = newSettings
        await store.saveBudgetSettings()

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.settings.budget.totalBudget, 70000)
    }

    func testSettingsValidation() async throws {
        // Given
        let testSettings = CoupleSettings.makeTest()
        mockRepository.settings = testSettings

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        // Then - Settings should be valid
        XCTAssertNotNil(store.settings.global.currency)
        XCTAssertNotNil(store.settings.budget.totalBudget)
    }

    func testHasUnsavedChanges() async throws {
        // Given
        let testSettings = CoupleSettings.makeTest()
        mockRepository.settings = testSettings

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        // Initially no unsaved changes
        XCTAssertFalse(store.hasUnsavedChanges)

        // Make a change
        store.localSettings.global.currency = "EUR"

        // Then - Should have unsaved changes
        XCTAssertTrue(store.hasUnsavedChanges)
    }

    func testDiscardChanges() async throws {
        // Given
        let testSettings = CoupleSettings.makeTest(currency: "USD")
        mockRepository.settings = testSettings

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        // Make changes
        store.localSettings.global.currency = "EUR"
        XCTAssertTrue(store.hasUnsavedChanges)

        // Discard changes
        store.discardChanges()

        // Then
        XCTAssertFalse(store.hasUnsavedChanges)
        XCTAssertEqual(store.localSettings.global.currency, "USD")
    }

    func testSaveGlobalSettings() async throws {
        // Given
        let testSettings = CoupleSettings.makeTest()
        mockRepository.settings = testSettings

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        store.localSettings.global.currency = "EUR"
        await store.saveGlobalSettings()

        // Then
        XCTAssertNil(store.error)
        XCTAssertFalse(store.hasUnsavedChanges)
        XCTAssertEqual(store.settings.global.currency, "EUR")
    }

    func testSaveThemeSettings() async throws {
        // Given
        let testSettings = CoupleSettings.makeTest()
        mockRepository.settings = testSettings

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        store.localSettings.theme.colorScheme = "dark"
        store.localSettings.theme.darkMode = true
        await store.saveThemeSettings()

        // Then
        XCTAssertNil(store.error)
        XCTAssertFalse(store.hasUnsavedChanges)
    }

    func testSaveBudgetSettings() async throws {
        // Given
        let testSettings = CoupleSettings.makeTest()
        mockRepository.settings = testSettings

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        store.localSettings.budget.totalBudget = 60000
        await store.saveBudgetSettings()

        // Then
        XCTAssertNil(store.error)
        XCTAssertFalse(store.hasUnsavedChanges)
    }

    func testSaveTasksSettings() async throws {
        // Given
        let testSettings = CoupleSettings.makeTest()
        mockRepository.settings = testSettings

        // When
        let store = SettingsStoreV2(repository: mockRepository)
        await store.loadSettings()

        store.localSettings.tasks.defaultView = "list"
        store.localSettings.tasks.notificationsEnabled = false
        await store.saveTasksSettings()

        // Then
        XCTAssertNil(store.error)
        XCTAssertFalse(store.hasUnsavedChanges)
    }
}
