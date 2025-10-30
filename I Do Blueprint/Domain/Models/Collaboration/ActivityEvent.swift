//
//  ActivityEvent.swift
//  I Do Blueprint
//
//  Activity feed event model
//

import Foundation

/// Represents an activity event in the activity feed
struct ActivityEvent: Identifiable, Codable, Sendable {
    let id: UUID
    let createdAt: Date
    let coupleId: UUID
    let actorId: UUID
    let actionType: ActionType
    let resourceType: ResourceType
    let resourceId: UUID?
    let resourceName: String?
    let changes: [String: AnyCodable]?
    let metadata: [String: AnyCodable]?
    var isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case coupleId = "couple_id"
        case actorId = "actor_id"
        case actionType = "action_type"
        case resourceType = "resource_type"
        case resourceId = "resource_id"
        case resourceName = "resource_name"
        case changes
        case metadata
        case isRead = "is_read"
    }
    
    /// Human-readable description of the activity
    var description: String {
        let action = actionType.displayName
        let resource = resourceType.displayName
        let name = resourceName ?? "item"
        return "\(action) \(resource): \(name)"
    }
}

/// Activity action types
enum ActionType: String, Codable, Sendable {
    case created
    case updated
    case deleted
    case viewed
    case commented
    case invited
    case joined
    case left
    
    var displayName: String {
        switch self {
        case .created: return "Created"
        case .updated: return "Updated"
        case .deleted: return "Deleted"
        case .viewed: return "Viewed"
        case .commented: return "Commented on"
        case .invited: return "Invited"
        case .joined: return "Joined"
        case .left: return "Left"
        }
    }
}

/// Resource types that can have activity events
enum ResourceType: String, Codable, Sendable {
    case guest
    case budgetCategory = "budget_category"
    case expense
    case vendor
    case task
    case document
    case timeline
    case seatingChart = "seating_chart"
    case collaborator
    
    var displayName: String {
        switch self {
        case .guest: return "guest"
        case .budgetCategory: return "budget category"
        case .expense: return "expense"
        case .vendor: return "vendor"
        case .task: return "task"
        case .document: return "document"
        case .timeline: return "timeline item"
        case .seatingChart: return "seating chart"
        case .collaborator: return "collaborator"
        }
    }
}

// MARK: - Test Helpers

extension ActivityEvent {
    /// Creates a test activity event with default values
    static func makeTest(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        coupleId: UUID = UUID(),
        actorId: UUID = UUID(),
        actionType: ActionType = .created,
        resourceType: ResourceType = .guest,
        resourceId: UUID? = UUID(),
        resourceName: String? = "Test Resource",
        changes: [String: AnyCodable]? = nil,
        metadata: [String: AnyCodable]? = nil,
        isRead: Bool = false
    ) -> ActivityEvent {
        ActivityEvent(
            id: id,
            createdAt: createdAt,
            coupleId: coupleId,
            actorId: actorId,
            actionType: actionType,
            resourceType: resourceType,
            resourceId: resourceId,
            resourceName: resourceName,
            changes: changes,
            metadata: metadata,
            isRead: isRead
        )
    }
}
