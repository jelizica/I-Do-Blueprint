//
//  StatsCardView.swift
//  I Do Blueprint
//
//  Individual statistics card component
//

import SwiftUI

/// Individual statistics card displaying icon, value, label, and optional trend
struct StatsCardView: View {
    let stat: StatItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Icon and trend row
            HStack {
                Image(systemName: stat.icon)
                    .font(.title2)
                    .foregroundColor(stat.color)
                    .accessibilityHidden(true)

                Spacer()

                if let trend = stat.trend {
                    TrendIndicator(trend: trend)
                }
            }

            Spacer()

            // Value
            Text(stat.value)
                .font(Typography.numberLarge)
                .foregroundColor(SemanticColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Label
            Text(stat.label)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .card(shadow: .light)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stat.fullAccessibilityLabel)
        .accessibilityAddTraits(.isStaticText)
    }
}

/// Trend indicator showing directional change
struct TrendIndicator: View {
    let trend: StatItem.Trend

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .font(.caption2)

            if case .up(let value) = trend {
                Text(value)
                    .font(Typography.caption2)
            } else if case .down(let value) = trend {
                Text(value)
                    .font(Typography.caption2)
            }
        }
        .foregroundColor(trend.color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(trend.color.opacity(0.1))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(trend.accessibilityDescription)
    }
}

// MARK: - Previews

#Preview("Guest Stats Card") {
    StatsCardView(stat: .guestTotal(count: 150))
        .frame(width: 200)
}

#Preview("Budget Stats Card") {
    StatsCardView(stat: .budgetTotal(amount: 25000))
        .frame(width: 200)
}

#Preview("Stats Card with Trend Up") {
    StatsCardView(
        stat: StatItem(
            icon: "person.3.fill",
            label: "Total Guests",
            value: "150",
            color: .blue,
            trend: .up("+10")
        )
    )
    .frame(width: 200)
}

#Preview("Stats Card with Trend Down") {
    StatsCardView(
        stat: StatItem(
            icon: "dollarsign.circle.fill",
            label: "Remaining Budget",
            value: "$5,000",
            color: AppColors.Budget.underBudget,
            trend: .down("-$2,000")
        )
    )
    .frame(width: 200)
}

#Preview("Vendor Stats Card") {
    StatsCardView(stat: .vendorBooked(count: 8))
        .frame(width: 200)
}
