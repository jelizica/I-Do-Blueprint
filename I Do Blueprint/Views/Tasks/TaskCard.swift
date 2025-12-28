//
//  TaskCard.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct TaskCard: View {
    let task: WeddingTask
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Priority Badge & Due Date
                HStack {
                    priorityBadge

                    Spacer()

                    if let dueDate = task.dueDate {
                        dueDateBadge(dueDate)
                    }
                }

                // Task Name
                Text(task.taskName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                // Description
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Metadata Row
                HStack(spacing: 12) {
                    // Assigned To
                    if !task.assignedTo.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                            Text("\(task.assignedTo.count)")
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                    }

                    // Subtasks
                    if let subtasks = task.subtasks, !subtasks.isEmpty {
                        let completed = subtasks.filter { $0.status == .completed }.count
                        HStack(spacing: 4) {
                            Image(systemName: "checklist")
                                .font(.caption2)
                            Text("\(completed)/\(subtasks.count)")
                                .font(.caption2)
                        }
                        .foregroundColor(completed == subtasks.count ? .green : .orange)
                    }

                    // Cost Estimate
                    if let cost = task.costEstimate, cost > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.caption2)
                            Text("$\(Int(cost))")
                                .font(.caption2)
                        }
                        .foregroundColor(.green)
                    }

                    Spacer()
                }

                // Tags Row
                if task.vendorId != nil || task.milestoneId != nil {
                    HStack(spacing: 6) {
                        if task.vendorId != nil {
                            tagView(icon: "person.2.fill", text: "Vendor", color: .purple)
                        }

                        if task.milestoneId != nil {
                            tagView(icon: "star.fill", text: "Milestone", color: .yellow)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
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
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }

    // MARK: - Computed Properties

    /// User's configured timezone - single source of truth for date operations
    private var userTimezone: TimeZone {
        DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
    }

    // MARK: - Priority Badge

    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)

            Text(task.priority.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            Capsule()
                .fill(priorityColor.opacity(0.15)))
        .foregroundColor(priorityColor)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .urgent: .red
        case .high: .orange
        case .medium: .blue
        case .low: .gray
        }
    }

    // MARK: - Due Date Badge

    private func dueDateBadge(_ date: Date) -> some View {
        // Use user's timezone for date calculations
        let daysUntil = DateFormatting.daysBetween(from: Date(), to: date, in: userTimezone)
        let isOverdue = daysUntil < 0 && task.status != .completed

        return HStack(spacing: 4) {
            Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar")
                .font(.caption2)

            Text(dueDateText(date, daysUntil: daysUntil, isOverdue: isOverdue, timezone: userTimezone))
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            Capsule()
                .fill(dueDateColor(isOverdue: isOverdue, daysUntil: daysUntil).opacity(0.15)))
        .foregroundColor(dueDateColor(isOverdue: isOverdue, daysUntil: daysUntil))
    }

    private func dueDateText(_ date: Date, daysUntil: Int, isOverdue: Bool, timezone: TimeZone) -> String {
        if isOverdue {
            return "Overdue"
        } else if daysUntil == 0 {
            return "Today"
        } else if daysUntil == 1 {
            return "Tomorrow"
        } else if daysUntil < 7 {
            return "\(daysUntil)d"
        } else {
            return DateFormatting.formatDate(date, format: "MMM d", timezone: timezone)
        }
    }

    private func dueDateColor(isOverdue: Bool, daysUntil: Int) -> Color {
        if isOverdue {
            .red
        } else if daysUntil <= 3 {
            .orange
        } else {
            .blue
        }
    }

    // MARK: - Tag View

    private func tagView(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule()
                .fill(color.opacity(0.15)))
        .foregroundColor(color)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        TaskCard(
            task: WeddingTask(
                id: UUID(),
                coupleId: UUID(),
                taskName: "Book Wedding Venue",
                description: "Visit and finalize the venue booking for the ceremony and reception",
                budgetCategoryId: nil,
                priority: .urgent,
                dueDate: Date().addingTimeInterval(-86400 * 2), // 2 days ago
                startDate: Date(),
                assignedTo: ["Partner 1", "Partner 2"],
                vendorId: 1,
                status: .inProgress,
                dependsOnTaskId: nil,
                estimatedHours: 4,
                costEstimate: 5000,
                notes: nil,
                milestoneId: UUID(),
                createdAt: Date(),
                updatedAt: Date(),
                subtasks: [
                    Subtask(
                        id: UUID(),
                        taskId: UUID(),
                        subtaskName: "Research venues",
                        status: .completed,
                        assignedTo: ["Partner 1"],
                        notes: nil,
                        createdAt: Date(),
                        updatedAt: Date()),
                    Subtask(
                        id: UUID(),
                        taskId: UUID(),
                        subtaskName: "Schedule tours",
                        status: .inProgress,
                        assignedTo: ["Partner 2"],
                        notes: nil,
                        createdAt: Date(),
                        updatedAt: Date())
                ],
                milestone: nil,
                vendor: nil,
                budgetCategory: nil),
            onTap: { print("Tapped") })

        TaskCard(
            task: WeddingTask(
                id: UUID(),
                coupleId: UUID(),
                taskName: "Send Invitations",
                description: "Design, print, and mail wedding invitations to all guests",
                budgetCategoryId: nil,
                priority: .high,
                dueDate: Date().addingTimeInterval(86400 * 7), // 7 days from now
                startDate: nil,
                assignedTo: ["Partner 1"],
                vendorId: nil,
                status: .notStarted,
                dependsOnTaskId: nil,
                estimatedHours: 8,
                costEstimate: 800,
                notes: nil,
                milestoneId: nil,
                createdAt: Date(),
                updatedAt: Date(),
                subtasks: nil,
                milestone: nil,
                vendor: nil,
                budgetCategory: nil),
            onTap: { print("Tapped") })
    }
    .padding()
    .frame(width: 320)
}
