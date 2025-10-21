//
//  SeatingChart.swift
//  My Wedding Planning App
//
//  Data models for seating chart functionality
//

import SwiftUI

// MARK: - Seating Chart

struct SeatingChart: Identifiable, Codable, Hashable {
    let id: UUID
    var tenantId: String
    var chartName: String
    var eventId: UUID?  // Changed from eventName to eventId to match database
    var venueLayoutType: VenueLayout
    var venueConfiguration: VenueConfiguration
    var tables: [Table]
    var guests: [SeatingGuest]
    var seatingAssignments: [SeatingAssignment]
    var layoutSettings: LayoutSettings
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    var chartDescription: String?
    var isFinalized: Bool

    // Phase 2: New properties for enhanced functionality
    var seatingGuestGroups: [SeatingGuestGroup]
    var tableZones: [TableZone]
    var seatingRelationships: [SeatingGuestRelationship]
    var defaultTableStyle: TableShape

    enum CodingKeys: String, CodingKey {
        case id
        case tenantId = "couple_id"
        case chartName = "chart_name"
        case eventId = "event_id"
        case venueLayoutData = "venue_layout_data"
        case totalTables = "total_tables"
        case totalSeats = "total_seats"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isActive = "is_active"
        case notes
        case isFinalized = "is_finalized"
        case canvasWidth = "canvas_width"
        case canvasHeight = "canvas_height"
        case backgroundColor = "background_color"
        case backgroundImage = "background_image"
        case zoomLevel = "zoom_level"
        case viewPosition = "view_position"
        case gridSettings = "grid_settings"
    }

    // Custom decoder to handle database structure
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        tenantId = try container.decode(String.self, forKey: .tenantId)
        chartName = try container.decode(String.self, forKey: .chartName)
        eventId = try container.decodeIfPresent(UUID.self, forKey: .eventId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        chartDescription = try container.decodeIfPresent(String.self, forKey: .notes)
        isFinalized = try container.decode(Bool.self, forKey: .isFinalized)

        // Default values for fields not in database
        venueLayoutType = .round
        venueConfiguration = VenueConfiguration()
        tables = []
        guests = []
        seatingAssignments = []
        layoutSettings = LayoutSettings()

        // Phase 2: Default values for new properties
        seatingGuestGroups = []
        tableZones = []
        seatingRelationships = []
        defaultTableStyle = .rectangular
    }

    // Custom encoder to handle database structure
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(tenantId, forKey: .tenantId)
        try container.encode(chartName, forKey: .chartName)
        try container.encodeIfPresent(eventId, forKey: .eventId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(chartDescription, forKey: .notes)
        try container.encode(isFinalized, forKey: .isFinalized)
    }

    init(
        tenantId: String,
        chartName: String,
        eventId: UUID? = nil,
        venueLayoutType: VenueLayout = .round,
        venueConfiguration: VenueConfiguration = VenueConfiguration(),
        chartDescription: String? = nil,
        isFinalized: Bool = false
    ) {
        id = UUID()
        self.tenantId = tenantId
        self.chartName = chartName
        self.eventId = eventId
        self.venueLayoutType = venueLayoutType
        self.venueConfiguration = venueConfiguration
        tables = []
        guests = []
        seatingAssignments = []
        layoutSettings = LayoutSettings()
        createdAt = Date()
        updatedAt = Date()
        isActive = true
        self.chartDescription = chartDescription
        self.isFinalized = isFinalized

        // Phase 2: Initialize new properties
        seatingGuestGroups = []
        tableZones = []
        seatingRelationships = []
        defaultTableStyle = .rectangular
    }
}

// MARK: - Venue Layout

struct VenueConfiguration: Codable, Hashable {
    var dimensions: CGSize
    var backgroundImage: String?
    var obstacles: [VenueObstacle]
    var danceFloor: CGRect?
    var stage: CGRect?
    var bar: CGRect?
    var buffet: CGRect?
    var entrance: CGPoint?

