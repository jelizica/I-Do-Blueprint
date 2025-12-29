//
//  V3SectionHeader.swift
//  I Do Blueprint
//
//  Section header component for V3 vendor detail view
//

import SwiftUI

/// Section header with icon and title
struct V3SectionHeader: View {
    let title: String
    let icon: String
    var color: Color = AppColors.primary
    var showDivider: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()
            }

            if showDivider {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.5), color.opacity(0.1), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .cornerRadius(1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("\(title) section")
    }
}

// MARK: - Preview

#Preview("Section Headers") {
    VStack(alignment: .leading, spacing: Spacing.xl) {
        V3SectionHeader(
            title: "Quick Info",
            icon: "info.circle.fill",
            color: AppColors.Vendor.contacted
        )

        V3SectionHeader(
            title: "Contact",
            icon: "envelope.circle.fill",
            color: AppColors.Vendor.contacted
        )

        V3SectionHeader(
            title: "Expenses",
            icon: "receipt.fill",
            color: AppColors.Vendor.booked
        )

        V3SectionHeader(
            title: "Payment Schedule",
            icon: "calendar.badge.clock",
            color: AppColors.Vendor.pending
        )

        V3SectionHeader(
            title: "Documents",
            icon: "doc.text.fill",
            color: AppColors.primary,
            showDivider: false
        )
    }
    .padding()
    .background(AppColors.background)
}
