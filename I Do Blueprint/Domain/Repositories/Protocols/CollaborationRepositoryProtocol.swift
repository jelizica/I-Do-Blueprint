//
//  CollaborationRepositoryProtocol.swift
//  I Do Blueprint
//
//  Protocol for collaboration-related data operations
//

import Foundation

/// Protocol for collaboration-related data operations
///
/// This protocol defines the contract for all collaboration management operations including:
/// - CRUD operations for collaborators
/// - Role management
/// - Invitation workflow
/// - Permission checks
///
/// ## Implementation Requirements
/// Implementations must handle:
/// - Multi-tenant data scoping (couple_id filtering)
/// - Proper error handling and propagation
/// - Cache invalidation on mutations
/// - Analytics tracking for performance monitoring
///
/// ## Thread Safety
/// All methods are async and can be called from any actor context.
/// The protocol conforms to `Sendable` for safe concurrent access.
protocol CollaborationRepositoryProtocol: Sendable {
    
    // MARK: - Fetch Operations
    
    /// Fetches all collaborators for the current couple
    ///
    /// Returns collaborators sorted by creation date (newest first).
    /// Results are automatically scoped to the current couple's tenant ID.
    ///
    /// - Returns: Array of collaborator records
    /// - Throws: Repository errors if fetch fails or tenant context is missing
    func fetchCollaborators() async throws -> [Collaborator]
    
    /// Fetches all available collaboration roles
    ///
    /// Returns system-defined roles (owner, partner, planner, viewer).
    ///
    /// - Returns: Array of collaboration roles
    /// - Throws: Repository errors if fetch fails
    func fetchRoles() async throws -> [CollaborationRole]
    
    /// Fetches a specific collaborator by ID
    ///
    /// - Parameter id: The UUID of the collaborator
    /// - Returns: The collaborator if found
    /// - Throws: Repository errors if fetch fails or collaborator not found
    func fetchCollaborator(id: UUID) async throws -> Collaborator
    
    /// Fetches the current user's collaborator record for the couple
    ///
    /// - Returns: The current user's collaborator record, or nil if user is not a collaborator
    /// - Throws: Repository errors if fetch fails
    func fetchCurrentUserCollaborator() async throws -> Collaborator?
    
    /// Fetches all collaborations for the current user across all couples
    ///
    /// Returns collaborations sorted by wedding date (soonest first).
    /// Includes both active and pending collaborations.
    ///
    /// - Returns: Array of user's collaborations with couple details
    /// - Throws: Repository errors if fetch fails
    func fetchUserCollaborations() async throws -> [UserCollaboration]

    /// Fetches an invitation by token
    ///
    /// Used for deep link invitation acceptance flow.
    ///
    /// - Parameter token: The invitation token from the deep link
    /// - Returns: The invitation details including couple_id, role, and collaborator info
    /// - Throws: Repository errors if invitation not found or expired
    func fetchInvitationByToken(_ token: String) async throws -> InvitationDetails

    // MARK: - Create, Update, Delete Operations
    
    /// Invites a new collaborator
    ///
    /// Creates a collaborator record with pending status.
    /// The collaborator will be automatically associated with the current couple's tenant ID.
    ///
    /// - Parameters:
    ///   - email: Email address of the person to invite
    ///   - roleId: The role ID to assign
    ///   - displayName: Optional display name
    /// - Returns: The created collaborator with pending status
    /// - Throws: Repository errors if creation fails or user lacks permission
    func inviteCollaborator(email: String, roleId: UUID, displayName: String?) async throws -> Collaborator
    
    /// Accepts a collaboration invitation
    ///
    /// Updates the collaborator status from pending to active.
    ///
    /// - Parameter id: The collaborator ID
    /// - Returns: The updated collaborator with active status
    /// - Throws: Repository errors if update fails or invitation not found
    func acceptInvitation(id: UUID) async throws -> Collaborator
    
    /// Updates a collaborator's role
    ///
    /// Only users with manage_roles permission can update roles.
    ///
    /// - Parameters:
    ///   - id: The collaborator ID
    ///   - roleId: The new role ID
    /// - Returns: The updated collaborator
    /// - Throws: Repository errors if update fails or user lacks permission
    func updateCollaboratorRole(id: UUID, roleId: UUID) async throws -> Collaborator
    
    /// Removes a collaborator
    ///
    /// Only users with manage_roles permission can remove collaborators.
    /// Cannot remove the last owner.
    ///
    /// - Parameter id: The collaborator ID to remove
    /// - Throws: Repository errors if deletion fails or user lacks permission
    func removeCollaborator(id: UUID) async throws
    
    /// Allows user to leave a collaboration (remove themselves)
    ///
    /// User can only leave if they are not the last owner.
    ///
    /// - Parameter coupleId: The couple ID to leave
    /// - Throws: Repository errors if removal fails or user is last owner
    func leaveCollaboration(coupleId: UUID) async throws
    
    /// Declines a pending invitation
    ///
    /// Updates collaborator status from pending to declined.
    ///
    /// - Parameter id: The collaborator ID
    /// - Throws: Repository errors if update fails
    func declineInvitation(id: UUID) async throws
    
    // MARK: - Permission Checks
    
    /// Checks if the current user has a specific permission
    ///
    /// - Parameter permission: The permission to check (can_edit, can_delete, can_invite, can_manage_roles)
    /// - Returns: True if user has the permission
    /// - Throws: Repository errors if check fails
    func hasPermission(_ permission: String) async throws -> Bool
    
    /// Gets the current user's role name
    ///
    /// - Returns: The role name (owner, partner, planner, viewer), or nil if user is not a collaborator
    /// - Throws: Repository errors if fetch fails
    func getCurrentUserRole() async throws -> RoleName?
    
    // MARK: - Onboarding Support
    
    /// Creates an owner collaborator record during onboarding
    ///
    /// This method is called automatically when a user completes onboarding and creates their couple profile.
    /// It creates an active collaborator record with the owner role, allowing the user to immediately
    /// access collaboration features and invite other collaborators.
    ///
    /// The method is idempotent - if an owner collaborator already exists for the user, it returns
    /// the existing record without creating a duplicate.
    ///
    /// - Parameters:
    ///   - coupleId: The UUID of the couple profile
    ///   - userId: The UUID of the user (from auth.users)
    ///   - email: The user's email address
    ///   - displayName: Optional display name (typically partner name from onboarding)
    /// - Returns: The created or existing owner collaborator record
    /// - Throws: Repository errors if creation fails
    func createOwnerCollaborator(
        coupleId: UUID,
        userId: UUID,
        email: String,
        displayName: String?
    ) async throws -> Collaborator
}
