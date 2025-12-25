//
//  BudgetFolder.swift
//  I Do Blueprint
//
//  Helper utilities for budget folder operations
//

import Foundation

/// Helper struct for budget folder calculations and validation
struct BudgetFolder {
    
    // MARK: - Total Calculations
    
    /// Result of folder total calculations
    struct FolderTotals {
        let totalWithoutTax: Double
        let totalTax: Double
        let totalWithTax: Double
    }
    
    /// Calculates all totals for a folder in a single traversal (optimized)
    /// - Parameters:
    ///   - allItems: All budget items in the scenario
    ///   - folderId: Folder ID to calculate totals for
    /// - Returns: FolderTotals containing all three totals
    static func calculateAllTotals(allItems: [BudgetItem], folderId: String) -> FolderTotals {
        let descendants = getAllDescendantItems(allItems: allItems, folderId: folderId)
        
        // Single pass calculation of all three totals
        let totals = descendants.reduce((withoutTax: 0.0, tax: 0.0, withTax: 0.0)) { accumulator, item in
            let tax = item.vendorEstimateWithoutTax * item.taxRate / 100
            return (
                withoutTax: accumulator.withoutTax + item.vendorEstimateWithoutTax,
                tax: accumulator.tax + tax,
                withTax: accumulator.withTax + item.vendorEstimateWithTax
            )
        }
        
        return FolderTotals(
            totalWithoutTax: totals.withoutTax,
            totalTax: totals.tax,
            totalWithTax: totals.withTax
        )
    }
    
    /// Calculates total amount without tax for all items in a folder (recursive)
    /// - Parameters:
    ///   - allItems: All budget items in the scenario
    ///   - folderId: Folder ID to calculate totals for
    /// - Returns: Total amount without tax
    static func calculateTotalWithoutTax(allItems: [BudgetItem], folderId: String) -> Double {
        calculateAllTotals(allItems: allItems, folderId: folderId).totalWithoutTax
    }
    
    /// Calculates total tax for all items in a folder (recursive)
    /// - Parameters:
    ///   - allItems: All budget items in the scenario
    ///   - folderId: Folder ID to calculate totals for
    /// - Returns: Total tax amount
    static func calculateTotalTax(allItems: [BudgetItem], folderId: String) -> Double {
        calculateAllTotals(allItems: allItems, folderId: folderId).totalTax
    }
    
    /// Calculates total amount with tax for all items in a folder (recursive)
    /// - Parameters:
    ///   - allItems: All budget items in the scenario
    ///   - folderId: Folder ID to calculate totals for
    /// - Returns: Total amount with tax
    static func calculateTotalWithTax(allItems: [BudgetItem], folderId: String) -> Double {
        calculateAllTotals(allItems: allItems, folderId: folderId).totalWithTax
    }
    
    // MARK: - Hierarchy Navigation
    
    /// Gets all descendant items (not folders) of a folder recursively
    /// - Parameters:
    ///   - allItems: All budget items in the scenario
    ///   - folderId: Folder ID to get descendants for
    /// - Returns: Array of all descendant items (excluding folders)
    static func getAllDescendantItems(allItems: [BudgetItem], folderId: String) -> [BudgetItem] {
        var result: [BudgetItem] = []
        var queue = [folderId]
        var queueIndex = 0
        var visited = Set<String>([folderId]) // Track visited folders to prevent cycles
        
        while queueIndex < queue.count {
            let currentId = queue[queueIndex]
            queueIndex += 1
            
            // Get all children of current folder
            let children = allItems.filter { $0.parentFolderId == currentId }
            
            for child in children {
                if child.isFolder {
                    // Only process folder if not already visited (cycle protection)
                    if !visited.contains(child.id) {
                        visited.insert(child.id)
                        queue.append(child.id)
                    }
                } else {
                    // Add non-folder items to result
                    result.append(child)
                }
            }
        }
        
        return result
    }
    
    /// Gets the hierarchy level of an item (0 = root, 1 = first level, etc.)
    /// - Parameters:
    ///   - allItems: All budget items in the scenario
    ///   - itemId: Item ID to get level for
    /// - Returns: Hierarchy level (0-based), or -1 if circular reference detected
    static func getHierarchyLevel(allItems: [BudgetItem], itemId: String) -> Int {
        var level = 0
        var currentId: String? = itemId
        var visited = Set<String>()
        
        while let id = currentId,
              let item = allItems.first(where: { $0.id == id }),
              let parentId = item.parentFolderId {
            // Check for circular reference
            if visited.contains(id) {
                // Circular reference detected - return sentinel value
                return -1
            }
            visited.insert(id)
            
            level += 1
            currentId = parentId
        }
        
        return level
    }
    
