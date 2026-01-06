//
//  MockTimelineRepository.swift
//  My Wedding Planning App
//
//  Mock implementation for testing
//

import Foundation

@MainActor
class MockTimelineRepository: TimelineRepositoryProtocol {
    var timelineItems: [TimelineItem] = []
    var milestones: [Milestone] = []
    var weddingDayEvents: [WeddingDayEvent] = []

    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: -1)

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

        let item = TimelineItem(
            id: UUID(),
            coupleId: insertData.coupleId,
            title: insertData.title,
            description: insertData.description,
            itemType: insertData.itemType,
            itemDate: insertData.itemDate,
            endDate: insertData.endDate,
            completed: insertData.completed,
            relatedId: insertData.relatedId,
            createdAt: Date(),
            updatedAt: Date(),
            task: nil,
            milestone: nil,
            vendor: nil,
            payment: nil)
        timelineItems.append(item)
        return item
    }

    func updateTimelineItem(_ item: TimelineItem) async throws -> TimelineItem {
        if shouldThrowError { throw errorToThrow }

        guard let index = timelineItems.firstIndex(where: { $0.id == item.id }) else {
            throw NSError(domain: "test", code: 404)
        }

        var updated = item
        updated.updatedAt = Date()
        timelineItems[index] = updated
        return updated
    }

    func deleteTimelineItem(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        timelineItems.removeAll { $0.id == id }
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

        let milestone = Milestone(
            id: UUID(),
            coupleId: insertData.coupleId,
            milestoneName: insertData.milestoneName,
            description: insertData.description,
            milestoneDate: insertData.milestoneDate,
            completed: insertData.completed,
            color: insertData.color,
            createdAt: Date(),
            updatedAt: Date())
        milestones.append(milestone)
        return milestone
    }

    func updateMilestone(_ milestone: Milestone) async throws -> Milestone {
        if shouldThrowError { throw errorToThrow }

        guard let index = milestones.firstIndex(where: { $0.id == milestone.id }) else {
            throw NSError(domain: "test", code: 404)
        }

        var updated = milestone
        updated.updatedAt = Date()
        milestones[index] = updated
        return updated
    }

    func deleteMilestone(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        milestones.removeAll { $0.id == id }
    }

    // MARK: - Wedding Day Events

    func fetchWeddingDayEvents() async throws -> [WeddingDayEvent] {
        if shouldThrowError { throw errorToThrow }
        return weddingDayEvents
    }

    func fetchWeddingDayEvents(forDate date: Date) async throws -> [WeddingDayEvent] {
        if shouldThrowError { throw errorToThrow }
        let calendar = Calendar.current
        return weddingDayEvents.filter { calendar.isDate($0.eventDate, inSameDayAs: date) }
    }

    func fetchWeddingDayEvent(id: UUID) async throws -> WeddingDayEvent? {
        if shouldThrowError { throw errorToThrow }
        return weddingDayEvents.first(where: { $0.id == id })
    }

    func createWeddingDayEvent(_ insertData: WeddingDayEventInsertData) async throws -> WeddingDayEvent {
        if shouldThrowError { throw errorToThrow }

        let event = WeddingDayEvent.makeTest(
            coupleId: insertData.coupleId,
            eventName: insertData.eventName,
            eventDate: insertData.eventDate,
            startTime: insertData.startTime,
            endTime: insertData.endTime,
            status: WeddingDayEventStatus(rawValue: insertData.status) ?? .pending,
            category: WeddingDayEventCategory(rawValue: insertData.category) ?? .other,
            isMainEvent: insertData.isMainEvent
        )
        weddingDayEvents.append(event)
        return event
    }

    func updateWeddingDayEvent(_ event: WeddingDayEvent) async throws -> WeddingDayEvent {
        if shouldThrowError { throw errorToThrow }

        guard let index = weddingDayEvents.firstIndex(where: { $0.id == event.id }) else {
            throw NSError(domain: "test", code: 404)
        }

        var updated = event
        updated.updatedAt = Date()
        weddingDayEvents[index] = updated
        return updated
    }

    func deleteWeddingDayEvent(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        weddingDayEvents.removeAll { $0.id == id }
    }
}
