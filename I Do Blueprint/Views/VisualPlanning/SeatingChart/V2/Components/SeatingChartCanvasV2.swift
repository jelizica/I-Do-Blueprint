//
//  SeatingChartCanvasV2.swift
//  My Wedding Planning App
//
//  Canvas view with zoom, pan, and fixed rotation for Seating Chart V2
//

import SwiftUI
import UniformTypeIdentifiers

/// V2 canvas with proper rotation handling and drag gestures
struct SeatingChartCanvasV2: View {
    @Binding var chart: SeatingChart
    @Binding var selectedTableId: UUID?
    @Binding var canvasScale: CGFloat
    @Binding var canvasOffset: CGSize

    let showGuestNames: Bool
    let onTableTap: (UUID) -> Void
    let onGuestDrop: (SeatingGuest, UUID?, Int?) -> Void

    @State private var dragStartPosition: CGPoint = .zero
    @State private var hoveredTableId: UUID?

    // MARK: - Constants

    private let minScale: CGFloat = 0.3
    private let maxScale: CGFloat = 3.0
    private let canvasSize = CGSize(width: 2000, height: 1500)

    // MARK: - Computed Properties

    private var assignmentsByTable: [UUID: [SeatingAssignment]] {
        Dictionary(grouping: chart.seatingAssignments) { $0.tableId }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Canvas background
                canvasBackground

                // Tables with guests
                ForEach(chart.tables) { table in
                    TableViewV2(
                        table: table,
                        assignments: assignmentsByTable[table.id] ?? [],
                        guests: chart.guests,
                        scale: canvasScale,
                        showGuestNames: showGuestNames,
                        isSelected: selectedTableId == table.id,
                        onRotate: { tableId, rotation in
                            rotateTable(tableId, to: rotation)
                        },
                        onDelete: { tableId in
                            deleteTable(tableId)
                        }
                    )
                    .position(
                        x: table.position.x * canvasScale + canvasOffset.width + geometry.size.width / 2,
                        y: table.position.y * canvasScale + canvasOffset.height + geometry.size.height / 2
                    )
                    .gesture(
                        tableDragGesture(for: table)
                    )
                    .onTapGesture {
                        onTableTap(table.id)
                    }
                    .onHover { hovering in
                        hoveredTableId = hovering ? table.id : nil
                    }
                }

                // Minimap
                minimapView(in: geometry)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(canvasPanGesture)
            .gesture(magnificationGesture)
            .onDrop(of: [.text], isTargeted: nil) { providers, location in
                handleDrop(providers: providers, location: location, in: geometry)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .focusable()
        .onKeyPress(.init("r")) {
            rotateSelectedTable(by: 90)
            return .handled
        }
        .onKeyPress(.init("R")) {
            rotateSelectedTable(by: -90)
            return .handled
        }
    }

    // MARK: - Subviews

    private var canvasBackground: some View {
        ZStack {
            // Grid pattern
            Canvas { context, size in
                let gridSpacing: CGFloat = 50 * canvasScale
                let offsetX = canvasOffset.width.truncatingRemainder(dividingBy: gridSpacing)
                let offsetY = canvasOffset.height.truncatingRemainder(dividingBy: gridSpacing)

                context.stroke(
                    Path { path in
                        // Vertical lines
                        var x = offsetX
                        while x < size.width {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                            x += gridSpacing
                        }

                        // Horizontal lines
                        var y = offsetY
                        while y < size.height {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                            y += gridSpacing
                        }
                    },
                    with: .color(.gray.opacity(0.2)),
                    lineWidth: 1
                )
            }

            // Center crosshair
            Path { path in
                let centerX = canvasOffset.width
                let centerY = canvasOffset.height

                // Vertical line
                path.move(to: CGPoint(x: centerX, y: centerY - 20))
                path.addLine(to: CGPoint(x: centerX, y: centerY + 20))

                // Horizontal line
                path.move(to: CGPoint(x: centerX - 20, y: centerY))
                path.addLine(to: CGPoint(x: centerX + 20, y: centerY))
            }
            .stroke(Color.seatingAccentTeal, lineWidth: 2)
        }
    }

    private func minimapView(in geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    // Zoom controls
                    VStack(spacing: 4) {
                        Button(action: { zoomIn() }) {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.borderless)

                        Text("\(Int(canvasScale * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Button(action: { zoomOut() }) {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.borderless)

                        Button(action: { resetView() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(Spacing.sm)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.9))
                    .cornerRadius(8)
                    .shadow(radius: 2)

                    // Mini viewport indicator
                    ZStack {
                        // Tables in minimap
                        ForEach(chart.tables) { table in
                            Rectangle()
                                .fill(selectedTableId == table.id ? Color.seatingAccentTeal : SemanticColors.textSecondary)
                                .frame(width: 8, height: 8)
                                .position(
                                    x: (table.position.x / canvasSize.width) * 120 + 60,
                                    y: (table.position.y / canvasSize.height) * 90 + 45
                                )
                        }

                        // Viewport rectangle
                        Rectangle()
                            .stroke(Color.seatingAccentTeal, lineWidth: 2)
                            .frame(width: 120 / canvasScale, height: 90 / canvasScale)
                    }
                    .frame(width: 120, height: 90)
                    .background(SemanticColors.textPrimary.opacity(Opacity.subtle))
                    .cornerRadius(4)
                    .shadow(radius: 2)
                }
                .padding()
            }
        }
    }

