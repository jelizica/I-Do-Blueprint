//
//  Collaborator.swift
//  I Do Blueprint
//
//  Collaboration system model for tracking collaborators
//

import Foundation

/// Represents a collaborator on a wedding planning project
struct Collaborator: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    let coupleId: UUID
    let userId: UUID
    let roleId: UUID
    let invitedBy: UUID?
    let invitedAt: Date
    var acceptedAt: Date?
    var status: CollaboratorStatus
    let email: String
    var displayName: String?
    var avatarUrl: String?
    var lastSeenAt: Date?

    // Computed property for full name fallback
    var name: String {
        displayName ?? email
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case coupleId = "couple_id"
        case userId = "user_id"
        case roleId = "role_id"
        case invitedBy = "invited_by"
        case invitedAt = "invited_at"
        case acceptedAt = "accepted_at"
        case status
        case email
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case lastSeenAt = "last_seen_at"
    }
}

/// Collaborator status
enum CollaboratorStatus: String, Codable, Sendable {
    case pending
    case active
    case inactive
    case revoked
}

// MARK: - Test Helpers

extension Collaborator {
    /// Creates a test collaborator with default values
    static func makeTest(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        coupleId: UUID = UUID(),
        userId: UUID = UUID(),
        roleId: UUID = UUID(),
        invitedBy: UUID? = nil,
        invitedAt: Date = Date(),
        acceptedAt: Date? = nil,
        status: CollaboratorStatus = .active,
        email: String = "test@example.com",
        displayName: String? = "Test User",
        avatarUrl: String? = nil,
        lastSeenAt: Date? = nil
    ) -> Collaborator {
        Collaborator(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            coupleId: coupleId,
            userId: userId,
            roleId: roleId,
            invitedBy: invitedBy,
            invitedAt: invitedAt,
            acceptedAt: acceptedAt,
            status: status,
            email: email,
            displayName: displayName,
            avatarUrl: avatarUrl,
            lastSeenAt: lastSeenAt
        )
    }
}
