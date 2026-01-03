//
//  DashboardMetricCard.swift
//  I Do Blueprint
//
//  Extracted metric card for dashboard
//

import SwiftUI

struct DashboardMetricCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 48, height: 48)
                    .background(iconColor.opacity(0.1))
                    .cornerRadius(CornerRadius.md)

                Spacer(minLength: Spacing.sm)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(value)
                    .font(Typography.numberMedium)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .shadow(color: SemanticColors.shadowLight, radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text("\(value), \(subtitle)"))
    }
}
