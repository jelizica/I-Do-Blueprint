//
//  TimelineStoreV2Tests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for TimelineStoreV2
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class TimelineStoreV2Tests: XCTestCase {
    var store: TimelineStoreV2!
    var mockRepository: MockTimelineRepository!

    override func setUp() async throws {
        mockRepository = MockTimelineRepository()
        store = withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }
    }

    override func tearDown() async throws {
        store = nil
        mockRepository = nil
    }

    // MARK: - Load Timeline Tests

    func testLoadTimelineItems_Success() async throws {
        // Given
        let mockItems = [
            createMockTimelineItem(title: "Ceremony", date: Date()),
            createMockTimelineItem(title: "Reception", date: Date().addingTimeInterval(3600)),
        ]
        let mockMilestones = [
            createMockMilestone(name: "Save the Date")
        ]
        mockRepository.timelineItems = mockItems
        mockRepository.milestones = mockMilestones

        // When
        await store.loadTimelineItems()

        // Then
        XCTAssertEqual(store.timelineItems.count, 2)
        XCTAssertEqual(store.milestones.count, 1)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testLoadTimelineItems_EmptyResult() async throws {
        // Given
        mockRepository.timelineItems = []
        mockRepository.milestones = []

        // When
        await store.loadTimelineItems()

        // Then
        XCTAssertTrue(store.timelineItems.isEmpty)
        XCTAssertTrue(store.milestones.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testLoadTimelineItems_Error() async throws {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await store.loadTimelineItems()

        // Then
        XCTAssertTrue(store.timelineItems.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Create Timeline Item Tests

    func testCreateTimelineItem_Success() async throws {
        // Given
        let insertData = TimelineItemInsertData(
            title: "New Event",
            description: nil,
            itemDate: Date(),
            itemType: .ceremony,
            duration: nil,
            location: nil,
            notes: nil
        )
        let newItem = createMockTimelineItem(title: "New Event")
        mockRepository.createdItem = newItem

        // When
        await store.createTimelineItem(insertData)

        // Then
        XCTAssertEqual(store.timelineItems.count, 1)
        XCTAssertEqual(store.timelineItems[0].title, "New Event")
        XCTAssertNil(store.error)
    }

    func testCreateTimelineItem_SortsAutomatically() async throws {
        // Given
        let laterDate = Date().addingTimeInterval(3600)
        let earlierDate = Date()

        let item1 = createMockTimelineItem(title: "Later", date: laterDate)
        let item2 = createMockTimelineItem(title: "Earlier", date: earlierDate)

        store.timelineItems = [item1]
        mockRepository.createdItem = item2

        // When
        await store.createTimelineItem(TimelineItemInsertData(
            title: "Earlier",
            description: nil,
            itemDate: earlierDate,
            itemType: .ceremony,
            duration: nil,
            location: nil,
            notes: nil
        ))

        // Then
        XCTAssertEqual(store.timelineItems.count, 2)
        XCTAssertEqual(store.timelineItems[0].title, "Earlier")
        XCTAssertEqual(store.timelineItems[1].title, "Later")
    }

    // MARK: - Update Timeline Item Tests

    func testUpdateTimelineItem_Success() async throws {
        // Given
        let originalItem = createMockTimelineItem(title: "Original")
        store.timelineItems = [originalItem]

        var updatedItem = originalItem
        updatedItem.title = "Updated"
        mockRepository.updatedItem = updatedItem

        // When
        await store.updateTimelineItem(updatedItem)

        // Then
        XCTAssertEqual(store.timelineItems[0].title, "Updated")
        XCTAssertNil(store.error)
    }

    func testUpdateTimelineItem_RollbackOnError() async throws {
        // Given
        let originalItem = createMockTimelineItem(title: "Original")
        store.timelineItems = [originalItem]

        var updatedItem = originalItem
        updatedItem.title = "Updated"
        mockRepository.shouldThrowError = true

        // When
        await store.updateTimelineItem(updatedItem)

        // Then
        XCTAssertEqual(store.timelineItems[0].title, "Original")
        XCTAssertNotNil(store.error)
    }

    // MARK: - Delete Timeline Item Tests

    func testDeleteTimelineItem_Success() async throws {
        // Given
        let item = createMockTimelineItem(title: "To Delete")
        store.timelineItems = [item]

        // When
        await store.deleteTimelineItem(item)

        // Then
        XCTAssertTrue(store.timelineItems.isEmpty)
        XCTAssertNil(store.error)
    }

    func testDeleteTimelineItem_RollbackOnError() async throws {
        // Given
        let item = createMockTimelineItem(title: "To Delete")
        store.timelineItems = [item]
        mockRepository.shouldThrowError = true

        // When
        await store.deleteTimelineItem(item)

        // Then
        XCTAssertEqual(store.timelineItems.count, 1)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Toggle Completion Tests

    func testToggleItemCompletion_MarksIncompleteAsComplete() async throws {
        // Given
        let item = createMockTimelineItem(title: "Item", completed: false)
        store.timelineItems = [item]

        var completedItem = item
        completedItem.completed = true
        mockRepository.updatedItem = completedItem

        // When
        await store.toggleItemCompletion(item)

        // Then
        XCTAssertTrue(store.timelineItems[0].completed)
    }

    // MARK: - Milestone Tests

    func testCreateMilestone_Success() async throws {
        // Given
        let insertData = MilestoneInsertData(
            name: "Engagement",
            description: nil,
            milestoneDate: Date(),
            icon: nil
        )
        let newMilestone = createMockMilestone(name: "Engagement")
        mockRepository.createdMilestone = newMilestone

        // When
        await store.createMilestone(insertData)

        // Then
        XCTAssertEqual(store.milestones.count, 1)
        XCTAssertEqual(store.milestones[0].name, "Engagement")
        XCTAssertNil(store.error)
    }

    func testUpdateMilestone_Success() async throws {
        // Given
        let originalMilestone = createMockMilestone(name: "Original")
        store.milestones = [originalMilestone]

        var updatedMilestone = originalMilestone
        updatedMilestone.name = "Updated"
        mockRepository.updatedMilestone = updatedMilestone

        // When
        await store.updateMilestone(updatedMilestone)

        // Then
        XCTAssertEqual(store.milestones[0].name, "Updated")
        XCTAssertNil(store.error)
    }

    func testDeleteMilestone_RollbackOnError() async throws {
        // Given
        let milestone = createMockMilestone(name: "To Delete")
        store.milestones = [milestone]
        mockRepository.shouldThrowError = true

        // When
        await store.deleteMilestone(milestone)

        // Then
        XCTAssertEqual(store.milestones.count, 1)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Computed Properties Tests

    func testFilteredItems_FiltersByType() {
        // Given
        store.timelineItems = [
            createMockTimelineItem(title: "Ceremony", itemType: .ceremony),
            createMockTimelineItem(title: "Reception", itemType: .reception),
        ]
        store.filterType = .ceremony

        // When
        let filtered = store.filteredItems

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].title, "Ceremony")
    }

    func testFilteredItems_HidesCompletedWhenToggled() {
        // Given
        store.timelineItems = [
            createMockTimelineItem(title: "Done", completed: true),
            createMockTimelineItem(title: "Not Done", completed: false),
        ]
        store.showCompleted = false

        // When
        let filtered = store.filteredItems

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].title, "Not Done")
    }

    func testOverdueItems_ReturnsOnlyPastIncompleteItems() {
        // Given
        let past = Date().addingTimeInterval(-3600)
        let future = Date().addingTimeInterval(3600)

        store.timelineItems = [
            createMockTimelineItem(title: "Overdue", date: past, completed: false),
            createMockTimelineItem(title: "Future", date: future, completed: false),
            createMockTimelineItem(title: "Past Complete", date: past, completed: true),
        ]

        // When
        let overdue = store.overdueItems

        // Then
        XCTAssertEqual(overdue.count, 1)
        XCTAssertEqual(overdue[0].title, "Overdue")
    }

    // MARK: - Helper Methods

    private func createMockTimelineItem(
        title: String,
        date: Date = Date(),
        itemType: TimelineItemType = .ceremony,
        completed: Bool = false
    ) -> TimelineItem {
        TimelineItem(
            id: UUID(),
            tenantId: UUID(),
            title: title,
            description: nil,
            itemDate: date,
            itemType: itemType,
            duration: nil,
            location: nil,
            notes: nil,
            completed: completed,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func createMockMilestone(
        name: String,
        date: Date = Date(),
        completed: Bool = false
    ) -> Milestone {
        Milestone(
            id: UUID(),
            tenantId: UUID(),
            name: name,
            description: nil,
            milestoneDate: date,
            icon: nil,
            completed: completed,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Repository

class MockTimelineRepository: TimelineRepositoryProtocol {
    var timelineItems: [TimelineItem] = []
    var milestones: [Milestone] = []
    var createdItem: TimelineItem?
    var updatedItem: TimelineItem?
    var createdMilestone: Milestone?
    var updatedMilestone: Milestone?
    var shouldThrowError = false

    func fetchTimelineItems() async throws -> [TimelineItem] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return timelineItems
    }

    func fetchMilestones() async throws -> [Milestone] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return milestones
    }

    func createTimelineItem(_ insertData: TimelineItemInsertData) async throws -> TimelineItem {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return createdItem ?? TimelineItem(
            id: UUID(),
            tenantId: UUID(),
            title: insertData.title,
            description: insertData.description,
            itemDate: insertData.itemDate,
            itemType: insertData.itemType,
            duration: insertData.duration,
            location: insertData.location,
            notes: insertData.notes,
            completed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func updateTimelineItem(_ item: TimelineItem) async throws -> TimelineItem {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return updatedItem ?? item
    }

    func deleteTimelineItem(id: UUID) async throws {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
    }

    func createMilestone(_ insertData: MilestoneInsertData) async throws -> Milestone {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return createdMilestone ?? Milestone(
            id: UUID(),
            tenantId: UUID(),
            name: insertData.name,
            description: insertData.description,
            milestoneDate: insertData.milestoneDate,
            icon: insertData.icon,
            completed: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func updateMilestone(_ milestone: Milestone) async throws -> Milestone {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return updatedMilestone ?? milestone
    }

    func deleteMilestone(id: UUID) async throws {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
    }

    func invalidateCache() async {
        // No-op for mock
    }
}
