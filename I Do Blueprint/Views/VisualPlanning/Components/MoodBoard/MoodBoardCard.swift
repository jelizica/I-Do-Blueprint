//
//  MoodBoardCard.swift
//  I Do Blueprint
//
//  Card view component for mood board list
//

import SwiftUI

// MARK: - Mood Board Card View

struct MoodBoardCardView: View {
    let moodBoard: MoodBoard
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Preview/Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                moodBoard.backgroundColor.opacity(0.4),
                                moodBoard.backgroundColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(moodBoard.backgroundColor.opacity(0.3), lineWidth: 1))

                if !moodBoard.elements.isEmpty {
                    // 2x2 grid preview of elements
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(moodBoard.elements.prefix(4)) { element in
                            MoodBoardElementPreview(element: element)
                        }
                    }
                    .padding(Spacing.lg)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Empty Board")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Quick actions overlay on hover
                if isHovering {
                    HStack(spacing: 12) {
                        Spacer()

                        VStack(spacing: 8) {
                            MoodBoardQuickActionButton(icon: "pencil", color: .blue)
                            MoodBoardQuickActionButton(icon: "doc.on.doc", color: .green)
                            MoodBoardQuickActionButton(icon: "trash", color: .red)
                        }
                        .padding(Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial))
                    }
                    .padding(Spacing.sm)
                    .transition(.opacity.combined(with: .scale))
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(moodBoard.boardName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: moodBoard.styleCategory.iconName)
                            .foregroundColor(.blue)
                        Text(moodBoard.styleCategory.displayName)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }

                if let description = moodBoard.boardDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Label("\(moodBoard.elements.count) elements", systemImage: "square.stack.3d.up")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(moodBoard.updatedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Tags
                if !moodBoard.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(moodBoard.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.12)))
                                .foregroundColor(.blue)
                        }
                        if moodBoard.tags.count > 3 {
                            Text("+\(moodBoard.tags.count - 3)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: .black.opacity(isHovering ? 0.12 : 0.06),
                    radius: isHovering ? 8 : 4,
                    x: 0,
                    y: isHovering ? 4 : 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.textSecondary.opacity(isHovering ? 0.3 : 0.15), lineWidth: 1))
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}
