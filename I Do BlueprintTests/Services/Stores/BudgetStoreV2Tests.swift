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
    var store: BudgetStoreV2!
    var mockRepository: MockBudgetRepository!

    override func setUp() async throws {
        mockRepository = MockBudgetRepository()
        store = withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }
    }

    override func tearDown() async throws {
        store = nil
        mockRepository = nil
    }

    // MARK: - Load Budget Data Tests

    func testLoadBudgetData_Success() async throws {
        // Given
        let mockSummary = createMockBudgetSummary(totalBudget: 50000)
        let mockCategories = [
            createMockCategory(categoryName: "Venue", allocatedAmount: 15000),
            createMockCategory(categoryName: "Catering", allocatedAmount: 10000),
        ]
        let mockExpenses = [
            createMockExpense(expenseName: "Venue Deposit", amount: 5000),
        ]

        mockRepository.budgetSummary = mockSummary
        mockRepository.categories = mockCategories
        mockRepository.expenses = mockExpenses

        // When
        await store.loadBudgetData()

        // Then
        XCTAssertNotNil(store.budgetSummary)
        XCTAssertEqual(store.budgetSummary?.totalBudget, 50000)
        XCTAssertEqual(store.categories.count, 2)
        XCTAssertEqual(store.expenses.count, 1)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testLoadBudgetData_Error() async throws {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await store.loadBudgetData()

        // Then
        XCTAssertNil(store.budgetSummary)
        XCTAssertTrue(store.categories.isEmpty)
        XCTAssertTrue(store.expenses.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Add Category Tests

    func testAddCategory_Success() async throws {
        // Given
        let newCategory = createMockCategory(categoryName: "Photography", allocatedAmount: 5000)
        mockRepository.categories = []

        // When
        await store.addCategory(newCategory)

        // Then
        XCTAssertEqual(store.categories.count, 1)
        XCTAssertEqual(store.categories[0].categoryName, "Photography")
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testAddCategory_Error() async throws {
        // Given
        let newCategory = createMockCategory(categoryName: "Flowers", allocatedAmount: 3000)
        mockRepository.shouldThrowError = true

        // When
        await store.addCategory(newCategory)

        // Then
        XCTAssertTrue(store.categories.isEmpty)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Update Category Tests

    func testUpdateCategory_Success() async throws {
        // Given
        let originalCategory = createMockCategory(categoryName: "Original", allocatedAmount: 1000, id: UUID())
        mockRepository.categories = [originalCategory]
        await store.loadBudgetData()

        var updatedCategory = originalCategory
        updatedCategory.categoryName = "Updated"
        updatedCategory.allocatedAmount = 2000
        mockRepository.categories = [updatedCategory]

        // When
        await store.updateCategory(updatedCategory)

        // Then
        XCTAssertEqual(store.categories.count, 1)
        XCTAssertEqual(store.categories[0].categoryName, "Updated")
        XCTAssertEqual(store.categories[0].allocatedAmount, 2000)
        XCTAssertNil(store.error)
    }

    func testUpdateCategory_Rollback() async throws {
        // Given
        let originalCategory = createMockCategory(categoryName: "Original", allocatedAmount: 1000, id: UUID())
        mockRepository.categories = [originalCategory]
        await store.loadBudgetData()

        var updatedCategory = originalCategory
        updatedCategory.categoryName = "Failed Update"
        mockRepository.shouldThrowError = true

        // When
        await store.updateCategory(updatedCategory)

        // Then - Should rollback to original
        XCTAssertEqual(store.categories.count, 1)
        XCTAssertEqual(store.categories[0].categoryName, "Original")
        XCTAssertNotNil(store.error)
    }

    // MARK: - Delete Category Tests

    func testDeleteCategory_Success() async throws {
        // Given
        let category1 = createMockCategory(categoryName: "Category 1", id: UUID())
        let category2 = createMockCategory(categoryName: "Category 2", id: UUID())
        mockRepository.categories = [category1, category2]
        await store.loadBudgetData()

        // When
        await store.deleteCategory(id: category1.id)

        // Then
        XCTAssertEqual(store.categories.count, 1)
        XCTAssertEqual(store.categories[0].id, category2.id)
        XCTAssertNil(store.error)
    }

    func testDeleteCategory_Rollback() async throws {
        // Given
        let category = createMockCategory(categoryName: "Category", id: UUID())
        mockRepository.categories = [category]
        await store.loadBudgetData()

        mockRepository.shouldThrowError = true

        // When
        await store.deleteCategory(id: category.id)

        // Then - Should rollback
        XCTAssertEqual(store.categories.count, 1)
        XCTAssertEqual(store.categories[0].id, category.id)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Add Expense Tests

    func testAddExpense_Success() async throws {
        // Given
        let newExpense = createMockExpense(expenseName: "DJ Booking", amount: 1500)
        mockRepository.expenses = []

        // When
        await store.addExpense(newExpense)

        // Then
        XCTAssertEqual(store.expenses.count, 1)
        XCTAssertEqual(store.expenses[0].expenseName, "DJ Booking")
        XCTAssertNil(store.error)
    }

    // MARK: - Update Expense Tests

    func testUpdateExpense_Success() async throws {
        // Given
        let originalExpense = createMockExpense(expenseName: "Original", amount: 1000, id: UUID())
        mockRepository.expenses = [originalExpense]
        await store.loadBudgetData()

        var updatedExpense = originalExpense
        updatedExpense.expenseName = "Updated"
        updatedExpense.amount = 1500
        mockRepository.expenses = [updatedExpense]

        // When
        await store.updateExpense(updatedExpense)

        // Then
        XCTAssertEqual(store.expenses.count, 1)
        XCTAssertEqual(store.expenses[0].expenseName, "Updated")
        XCTAssertEqual(store.expenses[0].amount, 1500)
        XCTAssertNil(store.error)
    }

    func testUpdateExpense_Rollback() async throws {
        // Given
        let originalExpense = createMockExpense(expenseName: "Original", amount: 1000, id: UUID())
        mockRepository.expenses = [originalExpense]
        await store.loadBudgetData()

        var updatedExpense = originalExpense
        updatedExpense.expenseName = "Failed"
        mockRepository.shouldThrowError = true

        // When
        await store.updateExpense(updatedExpense)

        // Then
        XCTAssertEqual(store.expenses.count, 1)
        XCTAssertEqual(store.expenses[0].expenseName, "Original")
        XCTAssertNotNil(store.error)
    }

    // MARK: - Delete Expense Tests

    func testDeleteExpense_Success() async throws {
        // Given
        let expense1 = createMockExpense(expenseName: "Expense 1", id: UUID())
        let expense2 = createMockExpense(expenseName: "Expense 2", id: UUID())
        mockRepository.expenses = [expense1, expense2]
        await store.loadBudgetData()

        // When
        await store.deleteExpense(id: expense1.id)

        // Then
        XCTAssertEqual(store.expenses.count, 1)
        XCTAssertEqual(store.expenses[0].id, expense2.id)
        XCTAssertNil(store.error)
    }

    // MARK: - Computed Properties Tests

    func testComputedProperties() async throws {
        // Given
        let mockSummary = createMockBudgetSummary(totalBudget: 50000)
        let mockCategories = [
            createMockCategory(categoryName: "Venue", allocatedAmount: 15000),
            createMockCategory(categoryName: "Catering", allocatedAmount: 10000),
        ]
        let mockExpenses = [
            createMockExpense(expenseName: "Venue Deposit", amount: 5000),
            createMockExpense(expenseName: "Catering Deposit", amount: 3000),
        ]

        mockRepository.budgetSummary = mockSummary
        mockRepository.categories = mockCategories
        mockRepository.expenses = mockExpenses

        await store.loadBudgetData()

        // Then
        XCTAssertEqual(store.totalSpent, 8000)
        XCTAssertEqual(store.totalAllocated, 25000)
        XCTAssertEqual(store.actualTotalBudget, 50000)
        XCTAssertEqual(store.remainingBudget, 42000)
        XCTAssertEqual(store.percentageSpent, 16.0)
        XCTAssertEqual(store.percentageAllocated, 50.0)
        XCTAssertFalse(store.isOverBudget)
    }

    // MARK: - Category Filtering Consistency Tests

    func testCategoryFilteringConsistency() async throws {
        // Given - Create a category with a specific ID
        let categoryId = UUID()
        let category = createMockCategory(categoryName: "Venue", allocatedAmount: 10000, id: categoryId)

        // Create expenses with the same budgetCategoryId
        let expense1 = createMockExpense(
            expenseName: "Venue Deposit",
            amount: 5000,
            categoryId: categoryId,
            paymentStatus: "paid"
        )
        let expense2 = createMockExpense(
            expenseName: "Venue Balance",
            amount: 3000,
            categoryId: categoryId,
            paymentStatus: "pending"
        )
        let expense3 = createMockExpense(
            expenseName: "Other Category",
            amount: 1000,
            categoryId: UUID(), // Different category
            paymentStatus: "paid"
        )

        mockRepository.categories = [category]
        mockRepository.expenses = [expense1, expense2, expense3]
        await store.loadBudgetData()

        // When - Call all category filtering methods
        let expensesFromExpensesForCategory = store.expensesForCategory(categoryId)
        let spentAmount = store.spentAmount(for: categoryId)
        let projectedAmount = store.projectedSpending(for: categoryId)
        let actualAmount = store.actualSpending(for: categoryId)

        // Then - Verify all methods use the same filtering logic
        // expensesForCategory should return 2 expenses (expense1 and expense2)
        XCTAssertEqual(expensesFromExpensesForCategory.count, 2, "expensesForCategory should return 2 expenses")
        XCTAssertTrue(expensesFromExpensesForCategory.contains(where: { $0.id == expense1.id }))
        XCTAssertTrue(expensesFromExpensesForCategory.contains(where: { $0.id == expense2.id }))
        XCTAssertFalse(expensesFromExpensesForCategory.contains(where: { $0.id == expense3.id }))

        // spentAmount should sum all expenses for the category (5000 + 3000 = 8000)
        XCTAssertEqual(spentAmount, 8000, "spentAmount should sum all expenses for the category")

        // projectedSpending should also sum all expenses (5000 + 3000 = 8000)
        XCTAssertEqual(projectedAmount, 8000, "projectedSpending should match spentAmount")

        // actualSpending should only sum paid expenses (5000)
        XCTAssertEqual(actualAmount, 5000, "actualSpending should only sum paid expenses")

        // Verify consistency: the count of expenses from expensesForCategory should match
        // the count used by spentAmount and projectedSpending
        let manualSpentAmount = expensesFromExpensesForCategory.reduce(0) { $0 + $1.amount }
        XCTAssertEqual(spentAmount, manualSpentAmount, "spentAmount should match manual calculation from expensesForCategory")
        XCTAssertEqual(projectedAmount, manualSpentAmount, "projectedSpending should match manual calculation from expensesForCategory")
    }

    // MARK: - Payment Schedule Tests

    func testAddPaymentSchedule_Success() async throws {
        // Given
        let newSchedule = createMockPaymentSchedule(vendor: "Test Vendor", amount: 1000)
        mockRepository.paymentSchedules = []

        // When
        await store.addPaymentSchedule(newSchedule)

        // Then
        XCTAssertEqual(store.paymentSchedules.count, 1)
        XCTAssertEqual(store.paymentSchedules[0].vendor, "Test Vendor")
        XCTAssertEqual(mockRepository.paymentSchedules.count, 1, "Repository should persist the payment schedule")
        XCTAssertNil(store.error)
    }

    func testAddPaymentSchedule_Error() async throws {
        // Given
        let newSchedule = createMockPaymentSchedule(vendor: "Test Vendor", amount: 1000)
        mockRepository.shouldThrowError = true

        // When
        await store.addPaymentSchedule(newSchedule)

        // Then
        XCTAssertTrue(store.paymentSchedules.isEmpty, "Payment schedule should not be added on error")
        XCTAssertTrue(mockRepository.paymentSchedules.isEmpty, "Repository should not persist on error")
        XCTAssertNotNil(store.error)
    }

    func testDeletePaymentSchedule_Success() async throws {
        // Given
        let schedule1 = createMockPaymentSchedule(vendor: "Vendor 1", amount: 1000, id: 1)
        let schedule2 = createMockPaymentSchedule(vendor: "Vendor 2", amount: 2000, id: 2)
        mockRepository.paymentSchedules = [schedule1, schedule2]
        await store.loadBudgetData()

        // When
        await store.deletePaymentSchedule(id: schedule1.id)

        // Then
        XCTAssertEqual(store.paymentSchedules.count, 1)
        XCTAssertEqual(store.paymentSchedules[0].id, schedule2.id)
        XCTAssertEqual(mockRepository.paymentSchedules.count, 1, "Repository should persist the deletion")
        XCTAssertNil(store.error)
    }

    func testDeletePaymentSchedule_Rollback() async throws {
        // Given
        let schedule = createMockPaymentSchedule(vendor: "Test Vendor", amount: 1000, id: 1)
        mockRepository.paymentSchedules = [schedule]
        await store.loadBudgetData()

        mockRepository.shouldThrowError = true

        // When
        await store.deletePaymentSchedule(id: schedule.id)

        // Then - Should rollback
        XCTAssertEqual(store.paymentSchedules.count, 1, "Payment schedule should be restored on error")
        XCTAssertEqual(store.paymentSchedules[0].id, schedule.id)
        XCTAssertEqual(mockRepository.paymentSchedules.count, 1, "Repository should not delete on error")
        XCTAssertNotNil(store.error)
    }

    func testUpdatePaymentSchedule_Success() async throws {
        // Given
        let originalSchedule = createMockPaymentSchedule(vendor: "Original", amount: 1000, id: 1)
        mockRepository.paymentSchedules = [originalSchedule]
        await store.loadBudgetData()

        var updatedSchedule = originalSchedule
        updatedSchedule.vendor = "Updated"
        updatedSchedule.amount = 2000
        mockRepository.paymentSchedules = [updatedSchedule]

        // When
        await store.updatePaymentSchedule(updatedSchedule)

        // Then
        XCTAssertEqual(store.paymentSchedules.count, 1)
        XCTAssertEqual(store.paymentSchedules[0].vendor, "Updated")
        XCTAssertEqual(store.paymentSchedules[0].amount, 2000)
        XCTAssertNil(store.error)
    }

    func testUpdatePaymentSchedule_Rollback() async throws {
        // Given
        let originalSchedule = createMockPaymentSchedule(vendor: "Original", amount: 1000, id: 1)
        mockRepository.paymentSchedules = [originalSchedule]
        await store.loadBudgetData()

        var updatedSchedule = originalSchedule
        updatedSchedule.vendor = "Failed Update"
        mockRepository.shouldThrowError = true

        // When
        await store.updatePaymentSchedule(updatedSchedule)

        // Then - Should rollback to original
        XCTAssertEqual(store.paymentSchedules.count, 1)
        XCTAssertEqual(store.paymentSchedules[0].vendor, "Original")
        XCTAssertNotNil(store.error)
    }

    // MARK: - Helper Methods

    private func createMockBudgetSummary(totalBudget: Double) -> BudgetSummary {
        BudgetSummary(
            id: UUID(),
            coupleId: UUID(),
            totalBudget: totalBudget,
            baseBudget: totalBudget,
            currency: "USD",
            weddingDate: Date(),
            notes: nil,
            includesEngagementRings: false,
            engagementRingAmount: 0,
            createdAt: Date(),
            updatedAt: nil
        )
    }

    private func createMockCategory(
        categoryName: String,
        allocatedAmount: Double = 1000,
        id: UUID = UUID()
    ) -> BudgetCategory {
        BudgetCategory(
            id: id,
            coupleId: UUID(),
            categoryName: categoryName,
            parentCategoryId: nil,
            allocatedAmount: allocatedAmount,
            spentAmount: 0,
            typicalPercentage: nil,
            priorityLevel: 1,
            isEssential: true,
            notes: nil,
            forecastedAmount: allocatedAmount,
            confidenceLevel: 0.8,
            lockedAllocation: false,
            description: nil,
            createdAt: Date(),
            updatedAt: nil
        )
    }

    private func createMockExpense(
        expenseName: String,
        amount: Double = 1000,
        id: UUID = UUID(),
        categoryId: UUID = UUID(),
        paymentStatus: String = "Paid"
    ) -> Expense {
        Expense(
            id: id,
            coupleId: UUID(),
            budgetCategoryId: categoryId,
            vendorId: nil,
            vendorName: nil,
            expenseName: expenseName,
            amount: amount,
            expenseDate: Date(),
            paymentMethod: "Credit Card",
            paymentStatus: paymentStatus,
            receiptUrl: nil,
            invoiceNumber: nil,
            notes: nil,
            approvalStatus: nil,
            approvedBy: nil,
            approvedAt: nil,
            invoiceDocumentUrl: nil,
            isTestData: false,
            createdAt: Date(),
            updatedAt: nil
        )
    }

    private func createMockPaymentSchedule(
        vendor: String,
        amount: Double,
        id: Int64 = 1
    ) -> PaymentSchedule {
        PaymentSchedule(
            id: id,
            coupleId: UUID(),
            vendor: vendor,
            amount: amount,
            dueDate: Date(),
            paymentStatus: .pending,
            notes: nil,
            createdAt: Date(),
            updatedAt: nil
        )
    }
}
