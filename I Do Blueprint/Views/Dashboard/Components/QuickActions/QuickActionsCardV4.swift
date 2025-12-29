//
//  QuickActionsCardV4.swift
//  I Do Blueprint
//
//  Extracted quick actions card for dashboard
//

import SwiftUI

struct QuickActionsCardV4: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Quick Actions")
                .font(Typography.subheading)
                .foregroundColor(AppColors.textPrimary)
                .padding(.bottom, Spacing.sm)

            Divider()

            HStack(spacing: Spacing.lg) {
                DashboardV4QuickActionButton(
                    icon: "envelope.fill",
                    title: "Send Invites",
                    color: AppColors.info
                )

                DashboardV4QuickActionButton(
                    icon: "calendar.badge.plus",
                    title: "Add Event",
                    color: AppColors.info
                )

                DashboardV4QuickActionButton(
                    icon: "dollarsign.circle.fill",
                    title: "Update Budget",
                    color: AppColors.success
                )

                DashboardV4QuickActionButton(
                    icon: "person.badge.plus",
                    title: "Find Vendors",
                    color: AppColors.info
                )
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .shadow(color: AppColors.shadowLight, radius: 2, x: 0, y: 1)
        .cornerRadius(CornerRadius.md)
    }
}
