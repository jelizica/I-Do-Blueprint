//
//  VendorFinancialCard.swift
//  My Wedding Planning App
//
//  Extracted from VendorDetailViewV2.swift
//

import SwiftUI

struct FinancialCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)
            }

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(color.opacity(0.1))
                )
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowLight, radius: 3, y: 2)
        )
    }
}
