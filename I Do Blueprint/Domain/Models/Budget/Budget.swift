import Foundation
import SwiftUI

// MARK: - Budget Data Models

// MARK: - Gifts and Owed Items Model

struct GiftOrOwed: Identifiable, Codable {
    let id: UUID
    let coupleId: UUID
    var title: String
    var amount: Double
    var type: GiftOrOwedType
    var description: String?
    var fromPerson: String?
    var expectedDate: Date?
    var receivedDate: Date?
    var status: GiftOrOwedStatus
    var scenarioId: UUID?
    var createdAt: Date
    var updatedAt: Date?

    enum GiftOrOwedType: String, CaseIterable, Codable {
        case giftReceived = "gift_received"
        case moneyOwed = "money_owed"
        case contribution

        var displayName: String {
            switch self {
            case .giftReceived: "Gift Received"
            case .moneyOwed: "Money Owed"
            case .contribution: "Contribution"
            }
        }

        var iconName: String {
            switch self {
            case .giftReceived: "gift"
            case .moneyOwed: "hand.heart"
            case .contribution: "dollarsign"
            }
        }
    }

    enum GiftOrOwedStatus: String, CaseIterable, Codable {
        case pending
        case received
        case confirmed

        var displayName: String {
            switch self {
            case .pending: "Pending"
            case .received: "Received"
            case .confirmed: "Confirmed"
            }
        }

        var color: Color {
            switch self {
            case .pending: .orange
            case .received: .green
            case .confirmed: .blue
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case title
        case amount
        case type
        case description
        case fromPerson = "from_person"
        case expectedDate = "expected_date"
        case receivedDate = "received_date"
        case status
        case scenarioId = "scenario_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct BudgetSummary: Identifiable, Codable {
    let id: UUID
    let coupleId: UUID
    var totalBudget: Double
    var baseBudget: Double
    var currency: String
    var weddingDate: Date?
    var notes: String?
    var includesEngagementRings: Bool
    var engagementRingAmount: Double
    var createdAt: Date
    var updatedAt: Date?

    // Computed properties
    var totalSpent: Double {
        // This would be calculated from expenses
        0.0 // Placeholder - will be calculated in BudgetStore
    }

    var totalAllocated: Double {
        // This would be calculated from budget_categories
        0.0 // Placeholder - will be calculated in BudgetStore
    }

    var remainingBudget: Double {
        totalBudget - totalSpent
    }

    var percentageSpent: Double {
        guard totalBudget > 0 else { return 0 }
        return (totalSpent / totalBudget) * 100
    }

    var percentageAllocated: Double {
        guard totalBudget > 0 else { return 0 }
        return (totalAllocated / totalBudget) * 100
    }

    var isOverBudget: Bool {
        totalSpent > totalBudget
    }

    // Explicit memberwise initializer
    init(
        id: UUID,
        coupleId: UUID,
        totalBudget: Double,
        baseBudget: Double,
        currency: String,
        weddingDate: Date? = nil,
        notes: String? = nil,
        includesEngagementRings: Bool,
        engagementRingAmount: Double,
        createdAt: Date,
        updatedAt: Date? = nil) {
        self.id = id
        self.coupleId = coupleId
        self.totalBudget = totalBudget
        self.baseBudget = baseBudget
        self.currency = currency
        self.weddingDate = weddingDate
        self.notes = notes
        self.includesEngagementRings = includesEngagementRings
        self.engagementRingAmount = engagementRingAmount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoding to handle different date formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)
        totalBudget = try container.decode(Double.self, forKey: .totalBudget)
        baseBudget = try container.decode(Double.self, forKey: .baseBudget)
        currency = try container.decode(String.self, forKey: .currency)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        includesEngagementRings = try container.decode(Bool.self, forKey: .includesEngagementRings)
        engagementRingAmount = try container.decode(Double.self, forKey: .engagementRingAmount)

        // Custom date decoding
        weddingDate = try Self.decodeDateIfPresent(from: container, forKey: .weddingDate)
        createdAt = try Self.decodeDate(from: container, forKey: .createdAt)
        updatedAt = try Self.decodeDateIfPresent(from: container, forKey: .updatedAt)
    }

    // Helper methods for date decoding
    private static func decodeDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys) throws -> Date {
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }

