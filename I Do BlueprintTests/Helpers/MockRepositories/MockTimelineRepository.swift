//
//  MockTimelineRepository.swift
//  I Do BlueprintTests
//
//  Mock implementation of TimelineRepositoryProtocol for testing
//

import Foundation
@testable import I_Do_Blueprint

class MockTimelineRepository: TimelineRepositoryProtocol {
    var timelineItems: [TimelineItem] = []
    var milestones: [Milestone] = []
    var shouldThrowError = false
    var errorToThrow: TimelineError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchTimelineItems() async throws -> [TimelineItem] {
        if shouldThrowError { throw errorToThrow }
        return timelineItems
    }

    func fetchTimelineItem(id: UUID) async throws -> TimelineItem? {
        if shouldThrowError { throw errorToThrow }
        return timelineItems.first(where: { $0.id == id })
    }

    func createTimelineItem(_ insertData: TimelineItemInsertData) async throws -> TimelineItem {
        if shouldThrowError { throw errorToThrow }
        let item = TimelineItem.makeTest(title: insertData.title)
        timelineItems.append(item)
        return item
    }

    func updateTimelineItem(_ item: TimelineItem) async throws -> TimelineItem {
        if shouldThrowError { throw errorToThrow }
        if let index = timelineItems.firstIndex(where: { $0.id == item.id }) {
            timelineItems[index] = item
        }
        return item
    }

    func deleteTimelineItem(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        timelineItems.removeAll(where: { $0.id == id })
    }

    func fetchMilestones() async throws -> [Milestone] {
        if shouldThrowError { throw errorToThrow }
        return milestones
    }

    func fetchMilestone(id: UUID) async throws -> Milestone? {
        if shouldThrowError { throw errorToThrow }
        return milestones.first(where: { $0.id == id })
    }

    func createMilestone(_ insertData: MilestoneInsertData) async throws -> Milestone {
        if shouldThrowError { throw errorToThrow }
        let milestone = Milestone.makeTest(milestoneName: insertData.milestoneName)
        milestones.append(milestone)
        return milestone
    }

    func updateMilestone(_ milestone: Milestone) async throws -> Milestone {
        if shouldThrowError { throw errorToThrow }
        if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
            milestones[index] = milestone
        }
        return milestone
    }

    func deleteMilestone(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        milestones.removeAll(where: { $0.id == id })
    }
}
