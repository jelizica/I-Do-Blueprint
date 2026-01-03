//
//  Guest.swift
//  My Wedding Planning App
//
//  Created by Jessica Clark on 9/26/25.
//

import Foundation
import SwiftUI
import AppKit

// RSVP status ordering for consistent sorting across the application
enum RSVPStatus: String, CaseIterable, Codable {
    case attending = "attending"
    case confirmed = "confirmed"
    case maybe = "maybe"
    case pending = "pending"
    case invited = "invited"
    case saveTheDateSent = "save_the_date_sent"
    case invitationSent = "invitation_sent"
    case reminded = "reminded"
    case declined = "declined"
    case noResponse = "no_response"

    var displayName: String {
        switch self {
        case .attending: "Attending"
        case .confirmed: "Confirmed"
        case .maybe: "Maybe"
        case .pending: "Pending"
        case .invited: "Invited"
        case .saveTheDateSent: "Save the Date Sent"
        case .invitationSent: "Invitation Sent"
        case .reminded: "Reminded"
        case .declined: "Declined"
        case .noResponse: "No Response"
        }
    }

    var color: Color {
        switch self {
        case .attending, .confirmed: AppColors.Guest.confirmed
        case .declined: AppColors.Guest.declined
        case .maybe, .pending: AppColors.Guest.pending
        case .invited, .saveTheDateSent, .invitationSent, .reminded, .noResponse: AppColors.Guest.invited
        }
    }

    /// SF Symbol icon for accessibility and visual clarity
    var icon: String {
        switch self {
        case .attending, .confirmed:
            return "checkmark.circle.fill"
        case .declined:
            return "xmark.circle.fill"
        case .maybe:
            return "questionmark.circle.fill"
        case .pending:
            return "clock.fill"
        case .invited, .saveTheDateSent, .invitationSent:
            return "envelope.fill"
        case .reminded:
            return "bell.fill"
        case .noResponse:
            return "ellipsis.circle.fill"
        }
    }
}

enum InvitedBy: String, CaseIterable, Codable {
    case bride1 = "bride1"
    case bride2 = "bride2"
    case both = "both"

    var displayName: String {
        switch self {
        case .bride1: "Partner 1"
        case .bride2: "Partner 2"
        case .both: "Both"
        }
    }

    /// Returns the display name using actual partner names from settings
    func displayName(with settings: CoupleSettings) -> String {
        switch self {
        case .bride1:
            return settings.global.partner1Nickname.isEmpty
                ? (settings.global.partner1FullName.isEmpty ? "Partner 1" : settings.global.partner1FullName)
                : settings.global.partner1Nickname
        case .bride2:
            return settings.global.partner2Nickname.isEmpty
                ? (settings.global.partner2FullName.isEmpty ? "Partner 2" : settings.global.partner2FullName)
                : settings.global.partner2Nickname
        case .both:
            let name1 = settings.global.partner1Nickname.isEmpty
                ? (settings.global.partner1FullName.isEmpty ? "Partner 1" : settings.global.partner1FullName)
                : settings.global.partner1Nickname
            let name2 = settings.global.partner2Nickname.isEmpty
                ? (settings.global.partner2FullName.isEmpty ? "Partner 2" : settings.global.partner2FullName)
                : settings.global.partner2Nickname
            return "\(name1) & \(name2)"
        }
    }
}

enum PreferredContactMethod: String, CaseIterable, Codable {
    case email = "email"
    case phone = "phone"
    case mail = "mail"

    var displayName: String {
        switch self {
        case .email: "Email"
        case .phone: "Phone"
        case .mail: "Mail"
        }
    }
}

