//
//  TasksDetailedView.swift
//  I Do Blueprint
//
//  Detailed task view with priority filtering
//

import SwiftUI

struct TasksDetailedView: View {
    @ObservedObject var store: TaskStoreV2
    @State private var selectedFilter: TaskFilter = .all

    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case urgent = "Urgent"
        case high = "High Priority"
        case inProgress = "In Progress"
        case completed = "Completed"
    }

    private var filteredTasks: [WeddingTask] {
        switch selectedFilter {
        case .all:
            return store.tasks
        case .urgent:
            return store.tasks.filter { $0.priority == .urgent }
        case .high:
            return store.tasks.filter { $0.priority == .high }
        case .inProgress:
            return store.tasks.filter { $0.status == .inProgress }
        case .completed:
            return store.tasks.filter { $0.status == .completed }
        }
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Summary Cards
            HStack(spacing: Spacing.md) {
                DashboardSummaryCard(
                    title: "Total Tasks",
                    value: "\(store.tasks.count)",
                    icon: "list.bullet",
                    color: .blue
                )

                DashboardSummaryCard(
                    title: "Completed",
                    value: "\(store.tasks.filter { $0.status == .completed }.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                DashboardSummaryCard(
                    title: "In Progress",
                    value: "\(store.tasks.filter { $0.status == .inProgress }.count)",
                    icon: "arrow.clockwise",
                    color: .orange
                )

                DashboardSummaryCard(
                    title: "Urgent",
                    value: "\(store.tasks.filter { $0.priority == .urgent }.count)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }

            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            // Task List
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("\(filteredTasks.count) Tasks")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                ForEach(filteredTasks) { task in
                    TaskDetailRow(task: task)

                    if task.id != filteredTasks.last?.id {
                        Divider()
                    }
                }
            }
            .padding(Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(SemanticColors.textPrimary.opacity(Opacity.medium))
                    .shadow(color: SemanticColors.shadowLight, radius: 8, y: 4)
            )
        }
    }
}

struct TaskDetailRow: View {
    let task: WeddingTask

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 12, height: 12)
                .padding(.top, Spacing.xs)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(task.taskName)
                    .font(Typography.bodyRegular)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)

                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                        .lineLimit(2)
                }

                HStack(spacing: Spacing.sm) {
                    TaskPriorityBadge(priority: task.priority)
                    TaskStatusBadge(status: task.status)

                    if let dueDate = task.dueDate {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(formattedDate(dueDate))
                        }
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, Spacing.sm)
    }

    private var priorityColor: Color {
        switch task.priority {
        case .urgent: return SemanticColors.error
        case .high: return SemanticColors.warning
        case .medium: return SemanticColors.info
        case .low: return SemanticColors.textSecondary
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct TaskPriorityBadge: View {
    let priority: WeddingTaskPriority

    var body: some View {
        Text(priorityText)
            .font(Typography.caption2)
            .fontWeight(.medium)
            .foregroundColor(priorityColor)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(priorityColor.opacity(0.1))
            )
    }

    private var priorityText: String {
        switch priority {
        case .urgent: return "Urgent"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }

    private var priorityColor: Color {
        switch priority {
        case .urgent: return SemanticColors.error
        case .high: return SemanticColors.warning
        case .medium: return SemanticColors.info
        case .low: return SemanticColors.textSecondary
        }
    }
}

#Preview {
    TasksDetailedView(store: TaskStoreV2())
        .padding()
        .frame(width: 1000)
}
