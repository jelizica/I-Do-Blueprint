//
//  WeddingDayEvent.swift
//  I Do Blueprint
//
//  Wedding Day Timeline event model with enhanced fields for timeline views
//  Supports List, Wall, and Gantt chart displays
//

import Foundation
import SwiftUI

// MARK: - Event Status

/// Status values for wedding day events
enum WeddingDayEventStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "pending"
    case onTrack = "on_track"
    case ready = "ready"
    case confirmed = "confirmed"
    case completed = "completed"
    case keyEvent = "key_event"
    case mainEvent = "main_event"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .onTrack: return "On Track"
        case .ready: return "Ready"
        case .confirmed: return "Confirmed"
        case .completed: return "Completed"
        case .keyEvent: return "Key Event"
        case .mainEvent: return "Main Event"
        }
    }

    var color: Color {
        TimelineColors.colorForStatus(rawValue)
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .onTrack: return "checkmark.circle"
        case .ready: return "checkmark.seal"
        case .confirmed: return "checkmark.seal.fill"
        case .completed: return "checkmark.circle.fill"
        case .keyEvent: return "star.fill"
        case .mainEvent: return "heart.fill"
        }
    }
}

// MARK: - Event Category

/// Categories for wedding day events
enum WeddingDayEventCategory: String, Codable, CaseIterable, Identifiable {
    case bridalPrep = "bridal_prep"
    case groomPrep = "groom_prep"
    case ceremony = "ceremony"
    case reception = "reception"
    case photos = "photos"
    case cocktail = "cocktail"
    case dinner = "dinner"
    case dancing = "dancing"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bridalPrep: return "Bridal Prep"
        case .groomPrep: return "Groom Prep"
        case .ceremony: return "Ceremony"
        case .reception: return "Reception"
        case .photos: return "Photos"
        case .cocktail: return "Cocktail Hour"
        case .dinner: return "Dinner"
        case .dancing: return "Dancing"
        case .other: return "Other"
        }
    }

    var color: Color {
        TimelineColors.colorForCategory(rawValue)
    }

    var icon: String {
        switch self {
        case .bridalPrep: return "sparkles"
        case .groomPrep: return "person.fill"
        case .ceremony: return "heart.fill"
        case .reception: return "party.popper.fill"
        case .photos: return "camera.fill"
        case .cocktail: return "wineglass.fill"
        case .dinner: return "fork.knife"
        case .dancing: return "music.note"
        case .other: return "calendar"
        }
    }
}

// MARK: - Wedding Day Event Model

