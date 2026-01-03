//
//  SeatingChartCanvas.swift
//  I Do Blueprint
//
//  Canvas component for seating chart editor with drag & drop functionality
//

import SwiftUI

struct SeatingChartCanvas: View {
    @Binding var editableChart: SeatingChart
    @Binding var selectedTableId: UUID?
    @Binding var editingTableId: UUID?
    @Binding var showingTableEditor: Bool
    @Binding var canvasScale: CGFloat
    @Binding var canvasOffset: CGPoint
    @Binding var isDraggingTable: Bool
    @Binding var dragStartPosition: CGPoint
    @Binding var draggingTableId: UUID?

    let updateTablePositionWithTranslation: (UUID, CGPoint, CGSize) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                SemanticColors.textPrimary

                // Grid overlay
                if editableChart.layoutSettings.snapToGrid {
                    GridOverlay(
                        gridSize: editableChart.layoutSettings.gridSize,
                        showGrid: true,
                        canvasSize: geometry.size,
                        scale: canvasScale)
                }

                // Render tables on canvas
                ForEach(editableChart.tables, id: \.id) { table in
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
                        .id(table.id)
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
                                                dragStartPosition,
                                                value.translation)
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
                            .padding(Spacing.lg)
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
}

#Preview {
    let sampleChart = SeatingChart(
        tenantId: "sample",
        chartName: "Wedding Reception",
        eventId: nil)

    SeatingChartCanvas(
        editableChart: .constant(sampleChart),
        selectedTableId: .constant(nil),
        editingTableId: .constant(nil),
        showingTableEditor: .constant(false),
        canvasScale: .constant(1.0),
        canvasOffset: .constant(.zero),
        isDraggingTable: .constant(false),
        dragStartPosition: .constant(.zero),
        draggingTableId: .constant(nil),
        updateTablePositionWithTranslation: { _, _, _ in }
    )
}
