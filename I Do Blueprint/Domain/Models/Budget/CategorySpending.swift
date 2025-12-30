//
//  CategorySpending.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Model for category spending analysis
//

import Foundation

struct CategorySpending {
    let categoryId: UUID
    let categoryName: String
    let allocatedAmount: Double
    let spentAmount: Double
    let remainingAmount: Double
    let percentageSpent: Double
    let expenseCount: Int
    let lastExpenseDate: Date?
    let isOverBudget: Bool
    let priority: BudgetPriority
    let color: String
}
