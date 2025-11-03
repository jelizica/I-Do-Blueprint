//
//  BudgetStoreV2+Expenses.swift
//  I Do Blueprint
//
//  Expense operations for BudgetStoreV2
//

import Foundation
import Supabase

// MARK: - Expense Operations

extension BudgetStoreV2 {

    // MARK: - Expense Loading

    /// Load expenses (compatibility method - expenses are loaded with loadBudgetData)
    func loadExpenses() async {
        // Expenses are loaded as part of loadBudgetData()
        // This method exists for compatibility
        await loadBudgetData()
    }

    // MARK: - Expense CRUD Operations

    /// Add a new expense
    func addExpense(_ expense: Expense) async {
        do {
            let created = try await repository.createExpense(expense)

            if case .loaded(var budgetData) = loadingState {
                budgetData.expenses.insert(created, at: 0)
                loadingState = .loaded(budgetData)
            }

            showSuccess("Expense added successfully")
            invalidateCache()
            logger.info("Added expense: \(created.expenseName)")
        } catch {
            loadingState = .error(BudgetError.createFailed(underlying: error))
            await handleError(error, operation: "add expense") { [weak self] in
                await self?.addExpense(expense)
            }
        }
    }

    /// Create an expense (alias for addExpense for compatibility)
    func createExpense(_ expense: Expense) async {
        await addExpense(expense)
    }

    /// Update an existing expense with optimistic update
    func updateExpense(_ expense: Expense) async {
        // Optimistic update
        guard case .loaded(var budgetData) = loadingState,
              let index = budgetData.expenses.firstIndex(where: { $0.id == expense.id }) else {
            return
        }

        let original = budgetData.expenses[index]
        budgetData.expenses[index] = expense
        loadingState = .loaded(budgetData)

        do {
            let updated = try await repository.updateExpense(expense)

            if case .loaded(var data) = loadingState,
               let idx = data.expenses.firstIndex(where: { $0.id == expense.id }) {
                data.expenses[idx] = updated
                loadingState = .loaded(data)
            }

            showSuccess("Expense updated successfully")
            invalidateCache()
            logger.info("Updated expense: \(updated.expenseName)")
        } catch {
            // Rollback on error
            if case .loaded(var data) = loadingState,
               let idx = data.expenses.firstIndex(where: { $0.id == expense.id }) {
                data.expenses[idx] = original
                loadingState = .loaded(data)
            }
            loadingState = .error(BudgetError.updateFailed(underlying: error))
            await handleError(error, operation: "update expense") { [weak self] in
                await self?.updateExpense(expense)
            }
        }
    }

    /// Delete an expense with optimistic delete
    func deleteExpense(id: UUID) async {
        // Optimistic delete
        guard case .loaded(var budgetData) = loadingState,
              let index = budgetData.expenses.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = budgetData.expenses.remove(at: index)
        loadingState = .loaded(budgetData)

        do {
            try await repository.deleteExpense(id: id)
            showSuccess("Expense deleted successfully")
            invalidateCache()
            logger.info("Deleted expense: \(removed.expenseName)")
        } catch {
            // Rollback on error
            if case .loaded(var data) = loadingState {
                data.expenses.insert(removed, at: index)
                loadingState = .loaded(data)
            }
            loadingState = .error(BudgetError.deleteFailed(underlying: error))
            await handleError(error, operation: "delete expense") { [weak self] in
                await self?.deleteExpense(id: id)
            }
        }
    }

    // MARK: - Expense Helper Methods

    /// Get all expenses for a specific category
    func expensesForCategory(_ categoryId: UUID) -> [Expense] {
        expenses.filter { $0.budgetCategoryId == categoryId }
    }

    // MARK: - Expense Linking Operations