    init() {
        dimensions = CGSize(width: 800, height: 600)
        obstacles = []
    }
}

struct VenueObstacle: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var position: CGPoint
    var size: CGSize
    var obstacleType: ObstacleType
    var isMovable: Bool

    init(name: String, position: CGPoint, size: CGSize, type: ObstacleType) {
        id = UUID()
        self.name = name
        self.position = position
        self.size = size
        obstacleType = type
        isMovable = type != .wall && type != .column
    }
}

enum ObstacleType: String, CaseIterable, Codable {
    case wall, column, bar, buffet, danceFloor, stage, dj, photo

    var displayName: String {
        switch self {
        case .wall: "Wall"
        case .column: "Column"
        case .bar: "Bar"
        case .buffet: "Buffet"
        case .danceFloor: "Dance Floor"
        case .stage: "Stage"
        case .dj: "DJ Station"
        case .photo: "Photo Area"
        }
    }

    var icon: String {
        switch self {
        case .wall: "rectangle"
        case .column: "circle"
        case .bar: "wineglass"
        case .buffet: "fork.knife"
        case .danceFloor: "music.note"
        case .stage: "theatermasks"
        case .dj: "hifispeaker"
        case .photo: "camera"
        }
    }

    var defaultColor: Color {
        switch self {
        case .wall: .gray
        case .column: .brown
        case .bar: .blue
        case .buffet: .orange
        case .danceFloor: .purple
        case .stage: .red
        case .dj: .green
        case .photo: .yellow
        }
    }
}

// MARK: - Table

struct Table: Identifiable, Codable, Hashable {
    let id: UUID
    var tableNumber: Int
    var tableName: String?
    var position: CGPoint
    var tableShape: TableShape
    var capacity: Int
    var assignedGuests: [UUID] // Guest IDs
    var rotation: Double
    var tableDecoration: TableDecoration?
    var notes: String

    init(
        tableNumber: Int,
        position: CGPoint = .zero,
        shape: TableShape = .round,
        capacity: Int = 8) {
        id = UUID()
        self.tableNumber = tableNumber
        self.position = position
        tableShape = shape
        self.capacity = capacity
        assignedGuests = []
        rotation = 0
        notes = ""
    }

    var availableSeats: Int {
        capacity - assignedGuests.count
    }

    var isFull: Bool {
        assignedGuests.count >= capacity
    }
}

struct TableDecoration: Codable, Hashable {
    var centerpiece: String?
    var linens: String?
    var chargers: String?
    var theme: String?
}

// MARK: - Seating Guest

struct SeatingGuest: Identifiable, Codable, Hashable {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var relationship: GuestRelationship
    var dietaryRestrictions: String
    var accessibility: AccessibilityNeeds?
    var preferences: [String]
    var conflicts: [UUID] // Other guest IDs to avoid
    var group: String? // Family/friend group
    var plusOne: UUID? // Partner's guest ID
    var specialRequests: String
    var photoURL: String?
    var isVIP: Bool

    init(
        firstName: String,
        lastName: String,
        email: String = "",
        phone: String = "",
        relationship: GuestRelationship = .friend,
        group: String? = nil,
        isVIP: Bool = false
    ) {
        id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.relationship = relationship
        self.group = group
        self.isVIP = isVIP
        dietaryRestrictions = ""
        preferences = []
        conflicts = []
        specialRequests = ""
        photoURL = nil
    }

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var displayName: String {
        fullName
    }

    var initials: String {
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
}

enum GuestRelationship: String, CaseIterable, Codable {
    case bride, groom, brideSide, groomSide, family, friend, coworker, vendor

    var displayName: String {
        switch self {
        case .bride: "Bride"
        case .groom: "Groom"
        case .brideSide: "Bride's Side"
        case .groomSide: "Groom's Side"
        case .family: "Family"
        case .friend: "Friend"
        case .coworker: "Coworker"
        case .vendor: "Vendor"
        }
    }