struct Guest: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    var firstName: String
    var lastName: String
    var email: String?
    var phone: String?
    var guestGroupId: UUID?
    var relationshipToCouple: String?
    var invitedBy: InvitedBy?
    var rsvpStatus: RSVPStatus
    var rsvpDate: Date?
    var plusOneAllowed: Bool
    var plusOneName: String?
    var plusOneAttending: Bool
    var attendingCeremony: Bool
    var attendingReception: Bool
    var attendingRehearsal: Bool
    var attendingOtherEvents: [String]?
    var dietaryRestrictions: String?
    var accessibilityNeeds: String?
    var tableAssignment: Int?
    var seatNumber: Int?
    var preferredContactMethod: PreferredContactMethod?
    var addressLine1: String?
    var addressLine2: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String?
    var invitationNumber: String?
    var isWeddingParty: Bool
    var weddingPartyRole: String?
    var preparationNotes: String?
    let coupleId: UUID
    var mealOption: String?
    var giftReceived: Bool
    var notes: String?
    var hairDone: Bool
    var makeupDone: Bool

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var formattedPhone: String? {
        guard let phone, !phone.isEmpty else { return nil }
        return phone
    }

    /// Returns true if the guest's RSVP status indicates they are attending
    var isAttending: Bool {
        rsvpStatus == .attending || rsvpStatus == .confirmed
    }

    // Custom coding keys to match database column names
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case firstName = "first_name"
        case lastName = "last_name"
        case email = "email"
        case phone = "phone"
        case guestGroupId = "guest_group_id"
        case relationshipToCouple = "relationship_to_couple"
        case invitedBy = "invited_by"
        case rsvpStatus = "rsvp_status"
        case rsvpDate = "rsvp_date"
        case plusOneAllowed = "plus_one_allowed"
        case plusOneName = "plus_one_name"
        case plusOneAttending = "plus_one_attending"
        case attendingCeremony = "attending_ceremony"
        case attendingReception = "attending_reception"
        case attendingRehearsal = "attending_rehearsal"
        case attendingOtherEvents = "attending_other_events"
        case dietaryRestrictions = "dietary_restrictions"
        case accessibilityNeeds = "accessibility_needs"
        case tableAssignment = "table_assignment"
        case seatNumber = "seat_number"
        case preferredContactMethod = "preferred_contact_method"
        case addressLine1 = "address_line1"
        case addressLine2 = "address_line2"
        case city = "city"
        case state = "state"
        case zipCode = "zip_code"
        case country = "country"
        case invitationNumber = "invitation_number"
        case isWeddingParty = "is_wedding_party"
        case weddingPartyRole = "wedding_party_role"
        case preparationNotes = "preparation_notes"
        case coupleId = "couple_id"
        case mealOption = "meal_option"
        case giftReceived = "gift_received"
        case notes = "notes"
        case hairDone = "hair_done"
        case makeupDone = "makeup_done"
    }
}

// MARK: - Sort Options

