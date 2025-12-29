//
//  TaskProgressCardV4.swift
//  I Do Blueprint
//
//  Extracted from DashboardViewV4.swift
//  Task progress card showing remaining tasks and recent task list
//

import SwiftUI

struct TaskProgressCardV4: View {
    @ObservedObject var store: TaskStoreV2
    let userTimezone: TimeZone

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Task Manager")
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)

                Text("\(remainingTasks) tasks remaining")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.bottom, Spacing.sm)

            Divider()

            // Recent Tasks
            VStack(spacing: Spacing.md) {
                ForEach(store.tasks.prefix(5)) { task in
                    DashboardTaskRow(task: task, userTimezone: userTimezone)
                }
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 347)
        .background(AppColors.cardBackground)
        .shadow(color: AppColors.shadowLight, radius: 2, x: 0, y: 1)
        .cornerRadius(CornerRadius.md)
    }

    private var remainingTasks: Int {
        store.tasks.filter { $0.status != .completed }.count
    }
}
