//
//  Gift.swift
//  I Do Blueprint
//
//  Extracted from Budget.swift as part of architecture improvement plan
//  Model for gift tracking
//

import Foundation

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
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
