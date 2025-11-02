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
class GuestStoreV2: ObservableObject, CacheableStore {
    @Published var loadingState: LoadingState<[Guest]> = .idle
    @Published private(set) var guestStats: GuestStats?
    @Published private(set) var filteredGuests: [Guest] = []

    @Published var showSuccessToast = false
    @Published var successMessage = ""

    // MARK: - Cache Management
    var lastLoadTime: Date?
    let cacheValidityDuration: TimeInterval = 60 // 1 minute (fast-changing)

    @Dependency(\.guestRepository) var repository
    
    // Task tracking for cancellation handling
    private var loadTask: Task<Void, Never>?
    private var addTask: Task<Void, Never>?
    private var updateTask: Task<Void, Never>?
    private var deleteTask: Task<Void, Never>?
    
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

    func loadGuestData(force: Bool = false) async {
        // Cancel any previous load task
        loadTask?.cancel()
        
        // Create new load task
        loadTask = Task { @MainActor in
            let totalStart = Date()
            var mainThreadAccumulated: TimeInterval = 0

            // Use cached data if still valid
            if !force && isCacheValid() {
                AppLogger.ui.debug("Using cached guest data (age: \(Int(cacheAge()))s)")
                return
            }
            // Only load if idle or error state
            guard loadingState.isIdle || loadingState.hasError || force else {
                return
            }
            
            // Mark main-thread work: set loading state
            do {
                let t0 = Date()
                loadingState = .loading
                mainThreadAccumulated += Date().timeIntervalSince(t0)
            }

            do {
                // Check for cancellation before expensive operations
                try Task.checkCancellation()

                // Measure sub-operations
                let guestsStart = Date()
                async let guestsResult = repository.fetchGuests()
                let statsStart = Date()
                async let statsResult = repository.fetchGuestStats()

                let fetchedGuests = try await guestsResult
                let fetchedStats = try await statsResult

                // Record sub-operation durations
                await PerformanceMonitor.shared.recordOperation("guest.fetchGuests", duration: Date().timeIntervalSince(guestsStart))
                await PerformanceMonitor.shared.recordOperation("guest.fetchGuestStats", duration: Date().timeIntervalSince(statsStart))
                
                // Check again before updating state
                try Task.checkCancellation()
                
                // Main-thread updates
                let t1 = Date()
                guestStats = fetchedStats
                filteredGuests = fetchedGuests
                loadingState = .loaded(fetchedGuests)
                lastLoadTime = Date()
                mainThreadAccumulated += Date().timeIntervalSince(t1)
            } catch is CancellationError {
                // Don't treat cancellation as error - it's expected during tenant switch
                AppLogger.ui.debug("GuestStoreV2.loadGuestData: Load cancelled (expected during tenant switch)")
                // Reset to idle so next load can proceed
                let tCancel = Date()
                loadingState = .idle
                mainThreadAccumulated += Date().timeIntervalSince(tCancel)
            } catch let error as URLError where error.code == .cancelled {
                // URLError cancellation - also expected
                AppLogger.ui.debug("GuestStoreV2.loadGuestData: Load cancelled (URLError)")
                // Reset to idle so next load can proceed
                let tCancel = Date()
                loadingState = .idle
                mainThreadAccumulated += Date().timeIntervalSince(tCancel)
            } catch {
                let tErr = Date()
                loadingState = .error(GuestError.fetchFailed(underlying: error))
                mainThreadAccumulated += Date().timeIntervalSince(tErr)
                AppLogger.ui.error("GuestStoreV2.loadGuestData: Failed to fetch guests", error: error)
            }

            // Record total
            await PerformanceMonitor.shared.recordOperation(
                "guest.loadGuestData",
                duration: Date().timeIntervalSince(totalStart),
                mainThread: mainThreadAccumulated
            )
        }
        
        await loadTask?.value
    }

    func addGuest(_ guest: Guest) async {
        // Cancel any previous add task
        addTask?.cancel()
        
        // Create new add task
        addTask = Task { @MainActor in
            // Add breadcrumb for debugging
            addOperationBreadcrumb(
                "addGuest",
                category: "guest",
                data: ["guestName": guest.fullName]
            )
            
            do {
                try Task.checkCancellation()
                
                let created = try await repository.createGuest(guest)
                
                try Task.checkCancellation()
                
                // Update loaded state with new guest
                if case .loaded(var currentGuests) = loadingState {
                    currentGuests.append(created)
                    loadingState = .loaded(currentGuests)
                    filteredGuests = currentGuests
                }

                // Recalculate stats to include new guest
                guestStats = try await repository.fetchGuestStats()

                // Invalidate store cache since data changed
                invalidateCache()

                // Show success feedback
                HapticFeedback.itemAdded()
                showSuccess("Guest added successfully")
            } catch is CancellationError {
                AppLogger.ui.debug("GuestStoreV2.addGuest: Operation cancelled")
            } catch let error as URLError where error.code == .cancelled {
                AppLogger.ui.debug("GuestStoreV2.addGuest: Operation cancelled (URLError)")
            } catch {
                loadingState = .error(GuestError.createFailed(underlying: error))
                ErrorHandler.shared.handle(
                    error,
                    context: ErrorContext(
                        operation: "addGuest",
                        feature: "guest",
                        metadata: ["guestName": guest.fullName]
                    )
                )
            }
        }
        
        await addTask?.value
    }

