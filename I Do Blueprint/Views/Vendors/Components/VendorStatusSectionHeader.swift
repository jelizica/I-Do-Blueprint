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
            .foregroundColor(status == "Booked" ? SemanticColors.statusSuccess : SemanticColors.statusWarning)

            Spacer()

            Text("\(count)")
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColors.textSecondary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(
                    Capsule()
                        .fill((status == "Booked" ? SemanticColors.statusSuccess : SemanticColors.statusWarning).opacity(Opacity.verySubtle))
                )
                .accessibilityLabel("\(count) vendors")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(SemanticColors.backgroundPrimary.opacity(Opacity.strong))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(status) section")
        .accessibilityValue("\(count) vendors")
        .accessibilityAddTraits(.isHeader)
    }
}
