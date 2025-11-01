//
//  MoodBoardRow.swift
//  I Do Blueprint
//
//  List row view component for mood board list
//

import SwiftUI

// MARK: - Mood Board List Row View

struct MoodBoardListRowView: View {
    let moodBoard: MoodBoard
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail preview
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                moodBoard.backgroundColor.opacity(0.4),
                                moodBoard.backgroundColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                    .frame(width: 120, height: 80)

                if !moodBoard.elements.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(moodBoard.elements.prefix(2)) { element in
                            MoodBoardElementPreview(element: element)
                                .frame(width: 56, height: 76)
                        }
                    }
                    .padding(Spacing.xxs)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(moodBoard.boardName)
                        .font(.headline)
                        .fontWeight(.semibold)

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
                        .lineLimit(1)
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
            }

            // Quick actions on hover
            if isHovering {
                HStack(spacing: 8) {
                    MoodBoardQuickActionButton(icon: "pencil", color: .blue)
                    MoodBoardQuickActionButton(icon: "doc.on.doc", color: .green)
                    MoodBoardQuickActionButton(icon: "trash", color: .red)
                }
                .transition(.opacity.combined(with: .scale))
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
        .scaleEffect(isHovering ? 1.005 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}
