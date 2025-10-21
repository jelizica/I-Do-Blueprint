//
//  MoneyOwedTypes.swift
//  I Do Blueprint
//
//  Data models and types for money owed view
//

import SwiftUI

// MARK: - Status Filter

enum StatusFilter: String, CaseIterable {
    case all = "All"
    case pending = "Pending"
    case paid = "Paid"
    case overdue = "Overdue"
}

// MARK: - Sort Order

enum SortOrder: String, CaseIterable {
    case dueDateAscending = "Due Date (Earliest)"
    case dueDateDescending = "Due Date (Latest)"
    case amountDescending = "Amount (High to Low)"
    case amountAscending = "Amount (Low to High)"
    case priorityDescending = "Priority (High to Low)"
    case personAscending = "Person (A-Z)"
}

// MARK: - Priority Data

struct PriorityData {
    let priority: OwedPriority
    let amount: Double
    let count: Int
    let color: Color
}

// MARK: - Due Date Data

struct DueDateData {
    let date: Date
    let amount: Double
    let isOverdue: Bool
}

// MARK: - Owed Priority Extension

extension OwedPriority {
    var color: Color {
        switch self {
        case .low: AppColors.Budget.underBudget
        case .medium: AppColors.Budget.pending
        case .high: AppColors.Budget.overBudget
        }
    }

    var abbreviation: String {
        switch self {
        case .low: "L"
        case .medium: "M"
        case .high: "H"
        }
    }

    var sortOrder: Int {
        switch self {
        case .high: 3
        case .medium: 2
        case .low: 1
        }
    }
}
