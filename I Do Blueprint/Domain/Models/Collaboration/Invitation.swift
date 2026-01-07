//
//  Invitation.swift
//  I Do Blueprint
//
//  Domain model for collaboration invitations (pending users)
//

import Foundation

/// Represents a pending invitation to collaborate on wedding planning
struct Invitation: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date

    // Multi-tenant isolation
    let coupleId: UUID

    // Invitation details
    let email: String
    let roleId: UUID
    let invitedBy: UUID
    let invitedAt: Date
    let expiresAt: Date

    // Status tracking
    let status: InvitationStatus

    // Security
    let token: String

    // Optional metadata
    let displayName: String?
    let message: String?
    let acceptedBy: UUID?
    let acceptedAt: Date?
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case coupleId = "couple_id"
        case email = "email"
        case roleId = "role_id"
        case invitedBy = "invited_by"
        case invitedAt = "invited_at"
        case expiresAt = "expires_at"
        case status = "status"
        case token = "token"
        case displayName = "display_name"
        case message = "message"
        case acceptedBy = "accepted_by"
        case acceptedAt = "accepted_at"
        case metadata = "metadata"
    }

    // MARK: - Computed Properties

    var isExpired: Bool {
        Date() > expiresAt && status == .pending
    }

    var isActive: Bool {
        status == .pending && !isExpired
    }

    var daysUntilExpiration: Int {
        guard status == .pending else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
        return max(0, days)
    }
}

/// Details returned when fetching invitation by token
/// Includes all information needed for invitation acceptance flow
struct InvitationDetails: Codable, Sendable, Equatable {
    let invitation: Invitation
    let role: CollaborationRole
    let coupleId: UUID
    let coupleName: String?
    let inviterEmail: String?

    var isExpired: Bool {
        invitation.isExpired
    }

    var isActive: Bool {
        invitation.isActive
    }
}

/// Status of an invitation
enum InvitationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case expired = "expired"
    case cancelled = "cancelled"
    case declined = "declined"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .expired: return "Expired"
        case .cancelled: return "Cancelled"
        case .declined: return "Declined"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .accepted: return "checkmark.circle"
        case .expired: return "exclamationmark.triangle"
        case .cancelled: return "xmark.circle"
        case .declined: return "hand.raised"
        }
    }
}
