//
//  ModernSidebarView.swift
//  My Wedding Planning App
//
//  Enhanced sidebar with guest groups and modern design
//

import SwiftUI

struct ModernSidebarView: View {
    @Binding var chart: SeatingChart
    @Binding var selectedTab: EditorTab
    @Binding var selectedTableId: UUID?

    @State private var searchText = ""
    @State private var showingGroupEditor = false
    @State private var guestGroups: [SeatingGuestGroup] = SeatingGuestGroup.defaultGroups

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchSection

            Divider()

            // Tab selection
            tabSelectionSection

            Divider()

            // Tab content
            ScrollView {
                switch selectedTab {
                case .layout:
                    layoutContent
                case .tables:
                    tablesContent
                case .guests:
                    guestsContent
                case .assignments:
                    assignmentsContent
                case .analytics:
                    analyticsContent
                }
            }
        }
        .frame(minWidth: 320, idealWidth: 360)
        .background(Color.seatingCream.opacity(0.3))
    }

    // MARK: - Search Section

    private var searchSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))

            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.seatingBody)
        }
        .padding(12)
        .background(Color.white)
    }

    // MARK: - Tab Selection

    private var tabSelectionSection: some View {
        VStack(spacing: 8) {
            ForEach(EditorTab.allCases, id: \.self) { tab in
                ModernTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    count: getTabCount(for: tab)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(12)
    }

    private func getTabCount(for tab: EditorTab) -> Int? {
        switch tab {
        case .layout: return nil
        case .tables: return chart.tables.count
        case .guests: return chart.guests.count
        case .assignments: return chart.seatingAssignments.count
        case .analytics: return nil
        }
    }

    // MARK: - Layout Content

    private var layoutContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Table zones section
            SectionCard(title: "Table Zones", icon: "mappin.circle") {
                VStack(spacing: 8) {
                    if chart.tableZones.isEmpty {
                        SidebarEmptyStateView(
                            icon: "mappin.slash",
                            message: "No zones created",
                            action: "Add Zone"
                        ) {
                            // Add zone action
                        }
                    } else {
                        ForEach(chart.tableZones.sorted(by: { $0.order < $1.order })) { zone in
                            ZoneRow(zone: zone)
                        }
                    }
                }
            }

            // Layout style section
            SectionCard(title: "Layout Style", icon: "rectangle.grid.2x2") {
                VStack(spacing: 8) {
                    ForEach(RectangularLayoutStyle.allCases, id: \.self) { style in
                        LayoutStyleRow(style: style) {
                            // Apply layout style
                        }
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Tables Content

    private var tablesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quick add
            Button(action: {}) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.seatingAccentTeal)
                    Text("Add Table")
                        .font(.seatingBodyMedium)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.seatingAccentTeal.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            // Tables list
            ForEach(filteredTables) { table in
                ModernTableRow(
                    table: table,
                    isSelected: selectedTableId == table.id,
                    assignmentCount: chart.seatingAssignments.filter { $0.tableId == table.id }.count
                ) {
                    selectedTableId = table.id
                }
            }
        }
        .padding()
    }

    // MARK: - Guests Content

    private var guestsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Guest groups section
            SectionCard(title: "Guest Groups", icon: "person.3") {
                VStack(spacing: 8) {
                    ForEach($guestGroups) { $group in
                        GuestGroupToggle(group: $group) {
                            // Toggle visibility
                        }
                    }

                    Button(action: { showingGroupEditor = true }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Create Group")
                                .font(.seatingCaption)
                        }
                        .foregroundColor(.seatingAccentTeal)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Unassigned guests
            UnassignedGuestsPanel(
                guests: unassignedGuests,
                searchText: searchText
            )
        }
        .padding()
        .sheet(isPresented: $showingGroupEditor) {
            GuestGroupEditorSheet(groups: $guestGroups)
        }
    }

    // MARK: - Assignments Content

    private var assignmentsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Progress card
            AssignmentProgressCard(
                assigned: chart.seatingAssignments.count,
                total: chart.guests.count
            )

            // Quick actions
            VStack(spacing: 8) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Auto-Assign Guests")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.seatingSuccess.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Clear All Assignments")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.seatingError.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            // Assignments list
            ForEach(chart.seatingAssignments) { assignment in
                if let guest = chart.guests.first(where: { $0.id == assignment.guestId }),
                   let table = chart.tables.first(where: { $0.id == assignment.tableId }) {
                    AssignmentRow(guest: guest, table: table)
                }
            }
        }
        .padding()
    }

    // MARK: - Analytics Content

    private var analyticsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Stats cards
            let analytics = calculateAnalytics()

            StatCard(
                title: "Total Guests",
                value: "\(analytics.totalGuests)",
                subtitle: "\(analytics.assignedGuests) assigned",
                color: .groupFamily,
                icon: "person.3"
            )

            StatCard(
                title: "Total Tables",
                value: "\(analytics.totalTables)",
                subtitle: "\(analytics.occupiedTables) occupied",
                color: .groupFriends,
                icon: "tablecells"
            )

            StatCard(
                title: "Completion",
                value: "\(Int(analytics.assignmentProgress * 100))%",
                subtitle: "\(analytics.unassignedGuests) remaining",
                color: .seatingWarning,
                icon: "chart.bar"
            )

            // Conflicts
            if analytics.conflictCount > 0 {
                ConflictCard(count: analytics.conflictCount)
            }
        }
        .padding()
    }

    // MARK: - Helper Properties

    private var filteredTables: [Table] {
        if searchText.isEmpty {
            return chart.tables
        }
        return chart.tables.filter { table in
            "Table \(table.tableNumber)".localizedCaseInsensitiveContains(searchText)
        }
    }

    private var unassignedGuests: [SeatingGuest] {
        chart.guests.filter { guest in
            !chart.seatingAssignments.contains { $0.guestId == guest.id }
        }
    }

    private func calculateAnalytics() -> (
        totalGuests: Int,
        assignedGuests: Int,
        unassignedGuests: Int,
        totalTables: Int,
        occupiedTables: Int,
        assignmentProgress: Double,
        conflictCount: Int
    ) {
        let totalGuests = chart.guests.count
        let assignedGuests = chart.seatingAssignments.count
        let unassignedGuests = totalGuests - assignedGuests
        let totalTables = chart.tables.count
        let occupiedTables = Set(chart.seatingAssignments.map(\.tableId)).count
        let progress = totalGuests > 0 ? Double(assignedGuests) / Double(totalGuests) : 0

        return (
            totalGuests,
            assignedGuests,
            unassignedGuests,
            totalTables,
            occupiedTables,
            progress,
            0  // TODO: Calculate conflicts
        )
    }
}

