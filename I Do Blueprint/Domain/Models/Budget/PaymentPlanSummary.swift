//
//  PaymentPlanSummary.swift
//  I Do Blueprint
//
//  Aggregated view of a payment plan showing plan-level summary
//

import Foundation
import SwiftUI

/// Aggregated view of a payment plan showing plan-level summary
struct PaymentPlanSummary: Identifiable, Sendable, Codable {
    // MARK: - Identifiers
    
    /// Unique identifier for this payment plan
    let paymentPlanId: UUID
    let expenseId: UUID
    let coupleId: UUID
    let vendor: String
    let vendorId: Int64
    let vendorType: String?
    
    /// Use paymentPlanId as the unique identifier for SwiftUI
    var id: UUID { paymentPlanId }
    
    // MARK: - Plan Type
    let paymentType: String
    let paymentPlanType: String
    let planTypeDisplay: String
    
    // MARK: - Plan Metadata
    /// Total payments in the plan (may be null if not explicitly set, defaults to actualPaymentCount)
    let totalPayments: Int?
    let firstPaymentDate: Date
    let lastPaymentDate: Date
    let depositDate: Date?
    
    // MARK: - Financial Aggregates
    let totalAmount: Double
    let amountPaid: Double
    let amountRemaining: Double
    let depositAmount: Double
    let percentPaid: Double
    
    // MARK: - Payment Counts (bigint in database)
    let actualPaymentCount: Int64
    let paymentsCompleted: Int64
    let paymentsRemaining: Int64
    let depositCount: Int64
    
    // MARK: - Status
    let allPaid: Bool
    let anyPaid: Bool
    let hasDeposit: Bool
    let hasRetainer: Bool
    let planStatus: PlanStatus
    
    // MARK: - Next Payment
    let nextPaymentDate: Date?
    let nextPaymentAmount: Double?
    let daysUntilNextPayment: Int?
    
    // MARK: - Overdue (bigint in database)
    let overdueCount: Int64
    let overdueAmount: Double
    
    // MARK: - Additional Info
    let combinedNotes: String?
    let planCreatedAt: Date
    let planUpdatedAt: Date?
    
    // MARK: - Memberwise Initializer
    
    init(
        paymentPlanId: UUID,
        expenseId: UUID,
        coupleId: UUID,
        vendor: String,
        vendorId: Int64,
        vendorType: String?,
        paymentType: String,
        paymentPlanType: String,
        planTypeDisplay: String,
        totalPayments: Int?,
        firstPaymentDate: Date,
        lastPaymentDate: Date,
        depositDate: Date?,
        totalAmount: Double,
        amountPaid: Double,
        amountRemaining: Double,
        depositAmount: Double,
        percentPaid: Double,
        actualPaymentCount: Int64,
        paymentsCompleted: Int64,
        paymentsRemaining: Int64,
        depositCount: Int64,
        allPaid: Bool,
        anyPaid: Bool,
        hasDeposit: Bool,
        hasRetainer: Bool,
        planStatus: PlanStatus,
        nextPaymentDate: Date?,
        nextPaymentAmount: Double?,
        daysUntilNextPayment: Int?,
        overdueCount: Int64,
        overdueAmount: Double,
        combinedNotes: String?,
        planCreatedAt: Date,
        planUpdatedAt: Date?
    ) {
        self.paymentPlanId = paymentPlanId
        self.expenseId = expenseId
        self.coupleId = coupleId
        self.vendor = vendor
        self.vendorId = vendorId
        self.vendorType = vendorType
        self.paymentType = paymentType
        self.paymentPlanType = paymentPlanType
        self.planTypeDisplay = planTypeDisplay
        self.totalPayments = totalPayments
        self.firstPaymentDate = firstPaymentDate
        self.lastPaymentDate = lastPaymentDate
        self.depositDate = depositDate
        self.totalAmount = totalAmount
        self.amountPaid = amountPaid
        self.amountRemaining = amountRemaining
        self.depositAmount = depositAmount
        self.percentPaid = percentPaid
        self.actualPaymentCount = actualPaymentCount
        self.paymentsCompleted = paymentsCompleted
        self.paymentsRemaining = paymentsRemaining
        self.depositCount = depositCount
        self.allPaid = allPaid
        self.anyPaid = anyPaid
        self.hasDeposit = hasDeposit
        self.hasRetainer = hasRetainer
        self.planStatus = planStatus
        self.nextPaymentDate = nextPaymentDate
        self.nextPaymentAmount = nextPaymentAmount
        self.daysUntilNextPayment = daysUntilNextPayment
        self.overdueCount = overdueCount
        self.overdueAmount = overdueAmount
        self.combinedNotes = combinedNotes
        self.planCreatedAt = planCreatedAt
        self.planUpdatedAt = planUpdatedAt
    }
    
