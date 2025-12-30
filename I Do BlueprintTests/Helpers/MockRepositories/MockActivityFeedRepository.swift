//
//  MockActivityFeedRepository.swift
//  I Do BlueprintTests
//
//  Mock implementation of ActivityFeedRepositoryProtocol for testing
//

import Foundation
@testable import I_Do_Blueprint

class MockActivityFeedRepository: ActivityFeedRepositoryProtocol {
    var activities: [ActivityEvent] = []
    var shouldThrowError = false
    var errorToThrow: ActivityFeedError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchActivities(limit: Int, offset: Int) async throws -> [ActivityEvent] {
        if shouldThrowError { throw errorToThrow }
        let start = min(offset, activities.count)
        let end = min(offset + limit, activities.count)
        return Array(activities[start..<end])
    }

    func fetchActivities(actionType: ActionType, limit: Int) async throws -> [ActivityEvent] {
        if shouldThrowError { throw errorToThrow }
        return activities.filter { $0.actionType == actionType }.prefix(limit).map { $0 }
    }

    func fetchActivities(resourceType: ResourceType, limit: Int) async throws -> [ActivityEvent] {
        if shouldThrowError { throw errorToThrow }
        return activities.filter { $0.resourceType == resourceType }.prefix(limit).map { $0 }
    }

    func fetchActivities(actorId: UUID, limit: Int) async throws -> [ActivityEvent] {
        if shouldThrowError { throw errorToThrow }
        return activities.filter { $0.actorId == actorId }.prefix(limit).map { $0 }
    }

    func fetchUnreadCount() async throws -> Int {
        if shouldThrowError { throw errorToThrow }
        return activities.filter { !$0.isRead }.count
    }

    func markAsRead(id: UUID) async throws -> ActivityEvent {
        if shouldThrowError { throw errorToThrow }
        guard let index = activities.firstIndex(where: { $0.id == id }) else {
            throw ActivityFeedError.fetchFailed(underlying: NSError(domain: "Test", code: -1))
        }
        var activity = activities[index]
        activity.isRead = true
        activities[index] = activity
        return activity
    }

    func markAllAsRead() async throws -> Int {
        if shouldThrowError { throw errorToThrow }
        let unreadCount = activities.filter { !$0.isRead }.count
        for index in activities.indices {
            activities[index].isRead = true
        }
        return unreadCount
    }

    func fetchActivityStats() async throws -> ActivityStats {
        if shouldThrowError { throw errorToThrow }
        var activitiesByAction: [ActionType: Int] = [:]
        var activitiesByResource: [ResourceType: Int] = [:]

        for activity in activities {
            activitiesByAction[activity.actionType, default: 0] += 1
            activitiesByResource[activity.resourceType, default: 0] += 1
        }

        let oneDayAgo = Date().addingTimeInterval(-86400)
        let recentCount = activities.filter { $0.createdAt > oneDayAgo }.count

        return ActivityStats(
            totalActivities: activities.count,
            activitiesByAction: activitiesByAction,
            activitiesByResource: activitiesByResource,
            recentActivityCount: recentCount
        )
    }
}
