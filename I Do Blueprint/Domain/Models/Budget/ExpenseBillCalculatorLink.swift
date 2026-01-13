//
//  ExpenseBillCalculatorLink.swift
//  I Do Blueprint
//
//  Model representing a link between an expense and a bill calculator
//

import Foundation

// MARK: - Expense Bill Calculator Link

/// Represents a link between an expense and a bill calculator
/// Maps to the `expense_bill_calculator_links` table
struct ExpenseBillCalculatorLink: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let expenseId: UUID
    let billCalculatorId: UUID
    let coupleId: UUID
    let linkType: LinkType
    let allocatedAmount: Double?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Link Type

    enum LinkType: String, Codable, CaseIterable, Sendable {
        case full
        case partial
        case deposit
        case installment
        case final

        var displayName: String {
            switch self {
            case .full: return "Full"
            case .partial: return "Partial"
            case .deposit: return "Deposit"
            case .installment: return "Installment"
            case .final: return "Final"
            }
        }
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case expenseId = "expense_id"
        case billCalculatorId = "bill_calculator_id"
        case coupleId = "couple_id"
        case linkType = "link_type"
        case allocatedAmount = "allocated_amount"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        expenseId: UUID,
        billCalculatorId: UUID,
        coupleId: UUID,
        linkType: LinkType = .full,
        allocatedAmount: Double? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.expenseId = expenseId
        self.billCalculatorId = billCalculatorId
        self.coupleId = coupleId
        self.linkType = linkType
        self.allocatedAmount = allocatedAmount
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Test Data

extension ExpenseBillCalculatorLink {
    /// Creates a test instance for previews and testing
    static func makeTest(
        id: UUID = UUID(),
        expenseId: UUID = UUID(),
        billCalculatorId: UUID = UUID(),
        coupleId: UUID = UUID(),
        linkType: LinkType = .full,
        allocatedAmount: Double? = nil,
        notes: String? = nil
    ) -> ExpenseBillCalculatorLink {
        ExpenseBillCalculatorLink(
            id: id,
            expenseId: expenseId,
            billCalculatorId: billCalculatorId,
            coupleId: coupleId,
            linkType: linkType,
            allocatedAmount: allocatedAmount,
            notes: notes,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
