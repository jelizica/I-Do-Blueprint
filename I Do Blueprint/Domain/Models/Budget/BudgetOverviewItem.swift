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
