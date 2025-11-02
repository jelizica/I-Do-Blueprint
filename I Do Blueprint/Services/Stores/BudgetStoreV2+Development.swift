//
//  BudgetStoreV2+Development.swift
//  I Do Blueprint
//
//  Budget development operations for BudgetStoreV2
//

import Foundation

// MARK: - Budget Development Operations

extension BudgetStoreV2 {
    
    // MARK: - Budget Development Item Operations
    
    /// Load budget development items for a specific scenario
    func loadBudgetDevelopmentItems(scenarioId: String? = nil) async -> [BudgetItem] {
        do {
            let items = try await repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
            return items
        } catch {
            logger.error("Failed to load budget development items", error: error)
            return []
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
        return savedItem
    }
    
    /// Delete a budget development item
    func deleteBudgetDevelopmentItem(id: String) async throws {
        try await repository.deleteBudgetDevelopmentItem(id: id)
        logger.info("Deleted budget development item: \(id)")
    }
    
    // MARK: - Scenario Management
    
    /// Save scenario and items atomically via repository RPC
    func saveScenarioWithItems(_ scenario: SavedScenario, items: [BudgetItem]) async throws -> (scenarioId: String, insertedItems: Int) {
        try await repository.saveBudgetScenarioWithItems(scenario, items: items)
    }
}
