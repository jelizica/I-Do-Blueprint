//
//  BudgetDevelopmentDataSource.swift
//  I Do Blueprint
//
//  Data source for budget development operations.
//  Handles CRUD operations with caching and retry logic.
//  Complex business logic delegated to BudgetDevelopmentService.
//

import Foundation
import Supabase

/// Actor-based data source for budget development operations
/// Provides caching, in-flight request coalescing, and comprehensive error handling
actor BudgetDevelopmentDataSource {
    private let supabase: SupabaseClient
    private nonisolated let logger = AppLogger.repository
    private let service = BudgetDevelopmentService()
    
    // In-flight request de-duplication
    private var inFlightScenarios: [UUID: Task<[SavedScenario], Error>] = [:]
    private var inFlightItems: [String: Task<[BudgetItem], Error>] = [:]
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // MARK: - Budget Development Scenarios
    
    /// Fetches all budget development scenarios for the current tenant
    func fetchBudgetDevelopmentScenarios(tenantId: UUID) async throws -> [SavedScenario] {
        let cacheKey = "budget_dev_scenarios_\(tenantId.uuidString)"
        
        if let cached: [SavedScenario] = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
            logger.info("Cache hit: budget development scenarios (\(cached.count) items)")
            return cached
        }
        
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
            if duration > 1.0 {
                self.logger.info("Slow budget scenarios fetch: \(String(format: "%.2f", duration))s for \(scenarios.count) items")
            }
            
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
            
            await invalidateScenarioCaches(tenantId: scenario.coupleId)
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

    /// Deletes a budget development scenario and all its associated items
    func deleteBudgetDevelopmentScenario(id: String, tenantId: UUID) async throws {
        let startTime = Date()

        do {
            // First delete all items associated with this scenario
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .delete()
                    .eq("scenario_id", value: id)
                    .execute()
            }

            // Then delete the scenario itself
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_scenarios")
                    .delete()
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted budget development scenario: \(id) in \(String(format: "%.2f", duration))s")

            await invalidateScenarioCaches(tenantId: tenantId)
            await invalidateItemCaches(scenarioId: id)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to delete budget development scenario after \(String(format: "%.2f", duration))s", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteBudgetDevelopmentScenario",
                "scenarioId": id,
                "tenantId": tenantId.uuidString
            ])
            throw BudgetError.deleteFailed(underlying: error)
        }
    }

    /// Fetches the primary budget scenario for the tenant
    func fetchPrimaryBudgetScenario(tenantId: UUID) async throws -> BudgetDevelopmentScenario? {
        let cacheKey = "primary_budget_scenario_\(tenantId.uuidString)"
        
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
    func fetchBudgetDevelopmentItems(scenarioId: String?) async throws -> [BudgetItem] {
        let cacheKey = scenarioId.map { "budget_dev_items_\($0)" } ?? "budget_dev_items_all"
        
        if let cached: [BudgetItem] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }
        
        let requestKey = scenarioId ?? "all"
        if let task = inFlightItems[requestKey] {
            return try await task.value
        }
        
        let task = Task<[BudgetItem], Error> { [weak self] in
            guard let self = self else { throw CancellationError() }

            let items: [BudgetItem] = try await RepositoryNetwork.withRetry {
                var query = self.supabase.from("budget_development_items").select()
                if let scenarioId {
                    query = query.eq("scenario_id", value: scenarioId)
                }
                return try await query.order("created_at", ascending: false).execute().value
            }

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
            
            await invalidateItemCaches(scenarioId: item.scenarioId)
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
    func updateBudgetDevelopmentItem(_ item: BudgetItem) async throws -> (updated: BudgetItem, previous: BudgetItem?) {
        let startTime = Date()
        
        do {
            // Read previous state for potential rollback
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
    func invalidateCachesAfterUpdate(_ item: BudgetItem) async {
        await invalidateItemCaches(scenarioId: item.scenarioId)
    }
    
    /// Deletes a budget development item
    func deleteBudgetDevelopmentItem(id: String) async throws -> String? {
        let startTime = Date()
        
        do {
            // Fetch the item first to get its scenarioId
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
            
            await invalidateItemCaches(scenarioId: scenarioId)
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
    func replaceAllocations(expenseId: UUID, scenarioId: String, with newAllocations: [ExpenseAllocation]) async throws {
        // Fetch backup of existing allocations
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
        
        await RepositoryCache.shared.remove("budget_overview_items_\(scenarioId)")
    }
    
    /// Links a gift to a budget item
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
            
            await RepositoryCache.shared.remove("gifts_and_owed")

            // Invalidate budget development items cache and budget overview items cache
            await RepositoryCache.shared.invalidatePrefix("budget_dev_items_")
            await RepositoryCache.shared.invalidatePrefix("budget_overview_items_")
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

    /// Unlinks a gift from a budget item by clearing the linked_gift_owed_id
    /// - Parameter budgetItemId: The budget item to unlink the gift from
    func unlinkGiftFromBudgetItem(budgetItemId: String) async throws {
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .update(["linked_gift_owed_id": AnyJSON.null])
                    .eq("id", value: budgetItemId)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Unlinked gift from budget item \(budgetItemId) in \(String(format: "%.2f", duration))s")

            // Invalidate caches
            await RepositoryCache.shared.remove("gifts_and_owed")

            // Invalidate budget development items cache and budget overview items cache
            await RepositoryCache.shared.invalidatePrefix("budget_dev_items_")
            await RepositoryCache.shared.invalidatePrefix("budget_overview_items_")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Gift unlinking failed after \(String(format: "%.2f", duration))s", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "unlinkGiftFromBudgetItem",
                "budgetItemId": budgetItemId
            ])
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    // MARK: - Gift Allocations (Proportional)

    /// Fetches gift allocations for a specific budget item in a scenario
    func fetchGiftAllocations(scenarioId: String, budgetItemId: String) async throws -> [GiftAllocation] {
        let startTime = Date()

        do {
            let allocations: [GiftAllocation] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("gift_budget_allocations")
                    .select()
                    .eq("scenario_id", value: scenarioId)
                    .eq("budget_item_id", value: budgetItemId)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            if duration > 1.0 {
                logger.info("Slow gift allocations fetch: \(String(format: "%.2f", duration))s for \(allocations.count) items")
            }

            return allocations
        } catch {
            logger.error("Failed to fetch gift allocations", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchGiftAllocations",
                "scenarioId": scenarioId,
                "budgetItemId": budgetItemId
            ])
            throw BudgetError.fetchFailed(underlying: error)
        }
    }

    /// Fetches all gift allocations for a scenario
    func fetchGiftAllocationsForScenario(scenarioId: String) async throws -> [GiftAllocation] {
        let startTime = Date()

        do {
            let allocations: [GiftAllocation] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("gift_budget_allocations")
                    .select()
                    .eq("scenario_id", value: scenarioId)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            if duration > 1.0 {
                logger.info("Slow gift allocations fetch (scenario): \(String(format: "%.2f", duration))s for \(allocations.count) items")
            }

            return allocations
        } catch {
            logger.error("Failed to fetch gift allocations for scenario", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchGiftAllocationsForScenario",
                "scenarioId": scenarioId
            ])
            throw BudgetError.fetchFailed(underlying: error)
        }
    }

    /// Creates a new gift allocation
    func createGiftAllocation(_ allocation: GiftAllocation) async throws -> GiftAllocation {
        let startTime = Date()

        do {
            let created: GiftAllocation = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("gift_budget_allocations")
                    .insert(allocation)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created gift allocation: \(created.giftId) -> \(created.budgetItemId) in \(String(format: "%.2f", duration))s")

            // Invalidate relevant caches
            await RepositoryCache.shared.remove("budget_overview_items_\(allocation.scenarioId)")
            await RepositoryCache.shared.invalidatePrefix("gift_allocations_")
            return created
        } catch {
            logger.error("Failed to create gift allocation", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "createGiftAllocation",
                "giftId": allocation.giftId,
                "budgetItemId": allocation.budgetItemId
            ])
            throw BudgetError.createFailed(underlying: error)
        }
    }

    /// Fetches allocations for a specific gift in a scenario
    func fetchAllocationsForGift(giftId: UUID, scenarioId: String) async throws -> [GiftAllocation] {
        let allocations: [GiftAllocation] = try await RepositoryNetwork.withRetry { [self] in
            try await self.supabase
                .from("gift_budget_allocations")
                .select()
                .eq("gift_id", value: giftId)
                .eq("scenario_id", value: scenarioId)
                .execute()
                .value
        }
        return allocations
    }

    /// Fetches allocations for a specific gift across all scenarios
    func fetchAllocationsForGiftAllScenarios(giftId: UUID) async throws -> [GiftAllocation] {
        let allocations: [GiftAllocation] = try await RepositoryNetwork.withRetry { [self] in
            try await self.supabase
                .from("gift_budget_allocations")
                .select()
                .eq("gift_id", value: giftId)
                .execute()
                .value
        }
        return allocations
    }

    /// Replaces all allocations for a gift in a scenario
    func replaceGiftAllocations(giftId: UUID, scenarioId: String, with newAllocations: [GiftAllocation]) async throws {
        // Fetch backup of existing allocations
        let existing: [GiftAllocation] = try await RepositoryNetwork.withRetry { [self] in
            try await self.supabase
                .from("gift_budget_allocations")
                .select()
                .eq("gift_id", value: giftId)
                .eq("scenario_id", value: scenarioId)
                .execute()
                .value
        }

        // Delete existing
        try await RepositoryNetwork.withRetry { [self] in
            try await self.supabase
                .from("gift_budget_allocations")
                .delete()
                .eq("gift_id", value: giftId)
                .eq("scenario_id", value: scenarioId)
                .execute()
        }

        // Insert new set
        if !newAllocations.isEmpty {
            do {
                try await RepositoryNetwork.withRetry { [self] in
                    try await self.supabase
                        .from("gift_budget_allocations")
                        .insert(newAllocations)
                        .execute()
                }
            } catch {
                // Attempt to restore previous allocations
                if !existing.isEmpty {
                    do {
                        try await RepositoryNetwork.withRetry { [self] in
                            try await self.supabase
                                .from("gift_budget_allocations")
                                .insert(existing)
                                .execute()
                        }
                        logger.info("Restored previous gift allocations after insert failure for gift: \(giftId)")
                    } catch {
                        logger.error("Failed to restore gift allocations after insert failure", error: error)
                    }
                }
                throw error
            }
        }

        // Invalidate caches
        await RepositoryCache.shared.remove("budget_overview_items_\(scenarioId)")
        await RepositoryCache.shared.invalidatePrefix("gift_allocations_")
    }

    // MARK: - Bill Calculator Linking

    /// Links a bill calculator to a budget item, replacing its amount with the bill's subtotal
    /// - Parameters:
    ///   - billCalculatorId: The bill calculator to link
    ///   - budgetItemId: The budget item to update
    ///   - billSubtotal: The pre-tax subtotal from the bill calculator
    func linkBillCalculatorToBudgetItem(billCalculatorId: UUID, budgetItemId: String, billSubtotal: Double) async throws {
        let startTime = Date()

        do {
            // 1. Fetch current item to store pre-link amount and get tax rate
            let existingItems: [BudgetItem] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .select()
                    .eq("id", value: budgetItemId)
                    .limit(1)
                    .execute()
                    .value
            }

            guard let existingItem = existingItems.first else {
                throw BudgetError.fetchFailed(underlying: NSError(
                    domain: "BudgetDevelopmentDataSource",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Budget item not found: \(budgetItemId)"]
                ))
            }

            // 2. Calculate amounts using bill subtotal and item's tax rate
            let amountWithoutTax = billSubtotal
            let amountWithTax = billSubtotal * (1 + existingItem.taxRate / 100)

            // 3. Update with linking and store original amount
            struct BillLinkUpdate: Codable {
                let linkedBillCalculatorId: UUID
                let preLinkAmount: Double
                let vendorEstimateWithoutTax: Double
                let vendorEstimateWithTax: Double
                let updatedAt: Date

                enum CodingKeys: String, CodingKey {
                    case linkedBillCalculatorId = "linked_bill_calculator_id"
                    case preLinkAmount = "pre_link_amount"
                    case vendorEstimateWithoutTax = "vendor_estimate_without_tax"
                    case vendorEstimateWithTax = "vendor_estimate_with_tax"
                    case updatedAt = "updated_at"
                }
            }

            let update = BillLinkUpdate(
                linkedBillCalculatorId: billCalculatorId,
                preLinkAmount: existingItem.vendorEstimateWithoutTax,
                vendorEstimateWithoutTax: amountWithoutTax,
                vendorEstimateWithTax: amountWithTax,
                updatedAt: Date()
            )

            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .update(update)
                    .eq("id", value: budgetItemId)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Linked bill \(billCalculatorId) to budget item \(budgetItemId) in \(String(format: "%.2f", duration))s")

            // Invalidate caches
            await invalidateItemCaches(scenarioId: existingItem.scenarioId)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Bill calculator linking failed after \(String(format: "%.2f", duration))s", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "linkBillCalculatorToBudgetItem",
                "billCalculatorId": billCalculatorId.uuidString,
                "budgetItemId": budgetItemId
            ])
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    /// Unlinks a bill calculator from a budget item, reverting to the pre-link amount
    /// - Parameter budgetItemId: The budget item to unlink
    func unlinkBillCalculatorFromBudgetItem(budgetItemId: String) async throws {
        let startTime = Date()

        do {
            // 1. Fetch current item to get pre-link amount and tax rate
            let existingItems: [BudgetItem] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .select()
                    .eq("id", value: budgetItemId)
                    .limit(1)
                    .execute()
                    .value
            }

            guard let existingItem = existingItems.first else {
                throw BudgetError.fetchFailed(underlying: NSError(
                    domain: "BudgetDevelopmentDataSource",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Budget item not found: \(budgetItemId)"]
                ))
            }

            // 2. Revert to original amount (or 0 if no pre-link amount)
            let revertAmount = existingItem.preLinkAmount ?? 0
            let amountWithTax = revertAmount * (1 + existingItem.taxRate / 100)

            // 3. Clear link and restore amount
            struct BillUnlinkUpdate: Codable {
                let linkedBillCalculatorId: UUID?
                let preLinkAmount: Double?
                let vendorEstimateWithoutTax: Double
                let vendorEstimateWithTax: Double
                let updatedAt: Date

                enum CodingKeys: String, CodingKey {
                    case linkedBillCalculatorId = "linked_bill_calculator_id"
                    case preLinkAmount = "pre_link_amount"
                    case vendorEstimateWithoutTax = "vendor_estimate_without_tax"
                    case vendorEstimateWithTax = "vendor_estimate_with_tax"
                    case updatedAt = "updated_at"
                }
            }

            let update = BillUnlinkUpdate(
                linkedBillCalculatorId: nil,
                preLinkAmount: nil,
                vendorEstimateWithoutTax: revertAmount,
                vendorEstimateWithTax: amountWithTax,
                updatedAt: Date()
            )

            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .update(update)
                    .eq("id", value: budgetItemId)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Unlinked bill from budget item \(budgetItemId) in \(String(format: "%.2f", duration))s")

            // Invalidate caches
            await invalidateItemCaches(scenarioId: existingItem.scenarioId)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Bill calculator unlinking failed after \(String(format: "%.2f", duration))s", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "unlinkBillCalculatorFromBudgetItem",
                "budgetItemId": budgetItemId
            ])
            throw BudgetError.updateFailed(underlying: error)
        }
    }

    // MARK: - Composite Saves
    
    /// Saves a budget scenario with its items in a single transaction
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
            
            await invalidateScenarioCaches(tenantId: scenario.coupleId)
            await invalidateItemCaches(scenarioId: first.scenario_id)
            
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
    
    // MARK: - Folder Operations (Delegated to Service)
    
    /// Creates a new folder
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
            
            await invalidateItemCaches(scenarioId: scenarioId)
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
            
            let update = MoveUpdate(parentFolderId: targetFolderId, displayOrder: displayOrder, updatedAt: Date())
            
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .update(update)
                    .eq("id", value: itemId)
                    .execute()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Moved item \(itemId) to folder \(targetFolderId ?? "root") in \(String(format: "%.2f", duration))s")
            
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
            
            try await RepositoryNetwork.withRetry { [self] in
                for (itemId, order) in items {
                    let update = OrderUpdate(id: itemId, displayOrder: order, updatedAt: now)
                    try await self.supabase
                        .from("budget_development_items")
                        .update(update)
                        .eq("id", value: itemId)
                        .execute()
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated display order for \(items.count) items in \(String(format: "%.2f", duration))s")
            
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
    
    /// Calculates folder totals recursively (delegates to service)
    func calculateFolderTotals(folderId: String) async throws -> FolderTotals {
        // Fetch the folder to get its scenarioId
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
        
        // Delegate calculation to service
        return await service.calculateFolderTotals(folderId: folderId, allItems: items)
    }
    
    /// Checks if an item can be moved to a folder (delegates to service)
    func canMoveItem(itemId: String, toFolder targetFolderId: String?) async throws -> Bool {
        // Can't move to itself
        guard itemId != targetFolderId else { return false }
        
        // If moving to root, always allowed
        guard let targetFolderId = targetFolderId else { return true }
        
        // Fetch the item to get its scenarioId
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
        
        // Delegate validation to service
        return await service.canMoveItem(itemId: itemId, toFolder: targetFolderId, allItems: items)
    }
    
    /// Deletes a folder and optionally its contents (delegates to service)
    func deleteFolder(folderId: String, deleteContents: Bool) async throws {
        let startTime = Date()
        
        do {
            // Fetch the folder to get its scenarioId
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
                // Fetch all items and get descendant IDs from service
                let items = try await fetchBudgetItemsHierarchical(scenarioId: scenarioId)
                let descendantIds = await service.getAllDescendantIds(of: folderId, from: items)
                
                // Delete all descendants first
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
                
                // Delete the folder itself
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
                let children = await service.getDirectChildren(of: folderId, from: items)
                
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
            
            await invalidateItemCaches(scenarioId: scenarioId)
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
    
    // MARK: - Cache Invalidation Helpers
    
    private func invalidateScenarioCaches(tenantId: UUID) async {
        let tenantIdString = tenantId.uuidString
        await RepositoryCache.shared.remove("budget_dev_scenarios_\(tenantIdString)")
        await RepositoryCache.shared.remove("primary_budget_scenario_\(tenantIdString)")
    }
    
    private func invalidateItemCaches(scenarioId: String?) async {
        if let scenarioId = scenarioId {
            await RepositoryCache.shared.remove("budget_dev_items_\(scenarioId)")
            await RepositoryCache.shared.remove("budget_items_hierarchical_\(scenarioId)")
            // Also invalidate budget overview cache so linked bill amounts are reflected
            await RepositoryCache.shared.remove("budget_overview_items_\(scenarioId)")
        }
        await RepositoryCache.shared.remove("budget_dev_items_all")
    }

    // MARK: - Budget Item Bill Calculator Links (Multi-Bill Support)

    /// Fetches all bill calculator links for a specific budget item
    func fetchBillCalculatorLinksForBudgetItem(budgetItemId: String) async throws -> [BudgetItemBillCalculatorLink] {
        let startTime = Date()

        do {
            guard let budgetItemUUID = UUID(uuidString: budgetItemId) else {
                throw BudgetError.fetchFailed(underlying: NSError(
                    domain: "BudgetDevelopmentDataSource",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid budget item ID format: \(budgetItemId)"]
                ))
            }

            let links: [BudgetItemBillCalculatorLink] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_item_bill_calculator_links")
                    .select()
                    .eq("budget_item_id", value: budgetItemUUID)
                    .order("created_at", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(links.count) bill calculator links for budget item \(budgetItemId) in \(String(format: "%.2f", duration))s")
            return links
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch bill calculator links after \(String(format: "%.2f", duration))s", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchBillCalculatorLinksForBudgetItem",
                "budgetItemId": budgetItemId
            ])
            throw BudgetError.fetchFailed(underlying: error)
        }
    }

    /// Links multiple bill calculators to a budget item
    /// Updates the budget item's amount to sum of all linked bill subtotals and sets linked_bill_calculator_id
    func linkBillCalculatorsToBudgetItem(
        budgetItemId: String,
        billCalculatorIds: [UUID],
        coupleId: UUID,
        notes: String?
    ) async throws -> [BudgetItemBillCalculatorLink] {
        let startTime = Date()

        guard !billCalculatorIds.isEmpty else {
            return []
        }

        guard let budgetItemUUID = UUID(uuidString: budgetItemId) else {
            throw BudgetError.createFailed(underlying: NSError(
                domain: "BudgetDevelopmentDataSource",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid budget item ID format: \(budgetItemId)"]
            ))
        }

        do {
            // Fetch the budget item to get its scenario ID and current amount for pre-link backup
            let existingItems: [BudgetItem] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .select()
                    .eq("id", value: budgetItemId)
                    .limit(1)
                    .execute()
                    .value
            }

            guard let existingItem = existingItems.first else {
                throw BudgetError.fetchFailed(underlying: NSError(
                    domain: "BudgetDevelopmentDataSource",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Budget item not found: \(budgetItemId)"]
                ))
            }

            // Fetch the bill calculators to calculate combined subtotal
            // Note: Use "items:bill_calculator_items(*)" to alias the nested items to match the BillCalculator model's expected key
            let billCalculators: [BillCalculator] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("bill_calculators")
                    .select("*, items:bill_calculator_items(*)")
                    .in("id", values: billCalculatorIds)
                    .execute()
                    .value
            }

            // Calculate combined subtotal from all linked bills
            let combinedSubtotal = billCalculators.reduce(0.0) { $0 + $1.subtotal }
            let amountWithTax = combinedSubtotal * (1 + existingItem.taxRate / 100)

            // Create insert data for each link
            let insertData = billCalculatorIds.map { billId in
                BudgetItemBillCalculatorLinkInsertData(
                    budgetItemId: budgetItemUUID,
                    billCalculatorId: billId,
                    coupleId: coupleId,
                    notes: notes
                )
            }

            // Insert all links
            let createdLinks: [BudgetItemBillCalculatorLink] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_item_bill_calculator_links")
                    .insert(insertData)
                    .select()
                    .execute()
                    .value
            }

            // Update the budget item with combined amount and set linked_bill_calculator_id
            // Store original amount in pre_link_amount for revert capability
            struct BillLinkUpdate: Codable {
                let linkedBillCalculatorId: UUID?
                let preLinkAmount: Double?
                let vendorEstimateWithoutTax: Double
                let vendorEstimateWithTax: Double
                let updatedAt: Date

                enum CodingKeys: String, CodingKey {
                    case linkedBillCalculatorId = "linked_bill_calculator_id"
                    case preLinkAmount = "pre_link_amount"
                    case vendorEstimateWithoutTax = "vendor_estimate_without_tax"
                    case vendorEstimateWithTax = "vendor_estimate_with_tax"
                    case updatedAt = "updated_at"
                }
            }

            // Use first bill ID as the linked_bill_calculator_id (for UI indicator)
            // The junction table stores all links
            let update = BillLinkUpdate(
                linkedBillCalculatorId: billCalculatorIds.first,
                preLinkAmount: existingItem.preLinkAmount ?? existingItem.vendorEstimateWithoutTax,
                vendorEstimateWithoutTax: combinedSubtotal,
                vendorEstimateWithTax: amountWithTax,
                updatedAt: Date()
            )

            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .update(update)
                    .eq("id", value: budgetItemId)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Linked \(createdLinks.count) bill calculators to budget item \(budgetItemId) (combined subtotal: \(combinedSubtotal)) in \(String(format: "%.2f", duration))s")

            // Invalidate caches
            await invalidateItemCaches(scenarioId: existingItem.scenarioId)

            return createdLinks
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to link bill calculators after \(String(format: "%.2f", duration))s", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "linkBillCalculatorsToBudgetItem",
                "budgetItemId": budgetItemId,
                "billCalculatorCount": billCalculatorIds.count
            ])
            throw BudgetError.createFailed(underlying: error)
        }
    }

    /// Removes a specific bill calculator link by link ID
    func unlinkBillCalculatorFromBudgetItemByLinkId(linkId: UUID) async throws {
        let startTime = Date()

        do {
            // First fetch the link to get budget_item_id for cache invalidation
            let links: [BudgetItemBillCalculatorLink] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_item_bill_calculator_links")
                    .select()
                    .eq("id", value: linkId)
                    .limit(1)
                    .execute()
                    .value
            }

            guard let link = links.first else {
                throw BudgetError.deleteFailed(underlying: NSError(
                    domain: "BudgetDevelopmentDataSource",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Link not found: \(linkId)"]
                ))
            }

            // Get the budget item to find scenario for cache invalidation
            let budgetItems: [BudgetItem] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .select()
                    .eq("id", value: link.budgetItemId)
                    .limit(1)
                    .execute()
                    .value
            }

            // Delete the link (trigger will update budget item amount)
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_item_bill_calculator_links")
                    .delete()
                    .eq("id", value: linkId)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Removed bill calculator link \(linkId) in \(String(format: "%.2f", duration))s")

            // Invalidate caches
            if let budgetItem = budgetItems.first {
                await invalidateItemCaches(scenarioId: budgetItem.scenarioId)
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to remove bill calculator link after \(String(format: "%.2f", duration))s", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "unlinkBillCalculatorFromBudgetItemByLinkId",
                "linkId": linkId.uuidString
            ])
            throw BudgetError.deleteFailed(underlying: error)
        }
    }

    /// Removes all bill calculator links for a budget item
    func unlinkAllBillCalculatorsFromBudgetItem(budgetItemId: String) async throws {
        let startTime = Date()

        guard let budgetItemUUID = UUID(uuidString: budgetItemId) else {
            throw BudgetError.deleteFailed(underlying: NSError(
                domain: "BudgetDevelopmentDataSource",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid budget item ID format: \(budgetItemId)"]
            ))
        }

        do {
            // Get the budget item to find scenario for cache invalidation and pre-link amount
            let budgetItems: [BudgetItem] = try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .select()
                    .eq("id", value: budgetItemId)
                    .limit(1)
                    .execute()
                    .value
            }

            guard let existingItem = budgetItems.first else {
                throw BudgetError.fetchFailed(underlying: NSError(
                    domain: "BudgetDevelopmentDataSource",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Budget item not found: \(budgetItemId)"]
                ))
            }

            // Delete all links for this budget item from junction table
            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_item_bill_calculator_links")
                    .delete()
                    .eq("budget_item_id", value: budgetItemUUID)
                    .execute()
            }

            // Also clear the legacy linked_bill_calculator_id and restore pre-link amount
            // This ensures the UI state is updated even if no database trigger is configured
            let revertAmount = existingItem.preLinkAmount ?? 0
            let amountWithTax = revertAmount * (1 + existingItem.taxRate / 100)

            struct BillUnlinkClear: Codable {
                let linkedBillCalculatorId: UUID?
                let preLinkAmount: Double?
                let vendorEstimateWithoutTax: Double
                let vendorEstimateWithTax: Double
                let updatedAt: Date

                enum CodingKeys: String, CodingKey {
                    case linkedBillCalculatorId = "linked_bill_calculator_id"
                    case preLinkAmount = "pre_link_amount"
                    case vendorEstimateWithoutTax = "vendor_estimate_without_tax"
                    case vendorEstimateWithTax = "vendor_estimate_with_tax"
                    case updatedAt = "updated_at"
                }
            }

            let clearUpdate = BillUnlinkClear(
                linkedBillCalculatorId: nil,
                preLinkAmount: nil,
                vendorEstimateWithoutTax: revertAmount,
                vendorEstimateWithTax: amountWithTax,
                updatedAt: Date()
            )

            try await RepositoryNetwork.withRetry { [self] in
                try await self.supabase
                    .from("budget_development_items")
                    .update(clearUpdate)
                    .eq("id", value: budgetItemId)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Removed all bill calculator links for budget item \(budgetItemId) in \(String(format: "%.2f", duration))s")

            // Invalidate caches
            await invalidateItemCaches(scenarioId: existingItem.scenarioId)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to remove all bill calculator links after \(String(format: "%.2f", duration))s", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "unlinkAllBillCalculatorsFromBudgetItem",
                "budgetItemId": budgetItemId
            ])
            throw BudgetError.deleteFailed(underlying: error)
        }
    }
}
