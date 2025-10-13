//
//  SeatingChartEditorView.swift
//  My Wedding Planning App
//
//  Interactive seating chart editor with drag & drop functionality
//

import SwiftUI

struct SeatingChartEditorView: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2
    @Environment(\.dismiss) private var dismiss

    let seatingChart: SeatingChart
    @State private var editableChart: SeatingChart
    @State private var selectedTab: EditorTab = .layout
    @State private var selectedTableId: UUID?
    @State private var editingTableId: UUID?
    @State private var showingTableEditor = false
    @State private var selectedGuestId: UUID?
    @State private var canvasScale: CGFloat = 1.0
    @State private var canvasOffset: CGPoint = .zero
    @State private var showingGuestImport = false
    @State private var showingTableCreator = false
    @State private var isDraggingTable = false
    @State private var dragStartPosition: CGPoint = .zero
    @State private var draggingTableId: UUID?

    init(seatingChart: SeatingChart) {
        self.seatingChart = seatingChart
        _editableChart = State(initialValue: seatingChart)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            HStack(spacing: 0) {
                // Left Sidebar
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

                Divider()

                // Main Canvas
                canvasSection
            }
        }
        .frame(minWidth: 1200, idealWidth: 1400, minHeight: 650, idealHeight: 700, maxHeight: 720)
        .onAppear {
            centerCanvas()
            loadGuestsIfNeeded()
        }
        .sheet(isPresented: $showingTableEditor) {
            if let tableId = editingTableId,
               let table = editableChart.tables.first(where: { $0.id == tableId }) {
                TableEditorSheet(
                    table: binding(for: tableId),
                    guests: editableChart.guests,
                    assignments: bindingForAssignments(tableId: tableId),
                    onRotate: { rotateTable(tableId, angle: 45) },
                    onDismiss: {
                        showingTableEditor = false
                        editingTableId = nil
                    })
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(editableChart.chartName)
                    .font(.title2)
                    .fontWeight(.semibold)

                if let description = editableChart.chartDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Canvas controls
            HStack(spacing: 8) {
                Button("Zoom Out") {
                    canvasScale = max(0.5, canvasScale - 0.1)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(canvasScale <= 0.5)

                Text("\(Int(canvasScale * 100))%")
                    .font(.system(.caption, design: .monospaced))
                    .frame(width: 50)

                Button("Zoom In") {
                    canvasScale = min(2.0, canvasScale + 0.1)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(canvasScale >= 2.0)

                Button("Fit to View") {
                    fitCanvasToView()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            HStack(spacing: 8) {
                Button("Save") {
                    saveChart()
                }
                .buttonStyle(.borderedProminent)

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
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
        .padding(12)
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
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1))

                // Venue elements card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Venue Elements")
                        .font(.headline)

                    Divider()

                    Button("Add Element") {
                        addVenueElement()
                    }
                    .buttonStyle(.bordered)

                    // TODO: Implement ObstacleRow component
                    // if !editableChart.venueConfiguration.obstacles.isEmpty {
                    //     ForEach(editableChart.venueConfiguration.obstacles) { obstacle in
                    //         ObstacleRow(obstacle: obstacle) {
                    //             removeObstacle(obstacle)
                    //         }
                    //     }
                    // }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1))

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
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1))
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
                    addNewTable()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()

            Divider()

            // Tables list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(editableChart.tables) { table in
                        TableRowView(
                            table: table,
                            isSelected: selectedTableId == table.id,
                            assignments: editableChart.seatingAssignments.filter { $0.tableId == table.id },
                            onSelect: { selectedTableId = table.id },
                            onEdit: { editTable(table) },
                            onDelete: { deleteTable(table) })
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
                    ForEach(editableChart.guests) { guest in
                        // TODO: Implement GuestRow component
                        HStack {
                            Text("\(guest.firstName) \(guest.lastName)")
                            Spacer()
                            if editableChart.seatingAssignments.contains(where: { $0.guestId == guest.id }) {
                                Text("Assigned")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(selectedGuestId == guest.id ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                        .cornerRadius(8)
                        .onTapGesture {
                            selectedGuestId = guest.id
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingGuestImport) {
            // TODO: Implement GuestImportView component
            VStack {
                Text("Guest Import")
                Button("Cancel") {
                    showingGuestImport = false
                }
            }
            .padding()
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
                    autoAssignGuests()
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
                    ForEach(editableChart.seatingAssignments) { assignment in
                        // TODO: Implement AssignmentRow component
                        HStack {
                            if let guest = editableChart.guests.first(where: { $0.id == assignment.guestId }),
                               let table = editableChart.tables.first(where: { $0.id == assignment.tableId }) {
                                Text("\(guest.firstName) \(guest.lastName)")
                                Spacer()
                                Text("Table \(table.tableNumber)")
                                    .font(.caption)
                                Button("Remove") {
                                    removeAssignment(assignment)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
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

    // MARK: - Canvas Section

    private var canvasSection: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.white

                // Grid overlay
                if editableChart.layoutSettings.snapToGrid {
                    GridOverlay(
                        gridSize: editableChart.layoutSettings.gridSize,
                        showGrid: true,
                        canvasSize: geometry.size,
                        scale: canvasScale)
                }

                // Render tables on canvas
                ForEach(editableChart.tables) { table in
                    TableView(
                        table: table,
                        isSelected: selectedTableId == table.id,
                        isEditing: editingTableId == table.id,
                        scale: canvasScale,
                        assignments: editableChart.seatingAssignments,
                        guests: editableChart.guests)
                        .rotationEffect(.degrees(table.rotation))
                        .position(
                            x: table.position.x * canvasScale + canvasOffset.x,
                            y: table.position.y * canvasScale + canvasOffset.y)
                        .onTapGesture {
                            selectedTableId = table.id
                        }
                        .onTapGesture(count: 2) {
                            // Double-click to open table editor
                            editingTableId = table.id
                            showingTableEditor = true
                        }
                        .gesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { value in
                                    // Allow dragging when table is selected or being edited
                                    if selectedTableId == table.id || editingTableId == table.id {
                                        if !isDraggingTable {
                                            // Start of drag - store initial position
                                            isDraggingTable = true
                                            draggingTableId = table.id
                                            dragStartPosition = table.position
                                        }

                                        if draggingTableId == table.id {
                                            // Update position based on translation from start
                                            updateTablePositionWithTranslation(
                                                table.id,
                                                startPosition: dragStartPosition,
                                                translation: value.translation)
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    isDraggingTable = false
                                    draggingTableId = nil
                                })
                }

                // Minimap positioned in bottom-right corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        MinimapView(
                            tables: editableChart.tables,
                            canvasSize: geometry.size,
                            canvasScale: canvasScale,
                            canvasOffset: canvasOffset,
                            viewportSize: geometry.size)
                            .frame(width: 150, height: 100)
                            .padding(16)
                    }
                }
            }
            .clipped()
            .gesture(
                SimultaneousGesture(
                    // Pan gesture
                    DragGesture()
                        .onChanged { value in
                            if !isDraggingTable {
                                canvasOffset = CGPoint(
                                    x: canvasOffset.x + value.translation.width,
                                    y: canvasOffset.y + value.translation.height)
                            }
                        },
                    // Zoom gesture
                    MagnificationGesture()
                        .onChanged { value in
                            canvasScale = max(0.5, min(2.0, value))
                        }))
        }
    }

    // MARK: - Helper Methods

    private func centerCanvas() {
        canvasOffset = .zero
        canvasScale = 1.0
    }

    private func fitCanvasToView() {
        canvasScale = 0.8
        canvasOffset = .zero
    }

    private func saveChart() {
        Task {
            await visualPlanningStore.updateSeatingChart(editableChart)
            dismiss()
        }
    }

    private func addNewTable() {
        let newTable = Table(
            tableNumber: editableChart.tables.count + 1,
            position: CGPoint(x: 100, y: 100),
            shape: .round,
            capacity: 8)
        editableChart.tables.append(newTable)
    }

    private func editTable(_ table: Table) {
        editingTableId = table.id
        selectedTableId = table.id
        showingTableEditor = true
    }

    private func updateTablePosition(_ tableId: UUID, translation: CGSize) {
        if let index = editableChart.tables.firstIndex(where: { $0.id == tableId }) {
            var table = editableChart.tables[index]
            table.position.x += translation.width / canvasScale
            table.position.y += translation.height / canvasScale
            editableChart.tables[index] = table
        }
    }

    private func updateTablePositionWithTranslation(_ tableId: UUID, startPosition: CGPoint, translation: CGSize) {
        if let index = editableChart.tables.firstIndex(where: { $0.id == tableId }) {
            var table = editableChart.tables[index]
            // Set absolute position based on start position + translation
            table.position.x = startPosition.x + (translation.width / canvasScale)
            table.position.y = startPosition.y + (translation.height / canvasScale)
            editableChart.tables[index] = table
        }
    }

    private func rotateTable(_ tableId: UUID, angle: Double) {
        if let index = editableChart.tables.firstIndex(where: { $0.id == tableId }) {
            var table = editableChart.tables[index]
            table.rotation += angle
            editableChart.tables[index] = table
        }
    }

    private func deleteTable(_ table: Table) {
        editableChart.tables.removeAll { $0.id == table.id }
        editableChart.seatingAssignments.removeAll { $0.tableId == table.id }
    }

    private func binding(for tableId: UUID) -> Binding<Table> {
        Binding(
            get: {
                editableChart.tables.first(where: { $0.id == tableId }) ?? editableChart.tables[0]
            },
            set: { newValue in
                if let index = editableChart.tables.firstIndex(where: { $0.id == tableId }) {
                    editableChart.tables[index] = newValue
                }
            })
    }

    private func bindingForAssignments(tableId: UUID) -> Binding<[SeatingAssignment]> {
        Binding(
            get: {
                editableChart.seatingAssignments.filter { $0.tableId == tableId }
            },
            set: { newAssignments in
                editableChart.seatingAssignments.removeAll { $0.tableId == tableId }
                editableChart.seatingAssignments.append(contentsOf: newAssignments)
            })
    }

    private func addVenueElement() {
        let newObstacle = VenueObstacle(
            name: "New Element",
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 100, height: 50),
            type: .bar)
        // Note: SeatingChart doesn't have venueLayout property
        // editableChart.venueLayout.obstacles.append(newObstacle)
    }

    private func removeObstacle(_: VenueObstacle) {
        // Note: SeatingChart doesn't have venueLayout property
        // editableChart.venueLayout.obstacles.removeAll { $0.id == obstacle.id }
    }

    private func getAssignedTable(for _: UUID) -> Table? {
        // Note: SeatingChart doesn't have seatingAssignments property
        // guard let assignment = editableChart.seatingAssignments.first(where: { $0.guestId == guestId }) else {
        //     return nil
        // }
        // return editableChart.tables.first { $0.id == assignment.tableId }
        nil
    }

    private func getAssignmentProgress() -> Double {
        guard !editableChart.guests.isEmpty else { return 0 }
        // Note: SeatingChart doesn't have seatingAssignments property
        // return Double(editableChart.seatingAssignments.count) / Double(editableChart.guests.count)
        return 0
    }

    private func removeAssignment(_: SeatingAssignment) {
        // Note: SeatingChart doesn't have seatingAssignments property
        // editableChart.seatingAssignments.removeAll { $0.id == assignment.id }
    }

    private func autoAssignGuests() {
        // Simple auto-assignment algorithm
        let unassignedGuests = editableChart.guests.filter { guest in
            !editableChart.seatingAssignments.contains { $0.guestId == guest.id }
        }

        for guest in unassignedGuests {
            if let availableTable = editableChart.tables.first(where: { !$0.isFull }) {
                let assignment = SeatingAssignment(guestId: guest.id, tableId: availableTable.id)
                editableChart.seatingAssignments.append(assignment)
            }
        }
    }

    private func handleTableDrop(tableId: UUID, position: CGPoint) {
        if let tableIndex = editableChart.tables.firstIndex(where: { $0.id == tableId }) {
            editableChart.tables[tableIndex].position = position
        }
    }

    private func loadGuestsIfNeeded() {
        // Load guests if the chart doesn't have any
        guard editableChart.guests.isEmpty else { return }

        Task {
            do {
                let service = SupabaseVisualPlanningService()
                let guests = try await service.fetchSeatingGuests(for: editableChart.tenantId)
                editableChart.guests = guests
            } catch {
                AppLogger.ui.error("Failed to load guests", error: error)
            }
        }
    }

    private func calculateAnalytics() -> SeatingAnalytics {
        let totalGuests = editableChart.guests.count
        let assignedGuests = editableChart.seatingAssignments.count
        let unassignedGuests = totalGuests - assignedGuests

        let totalTables = editableChart.tables.count
        let occupiedTables = Set(editableChart.seatingAssignments.map(\.tableId)).count
        let emptyTables = totalTables - occupiedTables

        let averageOccupancy = totalTables > 0 ? Double(assignedGuests) / Double(totalTables) : 0

        // TODO: Calculate conflicts and preferences properly
        let conflictCount = 0
        let satisfiedPreferences = 0
        let totalPreferences = editableChart.guests.reduce(0) { $0 + $1.preferences.count }

        return SeatingAnalytics(
            totalGuests: totalGuests,
            assignedGuests: assignedGuests,
            unassignedGuests: unassignedGuests,
            totalTables: totalTables,
            occupiedTables: occupiedTables,
            emptyTables: emptyTables,
            averageTableOccupancy: averageOccupancy,
            conflictCount: conflictCount,
            satisfiedPreferences: satisfiedPreferences,
            totalPreferences: totalPreferences)
    }
}

// MARK: - Editor Tabs

enum EditorTab: CaseIterable {
    case layout, tables, guests, assignments, analytics

    var title: String {
        switch self {
        case .layout: "Layout"
        case .tables: "Tables"
        case .guests: "Guests"
        case .assignments: "Assignments"
        case .analytics: "Analytics"
        }
    }

    var icon: String {
        switch self {
        case .layout: "rectangle.3.group"
        case .tables: "tablecells"
        case .guests: "person.2"
        case .assignments: "arrow.right.circle"
        case .analytics: "chart.pie"
        }
    }
}

#Preview {
    let sampleChart = SeatingChart(
        tenantId: "sample",
        chartName: "Wedding Reception",
        eventId: nil)

    SeatingChartEditorView(seatingChart: sampleChart)
        .environmentObject(VisualPlanningStoreV2())
}
