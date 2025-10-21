//
//  RemindersSummaryCard.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct RemindersSummaryCard: View {
    let metrics: ReminderMetrics
    @State private var isHovered = false

    var body: some View {
        BaseSummaryCard(
            icon: "bell.fill",
            title: "Reminders",
            subtitle: "\(metrics.total) total",
            color: .orange,
            isHovered: $isHovered) {
            VStack(spacing: 16) {
                CircularProgress(
                    value: metrics.total > 0 ? Double(metrics.completed) / Double(metrics.total) : 0,
                    color: .orange,
                    lineWidth: 10,
                    size: 80,
                    showPercentage: true
                )

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    QuickStat(
                        icon: "calendar.badge.clock",
                        label: "Due Today",
                        value: "\(metrics.dueToday)",
                        color: .red)

                    QuickStat(
                        icon: "clock.fill",
                        label: "This Week",
                        value: "\(metrics.dueThisWeek)",
                        color: .orange)
                }
            }
        }
    }
}

#Preview {
    RemindersSummaryCard(
        metrics: ReminderMetrics(
            total: 12,
            active: 9,
            completed: 3,
            overdue: 1,
            dueToday: 2,
            dueThisWeek: 5,
            recentReminders: []))
        .padding()
        .frame(width: 350)
}
