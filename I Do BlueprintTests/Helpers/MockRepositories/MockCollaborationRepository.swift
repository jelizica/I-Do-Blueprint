//
//  MockCollaborationRepository.swift
//  I Do BlueprintTests
//
//  Mock implementation of CollaborationRepositoryProtocol for testing
//

import Foundation
@testable import I_Do_Blueprint

class MockCollaborationRepository: CollaborationRepositoryProtocol {
    var collaborators: [Collaborator] = []
    var roles: [CollaborationRole] = []
    var currentUserCollaborator: Collaborator?
    var currentUserRole: RoleName?
    var permissions: [String: Bool] = [:]
    var shouldThrowError = false
    var errorToThrow: CollaborationError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchCollaborators() async throws -> [Collaborator] {
        if shouldThrowError { throw errorToThrow }
        return collaborators
    }

    func fetchRoles() async throws -> [CollaborationRole] {
        if shouldThrowError { throw errorToThrow }
        return roles
    }

    func fetchCollaborator(id: UUID) async throws -> Collaborator {
        if shouldThrowError { throw errorToThrow }
        guard let collaborator = collaborators.first(where: { $0.id == id }) else {
            throw CollaborationError.notFound(id: id)
        }
        return collaborator
    }

    func fetchCurrentUserCollaborator() async throws -> Collaborator? {
        if shouldThrowError { throw errorToThrow }
        return currentUserCollaborator
    }

    func inviteCollaborator(email: String, roleId: UUID, displayName: String?) async throws -> Collaborator {
        if shouldThrowError { throw errorToThrow }
        let collaborator = Collaborator.makeTest(email: email, displayName: displayName, status: .pending)
        collaborators.append(collaborator)
        return collaborator
    }

    func acceptInvitation(id: UUID) async throws -> Collaborator {
        if shouldThrowError { throw errorToThrow }
        guard let index = collaborators.firstIndex(where: { $0.id == id }) else {
            throw CollaborationError.notFound(id: id)
        }
        var collaborator = collaborators[index]
        collaborator.status = .active
        collaborator.acceptedAt = Date()
        collaborators[index] = collaborator
        return collaborator
    }

    func updateCollaboratorRole(id: UUID, roleId: UUID) async throws -> Collaborator {
        if shouldThrowError { throw errorToThrow }
        guard let index = collaborators.firstIndex(where: { $0.id == id }) else {
            throw CollaborationError.notFound(id: id)
        }
        var collaborator = collaborators[index]
        collaborator.roleId = roleId
        collaborators[index] = collaborator
        return collaborator
    }

    func removeCollaborator(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        collaborators.removeAll(where: { $0.id == id })
    }

    func hasPermission(_ permission: String) async throws -> Bool {
        if shouldThrowError { throw errorToThrow }
        return permissions[permission] ?? false
    }

    func getCurrentUserRole() async throws -> RoleName? {
        if shouldThrowError { throw errorToThrow }
        return currentUserRole
    }

    func fetchInvitationByToken(_ token: String) async throws -> InvitationDetails {
        if shouldThrowError { throw errorToThrow }
        throw CollaborationError.invitationNotFound
    }

    func createOwnerCollaborator(
        coupleId: UUID,
        userId: UUID,
        email: String,
        displayName: String?
    ) async throws -> Collaborator {
        if shouldThrowError { throw errorToThrow }

        // Check if already exists (idempotency)
        if let existing = collaborators.first(where: { $0.coupleId == coupleId && $0.userId == userId }) {
            return existing
        }

        // Create owner collaborator
        let ownerRole = roles.first(where: { $0.roleName == .owner })
        let collaborator = Collaborator.makeTest(
            coupleId: coupleId,
            userId: userId,
            roleId: ownerRole?.id ?? UUID(),
            invitedBy: userId,
            acceptedAt: Date(),
            status: .active,
            email: email,
            displayName: displayName
        )
        collaborators.append(collaborator)
        return collaborator
    }
}
