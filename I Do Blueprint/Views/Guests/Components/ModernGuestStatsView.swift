//
//  ModernGuestStatsView.swift
//  My Wedding Planning App
//
//  Extracted from GuestListViewV2.swift
//

import SwiftUI

struct ModernStatsView: View {
    let stats: GuestStats

    var body: some View {
        StatsGridView(
            stats: [
                .guestTotal(count: stats.totalGuests),
                .guestConfirmed(count: stats.attendingGuests, total: stats.totalGuests),
                .guestPending(count: stats.pendingGuests),
                StatItem(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Response Rate",
                    value: "\(Int(stats.responseRate))%",
                    color: AppColors.info,
                    trend: stats.responseRate >= 75 ? .up("+\(Int(stats.responseRate - 50))%") : .neutral,
                    accessibilityLabel: "Response rate: \(Int(stats.responseRate)) percent"
                )
            ],
            columns: 2
        )
    }
}
