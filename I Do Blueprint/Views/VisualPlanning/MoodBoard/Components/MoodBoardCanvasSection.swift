//
//  MoodBoardCanvasSection.swift
//  My Wedding Planning App
//
//  Canvas section for mood board editor
//

import SwiftUI

struct MoodBoardCanvasSection: View {
    @Binding var editableMoodBoard: MoodBoard
    @Binding var selectedElementId: UUID?

    let selectedTool: EditorTool
    let canvasScale: CGFloat
    let canvasOffset: CGPoint
    let onElementChanged: (VisualElement) -> Void
    let onCanvasChanged: (MoodBoard) -> Void
    let onPanGesture: (CGSize) -> Void
    let onZoomGesture: (CGFloat) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                editableMoodBoard.backgroundColor

                // Grid overlay (optional)
                if selectedTool == .grid {
                    GridOverlay(gridSize: 20, showGrid: true, canvasSize: geometry.size, scale: canvasScale)
                        .opacity(0.3)
                }

                // Enhanced canvas view
                EnhancedMoodBoardCanvasView(
                    moodBoard: $editableMoodBoard,
                    selectedElementId: $selectedElementId,
                    selectedTool: selectedTool,
                    canvasScale: canvasScale,
                    canvasOffset: canvasOffset,
                    onElementChanged: onElementChanged,
                    onCanvasChanged: onCanvasChanged)
                    .scaleEffect(canvasScale)
                    .offset(x: canvasOffset.x, y: canvasOffset.y)
            }
            .clipped()
            .gesture(
                SimultaneousGesture(
                    // Pan gesture for canvas
                    DragGesture()
                        .onChanged { value in
                            if selectedTool == .pan {
                                onPanGesture(value.translation)
                            }
                        },
                    // Zoom gesture
                    MagnificationGesture()
                        .onChanged { value in
                            onZoomGesture(value)
                        }))
        }
    }
}
