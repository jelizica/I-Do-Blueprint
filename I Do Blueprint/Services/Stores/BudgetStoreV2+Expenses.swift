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
    func unlinkExpense(expenseId: String, budgetItemId: String) async throws {
    guard let client = SupabaseManager.shared.client else {
    throw BudgetError.updateFailed(
    underlying: SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
    )
    }
    
    do {
    // Delete the allocation from expense_budget_allocations table
    logger.info("Attempting to delete allocation: expense_id=\(expenseId), budget_item_id=\(budgetItemId)")
    
    let response = try await client
    .from("expense_budget_allocations")
    .delete()
    .eq("expense_id", value: expenseId)
    .eq("budget_item_id", value: budgetItemId)
    .execute()
    
    logger.info("Delete response status: \(response.response.statusCode)")
    logger.info("Expense unlinked from database successfully")
    
    // Invalidate related caches SYNCHRONOUSLY to ensure they're cleared before any refresh
    // Use lowercase UUID to match repository cache keys
    if let scenarioId = primaryScenario?.id.uuidString.lowercased() {
    await RepositoryCache.shared.remove("budget_overview_items_\(scenarioId)")
    await RepositoryCache.shared.remove("budget_development_items_\(scenarioId)")
    logger.info("Invalidated caches for scenario: \(scenarioId)")
    }
    await RepositoryCache.shared.remove("expenses")
    
    logger.info("Expense unlink complete - caches invalidated")
    } catch {
    logger.error("Failed to unlink expense", error: error)
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
