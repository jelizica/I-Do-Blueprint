//
//  VendorBusinessDetailsSection.swift
//  My Wedding Planning App
//
//  Extracted from VendorDetailViewV2.swift
//

import SwiftUI

struct VendorBusinessDetailsSection: View {
    let vendor: Vendor
    let reviewStats: VendorReviewStats?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Business Details",
                icon: "building.2.circle.fill",
                color: .purple
            )

            VStack(spacing: Spacing.sm) {
                BusinessDetailCard(
                    icon: "building.columns.fill",
                    title: "Business Name",
                    value: vendor.vendorName,
                    color: .purple
                )

                if let vendorType = vendor.vendorType {
                    BusinessDetailCard(
                        icon: "tag.fill",
                        title: "Service Type",
                        value: vendorType,
                        color: AppColors.Vendor.contacted
                    )
                }

                if let avgRating = reviewStats?.avgRating {
                    BusinessDetailCard(
                        icon: "star.fill",
                        title: "Average Rating",
                        value: String(format: "%.1f", avgRating),
                        color: .yellow
                    )
                }
            }
        }
    }
}
