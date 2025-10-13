//
//  TimelineItemRow.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct TimelineItemRow: View {
    let item: TimelineItem
    let onTap: () -> Void
    let onToggleCompletion: () -> Void

    @State private var isHovered = false

    private var typeConfig: (icon: String, color: Color) {
        switch item.itemType {
        case .task:
            ("checklist", .blue)
        case .milestone:
            ("star.fill", .purple)
        case .vendorEvent:
            ("person.2.fill", .orange)
        case .payment:
            ("dollarsign.circle.fill", .green)
        case .reminder:
            ("bell.fill", .red)
        case .other:
            ("circle.fill", .gray)
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Completion Checkbox
            Button(action: onToggleCompletion) {
                Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.completed ? .green : .gray)
            }
            .buttonStyle(.plain)

            // Type Icon
            ZStack {
                Circle()
                    .fill(typeConfig.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: typeConfig.icon)
                    .font(.body)
                    .foregroundColor(typeConfig.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .strikethrough(item.completed)

                    Spacer()

                    // Date
                    Text(formatDate(item.itemDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Type Badge
                HStack(spacing: 4) {
                    Image(systemName: typeConfig.icon)
                        .font(.caption2)
                    Text(item.itemType.displayName)
                        .font(.caption2)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(typeConfig.color.opacity(0.15)))
                .foregroundColor(typeConfig.color)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: isHovered ? typeConfig.color.opacity(0.2) : .black.opacity(0.05),
                    radius: isHovered ? 6 : 3,
                    x: 0,
                    y: isHovered ? 3 : 1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    item.completed ? Color.green.opacity(0.3) : Color.clear,
                    lineWidth: 1))
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(timelineAccessibilityLabel)
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(item.completed ? [.isButton] : [.isButton])
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private var timelineAccessibilityLabel: String {
        let dateString = item.itemDate.formatted(date: .long, time: .omitted)
        let status = item.completed ? "Completed" : "Upcoming"
        var components = [item.title, item.itemType.displayName, dateString, status]

        if let description = item.description, !description.isEmpty {
            components.append(description)
        }

        return components.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        TimelineItemRow(
            item: TimelineItem(
                id: UUID(),
                coupleId: UUID(),
                title: "Book Wedding Photographer",
                description: "Schedule meetings with top 3 photographers",
                itemType: .task,
                itemDate: Date().addingTimeInterval(86400 * 14),
                endDate: nil,
                completed: false,
                relatedId: nil,
                createdAt: Date(),
                updatedAt: Date(),
                task: nil,
                milestone: nil,
                vendor: nil,
                payment: nil),
            onTap: {},
            onToggleCompletion: {})

        TimelineItemRow(
            item: TimelineItem(
                id: UUID(),
                coupleId: UUID(),
                title: "Final Payment to Caterer",
                description: "$5,000 final payment due",
                itemType: .payment,
                itemDate: Date().addingTimeInterval(86400 * 7),
                endDate: nil,
                completed: true,
                relatedId: nil,
                createdAt: Date(),
                updatedAt: Date(),
                task: nil,
                milestone: nil,
                vendor: nil,
                payment: nil),
            onTap: {},
            onToggleCompletion: {})

        TimelineItemRow(
            item: TimelineItem(
                id: UUID(),
                coupleId: UUID(),
                title: "Cake Tasting Appointment",
                description: "Meeting with Sweet Treats Bakery at 2 PM",
                itemType: .vendorEvent,
                itemDate: Date().addingTimeInterval(86400 * 21),
                endDate: nil,
                completed: false,
                relatedId: nil,
                createdAt: Date(),
                updatedAt: Date(),
                task: nil,
                milestone: nil,
                vendor: nil,
                payment: nil),
            onTap: {},
            onToggleCompletion: {})
    }
    .padding()
    .frame(width: 700)
}
