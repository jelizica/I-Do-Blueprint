//
//  GuestRepositoryProtocol.swift
//  I Do Blueprint
//
//  Created as part of JES-43: Create Missing Repository Protocols
//  Protocol for guest-related data operations
//

import Foundation

/// Protocol for guest-related data operations
///
/// This protocol defines the contract for all guest management operations including:
/// - CRUD operations for guest records
/// - Guest statistics and analytics
/// - Search and filtering capabilities
///
/// ## Implementation Requirements
/// Implementations must handle:
/// - Multi-tenant data scoping (couple_id filtering)
/// - Proper error handling and propagation
/// - Cache invalidation on mutations
/// - Analytics tracking for performance monitoring
/// - RSVP status tracking and updates
///
/// ## Thread Safety
/// All methods are async and can be called from any actor context.
/// The protocol conforms to `Sendable` for safe concurrent access.
///
/// ## Error Handling
/// Methods throw errors for:
/// - Network failures
/// - Database errors
/// - Authentication/authorization failures
/// - Validation errors (e.g., duplicate guests, invalid email)
/// - Missing tenant context
///
/// ## Usage Example
/// ```swift
/// @Dependency(\.guestRepository) var repository
///
/// // Fetch all guests
/// let guests = try await repository.fetchGuests()
///
/// // Create a new guest
/// let newGuest = Guest(fullName: "John Doe", email: "john@example.com", ...)
/// let created = try await repository.createGuest(newGuest)
///
/// // Update RSVP status
/// var updated = created
/// updated.rsvpStatus = .confirmed
/// try await repository.updateGuest(updated)
/// ```
protocol GuestRepositoryProtocol: Sendable {

    // MARK: - Fetch Operations

    /// Fetches all guests for the current couple
    ///
    /// Returns guests sorted by creation date (newest first).
    /// Results are automatically scoped to the current couple's tenant ID.
    ///
    /// - Returns: Array of guest records
    /// - Throws: Repository errors if fetch fails or tenant context is missing
    func fetchGuests() async throws -> [Guest]


    /// Fetches guest statistics for the current couple
    ///
    /// Calculates aggregate statistics including:
    /// - Total guest count
    /// - Attending/confirmed count
    /// - Pending/invited count
    /// - Declined count
    /// - RSVP response rate percentage
    ///
    /// - Returns: Guest statistics object
    /// - Throws: Repository errors if fetch fails
    func fetchGuestStats() async throws -> GuestStats

    // MARK: - Create, Update, Delete Operations

    /// Creates a new guest record
    ///
    /// The guest will be automatically associated with the current couple's tenant ID.
    /// Server will assign ID and timestamps.
    ///
    /// - Parameter guest: The guest to create
    /// - Returns: The created guest with server-assigned ID and timestamps
    /// - Throws: Repository errors if creation fails, validation errors, or duplicate email
    func createGuest(_ guest: Guest) async throws -> Guest

    /// Updates an existing guest record
    ///
    /// Updates the guest and sets the `updatedAt` timestamp.
    /// Only guests belonging to the current couple can be updated.
    ///
    /// - Parameter guest: The guest with updated values
    /// - Returns: The updated guest with new timestamp
    /// - Throws: Repository errors if update fails, guest not found, or unauthorized
    func updateGuest(_ guest: Guest) async throws -> Guest

    /// Deletes a guest record
    ///
    /// Permanently removes the guest from the database.
    /// Only guests belonging to the current couple can be deleted.
    ///
    /// - Parameter id: The UUID of the guest to delete
    /// - Throws: Repository errors if deletion fails, guest not found, or unauthorized
    func deleteGuest(id: UUID) async throws

    // MARK: - Search Operations

    /// Searches guests by query string
    ///
    /// Searches across multiple fields:
    /// - Full name (case-insensitive)
    /// - Email address (case-insensitive)
    /// - Phone number
    ///
    /// Returns empty array if query is empty.
    ///
    /// - Parameter query: The search query string
    /// - Returns: Array of matching guests
    /// - Throws: Repository errors if search fails
    func searchGuests(query: String) async throws -> [Guest]

    // MARK: - Batch Import Operations

    /// Imports multiple guests in a single batch operation
    ///
    /// Performs a batch insert of guest records with proper error handling.
    /// The `couple_id` is automatically populated from the current session.
    /// Server will assign IDs and timestamps for each guest.
    ///
    /// This method is optimized for importing large numbers of guests (e.g., from CSV).
    /// It uses a single database transaction for better performance.
    ///
    /// - Parameter guests: Array of guests to import
    /// - Returns: Array of created guests with server-assigned IDs and timestamps
    /// - Throws: Repository errors if import fails, validation errors, or duplicate emails
    func importGuests(_ guests: [Guest]) async throws -> [Guest]
}
