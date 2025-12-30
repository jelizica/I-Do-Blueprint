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
        case received = "received"
        case confirmed = "confirmed"

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
    }
}
