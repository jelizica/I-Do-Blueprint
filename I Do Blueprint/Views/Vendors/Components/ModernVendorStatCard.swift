//
//  ModernVendorStatCard.swift
//  I Do Blueprint
//
//  Extracted from VendorListViewV2.swift
//

import SwiftUI

struct ModernVendorStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )

                Spacer()
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text(title)
                .font(.system(size: 9))
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.3)
        }
        .frame(height: 80)
        .hoverableCard(padding: Spacing.md)
    }
}
