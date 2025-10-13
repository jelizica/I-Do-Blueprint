//
//  CoupleMembership.swift
//  I Do Blueprint
//
//  Model for couple memberships
//

import Foundation

/// Represents a user's membership in a couple
struct CoupleMembership: Codable, Identifiable, Sendable {
    let id: UUID
    let coupleId: UUID
    let userId: UUID
    let role: String
    let createdAt: Date
    let updatedAt: Date

    // Couple profile information (joined)
    let partner1Name: String
    let partner2Name: String?
    let weddingDate: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case userId = "user_id"
        case role
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case partner1Name = "partner1_name"
        case partner2Name = "partner2_name"
        case weddingDate = "wedding_date"
    }

    /// Display name for the couple
    var displayName: String {
        if let partner2 = partner2Name, !partner2.isEmpty {
            return "\(partner1Name) & \(partner2)"
        }
        return partner1Name
    }
}
