//
//  GuestStatusSectionHeader.swift
//  My Wedding Planning App
//
//  Extracted from GuestListViewV2.swift
//

import SwiftUI

struct StatusSectionHeader: View {
    let status: RSVPStatus
    let count: Int

    var body: some View {
        HStack {
            HStack(spacing: Spacing.sm) {
                Image(systemName: status.iconName)
                    .font(Typography.caption)
                Text(status.displayName)
                    .font(Typography.subheading)
            }
            .foregroundColor(status.color)

            Spacer()

            Text("\(count)")
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(
                    Capsule()
                        .fill(status.color.opacity(0.15))
                )
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(AppColors.background.opacity(0.95))
    }
}
