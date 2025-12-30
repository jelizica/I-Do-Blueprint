//
//  MockGuestRepository.swift
//  I Do BlueprintTests
//
//  Mock implementation of GuestRepositoryProtocol for testing
//

import Foundation
@testable import I_Do_Blueprint

class MockGuestRepository: GuestRepositoryProtocol {
    var guests: [Guest] = []
    var guestStats: GuestStats = GuestStats(totalGuests: 0, attendingGuests: 0, pendingGuests: 0, declinedGuests: 0, responseRate: 0.0)
    var shouldThrowError = false
    var errorToThrow: GuestError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

    func fetchGuests() async throws -> [Guest] {
        if shouldThrowError { throw errorToThrow }
        return guests
    }

    func fetchGuestStats() async throws -> GuestStats {
        if shouldThrowError { throw errorToThrow }
        return guestStats
    }

    func createGuest(_ guest: Guest) async throws -> Guest {
        if shouldThrowError { throw errorToThrow }
        guests.append(guest)
        return guest
    }

    func updateGuest(_ guest: Guest) async throws -> Guest {
        if shouldThrowError { throw errorToThrow }
        if let index = guests.firstIndex(where: { $0.id == guest.id }) {
            guests[index] = guest
        }
        return guest
    }

    func deleteGuest(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        guests.removeAll(where: { $0.id == id })
    }

    func searchGuests(query: String) async throws -> [Guest] {
        if shouldThrowError { throw errorToThrow }
        return guests.filter {
            $0.firstName.localizedCaseInsensitiveContains(query) ||
            $0.lastName.localizedCaseInsensitiveContains(query)
        }
    }
}
