//
//  PaymentSchedule.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Model for tracking payment schedules and plans
//  Note: Custom decoding logic is in PaymentSchedule+Migration.swift extension
//

import Foundation

struct PaymentSchedule: Identifiable, Codable {
    let id: Int64
    let coupleId: UUID
    var vendor: String
    var paymentDate: Date
    var paymentAmount: Double
    var notes: String?
    var vendorType: String?
    var paid: Bool
    var paymentType: String?
    var customAmount: Double?
    var billingFrequency: String?
    var autoRenew: Bool
    var startDate: Date?
    var reminderEnabled: Bool
    var reminderDaysBefore: Int?
    var priorityLevel: String?
    var expenseId: UUID?
    var vendorId: Int64?
    var isDeposit: Bool
    var isRetainer: Bool
    var paymentOrder: Int?
    var totalPaymentCount: Int?
    var paymentPlanType: String?
    var paymentPlanId: UUID?
    var segmentIndex: Int?  // For async plans: 0-based index of the segment this payment belongs to
    var createdAt: Date
    var updatedAt: Date?

    // MARK: - Partial Payment Tracking Fields

    /// The originally scheduled payment amount (immutable after creation)
    var originalAmount: Double
    /// The actual amount paid by the user (may differ from paymentAmount for partial/over payments)
    var amountPaid: Double
    /// Amount carried over from a previous underpayment
    var carryoverAmount: Double
    /// Reference to the payment that generated this carryover
    var carryoverFromId: Int64?
    /// True if this payment was auto-created from an underpayment
    var isCarryover: Bool
    /// Timestamp when the payment was actually recorded/made
    var paymentRecordedAt: Date?

    // Computed properties for backward compatibility
    var amount: Double {
        paymentAmount
    }

    var dueDate: Date {
        paymentDate
    }

    var paymentStatus: PaymentStatus {
        paid ? .paid : .pending
    }

    var reminderSent: Bool {
        false // This field doesn't exist in the actual table
    }

    // Payment status enum from payment_status field (if present)
    var paymentStatusFromDB: PaymentStatus? {
        // This would require adding a payment_status field to the struct
        // For now, return computed value based on paid flag
        if paid {
            return .paid
        }
        // Check if overdue
        if paymentDate < Date() {
            return .overdue
        }
        return .pending
    }

    // MARK: - Partial Payment Computed Properties

    /// The remaining balance to be paid on this payment
    var remainingBalance: Double {
        max(0, paymentAmount - amountPaid)
    }

    /// Whether this payment has been partially paid
    var isPartiallyPaid: Bool {
        amountPaid > 0 && amountPaid < paymentAmount
    }

    /// Whether this payment was overpaid
    var isOverpaid: Bool {
        amountPaid > paymentAmount
    }

    /// The overpayment amount (excess paid beyond what was due)
    var overpaymentAmount: Double {
        max(0, amountPaid - paymentAmount)
    }

    /// The underpayment amount (shortfall from what was due)
    var underpaymentAmount: Double {
        max(0, paymentAmount - amountPaid)
    }

    /// Whether any payment has been recorded
    var hasPaymentRecorded: Bool {
        amountPaid > 0
    }

    // Explicit memberwise initializer
    init(
        id: Int64,
        coupleId: UUID,
        vendor: String,
        paymentDate: Date,
        paymentAmount: Double,
        notes: String? = nil,
        vendorType: String? = nil,
        paid: Bool,
        paymentType: String? = nil,
        customAmount: Double? = nil,
        billingFrequency: String? = nil,
        autoRenew: Bool,
        startDate: Date? = nil,
        reminderEnabled: Bool,
        reminderDaysBefore: Int? = nil,
        priorityLevel: String? = nil,
        expenseId: UUID? = nil,
        vendorId: Int64? = nil,
        isDeposit: Bool,
        isRetainer: Bool,
        paymentOrder: Int? = nil,
        totalPaymentCount: Int? = nil,
        paymentPlanType: String? = nil,
        paymentPlanId: UUID? = nil,
        segmentIndex: Int? = nil,
        createdAt: Date,
        updatedAt: Date? = nil,
        originalAmount: Double? = nil,
        amountPaid: Double = 0,
        carryoverAmount: Double = 0,
        carryoverFromId: Int64? = nil,
        isCarryover: Bool = false,
        paymentRecordedAt: Date? = nil
    ) {
        self.id = id
        self.coupleId = coupleId
        self.vendor = vendor
        self.paymentDate = paymentDate
        self.paymentAmount = paymentAmount
        self.notes = notes
        self.vendorType = vendorType
        self.paid = paid
        self.paymentType = paymentType
        self.customAmount = customAmount
        self.billingFrequency = billingFrequency
        self.autoRenew = autoRenew
        self.startDate = startDate
        self.reminderEnabled = reminderEnabled
        self.reminderDaysBefore = reminderDaysBefore
        self.priorityLevel = priorityLevel
        self.expenseId = expenseId
        self.vendorId = vendorId
        self.isDeposit = isDeposit
        self.isRetainer = isRetainer
        self.paymentOrder = paymentOrder
        self.totalPaymentCount = totalPaymentCount
        self.paymentPlanType = paymentPlanType
        self.paymentPlanId = paymentPlanId
        self.segmentIndex = segmentIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        // Default originalAmount to paymentAmount if not provided (backward compatibility)
        self.originalAmount = originalAmount ?? paymentAmount
        self.amountPaid = amountPaid
        self.carryoverAmount = carryoverAmount
        self.carryoverFromId = carryoverFromId
        self.isCarryover = isCarryover
        self.paymentRecordedAt = paymentRecordedAt
    }

    // Custom decoding moved to PaymentSchedule+Migration.swift extension
    // This allows for legacy payment_type migration logic
    // The extension provides init(from:) with migration support

    // CodingKeys is internal (not private) so it can be shared with PaymentSchedule+Migration.swift
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case coupleId = "couple_id"
        case vendor = "vendor"
        case paymentDate = "payment_date"
        case paymentAmount = "payment_amount"
        case notes = "notes"
        case vendorType = "vendor_type"
        case paid = "paid"
        case paymentType = "payment_type"
        case customAmount = "custom_amount"
        case billingFrequency = "billing_frequency"
        case autoRenew = "auto_renew"
        case startDate = "start_date"
        case reminderEnabled = "reminder_enabled"
        case reminderDaysBefore = "reminder_days_before"
        case priorityLevel = "priority_level"
        case expenseId = "expense_id"
        case vendorId = "vendor_id"
        case isDeposit = "is_deposit"
        case isRetainer = "is_retainer"
        case paymentOrder = "payment_order"
        case totalPaymentCount = "total_payment_count"
        case paymentPlanType = "payment_plan_type"
        case paymentPlanId = "payment_plan_id"
        case segmentIndex = "segment_index"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        // Partial payment tracking fields
        case originalAmount = "original_amount"
        case amountPaid = "amount_paid"
        case carryoverAmount = "carryover_amount"
        case carryoverFromId = "carryover_from_id"
        case isCarryover = "is_carryover"
        case paymentRecordedAt = "payment_recorded_at"
    }
}
