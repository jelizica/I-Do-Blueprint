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
        let expenseById: [String: (name: String, amount: Double)] = Dictionary(
            uniqueKeysWithValues: expenses.map { ($0.id.uuidString.lowercased(), (name: $0.expenseName, amount: $0.amount)) }
        )
        let giftById: [String: (id: String, title: String, amount: Double)] = Dictionary(
            uniqueKeysWithValues: gifts.map { ($0.id.uuidString.lowercased(), (id: $0.id.uuidString, title: $0.title, amount: $0.amount)) }
        )

        // 2) Fetch bill totals for all expenses in parallel (optimization to avoid N+1 queries)
        let expenseBillTotals = try await fetchBillTotalsForExpenses(expenses: expenses)

        // 3) For each item, gather allocations and build overview
        var overview: [BudgetOverviewItem] = []
        overview.reserveCapacity(items.count)

        // Fetch all expense allocations for the scenario in a single call to avoid N+1 queries
        let allAllocations = try await repository.fetchExpenseAllocationsForScenario(scenarioId: scenarioId)
        let allocationsByItem: [String: [ExpenseAllocation]] = Dictionary(grouping: allAllocations, by: { $0.budgetItemId })

        // Fetch all gift allocations for the scenario in a single call (new proportional allocation system)
        let allGiftAllocations = try await repository.fetchGiftAllocationsForScenario(scenarioId: scenarioId)
        let giftAllocationsByItem: [String: [GiftAllocation]] = Dictionary(grouping: allGiftAllocations, by: { $0.budgetItemId.lowercased() })

        for item in items {
            // Look up allocations already fetched for this item
            let allocations = allocationsByItem[item.id] ?? []

            // Map to ExpenseLinks, applying allocation percentages to bill total if available
            let expenseLinks: [ExpenseLink] = allocations.compactMap { alloc in
                let key = alloc.expenseId.lowercased()
                guard let expenseData = expenseById[key] else { return nil }

                // Calculate amount using allocation percentage applied to bill total
                let amount: Double
                if let expenseUUID = UUID(uuidString: alloc.expenseId),
                   let billTotal = expenseBillTotals[expenseUUID],
                   expenseData.amount > 0 {
                    // Bill calculator wins - apply allocation percentage to bill total
                    // Percentage = allocatedAmount / expenseAmount
                    // Bill-based amount = percentage × billTotal
                    // Simplified: (allocatedAmount / expenseAmount) × billTotal
                    let percentage = alloc.allocatedAmount / expenseData.amount
                    amount = percentage * billTotal.totalAmount
                } else {
                    // No bill linked or expense amount is zero - use manual allocation
                    amount = alloc.allocatedAmount
                }

                return ExpenseLink(id: alloc.expenseId, title: expenseData.name, amount: amount)
            }

            let totalSpent = expenseLinks.reduce(0.0) { $0 + $1.amount }

            // Gift handling - prioritize new proportional allocations, fallback to legacy 1:1 linking
            var giftLinks: [GiftLink] = []
            var totalGiftAmount = 0.0

            // Check for new proportional gift allocations first
            let giftAllocations = giftAllocationsByItem[item.id.lowercased()] ?? []
            if !giftAllocations.isEmpty {
                // Use new proportional allocation system
                giftLinks = giftAllocations.compactMap { alloc in
                    guard let giftData = giftById[alloc.giftId.lowercased()] else { return nil }
                    return GiftLink(id: giftData.id, title: giftData.title, amount: alloc.allocatedAmount)
                }
                totalGiftAmount = giftLinks.reduce(0.0) { $0 + $1.amount }
            } else if let giftId = item.linkedGiftOwedId, let gift = giftById[giftId.lowercased()] {
                // Fallback to legacy 1:1 linking for backward compatibility
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
