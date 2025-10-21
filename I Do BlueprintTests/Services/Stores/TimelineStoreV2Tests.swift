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
    var mockRepository: MockTimelineRepository!
    var coupleId: UUID!

    override func setUp() async throws {
        mockRepository = MockTimelineRepository()
        coupleId = UUID()
    }

    override func tearDown() {
        mockRepository = nil
        coupleId = nil
    }

    // MARK: - Load Tests

    func testLoadTimelineItems_Success() async throws {
        // Given
        let testItems = [
            TimelineItem.makeTest(id: UUID(), coupleId: coupleId, title: "Book Venue"),
            TimelineItem.makeTest(id: UUID(), coupleId: coupleId, title: "Send Invitations")
        ]
        mockRepository.timelineItems = testItems

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.timelineItems.count, 2)
        XCTAssertEqual(store.timelineItems[0].title, "Book Venue")
    }

    func testLoadTimelineItems_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.timelineItems.count, 0)
    }

    func testLoadTimelineItems_Empty() async throws {
        // Given
        mockRepository.timelineItems = []

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.timelineItems.count, 0)
    }

    func testLoadMilestones_Success() async throws {
        // Given
        let testMilestones = [
            Milestone.makeTest(id: UUID(), coupleId: coupleId, milestoneName: "Engagement"),
            Milestone.makeTest(id: UUID(), coupleId: coupleId, milestoneName: "Wedding Day")
        ]
        mockRepository.milestones = testMilestones

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.milestones.count, 2)
    }

    func testLoadMilestones_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Create Tests

    func testCreateTimelineItem_OptimisticUpdate() async throws {
        // Given
        let existingItem = TimelineItem.makeTest(coupleId: coupleId, title: "Existing Item")
        mockRepository.timelineItems = [existingItem]

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()

        let insertData = TimelineItemInsertData(
            coupleId: coupleId,
            title: "New Item",
            itemType: .other,
            itemDate: Date(),
            completed: false
        )
        await store.createTimelineItem(insertData)

        // Then
        XCTAssertEqual(store.timelineItems.count, 2)
    }

    func testUpdateTimelineItem_Success() async throws {
        // Given
        let item = TimelineItem.makeTest(id: UUID(), coupleId: coupleId, title: "Book Venue", completed: false)
        mockRepository.timelineItems = [item]

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()

        var updatedItem = item
        updatedItem.completed = true
        await store.updateTimelineItem(updatedItem)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.timelineItems.first?.completed, true)
    }

    func testUpdateTimelineItem_Failure_RollsBack() async throws {
        // Given
        let item = TimelineItem.makeTest(id: UUID(), coupleId: coupleId, title: "Book Venue", completed: false)
        mockRepository.timelineItems = [item]

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()

        var updatedItem = item
        updatedItem.completed = true

        mockRepository.shouldThrowError = true
        await store.updateTimelineItem(updatedItem)

        // Then - Should rollback to original
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.timelineItems.first?.completed, false)
    }

    // MARK: - Delete Tests

    func testDeleteTimelineItem_Success() async throws {
        // Given
        let item1 = TimelineItem.makeTest(id: UUID(), coupleId: coupleId, title: "Item 1")
        let item2 = TimelineItem.makeTest(id: UUID(), coupleId: coupleId, title: "Item 2")
        mockRepository.timelineItems = [item1, item2]

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()
        await store.deleteTimelineItem(item1)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.timelineItems.count, 1)
        XCTAssertEqual(store.timelineItems.first?.title, "Item 2")
    }

    func testDeleteTimelineItem_Failure_RollsBack() async throws {
        // Given
        let item = TimelineItem.makeTest(id: UUID(), coupleId: coupleId, title: "Item 1")
        mockRepository.timelineItems = [item]

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()

        mockRepository.shouldThrowError = true
        await store.deleteTimelineItem(item)

        // Then - Should rollback
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.timelineItems.count, 1)
    }

    func testToggleCompleted() async throws {
        // Given
        let item = TimelineItem.makeTest(id: UUID(), coupleId: coupleId, title: "Item 1", completed: false)
        mockRepository.timelineItems = [item]

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()
        await store.toggleItemCompletion(item)

        // Then
        XCTAssertEqual(store.timelineItems.first?.completed, true)
    }

    // MARK: - Computed Properties Tests

    func testComputedProperty_UpcomingItems() async throws {
        // Given
        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let items = [
            TimelineItem.makeTest(coupleId: coupleId, itemDate: futureDate, completed: false),
            TimelineItem.makeTest(coupleId: coupleId, itemDate: futureDate, completed: false)
        ]
        mockRepository.timelineItems = items

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()

        // Then
        XCTAssertEqual(store.upcomingItems.count, 2)
    }

    func testComputedProperty_OverdueItems() async throws {
        // Given
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let items = [
            TimelineItem.makeTest(coupleId: coupleId, itemDate: pastDate, completed: false),
            TimelineItem.makeTest(coupleId: coupleId, itemDate: pastDate, completed: false)
        ]
        mockRepository.timelineItems = items

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()

        // Then
        XCTAssertEqual(store.overdueItems.count, 2)
    }

    func testComputedProperty_CompletedItems() async throws {
        // Given
        let items = [
            TimelineItem.makeTest(coupleId: coupleId, completed: true),
            TimelineItem.makeTest(coupleId: coupleId, completed: false),
            TimelineItem.makeTest(coupleId: coupleId, completed: true)
        ]
        mockRepository.timelineItems = items

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()

        // Then
        XCTAssertEqual(store.completedItemsCount(), 2)
    }

    func testFilterByType() async throws {
        // Given
        let items = [
            TimelineItem.makeTest(coupleId: coupleId, itemType: .payment),
            TimelineItem.makeTest(coupleId: coupleId, itemType: .task),
            TimelineItem.makeTest(coupleId: coupleId, itemType: .payment)
        ]
        mockRepository.timelineItems = items

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()
        store.filterType = .payment
        let filtered = store.filteredItems

        // Then
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.itemType == .payment })
    }

    func testFilterByDateRange() async throws {
        // Given
        let pastDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        let futureDate = Calendar.current.date(byAdding: .month, value: 2, to: Date())!
        let items = [
            TimelineItem.makeTest(coupleId: coupleId, itemDate: pastDate),
            TimelineItem.makeTest(coupleId: coupleId, itemDate: Date()),
            TimelineItem.makeTest(coupleId: coupleId, itemDate: futureDate)
        ]
        mockRepository.timelineItems = items

        // When
        let store = await withDependencies {
            $0.timelineRepository = mockRepository
        } operation: {
            TimelineStoreV2()
        }

        await store.loadTimelineItems()

        // Then
        XCTAssertEqual(store.timelineItems.count, 3)
    }
}
