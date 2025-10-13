//
//  ModernGuestStatsView.swift
//  My Wedding Planning App
//
//  Extracted from GuestListViewV2.swift
//

import SwiftUI

struct ModernStatsView: View {
    let stats: GuestStats

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ModernStatCard(
                title: "Total Guests",
                value: "\(stats.totalGuests)",
                icon: "person.3.fill",
                color: .purple,
                trend: nil
            )

            ModernStatCard(
                title: "Attending",
                value: "\(stats.attendingGuests)",
                icon: "checkmark.seal.fill",
                color: AppColors.success,
                trend: .positive
            )

            ModernStatCard(
                title: "Pending",
                value: "\(stats.pendingGuests)",
                icon: "clock.badge.fill",
                color: AppColors.warning,
                trend: nil
            )

            ModernStatCard(
                title: "Response Rate",
                value: "\(Int(stats.responseRate))%",
                icon: "chart.line.uptrend.xyaxis",
                color: AppColors.info,
                trend: stats.responseRate >= 75 ? .positive : .neutral
            )
        }
    }
}
