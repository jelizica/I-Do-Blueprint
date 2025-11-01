//
//  MoodBoardLeftToolbar.swift
//  My Wedding Planning App
//
//  Left toolbar for mood board editor
//

import SwiftUI

struct MoodBoardLeftToolbar: View {
    @Binding var selectedTool: EditorTool
    @Binding var showingFilters: Bool

    let onAddImage: () -> Void
    let onAddColorSwatch: () -> Void
    let onAddText: () -> Void
    let onAddInspiration: () -> Void
    let onAutoArrange: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Tool selection
            VStack(spacing: 8) {
                Text("Tools")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 4) {
                    ForEach(EditorTool.allCases, id: \.self) { tool in
                        Button(action: {
                            selectedTool = tool
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: tool.icon)
                                    .font(.title3)

                                Text(tool.title)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(selectedTool == tool ? Color.blue.opacity(0.2) : Color.clear)
                            .foregroundColor(selectedTool == tool ? .blue : .primary)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            Divider()
                .padding(.vertical)

            // Quick actions
            VStack(spacing: 8) {
                Text("Quick Actions")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 4) {
                    EditorQuickActionButton(
                        icon: "photo.badge.plus",
                        title: "Add Image",
                        action: onAddImage)

                    EditorQuickActionButton(
                        icon: "paintpalette",
                        title: "Add Color",
                        action: onAddColorSwatch)

                    EditorQuickActionButton(
                        icon: "textformat",
                        title: "Add Text",
                        action: onAddText)

                    EditorQuickActionButton(
                        icon: "lightbulb",
                        title: "Add Note",
                        action: onAddInspiration)

                    EditorQuickActionButton(
                        icon: "rectangle.3.group",
                        title: "Arrange",
                        action: onAutoArrange)

                    EditorQuickActionButton(
                        icon: "slider.horizontal.3",
                        title: "Filters",
                        action: { showingFilters.toggle() })
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .frame(width: 180)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Editor Quick Action Button

private struct EditorQuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)

                Text(title)
                    .font(.caption)

                Spacer()
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.sm)
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
