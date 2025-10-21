//
//  MoneyOwed.swift
//  I Do Blueprint
//
//  Model for tracking money owed to vendors, family, or other parties
//

import Foundation

/// Represents money owed to a vendor, family member, or other party
struct MoneyOwed: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let coupleId: UUID
    var toPerson: String
    var amount: Double
    var reason: String
    var dueDate: Date?
    var priority: OwedPriority
    var notes: String?
    var isPaid: Bool
    let createdAt: Date
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case toPerson = "to_person"
        case amount
        case reason
        case dueDate = "due_date"
        case priority
        case notes
        case isPaid = "is_paid"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        coupleId: UUID,
        toPerson: String,
        amount: Double,
        reason: String,
        dueDate: Date? = nil,
        priority: OwedPriority = .medium,
        notes: String? = nil,
        isPaid: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.coupleId = coupleId
        self.toPerson = toPerson
        self.amount = amount
        self.reason = reason
        self.dueDate = dueDate
        self.priority = priority
        self.notes = notes
        self.isPaid = isPaid
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - OwedPriority Enum

enum OwedPriority: String, CaseIterable, Codable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Test Helpers

extension MoneyOwed {
    /// Creates a test instance of MoneyOwed with default values
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        toPerson: String = "Test Vendor",
        amount: Double = 500.0,
        reason: String = "Test Payment",
        dueDate: Date? = nil,
        priority: OwedPriority = .medium,
        notes: String? = nil,
        isPaid: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) -> MoneyOwed {
        MoneyOwed(
            id: id,
            coupleId: coupleId,
            toPerson: toPerson,
            amount: amount,
            reason: reason,
            dueDate: dueDate,
            priority: priority,
            notes: notes,
            isPaid: isPaid,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
