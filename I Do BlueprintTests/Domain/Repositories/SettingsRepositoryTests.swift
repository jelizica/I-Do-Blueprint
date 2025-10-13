//
//  SettingsRepositoryTests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for SettingsRepository implementations
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class SettingsRepositoryTests: XCTestCase {
    var mockRepository: MockSettingsRepository!

    override func setUp() async throws {
        mockRepository = MockSettingsRepository()
    }

    override func tearDown() async throws {
        mockRepository = nil
    }

    // MARK: - Fetch Settings Tests

    func testFetchSettings_Success() async throws {
        // Given
        var mockSettings = CoupleSettings.default
        mockSettings.global.weddingDate = "2025-06-15"
        mockSettings.global.currency = "USD"
        mockSettings.global.partner1FullName = "Partner One"
        mockRepository.coupleSettings = mockSettings

        // When
        let result = try await mockRepository.fetchSettings()

        // Then
        XCTAssertEqual(result.global.weddingDate, "2025-06-15")
        XCTAssertEqual(result.global.currency, "USD")
        XCTAssertEqual(result.global.partner1FullName, "Partner One")
    }

    func testFetchSettings_ErrorHandling() async throws {
        // Given
        mockRepository.shouldThrowError = true

        // When/Then
        do {
            _ = try await mockRepository.fetchSettings()
            XCTFail("Should have thrown an error")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Update Global Settings Tests

    func testUpdateGlobalSettings_Success() async throws {
        // Given
        mockRepository.coupleSettings = .default

        var updatedGlobalSettings = mockRepository.coupleSettings.global
        updatedGlobalSettings.currency = "EUR"
        updatedGlobalSettings.weddingDate = "2025-06-15"
        updatedGlobalSettings.timezone = "Europe/Paris"

        // When
        try await mockRepository.updateGlobalSettings(updatedGlobalSettings)

        // Then
        XCTAssertEqual(mockRepository.coupleSettings.global.currency, "EUR")
        XCTAssertEqual(mockRepository.coupleSettings.global.weddingDate, "2025-06-15")
        XCTAssertEqual(mockRepository.coupleSettings.global.timezone, "Europe/Paris")
    }

    // MARK: - Update Theme Settings Tests

    func testUpdateThemeSettings_Success() async throws {
        // Given
        var themeSettings = mockRepository.coupleSettings.theme
        themeSettings.colorScheme = "dark"
        themeSettings.darkMode = true

        // When
        try await mockRepository.updateThemeSettings(themeSettings)

        // Then
        XCTAssertEqual(mockRepository.coupleSettings.theme.colorScheme, "dark")
        XCTAssertTrue(mockRepository.coupleSettings.theme.darkMode)
    }

    // MARK: - Update Budget Settings Tests

    func testUpdateBudgetSettings_Success() async throws {
        // Given
        var budgetSettings = mockRepository.coupleSettings.budget
        budgetSettings.totalBudget = 60000
        budgetSettings.baseBudget = 55000
        budgetSettings.includesEngagementRings = true
        budgetSettings.engagementRingAmount = 5000

        // When
        try await mockRepository.updateBudgetSettings(budgetSettings)

        // Then
        XCTAssertEqual(mockRepository.coupleSettings.budget.totalBudget, 60000)
        XCTAssertEqual(mockRepository.coupleSettings.budget.baseBudget, 55000)
        XCTAssertTrue(mockRepository.coupleSettings.budget.includesEngagementRings)
        XCTAssertEqual(mockRepository.coupleSettings.budget.engagementRingAmount, 5000)
    }

    // MARK: - Vendor Category Tests

    func testCreateVendorCategory_Success() async throws {
        // Given
        let newCategory = CustomVendorCategory(
            id: UUID().uuidString,
            coupleId: UUID().uuidString,
            name: "Custom Category",
            description: nil,
            typicalBudgetPercentage: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let created = try await mockRepository.createVendorCategory(newCategory)

        // Then
        XCTAssertEqual(created.name, "Custom Category")
        XCTAssertEqual(mockRepository.customVendorCategories.count, 1)
        XCTAssertEqual(mockRepository.customVendorCategories.first?.name, "Custom Category")
    }

    func testUpdateVendorCategory_Success() async throws {
        // Given
        let originalCategory = CustomVendorCategory(
            id: UUID().uuidString,
            coupleId: UUID().uuidString,
            name: "Original",
            description: nil,
            typicalBudgetPercentage: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockRepository.customVendorCategories = [originalCategory]

        var updatedCategory = originalCategory
        updatedCategory.name = "Updated"
        updatedCategory.description = "Updated description"
        updatedCategory.updatedAt = Date()

        // When
        let result = try await mockRepository.updateVendorCategory(updatedCategory)

        // Then
        XCTAssertEqual(result.name, "Updated")
        XCTAssertEqual(result.description, "Updated description")
        XCTAssertEqual(mockRepository.customVendorCategories.first?.name, "Updated")
    }

    func testDeleteVendorCategory_Success() async throws {
        // Given
        let category1 = CustomVendorCategory(
            id: "cat1",
            coupleId: UUID().uuidString,
            name: "Category 1",
            description: nil,
            typicalBudgetPercentage: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        let category2 = CustomVendorCategory(
            id: "cat2",
            coupleId: UUID().uuidString,
            name: "Category 2",
            description: nil,
            typicalBudgetPercentage: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockRepository.customVendorCategories = [category1, category2]

        // When
        try await mockRepository.deleteVendorCategory(id: "cat1")

        // Then
        XCTAssertEqual(mockRepository.customVendorCategories.count, 1)
        XCTAssertEqual(mockRepository.customVendorCategories.first?.id, "cat2")
    }

    // MARK: - Error Handling Tests

    func testUpdateOperations_WithError() async throws {
        // Given
        mockRepository.shouldThrowError = true
        var globalSettings = mockRepository.coupleSettings.global
        globalSettings.weddingDate = "2025-07-01"

        // When/Then
        do {
            try await mockRepository.updateGlobalSettings(globalSettings)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }

    func testConcurrentSettingsUpdates() async throws {
        // Given
        var globalSettings = mockRepository.coupleSettings.global
        globalSettings.currency = "GBP"
        globalSettings.weddingDate = "2025-08-20"

        var themeSettings = mockRepository.coupleSettings.theme
        themeSettings.colorScheme = "dark"
        themeSettings.darkMode = true

        // When - Perform concurrent updates
        async let globalUpdate: Void = mockRepository.updateGlobalSettings(globalSettings)
        async let themeUpdate: Void = mockRepository.updateThemeSettings(themeSettings)

        try await globalUpdate
        try await themeUpdate

        // Then
        XCTAssertEqual(mockRepository.coupleSettings.global.currency, "GBP")
        XCTAssertEqual(mockRepository.coupleSettings.theme.colorScheme, "dark")
    }
}