    var color: Color {
        switch self {
        case .bride: .pink
        case .groom: .blue
        case .brideSide: .purple
        case .groomSide: .cyan
        case .family: .green
        case .friend: .orange
        case .coworker: .yellow
        case .vendor: .gray
        }
    }
}

struct AccessibilityNeeds: Codable, Hashable {
    var wheelchairAccessible: Bool
    var hearingImpaired: Bool
    var visuallyImpaired: Bool
    var mobilityLimited: Bool
    var other: String?

    init() {
        wheelchairAccessible = false
        hearingImpaired = false
        visuallyImpaired = false
        mobilityLimited = false
    }
}

enum SeatingPreference: String, CaseIterable, Codable {
    case nearDanceFloor, farFromSpeakers, nearBar, nearBathroom, headTable,
         quietArea, familyTable, kidsTable, viewOfStage

    var displayName: String {
        switch self {
        case .nearDanceFloor: "Near Dance Floor"
        case .farFromSpeakers: "Away from Speakers"
        case .nearBar: "Near Bar"
        case .nearBathroom: "Near Bathroom"
        case .headTable: "Head Table"
        case .quietArea: "Quiet Area"
        case .familyTable: "Family Table"
        case .kidsTable: "Kids Table"
        case .viewOfStage: "View of Stage"
        }
    }
}

// MARK: - Seating Assignment

struct SeatingAssignment: Identifiable, Codable, Hashable {
    let id: UUID
    var guestId: UUID
    var tableId: UUID
    var seatNumber: Int?
    var assignedAt: Date
    var assignedBy: String
    var notes: String

    init(guestId: UUID, tableId: UUID, seatNumber: Int? = nil) {
        id = UUID()
        self.guestId = guestId
        self.tableId = tableId
        self.seatNumber = seatNumber
        assignedAt = Date()
        
        // Get user email from auth context
        if let userEmail = AuthContext.shared.currentUserEmail {
            assignedBy = userEmail
        } else {
            assignedBy = "unknown"
        }
        
        notes = ""
    }
}

// MARK: - Layout Settings

struct LayoutSettings: Codable, Hashable {
    var gridSize: Double
    var snapToGrid: Bool
    var showTableNumbers: Bool
    var showGuestNames: Bool
    var colorScheme: SeatingColorScheme
    var zoom: Double
    var panOffset: CGPoint

    init() {
        gridSize = 20
        snapToGrid = true
        showTableNumbers = true
        showGuestNames = false
        colorScheme = .relationship
        zoom = 1.0
        panOffset = .zero
    }
}

enum SeatingColorScheme: String, CaseIterable, Codable {
    case relationship, dietary, accessibility, assignment

    var displayName: String {
        switch self {
        case .relationship: "By Relationship"
        case .dietary: "By Dietary Needs"
        case .accessibility: "By Accessibility"
        case .assignment: "By Assignment Status"
        }
    }
}

// MARK: - Seating Analytics

struct SeatingAnalytics {
    let totalGuests: Int
    let assignedGuests: Int
    let unassignedGuests: Int
    let totalTables: Int
    let occupiedTables: Int
    let emptyTables: Int
    let averageTableOccupancy: Double
    let conflictCount: Int
    let satisfiedPreferences: Int
    let totalPreferences: Int

    var assignmentProgress: Double {
        guard totalGuests > 0 else { return 0 }
        return Double(assignedGuests) / Double(totalGuests)
    }

    var tableUtilization: Double {
        guard totalTables > 0 else { return 0 }
        return Double(occupiedTables) / Double(totalTables)
    }

    var preferenceScore: Double {
        guard totalPreferences > 0 else { return 1.0 }
        return Double(satisfiedPreferences) / Double(totalPreferences)
    }
}
