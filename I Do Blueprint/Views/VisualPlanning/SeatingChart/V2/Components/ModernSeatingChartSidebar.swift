//
//  ModernSeatingChartSidebar.swift
//  My Wedding Planning App
//
//  Modern unified sidebar for Seating Chart V2
//  Combines unassigned guests, table management, and assigned guests in one view
//

import SwiftUI

/// V2 sidebar with three-section design: Unassigned Guests, Tables, and Assigned Guests
struct ModernSeatingChartSidebar: View {
    @Binding var chart: SeatingChart
    @Binding var selectedTableId: UUID?
    let onGuestDrop: (SeatingGuest, UUID?, Int?) -> Void
    let onTableSelect: (UUID) -> Void

    @State private var searchText = ""
    @State private var selectedTab: SidebarTab = .unassigned
    @State private var expandedTableIds: Set<UUID> = []

    enum SidebarTab: String, CaseIterable {
        case unassigned = "Unassigned"
        case tables = "Tables"
        case assigned = "Assigned"

        var icon: String {
            switch self {
            case .unassigned: return "person.crop.circle.badge.questionmark"
            case .tables: return "tablecells"
            case .assigned: return "person.crop.circle.badge.checkmark"
            }
        }
    }

    // MARK: - Computed Properties

    private var unassignedGuests: [SeatingGuest] {
        let assignedGuestIds = Set(chart.seatingAssignments.map { $0.guestId })
        return chart.guests.filter { !assignedGuestIds.contains($0.id) }
            .filter { searchText.isEmpty || guestMatchesSearch($0) }
    }

    private var assignedGuests: [SeatingGuest] {
        let assignedGuestIds = Set(chart.seatingAssignments.map { $0.guestId })
        return chart.guests.filter { assignedGuestIds.contains($0.id) }
            .filter { searchText.isEmpty || guestMatchesSearch($0) }
    }

