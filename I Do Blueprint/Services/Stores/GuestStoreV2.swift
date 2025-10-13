//
//  GuestStoreV2.swift
//  My Wedding Planning App
//
//  New architecture version of guest management using repository pattern
//

import Combine
import Dependencies
import Foundation
import SwiftUI

/// New architecture version using repositories and dependency injection
@MainActor
class GuestStoreV2: ObservableObject {
    @Published private(set) var guests: [Guest] = []
    @Published private(set) var guestStats: GuestStats?
    @Published private(set) var filteredGuests: [Guest] = []

    @Published var isLoading = false
    @Published var error: GuestError?
    @Published var showSuccessToast = false
    @Published var successMessage = ""

    @Dependency(\.guestRepository) var repository

    // MARK: - Public Interface

    func loadGuestData() async {
        isLoading = true
        error = nil

        do {
            // Fetch guests and stats concurrently for better performance
            async let guestsResult = repository.fetchGuests()
            async let statsResult = repository.fetchGuestStats()

            guests = try await guestsResult
            guestStats = try await statsResult
            filteredGuests = guests
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func addGuest(_ guest: Guest) async {
        isLoading = true
        error = nil

        do {
            let created = try await repository.createGuest(guest)
            guests.append(created)
            filteredGuests = guests

            // Recalculate stats to include new guest
            guestStats = try await repository.fetchGuestStats()

            // Show success toast
            HapticFeedback.itemAdded()
            successMessage = "Guest added successfully!"
            showSuccessToast = true
        } catch {
            self.error = .createFailed(underlying: error)
        }

        isLoading = false
    }

    func updateGuest(_ guest: Guest) async {
        // Optimistic UI update - show changes immediately before server confirms
        if let index = guests.firstIndex(where: { $0.id == guest.id }) {
            let original = guests[index]
            guests[index] = guest

            // Keep filtered list in sync with main list
            if let filteredIndex = filteredGuests.firstIndex(where: { $0.id == guest.id }) {
                filteredGuests[filteredIndex] = guest
            }

            do {
                // Persist to backend and get confirmed data
                let updated = try await repository.updateGuest(guest)
                guests[index] = updated

                // Update filtered list with server-confirmed data
                if let filteredIndex = filteredGuests.firstIndex(where: { $0.id == guest.id }) {
                    filteredGuests[filteredIndex] = updated
                }

                // Recalculate guest statistics after update
                guestStats = try await repository.fetchGuestStats()
            } catch {
                // Revert optimistic update if server request fails
                guests[index] = original
                if let filteredIndex = filteredGuests.firstIndex(where: { $0.id == guest.id }) {
                    filteredGuests[filteredIndex] = original
                }
                self.error = .updateFailed(underlying: error)
            }
        }
    }

    func deleteGuest(id: UUID) async {
        // Optimistic delete - remove from UI immediately
        guard let index = guests.firstIndex(where: { $0.id == id }) else { return }
        let removed = guests.remove(at: index)

        // Keep filtered list in sync
        if let filteredIndex = filteredGuests.firstIndex(where: { $0.id == id }) {
            filteredGuests.remove(at: filteredIndex)
        }

        do {
            // Persist deletion to backend
            try await repository.deleteGuest(id: id)

            // Recalculate statistics without deleted guest
            guestStats = try await repository.fetchGuestStats()
        } catch {
            // Restore guest if deletion fails
            guests.insert(removed, at: index)
            filteredGuests = guests
            self.error = .deleteFailed(underlying: error)
        }
    }

    func searchGuests(query: String) async {
        do {
            filteredGuests = try await repository.searchGuests(query: query)
        } catch {
            self.error = .fetchFailed(underlying: error)
        }
    }

    func filterGuests(
        searchText: String,
        selectedStatus: RSVPStatus?,
        selectedInvitedBy: InvitedBy?) {
        var filtered = guests

        // Search across name, email, and phone fields
        if !searchText.isEmpty {
            filtered = filtered.filter { guest in
                guest.fullName.localizedCaseInsensitiveContains(searchText) ||
                    guest.email?.localizedCaseInsensitiveContains(searchText) == true ||
                    guest.phone?.contains(searchText) == true
            }
        }

        // Filter by RSVP status (attending, pending, declined)
        if let status = selectedStatus {
            filtered = filtered.filter { $0.rsvpStatus == status }
        }

        // Filter by which side invited the guest (bride/groom/both)
        if let invitedBy = selectedInvitedBy {
            filtered = filtered.filter { $0.invitedBy == invitedBy }
        }

        filteredGuests = filtered
    }

    // MARK: - Computed Properties

    var totalGuests: Int {
        guests.count
    }

    var attendingGuests: Int {
        guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count
    }

    var pendingGuests: Int {
        guests.filter { $0.rsvpStatus == .pending || $0.rsvpStatus == .invited }.count
    }
}
