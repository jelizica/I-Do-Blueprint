//
//  GiftOrOwed.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Model for tracking gifts received, money owed, and contributions
//

import Foundation
import SwiftUI

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

    /// The actual amount received (may differ from amount for partial contributions)
    var amountReceived: Double

    /// When the payment was recorded
    var paymentRecordedAt: Date?

    // MARK: - Computed Properties

    /// Remaining balance to be received
    var remainingBalance: Double {
        max(0, amount - amountReceived)
    }

    /// Whether this contribution has been partially received
    var isPartiallyReceived: Bool {
        amountReceived > 0 && amountReceived < amount
    }

    /// Whether this contribution has been fully received
    var isFullyReceived: Bool {
        amountReceived >= amount
    }

    /// Whether any payment has been recorded
    var hasPaymentRecorded: Bool {
        amountReceived > 0
    }

    /// Progress percentage (0.0 to 1.0)
    var receivedProgress: Double {
        guard amount > 0 else { return 0 }
        return min(amountReceived / amount, 1.0)
    }

    enum GiftOrOwedType: String, CaseIterable, Codable {
        case giftReceived = "gift_received"
        case moneyOwed = "money_owed"
        case contribution = "contribution"

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
        case pending = "pending"
        case partial = "partial"
        case received = "received"
        case confirmed = "confirmed"

        var displayName: String {
            switch self {
            case .pending: "Pending"
            case .partial: "Partial"
            case .received: "Received"
            case .confirmed: "Confirmed"
            }
        }

        var color: Color {
            switch self {
            case .pending: .orange
            case .partial: Color.fromHex("F59E0B") // Amber for partial
            case .received: .green
            case .confirmed: .blue
            }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case coupleId = "couple_id"
        case title = "title"
        case amount = "amount"
        case type = "type"
        case description = "description"
        case fromPerson = "from_person"
        case expectedDate = "expected_date"
        case receivedDate = "received_date"
        case status = "status"
        case scenarioId = "scenario_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case amountReceived = "amount_received"
        case paymentRecordedAt = "payment_recorded_at"
    }

    // MARK: - Custom Decoding (for backward compatibility)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)
        title = try container.decode(String.self, forKey: .title)
        amount = try container.decode(Double.self, forKey: .amount)
        type = try container.decode(GiftOrOwedType.self, forKey: .type)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        fromPerson = try container.decodeIfPresent(String.self, forKey: .fromPerson)
        expectedDate = try container.decodeIfPresent(Date.self, forKey: .expectedDate)
        receivedDate = try container.decodeIfPresent(Date.self, forKey: .receivedDate)
        status = try container.decode(GiftOrOwedStatus.self, forKey: .status)
        scenarioId = try container.decodeIfPresent(UUID.self, forKey: .scenarioId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)

        // New fields with defaults for backward compatibility
        amountReceived = try container.decodeIfPresent(Double.self, forKey: .amountReceived) ?? 0
        paymentRecordedAt = try container.decodeIfPresent(Date.self, forKey: .paymentRecordedAt)
    }

    // MARK: - Memberwise Initializer

    init(
        id: UUID = UUID(),
        coupleId: UUID,
        title: String,
        amount: Double,
        type: GiftOrOwedType,
        description: String? = nil,
        fromPerson: String? = nil,
        expectedDate: Date? = nil,
        receivedDate: Date? = nil,
        status: GiftOrOwedStatus = .pending,
        scenarioId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        amountReceived: Double = 0,
        paymentRecordedAt: Date? = nil
    ) {
        self.id = id
        self.coupleId = coupleId
        self.title = title
        self.amount = amount
        self.type = type
        self.description = description
        self.fromPerson = fromPerson
        self.expectedDate = expectedDate
        self.receivedDate = receivedDate
        self.status = status
        self.scenarioId = scenarioId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.amountReceived = amountReceived
        self.paymentRecordedAt = paymentRecordedAt
    }
}
