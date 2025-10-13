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
struct WeddingEventDB: Codable {
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

    enum CodingKeys: String, CodingKey {
        case id
        case eventName = "event_name"
        case eventType = "event_type"
        case eventDate = "event_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case venueId = "venue_id"
        case venueName = "venue_name"
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
        case venueLocation = "venue_location"
        case eventTime = "event_time"
        case coupleId = "couple_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
