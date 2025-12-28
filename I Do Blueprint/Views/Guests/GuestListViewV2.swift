//
//  GuestListViewV2.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/1/25.
//  Modern redesigned guest list with improved UI/UX
//

import Combine
import Supabase
import SwiftUI

struct GuestListViewV2: View {
    @Environment(\.appStores) private var appStores
    
    // ✅ CRITICAL: Use @ObservedObject to properly observe store changes
    // This ensures SwiftUI subscribes to all @Published properties and updates the view
    // when any of them change (loadingState, filteredGuests, guestStats, etc.)
    @ObservedObject private var guestStore: GuestStoreV2
    @ObservedObject private var settingsStore: SettingsStoreV2
    
    // Initialize stores from environment
    init(appStores: AppStores? = nil) {
        let stores = appStores ?? AppStores.shared
        _guestStore = ObservedObject(initialValue: stores.guest)
        _settingsStore = ObservedObject(initialValue: stores.settings)
    }
    
    @State private var searchText = ""
    @State private var selectedStatus: RSVPStatus?
    @State private var selectedInvitedBy: InvitedBy?
    @State private var selectedSortOption: GuestSortOption = .nameAsc
    @State private var showingAddGuest = false
    @State private var showingImport = false
    @State private var selectedGuest: Guest?
    @State private var groupByStatus = true
    
    // Memoized filtered and sorted guests to avoid recomputation on every render
    @State private var cachedFilteredGuests: [Guest] = []
    
    // Debounce task for search text to avoid filtering on every keystroke
    @State private var searchDebounceTask: Task<Void, Never>?
    
