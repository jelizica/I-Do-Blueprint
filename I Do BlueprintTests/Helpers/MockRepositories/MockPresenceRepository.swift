//
//  MockPresenceRepository.swift
//  I Do BlueprintTests
//
//  Mock implementation of PresenceRepositoryProtocol for testing
//

import Foundation
@testable import I_Do_Blueprint

class MockPresenceRepository: PresenceRepositoryProtocol {
    var presenceRecords: [Presence] = []
    var shouldThrowError = false
    var errorToThrow: PresenceError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchActivePresence() async throws -> [Presence] {
        if shouldThrowError { throw errorToThrow }
        return presenceRecords.filter { !$0.isStale }
    }

    func trackPresence(
        status: PresenceStatus,
        currentView: String?,
        currentResourceType: String?,
        currentResourceId: UUID?
    ) async throws -> Presence {
        if shouldThrowError { throw errorToThrow }
        let presence = Presence.makeTest(status: status, currentView: currentView)
        presenceRecords.append(presence)
        return presence
    }

    func updateEditingState(
        isEditing: Bool,
        resourceType: String?,
        resourceId: UUID?
    ) async throws -> Presence {
        if shouldThrowError { throw errorToThrow }
        guard let index = presenceRecords.firstIndex(where: { !$0.isStale }) else {
            throw PresenceError.notFound
        }
        var presence = presenceRecords[index]
        presence.isEditing = isEditing
        presence.editingResourceType = resourceType
        presence.editingResourceId = resourceId
        presenceRecords[index] = presence
        return presence
    }

    func sendHeartbeat() async throws -> Presence {
        if shouldThrowError { throw errorToThrow }
        guard let index = presenceRecords.firstIndex(where: { !$0.isStale }) else {
            throw PresenceError.notFound
        }
        var presence = presenceRecords[index]
        presence.lastHeartbeat = Date()
        presenceRecords[index] = presence
        return presence
    }

    func stopTracking() async throws {
        if shouldThrowError { throw errorToThrow }
        if let index = presenceRecords.firstIndex(where: { !$0.isStale }) {
            var presence = presenceRecords[index]
            presence.status = .offline
            presenceRecords[index] = presence
        }
    }

    func cleanupStalePresence() async throws {
        if shouldThrowError { throw errorToThrow }
        presenceRecords.removeAll(where: { $0.isStale })
    }
}
