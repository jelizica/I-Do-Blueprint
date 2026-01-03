//
//  TaskProgressCard.swift
//  I Do Blueprint
//
//  Task progress tracker with table view
//

import SwiftUI

struct TaskProgressCard: View {
    @ObservedObject var store: TaskStoreV2

    private var recentTasks: [WeddingTask] {
        Array(store.tasks.prefix(5))
    }

    var body: some View {
        // Compute timezone once for all task rows
        let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
        
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Task Tracker")
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text("Keep track of your wedding to-dos")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Spacer()
            }

            // Task Table
            VStack(spacing: 0) {
                // Header Row
                HStack {
                    Text("Task")
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(SemanticColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Status")
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(SemanticColors.textSecondary)
                        .frame(width: 100, alignment: .leading)

                    Text("Due Date")
                        .font(Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(SemanticColors.textSecondary)
                        .frame(width: 100, alignment: .leading)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(SemanticColors.backgroundSecondary)

                Divider()

                // Task Rows
                ForEach(recentTasks) { task in
                    TaskRow(task: task, userTimezone: userTimezone)

                    if task.id != recentTasks.last?.id {
                        Divider()
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(SemanticColors.textPrimary.opacity(Opacity.medium))
            )
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(SemanticColors.textPrimary.opacity(Opacity.medium))
                .shadow(color: SemanticColors.shadowLight, radius: 8, y: 4)
        )
    }
}

struct TaskRow: View {
    let task: WeddingTask
    let userTimezone: TimeZone

    var body: some View {
        HStack {
            Text(task.taskName)
                .font(Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(SemanticColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            TaskStatusBadge(status: task.status)
                .frame(width: 100, alignment: .leading)

            if let dueDate = task.dueDate {
                Text(formattedDate(dueDate))
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(width: 100, alignment: .leading)
            } else {
                Text("No date")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textTertiary)
                    .frame(width: 100, alignment: .leading)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }

    private func formattedDate(_ date: Date) -> String {
        // Note: Task due dates are stored as DATE (calendar dates) in the database,
        // not timestamps. The timezone is used only for formatting consistency with
        // the user's locale, not for timezone conversion of the actual date value.
        return DateFormatting.formatDate(date, format: "MMM d, yyyy", timezone: userTimezone)
    }
}

struct TaskStatusBadge: View {
    let status: TaskStatus

    var body: some View {
        Text(statusText)
            .font(Typography.caption2)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.1))
            )
    }

    private var statusText: String {
        switch status {
        case .notStarted: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .onHold: return "On Hold"
        case .cancelled: return "Cancelled"
        }
    }

    private var statusColor: Color {
        switch status {
        case .completed: return SemanticColors.success
        case .inProgress: return SemanticColors.info
        case .notStarted: return SemanticColors.textSecondary
        case .onHold: return SemanticColors.warning
        case .cancelled: return SemanticColors.error
        }
    }
}

#Preview {
    TaskProgressCard(store: TaskStoreV2())
        .frame(width: 600)
        .padding()
}
