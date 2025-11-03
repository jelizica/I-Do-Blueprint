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
    case attending
    case confirmed
    case maybe
    case pending
    case invited
    case saveTheDateSent = "save_the_date_sent"
    case invitationSent = "invitation_sent"
    case reminded
    case declined
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
}

enum InvitedBy: String, CaseIterable, Codable {
    case bride1
    case bride2
    case both

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
    case email
    case phone
    case mail

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

    // Custom coding keys to match database column names
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phone
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
        case attendingOtherEvents = "attending_other_events"
        case dietaryRestrictions = "dietary_restrictions"
        case accessibilityNeeds = "accessibility_needs"
        case tableAssignment = "table_assignment"
        case seatNumber = "seat_number"
        case preferredContactMethod = "preferred_contact_method"
        case addressLine1 = "address_line1"
        case addressLine2 = "address_line2"
        case city
        case state
        case zipCode = "zip_code"
        case country
        case invitationNumber = "invitation_number"
        case isWeddingParty = "is_wedding_party"
        case weddingPartyRole = "wedding_party_role"
        case preparationNotes = "preparation_notes"
        case coupleId = "couple_id"
        case mealOption = "meal_option"
        case giftReceived = "gift_received"
        case notes
        case hairDone = "hair_done"
        case makeupDone = "makeup_done"
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
        case family
        case friends
        case work
        case other

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
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case groupName = "group_name"
        case groupType = "group_type"
        case notes
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
