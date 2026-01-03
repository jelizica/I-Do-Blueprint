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
                .foregroundColor(SemanticColors.textPrimary)
                .padding(.bottom, Spacing.sm)

            Divider()

            HStack(spacing: Spacing.lg) {
                DashboardV4QuickActionButton(
                    icon: "envelope.fill",
                    title: "Send Invites",
                    color: QuickActions.guest
                )

                DashboardV4QuickActionButton(
                    icon: "calendar.badge.plus",
                    title: "Add Event",
                    color: QuickActions.event
                )

                DashboardV4QuickActionButton(
                    icon: "dollarsign.circle.fill",
                    title: "Update Budget",
                    color: QuickActions.budget
                )

                DashboardV4QuickActionButton(
                    icon: "person.badge.plus",
                    title: "Find Vendors",
                    color: QuickActions.vendor
                )
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(SemanticColors.backgroundSecondary)
        .shadow(color: SemanticColors.shadowLight, radius: 2, x: 0, y: 1)
        .cornerRadius(CornerRadius.md)
    }
}
