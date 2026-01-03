//
//  V3QuickInfoCard.swift
//  I Do Blueprint
//
//  A card displaying a single piece of quick information with icon
//  Used in vendor detail view quick info grid
//

import SwiftUI

/// A card displaying a single piece of quick information with icon
struct V3QuickInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            // Value
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(SemanticColors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // Title/Label
            Text(title.uppercased())
                .font(Typography.caption2)
                .foregroundColor(SemanticColors.textSecondary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Preview

#Preview("Quick Info Cards") {
    VStack(spacing: Spacing.md) {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: Spacing.md
        ) {
            V3QuickInfoCard(
                icon: "tag.fill",
                title: "Category",
                value: "Wedding Cake & Desserts",
                color: .purple
            )

            V3QuickInfoCard(
                icon: "dollarsign.circle.fill",
                title: "Quoted Amount",
                value: "$400",
                color: SemanticColors.statusSuccess
            )

            V3QuickInfoCard(
                icon: "checkmark.seal.fill",
                title: "Status",
                value: "Booked",
                color: SemanticColors.statusSuccess
            )

            V3QuickInfoCard(
                icon: "calendar.badge.checkmark",
                title: "Booked On",
                value: "Apr 14, 2025",
                color: SemanticColors.primaryAction
            )
        }
    }
    .padding()
    .background(SemanticColors.backgroundPrimary)
}
