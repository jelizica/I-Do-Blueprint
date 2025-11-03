//
//  Presence.swift
//  I Do Blueprint
//
//  Real-time presence tracking model
//

import Foundation

/// Represents a user's real-time presence
struct Presence: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    let coupleId: UUID
    let userId: UUID
    let sessionId: String
    var status: PresenceStatus
    var currentView: String?
    var currentResourceType: String?
    var currentResourceId: UUID?
    var isEditing: Bool
    var editingResourceType: String?
    var editingResourceId: UUID?
    var lastHeartbeat: Date
    var metadata: [String: String]

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case coupleId = "couple_id"
        case userId = "user_id"
        case sessionId = "session_id"
        case status
        case currentView = "current_view"
        case currentResourceType = "current_resource_type"
        case currentResourceId = "current_resource_id"
        case isEditing = "is_editing"
        case editingResourceType = "editing_resource_type"
        case editingResourceId = "editing_resource_id"
        case lastHeartbeat = "last_heartbeat"
        case metadata
    }

    /// Check if presence is stale (no heartbeat in last 5 minutes)
    var isStale: Bool {
        Date().timeIntervalSince(lastHeartbeat) > 300 // 5 minutes
    }

    /// Check if user is currently online
    var isOnline: Bool {
        status == .online && !isStale
    }
}

/// Presence status
enum PresenceStatus: String, Codable, Sendable {
    case online
    case away
    case offline
}

// MARK: - Test Helpers

extension Presence {
    /// Creates a test presence with default values
    static func makeTest(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        coupleId: UUID = UUID(),
        userId: UUID = UUID(),
        sessionId: String = UUID().uuidString,
        status: PresenceStatus = .online,
        currentView: String? = nil,
        currentResourceType: String? = nil,
        currentResourceId: UUID? = nil,
        isEditing: Bool = false,
        editingResourceType: String? = nil,
        editingResourceId: UUID? = nil,
        lastHeartbeat: Date = Date(),
        metadata: [String: String] = [:]
    ) -> Presence {
        Presence(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            coupleId: coupleId,
            userId: userId,
            sessionId: sessionId,
            status: status,
            currentView: currentView,
            currentResourceType: currentResourceType,
            currentResourceId: currentResourceId,
            isEditing: isEditing,
            editingResourceType: editingResourceType,
            editingResourceId: editingResourceId,
            lastHeartbeat: lastHeartbeat,
            metadata: metadata
        )
    }
}
