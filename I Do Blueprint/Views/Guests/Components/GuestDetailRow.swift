//
//  GuestDetailRow.swift
//  My Wedding Planning App
//
//  Extracted from GuestListViewV2.swift
//

import SwiftUI

struct GuestListDetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)

                Text(value)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(AppColors.cardBackground)
        )
    }
}
