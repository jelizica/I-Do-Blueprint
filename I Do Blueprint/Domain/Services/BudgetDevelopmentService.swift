//
//  BudgetDevelopmentService.swift
//  I Do Blueprint
//
//  Domain service for budget development business logic.
//  Handles complex operations like folder totals, validation, and hierarchical operations.
//

import Foundation

/// Domain service for budget development business logic
/// Handles complex operations that exceed simple CRUD
actor BudgetDevelopmentService {
    private nonisolated let logger = AppLogger.repository
    
    // MARK: - Folder Operations
    
    /// Calculates folder totals recursively
    /// - Parameters:
    ///   - folderId: The folder ID
    ///   - allItems: All items in the scenario
    /// - Returns: Folder totals (without tax, tax, with tax)
    func calculateFolderTotals(folderId: String, allItems: [BudgetItem]) -> FolderTotals {
        let descendants = getAllDescendants(of: folderId, from: allItems)
        
        let withoutTax = descendants.reduce(0) { $0 + $1.vendorEstimateWithoutTax }
        let tax = descendants.reduce(0) { $0 + ($1.vendorEstimateWithoutTax * $1.taxRate) }
        let withTax = descendants.reduce(0) { $0 + $1.vendorEstimateWithTax }
        
        return FolderTotals(withoutTax: withoutTax, tax: tax, withTax: withTax)
    }
    
    /// Validates if an item can be moved to a folder
    /// - Parameters:
    ///   - itemId: The item ID to move
    ///   - targetFolderId: The target folder ID (nil for root)
    ///   - allItems: All items in the scenario
    /// - Returns: True if the move is valid
    func canMoveItem(itemId: String, toFolder targetFolderId: String?, allItems: [BudgetItem]) -> Bool {
        // Can't move to itself
        if itemId == targetFolderId { return false }
        
        // If moving to root, always allowed
        guard let targetFolderId = targetFolderId else { return true }
        
        // Check if target is a folder
        guard let targetFolder = allItems.first(where: { $0.id == targetFolderId }),
              targetFolder.isFolder else {
            return false
        }
        
        // Check depth limit (max 3 levels)
        let targetDepth = getDepth(of: targetFolderId, in: allItems)
        if targetDepth >= 3 { return false }
        
        // Check for circular reference
        var visited = Set<String>()
        var currentId: String? = targetFolderId
        
        while let id = currentId {
            if visited.contains(id) || id == itemId { return false }
            visited.insert(id)
            
            guard let item = allItems.first(where: { $0.id == id }) else { break }
            currentId = item.parentFolderId
        }
        
        return true
    }
    
    /// Gets all descendant IDs for a folder (for deletion)
    /// - Parameters:
    ///   - folderId: The folder ID
    ///   - allItems: All items in the scenario
    /// - Returns: Array of descendant item IDs
    func getAllDescendantIds(of folderId: String, from allItems: [BudgetItem]) -> [String] {
        var result: [String] = []
        let directChildren = allItems.filter { $0.parentFolderId == folderId }
        
        for child in directChildren {
            result.append(child.id)
            if child.isFolder {
                result.append(contentsOf: getAllDescendantIds(of: child.id, from: allItems))
            }
        }
        
        return result
    }
    
    /// Gets direct children of a folder
    /// - Parameters:
    ///   - folderId: The folder ID
    ///   - allItems: All items in the scenario
    /// - Returns: Array of direct child items
    func getDirectChildren(of folderId: String, from allItems: [BudgetItem]) -> [BudgetItem] {
        return allItems.filter { $0.parentFolderId == folderId }
    }
    
    // MARK: - Private Helpers
    
    /// Recursively collects all descendants of a folder
    private func getAllDescendants(of folderId: String, from items: [BudgetItem]) -> [BudgetItem] {
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
    
    /// Gets the depth of an item in the folder hierarchy
    private func getDepth(of itemId: String, in items: [BudgetItem]) -> Int {
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
}
