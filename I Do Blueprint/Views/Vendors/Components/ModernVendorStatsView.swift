//
//  ModernVendorStatsView.swift
//  I Do Blueprint
//
//  Extracted from VendorListViewV2.swift
//

import SwiftUI

struct ModernVendorStatsView: View {
    let stats: VendorStats

    var body: some View {
        StatsGridView(
            stats: [
                .vendorTotal(count: stats.total),
                .vendorBooked(count: stats.booked),
                StatItem(
                    icon: "clock.badge.fill",
                    label: "Available",
                    value: "\(stats.available)",
                    color: AppColors.Vendor.pending,
                    accessibilityLabel: "Available vendors: \(stats.available)"
                ),
                StatItem(
                    icon: "dollarsign.circle.fill",
                    label: "Total Cost",
                    value: "$\(Int(stats.totalCost))",
                    color: AppColors.info,
                    accessibilityLabel: "Total vendor cost: $\(Int(stats.totalCost))"
                )
            ],
            columns: 2
        )
    }
}
