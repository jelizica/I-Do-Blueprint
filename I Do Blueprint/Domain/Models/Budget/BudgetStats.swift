//
//  BudgetStats.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Statistics and analytics model for budget overview
//

import Foundation

struct BudgetStats {
    let totalCategories: Int
    let categoriesOverBudget: Int
    let categoriesOnTrack: Int
    let totalExpenses: Int
    let expensesPending: Int
    let expensesOverdue: Int
    let averageSpendingPerCategory: Double
    let projectedOverage: Double
    let monthlyBurnRate: Double
}
