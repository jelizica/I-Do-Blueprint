//
//  SeatingChartSidebar.swift
//  I Do Blueprint
//
//  Sidebar component for seating chart editor with tab navigation and content
//

import SwiftUI

struct SeatingChartSidebar: View {
    @Binding var editableChart: SeatingChart
    @Binding var selectedTab: EditorTab
    @Binding var selectedTableId: UUID?
    @Binding var editingTableId: UUID?
    @Binding var showingTableEditor: Bool
    @Binding var showingGuestImport: Bool

    let onEditTable: (Table) -> Void
    let onDeleteTable: (Table) -> Void
    let onAddTable: () -> Void
    let onAssignGuest: (SeatingGuest) -> Void
    let onUnassignGuest: (SeatingGuest) -> Void
    let onEditAssignment: (SeatingAssignment) -> Void
    let onRemoveAssignment: (SeatingAssignment) -> Void
    let onAutoAssign: () -> Void
    let onAddVenueElement: () -> Void
    let onEditObstacle: (VenueObstacle) -> Void
    let onRemoveObstacle: (VenueObstacle) -> Void
    let getAssignedTable: (UUID) -> Table?
    let loadAvailableGuests: () -> [SeatingGuest]
    let importGuests: ([SeatingGuest]) -> Void
    let calculateAnalytics: () -> SeatingAnalytics

    var body: some View {
        VStack(spacing: 0) {
            // Tab Selection
            tabSelectionSection

            Divider()

            // Tab Content
            switch selectedTab {
            case .layout:
                layoutTabContent
            case .tables:
                tablesTabContent
            case .guests:
                guestsTabContent
            case .assignments:
                assignmentsTabContent
            case .analytics:
                analyticsTabContent
            }
        }
        .frame(minWidth: 320, idealWidth: 360)
    }

    // MARK: - Tab Selection

    private var tabSelectionSection: some View {
        VStack(spacing: 8) {
            ForEach(EditorTab.allCases, id: \.self) { tab in
                EditorTabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    count: getTabCount(for: tab)) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(Spacing.md)
    }

    private func getTabCount(for tab: EditorTab) -> Int? {
        switch tab {
        case .layout:
            nil
        case .tables:
            editableChart.tables.count
        case .guests:
            editableChart.guests.count
        case .assignments:
            editableChart.seatingAssignments.count
        case .analytics:
            nil
        }
    }

    // MARK: - Layout Tab

    private var layoutTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Venue settings card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Venue Layout")
                        .font(.headline)

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Layout: \(editableChart.venueLayoutType.displayName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.textSecondary.opacity(0.15), lineWidth: 1))

                // Venue elements card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Venue Elements")
                        .font(.headline)

                    Divider()

                    Button("Add Element") {
                        onAddVenueElement()
                    }
                    .buttonStyle(.bordered)

