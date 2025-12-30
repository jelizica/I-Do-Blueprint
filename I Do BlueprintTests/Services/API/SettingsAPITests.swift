//
//  SettingsAPITests.swift
//  I Do BlueprintTests
//
//  Integration tests for SettingsAPI
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class SettingsAPITests: XCTestCase {
    var mockSupabase: MockSettingsSupabaseClient!
    var api: SettingsAPI!
    
    override func setUp() async throws {
        try await super.setUp()
        mockSupabase = MockSettingsSupabaseClient()
        api = SettingsAPI(supabase: mockSupabase)
    }
    
    override func tearDown() async throws {
        mockSupabase = nil
        api = nil
        try await super.tearDown()
    }
    
    // MARK: - Fetch Settings Tests
    
    func test_fetchSettings_success() async throws {
        // Given
        let mockSettings = CoupleSettings.makeTest()
        mockSupabase.mockSettings = mockSettings
        
        // When
        let settings = try await api.fetchSettings()
        
        // Then
        XCTAssertEqual(settings.global.currency, mockSettings.global.currency)
        XCTAssertEqual(settings.theme.darkMode, mockSettings.theme.darkMode)
    }
    
    func test_fetchSettings_networkError_throwsError() async {
        // Given
        mockSupabase.shouldThrowError = true
        mockSupabase.errorToThrow = NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        // When/Then
        do {
            _ = try await api.fetchSettings()
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Update Settings Tests
    
    func test_updateSettings_partialUpdate_mergesCorrectly() async throws {
        // Given
        let currentSettings = CoupleSettings.makeTest(darkMode: false, currency: "USD")
        mockSupabase.mockSettings = currentSettings
        
        let partialUpdate: [String: Any] = [
            "theme": ["dark_mode": true]
        ]
        
        let expectedSettings = CoupleSettings.makeTest(darkMode: true, currency: "USD")
        mockSupabase.mockUpdatedSettings = expectedSettings
        
        // When
        let updatedSettings = try await api.updateSettings(partialUpdate)
        
        // Then
        XCTAssertTrue(updatedSettings.theme.darkMode)
        XCTAssertEqual(updatedSettings.global.currency, "USD")
    }
    
    func test_updateSettings_globalSettings_success() async throws {
        // Given
        let currentSettings = CoupleSettings.makeTest()
        mockSupabase.mockSettings = currentSettings
        
        let partialUpdate: [String: Any] = [
            "global": [
                "wedding_date": "2025-06-15",
                "partner1_full_name": "John Doe",
                "currency": "EUR"
            ]
        ]
        
        let expectedSettings = CoupleSettings.makeTest(
            weddingDate: "2025-06-15",
            partner1FullName: "John Doe",
            currency: "EUR"
        )
        mockSupabase.mockUpdatedSettings = expectedSettings
        
        // When
        let updatedSettings = try await api.updateSettings(partialUpdate)
        
        // Then
        XCTAssertEqual(updatedSettings.global.weddingDate, "2025-06-15")
        XCTAssertEqual(updatedSettings.global.partner1FullName, "John Doe")
        XCTAssertEqual(updatedSettings.global.currency, "EUR")
    }
    
    func test_updateSettings_budgetSettings_success() async throws {
        // Given
        let currentSettings = CoupleSettings.makeTest()
        mockSupabase.mockSettings = currentSettings
        
        let partialUpdate: [String: Any] = [
            "budget": [
                "total_budget": 50000.0,
                "auto_categorize": true,
                "payment_reminders": false
            ]
        ]
        
        let expectedSettings = CoupleSettings.makeTest(
            totalBudget: 50000.0,
            autoCategorize: true,
            paymentReminders: false
        )
        mockSupabase.mockUpdatedSettings = expectedSettings
        
        // When
        let updatedSettings = try await api.updateSettings(partialUpdate)
        
        // Then
        XCTAssertEqual(updatedSettings.budget.totalBudget, 50000.0)
        XCTAssertTrue(updatedSettings.budget.autoCategorize)
        XCTAssertFalse(updatedSettings.budget.paymentReminders)
    }
    
    func test_updateSettings_themeSettings_success() async throws {
        // Given
        let currentSettings = CoupleSettings.makeTest(darkMode: false)
        mockSupabase.mockSettings = currentSettings
        
        let partialUpdate: [String: Any] = [
            "theme": [
                "dark_mode": true,
                "color_scheme": "purple"
            ]
        ]
        
        let expectedSettings = CoupleSettings.makeTest(darkMode: true, colorScheme: "purple")
        mockSupabase.mockUpdatedSettings = expectedSettings
        
        // When
        let updatedSettings = try await api.updateSettings(partialUpdate)
        
        // Then
        XCTAssertTrue(updatedSettings.theme.darkMode)
        XCTAssertEqual(updatedSettings.theme.colorScheme, "purple")
    }
    
    func test_updateSettings_multipleCategories_success() async throws {
        // Given
        let currentSettings = CoupleSettings.makeTest()
        mockSupabase.mockSettings = currentSettings
        
        let partialUpdate: [String: Any] = [
            "theme": ["dark_mode": true],
            "budget": ["total_budget": 75000.0],
            "global": ["currency": "GBP"]
        ]
        
        let expectedSettings = CoupleSettings.makeTest(
            darkMode: true,
            currency: "GBP",
            totalBudget: 75000.0
        )
        mockSupabase.mockUpdatedSettings = expectedSettings
        
        // When
        let updatedSettings = try await api.updateSettings(partialUpdate)
        
        // Then
        XCTAssertTrue(updatedSettings.theme.darkMode)
        XCTAssertEqual(updatedSettings.budget.totalBudget, 75000.0)
        XCTAssertEqual(updatedSettings.global.currency, "GBP")
    }
    
    // MARK: - Custom Vendor Categories Tests
    
    func test_fetchCustomVendorCategories_success() async throws {
        // Given
        let category1 = CustomVendorCategory.makeTest(name: "Category 1")
        let category2 = CustomVendorCategory.makeTest(name: "Category 2")
        mockSupabase.mockCustomCategories = [category1, category2]
        
        // When
        let categories = try await api.fetchCustomVendorCategories()
        
        // Then
        XCTAssertEqual(categories.count, 2)
        XCTAssertEqual(categories[0].name, "Category 1")
        XCTAssertEqual(categories[1].name, "Category 2")
    }
    
    func test_createCustomVendorCategory_success() async throws {
        // Given
        let name = "New Category"
        let description = "Test description"
        let typicalBudget = "5-10%"
        
        let mockCategory = CustomVendorCategory.makeTest(
            name: name,
            description: description,
            typicalBudgetPercentage: typicalBudget
        )
        mockSupabase.mockCustomCategory = mockCategory
        
        // When
        let category = try await api.createCustomVendorCategory(
            name: name,
            description: description,
            typicalBudgetPercentage: typicalBudget
        )
        
        // Then
        XCTAssertEqual(category.name, name)
        XCTAssertEqual(category.description, description)
        XCTAssertEqual(category.typicalBudgetPercentage, typicalBudget)
    }
    
    func test_updateCustomVendorCategory_success() async throws {
        // Given
        let categoryId = "test-id"
        let updatedName = "Updated Category"
        
        let mockCategory = CustomVendorCategory.makeTest(
            id: categoryId,
            name: updatedName
        )
        mockSupabase.mockCustomCategory = mockCategory
        
        // When
        let category = try await api.updateCustomVendorCategory(
            id: categoryId,
            name: updatedName,
            description: nil,
            typicalBudgetPercentage: nil
        )
        
        // Then
        XCTAssertEqual(category.id, categoryId)
        XCTAssertEqual(category.name, updatedName)
    }
    
    func test_deleteCustomVendorCategory_success() async throws {
        // Given
        let categoryId = "test-id"
        mockSupabase.deleteSucceeds = true
        
        // When/Then
        try await api.deleteCustomVendorCategory(id: categoryId)
        // Should not throw
    }
    
    func test_checkVendorsUsingCategory_success() async throws {
        // Given
        let categoryId = "test-id"
        mockSupabase.mockVendorsUsingCategory = [
            VendorUsingCategory(id: 1, vendorName: "Vendor A"),
            VendorUsingCategory(id: 2, vendorName: "Vendor B")
        ]
        
        // When
        let vendors = try await api.checkVendorsUsingCategory(categoryId: categoryId)
        
        // Then
        XCTAssertEqual(vendors.count, 2)
        XCTAssertEqual(vendors[0].vendorName, "Vendor A")
        XCTAssertEqual(vendors[1].vendorName, "Vendor B")
    }
    
    // MARK: - Phone Number Formatting Tests
    
    func test_formatPhoneNumbers_success() async throws {
        // Given
        let mockResult = PhoneFormatResult(
            message: "Formatted 5 phone numbers",
            vendors: PhoneFormatSection(updated: 3, skipped: 0),
            contacts: PhoneFormatSection(updated: 2, skipped: 0)
        )
        mockSupabase.mockPhoneFormatResult = mockResult
        
        // When
        let result = try await api.formatPhoneNumbers()
        
        // Then
        XCTAssertEqual(result.message, "Formatted 5 phone numbers")
        XCTAssertEqual(result.vendors?.updated, 3)
        XCTAssertEqual(result.contacts?.updated, 2)
    }
    
    // MARK: - Data Deletion Tests
    
    func test_resetData_success() async throws {
        // Given
        mockSupabase.resetSucceeds = true
        
        // When/Then
        try await api.resetData(
            keepBudgetSandbox: true,
            keepAffordability: false,
            keepCategories: true
        )
        // Should not throw
    }
    
    func test_resetData_allOptions_success() async throws {
        // Given
        mockSupabase.resetSucceeds = true
        
        // When/Then
        try await api.resetData(
            keepBudgetSandbox: false,
            keepAffordability: false,
            keepCategories: false
        )
        // Should not throw
    }
}

// MARK: - Mock Supabase Client for Settings

class MockSettingsSupabaseClient {
    var shouldThrowError = false
    var errorToThrow: Error?
    var deleteSucceeds = true
    var resetSucceeds = true
    
    // Mock data
    var mockSettings: CoupleSettings?
    var mockUpdatedSettings: CoupleSettings?
    var mockCustomCategories: [CustomVendorCategory] = []
    var mockCustomCategory: CustomVendorCategory?
    var mockVendorsUsingCategory: [VendorUsingCategory] = []
    var mockPhoneFormatResult: PhoneFormatResult?
}

// MARK: - Test Helpers

extension CoupleSettings {
    static func makeTest(
        weddingDate: String = "2025-12-31",
        partner1FullName: String = "Partner 1",
        partner1Nickname: String = "P1",
        partner2FullName: String = "Partner 2",
        partner2Nickname: String = "P2",
        currency: String = "USD",
        timezone: String = "America/New_York",
        darkMode: Bool = false,
        colorScheme: String = "default",
        totalBudget: Double = 30000.0,
        baseBudget: Double = 30000.0,
        autoCategorize: Bool = true,
        paymentReminders: Bool = true
    ) -> CoupleSettings {
        CoupleSettings(
            global: GlobalSettings(
                weddingDate: weddingDate,
                partner1FullName: partner1FullName,
                partner1Nickname: partner1Nickname,
                partner2FullName: partner2FullName,
                partner2Nickname: partner2Nickname,
                currency: currency,
                timezone: timezone
            ),
            theme: ThemeSettings(
                colorScheme: colorScheme,
                darkMode: darkMode
            ),
            budget: BudgetSettings(
                totalBudget: totalBudget,
                baseBudget: baseBudget,
                includesEngagementRings: false,
                engagementRingAmount: nil,
                autoCategorize: autoCategorize,
                paymentReminders: paymentReminders,
                notes: nil
            ),
            cashFlow: CashFlowSettings(
                defaultPartner1Monthly: 1000.0,
                defaultPartner2Monthly: 1000.0,
                defaultInterestMonthly: 50.0,
                defaultGiftsMonthly: 200.0
            ),
            tasks: TasksSettings(
                defaultView: "list",
                showCompleted: true,
                notificationsEnabled: true
            ),
            vendors: VendorsSettings(
                defaultView: "grid",
                showPaymentStatus: true,
                autoReminders: true
            ),
            guests: GuestsSettings(
                defaultView: "list",
                showMealPreferences: true,
                rsvpReminders: true,
                customMealOptions: []
            ),
            documents: DocumentsSettings(
                autoOrganize: true,
                cloudBackup: true,
                retentionDays: 365
            ),
            notifications: NotificationsSettings(
                emailEnabled: true,
                pushEnabled: true,
                digestFrequency: "daily"
            ),
            links: LinksSettings(importantLinks: [])
        )
    }
}

extension CustomVendorCategory {
    static func makeTest(
        id: String = UUID().uuidString,
        coupleId: UUID = UUID(),
        name: String = "Test Category",
        description: String? = "Test description",
        typicalBudgetPercentage: String? = "5-10%",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> CustomVendorCategory {
        CustomVendorCategory(
            id: id,
            coupleId: coupleId,
            name: name,
            description: description,
            typicalBudgetPercentage: typicalBudgetPercentage,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
