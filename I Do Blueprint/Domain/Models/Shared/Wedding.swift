//
//  Wedding.swift
//  My Wedding Planning App
//
//  Created by Jessica Clark on 9/27/25.
//

import Foundation

// Type alias for compatibility
typealias WeddingEvent = WeddingEventDB

extension WeddingEventDB {
    // Simple initializer for basic event creation
    init(id: String, eventName: String, eventDate: Date, eventType: String = "wedding", coupleId: String = "") {
        self.id = id
        self.eventName = eventName
        self.eventType = eventType
        self.eventDate = eventDate
        startTime = nil
        endTime = nil
        venueId = nil
        venueName = nil
        address = nil
        city = nil
        state = nil
        zipCode = nil
        guestCount = nil
        budgetAllocated = nil
        notes = nil
        isConfirmed = nil
        description = nil
        eventOrder = nil
        isMainEvent = nil
        venueLocation = nil
        eventTime = nil
        self.coupleId = coupleId
        createdAt = nil
        updatedAt = nil
    }
}

// Database model that matches the wedding_events table schema
struct WeddingEventDB: Codable, Identifiable {
    let id: String
    let eventName: String
    let eventType: String
    let eventDate: Date
    let startTime: Date?
    let endTime: Date?
    let venueId: Int64?
    let venueName: String?
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let guestCount: Int?
    let budgetAllocated: Double?
    let notes: String?
    let isConfirmed: Bool?
    let description: String?
    let eventOrder: Int?
    let isMainEvent: Bool?
    let venueLocation: String?
    let eventTime: Date?
    let coupleId: String
    let createdAt: Date?
    let updatedAt: Date?
    
    // MARK: - Memberwise Initializer
    
    init(
        id: String,
        eventName: String,
        eventType: String,
        eventDate: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        venueId: Int64? = nil,
        venueName: String? = nil,
        address: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zipCode: String? = nil,
        guestCount: Int? = nil,
        budgetAllocated: Double? = nil,
        notes: String? = nil,
        isConfirmed: Bool? = nil,
        description: String? = nil,
        eventOrder: Int? = nil,
        isMainEvent: Bool? = nil,
        venueLocation: String? = nil,
        eventTime: Date? = nil,
        coupleId: String,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.eventName = eventName
        self.eventType = eventType
        self.eventDate = eventDate
        self.startTime = startTime
        self.endTime = endTime
        self.venueId = venueId
        self.venueName = venueName
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
        self.venueLocation = venueLocation
        self.eventTime = eventTime
        self.coupleId = coupleId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case eventName = "event_name"
        case eventType = "event_type"
        case eventDate = "event_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case venueId = "venue_id"
        case venueName = "venue_name"
        case address = "address"
        case city = "city"
        case state = "state"
        case zipCode = "zip_code"
        case guestCount = "guest_count"
        case budgetAllocated = "budget_allocated"
        case notes = "notes"
        case isConfirmed = "is_confirmed"
        case description = "description"
        case eventOrder = "event_order"
        case isMainEvent = "is_main_event"
        case venueLocation = "venue_location"
        case eventTime = "event_time"
        case coupleId = "couple_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Custom Codable Implementation
    
    // Custom encoder to handle TIME columns (start_time, end_time, event_time)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(eventName, forKey: .eventName)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(eventDate, forKey: .eventDate)
        
        // Encode time fields as HH:MM:SS strings for PostgreSQL TIME type
        if let startTime = startTime {
            try container.encode(formatTimeForDatabase(startTime), forKey: .startTime)
        } else {
            try container.encodeNil(forKey: .startTime)
        }
        
        if let endTime = endTime {
            try container.encode(formatTimeForDatabase(endTime), forKey: .endTime)
        } else {
            try container.encodeNil(forKey: .endTime)
        }
        
        try container.encodeIfPresent(venueId, forKey: .venueId)
        try container.encodeIfPresent(venueName, forKey: .venueName)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(zipCode, forKey: .zipCode)
        try container.encodeIfPresent(guestCount, forKey: .guestCount)
        try container.encodeIfPresent(budgetAllocated, forKey: .budgetAllocated)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(isConfirmed, forKey: .isConfirmed)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(eventOrder, forKey: .eventOrder)
        try container.encodeIfPresent(isMainEvent, forKey: .isMainEvent)
        try container.encodeIfPresent(venueLocation, forKey: .venueLocation)
        
        // Encode event_time as HH:MM:SS string
        if let eventTime = eventTime {
            try container.encode(formatTimeForDatabase(eventTime), forKey: .eventTime)
        } else {
            try container.encodeNil(forKey: .eventTime)
        }
        
        try container.encode(coupleId, forKey: .coupleId)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
    
    // Custom decoder to handle TIME columns and DATE column
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
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
            // Fallback: try decoding as Date directly (for backwards compatibility)
            eventDate = try container.decode(Date.self, forKey: .eventDate)
        }
        
        // Decode time strings back to Date objects
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
        
        venueId = try container.decodeIfPresent(Int64.self, forKey: .venueId)
        venueName = try container.decodeIfPresent(String.self, forKey: .venueName)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        zipCode = try container.decodeIfPresent(String.self, forKey: .zipCode)
        guestCount = try container.decodeIfPresent(Int.self, forKey: .guestCount)
        budgetAllocated = try container.decodeIfPresent(Double.self, forKey: .budgetAllocated)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        isConfirmed = try container.decodeIfPresent(Bool.self, forKey: .isConfirmed)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        eventOrder = try container.decodeIfPresent(Int.self, forKey: .eventOrder)
        isMainEvent = try container.decodeIfPresent(Bool.self, forKey: .isMainEvent)
        venueLocation = try container.decodeIfPresent(String.self, forKey: .venueLocation)
        
        if let eventTimeString = try container.decodeIfPresent(String.self, forKey: .eventTime) {
            eventTime = Self.parseTimeFromDatabase(eventTimeString)
        } else {
            eventTime = nil
        }
        
        coupleId = try container.decode(String.self, forKey: .coupleId)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
    
    // MARK: - Helper Methods
    
    /// Formats a Date object as HH:MM:SS for PostgreSQL TIME type
    private func formatTimeForDatabase(_ date: Date) -> String {
        Self.formatTimeForDatabase(date)
    }
    
    /// Formats a Date object as HH:MM:SS for PostgreSQL TIME type (static version)
    private static func formatTimeForDatabase(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    /// Parses a HH:MM:SS string from database into a Date object (using today's date)
    private static func parseTimeFromDatabase(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone.current
        
        // Try parsing with seconds
        if let time = formatter.date(from: timeString) {
            return time
        }
        
        // Fallback: try HH:mm format
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }
    
    /// Parses a YYYY-MM-DD string from database into a Date object
    private static func parseDateFromDatabase(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }
}
