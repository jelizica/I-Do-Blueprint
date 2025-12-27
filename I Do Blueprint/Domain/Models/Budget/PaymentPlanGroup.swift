//
//  PaymentPlanGroup.swift
//  I Do Blueprint
//
//  Hierarchical grouping structure for payment plans
//

import Foundation

/// Represents a hierarchical group of payment plans
/// Used for "By Vendor" and "By Expense" grouping strategies
struct PaymentPlanGroup: Identifiable {
    let id: UUID
    let groupName: String
    let groupType: GroupType
    let plans: [PaymentPlanSummary]
    
    enum GroupType {
        case vendor(vendorId: Int64)
        case expense(expenseId: UUID)
    }
    
    // Computed aggregates across all plans in the group
    var totalAmount: Double {
        plans.reduce(0) { $0 + $1.totalAmount }
    }
    
    var amountPaid: Double {
        plans.reduce(0) { $0 + $1.amountPaid }
    }
    
    var amountRemaining: Double {
        plans.reduce(0) { $0 + $1.amountRemaining }
    }
    
    var percentPaid: Double {
        totalAmount > 0 ? (amountPaid / totalAmount) * 100 : 0
    }
    
    var totalPayments: Int {
        plans.reduce(0) { $0 + ($1.totalPayments ?? 0) }
    }
    
    var paymentsCompleted: Int64 {
        plans.reduce(0) { $0 + $1.paymentsCompleted }
    }
    
    var paymentsRemaining: Int64 {
        plans.reduce(0) { $0 + $1.paymentsRemaining }
    }
    
    var hasOverdue: Bool {
        plans.contains { $0.isOverdue }
    }
    
    var overdueCount: Int64 {
        plans.reduce(0) { $0 + $1.overdueCount }
    }
    
    var nextPaymentDate: Date? {
        plans.compactMap { $0.nextPaymentDate }.min()
    }
    
    var allCompleted: Bool {
        !plans.isEmpty && plans.allSatisfy { $0.planStatus == .completed }
    }
}