    /// Unlink an expense from a budget item
    /// - Parameters:
    ///   - expenseId: The expense UUID string
    ///   - budgetItemId: The budget item UUID string
    ///   - scenarioId: The scenario UUID string used for precise cache invalidation
    func unlinkExpense(expenseId: String, budgetItemId: String, scenarioId: String) async throws {
        // Proportional unlink: remove the specified item from the expense's allocation set,
        // then rebalance the remaining items proportionally by their budgeted amounts.
        guard let expenseUUID = UUID(uuidString: expenseId) else {
            let errorInfo = [NSLocalizedDescriptionKey: "Invalid expense UUID"]
            let error = NSError(domain: "BudgetStoreV2", code: -1, userInfo: errorInfo)
            throw BudgetError.updateFailed(underlying: error)
        }

        do {
            logger.info("Starting proportional unlink for expense_id=\(expenseId), removing budget_item_id=\(budgetItemId) in scenario=\(scenarioId)")

            async let allocationsAsync = repository.fetchAllocationsForExpense(expenseId: expenseUUID, scenarioId: scenarioId)
            async let itemsAsync = repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
            async let expensesAsync = repository.fetchExpenses()
            let (existing, items, allExpenses) = try await (allocationsAsync, itemsAsync, expensesAsync)

            // Exclude the removed item
            let removeKey = budgetItemId.lowercased()
            var remainingIds = existing.map { $0.budgetItemId.lowercased() }.filter { $0 != removeKey }

            // If nothing remains, replace with empty set (fully unlinked)
            if remainingIds.isEmpty {
                try await repository.replaceAllocations(expenseId: expenseUUID, scenarioId: scenarioId, with: [])
            } else {
                // Build weights from remaining items' vendorEstimateWithTax
                let budgetById = Dictionary(uniqueKeysWithValues: items.map { ($0.id.lowercased(), $0.vendorEstimateWithTax) })
                // Keep only ids that exist in items
                remainingIds = remainingIds.filter { budgetById[$0] != nil }

                let totalBudgeted = remainingIds.compactMap { budgetById[$0] }.reduce(0, +)
                let amount = allExpenses.first(where: { $0.id == expenseUUID })?.amount ?? 0
                let coupleId = existing.first?.coupleId ?? items.first?.coupleId ?? ""
                let isTest = existing.first?.isTestData

                var newAllocations: [ExpenseAllocation] = []
                if totalBudgeted > 0 {
                    var remaining = amount
                    for (idx, key) in remainingIds.enumerated() {
                        let weight = budgetById[key]! / totalBudgeted
                        var value = amount * weight
                        value = (value * 100).rounded() / 100 // round to cents
                        if idx == remainingIds.count - 1 { value = (remaining * 100).rounded() / 100 }
                        remaining -= value
                        newAllocations.append(
                            ExpenseAllocation(
                                id: UUID().uuidString,
                                expenseId: expenseUUID.uuidString,
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
                    // If we cannot compute weights, allocate 100% to the first remaining item
                    let target = remainingIds.first!
                    newAllocations = [
                        ExpenseAllocation(
                            id: UUID().uuidString,
                            expenseId: expenseUUID.uuidString,
                            budgetItemId: target,
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

                try await repository.replaceAllocations(expenseId: expenseUUID, scenarioId: scenarioId, with: newAllocations)
            }

            // Invalidate related caches synchronously
            let scenarioKey = scenarioId.lowercased()
            await RepositoryCache.shared.remove("budget_overview_items_\(scenarioKey)")
            await RepositoryCache.shared.remove("budget_dev_items_\(scenarioKey)")
            if let tenantId = SessionManager.shared.getTenantId()?.uuidString {
                await RepositoryCache.shared.remove("expenses_\(tenantId)")
            }

            logger.info("Proportional unlink complete and caches invalidated")
        } catch {
            logger.error("Failed proportional unlink for expense", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    /// Unlink a gift from a budget item
    func unlinkGift(budgetItemId: String) async throws {
        guard let client = SupabaseManager.shared.client else {
            throw BudgetError.updateFailed(
                underlying: SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
            )
        }

        do {
            // Update the budget item to remove the linked gift
            _ = try await client
                .from("budget_development_items")
                .update(["linked_gift_owed_id": AnyJSON.null])
                .eq("id", value: budgetItemId)
                .execute()

            logger.info("Gift unlinked successfully")
        } catch {
            logger.error("Failed to unlink gift", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }
}
