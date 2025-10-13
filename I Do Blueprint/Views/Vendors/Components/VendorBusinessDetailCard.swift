//
//  VendorBusinessDetailCard.swift
//  My Wedding Planning App
//
//  Extracted from VendorDetailViewV2.swift
//

import SwiftUI

struct BusinessDetailCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)

                Text(value)
                    .font(Typography.caption)
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.shadowLight, radius: 3, y: 2)
        )
    }
}
