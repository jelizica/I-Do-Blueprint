import Foundation

// MARK: - BudgetAllocationServiceProtocol

/// Business logic for recalculating proportional expense allocations.
protocol BudgetAllocationServiceProtocol: Sendable {
    /// Recalculates proportional allocations when a budget item amount changes within a scenario.
    func recalculateAllocations(budgetItemId: String, scenarioId: String) async throws

    /// Recalculates proportional allocations for a single expense within a specific scenario.
    func recalculateExpenseAllocations(expenseId: UUID, scenarioId: String) async throws

    /// Recalculates proportional allocations for an expense across all scenarios using the new amount.
    func recalculateExpenseAllocationsForAllScenarios(expenseId: UUID, newAmount: Double) async throws

    /// Adds or links an expense to a budget item and rebalances all allocations proportionally
    /// across all linked items in the scenario.
    /// - Parameters:
    ///   - expense: The expense being linked
    ///   - budgetItemId: The budget item to link to
    ///   - scenarioId: The scenario in which allocations apply
    func linkExpenseProportionally(expense: Expense, to budgetItemId: String, inScenario scenarioId: String) async throws
}
