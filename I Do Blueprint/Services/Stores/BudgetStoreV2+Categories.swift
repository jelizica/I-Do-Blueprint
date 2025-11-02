//
//  BudgetStoreV2+Categories.swift
//  I Do Blueprint
//
//  Category operations for BudgetStoreV2
//

import Foundation

// MARK: - Category Operations

extension BudgetStoreV2 {
    
    // MARK: - Category CRUD Operations
    
    /// Add a new budget category
    func addCategory(_ category: BudgetCategory) async {
        do {
            let created = try await repository.createCategory(category)
            
            if case .loaded(var budgetData) = loadingState {
                budgetData.categories.append(created)
                budgetData.categories.sort { $0.priorityLevel < $1.priorityLevel }
                loadingState = .loaded(budgetData)
            }
            
            showSuccess("Category added successfully")
            // Store-level cache invalidation on mutation
            invalidateCache()
            logger.info("Added category: \(created.categoryName)" )
        } catch {
            loadingState = .error(BudgetError.createFailed(underlying: error))
            await handleError(error, operation: "add category") { [weak self] in
                await self?.addCategory(category)
            }
        }
    }
    
    /// Update an existing budget category with optimistic update
    func updateCategory(_ category: BudgetCategory) async {
        // Optimistic update
        guard case .loaded(var budgetData) = loadingState,
              let index = budgetData.categories.firstIndex(where: { $0.id == category.id }) else {
            return
        }
        
        let original = budgetData.categories[index]
        budgetData.categories[index] = category
        loadingState = .loaded(budgetData)
        
        do {
            let updated = try await repository.updateCategory(category)
            
            if case .loaded(var data) = loadingState,
               let idx = data.categories.firstIndex(where: { $0.id == category.id }) {
                data.categories[idx] = updated
                loadingState = .loaded(data)
            }
            
            showSuccess("Category updated successfully")
            invalidateCache()
            logger.info("Updated category: \(updated.categoryName)")
        } catch {
            // Rollback on error
            if case .loaded(var data) = loadingState,
               let idx = data.categories.firstIndex(where: { $0.id == category.id }) {
                data.categories[idx] = original
                loadingState = .loaded(data)
            }
            loadingState = .error(BudgetError.updateFailed(underlying: error))
            await handleError(error, operation: "update category") { [weak self] in
                await self?.updateCategory(category)
            }
        }
    }
    
    /// Delete a budget category with optimistic delete
    func deleteCategory(id: UUID) async {
        // Optimistic delete
        guard case .loaded(var budgetData) = loadingState,
              let index = budgetData.categories.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let removed = budgetData.categories.remove(at: index)
        loadingState = .loaded(budgetData)
        
        do {
            try await repository.deleteCategory(id: id)
            showSuccess("Category deleted successfully")
            invalidateCache()
            logger.info("Deleted category: \(removed.categoryName)")
        } catch {
            // Rollback on error
            if case .loaded(var data) = loadingState {
                data.categories.insert(removed, at: index)
                loadingState = .loaded(data)
            }
            loadingState = .error(BudgetError.deleteFailed(underlying: error))
            await handleError(error, operation: "delete category") { [weak self] in
                await self?.deleteCategory(id: id)
            }
        }
    }
    
    // MARK: - Category Filtering and Sorting
    
    /// Filter categories based on the specified filter option
    func filteredCategories(by filter: BudgetFilterOption) -> [BudgetCategory] {
        switch filter {
        case .all:
            return categories
        case .overBudget:
            return categories.filter { $0.spentAmount > $0.allocatedAmount }
        case .onTrack:
            return categories.filter { $0.spentAmount <= $0.allocatedAmount }
        case .underBudget:
            return categories.filter { $0.spentAmount < $0.allocatedAmount }
        case .highPriority:
            return categories.filter { $0.priorityLevel <= 2 }
        case .essential:
            return categories.filter { $0.isEssential == true }
        }
    }
    
    /// Sort categories based on the specified sort option
    func sortedCategories(
        _ categories: [BudgetCategory],
        by sort: BudgetSortOption,
        ascending: Bool
    ) -> [BudgetCategory] {
        let sorted: [BudgetCategory]
        switch sort {
        case .category:
            sorted = categories.sorted { $0.categoryName < $1.categoryName }
        case .amount:
            sorted = categories.sorted { $0.allocatedAmount < $1.allocatedAmount }
        case .spent:
            sorted = categories.sorted { $0.spentAmount < $1.spentAmount }
        case .remaining:
            sorted = categories.sorted { 
                ($0.allocatedAmount - $0.spentAmount) < ($1.allocatedAmount - $1.spentAmount) 
            }
        case .priority:
            sorted = categories.sorted { $0.priorityLevel < $1.priorityLevel }
        case .dueDate:
            // Categories don't have due dates, so sort by priority as fallback
            sorted = categories.sorted { $0.priorityLevel < $1.priorityLevel }
        }
        return ascending ? sorted : sorted.reversed()
    }
    
    // MARK: - Category Helper Methods
    
    /// Calculate spent amount for a specific category
    func spentAmount(for categoryId: UUID) -> Double {
        expenses.filter { $0.budgetCategoryId == categoryId }.reduce(0) { $0 + $1.amount }
    }
    
    /// Calculate projected spending for a category
    func projectedSpending(for categoryId: UUID) -> Double {
        let categoryExpenses = expenses.filter { $0.budgetCategoryId == categoryId }
        return categoryExpenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Calculate actual spending (paid only) for a category
    func actualSpending(for categoryId: UUID) -> Double {
        let categoryExpenses = expenses.filter { $0.budgetCategoryId == categoryId }
        return categoryExpenses.reduce(0) { $0 + ($1.paymentStatus == .paid ? $1.amount : 0) }
    }
    
    /// Create an enhanced category with spending details
    func enhancedCategory(_ category: BudgetCategory) -> EnhancedBudgetCategory {
        let projectedAmount = projectedSpending(for: category.id)
        let actualPaidAmount = actualSpending(for: category.id)
        return EnhancedBudgetCategory(
            category: category,
            projectedSpending: projectedAmount,
            actualSpending: actualPaidAmount
        )
    }
    
    // MARK: - Compatibility Aliases
    
    /// Alias for addCategory for backward compatibility
    func addBudgetCategory(_ category: BudgetCategory) async {
        await addCategory(category)
    }
    
    /// Alias for updateCategory for backward compatibility
    func updateBudgetCategory(_ category: BudgetCategory) async {
        await updateCategory(category)
    }
}