// MARK: - Supporting Views

struct ModernTabButton: View {
    let tab: EditorTab
    let isSelected: Bool
    let count: Int?
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.body)
                    .foregroundColor(isSelected ? .seatingAccentTeal : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.title)
                        .font(isSelected ? .seatingBodyBold : .seatingBody)
                        .foregroundColor(isSelected ? .primary : .secondary)

                    if let count {
                        Text("\(count) \(count == 1 ? "item" : "items")")
                            .font(.seatingCaption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.seatingAccentTeal)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.seatingAccentTeal.opacity(0.12) : (isHovering ? Color.gray.opacity(0.05) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.seatingAccentTeal.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.seatingAccentTeal)
                Text(title)
                    .font(.seatingH4)
            }

            Divider()

            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct ModernTableRow: View {
    let table: Table
    let isSelected: Bool
    let assignmentCount: Int
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: shapeIcon)
                    .foregroundColor(isSelected ? .seatingAccentTeal : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Table \(table.tableNumber)")
                        .font(.seatingBodyBold)
                        .foregroundColor(isSelected ? .seatingAccentTeal : .primary)

                    Text("\(assignmentCount)/\(table.capacity) seats")
                        .font(.seatingCaption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Progress circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        .frame(width: 32, height: 32)

                    Circle()
                        .trim(from: 0, to: CGFloat(assignmentCount) / CGFloat(table.capacity))
                        .stroke(
                            assignmentCount == table.capacity ? Color.seatingSuccess : Color.seatingAccentTeal,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.seatingAccentTeal.opacity(0.1) : Color.white)
            )
        }
        .buttonStyle(.plain)
    }

    private var shapeIcon: String {
        switch table.tableShape {
        case .round: return "circle"
        case .rectangular: return "rectangle"
        case .square: return "square"
        case .oval: return "oval"
        }
    }
}

