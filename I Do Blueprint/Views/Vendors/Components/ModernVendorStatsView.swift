//
//  ModernVendorStatsView.swift
//  I Do Blueprint
//
//  Extracted from VendorListViewV2.swift
//

import SwiftUI

struct ModernVendorStatsView: View {
    let stats: VendorStats

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.sm) {
            ModernVendorStatCard(
                title: "Total Vendors",
                value: "\(stats.total)",
                icon: "building.2.fill",
                color: .purple
            )

            ModernVendorStatCard(
                title: "Booked",
                value: "\(stats.booked)",
                icon: "checkmark.seal.fill",
                color: AppColors.success
            )

            ModernVendorStatCard(
                title: "Available",
                value: "\(stats.available)",
                icon: "clock.badge.fill",
                color: AppColors.warning
            )

            ModernVendorStatCard(
                title: "Total Cost",
                value: "$\(Int(stats.totalCost))",
                icon: "dollarsign.circle.fill",
                color: AppColors.info
            )
        }
    }
}
