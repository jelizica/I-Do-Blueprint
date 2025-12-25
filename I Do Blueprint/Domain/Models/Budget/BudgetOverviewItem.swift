//
//  BudgetOverviewItem.swift
//  My Wedding Planning App
//
//  Budget overview item with linked expenses and gifts
//

import Foundation

struct BudgetOverviewItem: Identifiable, Codable {
    let id: String
    let itemName: String
    let category: String
    let subcategory: String
    let budgeted: Double
    let spent: Double
    let effectiveSpent: Double
    let expenses: [ExpenseLink]
    let gifts: [GiftLink]
    
    // Folder-related properties
    let isFolder: Bool
    let parentFolderId: String?
    let displayOrder: Int
    
    // Computed property to check if this is a top-level item
    var isTopLevel: Bool {
        parentFolderId == nil
    }
    
    // Default initializer for non-folder items (backward compatibility)
    init(
        id: String,
        itemName: String,
        category: String,
        subcategory: String,
        budgeted: Double,
        spent: Double,
        effectiveSpent: Double,
        expenses: [ExpenseLink],
        gifts: [GiftLink],
        isFolder: Bool = false,
        parentFolderId: String? = nil,
        displayOrder: Int = 0
    ) {
        self.id = id
        self.itemName = itemName
        self.category = category
        self.subcategory = subcategory
        self.budgeted = budgeted
        self.spent = spent
        self.effectiveSpent = effectiveSpent
        self.expenses = expenses
        self.gifts = gifts
        self.isFolder = isFolder
        self.parentFolderId = parentFolderId
        self.displayOrder = displayOrder
    }
}

struct ExpenseLink: Identifiable, Codable {
    let id: String
    let title: String
    let amount: Double
}

struct GiftLink: Identifiable, Codable {
    let id: String
    let title: String
    let amount: Double
}
