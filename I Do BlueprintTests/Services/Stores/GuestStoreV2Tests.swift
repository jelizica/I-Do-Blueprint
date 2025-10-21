//
//  GuestStoreV2Tests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for GuestStoreV2
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class GuestStoreV2Tests: XCTestCase {
    var mockRepository: MockGuestRepository!
    var coupleId: UUID!

    override func setUp() async throws {
        mockRepository = MockGuestRepository()
        coupleId = UUID()
    }

    override func tearDown() {
        mockRepository = nil
        coupleId = nil
    }

    // MARK: - Load Tests

    func testLoadGuests_Success() async throws {
        // Given
        let testGuests = [
            Guest.makeTest(id: UUID(), coupleId: coupleId, firstName: "John", lastName: "Doe"),
            Guest.makeTest(id: UUID(), coupleId: coupleId, firstName: "Jane", lastName: "Smith")
        ]
        mockRepository.guests = testGuests

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.loadGuestData()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.guests.count, 2)
        XCTAssertEqual(store.guests[0].firstName, "John")
        XCTAssertEqual(store.guests[1].firstName, "Jane")
    }

    func testLoadGuests_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.loadGuestData()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.guests.count, 0)
    }

    func testLoadGuests_EmptyResult() async throws {
        // Given
        mockRepository.guests = []

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.loadGuestData()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.guests.count, 0)
    }

    // MARK: - Create Tests

    func testCreateGuest_Success() async throws {
        // Given
        let newGuest = Guest.makeTest(coupleId: coupleId, firstName: "New", lastName: "Guest")

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.addGuest(newGuest)

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.guests.count, 1)
        XCTAssertEqual(store.guests.first?.firstName, "New")
    }

    func testCreateGuest_OptimisticUpdate() async throws {
        // Given
        let existingGuest = Guest.makeTest(coupleId: coupleId, firstName: "Existing")
        mockRepository.guests = [existingGuest]

        let newGuest = Guest.makeTest(coupleId: coupleId, firstName: "New", lastName: "Guest")

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.loadGuestData()
        await store.addGuest(newGuest)

        // Then - Optimistic update should show immediately
        XCTAssertEqual(store.guests.count, 2)
        XCTAssertTrue(store.guests.contains(where: { $0.firstName == "New" }))
    }

    func testCreateGuest_Failure_RollsBack() async throws {
        // Given
        let existingGuest = Guest.makeTest(coupleId: coupleId, firstName: "Existing")
        mockRepository.guests = [existingGuest]

        let newGuest = Guest.makeTest(coupleId: coupleId, firstName: "New")

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.loadGuestData()

        // Set error after load
        mockRepository.shouldThrowError = true
        await store.addGuest(newGuest)

        // Then - Should rollback on error
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.guests.count, 1)
        XCTAssertEqual(store.guests.first?.firstName, "Existing")
    }

    // MARK: - Update Tests

    func testUpdateGuest_Success() async throws {
        // Given
        let guest = Guest.makeTest(id: UUID(), coupleId: coupleId, firstName: "John", lastName: "Doe")
        mockRepository.guests = [guest]

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.loadGuestData()

        var updatedGuest = guest
        updatedGuest.firstName = "Jane"
        await store.updateGuest(updatedGuest)

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.guests.count, 1)
        XCTAssertEqual(store.guests.first?.firstName, "Jane")
    }

    func testUpdateGuest_Failure_RollsBack() async throws {
        // Given
        let guest = Guest.makeTest(id: UUID(), coupleId: coupleId, firstName: "John", rsvpStatus: RSVPStatus.pending)
        mockRepository.guests = [guest]

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.loadGuestData()

        var updatedGuest = guest
        updatedGuest.rsvpStatus = .confirmed

        mockRepository.shouldThrowError = true
        await store.updateGuest(updatedGuest)

        // Then - Should rollback to original
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.guests.first?.rsvpStatus, .pending)
    }

    // MARK: - Delete Tests

    func testDeleteGuest_Success() async throws {
        // Given
        let guest1 = Guest.makeTest(id: UUID(), coupleId: coupleId, firstName: "John")
        let guest2 = Guest.makeTest(id: UUID(), coupleId: coupleId, firstName: "Jane")
        mockRepository.guests = [guest1, guest2]

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.loadGuestData()
        await store.deleteGuest(id: guest1.id)

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.guests.count, 1)
        XCTAssertEqual(store.guests.first?.firstName, "Jane")
    }

    func testDeleteGuest_Failure_RollsBack() async throws {
        // Given
        let guest = Guest.makeTest(id: UUID(), coupleId: coupleId, firstName: "John")
        mockRepository.guests = [guest]

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.loadGuestData()

        mockRepository.shouldThrowError = true
        await store.deleteGuest(id: guest.id)

        // Then - Should rollback
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.guests.count, 1)
        XCTAssertEqual(store.guests.first?.id, guest.id)
    }

    // MARK: - Computed Properties Tests

    func testComputedProperty_TotalCount() async throws {
        // Given
        let guests = [
            Guest.makeTest(coupleId: coupleId),
            Guest.makeTest(coupleId: coupleId),
            Guest.makeTest(coupleId: coupleId)
        ]
        mockRepository.guests = guests

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.loadGuestData()

        // Then
        XCTAssertEqual(store.totalGuests, 3)
    }

    func testComputedProperty_ConfirmedCount() async throws {
        // Given
        let guests = [
            Guest.makeTest(coupleId: coupleId, rsvpStatus: RSVPStatus.confirmed),
            Guest.makeTest(coupleId: coupleId, rsvpStatus: RSVPStatus.confirmed),
            Guest.makeTest(coupleId: coupleId, rsvpStatus: RSVPStatus.pending)
        ]
        mockRepository.guests = guests

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.loadGuestData()

        // Then
        XCTAssertEqual(store.attendingGuests, 2)
        XCTAssertEqual(store.pendingGuests, 1)
    }

    // testComputedProperty_ResponseRate removed - responseRate property doesn't exist in GuestStoreV2

    // MARK: - Filter Tests

    func testFilterByRSVPStatus() async throws {
        // Given
        let guests = [
            Guest.makeTest(coupleId: coupleId, firstName: "John", rsvpStatus: RSVPStatus.confirmed),
            Guest.makeTest(coupleId: coupleId, firstName: "Jane", rsvpStatus: RSVPStatus.pending),
            Guest.makeTest(coupleId: coupleId, firstName: "Bob", rsvpStatus: RSVPStatus.confirmed)
        ]
        mockRepository.guests = guests

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.loadGuestData()
        let confirmed = store.guests.filter { $0.rsvpStatus == .confirmed }

        // Then
        XCTAssertEqual(confirmed.count, 2)
        XCTAssertTrue(confirmed.allSatisfy { $0.rsvpStatus == .confirmed })
    }

    func testSearchGuests() async throws {
        // Given
        let guests = [
            Guest.makeTest(coupleId: coupleId, firstName: "John", lastName: "Doe"),
            Guest.makeTest(coupleId: coupleId, firstName: "Jane", lastName: "Smith"),
            Guest.makeTest(coupleId: coupleId, firstName: "Bob", lastName: "Johnson")
        ]
        mockRepository.guests = guests

        // When
        let store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }

        await store.loadGuestData()
        await store.searchGuests(query: "john")

        // Then
        XCTAssertEqual(store.filteredGuests.count, 2) // John Doe and Bob Johnson
    }
}
