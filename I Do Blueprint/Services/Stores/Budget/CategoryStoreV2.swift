//
//  CategoryStoreV2.swift
//  I Do Blueprint
//
//  Specialized store for budget category operations
//  Extracted from BudgetStoreV2 for better separation of concerns
//

import Combine
import Dependencies
import Foundation
import SwiftUI

@MainActor
final class CategoryStoreV2: ObservableObject {
    
    // MARK: - Published State
    
    /// Categories from parent store (read-only reference)
    @Published private(set) var categories: [BudgetCategory] = []
    
    /// Category dependencies cache (for delete validation)
    @Published private(set) var categoryDependencies: [UUID: CategoryDependencies] = [:]
    
    /// Loading state for category operations
    @Published private(set) var isLoading: Bool = false
    
    // MARK: - Dependencies
    
    @Dependency(\.budgetRepository) var repository
    private let logger = AppLogger.database
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - State Management
    
    /// Update categories from parent store
    func updateCategories(_ newCategories: [BudgetCategory]) {
        categories = newCategories
    }
    
    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        categories = []
        categoryDependencies = [:]
        isLoading = false
    }
    
    // MARK: - Category CRUD Operations
    
    /// Add a new budget category
    /// - Parameter category: Category to create
    /// - Returns: Created category with server-assigned ID
    func addCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let created = try await repository.createCategory(category)
            
            // Update local state
            categories.append(created)
            categories.sort { $0.priorityLevel < $1.priorityLevel }
            
            logger.info("Added category: \(created.categoryName)")
            return created
        } catch {
            logger.error("Error adding category", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "addCategory",
                    feature: "budget",
                    metadata: ["categoryName": category.categoryName]
                )
            )
            throw BudgetError.createFailed(underlying: error)
        }
    }
    
    /// Update an existing budget category with optimistic update
    /// - Parameter category: Category to update
    /// - Returns: Updated category from server
    func updateCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        // Optimistic update
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else {
            throw BudgetError.updateFailed(underlying: NSError(
                domain: "CategoryStore",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Category not found in local state"]
            ))
        }
        
        let original = categories[index]
        categories[index] = category
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updated = try await repository.updateCategory(category)
            
            // Update with server response
            if let idx = categories.firstIndex(where: { $0.id == category.id }) {
                categories[idx] = updated
            }
            
            logger.info("Updated category: \(updated.categoryName)")
            return updated
        } catch {
            // Rollback on error
            if let idx = categories.firstIndex(where: { $0.id == category.id }) {
                categories[idx] = original
            }
            
            logger.error("Error updating category", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "updateCategory",
                    feature: "budget",
                    metadata: ["categoryId": category.id.uuidString, "categoryName": category.categoryName]
                )
            )
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    /// Delete a budget category with optimistic delete
    /// - Parameter id: Category ID to delete
    func deleteCategory(id: UUID) async throws {
        // Optimistic delete
        guard let index = categories.firstIndex(where: { $0.id == id }) else {
            throw BudgetError.deleteFailed(underlying: NSError(
                domain: "CategoryStore",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Category not found in local state"]
            ))
        }
        
        let removed = categories.remove(at: index)
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await repository.deleteCategory(id: id)
            
            // Remove from dependencies cache
            categoryDependencies.removeValue(forKey: id)
            
            logger.info("Deleted category: \(removed.categoryName)")
        } catch {
            // Rollback on error
            categories.insert(removed, at: index)
            
            logger.error("Error deleting category", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "deleteCategory",
                    feature: "budget",
                    metadata: ["categoryId": id.uuidString, "categoryName": removed.categoryName]
                )
            )
            throw BudgetError.deleteFailed(underlying: error)
        }
    }
    
    // MARK: - Category Dependency Management
    
    /// Load dependency information for all categories
    func loadCategoryDependencies() async {
        let start = Date()
        var loadedCount = 0
        
        for category in categories {
            do {
                let deps = try await repository.checkCategoryDependencies(id: category.id)
                categoryDependencies[category.id] = deps
                loadedCount += 1
            } catch {
                logger.error("Failed to load dependencies for category \(category.id)", error: error)
                ErrorHandler.shared.handle(
                    error,
                    context: ErrorContext(
                        operation: "loadCategoryDependencies",
                        feature: "budget",
                        metadata: ["categoryId": category.id.uuidString]
                    )
                )
            }
        }
        
        let duration = Date().timeIntervalSince(start)
        logger.info("Loaded dependencies for \(loadedCount)/\(categories.count) categories in \(String(format: "%.2f", duration))s")
    }
    
    /// Check if a category can be deleted (has no dependencies)
    /// - Parameter category: Category to check
    /// - Returns: True if category can be safely deleted
    func canDeleteCategory(_ category: BudgetCategory) -> Bool {
        // Conservative default: if dependency info is missing, do not allow deletion
        categoryDependencies[category.id]?.canDelete ?? false
    }
    
    /// Get user-friendly warning message for category with dependencies
    /// - Parameter category: Category to check
    /// - Returns: Warning message if category has dependencies, nil otherwise
    func getDependencyWarning(for category: BudgetCategory) -> String? {
        guard let deps = categoryDependencies[category.id], !deps.canDelete else {
            return nil
        }
        return deps.blockingReasons.joined(separator: "\n")
    }
    
    /// Batch delete multiple categories
    /// - Parameter ids: Array of category IDs to delete
    /// - Returns: Result with succeeded and failed deletions
    func batchDeleteCategories(ids: [UUID]) async -> BatchDeleteResult {
        let start = Date()
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await repository.batchDeleteCategories(ids: ids)
            
            // Update local state for succeeded deletions
            if !result.succeeded.isEmpty {
                categories.removeAll { result.succeeded.contains($0.id) }
                
                // Clear dependencies for deleted categories
                for id in result.succeeded {
                    categoryDependencies.removeValue(forKey: id)
                }
            }
            
            let duration = Date().timeIntervalSince(start)
            logger.info("Batch deleted \(result.successCount)/\(result.totalAttempted) categories in \(String(format: "%.2f", duration))s")
            
            if result.failureCount > 0 {
                logger.warning("Failed to delete \(result.failureCount) categories")
            }
            
            return result
        } catch {
            logger.error("Batch delete failed", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "batchDeleteCategories",
                    feature: "budget",
                    metadata: ["categoryCount": ids.count]
                )
            )
            
            // Return empty result on complete failure (wrap errors for Sendable)
            let wrapped = ids.map { (id: UUID) -> (UUID, BatchDeleteResult.SendableErrorWrapper) in
                (id, BatchDeleteResult.SendableErrorWrapper(error))
            }
            return BatchDeleteResult(succeeded: [], failed: wrapped)
        }
    }
    
    // MARK: - Category Filtering and Sorting
    
    /// Filter categories based on the specified filter option
    /// - Parameter filter: Filter option to apply
    /// - Returns: Filtered array of categories
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
    /// - Parameters:
    ///   - categories: Categories to sort
    ///   - sort: Sort option to apply
    ///   - ascending: Sort direction
    /// - Returns: Sorted array of categories
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
    /// - Parameters:
    ///   - categoryId: Category ID
    ///   - expenses: All expenses to calculate from
    /// - Returns: Total spent amount for category
    func spentAmount(for categoryId: UUID, expenses: [Expense]) -> Double {
        expenses.filter { $0.budgetCategoryId == categoryId }.reduce(0) { $0 + $1.amount }
    }
    
    /// Calculate projected spending for a category
    /// - Parameters:
    ///   - categoryId: Category ID
    ///   - expenses: All expenses to calculate from
    /// - Returns: Total projected spending for category
    func projectedSpending(for categoryId: UUID, expenses: [Expense]) -> Double {
        let categoryExpenses = expenses.filter { $0.budgetCategoryId == categoryId }
        return categoryExpenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Calculate actual spending (paid only) for a category
    /// - Parameters:
    ///   - categoryId: Category ID
    ///   - expenses: All expenses to calculate from
    /// - Returns: Total actual paid amount for category
    func actualSpending(for categoryId: UUID, expenses: [Expense]) -> Double {
        let categoryExpenses = expenses.filter { $0.budgetCategoryId == categoryId }
        return categoryExpenses.reduce(0) { $0 + ($1.paymentStatus == .paid ? $1.amount : 0) }
    }
    
    /// Create an enhanced category with spending details
    /// - Parameters:
    ///   - category: Category to enhance
    ///   - expenses: All expenses to calculate from
    /// - Returns: Enhanced category with spending details
    func enhancedCategory(_ category: BudgetCategory, expenses: [Expense]) -> EnhancedBudgetCategory {
        let projectedAmount = projectedSpending(for: category.id, expenses: expenses)
        let actualPaidAmount = actualSpending(for: category.id, expenses: expenses)
        return EnhancedBudgetCategory(
            category: category,
            projectedSpending: projectedAmount,
            actualSpending: actualPaidAmount
        )
    }
    
    /// Get parent categories (no parent category ID)
    var parentCategories: [BudgetCategory] {
        categories.filter { $0.parentCategoryId == nil }
    }
}
