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
    @State private var showingObstacleEditor = false
    @State private var editingObstacle: VenueObstacle?
    @State private var showingAssignmentEditor = false
    @State private var editingAssignment: SeatingAssignment?
    @State private var showingTableSelector = false
    @State private var guestToAssign: SeatingGuest?

    init(seatingChart: SeatingChart) {
        self.seatingChart = seatingChart
        _editableChart = State(initialValue: seatingChart)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            SeatingChartHeader(
                chartName: editableChart.chartName,
                chartDescription: editableChart.chartDescription,
                canvasScale: $canvasScale,
                onFitToView: fitCanvasToView,
                onSave: saveChart,
                onClose: { dismiss() }
            )

            Divider()

            HStack(spacing: 0) {
                // Left Sidebar
                SeatingChartSidebar(
                    editableChart: $editableChart,
                    selectedTab: $selectedTab,
                    selectedTableId: $selectedTableId,
                    editingTableId: $editingTableId,
                    showingTableEditor: $showingTableEditor,
                    showingGuestImport: $showingGuestImport,
                    onEditTable: editTable,
                    onDeleteTable: deleteTable,
                    onAddTable: addNewTable,
                    onAssignGuest: assignGuest,
                    onUnassignGuest: unassignGuest,
                    onEditAssignment: editAssignment,
                    onRemoveAssignment: removeAssignment,
                    onAutoAssign: autoAssignGuests,
                    onAddVenueElement: addVenueElement,
                    onEditObstacle: editObstacle,
                    onRemoveObstacle: removeObstacle,
                    getAssignedTable: getAssignedTable,
                    loadAvailableGuests: loadAvailableGuests,
                    importGuests: importGuests,
                    calculateAnalytics: { editableChart.calculateAnalytics() }
                )

                Divider()

                // Main Canvas
                SeatingChartCanvas(
                    editableChart: $editableChart,
                    selectedTableId: $selectedTableId,
                    editingTableId: $editingTableId,
                    showingTableEditor: $showingTableEditor,
                    canvasScale: $canvasScale,
                    canvasOffset: $canvasOffset,
                    isDraggingTable: $isDraggingTable,
                    dragStartPosition: $dragStartPosition,
                    draggingTableId: $draggingTableId,
                    updateTablePositionWithTranslation: updateTablePositionWithTranslation
                )
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
        // TODO: Implement ObstacleEditorSheet for editing venue obstacles
        // .sheet(isPresented: $showingObstacleEditor) { ... }
        
        // TODO: Implement AssignmentEditorSheet for editing seating assignments
        // .sheet(isPresented: $showingAssignmentEditor) { ... }
        
        // TODO: Implement TableSelectorSheet for selecting tables when assigning guests
        // .sheet(isPresented: $showingTableSelector) { ... }
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
        editableChart.venueConfiguration.obstacles.append(newObstacle)
    }

    private func getAssignedTable(for guestId: UUID) -> Table? {
        guard let assignment = editableChart.seatingAssignments.first(where: { $0.guestId == guestId }) else {
            return nil
        }
        return editableChart.tables.first { $0.id == assignment.tableId }
    }

    private func removeAssignment(_ assignment: SeatingAssignment) {
        editableChart.seatingAssignments.removeAll { $0.id == assignment.id }
    }
    
    private func editObstacle(_ obstacle: VenueObstacle) {
        editingObstacle = obstacle
        showingObstacleEditor = true
    }
    
    private func removeObstacle(_ obstacle: VenueObstacle) {
        editableChart.venueConfiguration.obstacles.removeAll { $0.id == obstacle.id }
    }
    
    private func assignGuest(_ guest: SeatingGuest) {
        guestToAssign = guest
        showingTableSelector = true
    }
    
    private func unassignGuest(_ guest: SeatingGuest) {
        editableChart.seatingAssignments.removeAll { $0.guestId == guest.id }
    }
    
    private func importGuests(_ guests: [SeatingGuest]) {
        // Add guests that aren't already in the chart
        for guest in guests {
            if !editableChart.guests.contains(where: { $0.id == guest.id }) {
                editableChart.guests.append(guest)
            }
        }
    }
    
    private func editAssignment(_ assignment: SeatingAssignment) {
        editingAssignment = assignment
        showingAssignmentEditor = true
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
    
    private func loadAvailableGuests() -> [SeatingGuest] {
        // Return guests that aren't already in the chart
        // This is a synchronous function for the sheet, so we return empty array
        // The actual loading happens in loadGuestsIfNeeded()
        return []
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
