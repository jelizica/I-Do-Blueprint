//
//  BudgetEnums.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  All budget-related enums consolidated in one file
//

import Foundation

// MARK: - Budget Priority

enum BudgetPriority: String, Codable, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"

    var displayName: String {
        switch self {
        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"
        }
    }

    var sortOrder: Int {
        switch self {
        case .high: 1
        case .medium: 2
        case .low: 3
        }
    }
}

// MARK: - Payment Status

enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case partial = "partial"
    case paid = "paid"
    case overdue = "overdue"
    case cancelled = "cancelled"
    case refunded = "refunded"

    var displayName: String {
        switch self {
        case .pending: "Pending"
        case .partial: "Partial"
        case .paid: "Paid"
        case .overdue: "Overdue"
        case .cancelled: "Cancelled"
        case .refunded: "Refunded"
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .partial: return "yellow"
        case .paid: return "green"
        case .overdue: return "red"
        case .cancelled: return "gray"
        case .refunded: return "purple"
        }
    }
}

// MARK: - Payment Method

enum PaymentMethod: String, Codable, CaseIterable {
    case cash = "cash"
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    case bankTransfer = "bank_transfer"
    case check = "check"
    case venmo = "venmo"
    case zelle = "zelle"
    case paypal = "paypal"
    case other = "other"

    var displayName: String {
        switch self {
        case .cash: "Cash"
        case .creditCard: "Credit Card"
        case .debitCard: "Debit Card"
        case .bankTransfer: "Bank Transfer"
        case .check: "Check"
        case .venmo: "Venmo"
        case .zelle: "Zelle"
        case .paypal: "PayPal"
        case .other: "Other"
        }
    }
}

// MARK: - Recurring Frequency

enum RecurringFrequency: String, Codable, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"

    var displayName: String {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .quarterly: "Quarterly"
        case .yearly: "Yearly"
        }
    }
}

// MARK: - Budget Sort Option

enum BudgetSortOption: String, CaseIterable {
    case category = "category"
    case amount = "amount"
    case spent = "spent"
    case remaining = "remaining"
    case priority = "priority"
    case dueDate = "due_date"

    var displayName: String {
        switch self {
        case .category: "Category"
        case .amount: "Amount"
        case .spent: "Spent"
        case .remaining: "Remaining"
        case .priority: "Priority"
        case .dueDate: "Due Date"
        }
    }
}

// MARK: - Budget Filter Option

enum BudgetFilterOption: String, CaseIterable {
    case all = "all"
    case overBudget = "over_budget"
    case onTrack = "on_track"
    case underBudget = "under_budget"
    case highPriority = "high_priority"
    case essential = "essential"

    var displayName: String {
        switch self {
        case .all: "All Categories"
        case .overBudget: "Over Budget"
        case .onTrack: "On Track"
        case .underBudget: "Under Budget"
        case .highPriority: "High Priority"
        case .essential: "Essential"
        }
    }
}

// MARK: - Expense Filter Option

enum ExpenseFilterOption: String, CaseIterable {
    case all = "all"
    case pending = "pending"
    case partial = "partial"
    case paid = "paid"
    case overdue = "overdue"
    case dueToday = "due_today"
    case dueSoon = "due_soon"

    var displayName: String {
        switch self {
        case .all: "All Expenses"
        case .pending: "Pending"
        case .partial: "Partial"
        case .paid: "Paid"
        case .overdue: "Overdue"
        case .dueToday: "Due Today"
        case .dueSoon: "Due Soon"
        }
    }
}
