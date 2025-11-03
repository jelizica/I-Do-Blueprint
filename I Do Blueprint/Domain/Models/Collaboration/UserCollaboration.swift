//
//  UserCollaboration.swift
//  I Do Blueprint
//
//  User collaboration with couple details for managing collaborations across multiple weddings
//

import Foundation

/// User collaboration with couple details
///
/// Represents a user's collaboration on a specific couple's wedding, including
/// the couple information, role, status, and invitation metadata.
///
/// Used in the "My Collaborations" view to show all weddings a user is collaborating on.
struct UserCollaboration: Identifiable, Codable, Sendable {
    let id: UUID
    let coupleId: UUID
    let coupleName: String
    let weddingDate: Date?
    let role: RoleName
    let status: CollaboratorStatus
    let invitedBy: String?
    let invitedAt: Date
    let acceptedAt: Date?
    let lastSeenAt: Date?

    // MARK: - Computed Properties

    /// Whether this collaboration is active
    var isActive: Bool {
        status == .active
    }

    /// Whether this collaboration is pending acceptance
    var isPending: Bool {
        status == .pending
    }

    /// Days since invitation was sent
    var daysSinceInvitation: Int {
        Calendar.current.dateComponents([.day], from: invitedAt, to: Date()).day ?? 0
    }

    /// Formatted wedding date string
    var formattedWeddingDate: String {
        guard let weddingDate = weddingDate else {
            return "Date TBD"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: weddingDate)
    }

    /// Relative time since invitation (e.g., "2 days ago")
    var relativeInvitationTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: invitedAt, relativeTo: Date())
    }
}

// MARK: - Test Helpers

#if DEBUG
extension UserCollaboration {
    /// Creates a test collaboration for previews and testing
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        coupleName: String = "Jessica & Elizabeth",
        weddingDate: Date? = Date().addingTimeInterval(180 * 24 * 60 * 60), // 180 days from now
        role: RoleName = .partner,
        status: CollaboratorStatus = .active,
        invitedBy: String? = "Jessica Clark",
        invitedAt: Date = Date().addingTimeInterval(-7 * 24 * 60 * 60), // 7 days ago
        acceptedAt: Date? = Date().addingTimeInterval(-6 * 24 * 60 * 60), // 6 days ago
        lastSeenAt: Date? = Date().addingTimeInterval(-1 * 60 * 60) // 1 hour ago
    ) -> UserCollaboration {
        UserCollaboration(
            id: id,
            coupleId: coupleId,
            coupleName: coupleName,
            weddingDate: weddingDate,
            role: role,
            status: status,
            invitedBy: invitedBy,
            invitedAt: invitedAt,
            acceptedAt: acceptedAt,
            lastSeenAt: lastSeenAt
        )
    }
}
#endif
