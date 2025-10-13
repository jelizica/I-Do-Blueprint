//
//  GuestRepositoryTests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for GuestRepository implementations
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class GuestRepositoryTests: XCTestCase {
    var mockRepository: MockGuestRepository!

    override func setUp() async throws {
        mockRepository = MockGuestRepository()
    }

    override func tearDown() async throws {
        mockRepository = nil
    }

    // MARK: - Fetch Guests Tests

    func testFetchGuests_Success() async throws {
        // Given
        mockRepository.guests = [
            createMockGuest(firstName: "John", lastName: "Doe", rsvpStatus: .attending),
            createMockGuest(firstName: "Jane", lastName: "Smith", rsvpStatus: .pending),
        ]

        // When
        let result = try await mockRepository.fetchGuests()

        // Then
        XCTAssertTrue(mockRepository.fetchGuestsCalled)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].firstName, "John")
        XCTAssertEqual(result[1].lastName, "Smith")
    }

    func testFetchGuests_EmptyResult() async throws {
        // Given
        mockRepository.guests = []

        // When
        let result = try await mockRepository.fetchGuests()

        // Then
        XCTAssertTrue(mockRepository.fetchGuestsCalled)
        XCTAssertTrue(result.isEmpty)
    }

    func testFetchGuests_ErrorHandling() async throws {
        // Given
        mockRepository.shouldThrowError = true

        // When/Then
        do {
            _ = try await mockRepository.fetchGuests()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(mockRepository.fetchGuestsCalled)
        }
    }

    // MARK: - Fetch Stats Tests

    func testFetchGuestStats_CalculatesCorrectly() async throws {
        // Given
        mockRepository.guests = [
            createMockGuest(firstName: "Guest1", rsvpStatus: .attending),
            createMockGuest(firstName: "Guest2", rsvpStatus: .attending),
            createMockGuest(firstName: "Guest3", rsvpStatus: .confirmed),
            createMockGuest(firstName: "Guest4", rsvpStatus: .pending),
            createMockGuest(firstName: "Guest5", rsvpStatus: .declined),
        ]

        // When
        let stats = try await mockRepository.fetchGuestStats()

        // Then
        XCTAssertTrue(mockRepository.fetchStatsCalled)
        XCTAssertEqual(stats.totalGuests, 5)
        XCTAssertEqual(stats.attendingGuests, 3) // attending + confirmed
        XCTAssertEqual(stats.pendingGuests, 1)
        XCTAssertEqual(stats.declinedGuests, 1)
    }

    func testFetchGuestStats_ResponseRateCalculation() async throws {
        // Given - 8 guests: 6 responded (3 attending, 3 declined), 2 pending
        mockRepository.guests = [
            createMockGuest(firstName: "G1", rsvpStatus: .attending),
            createMockGuest(firstName: "G2", rsvpStatus: .attending),
            createMockGuest(firstName: "G3", rsvpStatus: .attending),
            createMockGuest(firstName: "G4", rsvpStatus: .declined),
            createMockGuest(firstName: "G5", rsvpStatus: .declined),
            createMockGuest(firstName: "G6", rsvpStatus: .declined),
            createMockGuest(firstName: "G7", rsvpStatus: .pending),
            createMockGuest(firstName: "G8", rsvpStatus: .pending),
        ]

        // When
        let stats = try await mockRepository.fetchGuestStats()

        // Then
        // Response rate = (total - pending) / total * 100 = (8 - 2) / 8 * 100 = 75%
        XCTAssertEqual(stats.responseRate, 75.0, accuracy: 0.01)
    }

    func testFetchGuestStats_EmptyGuestList() async throws {
        // Given
        mockRepository.guests = []

        // When
        let stats = try await mockRepository.fetchGuestStats()

        // Then
        XCTAssertEqual(stats.totalGuests, 0)
        XCTAssertEqual(stats.attendingGuests, 0)
        XCTAssertEqual(stats.responseRate, 0)
    }

    // MARK: - Create Guest Tests

    func testCreateGuest_Success() async throws {
        // Given
        let newGuest = createMockGuest(firstName: "Alice", lastName: "Johnson")

        // When
        let created = try await mockRepository.createGuest(newGuest)

        // Then
        XCTAssertTrue(mockRepository.createGuestCalled)
        XCTAssertEqual(created.firstName, "Alice")
        XCTAssertEqual(created.lastName, "Johnson")
        XCTAssertEqual(mockRepository.guests.count, 1)
    }

    func testCreateGuest_ErrorHandling() async throws {
        // Given
        mockRepository.shouldThrowError = true
        let newGuest = createMockGuest(firstName: "Bob", lastName: "Wilson")

        // When/Then
        do {
            _ = try await mockRepository.createGuest(newGuest)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(mockRepository.createGuestCalled)
            XCTAssertTrue(mockRepository.guests.isEmpty)
        }
    }

    // MARK: - Update Guest Tests

    func testUpdateGuest_Success() async throws {
        // Given
        let original = createMockGuest(firstName: "Charlie", lastName: "Brown", rsvpStatus: .pending)
        mockRepository.guests = [original]

        var updated = original
        updated.email = "charlie.updated@example.com"
        updated.phone = "555-9999"
        updated.rsvpStatus = .attending
        updated.dietaryRestrictions = "Vegetarian"
        updated.notes = "Updated notes"
        updated.updatedAt = Date()

        // When
        let result = try await mockRepository.updateGuest(updated)

        // Then
        XCTAssertTrue(mockRepository.updateGuestCalled)
        XCTAssertEqual(result.rsvpStatus, .attending)
        XCTAssertEqual(result.email, "charlie.updated@example.com")
        XCTAssertEqual(mockRepository.guests.first?.rsvpStatus, .attending)
    }

    func testUpdateGuest_ChangingRSVPStatus() async throws {
        // Given
        let pendingGuest = createMockGuest(firstName: "David", rsvpStatus: .pending)
        mockRepository.guests = [pendingGuest]

        var attendingGuest = pendingGuest
        attendingGuest.rsvpStatus = .attending

        // When
        _ = try await mockRepository.updateGuest(attendingGuest)

        // Then
        XCTAssertEqual(mockRepository.guests.first?.rsvpStatus, .attending)
    }

    // MARK: - Delete Guest Tests

    func testDeleteGuest_Success() async throws {
        // Given
        let guest1 = createMockGuest(firstName: "Emma", id: UUID())
        let guest2 = createMockGuest(firstName: "Frank", id: UUID())
        mockRepository.guests = [guest1, guest2]

        // When
        try await mockRepository.deleteGuest(id: guest1.id)

        // Then
        XCTAssertTrue(mockRepository.deleteGuestCalled)
        XCTAssertEqual(mockRepository.guests.count, 1)
        XCTAssertEqual(mockRepository.guests.first?.id, guest2.id)
    }

    func testDeleteGuest_NonexistentGuest() async throws {
        // Given
        mockRepository.guests = [createMockGuest(firstName: "Grace")]

        // When
        try await mockRepository.deleteGuest(id: UUID())

        // Then
        XCTAssertTrue(mockRepository.deleteGuestCalled)
        XCTAssertEqual(mockRepository.guests.count, 1) // Guest still exists
    }

    func testDeleteGuest_ErrorHandling() async throws {
        // Given
        let guest = createMockGuest(firstName: "Henry")
        mockRepository.guests = [guest]
        mockRepository.shouldThrowError = true

        // When/Then
        do {
            try await mockRepository.deleteGuest(id: guest.id)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(mockRepository.deleteGuestCalled)
            XCTAssertEqual(mockRepository.guests.count, 1) // Not deleted due to error
        }
    }

    // MARK: - Search Guests Tests

    func testSearchGuests_Success() async throws {
        // Given
        mockRepository.guests = [
            createMockGuest(firstName: "Alice", lastName: "Anderson"),
            createMockGuest(firstName: "Bob", lastName: "Brown"),
            createMockGuest(firstName: "Alice", lastName: "Williams"),
        ]

        // When
        let results = try await mockRepository.searchGuests(query: "Alice")

        // Then
        XCTAssertTrue(mockRepository.searchGuestsCalled)
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.firstName == "Alice" })
    }

    // MARK: - Helper Methods

    private func createMockGuest(
        firstName: String,
        lastName: String = "TestLastName",
        email: String? = nil,
        rsvpStatus: RSVPStatus = .pending,
        id: UUID = UUID()
    ) -> Guest {
        Guest(
            id: id,
            createdAt: Date(),
            updatedAt: Date(),
            firstName: firstName,
            lastName: lastName,
            email: email,
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
