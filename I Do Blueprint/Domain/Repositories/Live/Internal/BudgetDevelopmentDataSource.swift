//
//  BudgetDevelopmentDataSource.swift
//  I Do Blueprint
//
//  Internal data source for budget development operations.
//  Handles CRUD operations for budget scenarios, items, allocations, and folder management.
//

import Foundation
import Supabase

/// Internal actor-based data source for budget development operations
/// Provides caching, in-flight request coalescing, and comprehensive error handling
actor BudgetDevelopmentDataSource {
    private let supabase: SupabaseClient
    private nonisolated let logger = AppLogger.repository
    
    // In-flight request de-duplication
    private var inFlightScenarios: [UUID: Task<[SavedScenario], Error>] = [:]
    private var inFlightItems: [String: Task<[BudgetItem], Error>] = [:]
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // MARK: - Budget Development Scenarios
    
    /// Fetches all budget development scenarios for the current tenant
    /// - Parameter tenantId: The couple's tenant ID
    /// - Returns: Array of saved scenarios sorted by creation date (newest first)
    /// - Throws: BudgetError if fetch fails
    func fetchBudgetDevelopmentScenarios(tenantId: UUID) async throws -> [SavedScenario] {
        let cacheKey = "budget_dev_scenarios_\(tenantId.uuidString)"
        
        // Check cache first (5 min TTL)
        if let cached: [SavedScenario] = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            logger.info("Cache hit: budget development scenarios (\(cached.count) items)")
            return cached
        }
        
        // Coalesce in-flight requests
        if let task = inFlightScenarios[tenantId] {
            return try await task.value
        }
        
        let task = Task<[SavedScenario], Error> { [weak self] in
            guard let self = self else { throw CancellationError() }
            
            let startTime = Date()
            
            let scenarios: [SavedScenario] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("budget_development_scenarios")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            // Only log if slow
            if duration > 1.0 {
                self.logger.info("Slow budget scenarios fetch: \(String(format: "%.2f", duration))s for \(scenarios.count) items")
            }
            
            // Cache the result
            await RepositoryCache.shared.set(cacheKey, value: scenarios, ttl: 300)
            
            return scenarios
        }
        
        inFlightScenarios[tenantId] = task
        
        do {
            let result = try await task.value
            inFlightScenarios.removeValue(forKey: tenantId)
            return result
        } catch {
            inFlightScenarios.removeValue(forKey: tenantId)
            logger.error("Budget scenarios fetch failed", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchBudgetDevelopmentScenarios",
                "tenantId": tenantId.uuidString
            ])
            
            throw BudgetError.fetchFailed(underlying: error)
        }
    }
    
    /// Creates a new budget development scenario
    /// - Parameter scenario: The scenario to create
    /// - Returns: The created scenario with server-generated fields
    /// - Throws: BudgetError if creation fails
    func createBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        let startTime = Date()
        
        do {
            let created: SavedScenario = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_scenarios")
                    .insert(scenario)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created budget development scenario: \(created.scenarioName) in \(String(format: "%.2f", duration))s")
            
            // Invalidate cache
            await RepositoryCache.shared.remove("budget_dev_scenarios_\(scenario.coupleId.uuidString)")
            
            return created
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to create budget development scenario after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "createBudgetDevelopmentScenario",
                "scenarioName": scenario.scenarioName,
                "tenantId": scenario.coupleId.uuidString
            ])
            
            throw BudgetError.createFailed(underlying: error)
        }
    }
    
    /// Updates an existing budget development scenario
    /// - Parameter scenario: The scenario to update
    /// - Returns: The updated scenario
    /// - Throws: BudgetError if update fails
    func updateBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        let startTime = Date()
        
        do {
            logger.debug("Updating scenario: \(scenario.id), isPrimary: \(scenario.isPrimary), coupleId: \(scenario.coupleId)")
            
            let result: SavedScenario = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_scenarios")
                    .update(scenario)
                    .eq("id", value: scenario.id)
                    .eq("couple_id", value: scenario.coupleId)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated budget development scenario: \(result.scenarioName), isPrimary: \(result.isPrimary) in \(String(format: "%.2f", duration))s")
            
            // Invalidate caches
            await RepositoryCache.shared.remove("budget_dev_scenarios_\(scenario.coupleId.uuidString)")
            await RepositoryCache.shared.remove("primary_budget_scenario_\(scenario.coupleId.uuidString)")
            
            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to update budget development scenario after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "updateBudgetDevelopmentScenario",
                "scenarioId": scenario.id,
                "scenarioName": scenario.scenarioName,
                "tenantId": scenario.coupleId.uuidString
            ])
            
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    /// Fetches the primary budget scenario for the tenant
    /// - Parameter tenantId: The couple's tenant ID
    /// - Returns: The primary scenario, or nil if none exists
    /// - Throws: BudgetError if fetch fails
    func fetchPrimaryBudgetScenario(tenantId: UUID) async throws -> BudgetDevelopmentScenario? {
        let cacheKey = "primary_budget_scenario_\(tenantId.uuidString)"
        
        // Check cache first (5 min TTL)
        if let cached: BudgetDevelopmentScenario = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            logger.info("Cache hit: primary budget scenario")
            return cached
        }
        
        let startTime = Date()
        
        do {
            let scenarios: [BudgetDevelopmentScenario] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_scenarios")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .eq("is_primary", value: true)
                    .limit(1)
                    .execute()
                    .value
            }
            
            let scenario = scenarios.first
            let duration = Date().timeIntervalSince(startTime)
            
            if let scenario = scenario {
                logger.info("Fetched primary budget scenario: \(scenario.scenarioName) ($\(scenario.totalWithTax)) in \(String(format: "%.2f", duration))s")
                await RepositoryCache.shared.set(cacheKey, value: scenario, ttl: 300)
            } else {
                logger.info("No primary budget scenario found in \(String(format: "%.2f", duration))s")
            }
            
            return scenario
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Primary budget scenario fetch failed after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchPrimaryBudgetScenario",
                "tenantId": tenantId.uuidString
            ])
            
            throw BudgetError.fetchFailed(underlying: error)
        }
    }
    
    // MARK: - Budget Development Items
    
    /// Fetches budget development items for a scenario
    /// - Parameter scenarioId: Optional scenario ID to filter by
    /// - Returns: Array of budget items
    /// - Throws: BudgetError if fetch fails
    func fetchBudgetDevelopmentItems(scenarioId: String?) async throws -> [BudgetItem] {
        let cacheKey = scenarioId.map { "budget_dev_items_\($0)" } ?? "budget_dev_items_all"
        
        // Check cache first (1 min TTL)
        if let cached: [BudgetItem] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }
        
        // Coalesce in-flight requests
        let requestKey = scenarioId ?? "all"
        if let task = inFlightItems[requestKey] {
            return try await task.value
        }
        
        let task = Task<[BudgetItem], Error> { [weak self] in
            guard let self = self else { throw CancellationError() }
            
            var query = self.supabase.from("budget_development_items").select()
            
            if let scenarioId {
                query = query.eq("scenario_id", value: scenarioId)
            }
            
            let items: [BudgetItem] = try await query
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await RepositoryCache.shared.set(cacheKey, value: items)
            
            return items
        }
        
        inFlightItems[requestKey] = task
        
        do {
            let result = try await task.value
            inFlightItems.removeValue(forKey: requestKey)
            return result
        } catch {
            inFlightItems.removeValue(forKey: requestKey)
            logger.error("Budget items fetch failed", error: error)
            throw BudgetError.fetchFailed(underlying: error)
        }
    }
    
    /// Fetches budget items in hierarchical order
    /// - Parameter scenarioId: The scenario ID
    /// - Returns: Array of budget items sorted by display order
    /// - Throws: BudgetError if fetch fails
    func fetchBudgetItemsHierarchical(scenarioId: String) async throws -> [BudgetItem] {
        let cacheKey = "budget_items_hierarchical_\(scenarioId)"
        
        if let cached: [BudgetItem] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }
        
        let items: [BudgetItem] = try await RepositoryNetwork.withRetry { [self] in
            try await self.supabase
                .from("budget_development_items")
                .select()
                .eq("scenario_id", value: scenarioId)
                .order("display_order", ascending: true)
                .execute()
                .value
        }
        
        await RepositoryCache.shared.set(cacheKey, value: items)
        logger.info("Fetched \(items.count) hierarchical items for scenario \(scenarioId)")
        
        return items
    }
    
    /// Creates a new budget development item
    /// - Parameter item: The item to create
    /// - Returns: The created item with server-generated fields
    /// - Throws: BudgetError if creation fails
    func createBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        let startTime = Date()
        
        do {
            let created: BudgetItem = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .insert(item)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created budget development item: \(created.itemName) in \(String(format: "%.2f", duration))s")
            
            // Invalidate caches
            if let scenarioId = item.scenarioId {
                await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
            }
            await RepositoryCache.shared.remove("budget_dev_items_all")
            
            return created
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to create budget development item after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "createBudgetDevelopmentItem",
                "itemName": item.itemName
            ])
            
            throw BudgetError.createFailed(underlying: error)
        }
    }
    
    /// Updates an existing budget development item
    /// - Parameter item: The item to update
    /// - Returns: The updated item and the previous state (for potential rollback)
    /// - Throws: BudgetError if update fails
    func updateBudgetDevelopmentItem(_ item: BudgetItem) async throws -> (updated: BudgetItem, previous: BudgetItem?) {
        let startTime = Date()
        
        do {
            // Read previous state for potential rollback if recalculation fails
            let previousItems: [BudgetItem] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .select()
                    .eq("id", value: item.id)
                    .limit(1)
                    .execute()
                    .value
            }
            let previousItem = previousItems.first
            
            let result: BudgetItem = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .update(item)
                    .eq("id", value: item.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated budget development item: \(result.itemName) in \(String(format: "%.2f", duration))s")
            
            return (result, previousItem)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to update budget development item after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "updateBudgetDevelopmentItem",
                "itemId": item.id,
                "itemName": item.itemName
            ])
            
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    /// Rolls back a budget development item to a previous state
    /// - Parameter item: The previous item state to restore
    /// - Throws: BudgetError if rollback fails
    func rollbackBudgetDevelopmentItem(_ item: BudgetItem) async throws {
        do {
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .update(item)
                    .eq("id", value: item.id)
                    .execute()
            }
            logger.info("Rolled back budget development item: \(item.id)")
        } catch {
            logger.error("Failed to rollback budget development item", error: error)
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    /// Invalidates caches after successful item update
    /// - Parameter item: The updated item
    func invalidateCachesAfterUpdate(_ item: BudgetItem) async {
        if let scenarioId = item.scenarioId {
            await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
        }
        await RepositoryCache.shared.remove("budget_dev_items_all")
    }
    
    /// Deletes a budget development item
    /// - Parameter id: The item ID to delete
    /// - Returns: The scenario ID of the deleted item (for cache invalidation)
    /// - Throws: BudgetError if deletion fails
    func deleteBudgetDevelopmentItem(id: String) async throws -> String? {
        let startTime = Date()
        
        do {
            // Fetch the item first to get its scenarioId for proper cache invalidation
            let items: [BudgetItem] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .select()
                    .eq("id", value: id)
                    .limit(1)
                    .execute()
                    .value
            }
            let scenarioId = items.first?.scenarioId
            
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted budget development item: \(id) in \(String(format: "%.2f", duration))s")
            
            // Invalidate caches
            if let scenarioId = scenarioId {
                await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
            }
            await RepositoryCache.shared.remove("budget_dev_items_all")
            
            return scenarioId
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to delete budget development item after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteBudgetDevelopmentItem",
                "itemId": id
            ])
            
            throw BudgetError.deleteFailed(underlying: error)
        }
    }
    
    // MARK: - Expense Allocations
    
    /// Fetches expense allocations for a specific budget item in a scenario
    /// - Parameters:
    ///   - scenarioId: The scenario ID
    ///   - budgetItemId: The budget item ID
    /// - Returns: Array of expense allocations
    /// - Throws: BudgetError if fetch fails
    func fetchExpenseAllocations(scenarioId: String, budgetItemId: String) async throws -> [ExpenseAllocation] {
        let startTime = Date()
        
        do {
            let allocations: [ExpenseAllocation] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("expense_budget_allocations")
                    .select()
                    .eq("scenario_id", value: scenarioId)
                    .eq("budget_item_id", value: budgetItemId)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            if duration > 1.0 {
                logger.info("Slow expense allocations fetch: \(String(format: "%.2f", duration))s for \(allocations.count) items")
            }
            
            return allocations
        } catch {
            logger.error("Failed to fetch expense allocations", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchExpenseAllocations",
                "scenarioId": scenarioId,
                "budgetItemId": budgetItemId
            ])
            
            throw BudgetError.fetchFailed(underlying: error)
        }
    }
    
    /// Fetches all expense allocations for a scenario
    /// - Parameter scenarioId: The scenario ID
    /// - Returns: Array of expense allocations
    /// - Throws: BudgetError if fetch fails
    func fetchExpenseAllocationsForScenario(scenarioId: String) async throws -> [ExpenseAllocation] {
        let startTime = Date()
        
        do {
            let allocations: [ExpenseAllocation] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("expense_budget_allocations")
                    .select()
                    .eq("scenario_id", value: scenarioId)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            if duration > 1.0 {
                logger.info("Slow expense allocations fetch (scenario): \(String(format: "%.2f", duration))s for \(allocations.count) items")
            }
            
            return allocations
        } catch {
            logger.error("Failed to fetch expense allocations for scenario", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchExpenseAllocationsForScenario",
                "scenarioId": scenarioId
            ])
            
            throw BudgetError.fetchFailed(underlying: error)
        }
    }
    
    /// Creates a new expense allocation
    /// - Parameter allocation: The allocation to create
    /// - Returns: The created allocation with server-generated fields
    /// - Throws: BudgetError if creation fails
    func createExpenseAllocation(_ allocation: ExpenseAllocation) async throws -> ExpenseAllocation {
        let startTime = Date()
        
        do {
            let created: ExpenseAllocation = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("expense_budget_allocations")
                    .insert(allocation)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created expense allocation: \(created.expenseId) -> \(created.budgetItemId) in \(String(format: "%.2f", duration))s")
            
            // Invalidate cache
            await RepositoryCache.shared.remove("budget_overview_items_\(allocation.scenarioId)")
            
            return created
        } catch {
            logger.error("Failed to create expense allocation", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "createExpenseAllocation",
                "expenseId": allocation.expenseId,
                "budgetItemId": allocation.budgetItemId
            ])
            
            throw BudgetError.createFailed(underlying: error)
        }
    }
    
    /// Fetches allocations for a specific expense in a scenario
    /// - Parameters:
    ///   - expenseId: The expense ID
    ///   - scenarioId: The scenario ID
    /// - Returns: Array of expense allocations
    /// - Throws: BudgetError if fetch fails
    func fetchAllocationsForExpense(expenseId: UUID, scenarioId: String) async throws -> [ExpenseAllocation] {
        let allocations: [ExpenseAllocation] = try await RepositoryNetwork.withRetry { [self] in
            try await self.supabase
                .from("expense_budget_allocations")
                .select()
                .eq("expense_id", value: expenseId)
                .eq("scenario_id", value: scenarioId)
                .execute()
                .value
        }
        return allocations
    }
    
    /// Fetches allocations for a specific expense across all scenarios
    /// - Parameter expenseId: The expense ID
    /// - Returns: Array of expense allocations
    /// - Throws: BudgetError if fetch fails
    func fetchAllocationsForExpenseAllScenarios(expenseId: UUID) async throws -> [ExpenseAllocation] {
        let allocations: [ExpenseAllocation] = try await RepositoryNetwork.withRetry { [self] in
            try await self.supabase
                .from("expense_budget_allocations")
                .select()
                .eq("expense_id", value: expenseId)
                .execute()
                .value
        }
        return allocations
    }
    
    /// Replaces all allocations for an expense in a scenario
    /// - Parameters:
    ///   - expenseId: The expense ID
    ///   - scenarioId: The scenario ID
    ///   - newAllocations: The new allocations to set
    /// - Throws: BudgetError if replacement fails
    func replaceAllocations(expenseId: UUID, scenarioId: String, with newAllocations: [ExpenseAllocation]) async throws {
        // Fetch backup of existing allocations so we can restore on failure
        let existing: [ExpenseAllocation] = try await RepositoryNetwork.withRetry { [self] in
            try await self.supabase
                .from("expense_budget_allocations")
                .select()
                .eq("expense_id", value: expenseId)
                .eq("scenario_id", value: scenarioId)
                .execute()
                .value
        }
        
        // Delete existing
        try await RepositoryNetwork.withRetry { [self] in
            try await self.supabase
                .from("expense_budget_allocations")
                .delete()
                .eq("expense_id", value: expenseId)
                .eq("scenario_id", value: scenarioId)
                .execute()
        }
        
        // Insert new set
        if !newAllocations.isEmpty {
            do {
                try await RepositoryNetwork.withRetry { [self] in
                    try await self.supabase
                        .from("expense_budget_allocations")
                        .insert(newAllocations)
                        .execute()
                }
            } catch {
                // Attempt to restore previous allocations
                if !existing.isEmpty {
                    do {
                        try await RepositoryNetwork.withRetry { [self] in
                            try await self.supabase
                                .from("expense_budget_allocations")
                                .insert(existing)
                                .execute()
                        }
                        logger.info("Restored previous allocations after insert failure for expense: \(expenseId)")
                    } catch {
                        logger.error("Failed to restore allocations after insert failure", error: error)
                    }
                }
                throw error
            }
        }
        
        // Only invalidate cache after successful replace
        await RepositoryCache.shared.remove("budget_overview_items_\(scenarioId)")
    }
    
    /// Links a gift to a budget item
    /// - Parameters:
    ///   - giftId: The gift ID to link
    ///   - budgetItemId: The budget item ID to link to
    /// - Throws: BudgetError if linking fails
    func linkGiftToBudgetItem(giftId: UUID, budgetItemId: String) async throws {
        let startTime = Date()
        
        do {
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .update(["linked_gift_owed_id": giftId.uuidString])
                    .eq("id", value: budgetItemId)
                    .execute()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Linked gift \(giftId) to budget item \(budgetItemId) in \(String(format: "%.2f", duration))s")
            
            // Invalidate related caches
            await RepositoryCache.shared.remove("gifts_and_owed")
            
            // Invalidate budget development items cache for all scenarios
            let stats = await RepositoryCache.shared.stats()
            for key in stats.keys where key.hasPrefix("budget_development_items_") {
                await RepositoryCache.shared.remove(key)
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Gift linking failed after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "linkGiftToBudgetItem",
                "giftId": giftId.uuidString,
                "budgetItemId": budgetItemId
            ])
            
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    // MARK: - Composite Saves
    
    /// Saves a budget scenario with its items in a single transaction
    /// - Parameters:
    ///   - scenario: The scenario to save
    ///   - items: The items to save with the scenario
    /// - Returns: Tuple containing the scenario ID and count of inserted items
    /// - Throws: BudgetError if save fails
    func saveBudgetScenarioWithItems(_ scenario: SavedScenario, items: [BudgetItem]) async throws -> (scenarioId: String, insertedItems: Int) {
        struct Params: Encodable {
            let p_scenario: SavedScenario
            let p_items: [BudgetItem]
        }
        struct ResultRow: Decodable {
            let scenario_id: String
            let inserted_items: Int
        }
        
        let startTime = Date()
        let params = Params(p_scenario: scenario, p_items: items)
        
        do {
            let results: [ResultRow] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .rpc("save_budget_scenario_with_items", params: params)
                    .execute()
                    .value
            }
            
            guard let first = results.first,
                  !first.scenario_id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                let errorInfo = [NSLocalizedDescriptionKey: "RPC returned no or empty scenario_id"]
                let error = NSError(domain: "BudgetDevelopmentDataSource", code: -1, userInfo: errorInfo)
                throw BudgetError.updateFailed(underlying: error)
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Saved scenario + items via RPC in \(String(format: "%.2f", duration))s (items=\(first.inserted_items))")
            
            // Invalidate caches
            let tenantId = scenario.coupleId.uuidString
            await RepositoryCache.shared.remove("budget_dev_scenarios_\(tenantId)")
            await RepositoryCache.shared.remove("budget_dev_items_\(first.scenario_id)")
            await RepositoryCache.shared.remove("budget_dev_items_all")
            await RepositoryCache.shared.remove("primary_budget_scenario_\(tenantId)")
            
            return (first.scenario_id, first.inserted_items)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to save scenario with items after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "saveBudgetScenarioWithItems",
                "scenarioName": scenario.scenarioName,
                "itemCount": items.count
            ])
            
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    // MARK: - Folder Operations
    
    /// Creates a new folder
    /// - Parameters:
    ///   - name: The folder name
    ///   - scenarioId: The scenario ID
    ///   - parentFolderId: Optional parent folder ID
    ///   - displayOrder: The display order
    ///   - tenantId: The couple's tenant ID
    /// - Returns: The created folder
    /// - Throws: BudgetError if creation fails
    func createFolder(name: String, scenarioId: String, parentFolderId: String?, displayOrder: Int, tenantId: UUID) async throws -> BudgetItem {
        let startTime = Date()
        
        do {
            let folder = BudgetItem.createFolder(
                name: name,
                scenarioId: scenarioId,
                parentFolderId: parentFolderId,
                displayOrder: displayOrder,
                coupleId: tenantId
            )
            
            let created: BudgetItem = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .insert(folder)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created folder: \(name) in \(String(format: "%.2f", duration))s")
            
            // Invalidate caches
            await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
            await RepositoryCache.shared.remove("budget_dev_items_all")
            
            return created
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to create folder after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "createFolder",
                "folderName": name,
                "scenarioId": scenarioId
            ])
            
            throw BudgetError.createFailed(underlying: error)
        }
    }
    
    /// Moves an item to a folder
    /// - Parameters:
    ///   - itemId: The item ID to move
    ///   - targetFolderId: The target folder ID (nil for root)
    ///   - displayOrder: The new display order
    /// - Throws: BudgetError if move fails
    func moveItemToFolder(itemId: String, targetFolderId: String?, displayOrder: Int) async throws {
        let startTime = Date()
        
        do {
            struct MoveUpdate: Codable {
                let parentFolderId: String?
                let displayOrder: Int
                let updatedAt: Date
                
                enum CodingKeys: String, CodingKey {
                    case parentFolderId = "parent_folder_id"
                    case displayOrder = "display_order"
                    case updatedAt = "updated_at"
                }
            }
            
            let update = MoveUpdate(
                parentFolderId: targetFolderId,
                displayOrder: displayOrder,
                updatedAt: Date()
            )
            
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .update(update)
                    .eq("id", value: itemId)
                    .execute()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Moved item \(itemId) to folder \(targetFolderId ?? "root") in \(String(format: "%.2f", duration))s")
            
            // Invalidate cache
            await RepositoryCache.shared.remove("budget_dev_items_all")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to move item to folder after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "moveItemToFolder",
                "itemId": itemId,
                "targetFolderId": targetFolderId ?? "root"
            ])
            
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    /// Updates display order for multiple items
    /// - Parameter items: Array of tuples containing item ID and new display order
    /// - Throws: BudgetError if update fails
    func updateDisplayOrder(items: [(itemId: String, displayOrder: Int)]) async throws {
        struct OrderUpdate: Codable {
            let id: String
            let displayOrder: Int
            let updatedAt: Date
            
            enum CodingKeys: String, CodingKey {
                case id = "id"
                case displayOrder = "display_order"
                case updatedAt = "updated_at"
            }
        }
        
        let startTime = Date()
        
        do {
            let now = Date()
            let updates = items.map { (itemId, order) in
                OrderUpdate(id: itemId, displayOrder: order, updatedAt: now)
            }
            
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .upsert(updates)
                    .execute()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated display order for \(items.count) items in single batch operation in \(String(format: "%.2f", duration))s")
            
            // Invalidate cache
            await RepositoryCache.shared.remove("budget_dev_items_all")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to update display order after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "updateDisplayOrder",
                "itemCount": items.count
            ])
            
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    /// Toggles folder expansion state
    /// - Parameters:
    ///   - folderId: The folder ID
    ///   - isExpanded: The new expansion state
    /// - Throws: BudgetError if update fails
    func toggleFolderExpansion(folderId: String, isExpanded: Bool) async throws {
        let startTime = Date()
        
        do {
            struct ExpansionUpdate: Codable {
                let isExpanded: Bool
                let updatedAt: Date
                
                enum CodingKeys: String, CodingKey {
                    case isExpanded = "is_expanded"
                    case updatedAt = "updated_at"
                }
            }
            
            let update = ExpansionUpdate(isExpanded: isExpanded, updatedAt: Date())
            
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .update(update)
                    .eq("id", value: folderId)
                    .execute()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Toggled folder \(folderId) expansion to \(isExpanded) in \(String(format: "%.2f", duration))s")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to toggle folder expansion after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "toggleFolderExpansion",
                "folderId": folderId,
                "isExpanded": isExpanded
            ])
            
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    /// Calculates folder totals recursively
    /// - Parameter folderId: The folder ID
    /// - Returns: Folder totals (without tax, tax, with tax)
    /// - Throws: BudgetError if calculation fails
    func calculateFolderTotals(folderId: String) async throws -> FolderTotals {
        // Fetch the folder first to get its scenarioId
        let folders: [BudgetItem] = try await RepositoryNetwork.withRetry { [self] in
            try await self.supabase
                .from("budget_development_items")
                .select()
                .eq("id", value: folderId)
                .eq("is_folder", value: true)
                .limit(1)
                .execute()
                .value
        }
        
        guard let folder = folders.first, let scenarioId = folder.scenarioId else {
            throw BudgetError.fetchFailed(underlying: NSError(
                domain: "BudgetDevelopmentDataSource",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Folder not found or missing scenarioId"]
            ))
        }
        
        // Fetch all items for the scenario
        let items = try await fetchBudgetItemsHierarchical(scenarioId: scenarioId)
        
        // Recursively collect all descendants
        func getAllDescendants(of folderId: String) -> [BudgetItem] {
            var result: [BudgetItem] = []
            var queue = [folderId]
            
            while !queue.isEmpty {
                let currentId = queue.removeFirst()
                let children = items.filter { $0.parentFolderId == currentId && !$0.isFolder }
                result.append(contentsOf: children)
                
                let childFolders = items.filter { $0.parentFolderId == currentId && $0.isFolder }
                queue.append(contentsOf: childFolders.map { $0.id })
            }
            
            return result
        }
        
        let descendants = getAllDescendants(of: folderId)
        let withoutTax = descendants.reduce(0) { $0 + $1.vendorEstimateWithoutTax }
        let tax = descendants.reduce(0) { $0 + ($1.vendorEstimateWithoutTax * $1.taxRate) }
        let withTax = descendants.reduce(0) { $0 + $1.vendorEstimateWithTax }
        
        return FolderTotals(withoutTax: withoutTax, tax: tax, withTax: withTax)
    }
    
    /// Checks if an item can be moved to a folder
    /// - Parameters:
    ///   - itemId: The item ID to move
    ///   - targetFolderId: The target folder ID (nil for root)
    /// - Returns: True if the move is valid
    /// - Throws: BudgetError if validation fails
    func canMoveItem(itemId: String, toFolder targetFolderId: String?) async throws -> Bool {
        // Can't move to itself
        if itemId == targetFolderId { return false }
        
        // If moving to root, always allowed
        guard let targetFolderId = targetFolderId else { return true }
        
        // Fetch the item first to get its scenarioId
        let itemsToMove: [BudgetItem] = try await RepositoryNetwork.withRetry { [self] in
            try await self.supabase
                .from("budget_development_items")
                .select()
                .eq("id", value: itemId)
                .limit(1)
                .execute()
                .value
        }
        
        guard let item = itemsToMove.first, let scenarioId = item.scenarioId else {
            throw BudgetError.fetchFailed(underlying: NSError(
                domain: "BudgetDevelopmentDataSource",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Item not found or missing scenarioId"]
            ))
        }
        
        // Fetch all items for the scenario
        let items = try await fetchBudgetItemsHierarchical(scenarioId: scenarioId)
        
        // Check if target is a folder
        guard let targetFolder = items.first(where: { $0.id == targetFolderId }),
              targetFolder.isFolder else {
            return false
        }
        
        // Check depth limit (max 3 levels)
        func getDepth(of itemId: String) -> Int {
            var depth = 0
            var currentId: String? = itemId
            
            while let id = currentId,
                  let item = items.first(where: { $0.id == id }),
                  let parentId = item.parentFolderId {
                depth += 1
                currentId = parentId
            }
            
            return depth
        }
        
        let targetDepth = getDepth(of: targetFolderId)
        if targetDepth >= 3 { return false }
        
        // Check for circular reference
        var visited = Set<String>()
        var currentId: String? = targetFolderId
        
        while let id = currentId {
            if visited.contains(id) || id == itemId { return false }
            visited.insert(id)
            
            guard let item = items.first(where: { $0.id == id }) else { break }
            currentId = item.parentFolderId
        }
        
        return true
    }
    
    /// Deletes a folder and optionally its contents
    /// - Parameters:
    ///   - folderId: The folder ID to delete
    ///   - deleteContents: If true, deletes all contents; if false, moves contents to parent
    /// - Throws: BudgetError if deletion fails
    func deleteFolder(folderId: String, deleteContents: Bool) async throws {
        let startTime = Date()
        
        do {
            // Fetch the folder first to get its scenarioId
            let folders: [BudgetItem] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .select()
                    .eq("id", value: folderId)
                    .eq("is_folder", value: true)
                    .limit(1)
                    .execute()
                    .value
            }
            
            guard let folder = folders.first, let scenarioId = folder.scenarioId else {
                throw BudgetError.deleteFailed(underlying: NSError(
                    domain: "BudgetDevelopmentDataSource",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Folder not found or missing scenarioId"]
                ))
            }
            
            if deleteContents {
                // Delete folder and all descendant items recursively
                let items = try await fetchBudgetItemsHierarchical(scenarioId: scenarioId)
                
                // Recursively collect all descendant IDs
                func getAllDescendantIds(of parentId: String) -> [String] {
                    var result: [String] = []
                    let directChildren = items.filter { $0.parentFolderId == parentId }
                    
                    for child in directChildren {
                        result.append(child.id)
                        if child.isFolder {
                            result.append(contentsOf: getAllDescendantIds(of: child.id))
                        }
                    }
                    
                    return result
                }
                
                let descendantIds = getAllDescendantIds(of: folderId)
                
                // Delete all descendants first (if any)
                if !descendantIds.isEmpty {
                    try await RepositoryNetwork.withRetry { [self] in
                        try await self.supabase
                            .from("budget_development_items")
                            .delete()
                            .in("id", values: descendantIds)
                            .execute()
                    }
                    logger.info("Deleted \(descendantIds.count) descendant items from folder \(folderId)")
                }
                
                // Then delete the folder itself
                try await RepositoryNetwork.withRetry { [self] in
                    try await self.supabase
                        .from("budget_development_items")
                        .delete()
                        .eq("id", value: folderId)
                        .execute()
                }
                
                let duration = Date().timeIntervalSince(startTime)
                logger.info("Deleted folder \(folderId) and all contents in \(String(format: "%.2f", duration))s")
            } else {
                // Move contents to parent, then delete folder
                let items = try await fetchBudgetItemsHierarchical(scenarioId: scenarioId)
                let children = items.filter { $0.parentFolderId == folderId }
                
                // Move children to folder's parent
                for child in children {
                    try await moveItemToFolder(itemId: child.id, targetFolderId: folder.parentFolderId, displayOrder: child.displayOrder)
                }
                
                // Delete the folder
                try await RepositoryNetwork.withRetry { [self] in
                    try await self.supabase
                        .from("budget_development_items")
                        .delete()
                        .eq("id", value: folderId)
                        .execute()
                }
                
                let duration = Date().timeIntervalSince(startTime)
                logger.info("Deleted folder \(folderId), moved \(children.count) items to parent in \(String(format: "%.2f", duration))s")
            }
            
            // Invalidate caches
            await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
            await RepositoryCache.shared.remove("budget_dev_items_all")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to delete folder after \(String(format: "%.2f", duration))s", error: error)
            
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteFolder",
                "folderId": folderId,
                "deleteContents": deleteContents
            ])
            
            throw BudgetError.deleteFailed(underlying: error)
        }
    }
}