struct GuestGroupToggle: View {
    @Binding var group: SeatingGuestGroup
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: group.icon)
                .foregroundColor(group.color)
                .frame(width: 24)

            Text(group.name)
                .font(.seatingBody)

            Spacer()

            Text("\(group.guestIds.count)")
                .font(.seatingCaption)
                .foregroundColor(.secondary)

            Toggle("", isOn: $group.isVisible)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: group.color))
        }
        .padding(.vertical, 4)
    }
}

struct UnassignedGuestsPanel: View {
    let guests: [SeatingGuest]
    let searchText: String

    var filteredGuests: [SeatingGuest] {
        if searchText.isEmpty {
            return guests
        }
        return guests.filter { guest in
            "\(guest.firstName) \(guest.lastName)".localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        SectionCard(title: "Unassigned (\(guests.count))", icon: "person.crop.circle.badge.exclamationmark") {
            if guests.isEmpty {
                SidebarEmptyStateView(
                    icon: "checkmark.circle",
                    message: "All guests assigned!",
                    action: nil
                ) {}
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredGuests.prefix(10)) { guest in
                        UnassignedGuestRow(guest: guest)
                    }

                    if filteredGuests.count > 10 {
                        Text("+ \(filteredGuests.count - 10) more")
                            .font(.seatingCaption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct UnassignedGuestRow: View {
    let guest: SeatingGuest

    var body: some View {
        HStack(spacing: 8) {
            GuestAvatarView(guest: guest, size: 32, showBorder: true)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(guest.firstName) \(guest.lastName)")
                    .font(.seatingCaption)

                if let group = guest.group {
                    Text(group)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AssignmentProgressCard: View {
    let assigned: Int
    let total: Int

    private var progress: Double {
        total > 0 ? Double(assigned) / Double(total) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Assignment Progress")
                    .font(.seatingH4)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.seatingH3)
                    .foregroundColor(.seatingAccentTeal)
            }

            ProgressView(value: progress)
                .tint(.seatingAccentTeal)

            Text("\(assigned) of \(total) guests assigned")
                .font(.seatingCaption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct AssignmentRow: View {
    let guest: SeatingGuest
    let table: Table

    var body: some View {
        HStack(spacing: 12) {
            GuestAvatarView(guest: guest, size: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(guest.firstName) \(guest.lastName)")
                    .font(.seatingCaption)

                Text("Table \(table.tableNumber)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(8)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.seatingH2)
                    .foregroundColor(.primary)

                Text(title)
                    .font(.seatingCaption)
                    .foregroundColor(.secondary)

                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct ConflictCard: View {
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.seatingError)

            Text("\(count) seating \(count == 1 ? "conflict" : "conflicts") detected")
                .font(.seatingBodyMedium)

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.seatingError.opacity(0.1))
        )
    }
}

struct ZoneRow: View {
    let zone: TableZone

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(zone.color)
                .frame(width: 12, height: 12)

            Text(zone.name)
                .font(.seatingCaption)

            Spacer()

            Text("\(zone.tableIds.count)")
                .font(.seatingCaption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct LayoutStyleRow: View {
    let style: RectangularLayoutStyle
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: style.icon)
                    .foregroundColor(.seatingAccentTeal)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(style.rawValue)
                        .font(.seatingCaption)

                    Text(style.description)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(8)
            .background(Color.white)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct SidebarEmptyStateView: View {
    let icon: String
    let message: String
    let action: String?
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text(message)
                .font(.seatingCaption)
                .foregroundColor(.secondary)

            if let action {
                Button(action: onAction) {
                    Text(action)
                        .font(.seatingCaptionBold)
                        .foregroundColor(.seatingAccentTeal)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

struct GuestGroupEditorSheet: View {
    @Binding var groups: [SeatingGuestGroup]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Guest Group Editor")
                .font(.seatingH2)
                .padding()

            // TODO: Implement group editor
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(width: 500, height: 400)
    }
}

#Preview {
    let sampleChart = SeatingChart(
        tenantId: "sample",
        chartName: "Wedding Reception",
        eventId: nil
    )

    ModernSidebarView(
        chart: .constant(sampleChart),
        selectedTab: .constant(.guests),
        selectedTableId: .constant(nil)
    )
}
