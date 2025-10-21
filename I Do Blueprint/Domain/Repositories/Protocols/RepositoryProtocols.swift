//
//  RepositoryProtocols.swift
//  I Do Blueprint
//
//  Repository protocols that haven't been split into separate files yet
//

import Foundation

// MARK: - Couple Repository Protocol

/// Protocol for couple/membership-related data operations
///
/// This protocol defines operations for managing couple memberships and user associations.
///
/// ## Note
/// Budget, Guest, and Vendor protocols have been moved to separate files:
/// - See `BudgetRepositoryProtocol.swift`
/// - See `GuestRepositoryProtocol.swift`
/// - See `VendorRepositoryProtocol.swift`
///
/// Other protocols are in their own files:
/// - `NotesRepositoryProtocol.swift`
/// - `TaskRepositoryProtocol.swift`
/// - `TimelineRepositoryProtocol.swift`
/// - `DocumentRepositoryProtocol.swift`
/// - `SettingsRepositoryProtocol.swift`
/// - `VisualPlanningRepositoryProtocol.swift`
protocol CoupleRepositoryProtocol: Sendable {
    /// Fetches all couple memberships for a specific user
    ///
    /// Returns all couples that the user is a member of, allowing
    /// the user to switch between different wedding planning contexts.
    ///
    /// - Parameter userId: The UUID of the user
    /// - Returns: Array of couple memberships
    /// - Throws: Repository errors if fetch fails
    func fetchCouplesForUser(userId: UUID) async throws -> [CoupleMembership]
}
