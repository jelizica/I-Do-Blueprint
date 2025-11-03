//
//  GuestListViewV3.swift
//  I Do Blueprint
//
//  Enhanced guest management interface matching modern design
//

import SwiftUI

struct GuestListViewV3: View {
    @EnvironmentObject private var guestStore: GuestStoreV2
    @State private var searchText = ""
    @State private var selectedStatus: RSVPStatus?
    @State private var selectedInvitedBy: InvitedBy?
    @State private var showingAddGuest = false
    @State private var showingImport = false
    @State private var selectedGuest: Guest?
    @State private var selectedTab: GuestDetailTab = .contact

    private let logger = AppLogger.ui

    var body: some View {
        HStack(spacing: 0) {
            // Left panel - Guest list (420px)
            VStack(spacing: 0) {
                // Compact Stats Icons Row
                if let stats = guestStore.guestStats {
                    CompactStatsRow(stats: stats)
                        .padding()
                        .background(Color(NSColor.windowBackgroundColor))
                }

                Divider()

                // Search and Filters
                VStack(spacing: 12) {
                    // Search Bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))

                        TextField("Search guests...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                    }
                    .padding(Spacing.md)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)

                    // Filters Row
                    HStack(spacing: 12) {
                        // Status Filter
                        HStack {
                            Text("Status")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            Picker("", selection: $selectedStatus) {
                                Text("All Status").tag(RSVPStatus?.none)
                                ForEach(RSVPStatus.allCases, id: \.self) { status in
                                    Text(status.displayName).tag(status as RSVPStatus?)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }

                        // Invited By Filter
                        HStack {
                            Text("Invited By")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)

                            Picker("", selection: $selectedInvitedBy) {
                                Text("All Guests").tag(InvitedBy?.none)
                                ForEach(InvitedBy.allCases, id: \.self) { invitedBy in
                                    Text(invitedBy.displayName).tag(invitedBy as InvitedBy?)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(Color(NSColor.windowBackgroundColor))

                Divider()

                // Guest List
                if guestStore.isLoading {
                    LoadingView(message: "Loading guests...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if guestStore.filteredGuests.isEmpty {
                    EmptyGuestListView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(guestStore.filteredGuests) { guest in
                                SimpleGuestCard(
                                    guest: guest,
                                    isSelected: selectedGuest?.id == guest.id
                                )
                                .onTapGesture {
                                    selectedGuest = guest
                                }
                            }
                        }
                        .padding(Spacing.md)
                    }
                    .background(Color(NSColor.windowBackgroundColor))
                }
            }
            .frame(width: 420)

            Divider()

            // Right panel - Detail view
            if let guest = selectedGuest {
                GuestDetailViewV3(
                    guest: guest,
                    selectedTab: $selectedTab
                )
                .id(guest.id)
            } else {
                EmptyGuestSelectionView()
            }
        }
        .navigationTitle("")
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
                    Label("Add Guest", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddGuest) {
            AddGuestView { newGuest in
                await guestStore.addGuest(newGuest)
            }
            #if os(macOS)
            .frame(minWidth: 500, maxWidth: 600, minHeight: 500, maxHeight: 650)
            #endif
        }
        .sheet(isPresented: $showingImport) {
            GuestCSVImportView()
                .environmentObject(guestStore)
            #if os(macOS)
            .frame(minWidth: 700, maxWidth: 900, minHeight: 600, maxHeight: 800)
            #endif
        }
        .task {
            await guestStore.loadGuestData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .tenantDidChange)) { _ in
            Task {
                await guestStore.loadGuestData()
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
    }
}

// MARK: - Guest Detail Tab Enum

enum GuestDetailTab: String, CaseIterable {
    case contact = "Contact"
    case events = "Events"
    case meals = "Meals"
    case seating = "Seating"
    case address = "Address"
    case party = "Party"
    case gifts = "Gifts"
    case notes = "Notes"

    var icon: String {
        switch self {
        case .contact: return "person.fill"
        case .events: return "calendar"
        case .meals: return "fork.knife"
        case .seating: return "tablecells"
        case .address: return "map"
        case .party: return "star.fill"
        case .gifts: return "gift.fill"
        case .notes: return "note.text"
        }
    }
}

// MARK: - Compact Stats Row

struct CompactStatsRow: View {
    let stats: GuestStats

    var body: some View {
        HStack(spacing: 12) {
            CompactStatIcon(
                icon: "person.3.fill",
                color: .purple,
                value: "\(stats.totalGuests)"
            )

            CompactStatIcon(
                icon: "checkmark.circle.fill",
                color: .green,
                value: "\(stats.attendingGuests)"
            )

            CompactStatIcon(
                icon: "clock.fill",
                color: .orange,
                value: "\(stats.pendingGuests)"
            )

            CompactStatIcon(
                icon: "chart.bar.fill",
                color: .blue,
                value: "\(Int(stats.responseRate))%"
            )
        }
    }
}

struct CompactStatIcon: View {
    let icon: String
    let color: Color
    let value: String
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.textPrimary)
            }

            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Simple Guest Card

struct SimpleGuestCard: View {
    let guest: Guest
    let isSelected: Bool
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Circular Avatar
            Circle()
                .fill(guest.rsvpStatus.color.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(guest.firstName.prefix(1) + guest.lastName.prefix(1)))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(guest.rsvpStatus.color)
                )

            // Guest Info
            VStack(alignment: .leading, spacing: 4) {
                Text(guest.fullName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)

                Text(guest.rsvpStatus.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(guest.rsvpStatus.color)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.blue.opacity(0.08) : Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Guest Detail View

struct GuestDetailViewV3: View {
    let guest: Guest
    @Binding var selectedTab: GuestDetailTab

    var body: some View {
        VStack(spacing: 0) {
            // Large Avatar Header
            VStack(spacing: 16) {
                Circle()
                    .fill(guest.rsvpStatus.color.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(String(guest.firstName.prefix(1) + guest.lastName.prefix(1)))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(guest.rsvpStatus.color)
                    )

                VStack(spacing: 8) {
                    Text(guest.fullName)
                        .font(.system(size: 28, weight: .bold))

                    HStack(spacing: 8) {
                        Text(guest.rsvpStatus.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(guest.rsvpStatus.color.opacity(0.15))
                            .foregroundColor(guest.rsvpStatus.color)
                            .cornerRadius(12)

                        if let invitedBy = guest.invitedBy {
                            Text(invitedBy.displayName)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.top, Spacing.xxxl)
            .padding(.bottom, Spacing.xxl)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.windowBackgroundColor))

            // Tab Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GuestDetailTab.allCases, id: \.self) { tab in
                        GuestTabButton(
                            tab: tab,
                            isSelected: selectedTab == tab
                        )
                        .onTapGesture {
                            selectedTab = tab
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
            }
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Tab Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .contact:
                        ContactTabContent(guest: guest)
                    case .events:
                        EventsTabContent(guest: guest)
                    case .meals:
                        MealsTabContent(guest: guest)
                    case .seating:
                        SeatingTabContent(guest: guest)
                    case .address:
                        AddressTabContent(guest: guest)
                    case .party:
                        PartyTabContent(guest: guest)
                    case .gifts:
                        GiftsTabContent(guest: guest)
                    case .notes:
                        NotesTabContent(guest: guest)
                    }
                }
                .padding(Spacing.xxl)
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
}

// MARK: - Tab Button

struct GuestTabButton: View {
    let tab: GuestDetailTab
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: tab.icon)
                .font(.system(size: 13))
            Text(tab.rawValue)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(isSelected ? Color.blue : Color.clear)
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(8)
    }
}

// MARK: - Tab Content Views

struct ContactTabContent: View {
    let guest: Guest

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let email = guest.email {
                InfoRowV3(
                    icon: "envelope.fill",
                    iconColor: .blue,
                    label: "Email",
                    value: email
                )
            }

            if let phone = guest.phone {
                InfoRowV3(
                    icon: "phone.fill",
                    iconColor: .green,
                    label: "Phone",
                    value: phone
                )
            }

            InfoRowV3(
                icon: "person.2.fill",
                iconColor: .purple,
                label: "Relationship",
                value: guest.relationshipToCouple ?? "Not specified"
            )

            InfoRowV3(
                icon: "person.badge.plus",
                iconColor: .orange,
                label: "Plus One",
                value: guest.plusOneAllowed ? "Yes" : "No"
            )

            if guest.plusOneAllowed, let plusOneName = guest.plusOneName {
                InfoRowV3(
                    icon: "person.fill",
                    iconColor: .blue,
                    label: "Plus One Name",
                    value: plusOneName
                )
            }
        }
    }
}

struct EventsTabContent: View {
    let guest: Guest

    var body: some View {
        VStack(spacing: 12) {
            EventRowV3(
                title: "Ceremony",
                icon: "heart.fill",
                isAttending: guest.attendingCeremony
            )

            EventRowV3(
                title: "Reception",
                icon: "fork.knife",
                isAttending: guest.attendingReception
            )

            if let otherEvents = guest.attendingOtherEvents, !otherEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Other Events")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.top, Spacing.sm)

                    ForEach(otherEvents, id: \.self) { event in
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text(event)
                                .font(.system(size: 14))
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct MealsTabContent: View {
    let guest: Guest

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let mealOption = guest.mealOption {
                InfoRowV3(
                    icon: "fork.knife",
                    iconColor: .orange,
                    label: "Meal Selection",
                    value: mealOption
                )
            }

            if let dietary = guest.dietaryRestrictions, !dietary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Dietary Restrictions")
                            .font(.system(size: 15, weight: .semibold))
                    }

                    Text(dietary)
                        .font(.system(size: 14))
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            if let accessibility = guest.accessibilityNeeds, !accessibility.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "figure.roll")
                            .foregroundColor(.blue)
                        Text("Accessibility Needs")
                            .font(.system(size: 15, weight: .semibold))
                    }

                    Text(accessibility)
                        .font(.system(size: 14))
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct SeatingTabContent: View {
    let guest: Guest

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Table Number")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Text(guest.tableAssignment != nil ? "\(guest.tableAssignment!)" : "—")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
            }
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 8) {
                Text("Seat Number")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Text(guest.seatNumber != nil ? "\(guest.seatNumber!)" : "—")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
            }
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }
}

struct AddressTabContent: View {
    let guest: Guest

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.blue)
                Text("Mailing Address")
                    .font(.system(size: 17, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                if let address1 = guest.addressLine1 {
                    Text(address1)
                        .font(.system(size: 15))
                }

                if let address2 = guest.addressLine2, !address2.isEmpty {
                    Text(address2)
                        .font(.system(size: 15))
                }

                HStack(spacing: 4) {
                    if let city = guest.city {
                        Text(city + ",")
                    }
                    if let state = guest.state {
                        Text(state)
                    }
                    if let zip = guest.zipCode {
                        Text(zip)
                    }
                }
                .font(.system(size: 15))

                if let country = guest.country {
                    Text(country)
                        .font(.system(size: 15))
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
        }
    }
}

struct PartyTabContent: View {
    let guest: Guest

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            InfoRowV3(
                icon: "star.fill",
                iconColor: .yellow,
                label: "Wedding Party Member",
                value: guest.isWeddingParty ? "Yes" : "No"
            )

            if guest.isWeddingParty {
                if let role = guest.weddingPartyRole {
                    InfoRowV3(
                        icon: "person.fill.badge.plus",
                        iconColor: .purple,
                        label: "Role",
                        value: role
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Preparation Status")
                        .font(.system(size: 17, weight: .semibold))

                    HStack(spacing: 16) {
                        PrepStatusCard(
                            title: "Hair",
                            isDone: guest.hairDone,
                            icon: "scissors"
                        )

                        PrepStatusCard(
                            title: "Makeup",
                            isDone: guest.makeupDone,
                            icon: "paintbrush.fill"
                        )
                    }
                }

                if let notes = guest.preparationNotes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preparation Notes")
                            .font(.system(size: 15, weight: .semibold))

                        Text(notes)
                            .font(.system(size: 14))
                            .padding(Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct GiftsTabContent: View {
    let guest: Guest

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            InfoRowV3(
                icon: "gift.fill",
                iconColor: .red,
                label: "Gift Received",
                value: guest.giftReceived ? "Yes" : "No"
            )

            if guest.giftReceived {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Gift has been received")
                            .font(.system(size: 15, weight: .semibold))
                    }

                    Text("Remember to send a thank you card!")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct NotesTabContent: View {
    let guest: Guest

    var body: some View {
        if let notes = guest.notes, !notes.isEmpty {
            Text(notes)
                .font(.system(size: 15))
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "note.text")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))

                Text("No notes available")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.xxxl)
        }
    }
}

// MARK: - Supporting Views

struct InfoRowV3: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.system(size: 15, weight: .medium))
            }

            Spacer()
        }
    }
}

struct EventRowV3: View {
    let title: String
    let icon: String
    let isAttending: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isAttending ? .green : .red)
                .font(.system(size: 20))

            Text(title)
                .font(.system(size: 15, weight: .medium))

            Spacer()

            Image(systemName: isAttending ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isAttending ? .green : .red)
                .font(.system(size: 20))
        }
        .padding(Spacing.md)
        .background((isAttending ? Color.green : Color.red).opacity(0.1))
        .cornerRadius(10)
    }
}

struct PrepStatusCard: View {
    let title: String
    let isDone: Bool
    let icon: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isDone ? .green : .secondary)

            Text(title)
                .font(.system(size: 14, weight: .medium))

            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isDone ? .green : .secondary)
                .font(.system(size: 20))
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct EmptyGuestSelectionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Select a guest to view details")
                .foregroundColor(.secondary)
                .font(.system(size: 17))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    GuestListViewV3()
        .environmentObject(GuestStoreV2())
}
