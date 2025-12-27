//
//  BudgetStoreV2+Development.swift
//  I Do Blueprint
//
//  Budget development operations for BudgetStoreV2
//

import Foundation

// MARK: - Scenario Cache Actor

/// Thread-safe actor for caching scenario items
private actor ScenarioCache {
    private var cache: [String: (items: [BudgetItem], timestamp: Date)] = [:]
    private let ttl: TimeInterval = 300 // 5 minutes
    
    /// Get cached items for a scenario if not expired
    func get(_ scenarioId: String) -> [BudgetItem]? {
        guard let cached = cache[scenarioId] else {
            return nil
        }
        
        // Check if cache entry is still valid
        if Date().timeIntervalSince(cached.timestamp) < ttl {
            return cached.items
        }
        
        // Cache expired, remove it
        cache.removeValue(forKey: scenarioId)
        return nil
    }
    
    /// Set cached items for a scenario
    func set(_ scenarioId: String, items: [BudgetItem]) {
        cache[scenarioId] = (items, Date())
    }
    
    /// Invalidate cache for a specific scenario or all scenarios
    func invalidate(_ scenarioId: String? = nil) {
        if let scenarioId = scenarioId {
            cache.removeValue(forKey: scenarioId)
        } else {
            cache.removeAll()
        }
    }
}

// MARK: - Budget Development Operations

extension BudgetStoreV2 {

    // MARK: - Store-Level Cache
    
    /// Store-level cache for scenario items (faster than repository cache)
    private static let scenarioCache = ScenarioCache()
    
    // MARK: - Budget Development Item Operations

    /// Load budget development items for a specific scenario
    /// Uses store-level cache for faster subsequent loads
    func loadBudgetDevelopmentItems(scenarioId: String? = nil) async -> [BudgetItem] {
        // Check store-level cache first (faster than repository cache)
        if let scenarioId = scenarioId,
           let cached = await Self.scenarioCache.get(scenarioId) {
            logger.info("Store cache hit: scenario \(scenarioId) (\(cached.count) items)")
            return cached
        }
        
        do {
            let startTime = Date()
            let items = try await repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
            let duration = Date().timeIntervalSince(startTime)
            
            // Cache the results at store level
            if let scenarioId = scenarioId {
                await Self.scenarioCache.set(scenarioId, items: items)
                logger.info("Cached scenario \(scenarioId) items (\(items.count) items) - fetch took \(String(format: "%.2f", duration))s")
            }
            
            return items
        } catch {
            logger.error("Failed to load budget development items", error: error)
            return []
        }
    }
    
    /// Invalidate store-level cache for a specific scenario or all scenarios
    func invalidateScenarioCache(scenarioId: String? = nil) async {
        await Self.scenarioCache.invalidate(scenarioId)
        if let scenarioId = scenarioId {
            logger.debug("Invalidated store cache for scenario: \(scenarioId)")
        } else {
            logger.debug("Invalidated all scenario caches")
        }
    }

    /// Load budget development items with spent amounts for a scenario
    func loadBudgetDevelopmentItemsWithSpentAmounts(scenarioId: String) async -> [BudgetOverviewItem] {
        // Validate scenario ID is not empty
        guard !scenarioId.isEmpty else {
            logger.warning("Cannot load budget overview items: scenario ID is empty")
            return []
        }

        // Validate scenario ID is a valid UUID
        guard UUID(uuidString: scenarioId) != nil else {
            logger.warning("Cannot load budget overview items: invalid scenario ID format: \(scenarioId)")
            return []
        }

        do {
            let items = try await repository.fetchBudgetDevelopmentItemsWithSpentAmounts(scenarioId: scenarioId)
            return items
        } catch {
            logger.error("Failed to load budget overview items", error: error)
            return []
        }
    }

    /// Save a budget development item (create or update)
    func saveBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
        // Determine if this is a new item or an update by checking if it exists in the database
        // New items will be created, existing items will be updated
        let existingItems = try await repository.fetchBudgetDevelopmentItems(scenarioId: item.scenarioId)
        let isExisting = existingItems.contains { $0.id == item.id }

        let savedItem: BudgetItem
        if isExisting {
            savedItem = try await repository.updateBudgetDevelopmentItem(item)
            logger.info("Updated budget development item: \(savedItem.itemName)")
        } else {
            savedItem = try await repository.createBudgetDevelopmentItem(item)
            logger.info("Created budget development item: \(savedItem.itemName)")
        }
        
        // Invalidate cache for this scenario
        if let scenarioId = item.scenarioId {
            await invalidateScenarioCache(scenarioId: scenarioId)
        }
        
        return savedItem
    }

    /// Delete a budget development item
    func deleteBudgetDevelopmentItem(id: String) async throws {
        try await repository.deleteBudgetDevelopmentItem(id: id)
        logger.info("Deleted budget development item: \(id)")
        
        // Invalidate all scenario caches (we don't know which scenario this item belonged to)
        await invalidateScenarioCache()
    }

    // MARK: - Scenario Management

    /// Save scenario and items atomically via repository RPC
    func saveScenarioWithItems(_ scenario: SavedScenario, items: [BudgetItem]) async throws -> (scenarioId: String, insertedItems: Int) {
        let result = try await repository.saveBudgetScenarioWithItems(scenario, items: items)
        
        // Invalidate cache for this scenario
        await invalidateScenarioCache(scenarioId: result.scenarioId)
        
        return result
    }
    
    /// Update an existing budget development scenario
    func updateBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario {
        let updated = try await repository.updateBudgetDevelopmentScenario(scenario)
        logger.info("Updated budget development scenario: \(updated.scenarioName)")
        
        // Invalidate cache for this scenario
        await invalidateScenarioCache(scenarioId: updated.id)
        
        // Reload primary scenario if this was the primary
        if updated.isPrimary {
            await loadPrimaryScenario()
        }
        
        return updated
    }
}
