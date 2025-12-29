//
//  DashboardTaskRow.swift
//  I Do Blueprint
//
//  Extracted from DashboardViewV4.swift
//  Row component displaying a single task with status and due date
//

import SwiftUI

struct DashboardTaskRow: View {
    let task: WeddingTask
    let userTimezone: TimeZone

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.status == .completed ? AppColors.success : AppColors.textSecondary)

            Text(task.taskName)
                .font(Typography.caption)
                .foregroundColor(task.status == .completed ? AppColors.textSecondary : AppColors.textPrimary)
                .strikethrough(task.status == .completed)

            Spacer()

            if let dueDate = task.dueDate {
                Text(dueDateText(dueDate))
                    .font(Typography.caption)
                    .foregroundColor(dueDateColor(dueDate))
            }
        }
    }

    private func dueDateText(_ date: Date) -> String {
        // Use injected timezone for relative date calculations
        var calendar = Calendar.current
        calendar.timeZone = userTimezone
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Due today"
        } else if calendar.isDateInTomorrow(date) {
            return "Due tomorrow"
        } else {
            let days = DateFormatting.daysBetween(from: now, to: date, in: userTimezone)
            if days > 0 {
                return "Due in \(days) days"
            } else {
                return "Overdue"
            }
        }
    }

    private func dueDateColor(_ date: Date) -> Color {
        // Use injected timezone for day calculations
        let days = DateFormatting.daysBetween(from: Date(), to: date, in: userTimezone)

        if days < 0 {
            return AppColors.error
        } else if days <= 1 {
            return AppColors.warning
        } else {
            return AppColors.textSecondary
        }
    }
}
