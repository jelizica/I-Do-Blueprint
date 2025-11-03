//
//  CollaborationStoreV2.swift
//  I Do Blueprint
//
//  Collaboration management store using repository pattern
//

import Combine
import Dependencies
import Foundation
import SwiftUI

/// Collaboration management store for handling collaborators, roles, and permissions
@MainActor
class CollaborationStoreV2: ObservableObject {
    @Published var loadingState: LoadingState<[Collaborator]> = .idle
    @Published private(set) var roles: [CollaborationRole] = []
    @Published private(set) var currentUserRole: RoleName?
    @Published private(set) var currentUserCollaborator: Collaborator?

    @Published var showSuccessToast = false
    @Published var successMessage = ""

    // My Collaborations state
    @Published var userCollaborations: [UserCollaboration] = []
    @Published var pendingUserInvitations: [UserCollaboration] = []
    @Published var isLoadingCollaborations = false
    @Published var collaborationsError: Error?

    @Dependency(\.collaborationRepository) var repository

    // MARK: - Computed Properties

    var collaborators: [Collaborator] {
        loadingState.data ?? []
    }

    var isLoading: Bool {
        loadingState.isLoading
    }

    var error: CollaborationError? {
        if case .error(let err) = loadingState {
            return err as? CollaborationError ?? .fetchFailed(underlying: err)
        }
        return nil
    }

    var activeCollaborators: [Collaborator] {
        collaborators.filter { $0.status == .active }
    }

    var pendingInvitations: [Collaborator] {
        collaborators.filter { $0.status == .pending }
    }

    // MARK: - Permissions

    var canInvite: Bool {
        currentUserRole == .owner || currentUserRole == .partner
    }

    var canManageRoles: Bool {
        currentUserRole == .owner
    }

    var canEdit: Bool {
        currentUserRole == .owner || currentUserRole == .partner || currentUserRole == .planner
    }

    // MARK: - Public Interface

    func loadCollaborationData() async {
        // Only load if idle or error state
        guard loadingState.isIdle || loadingState.hasError else {
            return
        }

        loadingState = .loading

        do {
            async let collaboratorsResult = repository.fetchCollaborators()
            async let rolesResult = repository.fetchRoles()
            async let currentUserResult = repository.fetchCurrentUserCollaborator()
            async let roleResult = repository.getCurrentUserRole()

            let fetchedCollaborators = try await collaboratorsResult
            roles = try await rolesResult
            currentUserCollaborator = try await currentUserResult
            currentUserRole = try await roleResult

            loadingState = .loaded(fetchedCollaborators)
        } catch {
            loadingState = .error(CollaborationError.fetchFailed(underlying: error))
        }
    }

    func inviteCollaborator(email: String, roleId: UUID, displayName: String?) async {
        // Add breadcrumb for debugging
        addOperationBreadcrumb(
            "inviteCollaborator",
            category: "collaboration",
            data: ["email": email]
        )

        do {
            let created = try await repository.inviteCollaborator(
                email: email,
                roleId: roleId,
                displayName: displayName
            )

            // Update loaded state with new collaborator
            if case .loaded(var currentCollaborators) = loadingState {
                currentCollaborators.append(created)
                loadingState = .loaded(currentCollaborators)
            }

            // Show success feedback
            HapticFeedback.itemAdded()
            showSuccess("Invitation sent to \(email)")
        } catch {
            loadingState = .error(CollaborationError.createFailed(underlying: error))
            await handleError(
                error,
                operation: "invite collaborator",
                context: ["email": email]
            ) { [weak self] in
                await self?.inviteCollaborator(email: email, roleId: roleId, displayName: displayName)
            }
        }
    }

