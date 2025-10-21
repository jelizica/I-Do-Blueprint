//
//  PaymentTypes.swift
//  I Do Blueprint
//
//  Supporting types for payment management
//

import Foundation

// MARK: - Payment Filter

enum PaymentFilter {
    case all, pending, paid, overdue, thisMonth

    var displayName: String {
        switch self {
        case .all: "All"
        case .pending: "Pending"
        case .paid: "Paid"
        case .overdue: "Overdue"
        case .thisMonth: "This Month"
        }
    }
}

// MARK: - Payment Sort Option

enum PaymentSortOption: String, CaseIterable {
    case dueDate
    case amount
    case vendor
    case status

    var displayName: String {
        switch self {
        case .dueDate: "Due Date"
        case .amount: "Amount"
        case .vendor: "Vendor"
        case .status: "Status"
        }
    }
}

// MARK: - Payment Summary Data

struct PaymentSummaryData {
    let totalAmount: Double
    let paidAmount: Double
    let pendingAmount: Double
    let overdueAmount: Double
    let overdueCount: Int
    let thisMonthAmount: Double
    let thisMonthCount: Int
}

// MARK: - Payment Schedule Item

struct PaymentScheduleItem {
    let id: String
    let description: String
    let amount: Double
    let vendorName: String
    let dueDate: Date
    var isPaid: Bool
    let isRecurring: Bool
    let paymentMethod: String?

    init(
        id: String,
        description: String,
        amount: Double,
        vendorName: String,
        dueDate: Date,
        isPaid: Bool,
        isRecurring: Bool = false,
        paymentMethod: String? = nil) {
        self.id = id
        self.description = description
        self.amount = amount
        self.vendorName = vendorName
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.isRecurring = isRecurring
        self.paymentMethod = paymentMethod
    }
}
