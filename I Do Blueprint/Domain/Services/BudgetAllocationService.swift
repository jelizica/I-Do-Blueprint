import Foundation

// MARK: - BudgetAllocationService

/// Handles complex budget allocation calculations and redistribution.
actor BudgetAllocationService: BudgetAllocationServiceProtocol {
    private let repository: BudgetRepositoryProtocol
    private let logger = AppLogger.general

    init(repository: BudgetRepositoryProtocol) {
        self.repository = repository
    }

    // Adds or links an expense to a budget item, then rebalances allocations proportionally
    func linkExpenseProportionally(expense: Expense, to budgetItemId: String, inScenario scenarioId: String) async throws {
        logger.info("[BudgetAllocationService] Linking expense \(expense.id) to item \(budgetItemId) with proportional rebalance in scenario \(scenarioId)")

        // 1) Fetch existing allocations for this expense in the scenario
        let existing = try await repository.fetchAllocationsForExpense(expenseId: expense.id, scenarioId: scenarioId)

        // 2) Compute the affected item ids (existing + new)
        var affectedItemIds = Set(existing.map { $0.budgetItemId.lowercased() })
        affectedItemIds.insert(budgetItemId.lowercased())

        // 3) Fetch scenario items to get budgeted amounts for affected ids
        let items = try await repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
        let budgetById = Dictionary(uniqueKeysWithValues: items.map { ($0.id.lowercased(), $0.vendorEstimateWithTax) })
        let keys = affectedItemIds.filter { budgetById[$0] != nil }
        let totalBudgeted = keys.compactMap { budgetById[$0] }.reduce(0, +)

        // 4) Build new allocation set using proportional weights (fallback: 100% to target item)
        let coupleId = existing.first?.coupleId ?? items.first?.coupleId.uuidString ?? ""
        let isTest = existing.first?.isTestData
        let amount = expense.amount

        var allocations: [ExpenseAllocation] = []
        if totalBudgeted > 0 {
            // Round to cents and fix rounding residue on the last element
            var remaining = amount
            for (idx, key) in keys.enumerated() {
                let weight = budgetById[key]! / totalBudgeted
                var value = amount * weight
                // round to 2 decimals
                value = (value * 100).rounded() / 100
                if idx == keys.count - 1 { value = (remaining * 100).rounded() / 100 }
                remaining -= value
                allocations.append(
                    ExpenseAllocation(
                        id: UUID().uuidString,
                        expenseId: expense.id.uuidString,
                        budgetItemId: key,
                        allocatedAmount: value,
                        percentage: nil,
                        notes: nil,
                        createdAt: Date(),
                        updatedAt: nil,
                        coupleId: coupleId,
                        scenarioId: scenarioId,
                        isTestData: isTest
                    )
                )
            }
        } else {
            // If we can't compute weights, allocate entire amount to the requested item
            allocations = [
                ExpenseAllocation(
                    id: UUID().uuidString,
                    expenseId: expense.id.uuidString,
                    budgetItemId: budgetItemId,
                    allocatedAmount: amount,
                    percentage: nil,
                    notes: nil,
                    createdAt: Date(),
                    updatedAt: nil,
                    coupleId: coupleId,
                    scenarioId: scenarioId,
                    isTestData: isTest
                )
            ]
        }

        // 5) Atomically replace allocations to avoid validation errors (P0006)
        try await repository.replaceAllocations(expenseId: expense.id, scenarioId: scenarioId, with: allocations)
    }

    // Recalculates proportional allocations when a budget item amount changes
    func recalculateAllocations(budgetItemId: String, scenarioId: String) async throws {
        logger.info("[BudgetAllocationService] Recalculating allocations for budget item \(budgetItemId) in scenario \(scenarioId)")

        // 1) Fetch allocations linked to this budget item to discover affected expenses
        let allocationsForItem = try await repository.fetchExpenseAllocations(scenarioId: scenarioId, budgetItemId: budgetItemId)
        guard !allocationsForItem.isEmpty else { return }
        let affectedExpenseIds = Array(Set(allocationsForItem.compactMap { UUID(uuidString: $0.expenseId) }))

        // 2) Fetch all expenses and items in scenario for proportion calculations
        async let expensesAsync = repository.fetchExpenses()
        async let itemsAsync = repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
        let (allExpenses, items) = try await (expensesAsync, itemsAsync)
        let expenseAmountById = Dictionary(uniqueKeysWithValues: allExpenses.map { ($0.id, $0.amount) })
        let itemBudgetById = Dictionary(uniqueKeysWithValues: items.map { ($0.id.lowercased(), $0.vendorEstimateWithTax) })

        // 3) For each expense, recompute proportions and replace
        for expenseId in affectedExpenseIds {
            // a) Fetch all allocations for this expense within the scenario
            let allocations = try await repository.fetchAllocationsForExpense(expenseId: expenseId, scenarioId: scenarioId)
            guard allocations.count > 1 else { continue }

            // b) Use Set to avoid duplicate budget item IDs
            let uniqueKeys = Set(allocations.compactMap { alloc -> String? in
                let key = alloc.budgetItemId.lowercased()
                return itemBudgetById[key] != nil ? key : nil
            })
            let keys = Array(uniqueKeys)
            let totalBudgeted = keys.compactMap { itemBudgetById[$0] }.reduce(0, +)
            guard totalBudgeted > 0 else { continue }

            let amount = expenseAmountById[expenseId] ?? 0
            let baseCoupleId = allocations.first?.coupleId ?? ""
            let isTest = allocations.first?.isTestData

            // c) Build allocations with proper rounding and residue correction
            var newAllocations: [ExpenseAllocation] = []
            var remaining = amount
            for (idx, key) in keys.enumerated() {
                guard let budgeted = itemBudgetById[key] else { continue }
                let weight = budgeted / totalBudgeted
                var value = amount * weight
                // Round to 2 decimals
                value = (value * 100).rounded() / 100
                // Last item gets remaining to ensure sum matches exactly
                if idx == keys.count - 1 {
                    value = (remaining * 100).rounded() / 100
                }
                remaining -= value

                newAllocations.append(
                    ExpenseAllocation(
                        id: UUID().uuidString,
                        expenseId: expenseId.uuidString,
                        budgetItemId: key,
                        allocatedAmount: value,
                        percentage: nil,
                        notes: nil,
                        createdAt: Date(),
                        updatedAt: nil,
                        coupleId: baseCoupleId,
                        scenarioId: scenarioId,
                        isTestData: isTest
                    )
                )
            }

            try await repository.replaceAllocations(expenseId: expenseId, scenarioId: scenarioId, with: newAllocations)
        }
    }

    // Recalculates allocations when an expense amount changes (single scenario)
    func recalculateExpenseAllocations(expenseId: UUID, scenarioId: String) async throws {
        logger.info("[BudgetAllocationService] Recalculating allocations for expense \(expenseId) in scenario \(scenarioId)")

        // Fetch allocations and scenario items
        async let allocationsAsync = repository.fetchAllocationsForExpense(expenseId: expenseId, scenarioId: scenarioId)
        async let itemsAsync = repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
        async let expensesAsync = repository.fetchExpenses()
        let (allocations, items, expenses) = try await (allocationsAsync, itemsAsync, expensesAsync)
        guard allocations.count > 1 else { return }

        let itemBudgetById = Dictionary(uniqueKeysWithValues: items.map { ($0.id.lowercased(), $0.vendorEstimateWithTax) })
        let expenseAmount = expenses.first(where: { $0.id == expenseId })?.amount ?? 0
        let baseCoupleId = allocations.first?.coupleId ?? ""
        let isTest = allocations.first?.isTestData

        // Use Set to avoid duplicate budget item IDs (matches linkExpenseProportionally behavior)
        let uniqueKeys = Set(allocations.compactMap { alloc -> String? in
            let key = alloc.budgetItemId.lowercased()
            return itemBudgetById[key] != nil ? key : nil
        })
        let keys = Array(uniqueKeys)
        let totalBudgeted = keys.compactMap { itemBudgetById[$0] }.reduce(0, +)
        guard totalBudgeted > 0 else { return }

        // Build allocations with proper rounding and residue correction (matches linkExpenseProportionally)
        var newAllocations: [ExpenseAllocation] = []
        var remaining = expenseAmount
        for (idx, key) in keys.enumerated() {
            guard let budgeted = itemBudgetById[key] else { continue }
            let weight = budgeted / totalBudgeted
            var value = expenseAmount * weight
            // Round to 2 decimals
            value = (value * 100).rounded() / 100
            // Last item gets remaining to ensure sum matches exactly
            if idx == keys.count - 1 {
                value = (remaining * 100).rounded() / 100
            }
            remaining -= value

            newAllocations.append(
                ExpenseAllocation(
                    id: UUID().uuidString,
                    expenseId: expenseId.uuidString,
                    budgetItemId: key,
                    allocatedAmount: value,
                    percentage: nil,
                    notes: nil,
                    createdAt: Date(),
                    updatedAt: nil,
                    coupleId: baseCoupleId,
                    scenarioId: scenarioId,
                    isTestData: isTest
                )
            )
        }

        try await repository.replaceAllocations(expenseId: expenseId, scenarioId: scenarioId, with: newAllocations)
    }

    func recalculateExpenseAllocationsForAllScenarios(expenseId: UUID, newAmount: Double) async throws {
        logger.info("[BudgetAllocationService] Recalculating allocations for expense \(expenseId) across all scenarios with amount \(newAmount)")
        // Fetch all allocations for the expense across scenarios
        let allAllocations = try await repository.fetchAllocationsForExpenseAllScenarios(expenseId: expenseId)
        guard !allAllocations.isEmpty else { return }
        let groups = Dictionary(grouping: allAllocations, by: { $0.scenarioId })

        // For each scenario, compute using scenario's items
        for (scenarioId, allocations) in groups {
            let items = try await repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
            let itemBudgetById = Dictionary(uniqueKeysWithValues: items.map { ($0.id.lowercased(), $0.vendorEstimateWithTax) })
            let baseCoupleId = allocations.first?.coupleId ?? ""
            let isTest = allocations.first?.isTestData

            // Use Set to avoid duplicate budget item IDs (matches linkExpenseProportionally behavior)
            let uniqueKeys = Set(allocations.compactMap { alloc -> String? in
                let key = alloc.budgetItemId.lowercased()
                return itemBudgetById[key] != nil ? key : nil
            })
            let keys = Array(uniqueKeys)
            let totalBudgeted = keys.compactMap { itemBudgetById[$0] }.reduce(0, +)
            guard totalBudgeted > 0 else { continue }

            // Build allocations with proper rounding and residue correction (matches linkExpenseProportionally)
            var newAllocations: [ExpenseAllocation] = []
            var remaining = newAmount
            for (idx, key) in keys.enumerated() {
                guard let budgeted = itemBudgetById[key] else { continue }
                let weight = budgeted / totalBudgeted
                var value = newAmount * weight
                // Round to 2 decimals
                value = (value * 100).rounded() / 100
                // Last item gets remaining to ensure sum matches exactly
                if idx == keys.count - 1 {
                    value = (remaining * 100).rounded() / 100
                }
                remaining -= value

                newAllocations.append(
                    ExpenseAllocation(
                        id: UUID().uuidString,
                        expenseId: expenseId.uuidString,
                        budgetItemId: key,
                        allocatedAmount: value,
                        percentage: nil,
                        notes: nil,
                        createdAt: Date(),
                        updatedAt: nil,
                        coupleId: baseCoupleId,
                        scenarioId: scenarioId,
                        isTestData: isTest
                    )
                )
            }

            try await repository.replaceAllocations(expenseId: expenseId, scenarioId: scenarioId, with: newAllocations)
        }
    }
}
