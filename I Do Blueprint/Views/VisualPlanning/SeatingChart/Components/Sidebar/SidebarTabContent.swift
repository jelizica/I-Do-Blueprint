//
//  SidebarTabContent.swift
//  I Do Blueprint
//
//  Tab content views for modern sidebar
//

import SwiftUI

// MARK: - Layout Content

struct SidebarLayoutContent: View {
    @Binding var chart: SeatingChart
    
    var body: some View {
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
}

// MARK: - Tables Content

struct SidebarTablesContent: View {
    @Binding var chart: SeatingChart
    @Binding var selectedTableId: UUID?
    let searchText: String
    
    private var filteredTables: [Table] {
        if searchText.isEmpty {
            return chart.tables
        }
        return chart.tables.filter { table in
            "Table \(table.tableNumber)".localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
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
}

// MARK: - Guests Content

struct SidebarGuestsContent: View {
    @Binding var chart: SeatingChart
    @Binding var guestGroups: [SeatingGuestGroup]
    @Binding var showingGroupEditor: Bool
    let searchText: String
    
    private var unassignedGuests: [SeatingGuest] {
        chart.guests.filter { guest in
            !chart.seatingAssignments.contains { $0.guestId == guest.id }
        }
    }
    
    var body: some View {
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
    }
}

// MARK: - Assignments Content

struct SidebarAssignmentsContent: View {
    @Binding var chart: SeatingChart
    
    var body: some View {
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
}

// MARK: - Analytics Content

struct SidebarAnalyticsContent: View {
    let chart: SeatingChart
    
    private var analytics: (
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
        
        // Calculate conflicts
        var conflictCount = 0
        var processedPairs = Set<String>()
        let assignmentsByTable = Dictionary(grouping: chart.seatingAssignments, by: \.tableId)
        
        for (_, assignments) in assignmentsByTable {
            let guestIdsAtTable = assignments.map(\.guestId)
            
            for assignment in assignments {
                guard let guest = chart.guests.first(where: { $0.id == assignment.guestId }) else { continue }
                
                for conflictId in guest.conflicts {
                    if guestIdsAtTable.contains(conflictId) {
                        let pairKey = [guest.id.uuidString, conflictId.uuidString].sorted().joined(separator: "-")
                        
                        if !processedPairs.contains(pairKey) {
                            conflictCount += 1
                            processedPairs.insert(pairKey)
                        }
                    }
                }
            }
        }

        return (
            totalGuests,
            assignedGuests,
            unassignedGuests,
            totalTables,
            occupiedTables,
            progress,
            conflictCount
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Stats cards
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
}
