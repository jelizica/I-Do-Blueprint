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
    @EnvironmentObject private var guestStore: GuestStoreV2
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    @State private var searchText = ""
    @State private var selectedStatus: RSVPStatus?
    @State private var selectedInvitedBy: InvitedBy?
    @State private var showingAddGuest = false
    @State private var showingImport = false
    @State private var selectedGuest: Guest?
    @State private var groupByStatus = true

    var body: some View {
        NavigationStack {
            mainContent
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
                    await addGuest(newGuest)
                }
                .frame(minWidth: 500, maxWidth: 600, minHeight: 500, maxHeight: 650)
            }
            .sheet(isPresented: $showingImport) {
                GuestCSVImportView()
                    .environmentObject(guestStore)
                    .frame(minWidth: 700, maxWidth: 900, minHeight: 600, maxHeight: 800)
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

    private var mainContent: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                leftPanel(geometry: geometry)
                Divider()
                rightPanel
            }
        }
    }

    private func leftPanel(geometry: GeometryProxy) -> some View {
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
                groupByStatus: $groupByStatus,
                filteredCount: guestStore.filteredGuests.count,
                totalCount: guestStore.guests.count
            )
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            Divider()

            guestListView
        }
        .frame(
            minWidth: ResponsiveLayout.minListPanelWidth,
            maxWidth: ResponsiveLayout.listPanelWidth(for: geometry)
        )
        .background(AppColors.background)
    }

    private var guestListView: some View {
        Group {
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
    }

    private var rightPanel: some View {
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
        .environmentObject(GuestStoreV2())
        .environmentObject(SettingsStoreV2())
}