    // MARK: - Gestures

    private func tableDragGesture(for table: Table) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                if dragStartPosition == .zero {
                    dragStartPosition = table.position
                }

                // Don't transform translation - table position is in canvas coordinates
                // Rotation only affects visual appearance, not coordinate system
                updateTablePosition(
                    table.id,
                    startPosition: dragStartPosition,
                    translation: value.translation
                )
            }
            .onEnded { _ in
                dragStartPosition = .zero
            }
    }

    private var canvasPanGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                canvasOffset = CGSize(
                    width: canvasOffset.width + value.translation.width,
                    height: canvasOffset.height + value.translation.height
                )
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = canvasScale * value
                canvasScale = min(max(newScale, minScale), maxScale)
            }
    }

    // MARK: - Helper Methods

    private func updateTablePosition(_ tableId: UUID, startPosition: CGPoint, translation: CGSize) {
        if let index = chart.tables.firstIndex(where: { $0.id == tableId }) {
            let newPosition = CGPoint(
                x: startPosition.x + translation.width / canvasScale,
                y: startPosition.y + translation.height / canvasScale
            )
            chart.tables[index].position = newPosition
        }
    }

    private func rotateTable(_ tableId: UUID, to rotation: Double) {
        if let index = chart.tables.firstIndex(where: { $0.id == tableId }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                chart.tables[index].rotation = rotation
            }
        }
    }

    private func rotateSelectedTable(by degrees: Double) {
        guard let selectedId = selectedTableId,
              let index = chart.tables.firstIndex(where: { $0.id == selectedId }) else {
            return
        }

        let currentRotation = chart.tables[index].rotation
        let newRotation = (currentRotation + degrees).truncatingRemainder(dividingBy: 360)

        withAnimation(.easeInOut(duration: 0.2)) {
            chart.tables[index].rotation = newRotation
        }
    }

    private func deleteTable(_ tableId: UUID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            // Remove the table
            chart.tables.removeAll { $0.id == tableId }

            // Remove any seat assignments for this table
            chart.seatingAssignments.removeAll { $0.tableId == tableId }

            // Deselect if this was the selected table
            if selectedTableId == tableId {
                selectedTableId = nil
            }
        }
    }

    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.2)) {
            canvasScale = min(canvasScale * 1.2, maxScale)
        }
    }

    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.2)) {
            canvasScale = max(canvasScale / 1.2, minScale)
        }
    }

    private func resetView() {
        withAnimation(.easeInOut(duration: 0.3)) {
            canvasScale = 1.0
            canvasOffset = .zero
        }
    }

    private func handleDrop(providers: [NSItemProvider], location: CGPoint, in geometry: GeometryProxy) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { item, error in
            guard let data = item as? Data,
                  let guestIdString = String(data: data, encoding: .utf8),
                  let guestId = UUID(uuidString: guestIdString),
                  let guest = chart.guests.first(where: { $0.id == guestId }) else {
                return
            }

            // Convert drop location to canvas coordinates
            let canvasX = (location.x - geometry.size.width / 2 - canvasOffset.width) / canvasScale
            let canvasY = (location.y - geometry.size.height / 2 - canvasOffset.height) / canvasScale
            let dropPoint = CGPoint(x: canvasX, y: canvasY)

            // Find nearest table
            var nearestTable: Table?
            var nearestDistance: CGFloat = .infinity

            for table in chart.tables {
                let distance = GeometryHelpers.distance(from: dropPoint, to: table.position)
                if distance < nearestDistance && distance < 150 { // Within 150 points
                    nearestDistance = distance
                    nearestTable = table
                }
            }

            DispatchQueue.main.async {
                if let table = nearestTable {
                    // Find first empty seat
                    let assignedSeats = chart.seatingAssignments
                        .filter { $0.tableId == table.id }
                        .compactMap { $0.seatNumber }
                    let emptySeat = (0..<table.capacity).first { !assignedSeats.contains($0) }

                    onGuestDrop(guest, table.id, emptySeat)
                } else {
                    // Drop on empty canvas - unassign
                    onGuestDrop(guest, nil, nil)
                }
            }
        }

        return true
    }
}
