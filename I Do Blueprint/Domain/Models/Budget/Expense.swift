//
//  Expense.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Model for tracking wedding expenses and payments
//

import Foundation

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
        updatedAt: Date? = nil
    ) {
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

        // Custom date decoding using shared DateDecodingHelpers (refactored from duplicated code)
        expenseDate = try DateDecodingHelpers.decodeDate(from: container, forKey: .expenseDate)
        approvedAt = try DateDecodingHelpers.decodeDateIfPresent(from: container, forKey: .approvedAt)
        createdAt = try DateDecodingHelpers.decodeDate(from: container, forKey: .createdAt)
        updatedAt = try DateDecodingHelpers.decodeDateIfPresent(from: container, forKey: .updatedAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case coupleId = "couple_id"
        case budgetCategoryId = "budget_category_id"
        case vendorId = "vendor_id"
        case vendorName = "vendor_name"
        case expenseName = "expense_name"
        case amount = "amount"
        case expenseDate = "expense_date"
        case paymentMethod = "payment_method"
        case paymentStatus = "payment_status"
        case receiptUrl = "receipt_url"
        case invoiceNumber = "invoice_number"
        case notes = "notes"
        case approvalStatus = "approval_status"
        case approvedBy = "approved_by"
        case approvedAt = "approved_at"
        case invoiceDocumentUrl = "invoice_document_url"
        case isTestData = "is_test_data"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