/// Enhanced wedding event model for timeline views
/// Extends WeddingEventDB with additional fields for List, Wall, and Gantt displays
struct WeddingDayEvent: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let coupleId: UUID
    var eventName: String
    var eventType: String
    var eventDate: Date
    var startTime: Date?
    var endTime: Date?
    var venueId: Int64?
    var venueName: String?
    var venueLocation: String?
    var address: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var guestCount: Int?
    var budgetAllocated: Double?
    var notes: String?
    var isConfirmed: Bool
    var description: String?
    var eventOrder: Int
    var isMainEvent: Bool
    let createdAt: Date?
    var updatedAt: Date?

    // MARK: - New Timeline Fields
    var status: WeddingDayEventStatus
    var color: String?
    var dependsOnEventId: UUID?
    var durationMinutes: Int?
    var category: WeddingDayEventCategory
    var icon: String?
    var assignedVendorIds: [Int64]

    // MARK: - Computed Properties

    /// Returns the event's display color
    var displayColor: Color {
        if let hex = color {
            return Color.fromHex(hex)
        }
        return category.color
    }

    /// Returns the event's icon name
    var displayIcon: String {
        icon ?? category.icon
    }

    /// Calculates duration from start and end times
    var calculatedDurationMinutes: Int {
        if let duration = durationMinutes {
            return duration
        }
        guard let start = startTime, let end = endTime else {
            return 30 // Default duration
        }
        return Int(end.timeIntervalSince(start) / 60)
    }

    /// Formats the event time range for display
    var timeRangeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        guard let start = startTime else {
            return "Time TBD"
        }

        let startStr = formatter.string(from: start)

        if let end = endTime {
            let endStr = formatter.string(from: end)
            return "\(startStr) - \(endStr)"
        }

        return startStr
    }

    /// Returns true if event has a dependency
    var hasDependency: Bool {
        dependsOnEventId != nil
    }

    /// Returns true if this is a highlighted event (key or main)
    var isHighlighted: Bool {
        status == .keyEvent || status == .mainEvent || isMainEvent
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case eventName = "event_name"
        case eventType = "event_type"
        case eventDate = "event_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case venueId = "venue_id"
        case venueName = "venue_name"
        case venueLocation = "venue_location"
        case address
        case city
        case state
        case zipCode = "zip_code"
        case guestCount = "guest_count"
        case budgetAllocated = "budget_allocated"
        case notes
        case isConfirmed = "is_confirmed"
        case description
        case eventOrder = "event_order"
        case isMainEvent = "is_main_event"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case status
        case color
        case dependsOnEventId = "depends_on_event_id"
        case durationMinutes = "duration_minutes"
        case category
        case icon
        case assignedVendorIds = "assigned_vendor_ids"
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode UUID fields
        id = try container.decode(UUID.self, forKey: .id)
        coupleId = try container.decode(UUID.self, forKey: .coupleId)

        // Decode required strings
        eventName = try container.decode(String.self, forKey: .eventName)
        eventType = try container.decode(String.self, forKey: .eventType)

        // Decode event_date - PostgreSQL DATE type comes as "YYYY-MM-DD" string
        if let dateString = try? container.decode(String.self, forKey: .eventDate) {
            guard let parsedDate = Self.parseDateFromDatabase(dateString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .eventDate,
                    in: container,
                    debugDescription: "Invalid date format: \(dateString)"
                )
            }
            eventDate = parsedDate
        } else {
            eventDate = try container.decode(Date.self, forKey: .eventDate)
        }

        // Decode time fields (TIME columns come as HH:MM:SS strings)
        if let startTimeString = try container.decodeIfPresent(String.self, forKey: .startTime) {
            startTime = Self.parseTimeFromDatabase(startTimeString)
        } else {
            startTime = nil
        }

        if let endTimeString = try container.decodeIfPresent(String.self, forKey: .endTime) {
            endTime = Self.parseTimeFromDatabase(endTimeString)
        } else {
            endTime = nil
        }

        // Decode optional fields
        venueId = try container.decodeIfPresent(Int64.self, forKey: .venueId)
        venueName = try container.decodeIfPresent(String.self, forKey: .venueName)
        venueLocation = try container.decodeIfPresent(String.self, forKey: .venueLocation)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        zipCode = try container.decodeIfPresent(String.self, forKey: .zipCode)
        guestCount = try container.decodeIfPresent(Int.self, forKey: .guestCount)
        budgetAllocated = try container.decodeIfPresent(Double.self, forKey: .budgetAllocated)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        isConfirmed = try container.decodeIfPresent(Bool.self, forKey: .isConfirmed) ?? false
        description = try container.decodeIfPresent(String.self, forKey: .description)
        eventOrder = try container.decodeIfPresent(Int.self, forKey: .eventOrder) ?? 1
        isMainEvent = try container.decodeIfPresent(Bool.self, forKey: .isMainEvent) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)

        // Decode new timeline fields
        if let statusString = try container.decodeIfPresent(String.self, forKey: .status) {
            status = WeddingDayEventStatus(rawValue: statusString) ?? .pending
        } else {
            status = .pending
        }

        color = try container.decodeIfPresent(String.self, forKey: .color)
        dependsOnEventId = try container.decodeIfPresent(UUID.self, forKey: .dependsOnEventId)
        durationMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinutes)

        if let categoryString = try container.decodeIfPresent(String.self, forKey: .category) {
            category = WeddingDayEventCategory(rawValue: categoryString) ?? .other
        } else {
            category = .other
        }

        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        assignedVendorIds = try container.decodeIfPresent([Int64].self, forKey: .assignedVendorIds) ?? []
    }

    // MARK: - Custom Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(coupleId, forKey: .coupleId)
        try container.encode(eventName, forKey: .eventName)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(Self.formatDateForDatabase(eventDate), forKey: .eventDate)

        if let start = startTime {
            try container.encode(Self.formatTimeForDatabase(start), forKey: .startTime)
        } else {
            try container.encodeNil(forKey: .startTime)
        }

        if let end = endTime {
            try container.encode(Self.formatTimeForDatabase(end), forKey: .endTime)
        } else {
            try container.encodeNil(forKey: .endTime)
        }

        try container.encodeIfPresent(venueId, forKey: .venueId)
        try container.encodeIfPresent(venueName, forKey: .venueName)
        try container.encodeIfPresent(venueLocation, forKey: .venueLocation)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(zipCode, forKey: .zipCode)
        try container.encodeIfPresent(guestCount, forKey: .guestCount)
        try container.encodeIfPresent(budgetAllocated, forKey: .budgetAllocated)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encode(isConfirmed, forKey: .isConfirmed)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(eventOrder, forKey: .eventOrder)
        try container.encode(isMainEvent, forKey: .isMainEvent)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)

        // Encode new timeline fields
        try container.encode(status.rawValue, forKey: .status)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encodeIfPresent(dependsOnEventId, forKey: .dependsOnEventId)
        try container.encodeIfPresent(durationMinutes, forKey: .durationMinutes)
        try container.encode(category.rawValue, forKey: .category)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encode(assignedVendorIds, forKey: .assignedVendorIds)
    }

    // MARK: - Date/Time Helpers

    private static func parseDateFromDatabase(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }

    private static func parseTimeFromDatabase(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current

        if let time = formatter.date(from: timeString) {
            return time
        }

        // Fallback: try HH:mm format
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }

    private static func formatDateForDatabase(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    private static func formatTimeForDatabase(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    // MARK: - Memberwise Initializer

    init(
        id: UUID = UUID(),
        coupleId: UUID,
        eventName: String,
        eventType: String = "wedding",
        eventDate: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        venueId: Int64? = nil,
        venueName: String? = nil,
        venueLocation: String? = nil,
        address: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zipCode: String? = nil,
        guestCount: Int? = nil,
        budgetAllocated: Double? = nil,
        notes: String? = nil,
        isConfirmed: Bool = false,
        description: String? = nil,
        eventOrder: Int = 1,
        isMainEvent: Bool = false,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        status: WeddingDayEventStatus = .pending,
        color: String? = nil,
        dependsOnEventId: UUID? = nil,
        durationMinutes: Int? = nil,
        category: WeddingDayEventCategory = .other,
        icon: String? = nil,
        assignedVendorIds: [Int64] = []
    ) {
        self.id = id
        self.coupleId = coupleId
        self.eventName = eventName
        self.eventType = eventType
        self.eventDate = eventDate
        self.startTime = startTime
        self.endTime = endTime
        self.venueId = venueId
        self.venueName = venueName
        self.venueLocation = venueLocation
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.guestCount = guestCount
        self.budgetAllocated = budgetAllocated
        self.notes = notes
        self.isConfirmed = isConfirmed
        self.description = description
        self.eventOrder = eventOrder
        self.isMainEvent = isMainEvent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.status = status
        self.color = color
        self.dependsOnEventId = dependsOnEventId
        self.durationMinutes = durationMinutes
        self.category = category
        self.icon = icon
        self.assignedVendorIds = assignedVendorIds
    }
}

// MARK: - Test Builder Extension

extension WeddingDayEvent {
    /// Creates a test event with default values for unit testing
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        eventName: String = "Test Event",
        eventDate: Date = Date(),
        startTime: Date? = nil,
        endTime: Date? = nil,
        status: WeddingDayEventStatus = .pending,
        category: WeddingDayEventCategory = .other,
        isMainEvent: Bool = false
    ) -> WeddingDayEvent {
        WeddingDayEvent(
            id: id,
            coupleId: coupleId,
            eventName: eventName,
            eventDate: eventDate,
            startTime: startTime,
            endTime: endTime,
            isMainEvent: isMainEvent,
            status: status,
            category: category
        )
    }
}

