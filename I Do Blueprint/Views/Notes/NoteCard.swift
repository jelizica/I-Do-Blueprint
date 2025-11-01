//
//  NoteCard.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import MarkdownUI
import SwiftUI

struct NoteCard: View {
    let note: Note
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var showingDeleteConfirmation = false

    private var typeConfig: (icon: String, color: Color)? {
        guard let type = note.relatedType else { return nil }

        switch type {
        case .vendor:
            return ("person.2.fill", .purple)
        case .guest:
            return ("person.fill", .blue)
        case .task:
            return ("checklist", .orange)
        case .milestone:
            return ("star.fill", .yellow)
        case .budget:
            return ("dollarsign.circle.fill", .green)
        case .visualElement:
            return ("paintpalette.fill", .pink)
        case .payment:
            return ("creditcard.fill", .teal)
        case .document:
            return ("doc.fill", .indigo)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with type badge
            HStack {
                if let config = typeConfig {
                    HStack(spacing: 4) {
                        Image(systemName: config.icon)
                            .font(.caption2)
                        Text(note.relatedType?.displayName ?? "")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(config.color.opacity(0.15)))
                    .foregroundColor(config.color)
                }

                Spacer()

                // Delete button (shows on hover)
                if isHovered {
                    Button(action: { showingDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Title
            if let title = note.title, !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            // Content Preview (Markdown Rendered) - Fixed Height
            VStack(alignment: .leading, spacing: 0) {
                Markdown(note.content)
                    .markdownTheme(.gitHub)
                    .markdownTextStyle(\.text) {
                        FontSize(11)
                        ForegroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 60, alignment: .top)
            .clipped()

            Spacer()

            // Footer with timestamp
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(formatDate(note.updatedAt))
                    .font(.caption2)

                Spacer()

                // Character count
                Text("\(note.content.count) chars")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.secondary)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: isHovered ? .blue.opacity(0.2) : .black.opacity(0.05),
                    radius: isHovered ? 8 : 4,
                    x: 0,
                    y: isHovered ? 4 : 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1))
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .alert("Delete Note", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        NoteCard(
            note: Note(
                id: UUID(),
                coupleId: UUID(),
                title: "Venue Options",
                content: "Looking at three potential venues:\n1. Garden Estate - beautiful outdoor space\n2. Historic Mansion - elegant indoor setting\n3. Beach Resort - stunning ocean views\n\nNeed to schedule site visits for next month.",
                relatedType: .vendor,
                relatedId: nil,
                createdAt: Date().addingTimeInterval(-86400 * 2),
                updatedAt: Date().addingTimeInterval(-3600)),
            onTap: {},
            onDelete: {})
            .frame(width: 350)

        NoteCard(
            note: Note(
                id: UUID(),
                coupleId: UUID(),
                title: nil,
                content: "Remember to follow up with the florist about seasonal flower availability for late spring ceremony.",
                relatedType: nil,
                relatedId: nil,
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-86400)),
            onTap: {},
            onDelete: {})
            .frame(width: 350)
    }
    .padding()
}
