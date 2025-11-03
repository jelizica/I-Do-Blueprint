//
//  SeatingGuestGroup.swift
//  My Wedding Planning App
//
//  Model for guest grouping and organization
//

import Foundation
import SwiftUI

struct SeatingGuestGroup: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var colorHex: String  // Store as hex string for Codable
    var icon: String
    var guestIds: [UUID]
    var isVisible: Bool

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        icon: String,
        guestIds: [UUID] = [],
        isVisible: Bool = true
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.guestIds = guestIds
        self.isVisible = isVisible
    }

    var color: Color {
        Color.fromHexString(colorHex) ?? .gray
    }

    static let weddingParty = SeatingGuestGroup(
        name: "Wedding Party",
        colorHex: "#CC66CC",
        icon: "sparkles"
    )

    static let family = SeatingGuestGroup(
        name: "Family",
        colorHex: "#3399E6",
        icon: "house"
    )

    static let friends = SeatingGuestGroup(
        name: "Friends",
        colorHex: "#4DCC80",
        icon: "person.3"
    )

    static let colleagues = SeatingGuestGroup(
        name: "Colleagues",
        colorHex: "#E69933",
        icon: "briefcase"
    )

    static let other = SeatingGuestGroup(
        name: "Other",
        colorHex: "#999999",
        icon: "person"
    )

    static let defaultGroups: [SeatingGuestGroup] = [
        .weddingParty,
        .family,
        .friends,
        .colleagues,
        .other,
    ]
}

// MARK: - Table Zone

struct TableZone: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var colorHex: String
    var position: CGPoint
    var tableIds: [UUID]
    var order: Int

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        position: CGPoint,
        tableIds: [UUID] = [],
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.position = position
        self.tableIds = tableIds
        self.order = order
    }

    var color: Color {
        Color.fromHexString(colorHex) ?? .gray
    }

    static let headTable = TableZone(
        name: "HEAD TABLE",
        colorHex: "#E6B84D",
        position: CGPoint(x: 400, y: 100),
        order: 0
    )

    static let familyTables = TableZone(
        name: "FAMILY TABLES",
        colorHex: "#66B3E6",
        position: CGPoint(x: 400, y: 300),
        order: 1
    )

    static let friendsTables = TableZone(
        name: "FRIENDS TABLES",
        colorHex: "#80CC99",
        position: CGPoint(x: 400, y: 500),
        order: 2
    )

    static let defaultZones: [TableZone] = [
        .headTable,
        .familyTables,
        .friendsTables,
    ]
}

// MARK: - Guest Relationship

struct SeatingGuestRelationship: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var fromGuestId: UUID
    var toGuestId: UUID
    var type: RelationshipType
    var strength: Int  // 1-10, for seating priority

    init(
        id: UUID = UUID(),
        fromGuestId: UUID,
        toGuestId: UUID,
        type: RelationshipType,
        strength: Int = 5
    ) {
        self.id = id
        self.fromGuestId = fromGuestId
        self.toGuestId = toGuestId
        self.type = type
        self.strength = min(10, max(1, strength))
    }
}

enum RelationshipType: String, Codable, CaseIterable {
    case spouse = "spouse"
    case partner = "partner"
    case family = "family"
    case sibling = "sibling"
    case parent = "parent"
    case child = "child"
    case friend = "friend"
    case bestFriend = "bestFriend"
    case colleague = "colleague"
    case business = "business"
    case mustSitTogether = "mustSitTogether"
    case preferTogether = "preferTogether"
    case keepApart = "keepApart"

    var displayName: String {
        switch self {
        case .spouse: return "Spouse"
        case .partner: return "Partner"
        case .family: return "Family"
        case .sibling: return "Sibling"
        case .parent: return "Parent"
        case .child: return "Child"
        case .friend: return "Friend"
        case .bestFriend: return "Best Friend"
        case .colleague: return "Colleague"
        case .business: return "Business"
        case .mustSitTogether: return "Must Sit Together"
        case .preferTogether: return "Prefer Together"
        case .keepApart: return "Keep Apart"
        }
    }

    var color: Color {
        switch self {
        case .spouse, .partner:
            return .relationshipCouple
        case .family, .sibling, .parent, .child:
            return .relationshipFamily
        case .friend, .bestFriend:
            return .relationshipFriend
        case .colleague, .business:
            return .groupColleagues
        case .mustSitTogether, .preferTogether:
            return .seatingSuccess
        case .keepApart:
            return .relationshipConflict
        }
    }

    var icon: String {
        switch self {
        case .spouse, .partner: return "heart.fill"
        case .family: return "house.fill"
        case .sibling: return "person.2.fill"
        case .parent, .child: return "person.3.fill"
        case .friend: return "person.2"
        case .bestFriend: return "star.fill"
        case .colleague, .business: return "briefcase.fill"
        case .mustSitTogether: return "link"
        case .preferTogether: return "hand.thumbsup.fill"
        case .keepApart: return "hand.thumbsdown.fill"
        }
    }

    var isConflict: Bool {
        self == .keepApart
    }

    var isRequirement: Bool {
        self == .mustSitTogether
    }
}

// MARK: - Color Extension

extension Color {
    static func fromHexString(_ hex: String) -> Color? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        return Color(red: r, green: g, blue: b)
    }
}