    private enum CodingKeys: String, CodingKey {
        case paymentPlanId = "payment_plan_id"
        case expenseId = "expense_id"
        case coupleId = "couple_id"
        case vendor
        case vendorId = "vendor_id"
        case vendorType = "vendor_type"
        case paymentType = "payment_type"
        case paymentPlanType = "payment_plan_type"
        case planTypeDisplay = "plan_type_display"
        case totalPayments = "total_payments"
        case firstPaymentDate = "first_payment_date"
        case lastPaymentDate = "last_payment_date"
        case depositDate = "deposit_date"
        case totalAmount = "total_amount"
        case amountPaid = "amount_paid"
        case amountRemaining = "amount_remaining"
        case depositAmount = "deposit_amount"
        case percentPaid = "percent_paid"
        case actualPaymentCount = "actual_payment_count"
        case paymentsCompleted = "payments_completed"
        case paymentsRemaining = "payments_remaining"
        case depositCount = "deposit_count"
        case allPaid = "all_paid"
        case anyPaid = "any_paid"
        case hasDeposit = "has_deposit"
        case hasRetainer = "has_retainer"
        case planStatus = "plan_status"
        case nextPaymentDate = "next_payment_date"
        case nextPaymentAmount = "next_payment_amount"
        case daysUntilNextPayment = "days_until_next_payment"
        case overdueCount = "overdue_count"
        case overdueAmount = "overdue_amount"
        case combinedNotes = "combined_notes"
        case planCreatedAt = "plan_created_at"
        case planUpdatedAt = "plan_updated_at"
    }
    
