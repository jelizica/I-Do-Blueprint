//
//  BudgetFilter.swift
//  My Wedding Planning App
//
//  Budget filter options for overview dashboard
//

import Foundation

enum BudgetFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case overBudget = "Over Budget"
    case underBudget = "Under Budget"
    case onTrack = "On Track"
    case noExpenses = "No Expenses"

    var id: String { rawValue }
}
