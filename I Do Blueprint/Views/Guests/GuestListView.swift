//
//  GuestListView.swift
//  My Wedding Planning App
//
//  Created by Jessica Clark on 9/26/25.
//

import Combine
import Supabase
import SwiftUI

struct GuestListView: View {
    @EnvironmentObject private var guestStore: GuestStoreV2
    @State private var searchText = ""
    @State private var selectedStatus: RSVPStatus?
    @State private var selectedInvitedBy: InvitedBy?
    @State private var showingAddGuest = false
    @State private var selectedGuest: Guest?
    @State private var showingGuestDetail = false

    private let logger = AppLogger.ui

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Left panel - Guest list
                VStack(spacing: 0) {
                    // Stats Cards
                    if let stats = guestStore.guestStats {
                        StatsCardsView(stats: stats)
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Guest statistics")
                    }

                    // Search and Filters
                    SearchAndFiltersView(
                        searchText: $searchText,
                        selectedStatus: $selectedStatus,
                        selectedInvitedBy: $selectedInvitedBy)
                        .padding(.horizontal)
                        .padding(.bottom)
                        .background(Color(NSColor.controlBackgroundColor))

                    Divider()

                    // Guest List
                    GuestListContentView(
                        guests: filteredGuests,
                        isLoading: guestStore.isLoading,
                        selectedGuest: $selectedGuest,
                        onRefresh: {
                            await guestStore.loadGuestData()
                        })
                }
                .frame(width: 420)

                Divider()

                // Right panel - Detail view
                if let guest = selectedGuest {
                    GuestDetailView(guest: guest)
                        .id(guest.id)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Select a guest to view details")
                            .foregroundColor(.secondary)
                            .font(.title2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.windowBackgroundColor))
                }
            }
            .navigationTitle("Wedding Guests")
            .accessibilityAddTraits(.isHeader)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddGuest = true
                    } label: {
                        Label("Add Guest", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGuest) {
                AddGuestView { newGuest in
                    await addGuest(newGuest)
                }
                #if os(macOS)
                .frame(
                    minWidth: 700,
                    idealWidth: 900,
                    maxWidth: .infinity,
                    minHeight: 600,
                    idealHeight: 750,
                    maxHeight: .infinity
                )
                #endif
            }
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

    // MARK: - Computed Filtering
    
    private var filteredGuests: [Guest] {
        guestStore.guests.filter { guest in
            let matchesSearch = searchText.isEmpty ||
                guest.fullName.localizedCaseInsensitiveContains(searchText) ||
                guest.email?.localizedCaseInsensitiveContains(searchText) == true ||
                guest.phone?.contains(searchText) == true
            let matchesStatus = selectedStatus == nil || guest.rsvpStatus == selectedStatus
            let matchesInvitedBy = selectedInvitedBy == nil || guest.invitedBy == selectedInvitedBy
            return matchesSearch && matchesStatus && matchesInvitedBy
        }
    }
    
    // MARK: - Data Operations

    @MainActor
    private func addGuest(_ guest: Guest) async {
        await guestStore.addGuest(guest)
    }
}

// MARK: - Stats Cards View

struct StatsCardsView: View {
    let stats: GuestStats

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            GuestStatCard(
                title: "Total Guests",
                value: "\(stats.totalGuests)",
                color: .purple,
                icon: "person.3.fill")

            GuestStatCard(
                title: "Attending",
                value: "\(stats.attendingGuests)",
                color: .green,
                icon: "checkmark.circle.fill")

            GuestStatCard(
                title: "Pending",
                value: "\(stats.pendingGuests)",
                color: .orange,
                icon: "clock.fill")

            GuestStatCard(
                title: "Response Rate",
                value: "\(Int(stats.responseRate))%",
                color: .blue,
                icon: "chart.bar.fill")
        }
    }
}

struct GuestStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: .black.opacity(isHovering ? 0.1 : 0.06),
                    radius: isHovering ? 6 : 3,
                    x: 0,
                    y: isHovering ? 3 : 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1))
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Search and Filters View