enum GuestSortOption: String, CaseIterable, Identifiable {
    case nameAsc = "name_asc"
    case nameDesc = "name_desc"
    case rsvpStatusAttending = "rsvp_status_attending"
    case rsvpStatusPending = "rsvp_status_pending"
    case dateAddedNewest = "date_added_newest"
    case dateAddedOldest = "date_added_oldest"
    case tableNumber = "table_number"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .nameAsc: "Name (A-Z)"
        case .nameDesc: "Name (Z-A)"
        case .rsvpStatusAttending: "Attending First"
        case .rsvpStatusPending: "Pending First"
        case .dateAddedNewest: "Recently Added"
        case .dateAddedOldest: "Oldest First"
        case .tableNumber: "Table Number"
        }
    }

    var iconName: String {
        switch self {
        case .nameAsc, .nameDesc: "textformat"
        case .rsvpStatusAttending, .rsvpStatusPending: "checkmark.seal"
        case .dateAddedNewest, .dateAddedOldest: "calendar.badge.plus"
        case .tableNumber: "tablecells"
        }
    }

    var groupLabel: String {
        switch self {
        case .nameAsc, .nameDesc: "Name"
        case .rsvpStatusAttending, .rsvpStatusPending: "RSVP Status"
        case .dateAddedNewest, .dateAddedOldest: "Date Added"
        case .tableNumber: "Table"
        }
    }

    /// Sort an array of guests using this sort option
    func sort(_ guests: [Guest]) -> [Guest] {
        switch self {
        case .nameAsc:
            return guests.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
        case .nameDesc:
            return guests.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedDescending }
        case .rsvpStatusAttending:
            return guests.sorted { (g1, g2) in
                let attending1 = g1.rsvpStatus == .attending || g1.rsvpStatus == .confirmed
                let attending2 = g2.rsvpStatus == .attending || g2.rsvpStatus == .confirmed
                if attending1 == attending2 {
                    return g1.fullName.localizedCaseInsensitiveCompare(g2.fullName) == .orderedAscending
                }
                return attending1 && !attending2
            }
        case .rsvpStatusPending:
            return guests.sorted { (g1, g2) in
                let pending1 = g1.rsvpStatus == .pending || g1.rsvpStatus == .invited
                let pending2 = g2.rsvpStatus == .pending || g2.rsvpStatus == .invited
                if pending1 == pending2 {
                    return g1.fullName.localizedCaseInsensitiveCompare(g2.fullName) == .orderedAscending
                }
                return pending1 && !pending2
            }
        case .dateAddedNewest:
            return guests.sorted { $0.createdAt > $1.createdAt }
        case .dateAddedOldest:
            return guests.sorted { $0.createdAt < $1.createdAt }
        case .tableNumber:
            return guests.sorted { (g1, g2) in
                switch (g1.tableAssignment, g2.tableAssignment) {
                case (.some(let table1), .some(let table2)):
                    if table1 == table2 {
                        return g1.fullName.localizedCaseInsensitiveCompare(g2.fullName) == .orderedAscending
                    }
                    return table1 < table2
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return g1.fullName.localizedCaseInsensitiveCompare(g2.fullName) == .orderedAscending
                }
            }
        }
    }

    /// Grouped sort options for UI display
    static var grouped: [(String, [GuestSortOption])] {
        [
            ("Name", [.nameAsc, .nameDesc]),
            ("RSVP Status", [.rsvpStatusAttending, .rsvpStatusPending]),
            ("Date Added", [.dateAddedNewest, .dateAddedOldest]),
            ("Table", [.tableNumber])
        ]
    }
}

// Guest statistics for dashboard
struct GuestStats: Codable, Equatable, Sendable {
    let totalGuests: Int
    let attendingGuests: Int
    let pendingGuests: Int
    let declinedGuests: Int
    let responseRate: Double

    enum CodingKeys: String, CodingKey {
        case totalGuests = "total_guests"
        case attendingGuests = "attending_guests"
        case pendingGuests = "pending_guests"
        case declinedGuests = "declined_guests"
        case responseRate = "response_rate"
    }
}

// Guest group model
struct GuestGroup: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    var groupName: String
    var groupType: GroupType
    var notes: String?

    enum GroupType: String, CaseIterable, Codable {
        case family = "family"
        case friends = "friends"
        case work = "work"
        case other = "other"

        var displayName: String {
            switch self {
            case .family: "Family"
            case .friends: "Friends"
            case .work: "Work"
            case .other: "Other"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case groupName = "group_name"
        case groupType = "group_type"
        case notes = "notes"
    }
}

// MARK: - Avatar Support

extension Guest {
    /// Generate a unique avatar identifier for this guest
    /// Uses guest full name for Multiavatar API compatibility
    var avatarIdentifier: String {
        fullName
    }

    /// Fetch avatar image for this guest
    /// - Parameter size: Desired image size (default 100x100)
    /// - Returns: NSImage of the avatar
    /// - Throws: AvatarError if fetch fails
    func fetchAvatar(size: CGSize = CGSize(width: 100, height: 100)) async throws -> NSImage {
        try await MultiAvatarJSService.shared.fetchAvatar(
            for: avatarIdentifier,
            size: size
        )
    }
}
