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
    var color: Color = SemanticColors.primaryAction
    var showDivider: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

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
            color: SemanticColors.primaryAction
        )

        V3SectionHeader(
            title: "Contact",
            icon: "envelope.circle.fill",
            color: SemanticColors.primaryAction
        )

        V3SectionHeader(
            title: "Expenses",
            icon: "receipt.fill",
            color: SemanticColors.statusSuccess
        )

        V3SectionHeader(
            title: "Payment Schedule",
            icon: "calendar.badge.clock",
            color: SemanticColors.statusPending
        )

        V3SectionHeader(
            title: "Documents",
            icon: "doc.text.fill",
            color: SemanticColors.primaryAction,
            showDivider: false
        )
    }
    .padding()
    .background(SemanticColors.backgroundPrimary)
}
