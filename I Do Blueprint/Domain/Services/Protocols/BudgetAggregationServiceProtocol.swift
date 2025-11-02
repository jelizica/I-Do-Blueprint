import Foundation

// MARK: - BudgetAggregationServiceProtocol

/// Business logic for aggregating budget data for overview screens.
protocol BudgetAggregationServiceProtocol: Sendable {
    /// Fetches budget overview items (spent, effectiveSpent, expense links, and gifts) for a scenario.
    func fetchBudgetOverview(scenarioId: String) async throws -> [BudgetOverviewItem]
}