    // Filter task to cancel stale filtering operations
    @State private var filterTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            mainContent(guestStore: guestStore, settingsStore: settingsStore)
                .navigationTitle("Wedding Guests")
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showingImport = true
                        } label: {
                            Label("Import CSV", systemImage: "square.and.arrow.down")
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingAddGuest = true
                        } label: {
                            Label("Add Guest", systemImage: "plus.circle.fill")
                        }
                        .keyboardShortcut("n", modifiers: .command)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .sheet(isPresented: $showingAddGuest) {
                    AddGuestView { newGuest in
                        await addGuest(newGuest, guestStore: guestStore)
                        showingAddGuest = false
                    }
                    .frame(width: 900, height: 750)
                }
                .sheet(isPresented: $showingImport) {
                    GuestCSVImportView()
                        .environmentObject(guestStore)
                        .frame(minWidth: 700, maxWidth: 900, minHeight: 600, maxHeight: 800)
                }
                .successToast(
                    isPresented: Binding(
                        get: { guestStore.showSuccessToast },
                        set: { guestStore.showSuccessToast = $0 }
                    ),
                    message: guestStore.successMessage
                )
                .task {
                    await guestStore.loadGuestData()
                }
                .onAppear {
                    updateFilteredGuests()
                }
                .onDisappear {
                    // Cancel any in-flight tasks to prevent leaks and stale updates
                    searchDebounceTask?.cancel()
                    searchDebounceTask = nil
                    filterTask?.cancel()
                    filterTask = nil
                }
                .onChange(of: searchText) { _ in
                    // Cancel any existing debounce task
                    searchDebounceTask?.cancel()
                    
                    // Create new debounced task
                    searchDebounceTask = Task {
                        // Wait 250ms before filtering
                        try? await Task.sleep(nanoseconds: 250_000_000)
                        
                        // Check if task was cancelled
                        guard !Task.isCancelled else { return }
                        
                        // Update on main actor
                        await updateFilteredGuests()
                    }
                }
                .onChange(of: selectedStatus) { _ in
                    updateFilteredGuests()
                }
                .onChange(of: selectedInvitedBy) { _ in
                    updateFilteredGuests()
                }
                .onChange(of: selectedSortOption) { _ in
                    updateFilteredGuests()
                }
                .onChange(of: guestStore.guests) { _ in
                    updateFilteredGuests()
                }
                .onReceive(NotificationCenter.default.publisher(for: .deleteGuest)) { notification in
                    if let guestIdString = notification.userInfo?["guestId"] as? String,
                       let guestId = UUID(uuidString: guestIdString) {
                        Task {
                            await guestStore.deleteGuest(id: guestId)
                            selectedGuest = nil
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .updateGuest)) { notification in
                    if let updatedGuestData = notification.userInfo?["guest"] as? Data,
                       let updatedGuest = try? JSONDecoder().decode(Guest.self, from: updatedGuestData) {
                        Task {
                            await guestStore.updateGuest(updatedGuest)
                        }
                    }
                }
                                .alert("Error", isPresented: Binding(
                    get: { guestStore.error != nil },
                    set: { _ in }
                )) {
                    Button("OK") {}
                    if guestStore.error != nil {
                        Button("Retry") {
                            Task {
                                await guestStore.retryLoad()
                            }
                        }
                    }
                } message: {
                    if let error = guestStore.error {
                        Text(error.errorDescription ?? "Unknown error")
                    }
                }
        }
    }

    // MARK: - Subviews

    private func mainContent(guestStore: GuestStoreV2, settingsStore: SettingsStoreV2) -> some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                leftPanel(geometry: geometry, guestStore: guestStore)
                Divider()
                rightPanel(guestStore: guestStore, settingsStore: settingsStore)
            }
        }
    }

    private func leftPanel(geometry: GeometryProxy, guestStore: GuestStoreV2) -> some View {
        VStack(spacing: 0) {
            if let stats = guestStore.guestStats {
                ModernStatsView(stats: stats)
                    .padding(Spacing.md)
            }

            Divider()

            ModernSearchBar(
                searchText: $searchText,
                selectedStatus: $selectedStatus,
                selectedInvitedBy: $selectedInvitedBy,
                selectedSortOption: $selectedSortOption,
                groupByStatus: $groupByStatus,
                guestStore: guestStore,
                filteredCount: cachedFilteredGuests.count,
                totalCount: guestStore.guests.count
            )
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            Divider()

            guestListView(guestStore: guestStore)
        }
        .frame(
            minWidth: ResponsiveLayout.minListPanelWidth,
            maxWidth: ResponsiveLayout.listPanelWidth(for: geometry)
        )
        .background(AppColors.background)
    }

    private func guestListView(guestStore: GuestStoreV2) -> some View {
        Group {
            if groupByStatus {
                GroupedGuestListView(
                    guests: cachedFilteredGuests,
                    isLoading: guestStore.isLoading,
                    selectedGuest: $selectedGuest,
                    onRefresh: {
                        await guestStore.loadGuestData()
                    }
                )
            } else {
                ModernGuestListView(
                    guests: cachedFilteredGuests,
                    totalCount: guestStore.guests.count,
                    isLoading: guestStore.isLoading,
                    isSearching: !searchText.isEmpty,
                    onClearSearch: { searchText = "" },
                    selectedGuest: $selectedGuest,
                    onRefresh: {
                        await guestStore.loadGuestData()
                    }
                )
            }
        }
    }
    
    // MARK: - Memoized Filtering and Sorting
    
    /// Updates the cached filtered guests only when dependencies change
    /// This prevents recomputation on every SwiftUI render cycle
    /// Performs heavy computation off main actor using structured concurrency
    private func updateFilteredGuests() {
        // Cancel any existing filter task to prevent race conditions
        filterTask?.cancel()
        
        // Capture parameters (immutable snapshots)
        let guests = guestStore.guests
        let search = searchText
        let status = selectedStatus
        let invitedBy = selectedInvitedBy
        let sortOption = selectedSortOption
        
        // Create new filter task with user-initiated priority
        filterTask = Task(priority: .userInitiated) {
            // Check for cancellation before starting
            guard !Task.isCancelled else { return }
            
            // Perform heavy filtering off main actor
            let filtered = guests.filter { guest in
                // Search across name, email, and phone fields
                let matchesSearch = search.isEmpty ||
                    guest.fullName.localizedCaseInsensitiveContains(search) ||
                    guest.email?.localizedCaseInsensitiveContains(search) == true ||
                    guest.phone?.localizedCaseInsensitiveContains(search) == true
                
                // Filter by RSVP status (attending, pending, declined)
                let matchesStatus = status == nil || guest.rsvpStatus == status
                
                // Filter by which side invited the guest (bride/groom/both)
                let matchesInvitedBy = invitedBy == nil || guest.invitedBy == invitedBy
                
                return matchesSearch && matchesStatus && matchesInvitedBy
            }
            
            // Check for cancellation after filtering, before sorting
            guard !Task.isCancelled else { return }
            
            // Apply sorting
            let sorted = sortOption.sort(filtered)
            
            // Check for cancellation after sorting, before updating UI
            guard !Task.isCancelled else { return }
            
            // Update UI-bound state on main actor
            await MainActor.run {
                cachedFilteredGuests = sorted
            }
        }
    }

    private func rightPanel(guestStore: GuestStoreV2, settingsStore: SettingsStoreV2) -> some View {
        Group {
            if let selectedGuestId = selectedGuest?.id,
               let guest = guestStore.guests.first(where: { $0.id == selectedGuestId }) {
                GuestDetailViewV2(guest: guest, guestStore: guestStore)
                    .environmentObject(settingsStore)
                    .id(guest.id)
            } else {
                EmptyDetailView()
            }
        }
    }

    @MainActor
    private func addGuest(_ guest: Guest, guestStore: GuestStoreV2) async {
        await guestStore.addGuest(guest)
    }
}

// MARK: - Extensions

extension Guest {
    var initials: String {
        String(firstName.prefix(1) + lastName.prefix(1)).uppercased()
    }
}

extension RSVPStatus {
    var iconName: String {
        switch self {
        case .pending: return "clock.badge.fill"
        case .attending, .confirmed: return "checkmark.seal.fill"
        case .declined: return "xmark.circle.fill"
        case .maybe: return "questionmark.circle.fill"
        default: return "envelope.fill"
        }
    }
}

#Preview {
    GuestListViewV2()
        .environment(\.appStores, AppStores.shared)
}
