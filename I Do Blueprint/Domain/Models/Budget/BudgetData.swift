//
//  BudgetData.swift
//  I Do Blueprint
//
//  Created for JES-47: Standardize Loading States
//

import Foundation

/// Container for budget data used in LoadingState
struct BudgetData {
    var summary: BudgetSummary?
    var categories: [BudgetCategory]
    var expenses: [Expense]
}
