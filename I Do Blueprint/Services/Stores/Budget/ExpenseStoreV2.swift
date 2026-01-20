//
//  ExpenseStoreV2.swift
//  I Do Blueprint
//
//  Store for managing expenses
//  Handles CRUD operations for expenses with optimistic updates
//

import Combine
import Dependencies
import Foundation
import SwiftUI

/// Store for managing expenses
/// Handles CRUD operations for expenses with optimistic updates and rollback
@MainActor
class ExpenseStoreV2: ObservableObject {
    
    // MARK: - Published State

    @Published private(set) var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var error: BudgetError?

    /// Monotonically increasing counter that views can observe to trigger refresh.
    /// Incremented when bill calculator changes invalidate expense amounts.
    @Published private(set) var refreshTrigger: Int = 0
    
    // MARK: - Dependencies

    @Dependency(\.budgetRepository) var repository
    @Dependency(\.budgetAllocationService) var allocationService
    private let logger = AppLogger.database
    
    // MARK: - Computed Properties
    
    /// Total expenses amount
    var totalExpensesAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Pending expenses
    var pendingExpenses: [Expense] {
        expenses.filter { $0.paymentStatus == .pending }
    }
    
    /// Paid expenses
    var paidExpenses: [Expense] {
        expenses.filter { $0.paymentStatus == .paid }
    }
    
    /// Overdue expenses
    var overdueExpenses: [Expense] {
        expenses.filter { $0.isOverdue }
    }
    
    // MARK: - Public Methods

    /// Update expenses from external data (e.g., from BudgetStoreV2.loadBudgetData)
    /// This avoids duplicate API calls when expenses are already fetched
    func updateExpenses(_ newExpenses: [Expense]) {
        expenses = newExpenses
        logger.info("Updated expenses from external source: \(newExpenses.count) expenses")
    }

    /// Load all expenses
    func loadExpenses() async {
        isLoading = true
        error = nil
        
        do {
            expenses = try await repository.fetchExpenses()
            logger.info("Loaded \(expenses.count) expenses")
        } catch {
            await handleError(error, operation: "loadExpenses", context: [
                "expenseCount": expenses.count
            ])
            self.error = .fetchFailed(underlying: error)
        }
        
        isLoading = false
    }
    
    /// Add a new expense
    func addExpense(_ expense: Expense) async {
        isLoading = true
        error = nil
        
        do {
            let created = try await repository.createExpense(expense)
            expenses.insert(created, at: 0)
            logger.info("Added expense: \(created.expenseName)")
            showSuccess("Expense added successfully")
        } catch {
            await handleError(error, operation: "addExpense", context: [
                "expenseName": expense.expenseName,
                "amount": expense.amount
            ]) { [weak self] in
                await self?.addExpense(expense)
            }
            self.error = .createFailed(underlying: error)
        }
        
        isLoading = false
    }
    
    /// Create an expense (alias for addExpense for compatibility)
    func createExpense(_ expense: Expense) async {
        await addExpense(expense)
    }
    
