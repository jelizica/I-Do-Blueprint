//
//  StatsGridView.swift
//  I Do Blueprint
//
//  Grid layout for displaying multiple statistics cards
//

import SwiftUI

/// Grid view for displaying multiple statistics cards
struct StatsGridView: View {
    let stats: [StatItem]
    let columns: Int
    let spacing: CGFloat
    
    init(stats: [StatItem], columns: Int = 3, spacing: CGFloat = Spacing.md) {
        self.stats = stats
        self.columns = columns
        self.spacing = spacing
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            ForEach(stats) { stat in
                StatsCardView(stat: stat)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Adaptive Stats Grid

/// Adaptive stats grid that adjusts columns based on available width
struct AdaptiveStatsGridView: View {
    let stats: [StatItem]
    let minColumnWidth: CGFloat
    let spacing: CGFloat
    
    init(stats: [StatItem], minColumnWidth: CGFloat = 180, spacing: CGFloat = Spacing.md) {
        self.stats = stats
        self.minColumnWidth = minColumnWidth
        self.spacing = spacing
    }
    
    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minColumnWidth), spacing: spacing)],
            spacing: spacing
        ) {
            ForEach(stats) { stat in
                StatsCardView(stat: stat)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Previews

#Preview("Guest Stats Grid - 3 Columns") {
    StatsGridView(
        stats: [
            .guestTotal(count: 150),
            .guestConfirmed(count: 120, total: 150),
            .guestPending(count: 25),
            .guestDeclined(count: 5)
        ],
        columns: 3
    )
    .padding()
}

#Preview("Vendor Stats Grid - 4 Columns") {
    StatsGridView(
        stats: [
            .vendorTotal(count: 12),
            .vendorBooked(count: 8),
            .vendorPending(count: 3),
            .vendorContacted(count: 10)
        ],
        columns: 4
    )
    .padding()
}

#Preview("Budget Stats Grid - 3 Columns") {
    StatsGridView(
        stats: [
            .budgetTotal(amount: 25000),
            .budgetSpent(amount: 18000, total: 25000),
            .budgetRemaining(amount: 7000)
        ],
        columns: 3
    )
    .padding()
}

#Preview("Task Stats Grid - 2 Columns") {
    StatsGridView(
        stats: [
            .taskTotal(count: 45),
            .taskCompleted(count: 32, total: 45),
            .taskOverdue(count: 3)
        ],
        columns: 2
    )
    .padding()
}

#Preview("Adaptive Stats Grid") {
    AdaptiveStatsGridView(
        stats: [
            .guestTotal(count: 150),
            .guestConfirmed(count: 120, total: 150),
            .guestPending(count: 25),
            .guestDeclined(count: 5),
            .vendorTotal(count: 12),
            .vendorBooked(count: 8)
        ]
    )
    .padding()
    .frame(width: 800)
}