                    // Venue obstacles list
                    if !editableChart.venueConfiguration.obstacles.isEmpty {
                        ForEach(editableChart.venueConfiguration.obstacles, id: \.id) { obstacle in
                            ObstacleRow(
                                obstacle: obstacle,
                                onEdit: { onEditObstacle(obstacle) },
                                onDelete: { onRemoveObstacle(obstacle) }
                            )
                            .id(obstacle.id)
                        }
                    }
                }
                .padding(Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.textSecondary.opacity(0.15), lineWidth: 1))

                // Grid settings card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Grid Settings")
                        .font(.headline)

                    Divider()

                    Toggle("Snap to Grid", isOn: $editableChart.layoutSettings.snapToGrid)
                        .font(.subheadline)

                    if editableChart.layoutSettings.snapToGrid {
                        HStack {
                            Text("Grid Size:")
                                .font(.subheadline)

                            Slider(value: $editableChart.layoutSettings.gridSize, in: 10 ... 50, step: 5)

                            Text("\(Int(editableChart.layoutSettings.gridSize))")
                                .font(.system(.subheadline, design: .monospaced))
                                .frame(width: 30)
                        }
                    }
                }
                .padding(Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.textSecondary.opacity(0.15), lineWidth: 1))
            }
            .padding()
        }
    }

    // MARK: - Tables Tab

    private var tablesTabContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Tables (\(editableChart.tables.count))")
                    .font(.headline)

                Spacer()

                Button("Add Table") {
                    onAddTable()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()

            Divider()

            // Tables list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(editableChart.tables, id: \.id) { table in
                        TableRowView(
                            table: table,
                            isSelected: selectedTableId == table.id,
                            assignments: editableChart.seatingAssignments.filter { $0.tableId == table.id },
                            onSelect: { selectedTableId = table.id },
                            onEdit: { onEditTable(table) },
                            onDelete: { onDeleteTable(table) })
                            .id(table.id)
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Guests Tab

    private var guestsTabContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Guests (\(editableChart.guests.count))")
                    .font(.headline)

                Spacer()

                Button("Import Guests") {
                    showingGuestImport = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()

            Divider()

            // Guests list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(editableChart.guests, id: \.id) { guest in
                        GuestRow(
                            guest: guest,
                            assignedTable: getAssignedTable(guest.id),
                            onAssign: { onAssignGuest(guest) },
                            onUnassign: { onUnassignGuest(guest) }
                        )
                        .id(guest.id)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingGuestImport) {
            GuestImportView(
                isPresented: $showingGuestImport,
                availableGuests: loadAvailableGuests(),
                onImport: { guests in
                    importGuests(guests)
                }
            )
        }
    }

    // MARK: - Assignments Tab

    private var assignmentsTabContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Assignments")
                    .font(.headline)

                Spacer()

                Button("Auto-Assign") {
                    onAutoAssign()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()

            Divider()

            // Assignment progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    let progress = getAssignmentProgress()
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                ProgressView(value: getAssignmentProgress())
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
            }
            .padding()

            Divider()

            // Assignments list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(editableChart.seatingAssignments, id: \.id) { assignment in
                        if let guest = editableChart.guests.first(where: { $0.id == assignment.guestId }),
                           let table = editableChart.tables.first(where: { $0.id == assignment.tableId }) {
                            SeatingAssignmentRow(
                                assignment: assignment,
                                guest: guest,
                                table: table,
                                onEdit: { onEditAssignment(assignment) },
                                onRemove: { onRemoveAssignment(assignment) }
                            )
                            .id(assignment.id)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private func getAssignmentProgress() -> Double {
        guard !editableChart.guests.isEmpty else { return 0 }
        return Double(editableChart.seatingAssignments.count) / Double(editableChart.guests.count)
    }

    // MARK: - Analytics Tab

    private var analyticsTabContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Overview stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overview")
                        .font(.headline)

                    let analytics = calculateAnalytics()

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        SeatingAnalyticsCard(
                            title: "Total Guests",
                            value: "\(analytics.totalGuests)",
                            subtitle: "\(analytics.assignedGuests) assigned",
                            color: .blue,
                            icon: "person.3")

                        SeatingAnalyticsCard(
                            title: "Total Tables",
                            value: "\(analytics.totalTables)",
                            subtitle: "\(analytics.occupiedTables) occupied",
                            color: .green,
                            icon: "tablecells")

                        SeatingAnalyticsCard(
                            title: "Assignment Progress",
                            value: "\(Int(analytics.assignmentProgress * 100))%",
                            subtitle: "\(analytics.unassignedGuests) remaining",
                            color: .orange,
                            icon: "chart.bar")

                        SeatingAnalyticsCard(
                            title: "Table Utilization",
                            value: "\(Int(analytics.tableUtilization * 100))%",
                            subtitle: String(format: "Avg %.1f per table", analytics.averageTableOccupancy),
                            color: .purple,
                            icon: "chart.pie")
                    }
                }

                // Conflicts and preferences
                VStack(alignment: .leading, spacing: 8) {
                    Text("Seating Quality")
                        .font(.headline)

                    let analytics = calculateAnalytics()

                    HStack(spacing: 16) {
                        ConflictBadge(
                            title: "Conflicts",
                            count: analytics.conflictCount,
                            icon: "exclamationmark.triangle",
                            isGood: analytics.conflictCount == 0)

                        ConflictBadge(
                            title: "Preferences Satisfied",
                            count: analytics.satisfiedPreferences,
                            totalCount: analytics.totalPreferences,
                            icon: "heart",
                            isGood: analytics.preferenceScore > 0.8)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    let sampleChart = SeatingChart(
        tenantId: "sample",
        chartName: "Wedding Reception",
        eventId: nil)

    SeatingChartSidebar(
        editableChart: .constant(sampleChart),
        selectedTab: .constant(.layout),
        selectedTableId: .constant(nil),
        editingTableId: .constant(nil),
        showingTableEditor: .constant(false),
        showingGuestImport: .constant(false),
        onEditTable: { _ in },
        onDeleteTable: { _ in },
        onAddTable: {},
        onAssignGuest: { _ in },
        onUnassignGuest: { _ in },
        onEditAssignment: { _ in },
        onRemoveAssignment: { _ in },
        onAutoAssign: {},
        onAddVenueElement: {},
        onEditObstacle: { _ in },
        onRemoveObstacle: { _ in },
        getAssignedTable: { _ in nil },
        loadAvailableGuests: { [] },
        importGuests: { _ in },
        calculateAnalytics: {
            SeatingAnalytics(
                totalGuests: 0,
                assignedGuests: 0,
                unassignedGuests: 0,
                totalTables: 0,
                occupiedTables: 0,
                emptyTables: 0,
                averageTableOccupancy: 0,
                conflictCount: 0,
                satisfiedPreferences: 0,
                totalPreferences: 0
            )
        }
    )
}
