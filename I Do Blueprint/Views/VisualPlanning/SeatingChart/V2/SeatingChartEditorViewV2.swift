//
//  SeatingChartEditorViewV2.swift
//  My Wedding Planning App
//
//  V2 seating chart editor with illustrated avatars and modern UI
//  Features: DiceBear Personas API, fixed rotation, unified sidebar
//

import SwiftUI

struct SeatingChartEditorViewV2: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2
    @Environment(\.dismiss) private var dismiss

    let seatingChart: SeatingChart
    @State private var editableChart: SeatingChart
    @State private var selectedTableId: UUID?
    @State private var canvasScale: CGFloat = 1.0
    @State private var canvasOffset: CGSize = .zero
    @State private var showGuestNames: Bool = true
    @State private var showingTableEditor = false
    @State private var editingTableId: UUID?
    @State private var showingGuestImport = false
    @State private var showingTableCreator = false
    @State private var hasUnsavedChanges = false
    private let logger = AppLogger.ui

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
                // Modern unified sidebar
                ModernSeatingChartSidebar(
                    chart: $editableChart,
                    selectedTableId: $selectedTableId,
                    onGuestDrop: handleGuestDrop,
                    onTableSelect: handleTableSelection
                )

                Divider()

                // Main canvas with V2 components
                SeatingChartCanvasV2(
                    chart: $editableChart,
                    selectedTableId: $selectedTableId,
                    canvasScale: $canvasScale,
                    canvasOffset: $canvasOffset,
                    showGuestNames: showGuestNames,
                    onTableTap: handleTableSelection,
                    onGuestDrop: handleGuestDrop
                )
            }
        }
        .frame(minWidth: 1200, idealWidth: 1400, minHeight: 650, idealHeight: 700)
        .onAppear {
            loadGuestsIfNeeded()
        }
        .onChange(of: editableChart) { oldValue, newValue in
            hasUnsavedChanges = true
        }
        .sheet(isPresented: $showingTableEditor) {
            if let tableId = editingTableId,
               let tableIndex = editableChart.tables.firstIndex(where: { $0.id == tableId }) {
                TableEditorSheetV2(
                    table: $editableChart.tables[tableIndex],
                    chart: $editableChart,
                    onDismiss: {
                        showingTableEditor = false
                        editingTableId = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showingGuestImport) {
            GuestImportSheetV2(
                chart: $editableChart,
                onDismiss: { showingGuestImport = false }
            )
        }
        .sheet(isPresented: $showingTableCreator) {
            TableCreatorSheetV2(
                chart: $editableChart,
                onDismiss: { showingTableCreator = false }
            )
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            // Title and stats
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(editableChart.chartName)
                        .font(.title2.bold())

                    if hasUnsavedChanges {
                        Image(systemName: "circle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }

                    Text("V2")
                        .font(.caption.bold())
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.seatingAccentTeal)
                        .cornerRadius(4)
                }

                HStack(spacing: 16) {
                    Label("\(editableChart.guests.count) guests", systemImage: "person.3.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(editableChart.tables.count) tables", systemImage: "tablecells.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(editableChart.seatingAssignments.count) seated", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.seatingAccentTeal)
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 12) {
                // Add table button
                Button(action: { showingTableCreator = true }) {
                    Label("Add Table", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)

                // Import guests button
                Button(action: { showingGuestImport = true }) {
                    Label("Import Guests", systemImage: "person.crop.circle.badge.plus")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)

                // Toggle guest names
                Button(action: { showGuestNames.toggle() }) {
                    Image(systemName: showGuestNames ? "textformat" : "textformat.slash")
                        .font(.subheadline)
                }
                .buttonStyle(.borderless)
                .help(showGuestNames ? "Hide guest names" : "Show guest names")

                Divider()
                    .frame(height: 24)

                // Save button
                Button(action: saveChart) {
                    Label("Save", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(.seatingAccentTeal)
                .disabled(!hasUnsavedChanges)

                // Close button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Guest Assignment Handling

    private func handleGuestDrop(guest: SeatingGuest, tableId: UUID?, seatNumber: Int?) {
        // Remove existing assignment if any
        editableChart.seatingAssignments.removeAll { $0.guestId == guest.id }

        // Add new assignment if table specified
        if let tableId = tableId {
            let assignment = SeatingAssignment(
                guestId: guest.id,
                tableId: tableId,
                seatNumber: seatNumber
            )
            editableChart.seatingAssignments.append(assignment)
            hasUnsavedChanges = true
        }
    }

    private func handleTableSelection(_ tableId: UUID) {
        selectedTableId = (selectedTableId == tableId) ? nil : tableId
    }

    // MARK: - Data Loading

    private func loadGuestsIfNeeded() {
        Task {
            do {
                // Load guests from couple_settings if chart has none
                if editableChart.guests.isEmpty {
                    // This would typically call a store method to load guests
                    // For now, we'll just note that guests should be loaded
                                    }
            }
        }
    }

    // MARK: - Save

    private func saveChart() {
        Task {
            do {

                // Log table details
                for (index, table) in editableChart.tables.enumerated() {
                                    }

                try await visualPlanningStore.updateSeatingChart(editableChart)

                logger.info("Save completed successfully")
                hasUnsavedChanges = false
            } catch {
                logger.error("Error saving seating chart", error: error)
            }
        }
    }
}

// MARK: - Supporting Sheets

struct TableEditorSheetV2: View {
    @Binding var table: Table
    @Binding var chart: SeatingChart
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Table \(table.tableNumber)")
                .font(.title2.bold())

            Form {
                Section("Table Details") {
                    TextField("Table Number", value: $table.tableNumber, format: .number)
                    TextField("Table Name (optional)", text: Binding(
                        get: { table.tableName ?? "" },
                        set: { table.tableName = $0.isEmpty ? nil : $0 }
                    ))
                }

                Section("Table Configuration") {
                    Picker("Shape", selection: $table.tableShape) {
                        ForEach(TableShape.allCases, id: \.self) { shape in
                            Text(shape.displayName).tag(shape)
                        }
                    }

                    Stepper("Capacity: \(table.capacity)", value: $table.capacity, in: 2...20)

                    HStack {
                        Text("Rotation:")
                        Slider(value: $table.rotation, in: 0...360, step: 15)
                        Text("\(Int(table.rotation))°")
                            .frame(width: 50)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $table.notes)
                        .frame(height: 60)
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel", action: onDismiss)
                    .buttonStyle(.bordered)

                Spacer()

                Button("Done", action: onDismiss)
                    .buttonStyle(.borderedProminent)
                    .tint(.seatingAccentTeal)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
        .padding()
    }
}

struct GuestImportSheetV2: View {
    @Binding var chart: SeatingChart
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Import Guests")
                .font(.title2.bold())

            Text("Guest import functionality would be implemented here")
                .foregroundColor(.secondary)

            Spacer()

            Button("Done", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .tint(.seatingAccentTeal)
        }
        .frame(width: 600, height: 400)
        .padding()
    }
}

struct TableCreatorSheetV2: View {
    @Binding var chart: SeatingChart
    let onDismiss: () -> Void

    @State private var tableShape: TableShape = .round
    @State private var capacity: Int = 8
    @State private var count: Int = 1

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Tables")
                .font(.title2.bold())

            Form {
                Picker("Table Shape", selection: $tableShape) {
                    ForEach(TableShape.allCases, id: \.self) { shape in
                        Text(shape.displayName).tag(shape)
                    }
                }

                Stepper("Capacity: \(capacity)", value: $capacity, in: 2...20)

                Stepper("Number of Tables: \(count)", value: $count, in: 1...20)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel", action: onDismiss)
                    .buttonStyle(.bordered)

                Spacer()

                Button("Add Tables") {
                    addTables()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.seatingAccentTeal)
            }
        }
        .frame(width: 400, height: 300)
        .padding()
    }

    private func addTables() {
        let startNumber = (chart.tables.map { $0.tableNumber }.max() ?? 0) + 1

        for i in 0..<count {
            let table = Table(
                tableNumber: startNumber + i,
                position: CGPoint(x: CGFloat(i * 150), y: 0),
                shape: tableShape,
                capacity: capacity
            )
            chart.tables.append(table)
        }
    }
}