    func updateGuest(_ guest: Guest) async {
        // Cancel any previous update task
        updateTask?.cancel()
        
        // Create new update task
        updateTask = Task { @MainActor in
            // Add breadcrumb for debugging
            addOperationBreadcrumb(
                "updateGuest",
                category: "guest",
                data: [
                    "guestId": guest.id.uuidString,
                    "guestName": guest.fullName
                ]
            )
            
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
                try Task.checkCancellation()
                
                // Persist to backend and get confirmed data
                let updated = try await repository.updateGuest(guest)
                
                try Task.checkCancellation()
                
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
                
                // Invalidate store cache since data changed
                invalidateCache()
                
                showSuccess("Guest updated successfully")
            } catch is CancellationError {
                // Revert optimistic update on cancellation
                if case .loaded(var guests) = loadingState,
                   let idx = guests.firstIndex(where: { $0.id == guest.id }) {
                    guests[idx] = original
                    loadingState = .loaded(guests)
                }
                if let filteredIndex = filteredGuests.firstIndex(where: { $0.id == guest.id }) {
                    filteredGuests[filteredIndex] = original
                }
                AppLogger.ui.debug("GuestStoreV2.updateGuest: Operation cancelled")
            } catch let error as URLError where error.code == .cancelled {
                // Revert optimistic update on cancellation
                if case .loaded(var guests) = loadingState,
                   let idx = guests.firstIndex(where: { $0.id == guest.id }) {
                    guests[idx] = original
                    loadingState = .loaded(guests)
                }
                if let filteredIndex = filteredGuests.firstIndex(where: { $0.id == guest.id }) {
                    filteredGuests[filteredIndex] = original
                }
                AppLogger.ui.debug("GuestStoreV2.updateGuest: Operation cancelled (URLError)")
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
                ErrorHandler.shared.handle(
                    error,
                    context: ErrorContext(
                        operation: "updateGuest",
                        feature: "guest",
                        metadata: [
                            "guestId": guest.id.uuidString,
                            "guestName": guest.fullName
                        ]
                    )
                )
            }
        }
        
        await updateTask?.value
    }

    func deleteGuest(id: UUID) async {
        // Cancel any previous delete task
        deleteTask?.cancel()
        
        // Create new delete task
        deleteTask = Task { @MainActor in
            // Add breadcrumb for debugging
            addOperationBreadcrumb(
                "deleteGuest",
                category: "guest",
                data: ["guestId": id.uuidString]
            )
            
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
                try Task.checkCancellation()
                
                // Persist deletion to backend
                try await repository.deleteGuest(id: id)
                
                try Task.checkCancellation()

                // Recalculate statistics without deleted guest
                guestStats = try await repository.fetchGuestStats()
                
                // Invalidate store cache since data changed
                invalidateCache()
                
                showSuccess("Guest deleted successfully")
            } catch is CancellationError {
                // Restore guest on cancellation
                if case .loaded(var guests) = loadingState {
                    guests.insert(removed, at: index)
                    loadingState = .loaded(guests)
                    filteredGuests = guests
                }
                AppLogger.ui.debug("GuestStoreV2.deleteGuest: Operation cancelled")
            } catch let error as URLError where error.code == .cancelled {
                // Restore guest on cancellation
                if case .loaded(var guests) = loadingState {
                    guests.insert(removed, at: index)
                    loadingState = .loaded(guests)
                    filteredGuests = guests
                }
                AppLogger.ui.debug("GuestStoreV2.deleteGuest: Operation cancelled (URLError)")
            } catch {
                // Restore guest if deletion fails
                if case .loaded(var guests) = loadingState {
                    guests.insert(removed, at: index)
                    loadingState = .loaded(guests)
                    filteredGuests = guests
                }
                loadingState = .error(GuestError.deleteFailed(underlying: error))
                ErrorHandler.shared.handle(
                    error,
                    context: ErrorContext(
                        operation: "deleteGuest",
                        feature: "guest",
                        metadata: ["guestId": id.uuidString]
                    )
                )
            }
        }
        
        await deleteTask?.value
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
    
    // MARK: - State Management
    
    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        // Cancel in-flight tasks to avoid race conditions during tenant switch
        loadTask?.cancel()
        addTask?.cancel()
        updateTask?.cancel()
        deleteTask?.cancel()
        
        // Reset state and invalidate cache
        loadingState = .idle
        guestStats = nil
        filteredGuests = []
        lastLoadTime = nil
    }
}
