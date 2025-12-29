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
    
    // MARK: - Dependencies
    
    @Dependency(\.budgetRepository) var repository
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
    
    /// Load all expenses
    func loadExpenses() async {
        isLoading = true
        error = nil
        
        do {
            expenses = try await repository.fetchExpenses()
            logger.info("Loaded \(expenses.count) expenses")
        } catch {
            self.error = .fetchFailed(underlying: error)
            logger.error("Failed to load expenses", error: error)
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
        } catch {
            self.error = .createFailed(underlying: error)
            logger.error("Error adding expense", error: error)
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
        } catch {
            // Rollback on error
            if let idx = expenses.firstIndex(where: { $0.id == expense.id }) {
                expenses[idx] = original
            }
            self.error = .updateFailed(underlying: error)
            logger.error("Error updating expense", error: error)
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
        } catch {
            // Rollback on error
            expenses.insert(removed, at: index)
            self.error = .deleteFailed(underlying: error)
            logger.error("Error deleting expense, rolled back", error: error)
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
    
    // MARK: - State Management
    
    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        expenses = []
        isLoading = false
        error = nil
    }
}
