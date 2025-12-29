//
//  BudgetDevelopmentStoreV2.swift
//  I Do Blueprint
//
//  Budget development and folder operations store
//  Manages budget scenarios, items, allocations, and folder hierarchy
//

import Combine
import Dependencies
import Foundation
import SwiftUI

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

// MARK: - Budget Development Store

@MainActor
class BudgetDevelopmentStoreV2: ObservableObject {
    
    // MARK: - Dependencies
    
    @Dependency(\.budgetRepository) var repository
    let logger = AppLogger.database
    
    // MARK: - Store-Level Cache
    
    /// Store-level cache for scenario items (faster than repository cache)
    private static let scenarioCache = ScenarioCache()
    
    // MARK: - Initialization
    
    init() {}
    
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
        
        return updated
    }
    
    // MARK: - Folder Operations
    
    /// Creates a new budget folder
    /// - Parameters:
    ///   - name: Folder display name
    ///   - scenarioId: Scenario ID the folder belongs to
    ///   - parentFolderId: Parent folder ID (nil for root level)
    ///   - displayOrder: Display order within parent
    /// - Returns: Created folder item
    func createFolder(name: String, scenarioId: String, parentFolderId: String?, displayOrder: Int) async throws -> BudgetItem {
        do {
            let folder = try await repository.createFolder(
                name: name,
                scenarioId: scenarioId,
                parentFolderId: parentFolderId,
                displayOrder: displayOrder
            )
            
            logger.info("Created folder: \(name) in scenario \(scenarioId)")
            
            // Invalidate cache for this scenario
            await invalidateScenarioCache(scenarioId: scenarioId)
            
            return folder
        } catch {
            logger.error("Error creating folder", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "createFolder",
                    feature: "budget",
                    metadata: ["folderName": name, "scenarioId": scenarioId]
                )
            )
            throw BudgetError.createFailed(underlying: error)
        }
    }
    
    /// Moves an item to a different folder
    /// - Parameters:
    ///   - itemId: Item/folder to move
    ///   - targetFolderId: Destination folder (nil for root)
    ///   - displayOrder: New display order
    func moveItemToFolder(itemId: String, targetFolderId: String?, displayOrder: Int) async throws {
        do {
            try await repository.moveItemToFolder(
                itemId: itemId,
                targetFolderId: targetFolderId,
                displayOrder: displayOrder
            )
            
            logger.info("Moved item \(itemId) to folder \(targetFolderId ?? "root")")
            
            // Invalidate all scenario caches (we don't know which scenario this item belongs to)
            await invalidateScenarioCache()
        } catch {
            logger.error("Error moving item to folder", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "moveItemToFolder",
                    feature: "budget",
                    metadata: ["itemId": itemId, "targetFolderId": targetFolderId ?? "root"]
                )
            )
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    /// Updates display order for multiple items (drag-and-drop)
    /// - Parameter items: Array of (itemId, displayOrder) tuples
    func updateDisplayOrder(items: [(itemId: String, displayOrder: Int)]) async throws {
        do {
            try await repository.updateDisplayOrder(items: items)
            logger.info("Updated display order for \(items.count) items")
            
            // Invalidate all scenario caches
            await invalidateScenarioCache()
        } catch {
            logger.error("Error updating display order", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "updateDisplayOrder",
                    feature: "budget",
                    metadata: ["itemCount": items.count]
                )
            )
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    /// Toggles folder expansion state
    /// - Parameters:
    ///   - folderId: Folder ID
    ///   - isExpanded: New expansion state
    func toggleFolderExpansion(folderId: String, isExpanded: Bool) async throws {
        do {
            try await repository.toggleFolderExpansion(folderId: folderId, isExpanded: isExpanded)
            logger.info("Toggled folder \(folderId) expansion to \(isExpanded)")
        } catch {
            logger.error("Error toggling folder expansion", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "toggleFolderExpansion",
                    feature: "budget",
                    metadata: ["folderId": folderId, "isExpanded": isExpanded]
                )
            )
            throw BudgetError.updateFailed(underlying: error)
        }
    }
    
    /// Fetches budget items with hierarchical structure
    /// - Parameter scenarioId: Scenario ID to fetch
    /// - Returns: Flat array of items with folder relationships
    func fetchBudgetItemsHierarchical(scenarioId: String) async throws -> [BudgetItem] {
        do {
            let items = try await repository.fetchBudgetItemsHierarchical(scenarioId: scenarioId)
            logger.info("Fetched \(items.count) hierarchical items for scenario \(scenarioId)")
            return items
        } catch {
            logger.error("Error fetching hierarchical items", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "fetchBudgetItemsHierarchical",
                    feature: "budget",
                    metadata: ["scenarioId": scenarioId]
                )
            )
            throw BudgetError.fetchFailed(underlying: error)
        }
    }
    
    /// Calculates folder totals using database function
    /// - Parameter folderId: Folder ID
    /// - Returns: FolderTotals struct with withoutTax, tax, withTax
    func calculateFolderTotals(folderId: String) async throws -> FolderTotals {
        do {
            let totals = try await repository.calculateFolderTotals(folderId: folderId)
            logger.info("Calculated totals for folder \(folderId): $\(totals.withTax)")
            return totals
        } catch {
            logger.error("Error calculating folder totals", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "calculateFolderTotals",
                    feature: "budget",
                    metadata: ["folderId": folderId]
                )
            )
            throw BudgetError.fetchFailed(underlying: error)
        }
    }
    
    /// Validates if an item can be moved to a target folder
    /// - Parameters:
    ///   - itemId: Item to move
    ///   - targetFolderId: Target folder
    /// - Returns: True if move is valid
    /// - Throws: Repository errors if validation fails due to database/network issues
    func canMoveItem(itemId: String, toFolder targetFolderId: String?) async throws -> Bool {
        do {
            let canMove = try await repository.canMoveItem(itemId: itemId, toFolder: targetFolderId)
            return canMove
        } catch {
            logger.error("Error validating move", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "canMoveItem",
                    feature: "budget",
                    metadata: ["itemId": itemId, "targetFolderId": targetFolderId ?? "root"]
                )
            )
            throw BudgetError.fetchFailed(underlying: error)
        }
    }
    
    /// Deletes a folder and optionally moves contents to parent
    /// - Parameters:
    ///   - folderId: Folder to delete
    ///   - deleteContents: If true, delete all contents; if false, move to parent
    func deleteFolder(folderId: String, deleteContents: Bool) async throws {
        do {
            try await repository.deleteFolder(folderId: folderId, deleteContents: deleteContents)
            logger.info("Deleted folder \(folderId), contents \(deleteContents ? "deleted" : "moved to parent")")
            
            // Invalidate all scenario caches
            await invalidateScenarioCache()
        } catch {
            logger.error("Error deleting folder", error: error)
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "deleteFolder",
                    feature: "budget",
                    metadata: ["folderId": folderId, "deleteContents": deleteContents]
                )
            )
            throw BudgetError.deleteFailed(underlying: error)
        }
    }
    
    // MARK: - Folder Helper Methods
    
    /// Builds hierarchical structure from flat array of items
    /// - Parameter items: Flat array of budget items
    /// - Returns: Array of items at root level (parentFolderId == nil)
    func getChildren(of folderId: String?, from items: [BudgetItem]) -> [BudgetItem] {
        items.filter { $0.parentFolderId == folderId }.sorted { $0.displayOrder < $1.displayOrder }
    }
    
    /// Gets all descendant items of a folder (recursive)
    /// - Parameters:
    ///   - folderId: Folder ID
    ///   - items: All items in scenario
    /// - Returns: All descendant items (not folders)
    func getAllDescendants(of folderId: String, from items: [BudgetItem]) -> [BudgetItem] {
        var result: [BudgetItem] = []
        var queue = [folderId]
        
        while !queue.isEmpty {
            let currentId = queue.removeFirst()
            let children = items.filter { $0.parentFolderId == currentId && !$0.isFolder }
            result.append(contentsOf: children)
            
            // Add child folders to queue
            let childFolders = items.filter { $0.parentFolderId == currentId && $0.isFolder }
            queue.append(contentsOf: childFolders.map { $0.id })
        }
        
        return result
    }
    
    /// Calculates folder totals locally (without database call)
    /// - Parameters:
    ///   - folderId: Folder ID
    ///   - allItems: All items in scenario
    /// - Returns: FolderTotals struct
    func calculateLocalFolderTotals(folderId: String, allItems: [BudgetItem]) -> FolderTotals {
        let descendants = getAllDescendants(of: folderId, from: allItems)
        let withoutTax = descendants.reduce(0) { $0 + $1.vendorEstimateWithoutTax }
        let withTax = descendants.reduce(0) { $0 + $1.vendorEstimateWithTax }
        let tax = withTax - withoutTax
        
        return FolderTotals(withoutTax: withoutTax, tax: tax, withTax: withTax)
    }
    
    /// Gets the hierarchy level of an item (0 = root, 1 = first level, etc.)
    /// - Parameters:
    ///   - itemId: Item ID
    ///   - allItems: All items in scenario
    /// - Returns: Hierarchy level (0-based), or -1 if circular reference detected
    func getHierarchyLevel(itemId: String, allItems: [BudgetItem]) -> Int {
        var level = 0
        var currentId: String? = itemId
        var visited = Set<String>()
        
        while let id = currentId,
              let item = allItems.first(where: { $0.id == id }),
              let parentId = item.parentFolderId {
            // Check for circular reference
            if visited.contains(id) {
                // Circular reference detected - return sentinel value
                logger.error("Circular reference detected in folder hierarchy for item: \(itemId)")
                return -1
            }
            visited.insert(id)
            
            level += 1
            currentId = parentId
        }
        
        return level
    }
    
    // MARK: - State Management
    
    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        // Invalidate all caches
        Task {
            await invalidateScenarioCache()
        }
    }
}