// MARK: - Insert Data Model

/// Data structure for creating new wedding day events
struct WeddingDayEventInsertData: Codable {
    var coupleId: UUID
    var eventName: String
    var eventType: String
    var eventDate: Date
    var startTime: Date?
    var endTime: Date?
    var venueId: Int64?
    var venueName: String?
    var venueLocation: String?
    var notes: String?
    var description: String?
    var eventOrder: Int
    var isMainEvent: Bool
    var status: String
    var color: String?
    var dependsOnEventId: UUID?
    var durationMinutes: Int?
    var category: String
    var icon: String?
    var assignedVendorIds: [Int64]

    enum CodingKeys: String, CodingKey {
        case coupleId = "couple_id"
        case eventName = "event_name"
        case eventType = "event_type"
        case eventDate = "event_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case venueId = "venue_id"
        case venueName = "venue_name"
        case venueLocation = "venue_location"
        case notes
        case description
        case eventOrder = "event_order"
        case isMainEvent = "is_main_event"
        case status
        case color
        case dependsOnEventId = "depends_on_event_id"
        case durationMinutes = "duration_minutes"
        case category
        case icon
        case assignedVendorIds = "assigned_vendor_ids"
    }

    init(
        coupleId: UUID,
        eventName: String,
        eventType: String = "wedding",
        eventDate: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        venueId: Int64? = nil,
        venueName: String? = nil,
        venueLocation: String? = nil,
        notes: String? = nil,
        description: String? = nil,
        eventOrder: Int = 1,
        isMainEvent: Bool = false,
        status: WeddingDayEventStatus = .pending,
        color: String? = nil,
        dependsOnEventId: UUID? = nil,
        durationMinutes: Int? = nil,
        category: WeddingDayEventCategory = .other,
        icon: String? = nil,
        assignedVendorIds: [Int64] = []
    ) {
        self.coupleId = coupleId
        self.eventName = eventName
        self.eventType = eventType
        self.eventDate = eventDate
        self.startTime = startTime
        self.endTime = endTime
        self.venueId = venueId
        self.venueName = venueName
        self.venueLocation = venueLocation
        self.notes = notes
        self.description = description
        self.eventOrder = eventOrder
        self.isMainEvent = isMainEvent
        self.status = status.rawValue
        self.color = color
        self.dependsOnEventId = dependsOnEventId
        self.durationMinutes = durationMinutes
        self.category = category.rawValue
        self.icon = icon
        self.assignedVendorIds = assignedVendorIds
    }
}