    private var groupedUnassignedGuests: [String: [SeatingGuest]] {
        Dictionary(grouping: unassignedGuests) { $0.group ?? "Ungrouped" }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            sidebarHeader

            // Search bar
            searchBar

            // Tab selector
            tabSelector

            Divider()

            // Content area
            ScrollView {
                switch selectedTab {
                case .unassigned:
                    unassignedGuestsSection
                case .tables:
                    tablesSection
                case .assigned:
                    assignedGuestsSection
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Footer stats
            sidebarFooter
        }
        .frame(width: 320)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Header

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Seating Arrangement")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                StatBadge(
                    icon: "person.3.fill",
                    value: "\(chart.guests.count)",
                    label: "Guests",
                    color: .blue
                )

                StatBadge(
                    icon: "tablecells.fill",
                    value: "\(chart.tables.count)",
                    label: "Tables",
                    color: .green
                )

                StatBadge(
                    icon: "checkmark.circle.fill",
                    value: "\(chart.seatingAssignments.count)",
                    label: "Seated",
                    color: .seatingAccentTeal
                )
            }
        }
        .padding()
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search guests...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.sm)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(SidebarTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: tab.icon)
                            Text(tab.rawValue)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selectedTab == tab ? .seatingAccentTeal : .secondary)

                        Rectangle()
                            .fill(selectedTab == tab ? Color.seatingAccentTeal : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Unassigned Guests Section

    private var unassignedGuestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if unassignedGuests.isEmpty {
                emptyStateView(
                    icon: "checkmark.circle.fill",
                    message: searchText.isEmpty ? "All guests are seated!" : "No matching guests"
                )
            } else {
                ForEach(groupedUnassignedGuests.keys.sorted(), id: \.self) { groupName in
                    if let guests = groupedUnassignedGuests[groupName] {
                        GroupSection(title: groupName, count: guests.count) {
                            ForEach(guests) { guest in
                                UnassignedGuestRowV2(guest: guest)
                                    .onDrag {
                                        NSItemProvider(object: guest.id.uuidString as NSString)
                                    }
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Tables Section

    private var tablesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if chart.tables.isEmpty {
                emptyStateView(
                    icon: "tablecells.badge.ellipsis",
                    message: "No tables yet. Add tables to start seating guests."
                )
            } else {
                ForEach(chart.tables.sorted(by: { $0.tableNumber < $1.tableNumber })) { table in
                    TableRowV2(
                        table: table,
                        assignmentCount: chart.seatingAssignments.filter { $0.tableId == table.id }.count,
                        isSelected: selectedTableId == table.id,
                        isExpanded: expandedTableIds.contains(table.id),
                        onSelect: { onTableSelect(table.id) },
                        onToggleExpand: { toggleTableExpansion(table.id) }
                    )

                    if expandedTableIds.contains(table.id) {
                        tableGuestsList(for: table)
                            .padding(.leading, Spacing.xl)
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Assigned Guests Section

    private var assignedGuestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if assignedGuests.isEmpty {
                emptyStateView(
                    icon: "person.crop.circle.badge.questionmark",
                    message: "No guests seated yet"
                )
            } else {
                ForEach(assignedGuests) { guest in
                    if let assignment = chart.seatingAssignments.first(where: { $0.guestId == guest.id }),
                       let table = chart.tables.first(where: { $0.id == assignment.tableId }) {
                        AssignedGuestRowV2(
                            guest: guest,
                            tableNumber: table.tableNumber,
                            seatNumber: assignment.seatNumber
                        )
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Footer

    private var sidebarFooter: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(unassignedGuests.count) unassigned")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ProgressView(value: Double(chart.seatingAssignments.count), total: Double(chart.guests.count))
                    .progressViewStyle(.linear)
                    .tint(.seatingAccentTeal)
            }

            Spacer()

            Text("\(Int((Double(chart.seatingAssignments.count) / Double(max(1, chart.guests.count))) * 100))%")
                .font(.caption.bold())
                .foregroundColor(.seatingAccentTeal)
        }
        .padding()
    }

    // MARK: - Helper Views

    private func emptyStateView(icon: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.huge)
    }

    private func tableGuestsList(for table: Table) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            let tableAssignments = chart.seatingAssignments.filter { $0.tableId == table.id }
            ForEach(tableAssignments) { assignment in
                if let guest = chart.guests.first(where: { $0.id == assignment.guestId }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(guest.firstName) \(guest.lastName)")
                            .font(.caption)

                        Spacer()

                        if let seatNum = assignment.seatNumber {
                            Text("Seat \(seatNum + 1)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, Spacing.xxs)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func guestMatchesSearch(_ guest: SeatingGuest) -> Bool {
        let search = searchText.lowercased()
        return guest.firstName.lowercased().contains(search) ||
               guest.lastName.lowercased().contains(search) ||
               (guest.group?.lowercased().contains(search) ?? false)
    }

    private func toggleTableExpansion(_ tableId: UUID) {
        if expandedTableIds.contains(tableId) {
            expandedTableIds.remove(tableId)
        } else {
            expandedTableIds.insert(tableId)
        }
    }
}

// MARK: - Supporting Components

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(color)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct GroupSection<Content: View>: View {
    let title: String
    let count: Int
    let content: Content

    init(title: String, count: Int, @ViewBuilder content: () -> Content) {
        self.title = title
        self.count = count
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)

                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)

                Spacer()
            }

            content
        }
    }
}

struct UnassignedGuestRowV2: View {
    let guest: SeatingGuest

    var body: some View {
        HStack(spacing: 12) {
            GuestAvatarViewV2(
                guest: guest,
                size: 36,
                showName: false
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("\(guest.firstName) \(guest.lastName)")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if let group = guest.group {
                    Text(group)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if guest.isVIP {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding(Spacing.sm)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct TableRowV2: View {
    let table: Table
    let assignmentCount: Int
    let isSelected: Bool
    let isExpanded: Bool
    let onSelect: () -> Void
    let onToggleExpand: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    Image(systemName: tableShapeIcon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .seatingAccentTeal : .primary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Table \(table.tableNumber)")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)

                        HStack(spacing: 4) {
                            Text("\(assignmentCount)/\(table.capacity)")
                                .font(.caption)
                                .foregroundColor(assignmentCount == table.capacity ? .green : .secondary)

                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(table.tableShape.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if assignmentCount > 0 {
                        Button(action: onToggleExpand) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Spacing.md)
                .background(isSelected ? Color.seatingAccentTeal.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }

    private var tableShapeIcon: String {
        switch table.tableShape {
        case .round: return "circle"
        case .rectangular: return "rectangle"
        case .square: return "square"
        case .oval: return "oval"
        }
    }
}

struct AssignedGuestRowV2: View {
    let guest: SeatingGuest
    let tableNumber: Int
    let seatNumber: Int?

    var body: some View {
        HStack(spacing: 12) {
            GuestAvatarViewV2(
                guest: guest,
                size: 36,
                showName: false
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("\(guest.firstName) \(guest.lastName)")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Text("Table \(tableNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let seatNum = seatNumber {
                        Text("• Seat \(seatNum + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if guest.isVIP {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .padding(Spacing.sm)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}
