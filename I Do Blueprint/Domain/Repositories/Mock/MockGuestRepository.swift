//
//  MockGuestRepository.swift
//  My Wedding Planning App
//
//  Mock implementation of GuestRepositoryProtocol for testing
//

import Foundation

/// Mock implementation for testing
@MainActor
class MockGuestRepository: GuestRepositoryProtocol {
    // Storage
    var guests: [Guest] = []
    var guestStats: GuestStats?

    // Call tracking
    var fetchGuestsCalled = false
    var fetchStatsCalled = false
    var createGuestCalled = false
    var updateGuestCalled = false
    var deleteGuestCalled = false
    var searchGuestsCalled = false

    // Error control
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: -1)

    // Delay simulation
    var delay: TimeInterval = 0

    init() {}

    func fetchGuests() async throws -> [Guest] {
        fetchGuestsCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        return guests
    }

    func fetchGuestStats() async throws -> GuestStats {
        fetchStatsCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }

        if let guestStats {
            return guestStats
        }

        // Calculate stats from guests array
        let totalGuests = guests.count
        let attendingGuests = guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count
        let pendingGuests = guests.filter { $0.rsvpStatus == .pending || $0.rsvpStatus == .invited }.count
        let declinedGuests = guests.filter { $0.rsvpStatus == .declined }.count

        let responseRate: Double
        if totalGuests > 0 {
            let responded = totalGuests - pendingGuests
            responseRate = (Double(responded) / Double(totalGuests)) * 100
        } else {
            responseRate = 0
        }

        return GuestStats(
            totalGuests: totalGuests,
            attendingGuests: attendingGuests,
            pendingGuests: pendingGuests,
            declinedGuests: declinedGuests,
            responseRate: responseRate)
    }

    func createGuest(_ guest: Guest) async throws -> Guest {
        createGuestCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        guests.append(guest)
        return guest
    }

    func updateGuest(_ guest: Guest) async throws -> Guest {
        updateGuestCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        if let index = guests.firstIndex(where: { $0.id == guest.id }) {
            guests[index] = guest
        }
        return guest
    }

    func deleteGuest(id: UUID) async throws {
        deleteGuestCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }
        guests.removeAll { $0.id == id }
    }

    func searchGuests(query: String) async throws -> [Guest] {
        searchGuestsCalled = true
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }

        guard !query.isEmpty else {
            return guests
        }

        return guests.filter { guest in
            guest.fullName.localizedCaseInsensitiveContains(query) ||
                guest.email?.localizedCaseInsensitiveContains(query) == true ||
                guest.phone?.contains(query) == true
        }
    }

    func importGuests(_ guests: [Guest]) async throws -> [Guest] {
        if delay > 0 { try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000)) }
        if shouldThrowError { throw errorToThrow }

        // Add all guests to the storage
        self.guests.append(contentsOf: guests)

        // Return the imported guests (simulating database insert with IDs)
        return guests
    }

    // MARK: - Testing Utilities

    /// Reset all call tracking flags
    func resetFlags() {
        fetchGuestsCalled = false
        fetchStatsCalled = false
        createGuestCalled = false
        updateGuestCalled = false
        deleteGuestCalled = false
        searchGuestsCalled = false
    }

    /// Reset all data to defaults
    func resetData() {
        guests = []
        guestStats = nil
        resetFlags()
    }
}