    /// Update an existing expense with optimistic update
    func updateExpense(_ expense: Expense) async {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else {
            return
        }
        
        // Optimistic update - update UI immediately
        let original = expenses[index]
        expenses[index] = expense
        
        do {
            let updated = try await repository.updateExpense(expense)
            
            if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
                expenses[idx] = updated
            }
            
            logger.info("Updated expense: \(updated.expenseName)")
            showSuccess("Expense updated successfully")
        } catch {
            // Rollback on error
            if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
                expenses[idx] = original
            }
            await handleError(error, operation: "updateExpense", context: [
                "expenseId": expense.id.uuidString,
                "expenseName": expense.expenseName
            ]) { [weak self] in
                await self?.updateExpense(expense)
            }
            self.error = .updateFailed(underlying: error)
        }
    }
    
    /// Delete an expense with optimistic delete
    func deleteExpense(id: UUID) async {
        guard let index = expenses.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        // Optimistic delete
        let removed = expenses.remove(at: index)
        
        do {
            try await repository.deleteExpense(id: id)
            logger.info("Deleted expense: \(removed.expenseName)")
            showSuccess("Expense deleted successfully")
        } catch {
            // Rollback on error
            expenses.insert(removed, at: index)
            await handleError(error, operation: "deleteExpense", context: [
                "expenseId": id.uuidString,
                "expenseName": removed.expenseName
            ]) { [weak self] in
                await self?.deleteExpense(id: id)
            }
            self.error = .deleteFailed(underlying: error)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get all expenses for a specific category
    func expensesForCategory(_ categoryId: UUID) -> [Expense] {
        expenses.filter { $0.budgetCategoryId == categoryId }
    }
    
    /// Get all expenses for a specific vendor
    func expensesForVendor(_ vendorId: Int64) -> [Expense] {
        expenses.filter { $0.vendorId == vendorId }
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
            let error = NSError(domain: "ExpenseStoreV2", code: -1, userInfo: errorInfo)
            throw BudgetError.updateFailed(underlying: error)
        }
        
        do {
            logger.info("Starting proportional unlink for expense_id=\(expenseId), removing budget_item_id=\(budgetItemId) in scenario=\(scenarioId)")
            
            async let allocationsAsync = repository.fetchAllocationsForExpense(expenseId: expenseUUID, scenarioId: scenarioId)
            async let itemsAsync = repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
            let (existing, items) = try await (allocationsAsync, itemsAsync)
            
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
                let amount = expenses.first(where: { $0.id == expenseUUID })?.amount ?? 0
                let coupleId = existing.first?.coupleId ?? items.first?.coupleId.uuidString ?? ""
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
            // Note: scenarioId should NOT be lowercased - it must match the exact cache key format
            await RepositoryCache.shared.remove("budget_overview_items_\(scenarioId)")
            await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
            if let tenantId = SessionManager.shared.getTenantId()?.uuidString {
                await RepositoryCache.shared.remove("expenses_\(tenantId)")
            }
            
            logger.info("Proportional unlink complete and caches invalidated")
        } catch {
            await handleError(error, operation: "unlinkExpense", context: [
                "expenseId": expenseId,
                "budgetItemId": budgetItemId,
                "scenarioId": scenarioId
            ])
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    // MARK: - State Management

    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        expenses = []
        isLoading = false
        error = nil
    }

    // MARK: - Bill Calculator Sync

    /// Called when bill calculator changes may have affected linked expense amounts.
    /// The database trigger updates expense amounts, so we need to:
    /// 1. Reload expenses to get the updated amounts
    /// 2. Recalculate allocations for affected expenses (proportional redistribution)
    /// 3. Increment refresh trigger so views re-render
    /// - Parameter billCalculatorId: Optional bill calculator ID to recalculate allocations for linked expenses
    func invalidateCachesForBillCalculatorChange(billCalculatorId: UUID? = nil) async {
        logger.info("Invalidating expense caches due to bill calculator change")

        // Reload expenses to get updated amounts from database
        await loadExpenses()

        // Recalculate allocations for expenses linked to the changed bill calculator
        if let calculatorId = billCalculatorId {
            await recalculateAllocationsForLinkedExpenses(billCalculatorId: calculatorId)
        }

        // Increment refresh trigger to notify views
        refreshTrigger += 1

        logger.info("Expense refresh triggered (trigger: \(refreshTrigger))")
    }

    /// Recalculates allocations for all expenses linked to a bill calculator.
    /// Called after bill calculator changes to ensure expense allocations reflect the new amounts.
    private func recalculateAllocationsForLinkedExpenses(billCalculatorId: UUID) async {
        do {
            // Get all expense links for this bill calculator
            let links = try await repository.fetchExpenseLinksForBillCalculator(billCalculatorId: billCalculatorId)
            guard !links.isEmpty else {
                logger.info("No expenses linked to bill calculator \(billCalculatorId)")
                return
            }

            // Get unique expense IDs
            let expenseIds = Set(links.map { $0.expenseId })
            logger.info("Recalculating allocations for \(expenseIds.count) expenses linked to bill calculator \(billCalculatorId)")

            // Get updated expense amounts from our reloaded expenses
            let expenseAmounts = Dictionary(uniqueKeysWithValues: expenses.map { ($0.id, $0.amount) })

            // Recalculate allocations for each affected expense
            for expenseId in expenseIds {
                guard let newAmount = expenseAmounts[expenseId] else {
                    logger.warning("Expense \(expenseId) not found in loaded expenses, skipping allocation recalculation")
                    continue
                }

                do {
                    try await allocationService.recalculateExpenseAllocationsForAllScenarios(
                        expenseId: expenseId,
                        newAmount: newAmount
                    )
                    logger.info("Recalculated allocations for expense \(expenseId) with new amount \(newAmount)")
                } catch {
                    // Log but don't fail the whole operation if one expense fails
                    logger.error("Failed to recalculate allocations for expense \(expenseId)", error: error)
                }
            }
        } catch {
            logger.error("Failed to fetch expense links for bill calculator \(billCalculatorId)", error: error)
        }
    }
}
