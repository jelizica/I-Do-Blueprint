import Foundation

// MARK: - BudgetAggregationService

/// Handles complex budget data aggregation and calculations.
actor BudgetAggregationService: BudgetAggregationServiceProtocol {
    private let repository: BudgetRepositoryProtocol

    init(repository: BudgetRepositoryProtocol) {
        self.repository = repository
    }

    /// Fetches budget items with spent amounts and gift contributions
    func fetchBudgetOverview(scenarioId: String) async throws -> [BudgetOverviewItem] {
        // 1) Fetch base data
        async let itemsAsync = repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
        async let expensesAsync = repository.fetchExpenses()
        async let giftsAsync = repository.fetchGiftsAndOwed()

        let items = try await itemsAsync
        let expenses = try await expensesAsync
        let gifts = try await giftsAsync

        // Build lookup dictionaries
        let expenseById: [String: String] = Dictionary(
            uniqueKeysWithValues: expenses.map { ($0.id.uuidString.lowercased(), $0.expenseName) }
        )
        let giftById: [String: (id: String, title: String, amount: Double)] = Dictionary(
            uniqueKeysWithValues: gifts.map { ($0.id.uuidString.lowercased(), (id: $0.id.uuidString, title: $0.title, amount: $0.amount)) }
        )

        // 2) Fetch bill totals for all expenses in parallel (optimization to avoid N+1 queries)
        let expenseBillTotals = try await fetchBillTotalsForExpenses(expenses: expenses)

        // 3) For each item, gather allocations and build overview
        var overview: [BudgetOverviewItem] = []
        overview.reserveCapacity(items.count)

        // Fetch all allocations for the scenario in a single call to avoid N+1 queries
        let allAllocations = try await repository.fetchExpenseAllocationsForScenario(scenarioId: scenarioId)
        let allocationsByItem: [String: [ExpenseAllocation]] = Dictionary(grouping: allAllocations, by: { $0.budgetItemId })

        for item in items {
            // Look up allocations already fetched for this item
            let allocations = allocationsByItem[item.id] ?? []

            // Map to ExpenseLinks, using bill total if available, otherwise allocated amount
            let expenseLinks: [ExpenseLink] = allocations.compactMap { alloc in
                let key = alloc.expenseId.lowercased()
                guard let title = expenseById[key] else { return nil }

                // Check if this expense has a linked bill calculator
                let amount: Double
                if let expenseUUID = UUID(uuidString: alloc.expenseId),
                   let billTotal = expenseBillTotals[expenseUUID] {
                    // Bill calculator wins - use bill total instead of allocated amount
                    amount = billTotal.totalAmount
                } else {
                    // No bill linked - use manual allocation
                    amount = alloc.allocatedAmount
                }

                return ExpenseLink(id: alloc.expenseId, title: title, amount: amount)
            }

            let totalSpent = expenseLinks.reduce(0.0) { $0 + $1.amount }

            // Linked gift handling
            var giftLinks: [GiftLink] = []
            var totalGiftAmount = 0.0
            if let giftId = item.linkedGiftOwedId, let gift = giftById[giftId.lowercased()] {
                giftLinks = [GiftLink(id: gift.id, title: gift.title, amount: gift.amount)]
                totalGiftAmount = gift.amount
            }

            let effectiveSpent = max(0, totalSpent - totalGiftAmount)

            overview.append(
                BudgetOverviewItem(
                    id: item.id,
                    itemName: item.itemName,
                    category: item.category,
                    subcategory: item.subcategory ?? "",
                    budgeted: item.vendorEstimateWithTax,
                    spent: totalSpent,
                    effectiveSpent: effectiveSpent,
                    expenses: expenseLinks,
                    gifts: giftLinks,
                    isFolder: item.isFolder,
                    parentFolderId: item.parentFolderId,
                    displayOrder: item.displayOrder
                )
            )
        }

        return overview
    }

    // MARK: - Private Helpers

    /// Fetches bill totals for all expenses in parallel
    /// - Parameter expenses: Array of expenses to check for bill links
    /// - Returns: Dictionary mapping expense UUID to ExpenseBillTotal
    private func fetchBillTotalsForExpenses(expenses: [Expense]) async throws -> [UUID: ExpenseBillTotal] {
        // Fetch bill totals for all expenses in parallel
        let billTotals = try await withThrowingTaskGroup(of: (UUID, ExpenseBillTotal?).self) { group in
            for expense in expenses {
                group.addTask {
                    let billTotal = try await self.repository.fetchBillTotalForExpense(expenseId: expense.id)
                    return (expense.id, billTotal)
                }
            }

            var result: [UUID: ExpenseBillTotal] = [:]
            for try await (expenseId, billTotal) in group {
                if let billTotal = billTotal {
                    result[expenseId] = billTotal
                }
            }
            return result
        }

        return billTotals
    }
}