    func acceptInvitation(id: UUID) async {
        // Add breadcrumb for debugging
        addOperationBreadcrumb(
            "acceptInvitation",
            category: "collaboration",
            data: ["collaboratorId": id.uuidString]
        )

        // Optimistic update
        guard case .loaded(var currentCollaborators) = loadingState,
              let index = currentCollaborators.firstIndex(where: { $0.id == id }) else {
            return
        }

        let original = currentCollaborators[index]
        var updated = original
        updated.status = .active
        updated.acceptedAt = Date()
        currentCollaborators[index] = updated
        loadingState = .loaded(currentCollaborators)

        do {
            let accepted = try await repository.acceptInvitation(id: id)

            if case .loaded(var collaborators) = loadingState,
               let idx = collaborators.firstIndex(where: { $0.id == id }) {
                collaborators[idx] = accepted
                loadingState = .loaded(collaborators)
            }

            showSuccess("Invitation accepted")
        } catch {
            // Rollback on error
            if case .loaded(var collaborators) = loadingState,
               let idx = collaborators.firstIndex(where: { $0.id == id }) {
                collaborators[idx] = original
                loadingState = .loaded(collaborators)
            }
            loadingState = .error(CollaborationError.updateFailed(underlying: error))
            await handleError(
                error,
                operation: "accept invitation",
                context: ["collaboratorId": id.uuidString]
            ) { [weak self] in
                await self?.acceptInvitation(id: id)
            }
        }
    }

    func updateCollaboratorRole(id: UUID, roleId: UUID) async {
        // Add breadcrumb for debugging
        addOperationBreadcrumb(
            "updateCollaboratorRole",
            category: "collaboration",
            data: ["collaboratorId": id.uuidString]
        )

        do {
            let updatedCollaborator = try await repository.updateCollaboratorRole(id: id, roleId: roleId)

            // Update in loaded state
            if case .loaded(var collaborators) = loadingState,
               let idx = collaborators.firstIndex(where: { $0.id == id }) {
                collaborators[idx] = updatedCollaborator
                loadingState = .loaded(collaborators)
            }

            showSuccess("Role updated successfully")
        } catch {
            loadingState = .error(CollaborationError.updateFailed(underlying: error))
            await handleError(
                error,
                operation: "update role",
                context: ["collaboratorId": id.uuidString]
            ) { [weak self] in
                await self?.updateCollaboratorRole(id: id, roleId: roleId)
            }
        }
    }

    func removeCollaborator(id: UUID) async {
        // Add breadcrumb for debugging
        addOperationBreadcrumb(
            "removeCollaborator",
            category: "collaboration",
            data: ["collaboratorId": id.uuidString]
        )

        // Optimistic delete
        guard case .loaded(var currentCollaborators) = loadingState,
              let index = currentCollaborators.firstIndex(where: { $0.id == id }) else {
            return
        }

        let removed = currentCollaborators.remove(at: index)
        loadingState = .loaded(currentCollaborators)

        do {
            try await repository.removeCollaborator(id: id)
            showSuccess("Collaborator removed")
        } catch {
            // Restore on error
            if case .loaded(var collaborators) = loadingState {
                collaborators.insert(removed, at: index)
                loadingState = .loaded(collaborators)
            }
            loadingState = .error(CollaborationError.deleteFailed(underlying: error))
            await handleError(
                error,
                operation: "remove collaborator",
                context: ["collaboratorId": id.uuidString]
            ) { [weak self] in
                await self?.removeCollaborator(id: id)
            }
        }
    }

    func checkPermission(_ permission: String) async -> Bool {
        do {
            return try await repository.hasPermission(permission)
        } catch {
            return false
        }
    }

    func getRoleForId(_ roleId: UUID) -> CollaborationRole? {
        roles.first(where: { $0.id == roleId })
    }

    // MARK: - My Collaborations

