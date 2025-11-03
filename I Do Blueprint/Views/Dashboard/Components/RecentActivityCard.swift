//
//  RecentActivityCard.swift
//  I Do Blueprint
//
//  Recent activity feed with icons
//

import SwiftUI

struct RecentActivityCard: View {
    @ObservedObject var budgetStore: BudgetStoreV2
    @ObservedObject var guestStore: GuestStoreV2
    @ObservedObject var taskStore: TaskStoreV2

    struct Activity: Identifiable {
        let id = UUID()
        let icon: String
        let text: String
        let time: String
        let color: Color
    }

    private var activities: [Activity] {
        var items: [Activity] = []

        // Recent expenses
        if let recentExpense = budgetStore.expenses.first {
            items.append(Activity(
                icon: "checkmark.circle.fill",
                text: "Expense added: \(recentExpense.expenseName)",
                time: timeAgo(recentExpense.createdAt),
                color: .green
            ))
        }

        // Recent RSVPs
        let recentRSVPs = guestStore.guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }
        if !recentRSVPs.isEmpty {
            items.append(Activity(
                icon: "person.2.fill",
                text: "\(recentRSVPs.count) new RSVPs received",
                time: "Today",
                color: .blue
            ))
        }

        // Recent tasks
        let completedTasks = taskStore.tasks.filter { $0.status == .completed }
        if let recentTask = completedTasks.first {
            items.append(Activity(
                icon: "checkmark.circle.fill",
                text: "Task completed: \(recentTask.taskName)",
                time: timeAgo(recentTask.createdAt),
                color: .purple
            ))
        }

        // Placeholder activities if needed
        if items.isEmpty {
            items = [
                Activity(icon: "checkmark.circle.fill", text: "Venue deposit paid", time: "2 hours ago", color: .green),
                Activity(icon: "person.2.fill", text: "15 new RSVPs received", time: "5 hours ago", color: .blue),
                Activity(icon: "camera.fill", text: "Photographer contract signed", time: "1 day ago", color: .purple),
                Activity(icon: "fork.knife", text: "Cake tasting scheduled", time: "2 days ago", color: .orange)
            ]
        }

        return Array(items.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 20))
                    .foregroundColor(Color.fromHex( "A855F7"))

                Text("Recent Activity")
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()
            }

            // Activity List
            VStack(spacing: Spacing.md) {
                ForEach(activities) { activity in
                    DashboardActivityRow(activity: activity)

                    if activity.id != activities.last?.id {
                        Divider()
                    }
                }
            }

            Spacer()

            // Quick Actions
            VStack(spacing: Spacing.sm) {
                Text("Quick Actions")
                    .font(Typography.bodyRegular)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                QuickActionButton(icon: "plus", text: "Add New Task")
                QuickActionButton(icon: "envelope", text: "Send Reminder")
                QuickActionButton(icon: "phone", text: "Contact Vendor")

                Button {
                    // View full report
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))

                        Text("View Full Report")
                            .font(Typography.bodySmall)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        LinearGradient(
                            colors: [Color.fromHex( "EC4899"), Color.fromHex( "A855F7")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(AppColors.textPrimary)
                    .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.textPrimary.opacity(0.6))
                .shadow(color: AppColors.shadowLight, radius: 8, y: 4)
        )
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
}

struct DashboardActivityRow: View {
    let activity: RecentActivityCard.Activity

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: activity.icon)
                .font(.system(size: 16))
                .foregroundColor(activity.color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(activity.text)
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)

                Text(activity.time)
                    .font(Typography.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let text: String

    var body: some View {
        Button {
            // Handle action
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))

                Text(text)
                    .font(Typography.bodySmall)

                Spacer()
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(AppColors.textPrimary.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(AppColors.borderLight, lineWidth: 1)
                    )
            )
            .foregroundColor(AppColors.textPrimary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RecentActivityCard(
        budgetStore: BudgetStoreV2(),
        guestStore: GuestStoreV2(),
        taskStore: TaskStoreV2()
    )
    .frame(width: 350, height: 700)
    .padding()
}
