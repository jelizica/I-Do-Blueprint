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
    @StateObject private var guestStore = GuestStoreV2()
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @State private var searchText = ""
    @State private var selectedStatus: RSVPStatus?
    @State private var selectedInvitedBy: InvitedBy?
    @State private var showingAddGuest = false
    @State private var selectedGuest: Guest?
    @State private var groupByStatus = true

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Left panel - Guest list with enhanced design
                VStack(spacing: 0) {
                    // Modern Stats Section
                    if let stats = guestStore.guestStats {
                        ModernStatsView(stats: stats)
                            .padding(Spacing.md)
                    }

                    Divider()

                    // Enhanced Search and Filters
                    ModernSearchBar(
                        searchText: $searchText,
                        selectedStatus: $selectedStatus,
                        selectedInvitedBy: $selectedInvitedBy,
                        groupByStatus: $groupByStatus
                    )
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)

                    Divider()

                    // Guest List with grouping option
                    if groupByStatus {
                        GroupedGuestListView(
                            guests: guestStore.filteredGuests,
                            isLoading: guestStore.isLoading,
                            selectedGuest: $selectedGuest,
                            onRefresh: {
                                await guestStore.loadGuestData()
                            }
                        )
                    } else {
                        ModernGuestListView(
                            guests: guestStore.filteredGuests,
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
                .frame(width: 480)
                .background(AppColors.background)

                Divider()

                // Right panel - Enhanced Detail view
                if let selectedGuestId = selectedGuest?.id,
                   let guest = guestStore.guests.first(where: { $0.id == selectedGuestId }) {
                    GuestDetailViewV2(guest: guest, guestStore: guestStore)
                        .environmentObject(settingsStore)
                        .id(guest.id)
                } else if selectedGuest != nil {
                    EmptyDetailView()
                } else {
                    EmptyDetailView()
                }
            }
            .navigationTitle("Wedding Guests")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddGuest = true
                    } label: {
                        Label("Add Guest", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showingAddGuest) {
                AddGuestView { newGuest in
                    await addGuest(newGuest)
                }
                .frame(minWidth: 500, maxWidth: 600, minHeight: 500, maxHeight: 650)
            }
            .successToast(isPresented: $guestStore.showSuccessToast, message: guestStore.successMessage)
            .task {
                await guestStore.loadGuestData()
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
            .onChange(of: searchText) { _, _ in
                guestStore.filterGuests(
                    searchText: searchText,
                    selectedStatus: selectedStatus,
                    selectedInvitedBy: selectedInvitedBy
                )
            }
            .onChange(of: selectedStatus) { _, _ in
                guestStore.filterGuests(
                    searchText: searchText,
                    selectedStatus: selectedStatus,
                    selectedInvitedBy: selectedInvitedBy
                )
            }
            .onChange(of: selectedInvitedBy) { _, _ in
                guestStore.filterGuests(
                    searchText: searchText,
                    selectedStatus: selectedStatus,
                    selectedInvitedBy: selectedInvitedBy
                )
            }
            .alert("Error", isPresented: .constant(guestStore.error != nil)) {
                Button("OK") {
                    guestStore.error = nil
                }
            } message: {
                if let error = guestStore.error {
                    Text(error.errorDescription ?? "Unknown error")
                }
            }
        }
    }

    @MainActor
    private func addGuest(_ guest: Guest) async {
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
}
