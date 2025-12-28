//
//  MilestoneCard.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct MilestoneCard: View {
    let milestone: Milestone
    let onTap: () -> Void
    let onToggleCompletion: () -> Void

    @State private var isHovered = false

    private var milestoneColor: Color {
        if let colorString = milestone.color {
            switch colorString.lowercased() {
            case "red": return .red
            case "orange": return .orange
            case "yellow": return .yellow
            case "green": return .green
            case "blue": return .blue
            case "purple": return .purple
            case "pink": return .pink
            default: return .blue
            }
        }
        return .blue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with completion toggle
            HStack {
                Button(action: onToggleCompletion) {
                    Image(systemName: milestone.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(milestone.completed ? .green : .gray)
                }
                .buttonStyle(.plain)

                Spacer()

                Image(systemName: "star.fill")
                    .foregroundColor(milestoneColor)
            }

            // Milestone Name
            Text(milestone.milestoneName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)

            // Description
            if let description = milestone.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Date
            HStack {
                Image(systemName: "calendar")
                    .font(.caption2)

                Text(formatDate(milestone.milestoneDate))
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                // Days until/since
                if let daysText = daysUntilText() {
                    Text(daysText)
                        .font(.caption2)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(milestoneColor.opacity(0.15)))
                        .foregroundColor(milestoneColor)
                }
            }
            .foregroundColor(.secondary)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: isHovered ? milestoneColor.opacity(0.3) : .black.opacity(0.05),
                    radius: isHovered ? 8 : 4,
                    x: 0,
                    y: isHovered ? 4 : 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    milestone.completed ? Color.green.opacity(0.3) : milestoneColor.opacity(0.3),
                    lineWidth: 2))
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }

    /// User's configured timezone - single source of truth for all date operations
    private var userTimeZone: TimeZone {
        DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
    }

    private func formatDate(_ date: Date) -> String {
        // Use user's timezone for date formatting
        return DateFormatting.formatDate(date, format: "MMM d, yyyy", timezone: userTimeZone)
    }

    private func daysUntilText() -> String? {
        // Use user's timezone for day calculations
        let days = DateFormatting.daysBetween(from: Date(), to: milestone.milestoneDate, in: userTimeZone)

        if milestone.completed {
            return "Completed"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days < 0 {
            return "\(abs(days))d ago"
        } else {
            return "In \(days)d"
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        MilestoneCard(
            milestone: Milestone(
                id: UUID(),
                coupleId: UUID(),
                milestoneName: "Venue Booking Deadline",
                description: "Final date to confirm venue booking and deposit",
                milestoneDate: Date().addingTimeInterval(86400 * 30),
                completed: false,
                color: "purple",
                createdAt: Date(),
                updatedAt: Date()),
            onTap: {},
            onToggleCompletion: {})
            .frame(width: 280)

        MilestoneCard(
            milestone: Milestone(
                id: UUID(),
                coupleId: UUID(),
                milestoneName: "Send Invitations",
                description: "All wedding invitations mailed",
                milestoneDate: Date().addingTimeInterval(86400 * 60),
                completed: true,
                color: "green",
                createdAt: Date(),
                updatedAt: Date()),
            onTap: {},
            onToggleCompletion: {})
            .frame(width: 280)
    }
    .padding()
}
