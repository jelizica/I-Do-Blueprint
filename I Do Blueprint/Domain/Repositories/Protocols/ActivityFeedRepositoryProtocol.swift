//
//  ActivityFeedRepositoryProtocol.swift
//  I Do Blueprint
//
//  Protocol for activity feed operations
//

import Foundation

/// Protocol for activity feed operations
///
/// This protocol defines the contract for activity feed management including:
/// - Fetching activity events
/// - Filtering and pagination
/// - Mark as read functionality
/// - Real-time activity updates
///
/// ## Implementation Requirements
/// Implementations must handle:
/// - Multi-tenant data scoping (couple_id filtering)
/// - Proper error handling and propagation
/// - Cache invalidation on mutations
/// - Real-time broadcasting of new activities
///
/// ## Thread Safety
/// All methods are async and can be called from any actor context.
/// The protocol conforms to `Sendable` for safe concurrent access.
protocol ActivityFeedRepositoryProtocol: Sendable {
    
    // MARK: - Fetch Operations
    
    /// Fetches recent activity events for the current couple
    ///
    /// Returns activities sorted by creation date (newest first).
    /// Results are automatically scoped to the current couple's tenant ID.
    ///
    /// - Parameters:
    ///   - limit: Maximum number of activities to return (default: 50)
    ///   - offset: Number of activities to skip for pagination (default: 0)
    /// - Returns: Array of activity events
    /// - Throws: Repository errors if fetch fails or tenant context is missing
    func fetchActivities(limit: Int, offset: Int) async throws -> [ActivityEvent]
    
    /// Fetches activities filtered by action type
    ///
    /// - Parameters:
    ///   - actionType: The action type to filter by
    ///   - limit: Maximum number of activities to return
    /// - Returns: Array of filtered activity events
    /// - Throws: Repository errors if fetch fails
    func fetchActivities(actionType: ActionType, limit: Int) async throws -> [ActivityEvent]
    
    /// Fetches activities filtered by resource type
    ///
    /// - Parameters:
    ///   - resourceType: The resource type to filter by
    ///   - limit: Maximum number of activities to return
    /// - Returns: Array of filtered activity events
    /// - Throws: Repository errors if fetch fails
    func fetchActivities(resourceType: ResourceType, limit: Int) async throws -> [ActivityEvent]
    
    /// Fetches activities for a specific actor (user)
    ///
    /// - Parameters:
    ///   - actorId: The user ID who performed the actions
    ///   - limit: Maximum number of activities to return
    /// - Returns: Array of activity events by the actor
    /// - Throws: Repository errors if fetch fails
    func fetchActivities(actorId: UUID, limit: Int) async throws -> [ActivityEvent]
    
    /// Fetches unread activity count for the current user
    ///
    /// - Returns: Number of unread activities
    /// - Throws: Repository errors if fetch fails
    func fetchUnreadCount() async throws -> Int
    
    // MARK: - Update Operations
    
    /// Marks an activity as read
    ///
    /// - Parameter id: The activity event ID
    /// - Returns: The updated activity event
    /// - Throws: Repository errors if update fails
    func markAsRead(id: UUID) async throws -> ActivityEvent
    
    /// Marks all activities as read for the current user
    ///
    /// - Returns: Number of activities marked as read
    /// - Throws: Repository errors if update fails
    func markAllAsRead() async throws -> Int
    
    // MARK: - Statistics
    
    /// Fetches activity statistics for the current couple
    ///
    /// Returns counts by action type and resource type.
    ///
    /// - Returns: Activity statistics
    /// - Throws: Repository errors if fetch fails
    func fetchActivityStats() async throws -> ActivityStats
}

/// Activity statistics
struct ActivityStats: Codable, Sendable {
    let totalActivities: Int
    let activitiesByAction: [ActionType: Int]
    let activitiesByResource: [ResourceType: Int]
    let recentActivityCount: Int // Last 24 hours
    
    enum CodingKeys: String, CodingKey {
        case totalActivities = "total_activities"
        case activitiesByAction = "activities_by_action"
        case activitiesByResource = "activities_by_resource"
        case recentActivityCount = "recent_activity_count"
    }
}

// MARK: - Test Helpers

extension ActivityStats {
    static func makeTest(
        totalActivities: Int = 0,
        activitiesByAction: [ActionType: Int] = [:],
        activitiesByResource: [ResourceType: Int] = [:],
        recentActivityCount: Int = 0
    ) -> ActivityStats {
        ActivityStats(
            totalActivities: totalActivities,
            activitiesByAction: activitiesByAction,
            activitiesByResource: activitiesByResource,
            recentActivityCount: recentActivityCount
        )
    }
}