struct SearchAndFiltersView: View {
    @Binding var searchText: String
    @Binding var selectedStatus: RSVPStatus?
    @Binding var selectedInvitedBy: InvitedBy?

    var body: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search guests...", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Filters
            HStack {
                // Status Filter
                Picker("Status", selection: $selectedStatus) {
                    Text("All Status").tag(RSVPStatus?.none)
                    ForEach(RSVPStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status as RSVPStatus?)
                    }
                }
                .pickerStyle(.menu)

                // Invited By Filter
                Picker("Invited By", selection: $selectedInvitedBy) {
                    Text("All Guests").tag(InvitedBy?.none)
                    ForEach(InvitedBy.allCases, id: \.self) { invitedBy in
                        Text(invitedBy.displayName).tag(invitedBy as InvitedBy?)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                // Clear Filters
                if selectedStatus != nil || selectedInvitedBy != nil {
                    Button("Clear Filters") {
                        selectedStatus = nil
                        selectedInvitedBy = nil
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Guest List Content View

struct GuestListContentView: View {
    let guests: [Guest]
    let isLoading: Bool
    @Binding var selectedGuest: Guest?
    let onRefresh: () async -> Void

    var body: some View {
        if isLoading {
            LoadingView(message: "Loading guests...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if guests.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.dashed")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("No guests found")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("Add your first guest or adjust your search filters")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(guests) { guest in
                        Button(action: {
                            selectedGuest = guest
                        }) {
                            GuestRowView(guest: guest)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color(NSColor.windowBackgroundColor))
            .refreshable {
                await onRefresh()
            }
        }
    }
}

// MARK: - Guest Row View

struct GuestRowView: View {
    let guest: Guest
    @State private var isHovering = false
    @State private var avatarImage: NSImage?

    var body: some View {
        HStack(spacing: 16) {
            // Avatar with Multiavatar or gradient fallback
            Group {
                if let image = avatarImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                        .shadow(color: guest.rsvpStatus.color.opacity(0.2), radius: 4, x: 0, y: 2)
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [guest.rsvpStatus.color.opacity(0.3), guest.rsvpStatus.color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(String(guest.firstName.prefix(1) + guest.lastName.prefix(1)))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(guest.rsvpStatus.color))
                        .shadow(color: guest.rsvpStatus.color.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }
            .task {
                await loadAvatar()
            }
            .accessibilityLabel("Avatar for \(guest.fullName)")

            // Guest Info
            VStack(alignment: .leading, spacing: 6) {
                Text(guest.fullName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // RSVP Status Badge
                    Text(guest.rsvpStatus.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(guest.rsvpStatus.color.opacity(0.15))
                        .foregroundColor(guest.rsvpStatus.color)
                        .clipShape(Capsule())

                    if let email = guest.email {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Additional Info
            VStack(alignment: .trailing, spacing: 6) {
                if let invitationNumber = guest.invitationNumber {
                    Text("#\(invitationNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }

                HStack(spacing: 8) {
                    if guest.plusOneAllowed {
                        HStack(spacing: 3) {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption2)
                            Text("Plus One")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }

                    if let table = guest.tableAssignment {
                        HStack(spacing: 3) {
                            Image(systemName: "tablecells")
                                .font(.caption2)
                            Text("\(table)")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary.opacity(isHovering ? 1.0 : 0.5))
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: .black.opacity(isHovering ? 0.12 : 0.06),
                    radius: isHovering ? 8 : 4,
                    x: 0,
                    y: isHovering ? 4 : 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.textSecondary.opacity(isHovering ? 0.3 : 0.15), lineWidth: 1))
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape(Rectangle())
        .contentShape(Rectangle())
    }

    // MARK: - Avatar Loading

    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 112, height: 112) // 2x for retina
            )
            await MainActor.run {
                avatarImage = image
            }
        } catch {
            // Silently fail, keep showing initials
            // Error already logged by MultiAvatarJSService
        }
    }
}

#Preview {
    GuestListView()
}
