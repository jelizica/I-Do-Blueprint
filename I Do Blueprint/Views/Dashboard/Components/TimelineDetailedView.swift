//
//  TimelineDetailedView.swift
//  I Do Blueprint
//
//  Detailed timeline view with all items
//

import SwiftUI

struct TimelineDetailedView: View {
    @ObservedObject var store: TimelineStoreV2

    private var sortedItems: [TimelineItem] {
        store.timelineItems.sorted { $0.itemDate < $1.itemDate }
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Summary Cards
            HStack(spacing: Spacing.md) {
                DashboardSummaryCard(
                    title: "Total Items",
                    value: "\(store.timelineItems.count)",
                    icon: "calendar",
                    color: .purple
                )

                DashboardSummaryCard(
                    title: "Completed",
                    value: "\(store.timelineItems.filter { $0.completed }.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                DashboardSummaryCard(
                    title: "Upcoming",
                    value: "\(store.timelineItems.filter { !$0.completed && $0.itemDate >= Date() }.count)",
                    icon: "clock.fill",
                    color: .blue
                )
            }

            // Timeline Items
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Timeline")
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)

                ForEach(sortedItems) { item in
                    DashboardTimelineItemRow(item: item)
                }
            }
            .padding(Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(AppColors.textPrimary.opacity(0.6))
                    .shadow(color: AppColors.shadowLight, radius: 8, y: 4)
            )
        }
    }
}

struct DashboardTimelineItemRow: View {
    let item: TimelineItem

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Date indicator
            VStack(spacing: Spacing.xxs) {
                Text(monthDay)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(item.completed ? AppColors.success : AppColors.textPrimary)

                Text(year)
                    .font(Typography.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(width: 60)

            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(item.title)
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    if item.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                    }
                }

                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                HStack(spacing: Spacing.xs) {
                    Image(systemName: typeIcon)
                        .font(.system(size: 10))
                    Text(typeText)
                }
                .font(Typography.caption2)
                .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(AppColors.textPrimary.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(item.completed ? AppColors.success.opacity(0.3) : AppColors.borderLight, lineWidth: 1)
                )
        )
    }

    private var monthDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: item.itemDate)
    }

    private var year: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: item.itemDate)
    }

    private var typeIcon: String {
        switch item.itemType {
        case .milestone: return "flag.fill"
        case .task: return "checkmark.circle"
        case .vendorEvent: return "calendar"
        case .reminder: return "bell"
        case .payment: return "dollarsign.circle"
        @unknown default: return "circle"
        }
    }

    private var typeText: String {
        switch item.itemType {
        case .milestone: return "Milestone"
        case .task: return "Task"
        case .vendorEvent: return "Vendor Event"
        case .reminder: return "Reminder"
        case .payment: return "Payment"
        @unknown default: return "Item"
        }
    }
}

#Preview {
    TimelineDetailedView(store: TimelineStoreV2())
        .padding()
        .frame(width: 800)
}
