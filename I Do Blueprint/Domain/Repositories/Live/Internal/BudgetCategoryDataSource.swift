//
//  BudgetCategoryDataSource.swift
//  I Do Blueprint
//
//  Internal data source for budget category operations
//  Extracted from LiveBudgetRepository for better maintainability
//

import Foundation
import Supabase

/// Internal data source handling all budget category CRUD operations
/// This is not exposed publicly - all access goes through BudgetRepositoryProtocol
actor BudgetCategoryDataSource {
    private let supabase: SupabaseClient
    private nonisolated let logger = AppLogger.repository
    private let cacheStrategy: BudgetCacheStrategy
    
    // In-flight request de-duplication
    private var inFlightCategories: Task<[BudgetCategory], Error>?
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
        self.cacheStrategy = BudgetCacheStrategy()
    }
    
    // MARK: - Fetch Operations
    
    func fetchCategories() async throws -> [BudgetCategory] {
        let cacheKey = "budget_categories"
        
        // Check cache first (1 min TTL for fresher data)
        if let cached: [BudgetCategory] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }
        
        // Coalesce in-flight request
        if let task = inFlightCategories {
            return try await task.value
        }
        
        let task = Task<[BudgetCategory], Error> { [weak self] in
            guard let self = self else { throw CancellationError() }
            let startTime = Date()
            let categories: [BudgetCategory] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("budget_categories")
                    .select()
                    .order("priority_level", ascending: true)
                    .execute()
                    .value
            }
            let duration = Date().timeIntervalSince(startTime)
            if duration > 1.0 {
                self.logger.info("Slow category fetch: \(String(format: "%.2f", duration))s for \(categories.count) items")
            }
            await RepositoryCache.shared.set(cacheKey, value: categories)
            return categories
        }
        
        inFlightCategories = task
        do {
            let result = try await task.value
            inFlightCategories = nil
            return result
        } catch {
            inFlightCategories = nil
            logger.error("Failed to fetch categories", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchCategories",
                "dataSource": "BudgetCategoryDataSource"
            ])
            throw BudgetError.fetchFailed(underlying: error)
        }
    }
    
    // MARK: - Create Operations
    
    func createCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        do {
            // Verify auth session exists before making authenticated request
            let session = try await supabase.auth.session
            logger.info("✅ Auth session exists: user=\(session.user.id)")
            
            let startTime = Date()
            
            let created: BudgetCategory = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_categories")
                    .insert(category)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created category: \(created.categoryName) in \(String(format: "%.2f", duration))s")
            
            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .categoryCreated)
            
            return created
        } catch {
            logger.error("Failed to create category", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "createCategory",
                "dataSource": "BudgetCategoryDataSource"
            ])
            throw BudgetError.createFailed(underlying: error)
        }
    }
    
    // MARK: - Update Operations
    
    func updateCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
        do {
            let startTime = Date()
            
            var updated = category
            updated.updatedAt = Date()
            
            let result: BudgetCategory = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_categories")
                    .update(updated)
                    .eq("id", value: category.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated category: \(result.categoryName) in \(String(format: "%.2f", duration))s")
            
            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .categoryUpdated)
            
            return result
        } catch {
            logger.error("Failed to update category", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "updateCategory",
                "dataSource": "BudgetCategoryDataSource",
                "categoryId": category.id.uuidString
            ])
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    // MARK: - Delete Operations
    
    func deleteCategory(id: UUID) async throws {
        do {
            let startTime = Date()
            
            _ = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_categories")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted category: \(id) in \(String(format: "%.2f", duration))s")
            
            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .categoryDeleted)
        } catch {
            logger.error("Failed to delete category", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteCategory",
                "dataSource": "BudgetCategoryDataSource",
                "categoryId": id.uuidString
            ])
            throw BudgetError.deleteFailed(underlying: error)
        }
    }
    
    func batchDeleteCategories(ids: [UUID]) async throws -> BatchDeleteResult {
        var succeeded: [UUID] = []
        var failed: [(UUID, BatchDeleteResult.SendableErrorWrapper)] = []
        
        for id in ids {
            do {
                try await deleteCategory(id: id)
                succeeded.append(id)
            } catch {
                failed.append((id, BatchDeleteResult.SendableErrorWrapper(error)))
                logger.warning("Failed to delete category \(id) in batch: \(error.localizedDescription)")
            }
        }
        
        logger.info("Batch delete completed: \(succeeded.count) succeeded, \(failed.count) failed")
        
        return BatchDeleteResult(succeeded: succeeded, failed: failed)
    }
    
    // MARK: - Dependency Checking
    
    func checkCategoryDependencies(id: UUID, tenantId: UUID) async throws -> CategoryDependencies {
        do {
            let startTime = Date()
            
            // Fetch the category first to get its name
            let categories: [BudgetCategory] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_categories")
                    .select()
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId)
                    .limit(1)
                    .execute()
                    .value
            }
            
            guard let category = categories.first else {
                throw BudgetError.fetchFailed(underlying: NSError(
                    domain: "BudgetCategoryDataSource",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Category not found"]
                ))
            }
            
            // Fetch expenses linked to this category
            let expenses: [Expense] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("expenses")
                    .select()
                    .eq("budget_category_id", value: id)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }
            
            // Fetch subcategories
            let subcategories: [BudgetCategory] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_categories")
                    .select()
                    .eq("parent_category_id", value: id)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }
            
            // Fetch tasks linked to this category
            struct TaskBasic: Codable {
                let id: UUID
            }
            let tasks: [TaskBasic] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("wedding_tasks")
                    .select("id")
                    .eq("budget_category_id", value: id)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }
            
            // Fetch vendors linked to this category
            struct VendorBasic: Codable {
                let id: Int64
            }
            let vendors: [VendorBasic] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("vendor_information")
                    .select("id")
                    .eq("budget_category_id", value: id)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }
            
            // Fetch budget development items using this category name
            struct BudgetItemBasic: Codable {
                let id: String
                let category: String?
                let subcategory: String?
            }
            
            // Query 1: Items where category matches
            let categoryItems: [BudgetItemBasic] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .select("id, category, subcategory")
                    .eq("category", value: category.categoryName)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }
            
            // Query 2: Items where subcategory matches
            let subcategoryItems: [BudgetItemBasic] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .select("id, category, subcategory")
                    .eq("subcategory", value: category.categoryName)
                    .eq("couple_id", value: tenantId)
                    .execute()
                    .value
            }
            
            // Merge results and deduplicate by id
            let allItems = categoryItems + subcategoryItems
            let uniqueItemsDict = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id, $0) })
            let budgetItems = Array(uniqueItemsDict.values)
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Checked dependencies for category '\(category.categoryName)' in \(String(format: "%.2f", duration))s")
            
            return CategoryDependencies(
                categoryId: id,
                categoryName: category.categoryName,
                expenseCount: expenses.count,
                budgetItemCount: budgetItems.count,
                subcategoryCount: subcategories.count,
                taskCount: tasks.count,
                vendorCount: vendors.count
            )
        } catch {
            logger.error("Failed to check category dependencies", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "checkCategoryDependencies",
                "dataSource": "BudgetCategoryDataSource",
                "categoryId": id.uuidString
            ])
            throw BudgetError.fetchFailed(underlying: error)
        }
    }
}
