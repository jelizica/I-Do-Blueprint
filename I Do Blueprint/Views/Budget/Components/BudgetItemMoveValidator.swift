//
//  BudgetItemMoveValidator.swift
//  I Do Blueprint
//
//  Validates budget item move operations to prevent circular dependencies
//

import Foundation

struct BudgetItemMoveValidator {
    /// Validates whether an item can be moved to a target folder
    /// - Parameters:
    ///   - item: The item to move
    ///   - toFolder: The target folder
    ///   - allItems: All budget items for hierarchy traversal
    /// - Returns: True if the move is valid, false otherwise
    static func canMove(item: BudgetItem, toFolder: BudgetItem, allItems: [BudgetItem]) -> Bool {
        // Cannot move item to itself
        if item.id == toFolder.id { return false }
        
        // If moving a folder, ensure we're not moving it into one of its descendants
        if item.isFolder {
            var currentId: String? = toFolder.id
            while let id = currentId {
                if id == item.id { return false }
                currentId = allItems.first(where: { $0.id == id })?.parentFolderId
            }
        }
        
        // Check folder depth limit (max 3 levels)
        var depth = 0
        var currentId: String? = toFolder.id
        while let id = currentId {
            depth += 1
            if depth >= 3 { return false }
            currentId = allItems.first(where: { $0.id == id })?.parentFolderId
        }
        
        return true
    }
}
