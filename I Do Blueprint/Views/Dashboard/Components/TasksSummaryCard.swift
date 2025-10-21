//
//  TasksSummaryCard.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct TasksSummaryCard: View {
    let metrics: TaskMetrics
    @State private var isHovered = false

    var body: some View {
        BaseSummaryCard(
            icon: "checklist",
            title: "Tasks",
            subtitle: "\(metrics.total) total",
            color: .blue,
            isHovered: $isHovered,
            hasAlert: metrics.overdue > 0) {
            VStack(spacing: 16) {
                CircularProgress(
                    value: metrics.completionRate / 100,
                    color: metrics.completionRate >= 75 ? .green : metrics.completionRate >= 50 ? .orange : .red,
                    lineWidth: 12,
                    size: 100,
                    showPercentage: true
                )

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    QuickStat(
                        icon: "exclamationmark.circle.fill",
                        label: "High Priority",
                        value: "\(metrics.highPriority + metrics.urgent)",
                        color: .red)

                    QuickStat(
                        icon: "calendar.badge.clock",
                        label: "Due This Week",
                        value: "\(metrics.dueThisWeek)",
                        color: .orange)
                }
            }
        }
    }
}

#Preview {
    TasksSummaryCard(
        metrics: TaskMetrics(
            total: 25,
            completed: 15,
            inProgress: 6,
            notStarted: 3,
            onHold: 1,
            cancelled: 0,
            overdue: 2,
            dueThisWeek: 5,
            highPriority: 3,
            urgent: 1,
            completionRate: 60,
            recentTasks: []))
        .padding()
        .frame(width: 400)
}
