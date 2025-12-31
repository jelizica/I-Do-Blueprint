//
//  BudgetAllocationServiceTests.swift
//  I Do BlueprintTests
//
//  Unit tests for BudgetAllocationService
//  Part of I Do Blueprint-bji: Add Domain Service Unit Tests
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class BudgetAllocationServiceTests: XCTestCase {
    
    var mockRepository: MockBudgetRepository!
    var service: BudgetAllocationService!
    let testCoupleId = UUID()
    let testScenarioId = "test-scenario"
    
    override func setUp() async throws {
        mockRepository = MockBudgetRepository()
        service = BudgetAllocationService(repository: mockRepository)
    }
    
    override func tearDown() async throws {
        mockRepository = nil
        service = nil
    }
    
    // MARK: - linkExpenseProportionally Tests
    
    func test_linkExpenseProportionally_withNoExistingAllocations_allocatesFullAmountToTargetItem() async throws {
        // Given
        let expense = makeTestExpense(amount: 1000.0)
        let budgetItemId = "item-1"
        let budgetItem = makeTestBudgetItem(id: budgetItemId, amount: 500.0)
        
        mockRepository.allocationsForExpense = []
        mockRepository.budgetItems = [budgetItem]
        
        // When
        try await service.linkExpenseProportionally(
            expense: expense,
            to: budgetItemId,
            inScenario: testScenarioId
        )
        
        // Then
        XCTAssertEqual(mockRepository.replacedAllocations.count, 1)
        XCTAssertEqual(mockRepository.replacedAllocations.first?.allocatedAmount, 1000.0)
        XCTAssertEqual(mockRepository.replacedAllocations.first?.budgetItemId, budgetItemId)
    }
    
    func test_linkExpenseProportionally_withExistingAllocations_redistributesProportionally() async throws {
        // Given
        let expense = makeTestExpense(amount: 1000.0)
        let item1Id = "item-1"
        let item2Id = "item-2"
        
        let existingAllocation = makeTestAllocation(
            expenseId: expense.id,
            budgetItemId: item1Id,
            amount: 1000.0
        )
        
        let budgetItem1 = makeTestBudgetItem(id: item1Id, amount: 300.0)
        let budgetItem2 = makeTestBudgetItem(id: item2Id, amount: 700.0)
        
        mockRepository.allocationsForExpense = [existingAllocation]
        mockRepository.budgetItems = [budgetItem1, budgetItem2]
        
        // When
        try await service.linkExpenseProportionally(
            expense: expense,
            to: item2Id,
            inScenario: testScenarioId
        )
        
        // Then
        XCTAssertEqual(mockRepository.replacedAllocations.count, 2)
        
        // Verify proportional distribution (30% to item1, 70% to item2)
        let item1Allocation = mockRepository.replacedAllocations.first { $0.budgetItemId == item1Id }
        let item2Allocation = mockRepository.replacedAllocations.first { $0.budgetItemId == item2Id }
        
        XCTAssertNotNil(item1Allocation)
        XCTAssertNotNil(item2Allocation)
        XCTAssertEqual(item1Allocation?.allocatedAmount, 300.0, accuracy: 0.01)
        XCTAssertEqual(item2Allocation?.allocatedAmount, 700.0, accuracy: 0.01)
    }
    
    func test_linkExpenseProportionally_withRoundingIssues_adjustsLastAllocation() async throws {
        // Given
        let expense = makeTestExpense(amount: 100.0)
        let item1Id = "item-1"
        let item2Id = "item-2"
        let item3Id = "item-3"
        
        // Create items with amounts that will cause rounding issues
        let budgetItem1 = makeTestBudgetItem(id: item1Id, amount: 33.33)
        let budgetItem2 = makeTestBudgetItem(id: item2Id, amount: 33.33)
        let budgetItem3 = makeTestBudgetItem(id: item3Id, amount: 33.34)
        
        mockRepository.allocationsForExpense = []
        mockRepository.budgetItems = [budgetItem1, budgetItem2, budgetItem3]
        
        // When
        try await service.linkExpenseProportionally(
            expense: expense,
            to: item1Id,
            inScenario: testScenarioId
        )
        
        // Then
        let totalAllocated = mockRepository.replacedAllocations.reduce(0.0) { $0 + $1.allocatedAmount }
        XCTAssertEqual(totalAllocated, 100.0, accuracy: 0.01, "Total allocated should equal expense amount")
    }
    
    func test_linkExpenseProportionally_withZeroBudgetedAmounts_allocatesFullAmountToTargetItem() async throws {
        // Given
        let expense = makeTestExpense(amount: 1000.0)
        let budgetItemId = "item-1"
        let budgetItem = makeTestBudgetItem(id: budgetItemId, amount: 0.0)
        
        mockRepository.allocationsForExpense = []
        mockRepository.budgetItems = [budgetItem]
        
        // When
        try await service.linkExpenseProportionally(
            expense: expense,
            to: budgetItemId,
            inScenario: testScenarioId
        )
        
        // Then
        XCTAssertEqual(mockRepository.replacedAllocations.count, 1)
        XCTAssertEqual(mockRepository.replacedAllocations.first?.allocatedAmount, 1000.0)
    }
    
    // MARK: - recalculateAllocations Tests
    
    func test_recalculateAllocations_withNoAllocations_doesNothing() async throws {
        // Given
        let budgetItemId = "item-1"
        mockRepository.allocationsForBudgetItem = []
        
        // When
        try await service.recalculateAllocations(
            budgetItemId: budgetItemId,
            scenarioId: testScenarioId
        )
        
        // Then
        XCTAssertTrue(mockRepository.replacedAllocations.isEmpty)
    }
    
    func test_recalculateAllocations_withSingleAllocation_doesNotRecalculate() async throws {
        // Given
        let budgetItemId = "item-1"
        let expense = makeTestExpense(amount: 1000.0)
        let allocation = makeTestAllocation(
            expenseId: expense.id,
            budgetItemId: budgetItemId,
            amount: 1000.0
        )
        
        mockRepository.allocationsForBudgetItem = [allocation]
        mockRepository.allocationsForExpense = [allocation]
        mockRepository.expenses = [expense]
        mockRepository.budgetItems = [makeTestBudgetItem(id: budgetItemId, amount: 500.0)]
        
        // When
        try await service.recalculateAllocations(
            budgetItemId: budgetItemId,
            scenarioId: testScenarioId
        )
        
        // Then - Should not replace allocations for single allocation
        XCTAssertTrue(mockRepository.replacedAllocations.isEmpty)
    }
    
    func test_recalculateAllocations_withMultipleAllocations_recalculatesProportionally() async throws {
        // Given
        let item1Id = "item-1"
        let item2Id = "item-2"
        let expense = makeTestExpense(amount: 1000.0)
        
        let allocation1 = makeTestAllocation(expenseId: expense.id, budgetItemId: item1Id, amount: 500.0)
        let allocation2 = makeTestAllocation(expenseId: expense.id, budgetItemId: item2Id, amount: 500.0)
        
        // Budget items with new amounts (changed from 50/50 to 30/70)
        let budgetItem1 = makeTestBudgetItem(id: item1Id, amount: 300.0)
        let budgetItem2 = makeTestBudgetItem(id: item2Id, amount: 700.0)
        
        mockRepository.allocationsForBudgetItem = [allocation1]
        mockRepository.allocationsForExpense = [allocation1, allocation2]
        mockRepository.expenses = [expense]
        mockRepository.budgetItems = [budgetItem1, budgetItem2]
        
        // When
        try await service.recalculateAllocations(
            budgetItemId: item1Id,
            scenarioId: testScenarioId
        )
        
        // Then
        XCTAssertEqual(mockRepository.replacedAllocations.count, 2)
        
        let item1Allocation = mockRepository.replacedAllocations.first { $0.budgetItemId == item1Id }
        let item2Allocation = mockRepository.replacedAllocations.first { $0.budgetItemId == item2Id }
        
        XCTAssertEqual(item1Allocation?.allocatedAmount, 300.0, accuracy: 0.01)
        XCTAssertEqual(item2Allocation?.allocatedAmount, 700.0, accuracy: 0.01)
    }
    
    // MARK: - recalculateExpenseAllocations Tests
    
    func test_recalculateExpenseAllocations_withSingleAllocation_doesNotRecalculate() async throws {
        // Given
        let expense = makeTestExpense(amount: 1000.0)
        let allocation = makeTestAllocation(
            expenseId: expense.id,
            budgetItemId: "item-1",
            amount: 1000.0
        )
        
        mockRepository.allocationsForExpense = [allocation]
        mockRepository.budgetItems = [makeTestBudgetItem(id: "item-1", amount: 500.0)]
        mockRepository.expenses = [expense]
        
        // When
        try await service.recalculateExpenseAllocations(
            expenseId: expense.id,
            scenarioId: testScenarioId
        )
        
        // Then
        XCTAssertTrue(mockRepository.replacedAllocations.isEmpty)
    }
    
    func test_recalculateExpenseAllocations_withMultipleAllocations_recalculatesWithNewExpenseAmount() async throws {
        // Given
        let expense = makeTestExpense(amount: 2000.0) // Changed from 1000 to 2000
        let item1Id = "item-1"
        let item2Id = "item-2"
        
        let allocation1 = makeTestAllocation(expenseId: expense.id, budgetItemId: item1Id, amount: 500.0)
        let allocation2 = makeTestAllocation(expenseId: expense.id, budgetItemId: item2Id, amount: 500.0)
        
        let budgetItem1 = makeTestBudgetItem(id: item1Id, amount: 400.0)
        let budgetItem2 = makeTestBudgetItem(id: item2Id, amount: 600.0)
        
        mockRepository.allocationsForExpense = [allocation1, allocation2]
        mockRepository.budgetItems = [budgetItem1, budgetItem2]
        mockRepository.expenses = [expense]
        
        // When
        try await service.recalculateExpenseAllocations(
            expenseId: expense.id,
            scenarioId: testScenarioId
        )
        
        // Then
        XCTAssertEqual(mockRepository.replacedAllocations.count, 2)
        
        let item1Allocation = mockRepository.replacedAllocations.first { $0.budgetItemId == item1Id }
        let item2Allocation = mockRepository.replacedAllocations.first { $0.budgetItemId == item2Id }
        
        // 40% of 2000 = 800, 60% of 2000 = 1200
        XCTAssertEqual(item1Allocation?.allocatedAmount, 800.0, accuracy: 0.01)
        XCTAssertEqual(item2Allocation?.allocatedAmount, 1200.0, accuracy: 0.01)
    }
    
    // MARK: - recalculateExpenseAllocationsForAllScenarios Tests
    
    func test_recalculateExpenseAllocationsForAllScenarios_withMultipleScenarios_recalculatesEach() async throws {
        // Given
        let expense = makeTestExpense(amount: 1000.0)
        let newAmount = 1500.0
        let scenario1 = "scenario-1"
        let scenario2 = "scenario-2"
        
        let allocation1 = makeTestAllocation(
            expenseId: expense.id,
            budgetItemId: "item-1",
            amount: 500.0,
            scenarioId: scenario1
        )
        let allocation2 = makeTestAllocation(
            expenseId: expense.id,
            budgetItemId: "item-2",
            amount: 500.0,
            scenarioId: scenario1
        )
        let allocation3 = makeTestAllocation(
            expenseId: expense.id,
            budgetItemId: "item-3",
            amount: 1000.0,
            scenarioId: scenario2
        )
        
        mockRepository.allocationsForExpenseAllScenarios = [allocation1, allocation2, allocation3]
        mockRepository.budgetItems = [
            makeTestBudgetItem(id: "item-1", amount: 300.0),
            makeTestBudgetItem(id: "item-2", amount: 700.0),
            makeTestBudgetItem(id: "item-3", amount: 1000.0)
        ]
        
        // When
        try await service.recalculateExpenseAllocationsForAllScenarios(
            expenseId: expense.id,
            newAmount: newAmount
        )
        
        // Then - Should have replaced allocations for scenario1 (2 allocations)
        // scenario2 has only 1 allocation so it won't be recalculated
        XCTAssertEqual(mockRepository.replacedAllocations.count, 2)
        
        let totalAllocated = mockRepository.replacedAllocations.reduce(0.0) { $0 + $1.allocatedAmount }
        XCTAssertEqual(totalAllocated, newAmount, accuracy: 0.01)
    }
    
    func test_recalculateExpenseAllocationsForAllScenarios_withNoAllocations_doesNothing() async throws {
        // Given
        let expense = makeTestExpense(amount: 1000.0)
        mockRepository.allocationsForExpenseAllScenarios = []
        
        // When
        try await service.recalculateExpenseAllocationsForAllScenarios(
            expenseId: expense.id,
            newAmount: 1500.0
        )
        
        // Then
        XCTAssertTrue(mockRepository.replacedAllocations.isEmpty)
    }
    
    // MARK: - Edge Cases
    
    func test_linkExpenseProportionally_withVerySmallAmounts_handlesCorrectly() async throws {
        // Given
        let expense = makeTestExpense(amount: 0.01)
        let budgetItemId = "item-1"
        let budgetItem = makeTestBudgetItem(id: budgetItemId, amount: 100.0)
        
        mockRepository.allocationsForExpense = []
        mockRepository.budgetItems = [budgetItem]
        
        // When
        try await service.linkExpenseProportionally(
            expense: expense,
            to: budgetItemId,
            inScenario: testScenarioId
        )
        
        // Then
        XCTAssertEqual(mockRepository.replacedAllocations.count, 1)
        XCTAssertEqual(mockRepository.replacedAllocations.first?.allocatedAmount, 0.01, accuracy: 0.001)
    }
    
    func test_linkExpenseProportionally_withVeryLargeAmounts_handlesCorrectly() async throws {
        // Given
        let expense = makeTestExpense(amount: 1_000_000.0)
        let item1Id = "item-1"
        let item2Id = "item-2"
        
        let budgetItem1 = makeTestBudgetItem(id: item1Id, amount: 500_000.0)
        let budgetItem2 = makeTestBudgetItem(id: item2Id, amount: 500_000.0)
        
        mockRepository.allocationsForExpense = []
        mockRepository.budgetItems = [budgetItem1, budgetItem2]
        
        // When
        try await service.linkExpenseProportionally(
            expense: expense,
            to: item1Id,
            inScenario: testScenarioId
        )
        
        // Then
        let totalAllocated = mockRepository.replacedAllocations.reduce(0.0) { $0 + $1.allocatedAmount }
        XCTAssertEqual(totalAllocated, 1_000_000.0, accuracy: 0.01)
    }
    
    // MARK: - Helper Methods
    
    private func makeTestExpense(amount: Double) -> Expense {
        Expense(
            id: UUID(),
            expenseName: "Test Expense",
            amount: amount,
            paidDate: Date(),
            paymentMethod: "Credit Card",
            notes: nil,
            receiptUrl: nil,
            coupleId: testCoupleId,
            createdAt: Date(),
            updatedAt: nil,
            isTestData: true
        )
    }
    
    private func makeTestBudgetItem(id: String, amount: Double) -> BudgetDevelopmentItem {
        BudgetDevelopmentItem(
            id: id,
            scenarioId: testScenarioId,
            categoryId: UUID(),
            categoryName: "Test Category",
            itemName: "Test Item",
            vendorEstimate: amount,
            taxRate: 0.0,
            vendorEstimateWithTax: amount,
            actualCost: nil,
            notes: nil,
            priority: 1,
            isLocked: false,
            coupleId: testCoupleId,
            createdAt: Date(),
            updatedAt: nil,
            isTestData: true
        )
    }
    
    private func makeTestAllocation(
        expenseId: UUID,
        budgetItemId: String,
        amount: Double,
        scenarioId: String? = nil
    ) -> ExpenseAllocation {
        ExpenseAllocation(
            id: UUID().uuidString,
            expenseId: expenseId.uuidString,
            budgetItemId: budgetItemId,
            allocatedAmount: amount,
            percentage: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: nil,
            coupleId: testCoupleId.uuidString,
            scenarioId: scenarioId ?? testScenarioId,
            isTestData: true
        )
    }
}
