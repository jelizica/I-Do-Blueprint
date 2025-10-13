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
    var store: GuestStoreV2!
    var mockRepository: MockGuestRepository!

    override func setUp() async throws {
        mockRepository = MockGuestRepository()
        store = withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }
    }

    override func tearDown() async throws {
        store = nil
        mockRepository = nil
    }

    // MARK: - Load Guest Data Tests

    func testLoadGuestData_Success() async throws {
        // Given
        let mockGuests = [
            createMockGuest(firstName: "John", lastName: "Doe", rsvpStatus: .attending),
            createMockGuest(firstName: "Jane", lastName: "Smith", rsvpStatus: .pending),
        ]
        let mockStats = GuestStats(
            totalGuests: 2,
            attendingGuests: 1,
            pendingGuests: 1,
            declinedGuests: 0,
            responseRate: 50.0
        )
        mockRepository.guests = mockGuests
        mockRepository.guestStats = mockStats

        // When
        await store.loadGuestData()

        // Then
        XCTAssertEqual(store.guests.count, 2)
        XCTAssertEqual(store.filteredGuests.count, 2)
        XCTAssertEqual(store.guests[0].firstName, "John")
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertNotNil(store.guestStats)
        XCTAssertEqual(store.guestStats?.totalGuests, 2)
    }

    func testLoadGuestData_EmptyResult() async throws {
        // Given
        mockRepository.guests = []
        mockRepository.guestStats = GuestStats(
            totalGuests: 0,
            attendingGuests: 0,
            pendingGuests: 0,
            declinedGuests: 0,
            responseRate: 0
        )

        // When
        await store.loadGuestData()

        // Then
        XCTAssertTrue(store.guests.isEmpty)
        XCTAssertTrue(store.filteredGuests.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testLoadGuestData_Error() async throws {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await store.loadGuestData()

        // Then
        XCTAssertTrue(store.guests.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Add Guest Tests

    func testAddGuest_Success() async throws {
        // Given
        let newGuest = createMockGuest(firstName: "Alice", lastName: "Johnson")
        mockRepository.guests = []
        mockRepository.guestStats = GuestStats(
            totalGuests: 1,
            attendingGuests: 0,
            pendingGuests: 1,
            declinedGuests: 0,
            responseRate: 0
        )

        // When
        await store.addGuest(newGuest)

        // Then
        XCTAssertEqual(store.guests.count, 1)
        XCTAssertEqual(store.filteredGuests.count, 1)
        XCTAssertEqual(store.guests[0].firstName, "Alice")
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertTrue(store.showSuccessToast)
        XCTAssertNotNil(store.guestStats)
    }

    func testAddGuest_Error() async throws {
        // Given
        let newGuest = createMockGuest(firstName: "Bob", lastName: "Wilson")
        mockRepository.shouldThrowError = true

        // When
        await store.addGuest(newGuest)

        // Then
        XCTAssertTrue(store.guests.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
        XCTAssertFalse(store.showSuccessToast)
    }

    // MARK: - Update Guest Tests

    func testUpdateGuest_Success() async throws {
        // Given
        let originalGuest = createMockGuest(firstName: "Charlie", lastName: "Brown", rsvpStatus: .pending, id: UUID())
        mockRepository.guests = [originalGuest]
        mockRepository.guestStats = GuestStats(
            totalGuests: 1,
            attendingGuests: 1,
            pendingGuests: 0,
            declinedGuests: 0,
            responseRate: 100.0
        )

        await store.loadGuestData()

        var updatedGuest = originalGuest
        updatedGuest.rsvpStatus = .attending
        updatedGuest.email = "charlie.updated@example.com"
        mockRepository.guests = [updatedGuest]

        // When
        await store.updateGuest(updatedGuest)

        // Then
        XCTAssertEqual(store.guests.count, 1)
        XCTAssertEqual(store.guests[0].rsvpStatus, .attending)
        XCTAssertEqual(store.guests[0].email, "charlie.updated@example.com")
        XCTAssertEqual(store.filteredGuests[0].rsvpStatus, .attending)
        XCTAssertNil(store.error)
        XCTAssertNotNil(store.guestStats)
    }

    func testUpdateGuest_Rollback() async throws {
        // Given
        let originalGuest = createMockGuest(firstName: "David", lastName: "Lee", rsvpStatus: .pending, id: UUID())
        mockRepository.guests = [originalGuest]
        await store.loadGuestData()

        var updatedGuest = originalGuest
        updatedGuest.rsvpStatus = .attending
        mockRepository.shouldThrowError = true

        // When
        await store.updateGuest(updatedGuest)

        // Then - Should rollback to original
        XCTAssertEqual(store.guests.count, 1)
        XCTAssertEqual(store.guests[0].rsvpStatus, .pending)
        XCTAssertEqual(store.filteredGuests[0].rsvpStatus, .pending)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Delete Guest Tests

    func testDeleteGuest_Success() async throws {
        // Given
        let guest1 = createMockGuest(firstName: "Emma", lastName: "Davis", id: UUID())
        let guest2 = createMockGuest(firstName: "Frank", lastName: "Miller", id: UUID())
        mockRepository.guests = [guest1, guest2]
        mockRepository.guestStats = GuestStats(
            totalGuests: 1,
            attendingGuests: 0,
            pendingGuests: 1,
            declinedGuests: 0,
            responseRate: 0
        )

        await store.loadGuestData()

        // When
        await store.deleteGuest(id: guest1.id)

        // Then
        XCTAssertEqual(store.guests.count, 1)
        XCTAssertEqual(store.filteredGuests.count, 1)
        XCTAssertEqual(store.guests[0].id, guest2.id)
        XCTAssertNil(store.error)
        XCTAssertNotNil(store.guestStats)
    }

    func testDeleteGuest_Rollback() async throws {
        // Given
        let guest = createMockGuest(firstName: "Grace", lastName: "Taylor", id: UUID())
        mockRepository.guests = [guest]
        await store.loadGuestData()

        mockRepository.shouldThrowError = true

        // When
        await store.deleteGuest(id: guest.id)

        // Then - Should rollback
        XCTAssertEqual(store.guests.count, 1)
        XCTAssertEqual(store.filteredGuests.count, 1)
        XCTAssertEqual(store.guests[0].id, guest.id)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Search Tests

    func testSearchGuests_Success() async throws {
        // Given
        let allGuests = [
            createMockGuest(firstName: "Alice", lastName: "Anderson"),
            createMockGuest(firstName: "Bob", lastName: "Brown"),
            createMockGuest(firstName: "Alice", lastName: "Williams"),
        ]
        mockRepository.guests = allGuests

        // When
        await store.searchGuests(query: "Alice")

        // Then
        XCTAssertEqual(store.filteredGuests.count, 2)
        XCTAssertTrue(store.filteredGuests.allSatisfy { $0.firstName == "Alice" })
        XCTAssertNil(store.error)
    }

    // MARK: - Filter Tests

    func testFilterGuests_BySearchText() async throws {
        // Given
        mockRepository.guests = [
            createMockGuest(firstName: "John", lastName: "Doe"),
            createMockGuest(firstName: "Jane", lastName: "Smith"),
            createMockGuest(firstName: "John", lastName: "Williams"),
        ]
        await store.loadGuestData()

        // When
        store.filterGuests(searchText: "John", selectedStatus: nil, selectedInvitedBy: nil)

        // Then
        XCTAssertEqual(store.filteredGuests.count, 2)
        XCTAssertTrue(store.filteredGuests.allSatisfy { $0.firstName == "John" })
    }

    func testFilterGuests_ByRSVPStatus() async throws {
        // Given
        mockRepository.guests = [
            createMockGuest(firstName: "Guest1", rsvpStatus: .attending),
            createMockGuest(firstName: "Guest2", rsvpStatus: .pending),
            createMockGuest(firstName: "Guest3", rsvpStatus: .attending),
        ]
        await store.loadGuestData()

        // When
        store.filterGuests(searchText: "", selectedStatus: .attending, selectedInvitedBy: nil)

        // Then
        XCTAssertEqual(store.filteredGuests.count, 2)
        XCTAssertTrue(store.filteredGuests.allSatisfy { $0.rsvpStatus == .attending })
    }

    func testFilterGuests_Combined() async throws {
        // Given
        mockRepository.guests = [
            createMockGuest(firstName: "Alice", lastName: "Anderson", rsvpStatus: .attending),
            createMockGuest(firstName: "Alice", lastName: "Brown", rsvpStatus: .pending),
            createMockGuest(firstName: "Bob", lastName: "Smith", rsvpStatus: .attending),
        ]
        await store.loadGuestData()

        // When
        store.filterGuests(searchText: "Alice", selectedStatus: .attending, selectedInvitedBy: nil)

        // Then
        XCTAssertEqual(store.filteredGuests.count, 1)
        XCTAssertEqual(store.filteredGuests[0].firstName, "Alice")
        XCTAssertEqual(store.filteredGuests[0].rsvpStatus, .attending)
    }

    // MARK: - Computed Properties Tests

    func testComputedProperties() async throws {
        // Given
        mockRepository.guests = [
            createMockGuest(firstName: "Guest1", rsvpStatus: .attending),
            createMockGuest(firstName: "Guest2", rsvpStatus: .confirmed),
            createMockGuest(firstName: "Guest3", rsvpStatus: .pending),
            createMockGuest(firstName: "Guest4", rsvpStatus: .invited),
            createMockGuest(firstName: "Guest5", rsvpStatus: .declined),
        ]
        await store.loadGuestData()

        // Then
        XCTAssertEqual(store.totalGuests, 5)
        XCTAssertEqual(store.attendingGuests, 2) // attending + confirmed
        XCTAssertEqual(store.pendingGuests, 2) // pending + invited
    }

    // MARK: - Helper Methods

    private func createMockGuest(
        firstName: String,
        lastName: String = "TestLastName",
        rsvpStatus: RSVPStatus = .pending,
        id: UUID = UUID()
    ) -> Guest {
        Guest(
            id: id,
            createdAt: Date(),
            updatedAt: Date(),
            firstName: firstName,
            lastName: lastName,
            email: nil,
            phone: nil,
            guestGroupId: nil,
            relationshipToCouple: "Friend",
            invitedBy: nil,
            rsvpStatus: rsvpStatus,
            rsvpDate: nil,
            plusOneAllowed: false,
            plusOneName: nil,
            plusOneAttending: false,
            attendingCeremony: true,
            attendingReception: true,
            attendingOtherEvents: nil,
            dietaryRestrictions: nil,
            accessibilityNeeds: nil,
            tableAssignment: nil,
            seatNumber: nil,
            preferredContactMethod: nil,
            addressLine1: nil,
            addressLine2: nil,
            city: nil,
            state: nil,
            zipCode: nil,
            country: nil,
            invitationNumber: nil,
            isWeddingParty: false,
            weddingPartyRole: nil,
            preparationNotes: nil,
            coupleId: UUID(),
            mealOption: nil,
            giftReceived: false,
            notes: nil,
            hairDone: false,
            makeupDone: false
        )
    }
}
