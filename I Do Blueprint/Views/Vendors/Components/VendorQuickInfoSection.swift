//
//  VendorQuickInfoSection.swift
//  My Wedding Planning App
//
//  Extracted from VendorDetailViewV2.swift
//

import SwiftUI

struct VendorQuickInfoSection: View {
    let vendor: Vendor
    let contractInfo: VendorContract?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Quick Info",
                icon: "info.circle.fill",
                color: .blue
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: Spacing.md
            ) {
                if let vendorType = vendor.vendorType {
                    QuickInfoCard(
                        icon: "tag.fill",
                        title: "Category",
                        value: vendorType,
                        color: .purple
                    )
                }

                if let quotedAmount = vendor.quotedAmount {
                    QuickInfoCard(
                        icon: "dollarsign.circle.fill",
                        title: "Quoted Amount",
                        value: "$\(Int(quotedAmount))",
                        color: .green
                    )
                }

                QuickInfoCard(
                    icon: vendor.isBooked == true ? "checkmark.seal.fill" : "clock.badge.fill",
                    title: "Status",
                    value: vendor.statusDisplayName,
                    color: vendor.isBooked == true ? .green : .orange
                )

                if let dateBooked = vendor.dateBooked, vendor.isBooked == true {
                    QuickInfoCard(
                        icon: "calendar.badge.checkmark",
                        title: "Booked On",
                        value: dateBooked.formatted(date: .abbreviated, time: .omitted),
                        color: .blue
                    )
                }

                if let contractStatus = contractInfo?.contractStatus, contractStatus != .none {
                    QuickInfoCard(
                        icon: "doc.text.fill",
                        title: "Contract",
                        value: contractStatus.displayName,
                        color: .blue
                    )
                }
            }
        }
    }
}