        let dateString = try container.decode(String.self, forKey: key)
        return try parseDate(from: dateString)
    }

    private static func decodeDateIfPresent(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys) throws -> Date? {
        if let date = try? container.decodeIfPresent(Date.self, forKey: key) {
            return date
        }

        guard let dateString = try container.decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        return try parseDate(from: dateString)
    }

    private static func parseDate(from dateString: String) throws -> Date {
        // Try different date formats
        let formatters = [
            ISO8601DateFormatter(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }()
        ]

        for formatter in formatters {
            if let iso8601Formatter = formatter as? ISO8601DateFormatter {
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
            } else if let dateFormatter = formatter as? DateFormatter {
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Unable to parse date: \(dateString)"))
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case totalBudget = "total_budget"
        case baseBudget = "base_budget"
        case currency
        case weddingDate = "wedding_date"
        case notes
        case includesEngagementRings = "includes_engagement_rings"
        case engagementRingAmount = "engagement_ring_amount"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct BudgetCategory: Identifiable, Codable, Hashable {
    let id: UUID
    let coupleId: UUID
    var categoryName: String
    var parentCategoryId: UUID?
    var allocatedAmount: Double
    var spentAmount: Double
    var typicalPercentage: Double?
    var priorityLevel: Int
    var isEssential: Bool
    var notes: String?
    var forecastedAmount: Double
    var confidenceLevel: Double
    var lockedAllocation: Bool
    var description: String?
    var createdAt: Date
    var updatedAt: Date?

    // Computed properties for backward compatibility
    var priority: BudgetPriority {
        switch priorityLevel {
        case 1: .high
        case 2: .medium
        default: .low
        }
    }

    var color: String {
        // Generate a color based on category name hash for consistency
        let colors = [
            "#3B82F6",
            "#10B981",
            "#8B5CF6",
            "#F59E0B",
            "#EF4444",
            "#06B6D4",
            "#84CC16",
            "#F97316",
            "#EC4899",
            "#6366F1"
        ]
        let index = abs(categoryName.hashValue) % colors.count
        return colors[index]
    }

    var remainingAmount: Double {
        allocatedAmount - spentAmount
    }

    var percentageSpent: Double {
        guard allocatedAmount > 0 else { return 0 }
        return (spentAmount / allocatedAmount) * 100
    }

    var isOverBudget: Bool {
        spentAmount > allocatedAmount
    }

    // Explicit memberwise initializer
    init(
        id: UUID,
        coupleId: UUID,
        categoryName: String,
        parentCategoryId: UUID? = nil,
        allocatedAmount: Double,
        spentAmount: Double,
        typicalPercentage: Double? = nil,
        priorityLevel: Int,
        isEssential: Bool,
        notes: String? = nil,
        forecastedAmount: Double,
        confidenceLevel: Double,
        lockedAllocation: Bool,
        description: String? = nil,
        createdAt: Date,
        updatedAt: Date? = nil) {
        self.id = id
        self.coupleId = coupleId
        self.categoryName = categoryName
        self.parentCategoryId = parentCategoryId
        self.allocatedAmount = allocatedAmount
        self.spentAmount = spentAmount
        self.typicalPercentage = typicalPercentage
        self.priorityLevel = priorityLevel
        self.isEssential = isEssential
        self.notes = notes
        self.forecastedAmount = forecastedAmount
        self.confidenceLevel = confidenceLevel
        self.lockedAllocation = lockedAllocation
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoding to handle different date formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)
        categoryName = try container.decode(String.self, forKey: .categoryName)
        parentCategoryId = try container.decodeIfPresent(UUID.self, forKey: .parentCategoryId)
        allocatedAmount = try container.decode(Double.self, forKey: .allocatedAmount)
        spentAmount = try container.decode(Double.self, forKey: .spentAmount)
        typicalPercentage = try container.decodeIfPresent(Double.self, forKey: .typicalPercentage)
        priorityLevel = try container.decode(Int.self, forKey: .priorityLevel)
        isEssential = try container.decode(Bool.self, forKey: .isEssential)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        forecastedAmount = try container.decode(Double.self, forKey: .forecastedAmount)
        confidenceLevel = try container.decode(Double.self, forKey: .confidenceLevel)
        lockedAllocation = try container.decode(Bool.self, forKey: .lockedAllocation)
        description = try container.decodeIfPresent(String.self, forKey: .description)

        // Custom date decoding
        createdAt = try Self.decodeDate(from: container, forKey: .createdAt)
        updatedAt = try Self.decodeDateIfPresent(from: container, forKey: .updatedAt)
    }

    // Helper methods for date decoding
    private static func decodeDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys) throws -> Date {
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }

        let dateString = try container.decode(String.self, forKey: key)
        return try parseDate(from: dateString)
    }

    private static func decodeDateIfPresent(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys) throws -> Date? {
        if let date = try? container.decodeIfPresent(Date.self, forKey: key) {
            return date
        }

        guard let dateString = try container.decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        return try parseDate(from: dateString)
    }

    private static func parseDate(from dateString: String) throws -> Date {
        // Try different date formats
        let formatters = [
            ISO8601DateFormatter(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }()
        ]

        for formatter in formatters {
            if let iso8601Formatter = formatter as? ISO8601DateFormatter {
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
            } else if let dateFormatter = formatter as? DateFormatter {
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Unable to parse date: \(dateString)"))
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case categoryName = "category_name"
        case parentCategoryId = "parent_category_id"
        case allocatedAmount = "allocated_amount"
        case spentAmount = "spent_amount"
        case typicalPercentage = "typical_percentage"
        case priorityLevel = "priority_level"
        case isEssential = "is_essential"
        case notes
        case forecastedAmount = "forecasted_amount"
        case confidenceLevel = "confidence_level"
        case lockedAllocation = "locked_allocation"
        case description
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Expense: Identifiable, Codable {
    let id: UUID
    let coupleId: UUID
    var budgetCategoryId: UUID
    var vendorId: Int64?
    var vendorName: String?
    var expenseName: String
    var amount: Double
    var expenseDate: Date
    var paymentMethod: String?
    var paymentStatus: PaymentStatus
    var receiptUrl: String?
    var invoiceNumber: String?
    var notes: String?
    var approvalStatus: String?
    var approvedBy: String?
    var approvedAt: Date?
    var invoiceDocumentUrl: String?
    var isTestData: Bool
    var createdAt: Date
    var updatedAt: Date?

    // Computed properties for backward compatibility
    var categoryId: UUID {
        budgetCategoryId
    }

    var paidAmount: Double {
        // For simplicity, if payment_status is "paid", assume full amount is paid
        paymentStatus == .paid ? amount : 0.0
    }

    var remainingAmount: Double {
        amount - paidAmount
    }

    var dueDate: Date? {
        // Use expense_date as due date for now
        expenseDate
    }

    var paidDate: Date? {
        // Use approved_at as paid date if approved
        approvedAt
    }

    var isOverdue: Bool {
        let today = Date()
        return expenseDate < today && paymentStatus != .paid
    }

    var isDueToday: Bool {
        Calendar.current.isDateInToday(expenseDate)
    }

    var isDueSoon: Bool {
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: expenseDate).day ?? 0
        return daysUntilDue <= 7 && daysUntilDue >= 0
    }

    // Legacy computed property for backwards compatibility
    @available(*, deprecated, message: "Use paymentStatus directly instead")
    var paymentStatusEnum: PaymentStatus {
        paymentStatus
    }

    // Explicit memberwise initializer
    init(
        id: UUID,
        coupleId: UUID,
        budgetCategoryId: UUID,
        vendorId: Int64? = nil,
        vendorName: String? = nil,
        expenseName: String,
        amount: Double,
        expenseDate: Date,
        paymentMethod: String? = nil,
        paymentStatus: PaymentStatus,
        receiptUrl: String? = nil,
        invoiceNumber: String? = nil,
        notes: String? = nil,
        approvalStatus: String? = nil,
        approvedBy: String? = nil,
        approvedAt: Date? = nil,
        invoiceDocumentUrl: String? = nil,
        isTestData: Bool,
        createdAt: Date,
        updatedAt: Date? = nil) {
        self.id = id
        self.coupleId = coupleId
        self.budgetCategoryId = budgetCategoryId
        self.vendorId = vendorId
        self.vendorName = vendorName
        self.expenseName = expenseName
        self.amount = amount
        self.expenseDate = expenseDate
        self.paymentMethod = paymentMethod
        self.paymentStatus = paymentStatus
        self.receiptUrl = receiptUrl
        self.invoiceNumber = invoiceNumber
        self.notes = notes
        self.approvalStatus = approvalStatus
        self.approvedBy = approvedBy
        self.approvedAt = approvedAt
        self.invoiceDocumentUrl = invoiceDocumentUrl
        self.isTestData = isTestData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoding to handle different date formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)
        budgetCategoryId = try container.decode(UUID.self, forKey: .budgetCategoryId)
        vendorId = try container.decodeIfPresent(Int64.self, forKey: .vendorId)
        vendorName = try container.decodeIfPresent(String.self, forKey: .vendorName)
        expenseName = try container.decode(String.self, forKey: .expenseName)
        amount = try container.decode(Double.self, forKey: .amount)
        paymentMethod = try container.decodeIfPresent(String.self, forKey: .paymentMethod)
        paymentStatus = try container.decode(PaymentStatus.self, forKey: .paymentStatus)
        receiptUrl = try container.decodeIfPresent(String.self, forKey: .receiptUrl)
        invoiceNumber = try container.decodeIfPresent(String.self, forKey: .invoiceNumber)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        approvalStatus = try container.decodeIfPresent(String.self, forKey: .approvalStatus)
        approvedBy = try container.decodeIfPresent(String.self, forKey: .approvedBy)
        invoiceDocumentUrl = try container.decodeIfPresent(String.self, forKey: .invoiceDocumentUrl)
        isTestData = try container.decode(Bool.self, forKey: .isTestData)

        // Custom date decoding
        expenseDate = try Self.decodeDate(from: container, forKey: .expenseDate)
        approvedAt = try Self.decodeDateIfPresent(from: container, forKey: .approvedAt)
        createdAt = try Self.decodeDate(from: container, forKey: .createdAt)
        updatedAt = try Self.decodeDateIfPresent(from: container, forKey: .updatedAt)
    }

    // Helper methods for date decoding
    private static func decodeDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys) throws -> Date {
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }

        let dateString = try container.decode(String.self, forKey: key)
        return try parseDate(from: dateString)
    }

    private static func decodeDateIfPresent(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys) throws -> Date? {
        if let date = try? container.decodeIfPresent(Date.self, forKey: key) {
            return date
        }

        guard let dateString = try container.decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        return try parseDate(from: dateString)
    }

    private static func parseDate(from dateString: String) throws -> Date {
        // Try different date formats
        let formatters = [
            ISO8601DateFormatter(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }()
        ]

        for formatter in formatters {
            if let iso8601Formatter = formatter as? ISO8601DateFormatter {
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
            } else if let dateFormatter = formatter as? DateFormatter {
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Unable to parse date: \(dateString)"))
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case budgetCategoryId = "budget_category_id"
        case vendorId = "vendor_id"
        case vendorName = "vendor_name"
        case expenseName = "expense_name"
        case amount
        case expenseDate = "expense_date"
        case paymentMethod = "payment_method"
        case paymentStatus = "payment_status"
        case receiptUrl = "receipt_url"
        case invoiceNumber = "invoice_number"
        case notes
        case approvalStatus = "approval_status"
        case approvedBy = "approved_by"
        case approvedAt = "approved_at"
        case invoiceDocumentUrl = "invoice_document_url"
        case isTestData = "is_test_data"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

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
    var createdAt: Date
    var updatedAt: Date?

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
        createdAt: Date,
        updatedAt: Date? = nil) {
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoding to handle different date formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int64.self, forKey: .id)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)
        vendor = try container.decode(String.self, forKey: .vendor)
        paymentAmount = try container.decode(Double.self, forKey: .paymentAmount)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        vendorType = try container.decodeIfPresent(String.self, forKey: .vendorType)
        paid = try container.decode(Bool.self, forKey: .paid)
        paymentType = try container.decodeIfPresent(String.self, forKey: .paymentType)
        customAmount = try container.decodeIfPresent(Double.self, forKey: .customAmount)
        billingFrequency = try container.decodeIfPresent(String.self, forKey: .billingFrequency)
        autoRenew = try container.decode(Bool.self, forKey: .autoRenew)
        reminderEnabled = try container.decode(Bool.self, forKey: .reminderEnabled)
        reminderDaysBefore = try container.decodeIfPresent(Int.self, forKey: .reminderDaysBefore)
        priorityLevel = try container.decodeIfPresent(String.self, forKey: .priorityLevel)
        expenseId = try container.decodeIfPresent(UUID.self, forKey: .expenseId)
        vendorId = try container.decodeIfPresent(Int64.self, forKey: .vendorId)
        isDeposit = try container.decode(Bool.self, forKey: .isDeposit)
        isRetainer = try container.decode(Bool.self, forKey: .isRetainer)
        paymentOrder = try container.decodeIfPresent(Int.self, forKey: .paymentOrder)
        totalPaymentCount = try container.decodeIfPresent(Int.self, forKey: .totalPaymentCount)
        paymentPlanType = try container.decodeIfPresent(String.self, forKey: .paymentPlanType)

        // Custom date decoding
        paymentDate = try Self.decodeDate(from: container, forKey: .paymentDate)
        startDate = try Self.decodeDateIfPresent(from: container, forKey: .startDate)
        createdAt = try Self.decodeDate(from: container, forKey: .createdAt)
        updatedAt = try Self.decodeDateIfPresent(from: container, forKey: .updatedAt)
    }

    // Helper methods for date decoding (reuse same logic as Expense)
    private static func decodeDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys) throws -> Date {
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }

        let dateString = try container.decode(String.self, forKey: key)
        return try parseDate(from: dateString)
    }

    private static func decodeDateIfPresent(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys) throws -> Date? {
        if let date = try? container.decodeIfPresent(Date.self, forKey: key) {
            return date
        }

        guard let dateString = try container.decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        return try parseDate(from: dateString)
    }

    private static func parseDate(from dateString: String) throws -> Date {
        // Try different date formats
        let formatters = [
            ISO8601DateFormatter(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }()
        ]

        for formatter in formatters {
            if let iso8601Formatter = formatter as? ISO8601DateFormatter {
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
            } else if let dateFormatter = formatter as? DateFormatter {
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Unable to parse date: \(dateString)"))
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case vendor
        case paymentDate = "payment_date"
        case paymentAmount = "payment_amount"
        case notes
        case vendorType = "vendor_type"
        case paid
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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CategoryBenchmark: Identifiable, Codable {
    let id: UUID
    let categoryName: String
    var typicalPercentage: Double
    var minPercentage: Double
    var maxPercentage: Double
    var description: String?
    var region: String?
    var lastUpdated: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case categoryName = "category_name"
        case typicalPercentage = "typical_percentage"
        case minPercentage = "min_percentage"
        case maxPercentage = "max_percentage"
        case description
        case region
        case lastUpdated = "last_updated"
    }
}

// MARK: - Enums

enum BudgetPriority: String, Codable, CaseIterable {
    case high
    case medium
    case low

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

enum PaymentStatus: String, Codable, CaseIterable {
    case pending
    case partial
    case paid
    case overdue
    case cancelled
    case refunded

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

enum PaymentMethod: String, Codable, CaseIterable {
    case cash
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    case bankTransfer = "bank_transfer"
    case check
    case venmo
    case zelle
    case paypal
    case other

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

enum RecurringFrequency: String, Codable, CaseIterable {
    case weekly
    case monthly
    case quarterly
    case yearly

    var displayName: String {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .quarterly: "Quarterly"
        case .yearly: "Yearly"
        }
    }
}

// MARK: - Filter and Sort Options

enum BudgetSortOption: String, CaseIterable {
    case category
    case amount
    case spent
    case remaining
    case priority
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

enum BudgetFilterOption: String, CaseIterable {
    case all
    case overBudget = "over_budget"
    case onTrack = "on_track"
    case underBudget = "under_budget"
    case highPriority = "high_priority"
    case essential

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

enum ExpenseFilterOption: String, CaseIterable {
    case all
    case pending
    case partial
    case paid
    case overdue
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

// MARK: - Statistics and Analytics

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

struct CategorySpending {
    let categoryId: UUID
    let categoryName: String
    let allocatedAmount: Double
    let spentAmount: Double
    let remainingAmount: Double
    let percentageSpent: Double
    let expenseCount: Int
    let lastExpenseDate: Date?
    let isOverBudget: Bool
    let priority: BudgetPriority
    let color: String
}

// MARK: - View Models Support

struct BudgetTrend {
    let direction: TrendDirection
    let percentage: Double
    let label: String
}


// Enhanced category with projected spending calculations
struct EnhancedBudgetCategory {
    let category: BudgetCategory
    let projectedSpending: Double // All expenses (including pending)
    let actualSpending: Double // Only paid expenses

    // Computed properties for UI display
    var projectedPercentageSpent: Double {
        guard category.allocatedAmount > 0 else { return 0 }
        return (projectedSpending / category.allocatedAmount) * 100
    }

    var actualPercentageSpent: Double {
        guard category.allocatedAmount > 0 else { return 0 }
        return (actualSpending / category.allocatedAmount) * 100
    }

    var projectedRemainingAmount: Double {
        category.allocatedAmount - projectedSpending
    }

    var actualRemainingAmount: Double {
        category.allocatedAmount - actualSpending
    }

    var isProjectedOverBudget: Bool {
        projectedSpending > category.allocatedAmount
    }

    var isActualOverBudget: Bool {
        actualSpending > category.allocatedAmount
    }

    var pendingAmount: Double {
        projectedSpending - actualSpending
    }

    var isOverBudget: Bool {
        projectedSpending > category.allocatedAmount
    }
}

// MARK: - Budget Development Models

struct BudgetItem: Identifiable, Codable {
    let id: String
    var scenarioId: String?
    var itemName: String
    var category: String
    var subcategory: String?
    var vendorEstimateWithoutTax: Double
    var taxRate: Double
    var vendorEstimateWithTax: Double
    var personResponsible: String?
    var notes: String?
    var createdAt: Date?
    var updatedAt: Date?
    var eventId: String?
    var eventIds: [String]?
    var linkedExpenseId: String?
    var linkedGiftOwedId: String?
    var coupleId: String
    var isTestData: Bool?

    // Computed properties for compatibility
    var eventNames: [String] {
        // This would need to be populated from actual event data
        []
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case scenarioId = "scenario_id"
        case itemName = "item_name"
        case category
        case subcategory
        case vendorEstimateWithoutTax = "vendor_estimate_without_tax"
        case taxRate = "tax_rate"
        case vendorEstimateWithTax = "vendor_estimate_with_tax"
        case personResponsible = "person_responsible"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case eventId = "event_id"
        case eventIds = "event_ids"
        case linkedExpenseId = "linked_expense_id"
        case linkedGiftOwedId = "linked_gift_owed_id"
        case coupleId = "couple_id"
        case isTestData = "is_test_data"
    }
}

struct SavedScenario: Identifiable, Codable {
    let id: String
    var scenarioName: String
    var createdAt: Date
    var updatedAt: Date
    var totalWithoutTax: Double?
    var totalTax: Double?
    var totalWithTax: Double?
    var isPrimary: Bool
    var coupleId: String
    var isTestData: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case scenarioName = "scenario_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case totalWithoutTax = "total_without_tax"
        case totalTax = "total_tax"
        case totalWithTax = "total_with_tax"
        case isPrimary = "is_primary"
        case coupleId = "couple_id"
        case isTestData = "is_test_data"
    }
}

// MARK: - Tax Information Model

struct TaxInfo: Identifiable, Codable {
    let id: Int64
    let createdAt: Date?
    var region: String
    var taxRate: Double

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case region
        case taxRate = "tax_rate"
    }

    init(id: Int64 = 0, createdAt: Date? = nil, region: String, taxRate: Double) {
        self.id = id
        self.createdAt = createdAt
        self.region = region
        self.taxRate = taxRate
    }
}

// MARK: - Expense Allocation Model

struct ExpenseAllocation: Identifiable, Codable {
    let id: String
    let expenseId: String
    let budgetItemId: String
    let allocatedAmount: Double
    let percentage: Double?
    let notes: String?
    let createdAt: Date?
    let updatedAt: Date?
    let coupleId: String
    let scenarioId: String
    let isTestData: Bool?

    private enum CodingKeys: String, CodingKey {
        case id
        case expenseId = "expense_id"
        case budgetItemId = "budget_item_id"
        case allocatedAmount = "allocated_amount"
        case percentage
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case coupleId = "couple_id"
        case scenarioId = "scenario_id"
        case isTestData = "is_test_data"
    }
}

// MARK: - Gift Data Models

struct Gift: Identifiable, Codable {
    let id: UUID
    let coupleId: UUID
    var title: String
    var amount: Double
    var type: String // "gift_received", "money_owed", "contribution"
    var description: String?
    var fromPerson: String?
    var expectedDate: Date?
    var receivedDate: Date?
    var status: String // "pending", "received", "confirmed"
    var createdAt: Date
    var updatedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case title
        case amount
        case type
        case description
        case fromPerson = "from_person"
        case expectedDate = "expected_date"
        case receivedDate = "received_date"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Affordability Calculator Models

struct AffordabilityScenario: Identifiable, Codable {
    let id: UUID
    var scenarioName: String
    var partner1Monthly: Double
    var partner2Monthly: Double
    var calculationStartDate: Date?
    var isPrimary: Bool
    let coupleId: UUID
    var createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case scenarioName = "scenario_name"
        case partner1Monthly = "partner1_monthly"
        case partner2Monthly = "partner2_monthly"
        case calculationStartDate = "calculation_start_date"
        case isPrimary = "is_primary"
        case coupleId = "couple_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        scenarioName = try container.decode(String.self, forKey: .scenarioName)
        isPrimary = try container.decode(Bool.self, forKey: .isPrimary)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)

        // Handle dates
        createdAt = try Self.decodeDate(from: container, forKey: .createdAt)
        updatedAt = try Self.decodeDateIfPresent(from: container, forKey: .updatedAt)
        calculationStartDate = try Self.decodeDateIfPresent(from: container, forKey: .calculationStartDate)

        // Handle numeric fields that might come as strings from Supabase
        if let p1String = try? container.decode(String.self, forKey: .partner1Monthly) {
            partner1Monthly = Double(p1String) ?? 0
        } else {
            partner1Monthly = try container.decode(Double.self, forKey: .partner1Monthly)
        }

        if let p2String = try? container.decode(String.self, forKey: .partner2Monthly) {
            partner2Monthly = Double(p2String) ?? 0
        } else {
            partner2Monthly = try container.decode(Double.self, forKey: .partner2Monthly)
        }
    }

    // Helper methods for date decoding
    private static func decodeDate(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys) throws -> Date {
        if let date = try? container.decode(Date.self, forKey: key) {
            return date
        }

        let dateString = try container.decode(String.self, forKey: key)
        return try parseDate(from: dateString)
    }

    private static func decodeDateIfPresent(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys) throws -> Date? {
        if let date = try? container.decodeIfPresent(Date.self, forKey: key) {
            return date
        }

        guard let dateString = try container.decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        return try parseDate(from: dateString)
    }

    private static func parseDate(from dateString: String) throws -> Date {
        // Try different date formats
        let formatters = [
            ISO8601DateFormatter(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }()
        ]

        for formatter in formatters {
            if let iso8601Formatter = formatter as? ISO8601DateFormatter {
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
            } else if let dateFormatter = formatter as? DateFormatter {
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Invalid date format: \(dateString)"))
    }

    init(
        id: UUID = UUID(),
        scenarioName: String,
        partner1Monthly: Double,
        partner2Monthly: Double,
        calculationStartDate: Date? = nil,
        isPrimary: Bool = false,
        coupleId: UUID,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.scenarioName = scenarioName
        self.partner1Monthly = partner1Monthly
        self.partner2Monthly = partner2Monthly
        self.calculationStartDate = calculationStartDate
        self.isPrimary = isPrimary
        self.coupleId = coupleId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct ContributionItem: Identifiable, Codable {
    let id: UUID
    let scenarioId: UUID
    var contributorName: String
    var amount: Double
    var contributionDate: Date
    var contributionType: ContributionType
    var notes: String?
    let coupleId: UUID
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case scenarioId = "scenario_id"
        case contributorName = "contributor_name"
        case amount
        case contributionDate = "contribution_date"
        case contributionType = "contribution_type"
        case notes
        case coupleId = "couple_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        scenarioId = try container.decode(UUID.self, forKey: .scenarioId)
        contributorName = try container.decode(String.self, forKey: .contributorName)
        contributionType = try container.decode(ContributionType.self, forKey: .contributionType)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)

        // Handle amount - might be string or double from Supabase
        if let amountString = try? container.decode(String.self, forKey: .amount) {
            amount = Double(amountString) ?? 0
        } else {
            amount = try container.decode(Double.self, forKey: .amount)
        }

        // Handle dates with custom parsing
        contributionDate = try Self.decodeDate(from: container, forKey: .contributionDate)
        createdAt = try Self.decodeDateIfPresent(from: container, forKey: .createdAt)
        updatedAt = try Self.decodeDateIfPresent(from: container, forKey: .updatedAt)
    }

    private static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        let dateString = try container.decode(String.self, forKey: key)
        return try parseDate(from: dateString)
    }

    private static func decodeDateIfPresent(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date? {
        guard let dateString = try container.decodeIfPresent(String.self, forKey: key) else {
            return nil
        }
        return try parseDate(from: dateString)
    }

    private static func parseDate(from dateString: String) throws -> Date {
        // Try ISO8601 format first (handles timezone)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) {
            return date
        }

        // Try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            return date
        }

        // Try DateFormatter formats
        let formats = [
            "yyyy-MM-dd",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSSxxxxx"  // With timezone
        ]

        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Invalid date format: \(dateString)"))
    }

    init(
        id: UUID = UUID(),
        scenarioId: UUID,
        contributorName: String,
        amount: Double,
        contributionDate: Date,
        contributionType: ContributionType,
        notes: String? = nil,
        coupleId: UUID,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.scenarioId = scenarioId
        self.contributorName = contributorName
        self.amount = amount
        self.contributionDate = contributionDate
        self.contributionType = contributionType
        self.notes = notes
        self.coupleId = coupleId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum ContributionType: String, Codable, CaseIterable {
    case gift = "gift"
    case external = "external_contribution"

    var displayName: String {
        switch self {
        case .gift: return "Gift"
        case .external: return "External"
        }
    }
}
