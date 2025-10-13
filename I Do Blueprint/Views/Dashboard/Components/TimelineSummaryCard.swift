//
//  TimelineSummaryCard.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct TimelineSummaryCard: View {
    let metrics: TimelineMetrics
    @State private var isHovered = false

    var body: some View {
        BaseSummaryCard(
            icon: "calendar",
            title: "Timeline",
            subtitle: "\(metrics.totalItems) items",
            color: .purple,
            isHovered: $isHovered,
            hasAlert: metrics.overdueItems > 0) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickStat(
                    icon: "checkmark.circle.fill",
                    label: "Completed",
                    value: "\(metrics.completedItems)",
                    color: .green)

                QuickStat(
                    icon: "clock.fill",
                    label: "Upcoming",
                    value: "\(metrics.upcomingItems)",
                    color: .blue)

                QuickStat(
                    icon: "star.fill",
                    label: "Milestones",
                    value: "\(metrics.milestones)",
                    color: .yellow)

                QuickStat(
                    icon: "exclamationmark.circle.fill",
                    label: "Overdue",
                    value: "\(metrics.overdueItems)",
                    color: .red)
            }
        }
    }
}

#Preview {
    TimelineSummaryCard(
        metrics: TimelineMetrics(
            totalItems: 45,
            completedItems: 22,
            upcomingItems: 18,
            overdueItems: 5,
            milestones: 8,
            completedMilestones: 3,
            recentItems: []))
        .padding()
        .frame(width: 350)
}
