//
//  MoodBoardComponents.swift
//  I Do Blueprint
//
//  Supporting components for mood board list view
//

import SwiftUI

// MARK: - Mood Board Quick Action Button

struct MoodBoardQuickActionButton: View {
    let icon: String
    let color: Color
    @State private var isHovering = false

    var body: some View {
        Button(action: {
            // Action will be handled by parent
        }) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(SemanticColors.textPrimary)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.3), radius: isHovering ? 6 : 3, x: 0, y: 2))
                .scaleEffect(isHovering ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Mood Board Element Preview

struct MoodBoardElementPreview: View {
    let element: VisualElement
    @State private var isLoaded = false

    var body: some View {
        Group {
            switch element.elementType {
            case .color:
                // Color swatch preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(element.elementData.color ?? .gray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(SemanticColors.textPrimary.opacity(Opacity.light), lineWidth: 1))

            case .image:
                // Image preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.blue.opacity(0.5)))

            case .text:
                // Text preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.purple.opacity(0.1))
                    .overlay(
                        Text(element.elementData.text?.prefix(20) ?? "Text")
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .padding(Spacing.xs))

            case .inspiration:
                // Inspiration note preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.yellow.opacity(0.2))
                    .overlay(
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow.opacity(0.7)))
            }
        }
        .frame(height: 80)
        .opacity(isLoaded ? 1.0 : 0)
        .scaleEffect(isLoaded ? 1.0 : 0.8)
        .animation(.easeOut(duration: 0.3), value: isLoaded)
        .onAppear {
            withAnimation {
                isLoaded = true
            }
        }
    }
}

// MARK: - Filter Chip Component

struct MoodBoardFilterChip: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isActive ? .semibold : .regular)
                .foregroundColor(isActive ? .white : .primary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule()
                        .fill(isActive ? Color.blue : Color(NSColor.controlBackgroundColor)))
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color.clear : SemanticColors.textSecondary.opacity(Opacity.light), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty Mood Board View

struct EmptyMoodBoardView: View {
    @EnvironmentObject var visualPlanningStore: VisualPlanningStoreV2

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("No Mood Boards Yet")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create your first mood board to start visualizing your wedding style")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.huge)
            }

            Button(action: {
                visualPlanningStore.showingMoodBoardCreator = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create Your First Mood Board")
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(Color.blue)
                .foregroundColor(SemanticColors.textPrimary)
                .cornerRadius(10)
            }

            Spacer()
        }
    }
}
