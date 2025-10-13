//
//  BudgetRepositoryTests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for BudgetRepository implementations
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class BudgetRepositoryTests: XCTestCase {
    var mockRepository: MockBudgetRepository!

    override func setUp() async throws {
        mockRepository = MockBudgetRepository()
    }

    override func tearDown() async throws {
        mockRepository = nil
    }

    // MARK: - Budget Summary Tests

    func testFetchBudgetSummary_Success() async throws {
        // Given
        let summary = BudgetSummary(
            id: UUID(),
            coupleId: UUID(),
            totalBudget: 50000,
            baseBudget: 45000,
            currency: "USD",
            weddingDate: Date(),
            notes: nil,
            includesEngagementRings: true,
            engagementRingAmount: 5000,
            createdAt: Date(),
            updatedAt: nil
        )
        mockRepository.budgetSummary = summary

        // When
        let result = try await mockRepository.fetchBudgetSummary()

        // Then
        XCTAssertTrue(mockRepository.fetchSummaryCalled)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.totalBudget, 50000)
        XCTAssertEqual(result?.baseBudget, 45000)
        XCTAssertEqual(result?.currency, "USD")
    }

    func testFetchBudgetSummary_NilResult() async throws {
        // Given
        mockRepository.budgetSummary = nil

        // When
        let result = try await mockRepository.fetchBudgetSummary()

        // Then
        XCTAssertTrue(mockRepository.fetchSummaryCalled)
        XCTAssertNil(result)
    }

    func testFetchBudgetSummary_ErrorHandling() async throws {
        // Given
        mockRepository.shouldThrowError = true

        // When/Then
        do {
            _ = try await mockRepository.fetchBudgetSummary()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(mockRepository.fetchSummaryCalled)
        }
    }

    // MARK: - Category Tests

    func testFetchCategories_Success() async throws {
        // Given
        mockRepository.categories = [
            createMockCategory(categoryName: "Venue", allocatedAmount: 15000),
            createMockCategory(categoryName: "Catering", allocatedAmount: 10000),
        ]

        // When
        let result = try await mockRepository.fetchCategories()

        // Then
        XCTAssertTrue(mockRepository.fetchCategoriesCalled)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].categoryName, "Venue")
        XCTAssertEqual(result[1].allocatedAmount, 10000)
    }

    func testCreateCategory_Success() async throws {
        // Given
        let newCategory = createMockCategory(categoryName: "Photography", allocatedAmount: 5000)

        // When
        let created = try await mockRepository.createCategory(newCategory)

        // Then
        XCTAssertTrue(mockRepository.createCategoryCalled)
        XCTAssertEqual(created.categoryName, "Photography")
        XCTAssertEqual(mockRepository.categories.count, 1)
    }

    func testUpdateCategory_Success() async throws {
        // Given
        let original = createMockCategory(categoryName: "Venue", allocatedAmount: 15000)
        mockRepository.categories = [original]

        var updated = original
        updated.categoryName = "Venue & Location"
        updated.allocatedAmount = 18000
        updated.updatedAt = Date()

        // When
        let result = try await mockRepository.updateCategory(updated)

        // Then
        XCTAssertTrue(mockRepository.updateCategoryCalled)
        XCTAssertEqual(result.categoryName, "Venue & Location")
        XCTAssertEqual(result.allocatedAmount, 18000)
        XCTAssertEqual(mockRepository.categories.first?.allocatedAmount, 18000)
    }

    func testDeleteCategory_Success() async throws {
        // Given
        let category1 = createMockCategory(categoryName: "Category 1")
        let category2 = createMockCategory(categoryName: "Category 2")
        mockRepository.categories = [category1, category2]

        // When
        try await mockRepository.deleteCategory(id: category1.id)

        // Then
        XCTAssertTrue(mockRepository.deleteCategoryCalled)
        XCTAssertEqual(mockRepository.categories.count, 1)
        XCTAssertEqual(mockRepository.categories.first?.id, category2.id)
    }

    // MARK: - Expense Tests

    func testFetchExpenses_Success() async throws {
        // Given
        mockRepository.expenses = [
            createMockExpense(expenseName: "Venue Deposit", amount: 5000),
            createMockExpense(expenseName: "Catering Payment", amount: 3000),
        ]

        // When
        let result = try await mockRepository.fetchExpenses()

        // Then
        XCTAssertTrue(mockRepository.fetchExpensesCalled)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].expenseName, "Venue Deposit")
        XCTAssertEqual(result[1].amount, 3000)
    }

    func testCreateExpense_Success() async throws {
        // Given
        let newExpense = createMockExpense(expenseName: "DJ Booking", amount: 1500)

        // When
        let created = try await mockRepository.createExpense(newExpense)

        // Then
        XCTAssertTrue(mockRepository.createExpenseCalled)
        XCTAssertEqual(created.expenseName, "DJ Booking")
        XCTAssertEqual(created.amount, 1500)
        XCTAssertEqual(mockRepository.expenses.count, 1)
    }

    func testUpdateExpense_Success() async throws {
        // Given
        let original = createMockExpense(expenseName: "Initial Payment", amount: 1000)
        mockRepository.expenses = [original]

        var updated = original
        updated.expenseName = "Updated Payment"
        updated.amount = 1500
        updated.notes = "Updated notes"
        updated.updatedAt = Date()

        // When
        let result = try await mockRepository.updateExpense(updated)

        // Then
        XCTAssertEqual(result.expenseName, "Updated Payment")
        XCTAssertEqual(result.amount, 1500)
        XCTAssertEqual(mockRepository.expenses.first?.expenseName, "Updated Payment")
    }

    func testDeleteExpense_Success() async throws {
        // Given
        let expense1 = createMockExpense(expenseName: "Expense 1", amount: 100)
        let expense2 = createMockExpense(expenseName: "Expense 2", amount: 200)
        mockRepository.expenses = [expense1, expense2]

        // When
        try await mockRepository.deleteExpense(id: expense1.id)

        // Then
        XCTAssertEqual(mockRepository.expenses.count, 1)
        XCTAssertEqual(mockRepository.expenses.first?.id, expense2.id)
    }

    // MARK: - Error Handling Tests

    func testOperations_WithDelay() async throws {
        // Given
        mockRepository.delay = 0.1 // 100ms delay
        mockRepository.categories = [createMockCategory(categoryName: "Test")]

        // When
        let start = Date()
        _ = try await mockRepository.fetchCategories()
        let elapsed = Date().timeIntervalSince(start)

        // Then
        XCTAssertGreaterThanOrEqual(elapsed, 0.1)
        XCTAssertTrue(mockRepository.fetchCategoriesCalled)
    }

    func testConcurrentOperations() async throws {
        // Given
        mockRepository.categories = [
            createMockCategory(categoryName: "Category 1"),
            createMockCategory(categoryName: "Category 2"),
        ]
        mockRepository.expenses = [
            createMockExpense(expenseName: "Expense 1", amount: 100),
        ]

        // When - Perform concurrent operations
        async let categories = mockRepository.fetchCategories()
        async let expenses = mockRepository.fetchExpenses()

        let (cats, exps) = try await (categories, expenses)

        // Then
        XCTAssertEqual(cats.count, 2)
        XCTAssertEqual(exps.count, 1)
        XCTAssertTrue(mockRepository.fetchCategoriesCalled)
        XCTAssertTrue(mockRepository.fetchExpensesCalled)
    }

    // MARK: - Helper Methods

    private func createMockCategory(
        categoryName: String,
        allocatedAmount: Double = 1000,
        spentAmount: Double = 0
    ) -> BudgetCategory {
        BudgetCategory(
            id: UUID(),
            coupleId: UUID(),
            categoryName: categoryName,
            parentCategoryId: nil,
            allocatedAmount: allocatedAmount,
            spentAmount: spentAmount,
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
        amount: Double,
        expenseDate: Date = Date()
    ) -> Expense {
        Expense(
            id: UUID(),
            coupleId: UUID(),
            budgetCategoryId: UUID(),
            vendorId: nil,
            vendorName: nil,
            expenseName: expenseName,
            amount: amount,
            expenseDate: expenseDate,
            paymentMethod: "Credit Card",
            paymentStatus: "Paid",
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
}
