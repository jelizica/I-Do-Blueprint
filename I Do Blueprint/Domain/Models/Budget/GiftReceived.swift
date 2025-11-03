//
//  GiftReceived.swift
//  I Do Blueprint
//
//  Model for tracking gifts received from guests and family members
//

import Foundation

/// Represents a gift received from a guest or family member
struct GiftReceived: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let coupleId: UUID
    var fromPerson: String
    var amount: Double
    var dateReceived: Date
    var giftType: GiftType
    var notes: String?
    var isThankYouSent: Bool
    let createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case coupleId = "couple_id"
        case fromPerson = "from_person"
        case amount = "amount"
        case dateReceived = "date_received"
        case giftType = "gift_type"
        case notes = "notes"
        case isThankYouSent = "is_thank_you_sent"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        coupleId: UUID,
        fromPerson: String,
        amount: Double,
        dateReceived: Date,
        giftType: GiftType,
        notes: String? = nil,
        isThankYouSent: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.coupleId = coupleId
        self.fromPerson = fromPerson
        self.amount = amount
        self.dateReceived = dateReceived
        self.giftType = giftType
        self.notes = notes
        self.isThankYouSent = isThankYouSent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - GiftType Enum

enum GiftType: String, CaseIterable, Codable, Sendable {
    case cash = "Cash"
    case check = "Check"
    case gift = "Gift"
    case giftCard = "Gift Card"
    case other = "Other"

    var displayName: String {
        rawValue
    }
}

// MARK: - Test Helpers

extension GiftReceived {
    /// Creates a test instance of GiftReceived with default values
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        fromPerson: String = "Test Person",
        amount: Double = 100.0,
        dateReceived: Date = Date(),
        giftType: GiftType = .cash,
        notes: String? = nil,
        isThankYouSent: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) -> GiftReceived {
        GiftReceived(
            id: id,
            coupleId: coupleId,
            fromPerson: fromPerson,
            amount: amount,
            dateReceived: dateReceived,
            giftType: giftType,
            notes: notes,
            isThankYouSent: isThankYouSent,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
