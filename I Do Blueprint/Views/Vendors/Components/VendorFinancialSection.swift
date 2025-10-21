//
//  VendorFinancialSection.swift
//  My Wedding Planning App
//
//  Extracted from VendorDetailViewV2.swift
//

import SwiftUI

struct VendorFinancialSection: View {
    let vendor: Vendor

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Financial",
                icon: "dollarsign.circle.fill",
                color: AppColors.Vendor.booked
            )

            VStack(spacing: Spacing.sm) {
                if let quotedAmount = vendor.quotedAmount {
                    FinancialCard(
                        icon: "banknote.fill",
                        title: "Quoted Amount",
                        value: "$\(Int(quotedAmount))",
                        color: AppColors.Vendor.booked
                    )
                }

                if let budgetCategory = vendor.budgetCategoryName {
                    FinancialCard(
                        icon: "chart.pie.fill",
                        title: "Budget Category",
                        value: budgetCategory,
                        color: AppColors.Vendor.pending
                    )
                }
            }
        }
    }
}
