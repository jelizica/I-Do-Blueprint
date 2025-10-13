//
//  BudgetFlowTests.swift
//  I Do BlueprintTests
//
//  Integration tests for complete budget workflows
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class BudgetFlowTests: XCTestCase {
    var budgetStore: BudgetStoreV2!
    var mockBudgetRepository: MockBudgetRepository!

    override func setUp() async throws {
        mockBudgetRepository = MockBudgetRepository()
        budgetStore = withDependencies {
            $0.budgetRepository = mockBudgetRepository
        } operation: {
            BudgetStoreV2()
        }
    }

    override func tearDown() async throws {
        budgetStore = nil
        mockBudgetRepository = nil
    }

    // MARK: - Full Budget Creation Flow

    func testFullBudgetCreationFlow() async throws {
        // Given: Starting with empty budget
        mockBudgetRepository.budgetSummary = nil
        mockBudgetRepository.categories = []
        mockBudgetRepository.expenses = []

        // When: Load initial budget data
        await budgetStore.loadBudgetData()

        // Then: Budget should be initialized
        XCTAssertTrue(mockBudgetRepository.fetchSummaryCalled, "Should fetch summary")
        XCTAssertTrue(mockBudgetRepository.fetchCategoriesCalled, "Should fetch categories")
        XCTAssertTrue(mockBudgetRepository.fetchExpensesCalled, "Should fetch expenses")

        // When: Create budget summary
        let budgetSummary = BudgetSummary(
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
        mockBudgetRepository.budgetSummary = budgetSummary
        mockBudgetRepository.resetFlags()

        await budgetStore.updateTotalBudget(50000)

        // Then: Budget summary should be created
        XCTAssertTrue(mockBudgetRepository.updateSummaryCalled, "Should update budget summary")
        XCTAssertEqual(budgetStore.budgetSummary?.totalBudget, 50000)

        // When: Add budget categories
        let venueCategory = BudgetCategory(
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

        let cateringCategory = BudgetCategory(
            id: nil,
            name: "Catering",
            allocatedAmount: 10000,
            spent: 0,
            remaining: 10000,
            percentageOfTotal: 20,
            percentageSpent: 0,
            createdAt: Date(),
            updatedAt: Date()
        )

        mockBudgetRepository.resetFlags()
        await budgetStore.addCategory(venueCategory)
        await budgetStore.addCategory(cateringCategory)

        // Then: Categories should be added
        XCTAssertEqual(budgetStore.categories.count, 2, "Should have 2 categories")
        XCTAssertEqual(budgetStore.totalAllocated, 25000, "Total allocated should be 25000")

        // When: Add expenses to categories
        let venueExpense = Expense(
            id: nil,
            categoryId: 1,
            categoryName: "Venue",
            name: "Venue Deposit",
            amount: 5000,
            date: Date(),
            isPaid: true,
            notes: "Initial deposit",
            createdAt: Date(),
            updatedAt: Date()
        )

        mockBudgetRepository.resetFlags()
        await budgetStore.addExpense(venueExpense)

        // Then: Expense should be added and budget updated
        XCTAssertEqual(budgetStore.expenses.count, 1, "Should have 1 expense")
        XCTAssertEqual(budgetStore.totalSpent, 5000, "Total spent should be 5000")
        XCTAssertEqual(budgetStore.remainingBudget, 45000, "Remaining budget should be 45000")

        // When: Update budget allocation
        var updatedVenueCategory = venueCategory
        updatedVenueCategory.id = 1
        updatedVenueCategory.allocatedAmount = 18000

        mockBudgetRepository.resetFlags()
        await budgetStore.updateCategory(updatedVenueCategory)

        // Then: Category allocation should be updated
        XCTAssertTrue(mockBudgetRepository.updateCategoryCalled, "Should update category")

        // Verify final state
        XCTAssertFalse(budgetStore.isLoading, "Should not be loading")
        XCTAssertNil(budgetStore.error, "Should have no errors")
    }

    // MARK: - Budget Update Flow with Rollback

    func testBudgetUpdateFlowWithErrorRollback() async throws {
        // Given: Existing budget with data
        let existingCategory = BudgetCategory(
            id: 1,
            name: "Venue",
            allocatedAmount: 15000,
            spent: 5000,
            remaining: 10000,
            percentageOfTotal: 30,
            percentageSpent: 33,
            createdAt: Date(),
            updatedAt: Date()
        )

        mockBudgetRepository.categories = [existingCategory]
        await budgetStore.loadBudgetData()

        let initialCategoryCount = budgetStore.categories.count
        let initialCategory = budgetStore.categories.first

        // When: Update fails
        mockBudgetRepository.shouldThrowError = true
        mockBudgetRepository.resetFlags()

        var updatedCategory = existingCategory
        updatedCategory.allocatedAmount = 20000

        await budgetStore.updateCategory(updatedCategory)

        // Then: Should rollback to previous state
        XCTAssertTrue(mockBudgetRepository.updateCategoryCalled, "Should attempt update")
        XCTAssertNotNil(budgetStore.error, "Should have error")
        XCTAssertEqual(budgetStore.categories.count, initialCategoryCount, "Category count should be unchanged")
        XCTAssertEqual(budgetStore.categories.first?.allocatedAmount, initialCategory?.allocatedAmount, "Should rollback to original amount")
    }

    // MARK: - Multi-Operation Budget Flow

    func testMultiOperationBudgetFlow() async throws {
        // Given: Clean state
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

        // When: Perform multiple operations in sequence
        await budgetStore.loadBudgetData()

        // Add multiple categories
        let categories = [
            BudgetCategory(id: nil, name: "Venue", allocatedAmount: 30000, spent: 0, remaining: 30000, percentageOfTotal: 30, percentageSpent: 0, createdAt: Date(), updatedAt: Date()),
            BudgetCategory(id: nil, name: "Catering", allocatedAmount: 25000, spent: 0, remaining: 25000, percentageOfTotal: 25, percentageSpent: 0, createdAt: Date(), updatedAt: Date()),
            BudgetCategory(id: nil, name: "Photography", allocatedAmount: 15000, spent: 0, remaining: 15000, percentageOfTotal: 15, percentageSpent: 0, createdAt: Date(), updatedAt: Date())
        ]

        for category in categories {
            await budgetStore.addCategory(category)
        }

        // Add expenses to different categories
        let expenses = [
            Expense(id: nil, categoryId: 1, categoryName: "Venue", name: "Deposit", amount: 10000, date: Date(), isPaid: true, notes: nil, createdAt: Date(), updatedAt: Date()),
            Expense(id: nil, categoryId: 2, categoryName: "Catering", name: "Menu tasting", amount: 500, date: Date(), isPaid: true, notes: nil, createdAt: Date(), updatedAt: Date())
        ]

        for expense in expenses {
            await budgetStore.addExpense(expense)
        }

        // Then: Verify all operations completed successfully
        XCTAssertEqual(budgetStore.categories.count, 3, "Should have 3 categories")
        XCTAssertEqual(budgetStore.expenses.count, 2, "Should have 2 expenses")
        XCTAssertEqual(budgetStore.totalAllocated, 70000, "Total allocated should be 70000")
        XCTAssertEqual(budgetStore.totalSpent, 10500, "Total spent should be 10500")
        XCTAssertEqual(budgetStore.remainingBudget, 89500, "Remaining should be 89500")
        XCTAssertFalse(budgetStore.isOverBudget, "Should not be over budget")
        XCTAssertNil(budgetStore.error, "Should have no errors")
    }

    // MARK: - Budget Deletion Flow

    func testBudgetDeletionFlow() async throws {
        // Given: Budget with categories and expenses
        let category = BudgetCategory(
            id: 1,
            name: "Venue",
            allocatedAmount: 15000,
            spent: 5000,
            remaining: 10000,
            percentageOfTotal: 30,
            percentageSpent: 33,
            createdAt: Date(),
            updatedAt: Date()
        )

        let expense = Expense(
            id: 1,
            categoryId: 1,
            categoryName: "Venue",
            name: "Deposit",
            amount: 5000,
            date: Date(),
            isPaid: true,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        mockBudgetRepository.categories = [category]
        mockBudgetRepository.expenses = [expense]

        await budgetStore.loadBudgetData()

        XCTAssertEqual(budgetStore.categories.count, 1)
        XCTAssertEqual(budgetStore.expenses.count, 1)

        // When: Delete expense
        mockBudgetRepository.resetFlags()
        await budgetStore.deleteExpense(expense)

        // Then: Expense should be deleted
        XCTAssertTrue(mockBudgetRepository.deleteExpenseCalled, "Should delete expense")
        XCTAssertEqual(budgetStore.expenses.count, 0, "Should have no expenses")

        // When: Delete category
        mockBudgetRepository.resetFlags()
        await budgetStore.deleteCategory(category)

        // Then: Category should be deleted
        XCTAssertTrue(mockBudgetRepository.deleteCategoryCalled, "Should delete category")
        XCTAssertEqual(budgetStore.categories.count, 0, "Should have no categories")
        XCTAssertNil(budgetStore.error, "Should have no errors")
    }

    // MARK: - Over Budget Scenario

    func testOverBudgetScenario() async throws {
        // Given: Budget with limited funds
        mockBudgetRepository.budgetSummary = BudgetSummary(
            id: 1,
            coupleId: 1,
            totalBudget: 10000,
            totalSpent: 0,
            totalAllocated: 0,
            remainingBudget: 10000,
            percentageSpent: 0,
            percentageAllocated: 0,
            categoriesCount: 0,
            expensesCount: 0,
            lastUpdatedAt: Date()
        )

        await budgetStore.loadBudgetData()

        // When: Add expense exceeding budget
        let expensiveItem = Expense(
            id: nil,
            categoryId: 1,
            categoryName: "Venue",
            name: "Luxury Venue",
            amount: 12000,
            date: Date(),
            isPaid: true,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        await budgetStore.addExpense(expensiveItem)

        // Then: Should detect over budget
        XCTAssertTrue(budgetStore.isOverBudget, "Should be over budget")
        XCTAssertGreaterThan(budgetStore.totalSpent, budgetStore.actualTotalBudget, "Spent should exceed budget")
        XCTAssertLessThan(budgetStore.remainingBudget, 0, "Remaining should be negative")
    }
}
