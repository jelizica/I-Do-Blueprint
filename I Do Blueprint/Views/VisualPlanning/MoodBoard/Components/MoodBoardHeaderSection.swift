//
//  MoodBoardHeaderSection.swift
//  My Wedding Planning App
//
//  Header section for mood board editor
//

import SwiftUI

struct MoodBoardHeaderSection: View {
    @Binding var editableMoodBoard: MoodBoard
    @Binding var canvasScale: CGFloat
    @Binding var showingTemplates: Bool
    @Binding var showingExport: Bool

    let historyManager: MoodBoardHistoryManager
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onFit: () -> Void
    let onSave: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack {
            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(editableMoodBoard.boardName)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\(editableMoodBoard.elements.count) elements")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Main toolbar
            HStack(spacing: 8) {
                // History controls
                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!historyManager.canUndo)
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(action: onRedo) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(!historyManager.canRedo)
                .buttonStyle(.bordered)
                .controlSize(.small)

                Divider()
                    .frame(height: 20)

                // Canvas controls
                Button("Fit") {
                    onFit()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                HStack(spacing: 4) {
                    Button("-") {
                        canvasScale = max(0.25, canvasScale - 0.25)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Text("\(Int(canvasScale * 100))%")
                        .font(.system(.caption, design: .monospaced))
                        .frame(width: 50)

                    Button("+") {
                        canvasScale = min(4.0, canvasScale + 0.25)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Divider()
                    .frame(height: 20)

                // Advanced tools
                Button("Templates") {
                    showingTemplates = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Export") {
                    showingExport = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            HStack(spacing: 8) {
                Button("Save") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)

                Button("Close") {
                    onClose()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