    /// Load all collaborations for current user across all couples
    func loadUserCollaborations() async {
        // Defer loading state update to avoid "Publishing during view updates"
        await MainActor.run {
            isLoadingCollaborations = true
            collaborationsError = nil
        }

        addOperationBreadcrumb(
            "loadUserCollaborations",
            category: "collaboration",
            data: [:]
        )

        do {
            let collaborations = try await repository.fetchUserCollaborations()

            // Defer data updates to next run loop to avoid "Publishing during view updates"
            await MainActor.run {
                // Split into active and pending
                userCollaborations = collaborations.filter { $0.status == .active }
                pendingUserInvitations = collaborations.filter { $0.status == .pending }
                isLoadingCollaborations = false
            }

            AppLogger.ui.info("Loaded \(userCollaborations.count) active collaborations, \(pendingUserInvitations.count) pending")
        } catch {
            // Defer error state update
            await MainActor.run {
                collaborationsError = error
                isLoadingCollaborations = false
            }

            AppLogger.ui.error("Failed to load user collaborations", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "loadUserCollaborations"
            ])
        }
    }

    /// Leave a collaboration (remove self from a couple)
    func leaveCollaboration(coupleId: UUID) async throws {
        addOperationBreadcrumb(
            "leaveCollaboration",
            category: "collaboration",
            data: ["coupleId": coupleId.uuidString]
        )

        do {
            try await repository.leaveCollaboration(coupleId: coupleId)

            // Defer state update to avoid "Publishing during view updates"
            await MainActor.run {
                // Remove from local state
                userCollaborations.removeAll { $0.coupleId == coupleId }
            }

            AppLogger.ui.info("Left collaboration for couple: \(coupleId)")

            await SentryService.shared.trackAction(
                "collaboration_left",
                category: "collaboration",
                metadata: ["couple_id": coupleId.uuidString]
            )

            showSuccess("You have left the wedding")
            HapticFeedback.itemDeleted()
        } catch {
            AppLogger.ui.error("Failed to leave collaboration", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "leaveCollaboration",
                "coupleId": coupleId.uuidString
            ])
            throw error
        }
    }

    /// Decline a pending invitation
    func declineInvitation(id: UUID) async throws {
        addOperationBreadcrumb(
            "declineInvitation",
            category: "collaboration",
            data: ["invitationId": id.uuidString]
        )

        do {
            try await repository.declineInvitation(id: id)

            // Defer state update to avoid "Publishing during view updates"
            await MainActor.run {
                // Remove from pending invitations
                pendingUserInvitations.removeAll { $0.id == id }
            }

            AppLogger.ui.info("Declined invitation: \(id)")

            await SentryService.shared.trackAction(
                "invitation_declined",
                category: "collaboration",
                metadata: ["invitation_id": id.uuidString]
            )

            showSuccess("Invitation declined")
            HapticFeedback.selectionChanged()
        } catch {
            AppLogger.ui.error("Failed to decline invitation", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "declineInvitation",
                "invitationId": id.uuidString
            ])
            throw error
        }
    }

    /// Accept a pending invitation from My Collaborations view
    func acceptUserInvitation(id: UUID) async throws {
        addOperationBreadcrumb(
            "acceptUserInvitation",
            category: "collaboration",
            data: ["invitationId": id.uuidString]
        )

        do {
            let accepted = try await repository.acceptInvitation(id: id)

            // Defer state updates to avoid "Publishing during view updates"
            await MainActor.run {
                // Move from pending to active
                if let index = pendingUserInvitations.firstIndex(where: { $0.id == id }) {
                    let invitation = pendingUserInvitations.remove(at: index)

                    // Create active collaboration from accepted invitation
                    let activeCollaboration = UserCollaboration(
                        id: accepted.id,
                        coupleId: accepted.coupleId,
                        coupleName: invitation.coupleName,
                        weddingDate: invitation.weddingDate,
                        role: invitation.role,
                        status: .active,
                        invitedBy: invitation.invitedBy,
                        invitedAt: invitation.invitedAt,
                        acceptedAt: Date(),
                        lastSeenAt: nil
                    )

                    userCollaborations.append(activeCollaboration)
                }
            }

            AppLogger.ui.info("Accepted invitation: \(id)")

            await SentryService.shared.trackAction(
                "invitation_accepted",
                category: "collaboration",
                metadata: ["invitation_id": id.uuidString]
            )

            showSuccess("Invitation accepted! You can now switch to this wedding.")
            HapticFeedback.itemAdded()
        } catch {
            AppLogger.ui.error("Failed to accept invitation", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "acceptUserInvitation",
                "invitationId": id.uuidString
            ])
            throw error
        }
    }

    // MARK: - Retry Helper

    func retryLoad() async {
        await loadCollaborationData()
    }

    // MARK: - Private Helpers

    private func showSuccess(_ message: String) {
        successMessage = message
        showSuccessToast = true
    }
}