    // MARK: - Custom Decoding
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode identifiers
        paymentPlanId = try container.decode(UUID.self, forKey: .paymentPlanId)
        expenseId = try container.decode(UUID.self, forKey: .expenseId)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)
        vendor = try container.decode(String.self, forKey: .vendor)
        vendorId = try container.decode(Int64.self, forKey: .vendorId)
        vendorType = try container.decodeIfPresent(String.self, forKey: .vendorType)
        
        // Decode plan type
        paymentType = try container.decode(String.self, forKey: .paymentType)
        paymentPlanType = try container.decode(String.self, forKey: .paymentPlanType)
        planTypeDisplay = try container.decode(String.self, forKey: .planTypeDisplay)
        
        // Decode plan metadata with flexible date parsing
        // totalPayments may be null in database, use decodeIfPresent
        totalPayments = try container.decodeIfPresent(Int.self, forKey: .totalPayments)
        firstPaymentDate = try Self.decodeFlexibleDate(from: container, forKey: .firstPaymentDate)
        lastPaymentDate = try Self.decodeFlexibleDate(from: container, forKey: .lastPaymentDate)
        depositDate = Self.decodeFlexibleDateIfPresent(from: container, forKey: .depositDate)
        
        // Decode financial aggregates (numeric type may come as string from PostgreSQL)
        totalAmount = try Self.decodeFlexibleDouble(from: container, forKey: .totalAmount)
        amountPaid = try Self.decodeFlexibleDouble(from: container, forKey: .amountPaid)
        amountRemaining = try Self.decodeFlexibleDouble(from: container, forKey: .amountRemaining)
        depositAmount = try Self.decodeFlexibleDouble(from: container, forKey: .depositAmount)
        percentPaid = try Self.decodeFlexibleDouble(from: container, forKey: .percentPaid)
        
        // Decode payment counts (bigint in database)
        actualPaymentCount = try container.decode(Int64.self, forKey: .actualPaymentCount)
        paymentsCompleted = try container.decode(Int64.self, forKey: .paymentsCompleted)
        paymentsRemaining = try container.decode(Int64.self, forKey: .paymentsRemaining)
        depositCount = try container.decode(Int64.self, forKey: .depositCount)
        
        // Decode status
        allPaid = try container.decode(Bool.self, forKey: .allPaid)
        anyPaid = try container.decode(Bool.self, forKey: .anyPaid)
        hasDeposit = try container.decode(Bool.self, forKey: .hasDeposit)
        hasRetainer = try container.decode(Bool.self, forKey: .hasRetainer)
        planStatus = try container.decode(PlanStatus.self, forKey: .planStatus)
        
        // Decode next payment with flexible date parsing
        nextPaymentDate = Self.decodeFlexibleDateIfPresent(from: container, forKey: .nextPaymentDate)
        nextPaymentAmount = Self.decodeFlexibleDoubleIfPresent(from: container, forKey: .nextPaymentAmount)
        daysUntilNextPayment = try container.decodeIfPresent(Int.self, forKey: .daysUntilNextPayment)
        
        // Decode overdue (bigint in database, numeric for amount)
        overdueCount = try container.decode(Int64.self, forKey: .overdueCount)
        overdueAmount = try Self.decodeFlexibleDouble(from: container, forKey: .overdueAmount)
        
        // Decode additional info with flexible date parsing
        combinedNotes = try container.decodeIfPresent(String.self, forKey: .combinedNotes)
        planCreatedAt = try Self.decodeFlexibleDate(from: container, forKey: .planCreatedAt)
        planUpdatedAt = Self.decodeFlexibleDateIfPresent(from: container, forKey: .planUpdatedAt)
    }
    
    /// Decode a date that may be in ISO8601 timestamp or date-only format (YYYY-MM-DD)
    private static func decodeFlexibleDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        // Try standard Date decoding first (handles ISO8601 timestamps)
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }
        
        // Fall back to string parsing for date-only format
        let dateString = try container.decode(String.self, forKey: key)
        return try Self.parseFlexibleDateString(dateString, key: key)
    }
    
    /// Decode an optional date that may be in ISO8601 timestamp or date-only format
    private static func decodeFlexibleDateIfPresent(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Date? {
        // Check if key exists and is not null
        guard container.contains(key) else {
            return nil
        }
        
        // Check if value is null
        if (try? container.decodeNil(forKey: key)) == true {
            return nil
        }
        
        // Try standard Date decoding first
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }
        
        // Fall back to string parsing for date-only format (YYYY-MM-DD)
        guard let dateString = try? container.decode(String.self, forKey: key) else {
            return nil
        }
        
        return try? Self.parseFlexibleDateString(dateString, key: key)
    }
    
    /// Parse a date string that may be in various formats
    private static func parseFlexibleDateString(_ dateString: String, key: CodingKeys) throws -> Date {
        // Try date-only format (YYYY-MM-DD)
        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let date = dateOnlyFormatter.date(from: dateString) {
            return date
        }
        
        // Try ISO8601 with fractional seconds
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // Try ISO8601 without fractional seconds
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        // If all parsing fails, throw error
        let context = DecodingError.Context(
            codingPath: [key],
            debugDescription: "Invalid date format: \(dateString)"
        )
        throw DecodingError.dataCorrupted(context)
    }
    
    /// Decode a Double that may come as a number or string (PostgreSQL numeric type)
    private static func decodeFlexibleDouble(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Double {
        // Try standard Double decoding first
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        
        // Fall back to string parsing for PostgreSQL numeric type
        let stringValue = try container.decode(String.self, forKey: key)
        guard let value = Double(stringValue) else {
            let context = DecodingError.Context(
                codingPath: [key],
                debugDescription: "Cannot convert '\(stringValue)' to Double"
            )
            throw DecodingError.dataCorrupted(context)
        }
        return value
    }
    
    /// Decode an optional Double that may come as a number or string
    private static func decodeFlexibleDoubleIfPresent(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Double? {
        // Check if key exists and is not null
        guard container.contains(key) else {
            return nil
        }
        
        // Check if value is null
        if (try? container.decodeNil(forKey: key)) == true {
            return nil
        }
        
        // Try standard Double decoding first
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        
        // Fall back to string parsing
        guard let stringValue = try? container.decode(String.self, forKey: key),
              let value = Double(stringValue) else {
            return nil
        }
        return value
    }
    
    // MARK: - Encoding
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(paymentPlanId, forKey: .paymentPlanId)
        try container.encode(expenseId, forKey: .expenseId)
        try container.encode(coupleId, forKey: .coupleId)
        try container.encode(vendor, forKey: .vendor)
        try container.encode(vendorId, forKey: .vendorId)
        try container.encodeIfPresent(vendorType, forKey: .vendorType)
        try container.encode(paymentType, forKey: .paymentType)
        try container.encode(paymentPlanType, forKey: .paymentPlanType)
        try container.encode(planTypeDisplay, forKey: .planTypeDisplay)
        try container.encodeIfPresent(totalPayments, forKey: .totalPayments)
        try container.encode(firstPaymentDate, forKey: .firstPaymentDate)
        try container.encode(lastPaymentDate, forKey: .lastPaymentDate)
        try container.encodeIfPresent(depositDate, forKey: .depositDate)
        try container.encode(totalAmount, forKey: .totalAmount)
        try container.encode(amountPaid, forKey: .amountPaid)
        try container.encode(amountRemaining, forKey: .amountRemaining)
        try container.encode(depositAmount, forKey: .depositAmount)
        try container.encode(percentPaid, forKey: .percentPaid)
        try container.encode(actualPaymentCount, forKey: .actualPaymentCount)
        try container.encode(paymentsCompleted, forKey: .paymentsCompleted)
        try container.encode(paymentsRemaining, forKey: .paymentsRemaining)
        try container.encode(depositCount, forKey: .depositCount)
        try container.encode(allPaid, forKey: .allPaid)
        try container.encode(anyPaid, forKey: .anyPaid)
        try container.encode(hasDeposit, forKey: .hasDeposit)
        try container.encode(hasRetainer, forKey: .hasRetainer)
        try container.encode(planStatus, forKey: .planStatus)
        try container.encodeIfPresent(nextPaymentDate, forKey: .nextPaymentDate)
        try container.encodeIfPresent(nextPaymentAmount, forKey: .nextPaymentAmount)
        try container.encodeIfPresent(daysUntilNextPayment, forKey: .daysUntilNextPayment)
        try container.encode(overdueCount, forKey: .overdueCount)
        try container.encode(overdueAmount, forKey: .overdueAmount)
        try container.encodeIfPresent(combinedNotes, forKey: .combinedNotes)
        try container.encode(planCreatedAt, forKey: .planCreatedAt)
        try container.encodeIfPresent(planUpdatedAt, forKey: .planUpdatedAt)
    }
    
    enum PlanStatus: String, Codable {
        case completed
        case overdue
        case inProgress = "in_progress"
        case pending
        
        var displayName: String {
            switch self {
            case .completed: return "Completed"
            case .overdue: return "Overdue"
            case .inProgress: return "In Progress"
            case .pending: return "Pending"
            }
        }
        
        var color: Color {
            switch self {
            case .completed: return .green
            case .overdue: return .red
            case .inProgress: return .orange
            case .pending: return .gray
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Effective total payments count (uses totalPayments if set, otherwise actualPaymentCount)
    var effectiveTotalPayments: Int {
        totalPayments ?? Int(actualPaymentCount)
    }
    
    var progressText: String {
        "\(paymentsCompleted)/\(effectiveTotalPayments) payments"
    }
    
    /// Convenience property for Int conversion of overdueCount
    var overdueCountInt: Int {
        Int(overdueCount)
    }
    
    var isOverdue: Bool {
        overdueCount > 0
    }
    
    var statusIcon: String {
        switch planStatus {
        case .completed: return "checkmark.circle.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .inProgress: return "clock.fill"
        case .pending: return "circle"
        }
    }
    
    var formattedTotalAmount: String {
        NumberFormatter.currency.string(from: NSNumber(value: totalAmount)) ?? "$0"
    }
    
    var formattedAmountPaid: String {
        NumberFormatter.currency.string(from: NSNumber(value: amountPaid)) ?? "$0"
    }
    
    var formattedAmountRemaining: String {
        NumberFormatter.currency.string(from: NSNumber(value: amountRemaining)) ?? "$0"
    }
    
    var formattedNextPaymentAmount: String? {
        guard let amount = nextPaymentAmount else { return nil }
        return NumberFormatter.currency.string(from: NSNumber(value: amount))
    }
}

// MARK: - Test Data
extension PaymentPlanSummary {
    static func makeTest(
        paymentPlanId: UUID = UUID(),
        expenseId: UUID = UUID(),
        coupleId: UUID = UUID(),
        vendor: String = "Test Vendor",
        vendorId: Int64 = 1,
        vendorType: String? = "Photography",
        paymentType: String = "interval",
        paymentPlanType: String = "interval-recurring",
        planTypeDisplay: String = "Custom Interval",
        totalPayments: Int = 4,
        firstPaymentDate: Date = Date(),
        lastPaymentDate: Date = Date().addingTimeInterval(86400 * 180),
        depositDate: Date? = Date(),
        totalAmount: Double = 6300.0,
        amountPaid: Double = 4700.0,
        amountRemaining: Double = 1600.0,
        depositAmount: Double = 1500.0,
        percentPaid: Double = 74.60,
        actualPaymentCount: Int64 = 4,
        paymentsCompleted: Int64 = 3,
        paymentsRemaining: Int64 = 1,
        depositCount: Int64 = 1,
        allPaid: Bool = false,
        anyPaid: Bool = true,
        hasDeposit: Bool = true,
        hasRetainer: Bool = false,
        planStatus: PlanStatus = .inProgress,
        nextPaymentDate: Date? = Date().addingTimeInterval(86400 * 30),
        nextPaymentAmount: Double? = 1600.0,
        daysUntilNextPayment: Int? = 30,
        overdueCount: Int64 = 0,
        overdueAmount: Double = 0.0,
        combinedNotes: String? = nil,
        planCreatedAt: Date = Date(),
        planUpdatedAt: Date? = nil
    ) -> PaymentPlanSummary {
        PaymentPlanSummary(
            paymentPlanId: paymentPlanId,
            expenseId: expenseId,
            coupleId: coupleId,
            vendor: vendor,
            vendorId: vendorId,
            vendorType: vendorType,
            paymentType: paymentType,
            paymentPlanType: paymentPlanType,
            planTypeDisplay: planTypeDisplay,
            totalPayments: totalPayments,
            firstPaymentDate: firstPaymentDate,
            lastPaymentDate: lastPaymentDate,
            depositDate: depositDate,
            totalAmount: totalAmount,
            amountPaid: amountPaid,
            amountRemaining: amountRemaining,
            depositAmount: depositAmount,
            percentPaid: percentPaid,
            actualPaymentCount: actualPaymentCount,
            paymentsCompleted: paymentsCompleted,
            paymentsRemaining: paymentsRemaining,
            depositCount: depositCount,
            allPaid: allPaid,
            anyPaid: anyPaid,
            hasDeposit: hasDeposit,
            hasRetainer: hasRetainer,
            planStatus: planStatus,
            nextPaymentDate: nextPaymentDate,
            nextPaymentAmount: nextPaymentAmount,
            daysUntilNextPayment: daysUntilNextPayment,
            overdueCount: overdueCount,
            overdueAmount: overdueAmount,
            combinedNotes: combinedNotes,
            planCreatedAt: planCreatedAt,
            planUpdatedAt: planUpdatedAt
        )
    }
}
