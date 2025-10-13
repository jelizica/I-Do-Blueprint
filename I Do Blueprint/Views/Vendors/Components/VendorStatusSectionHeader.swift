//
//  VendorStatusSectionHeader.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/9/25.
//  Section header component for grouped vendor lists
//

import SwiftUI

struct VendorStatusSectionHeader: View {
    let status: String
    let count: Int

    var body: some View {
        HStack {
            HStack(spacing: Spacing.sm) {
                Image(systemName: status == "Booked" ? "checkmark.seal.fill" : "clock.badge.fill")
                    .font(Typography.caption)
                Text(status)
                    .font(Typography.subheading)
            }
            .foregroundColor(status == "Booked" ? AppColors.success : AppColors.warning)

            Spacer()

            Text("\(count)")
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(
                    Capsule()
                        .fill((status == "Booked" ? AppColors.success : AppColors.warning).opacity(0.15))
                )
                .accessibilityLabel("\(count) vendors")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(AppColors.background.opacity(0.95))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(status) section")
        .accessibilityValue("\(count) vendors")
        .accessibilityAddTraits(.isHeader)
    }
}
