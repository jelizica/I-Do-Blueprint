//
//  PaymentPlanGroupingStrategy.swift
//  I Do Blueprint
//
//  Defines strategies for grouping payment schedules in the Plans view
//

import Foundation

/// Strategy for grouping payment schedules in the Plans view
enum PaymentPlanGroupingStrategy: String, CaseIterable, Codable {
    case byPlanId = "by_plan_id"
    case byExpense = "by_expense"
    case byVendor = "by_vendor"
    
    var displayName: String {
        switch self {
        case .byPlanId: return "By Plan ID"
        case .byExpense: return "By Expense"
        case .byVendor: return "By Vendor"
        }
    }
    
    var description: String {
        switch self {
        case .byPlanId:
            return "Group payments by their original payment plan ID. Shows plans as they were created."
        case .byExpense:
            return "Group all payments for the same expense together. Recommended for seeing the complete payment picture."
        case .byVendor:
            return "Group all payments for the same vendor together, across all expenses."
        }
    }
    
    var icon: String {
        switch self {
        case .byPlanId: return "list.number"
        case .byExpense: return "doc.text"
        case .byVendor: return "building.2"
        }
    }
}

/// Helper enum for determining payment plan types from payment patterns
enum PaymentPlanType: String {
    case individual = "individual"
    case simpleRecurring = "simple-recurring"
    case intervalRecurring = "interval-recurring"
    case installment = "installment"
    case mixed = "mixed"
    
    var displayName: String {
        switch self {
        case .individual: return "One-time Payment"
        case .simpleRecurring: return "Monthly Recurring"
        case .intervalRecurring: return "Custom Interval"
        case .installment: return "Installment Plan"
        case .mixed: return "Mixed Payment Plan"
        }
    }
}
