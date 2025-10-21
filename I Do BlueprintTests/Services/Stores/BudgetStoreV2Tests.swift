//
//  BudgetStoreV2Tests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for BudgetStoreV2
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class BudgetStoreV2Tests: XCTestCase {
    var mockRepository: MockBudgetRepository!
    var coupleId: UUID!

    override func setUp() async throws {
        mockRepository = MockBudgetRepository()
        coupleId = UUID()
    }

    override func tearDown() {
        mockRepository = nil
        coupleId = nil
    }

    // MARK: - Load Tests

    func testLoadBudgetSummary_Success() async throws {
        // Given
        let summary = BudgetSummary(
            id: UUID(),
            coupleId: coupleId,
            totalBudget: 50000,
            baseBudget: 45000,
            currency: "USD",
            weddingDate: Date(),
            notes: nil,
            includesEngagementRings: false,
            engagementRingAmount: 0,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.categories = []
        mockRepository.expenses = []

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testLoadCategories_Success() async throws {
        // Given
        let testCategories = [
            BudgetCategory.makeTest(id: UUID(), coupleId: coupleId, categoryName: "Venue", allocatedAmount: 10000),
            BudgetCategory.makeTest(id: UUID(), coupleId: coupleId, categoryName: "Catering", allocatedAmount: 8000)
        ]
        mockRepository.categories = testCategories

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.categories.count, 2)
        XCTAssertEqual(store.categories[0].categoryName, "Venue")
    }

    func testLoadCategories_Empty() async throws {
        // Given
        mockRepository.categories = []

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.categories.count, 0)
    }

    func testLoadExpenses_Success() async throws {
        // Given
        let categoryId = UUID()
        let testExpenses = [
            Expense.makeTest(id: UUID(), coupleId: coupleId, budgetCategoryId: categoryId, expenseName: "Venue Deposit", amount: 1000),
            Expense.makeTest(id: UUID(), coupleId: coupleId, budgetCategoryId: categoryId, expenseName: "Catering Deposit", amount: 500)
        ]
        mockRepository.expenses = testExpenses

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.expenses.count, 2)
    }

    func testLoadExpenses_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Create Tests

    func testCreateCategory_Success() async throws {
        // Given
        let newCategory = BudgetCategory.makeTest(coupleId: coupleId, categoryName: "Photography")

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.addCategory(newCategory)

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.categories.count, 1)
        XCTAssertEqual(store.categories.first?.categoryName, "Photography")
    }

    func testCreateCategory_OptimisticUpdate() async throws {
        // Given
        let existingCategory = BudgetCategory.makeTest(coupleId: coupleId, categoryName: "Venue")
        mockRepository.categories = [existingCategory]

        let newCategory = BudgetCategory.makeTest(coupleId: coupleId, categoryName: "Catering")

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()
        await store.addCategory(newCategory)

        // Then - Optimistic update should show immediately
        XCTAssertEqual(store.categories.count, 2)
        XCTAssertTrue(store.categories.contains(where: { $0.categoryName == "Catering" }))
    }

    func testUpdateCategory_Success() async throws {
        // Given
        let category = BudgetCategory.makeTest(id: UUID(), coupleId: coupleId, categoryName: "Venue", allocatedAmount: 10000)
        mockRepository.categories = [category]

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()

        var updatedCategory = category
        updatedCategory.allocatedAmount = 12000
        await store.updateCategory(updatedCategory)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.categories.first?.allocatedAmount, 12000)
    }

    func testUpdateCategory_Failure_RollsBack() async throws {
        // Given
        let category = BudgetCategory.makeTest(id: UUID(), coupleId: coupleId, categoryName: "Venue", allocatedAmount: 10000)
        mockRepository.categories = [category]

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()

        var updatedCategory = category
        updatedCategory.allocatedAmount = 12000

        mockRepository.shouldThrowError = true
        await store.updateCategory(updatedCategory)

        // Then - Should rollback to original
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.categories.first?.allocatedAmount, 10000)
    }

    func testDeleteCategory_Success() async throws {
        // Given
        let category1 = BudgetCategory.makeTest(id: UUID(), coupleId: coupleId, categoryName: "Venue")
        let category2 = BudgetCategory.makeTest(id: UUID(), coupleId: coupleId, categoryName: "Catering")
        mockRepository.categories = [category1, category2]

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()
        await store.deleteCategory(id: category1.id)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.categories.count, 1)
        XCTAssertEqual(store.categories.first?.categoryName, "Catering")
    }

    func testDeleteCategory_Failure_RollsBack() async throws {
        // Given
        let category = BudgetCategory.makeTest(id: UUID(), coupleId: coupleId, categoryName: "Venue")
        mockRepository.categories = [category]

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()

        mockRepository.shouldThrowError = true
        await store.deleteCategory(id: category.id)

        // Then - Should rollback
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.categories.count, 1)
    }

    func testCreateExpense_OptimisticUpdate() async throws {
        // Given
        let categoryId = UUID()
        let newExpense = Expense.makeTest(coupleId: coupleId, budgetCategoryId: categoryId, expenseName: "Venue Deposit")

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.createExpense(newExpense)

        // Then
        XCTAssertEqual(store.expenses.count, 1)
        XCTAssertEqual(store.expenses.first?.expenseName, "Venue Deposit")
    }

    func testUpdateExpense_Failure_RollsBack() async throws {
        // Given
        let expense = Expense.makeTest(id: UUID(), coupleId: coupleId, expenseName: "Venue Deposit", amount: 1000)
        mockRepository.expenses = [expense]

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()

        var updatedExpense = expense
        updatedExpense.amount = 1500

        mockRepository.shouldThrowError = true
        await store.updateExpense(updatedExpense)

        // Then - Should rollback
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.expenses.first?.amount, 1000)
    }

    // MARK: - Computed Properties Tests

    func testComputedProperty_TotalAllocated() async throws {
        // Given
        let categories = [
            BudgetCategory.makeTest(coupleId: coupleId, allocatedAmount: 10000),
            BudgetCategory.makeTest(coupleId: coupleId, allocatedAmount: 8000),
            BudgetCategory.makeTest(coupleId: coupleId, allocatedAmount: 5000)
        ]
        mockRepository.categories = categories

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()

        // Then
        XCTAssertEqual(store.totalAllocated, 23000)
    }

    func testComputedProperty_TotalSpent() async throws {
        // Given
        let expenses = [
            Expense.makeTest(coupleId: coupleId, amount: 1000),
            Expense.makeTest(coupleId: coupleId, amount: 500),
            Expense.makeTest(coupleId: coupleId, amount: 750)
        ]
        mockRepository.expenses = expenses

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()

        // Then
        XCTAssertEqual(store.totalSpent, 2250)
    }

    func testComputedProperty_RemainingBudget() async throws {
        // Given
        let categories = [
            BudgetCategory.makeTest(coupleId: coupleId, allocatedAmount: 10000)
        ]
        let expenses = [
            Expense.makeTest(coupleId: coupleId, amount: 3000)
        ]
        mockRepository.categories = categories
        mockRepository.expenses = expenses

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()

        // Then
        XCTAssertEqual(store.remainingBudget, 7000)
    }

    func testComputedProperty_CategoriesOverBudget() async throws {
        // Given
        let category1 = BudgetCategory.makeTest(id: UUID(), coupleId: coupleId, allocatedAmount: 1000, spentAmount: 1500)
        let category2 = BudgetCategory.makeTest(id: UUID(), coupleId: coupleId, allocatedAmount: 2000, spentAmount: 500)
        mockRepository.categories = [category1, category2]

        // When
        let store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }

        await store.loadBudgetData()

        // Then
        let stats = store.stats
        XCTAssertEqual(stats.categoriesOverBudget, 1)
    }
}
