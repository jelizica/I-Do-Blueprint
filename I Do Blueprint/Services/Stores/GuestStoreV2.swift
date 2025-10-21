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
    @Published var loadingState: LoadingState<[Guest]> = .idle
    @Published private(set) var guestStats: GuestStats?
    @Published private(set) var filteredGuests: [Guest] = []

    @Published var showSuccessToast = false
    @Published var successMessage = ""

    @Dependency(\.guestRepository) var repository
    
    // MARK: - Computed Properties for Backward Compatibility
    
    var guests: [Guest] {
        loadingState.data ?? []
    }
    
    var isLoading: Bool {
        loadingState.isLoading
    }
    
    var error: GuestError? {
        if case .error(let err) = loadingState {
            return err as? GuestError ?? .fetchFailed(underlying: err)
        }
        return nil
    }

    // MARK: - Public Interface

    func loadGuestData() async {
        // Only load if idle or error state
        guard loadingState.isIdle || loadingState.hasError else {
            return
        }
        
        loadingState = .loading

        do {
            async let guestsResult = repository.fetchGuests()
            async let statsResult = repository.fetchGuestStats()

            let fetchedGuests = try await guestsResult
            guestStats = try await statsResult
            filteredGuests = fetchedGuests
            
            loadingState = .loaded(fetchedGuests)
        } catch {
            loadingState = .error(GuestError.fetchFailed(underlying: error))
        }
    }

    func addGuest(_ guest: Guest) async {
        do {
            let created = try await repository.createGuest(guest)
            
            // Update loaded state with new guest
            if case .loaded(var currentGuests) = loadingState {
                currentGuests.append(created)
                loadingState = .loaded(currentGuests)
                filteredGuests = currentGuests
            }

            // Recalculate stats to include new guest
            guestStats = try await repository.fetchGuestStats()

            // Show success feedback
            HapticFeedback.itemAdded()
            showSuccess("Guest added successfully")
        } catch {
            loadingState = .error(GuestError.createFailed(underlying: error))
            await handleError(error, operation: "add guest") { [weak self] in
                await self?.addGuest(guest)
            }
        }
    }

    func updateGuest(_ guest: Guest) async {
        // Optimistic UI update - show changes immediately before server confirms
        guard case .loaded(var currentGuests) = loadingState,
              let index = currentGuests.firstIndex(where: { $0.id == guest.id }) else {
            return
        }
        
        let original = currentGuests[index]
        currentGuests[index] = guest
        loadingState = .loaded(currentGuests)

        // Keep filtered list in sync with main list
        if let filteredIndex = filteredGuests.firstIndex(where: { $0.id == guest.id }) {
            filteredGuests[filteredIndex] = guest
        }

        do {
            // Persist to backend and get confirmed data
            let updated = try await repository.updateGuest(guest)
            
            if case .loaded(var guests) = loadingState,
               let idx = guests.firstIndex(where: { $0.id == guest.id }) {
                guests[idx] = updated
                loadingState = .loaded(guests)
            }

            // Update filtered list with server-confirmed data
            if let filteredIndex = filteredGuests.firstIndex(where: { $0.id == guest.id }) {
                filteredGuests[filteredIndex] = updated
            }

            // Recalculate guest statistics after update
            guestStats = try await repository.fetchGuestStats()
            
            showSuccess("Guest updated successfully")
        } catch {
            // Revert optimistic update if server request fails
            if case .loaded(var guests) = loadingState,
               let idx = guests.firstIndex(where: { $0.id == guest.id }) {
                guests[idx] = original
                loadingState = .loaded(guests)
            }
            if let filteredIndex = filteredGuests.firstIndex(where: { $0.id == guest.id }) {
                filteredGuests[filteredIndex] = original
            }
            loadingState = .error(GuestError.updateFailed(underlying: error))
            await handleError(error, operation: "update guest") { [weak self] in
                await self?.updateGuest(guest)
            }
        }
    }

    func deleteGuest(id: UUID) async {
        // Optimistic delete - remove from UI immediately
        guard case .loaded(var currentGuests) = loadingState,
              let index = currentGuests.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let removed = currentGuests.remove(at: index)
        loadingState = .loaded(currentGuests)

        // Keep filtered list in sync
        if let filteredIndex = filteredGuests.firstIndex(where: { $0.id == id }) {
            filteredGuests.remove(at: filteredIndex)
        }

        do {
            // Persist deletion to backend
            try await repository.deleteGuest(id: id)

            // Recalculate statistics without deleted guest
            guestStats = try await repository.fetchGuestStats()
            
            showSuccess("Guest deleted successfully")
        } catch {
            // Restore guest if deletion fails
            if case .loaded(var guests) = loadingState {
                guests.insert(removed, at: index)
                loadingState = .loaded(guests)
                filteredGuests = guests
            }
            loadingState = .error(GuestError.deleteFailed(underlying: error))
            await handleError(error, operation: "delete guest") { [weak self] in
                await self?.deleteGuest(id: id)
            }
        }
    }

    func searchGuests(query: String) async {
        do {
            filteredGuests = try await repository.searchGuests(query: query)
        } catch {
            loadingState = .error(GuestError.fetchFailed(underlying: error))
        }
    }

    func filterGuests(
        searchText: String,
        selectedStatus: RSVPStatus?,
        selectedInvitedBy: InvitedBy?) {
        var filtered = loadingState.data ?? []

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
    
    // MARK: - Retry Helper
    
    func retryLoad() async {
        await loadGuestData()
    }
}
