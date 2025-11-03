//
//  PresenceRepositoryProtocol.swift
//  I Do Blueprint
//
//  Protocol for presence tracking operations
//

import Foundation

/// Protocol for presence tracking operations
///
/// This protocol defines the contract for real-time presence management including:
/// - Tracking user presence (online/away/offline)
/// - Heartbeat mechanism
/// - Current view and editing state
/// - Session management
///
/// ## Implementation Requirements
/// Implementations must handle:
/// - Multi-tenant data scoping (couple_id filtering)
/// - Automatic cleanup of stale presence (>5 minutes)
/// - Real-time broadcasting of presence changes
/// - Session-based tracking
///
/// ## Thread Safety
/// All methods are async and can be called from any actor context.
/// The protocol conforms to `Sendable` for safe concurrent access.
protocol PresenceRepositoryProtocol: Sendable {

    // MARK: - Fetch Operations

    /// Fetches all active presence records for the current couple
    ///
    /// Returns only non-stale presence records (heartbeat within last 5 minutes).
    /// Results are automatically scoped to the current couple's tenant ID.
    ///
    /// - Returns: Array of active presence records
    /// - Throws: Repository errors if fetch fails or tenant context is missing
    func fetchActivePresence() async throws -> [Presence]

    /// Fetches presence for a specific user
    ///
    /// - Parameter userId: The user ID
    /// - Returns: The user's presence if found
    /// - Throws: Repository errors if fetch fails
    func fetchPresence(userId: UUID) async throws -> Presence?

    // MARK: - Presence Management

    /// Tracks presence for the current user
    ///
    /// Creates or updates presence record with current status and location.
    /// Automatically updates heartbeat timestamp.
    ///
    /// - Parameters:
    ///   - status: The presence status (online/away/offline)
    ///   - currentView: Optional current view name
    ///   - currentResourceType: Optional resource type being viewed
    ///   - currentResourceId: Optional resource ID being viewed
    /// - Returns: The updated presence record
    /// - Throws: Repository errors if operation fails
    func trackPresence(
        status: PresenceStatus,
        currentView: String?,
        currentResourceType: String?,
        currentResourceId: UUID?
    ) async throws -> Presence

    /// Updates editing state for the current user
    ///
    /// Marks the user as currently editing a specific resource.
    ///
    /// - Parameters:
    ///   - isEditing: Whether user is editing
    ///   - resourceType: Optional resource type being edited
    ///   - resourceId: Optional resource ID being edited
    /// - Returns: The updated presence record
    /// - Throws: Repository errors if operation fails
    func updateEditingState(
        isEditing: Bool,
        resourceType: String?,
        resourceId: UUID?
    ) async throws -> Presence

    /// Sends a heartbeat to keep presence alive
    ///
    /// Updates the last_heartbeat timestamp to prevent cleanup.
    /// Should be called periodically (every 30-60 seconds).
    ///
    /// - Returns: The updated presence record
    /// - Throws: Repository errors if operation fails
    func sendHeartbeat() async throws -> Presence

    /// Stops tracking presence for the current user
    ///
    /// Sets status to offline and stops heartbeat.
    ///
    /// - Throws: Repository errors if operation fails
    func stopTracking() async throws

    // MARK: - Cleanup

    /// Manually triggers cleanup of stale presence records
    ///
    /// Removes presence records with no heartbeat in last 5 minutes.
    /// This is normally handled automatically by pg_cron.
    ///
    /// - Returns: Number of records cleaned up
    /// - Throws: Repository errors if operation fails
    func cleanupStalePresence() async throws -> Int
}
