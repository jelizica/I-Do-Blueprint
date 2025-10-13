//
//  MultiStoreCoordinationTests.swift
//  I Do BlueprintTests
//
//  Integration tests for multi-store coordination and data consistency
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class MultiStoreCoordinationTests: XCTestCase {
    var budgetStore: BudgetStoreV2!
    var vendorStore: VendorStoreV2!
    var settingsStore: SettingsStoreV2!

    var mockBudgetRepository: MockBudgetRepository!
    var mockVendorRepository: MockVendorRepository!
    var mockSettingsRepository: MockSettingsRepository!

    override func setUp() async throws {
        mockBudgetRepository = MockBudgetRepository()
        mockVendorRepository = MockVendorRepository()
        mockSettingsRepository = MockSettingsRepository()

        budgetStore = withDependencies {
            $0.budgetRepository = mockBudgetRepository
        } operation: {
            BudgetStoreV2()
        }

        vendorStore = withDependencies {
            $0.vendorRepository = mockVendorRepository
        } operation: {
            VendorStoreV2()
        }

        settingsStore = withDependencies {
            $0.settingsRepository = mockSettingsRepository
        } operation: {
            SettingsStoreV2()
        }
    }

    override func tearDown() async throws {
        budgetStore = nil
        vendorStore = nil
        settingsStore = nil
        mockBudgetRepository = nil
        mockVendorRepository = nil
        mockSettingsRepository = nil
    }

    // MARK: - Vendor and Budget Coordination

    func testVendorAndBudgetCoordination() async throws {
        // Given: Budget with allocated categories
        let venueCategory = BudgetCategory(
            id: 1,
            name: "Venue",
            allocatedAmount: 15000,
            spent: 0,
            remaining: 15000,
            percentageOfTotal: 30,
            percentageSpent: 0,
            createdAt: Date(),
            updatedAt: Date()
        )

        mockBudgetRepository.categories = [venueCategory]
        mockBudgetRepository.budgetSummary = BudgetSummary(
            id: 1,
            coupleId: 1,
            totalBudget: 50000,
            totalSpent: 0,
            totalAllocated: 15000,
            remainingBudget: 50000,
            percentageSpent: 0,
            percentageAllocated: 30,
            categoriesCount: 1,
            expensesCount: 0,
            lastUpdatedAt: Date()
        )

        await budgetStore.loadBudgetData()

        // When: Book a vendor in the venue category
        let venueVendor = Vendor(
            id: nil,
            name: "Elegant Venues",
            category: "Venue",
            contactName: "Jane",
            email: "jane@venues.com",
            phone: "555-0001",
            website: nil,
            status: .booked,
            estimatedCost: 14500,
            actualCost: 14500,
            depositPaid: 5000,
            totalPaid: nil,
            contractSigned: true,
            rating: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        await vendorStore.addVendor(venueVendor)

        // Then: Vendor should be booked
        XCTAssertEqual(vendorStore.vendors.count, 1)
        XCTAssertEqual(vendorStore.vendors.first?.status, .booked)

        // When: Add expense for vendor deposit to budget
        let depositExpense = Expense(
            id: nil,
            categoryId: 1,
            categoryName: "Venue",
            name: "Venue Deposit - Elegant Venues",
            amount: 5000,
            date: Date(),
            isPaid: true,
            notes: "Deposit paid for Elegant Venues",
            createdAt: Date(),
            updatedAt: Date()
        )

        await budgetStore.addExpense(depositExpense)

        // Then: Budget should reflect the expense
        XCTAssertEqual(budgetStore.expenses.count, 1)
        XCTAssertEqual(budgetStore.totalSpent, 5000)
        XCTAssertEqual(budgetStore.remainingBudget, 45000)

        // Verify coordination
        let vendorCost = vendorStore.vendors.first?.depositPaid ?? 0
        let budgetExpense = budgetStore.expenses.first?.amount ?? 0
        XCTAssertEqual(vendorCost, budgetExpense, "Vendor deposit should match budget expense")
    }

    // MARK: - Settings and Budget Currency Coordination

    func testSettingsAndBudgetCurrencyCoordination() async throws {
        // Given: Settings with USD currency
        var settings = CoupleSettings.default
        settings.global.currency = "USD"
        mockSettingsRepository.coupleSettings = settings

        await settingsStore.loadSettings()
        XCTAssertEqual(settingsStore.settings.global.currency, "USD")

        // Given: Budget in USD
        mockBudgetRepository.budgetSummary = BudgetSummary(
            id: 1,
            coupleId: 1,
            totalBudget: 50000,
            totalSpent: 0,
            totalAllocated: 0,
            remainingBudget: 50000,
            percentageSpent: 0,
            percentageAllocated: 0,
            categoriesCount: 0,
            expensesCount: 0,
            lastUpdatedAt: Date()
        )

        await budgetStore.loadBudgetData()

        // When: Change currency to EUR in settings
        settingsStore.localSettings.global.currency = "EUR"
        await settingsStore.saveGlobalSettings()

        // Then: Settings should be updated
        XCTAssertEqual(settingsStore.settings.global.currency, "EUR")

        // Note: In real app, budget would need to be refreshed or converted
        // This test verifies that settings update independently
        XCTAssertNotNil(budgetStore.budgetSummary)
    }

    // MARK: - Complete Wedding Planning Flow

    func testCompleteWeddingPlanningFlow() async throws {
        // Given: Initialize all stores
        mockSettingsRepository.coupleSettings = .default
        mockBudgetRepository.budgetSummary = BudgetSummary(
            id: 1,
            coupleId: 1,
            totalBudget: 100000,
            totalSpent: 0,
            totalAllocated: 0,
            remainingBudget: 100000,
            percentageSpent: 0,
            percentageAllocated: 0,
            categoriesCount: 0,
            expensesCount: 0,
            lastUpdatedAt: Date()
        )

        // Step 1: Load all data
        await settingsStore.loadSettings()
        await budgetStore.loadBudgetData()
        await vendorStore.loadVendors()

        XCTAssertNotNil(settingsStore.settings)
        XCTAssertNotNil(budgetStore.budgetSummary)

        // Step 2: Create budget categories
        let categories = [
            BudgetCategory(id: nil, name: "Venue", allocatedAmount: 30000, spent: 0, remaining: 30000, percentageOfTotal: 30, percentageSpent: 0, createdAt: Date(), updatedAt: Date()),
            BudgetCategory(id: nil, name: "Catering", allocatedAmount: 25000, spent: 0, remaining: 25000, percentageOfTotal: 25, percentageSpent: 0, createdAt: Date(), updatedAt: Date()),
            BudgetCategory(id: nil, name: "Photography", allocatedAmount: 15000, spent: 0, remaining: 15000, percentageOfTotal: 15, percentageSpent: 0, createdAt: Date(), updatedAt: Date())
        ]

        for category in categories {
            await budgetStore.addCategory(category)
        }

        XCTAssertEqual(budgetStore.categories.count, 3)

        // Step 3: Add vendors for each category
        let vendors = [
            Vendor(id: nil, name: "Venue Co", category: "Venue", contactName: "John", email: "john@venue.com", phone: "555-0001", website: nil, status: .researching, estimatedCost: 28000, actualCost: nil, depositPaid: nil, totalPaid: nil, contractSigned: false, rating: nil, notes: nil, createdAt: Date(), updatedAt: Date()),
            Vendor(id: nil, name: "Gourmet Catering", category: "Catering", contactName: "Mary", email: "mary@catering.com", phone: "555-0002", website: nil, status: .researching, estimatedCost: 24000, actualCost: nil, depositPaid: nil, totalPaid: nil, contractSigned: false, rating: nil, notes: nil, createdAt: Date(), updatedAt: Date()),
            Vendor(id: nil, name: "Pro Photos", category: "Photography", contactName: "Bob", email: "bob@photos.com", phone: "555-0003", website: nil, status: .researching, estimatedCost: 12000, actualCost: nil, depositPaid: nil, totalPaid: nil, contractSigned: false, rating: nil, notes: nil, createdAt: Date(), updatedAt: Date())
        ]

        for vendor in vendors {
            await vendorStore.addVendor(vendor)
        }

        XCTAssertEqual(vendorStore.vendors.count, 3)

        // Step 4: Book vendors and add expenses
        var venueVendor = vendorStore.vendors[0]
        venueVendor.status = .booked
        venueVendor.contractSigned = true
        venueVendor.actualCost = 27500
        venueVendor.depositPaid = 10000
        await vendorStore.updateVendor(venueVendor)

        let venueDepositExpense = Expense(
            id: nil,
            categoryId: 1,
            categoryName: "Venue",
            name: "Venue Deposit",
            amount: 10000,
            date: Date(),
            isPaid: true,
            notes: "Deposit for Venue Co",
            createdAt: Date(),
            updatedAt: Date()
        )
        await budgetStore.addExpense(venueDepositExpense)

        var cateringVendor = vendorStore.vendors[1]
        cateringVendor.status = .booked
        cateringVendor.contractSigned = true
        cateringVendor.actualCost = 23000
        cateringVendor.depositPaid = 5000
        await vendorStore.updateVendor(cateringVendor)

        let cateringDepositExpense = Expense(
            id: nil,
            categoryId: 2,
            categoryName: "Catering",
            name: "Catering Deposit",
            amount: 5000,
            date: Date(),
            isPaid: true,
            notes: "Deposit for Gourmet Catering",
            createdAt: Date(),
            updatedAt: Date()
        )
        await budgetStore.addExpense(cateringDepositExpense)

        // Step 5: Verify coordination across stores
        XCTAssertEqual(budgetStore.expenses.count, 2, "Should have 2 expenses")
        XCTAssertEqual(budgetStore.totalSpent, 15000, "Total spent should be 15000")
        XCTAssertEqual(vendorStore.vendors.filter { $0.status == .booked }.count, 2, "Should have 2 booked vendors")

        // Calculate total vendor deposits
        let totalVendorDeposits = vendorStore.vendors
            .compactMap { $0.depositPaid }
            .reduce(0, +)
        XCTAssertEqual(totalVendorDeposits, budgetStore.totalSpent, "Vendor deposits should match budget expenses")

        // Step 6: Update settings and verify independence
        settingsStore.localSettings.budget.alertThreshold = 75
        await settingsStore.saveBudgetSettings()

        XCTAssertEqual(settingsStore.settings.budget.alertThreshold, 75)

        // Verify all stores are in valid state
        XCTAssertNil(settingsStore.error, "Settings should have no errors")
        XCTAssertNil(budgetStore.error, "Budget should have no errors")
        XCTAssertNil(vendorStore.error, "Vendor should have no errors")
    }

    // MARK: - Data Consistency Across Stores

    func testDataConsistencyAcrossStores() async throws {
        // Given: Multiple stores with related data
        mockBudgetRepository.budgetSummary = BudgetSummary(
            id: 1,
            coupleId: 1,
            totalBudget: 50000,
            totalSpent: 0,
            totalAllocated: 0,
            remainingBudget: 50000,
            percentageSpent: 0,
            percentageAllocated: 0,
            categoriesCount: 0,
            expensesCount: 0,
            lastUpdatedAt: Date()
        )

        let vendor = Vendor(
            id: 1,
            name: "Venue Co",
            category: "Venue",
            contactName: "John",
            email: "john@venue.com",
            phone: "555-0001",
            website: nil,
            status: .booked,
            estimatedCost: 15000,
            actualCost: 14500,
            depositPaid: 5000,
            totalPaid: 14500,
            contractSigned: true,
            rating: 5,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockVendorRepository.vendors = [vendor]

        let expense = Expense(
            id: 1,
            categoryId: 1,
            categoryName: "Venue",
            name: "Venue Payment",
            amount: 14500,
            date: Date(),
            isPaid: true,
            notes: "Full payment for Venue Co",
            createdAt: Date(),
            updatedAt: Date()
        )
        mockBudgetRepository.expenses = [expense]

        // When: Load all stores
        await budgetStore.loadBudgetData()
        await vendorStore.loadVendors()

        // Then: Data should be consistent
        let vendorPayment = vendorStore.vendors.first?.totalPaid ?? 0
        let budgetExpense = budgetStore.expenses.first?.amount ?? 0

        XCTAssertEqual(vendorPayment, budgetExpense, "Vendor payment should match budget expense")
        XCTAssertEqual(vendorStore.vendors.first?.category, budgetStore.expenses.first?.categoryName, "Categories should match")
    }

    // MARK: - Parallel Store Operations

    func testParallelStoreOperations() async throws {
        // Given: All stores ready
        mockBudgetRepository.budgetSummary = BudgetSummary(
            id: 1,
            coupleId: 1,
            totalBudget: 50000,
            totalSpent: 0,
            totalAllocated: 0,
            remainingBudget: 50000,
            percentageSpent: 0,
            percentageAllocated: 0,
            categoriesCount: 0,
            expensesCount: 0,
            lastUpdatedAt: Date()
        )
        mockSettingsRepository.coupleSettings = .default

        // When: Perform operations in parallel
        async let budgetLoad = budgetStore.loadBudgetData()
        async let vendorLoad = vendorStore.loadVendors()
        async let settingsLoad = settingsStore.loadSettings()

        await budgetLoad
        await vendorLoad
        await settingsLoad

        // Then: All operations should complete successfully
        XCTAssertNotNil(budgetStore.budgetSummary)
        XCTAssertNotNil(settingsStore.settings)
        XCTAssertFalse(budgetStore.isLoading)
        XCTAssertFalse(vendorStore.isLoading)
        XCTAssertFalse(settingsStore.isLoading)
        XCTAssertNil(budgetStore.error)
        XCTAssertNil(vendorStore.error)
        XCTAssertNil(settingsStore.error)
    }

    // MARK: - Store Error Isolation

    func testStoreErrorIsolation() async throws {
        // Given: Budget repository will fail
        mockBudgetRepository.shouldThrowError = true
        mockSettingsRepository.coupleSettings = .default

        // When: Load all stores
        await budgetStore.loadBudgetData()
        await settingsStore.loadSettings()
        await vendorStore.loadVendors()

        // Then: Budget should have error, but other stores should succeed
        XCTAssertNotNil(budgetStore.error, "Budget should have error")
        XCTAssertNil(settingsStore.error, "Settings should not have error")
        XCTAssertNil(vendorStore.error, "Vendor should not have error")
        XCTAssertNotNil(settingsStore.settings, "Settings should be loaded")
    }

    // MARK: - Store State Independence

    func testStoreStateIndependence() async throws {
        // Given: All stores loaded
        mockBudgetRepository.budgetSummary = BudgetSummary(
            id: 1,
            coupleId: 1,
            totalBudget: 50000,
            totalSpent: 0,
            totalAllocated: 0,
            remainingBudget: 50000,
            percentageSpent: 0,
            percentageAllocated: 0,
            categoriesCount: 0,
            expensesCount: 0,
            lastUpdatedAt: Date()
        )
        mockSettingsRepository.coupleSettings = .default

        await budgetStore.loadBudgetData()
        await settingsStore.loadSettings()
        await vendorStore.loadVendors()

        // When: Update one store
        settingsStore.localSettings.global.currency = "EUR"
        await settingsStore.saveGlobalSettings()

        // Then: Other stores should not be affected
        XCTAssertEqual(settingsStore.settings.global.currency, "EUR")
        XCTAssertNotNil(budgetStore.budgetSummary, "Budget should still be loaded")
        XCTAssertEqual(vendorStore.vendors.count, 0, "Vendors should be unchanged")

        // When: Update budget
        let category = BudgetCategory(
            id: nil,
            name: "Venue",
            allocatedAmount: 15000,
            spent: 0,
            remaining: 15000,
            percentageOfTotal: 30,
            percentageSpent: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        await budgetStore.addCategory(category)

        // Then: Settings and vendor stores should be unchanged
        XCTAssertEqual(settingsStore.settings.global.currency, "EUR", "Settings should be unchanged")
        XCTAssertEqual(vendorStore.vendors.count, 0, "Vendors should be unchanged")
        XCTAssertEqual(budgetStore.categories.count, 1, "Budget should have new category")
    }
}