    /// Gets all direct children of a folder
    /// - Parameters:
    ///   - allItems: All budget items in the scenario
    ///   - folderId: Folder ID (nil for root level)
    /// - Returns: Array of direct children sorted by display order
    static func getChildren(allItems: [BudgetItem], folderId: String?) -> [BudgetItem] {
        allItems
            .filter { $0.parentFolderId == folderId }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    // MARK: - Validation
    
    /// Validates if an item can be moved to a target folder
    /// - Parameters:
    ///   - folderId: Target folder ID (nil for root)
    ///   - allItems: All budget items in the scenario
    ///   - itemId: Item ID to move
    ///   - maxDepth: Maximum allowed depth (default: 3)
    /// - Returns: True if move is valid
    static func canMoveTo(
        folderId: String?,
        allItems: [BudgetItem],
        itemId: String,
        maxDepth: Int = 3
    ) -> Bool {
        // Can't move to itself
        if folderId == itemId { return false }
        
        // Check depth limit
        let targetDepth = folderId.map { getHierarchyLevel(allItems: allItems, itemId: $0) } ?? 0
        if targetDepth == -1 || targetDepth >= maxDepth { return false }
        
        // Prevent circular references by checking if target folder is a descendant of itemId
        // Walk up from target folder through ancestors and check if any equals itemId
        var visited = Set<String>()
        var currentId: String? = folderId
        
        while let id = currentId {
            // Check for circular reference (target is descendant of item being moved)
            if id == itemId { return false }
            
            // Check for infinite loop
            if visited.contains(id) { return false }
            visited.insert(id)
            
            guard let item = allItems.first(where: { $0.id == id }) else { break }
            currentId = item.parentFolderId
        }
        
        return true
    }
    
    /// Checks if moving an item would create a circular reference
    /// - Parameters:
    ///   - itemId: Item to move
    ///   - targetFolderId: Target folder
    ///   - allItems: All budget items
    /// - Returns: True if circular reference would be created
    static func wouldCreateCircularReference(
        itemId: String,
        targetFolderId: String?,
        allItems: [BudgetItem]
    ) -> Bool {
        guard let targetFolderId = targetFolderId else { return false }
        
        var visited = Set<String>()
        var currentId: String? = targetFolderId
        
        while let id = currentId {
            if id == itemId { return true }
            if visited.contains(id) { return true }
            visited.insert(id)
            
            guard let item = allItems.first(where: { $0.id == id }) else { break }
            currentId = item.parentFolderId
        }
        
        return false
    }
    
    /// Validates folder depth limit
    /// - Parameters:
    ///   - folderId: Folder ID to check
    ///   - allItems: All budget items
    ///   - maxDepth: Maximum allowed depth
    /// - Returns: True if within depth limit
    static func isWithinDepthLimit(
        folderId: String,
        allItems: [BudgetItem],
        maxDepth: Int = 3
    ) -> Bool {
        let depth = getHierarchyLevel(allItems: allItems, itemId: folderId)
        return depth != -1 && depth < maxDepth
    }
    
    // MARK: - Folder Operations
    
    /// Gets all folders in a scenario
    /// - Parameter allItems: All budget items in the scenario
    /// - Returns: Array of folder items
    static func getAllFolders(allItems: [BudgetItem]) -> [BudgetItem] {
        allItems.filter { $0.isFolder }
    }
    
    /// Gets all root-level items (items with no parent)
    /// - Parameter allItems: All budget items in the scenario
    /// - Returns: Array of root-level items
    static func getRootItems(allItems: [BudgetItem]) -> [BudgetItem] {
        allItems
            .filter { $0.parentFolderId == nil }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    /// Checks if a folder is empty (has no children)
    /// - Parameters:
    ///   - folderId: Folder ID to check
    ///   - allItems: All budget items
    /// - Returns: True if folder is empty
    static func isEmpty(folderId: String, allItems: [BudgetItem]) -> Bool {
        !allItems.contains { $0.parentFolderId == folderId }
    }
    
    /// Gets the path from root to an item (breadcrumb trail)
    /// - Parameters:
    ///   - itemId: Item ID
    ///   - allItems: All budget items
    /// - Returns: Array of items from root to target (excluding target)
    static func getPath(itemId: String, allItems: [BudgetItem]) -> [BudgetItem] {
        var path: [BudgetItem] = []
        var currentId: String? = itemId
        var visited = Set<String>()
        
        while let id = currentId,
              let item = allItems.first(where: { $0.id == id }),
              let parentId = item.parentFolderId {
            // Check for cycle
            if visited.contains(parentId) {
                break
            }
            visited.insert(id)
            
            guard let parent = allItems.first(where: { $0.id == parentId }) else {
                break
            }
            
            path.append(parent)  // O(1) append
            currentId = parentId
        }
        
        return path.reversed()  // Reverse to get root→closest parent order
    }
}
