//
//  SummaryCard.swift
//  I Do Blueprint
//
//  Summary card component for displaying aggregated information
//

import SwiftUI

/// Summary card for displaying aggregated data with multiple metrics
struct SummaryCard: View {
    private let logger = AppLogger.ui
    let title: String
    let items: [SummaryItem]
    let action: (() -> Void)?

    init(title: String, items: [SummaryItem], action: (() -> Void)? = nil) {
        self.title = title
        self.items = items
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Text(title)
                    .font(Typography.heading)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                if let action = action {
                    Button(action: action) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View details")
                }
            }

            Divider()

            // Summary items
            VStack(spacing: Spacing.sm) {
                ForEach(items) { item in
                    SummaryItemRow(item: item)
                }
            }
        }
        .padding(Spacing.lg)
        .card(shadow: .light)
        .accessibilityElement(children: .contain)
    }
}

/// Individual summary item
struct SummaryItem: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let icon: String?
    let color: Color?

    init(label: String, value: String, icon: String? = nil, color: Color? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
        self.color = color
    }
}

/// Row for displaying a summary item
struct SummaryItemRow: View {
    let item: SummaryItem

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon = item.icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(item.color ?? AppColors.textSecondary)
                    .frame(width: 20)
            }

            Text(item.label)
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)

            Spacer()

            Text(item.value)
                .font(Typography.bodyRegular)
                .fontWeight(.medium)
                .foregroundColor(item.color ?? AppColors.textPrimary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.label): \(item.value)")
    }
}

// MARK: - Compact Summary Card

/// Compact summary card for dashboard widgets
struct CompactSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: StatItem.Trend?

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color,
        trend: StatItem.Trend? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Icon and trend
            HStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .font(.body)
                            .foregroundColor(color)
                    )

                Spacer()

                if let trend = trend {
                    TrendIndicator(trend: trend)
                }
            }

            // Value
            Text(value)
                .font(Typography.numberLarge)
                .foregroundColor(AppColors.textPrimary)

            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(Spacing.md)
        .card(shadow: .light)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)\(subtitle != nil ? ", \(subtitle!)" : "")")
    }
}

// MARK: - Previews

#Preview("Summary Card") {
    SummaryCard(
        title: "Wedding Overview",
        items: [
            SummaryItem(label: "Total Guests", value: "150", icon: "person.3.fill", color: Color.blue),
            SummaryItem(label: "Confirmed", value: "120", icon: "checkmark.circle.fill", color: Color.green),
            SummaryItem(label: "Pending", value: "25", icon: "clock.fill", color: Color.orange),
            SummaryItem(label: "Declined", value: "5", icon: "xmark.circle.fill", color: Color.red)
        ],
        action: {
            // TODO: Implement action - print("View details tapped")
        }
    )
    .padding()
    .frame(width: 350)
}

#Preview("Compact Summary Cards") {
    HStack(spacing: Spacing.md) {
        CompactSummaryCard(
            title: "Total Budget",
            value: "$25,000",
            subtitle: "Allocated",
            icon: "dollarsign.circle.fill",
            color: .blue
        )

        CompactSummaryCard(
            title: "Spent",
            value: "$18,000",
            subtitle: "72% of budget",
            icon: "creditcard.fill",
            color: .orange,
            trend: .up("+$2,000")
        )

        CompactSummaryCard(
            title: "Remaining",
            value: "$7,000",
            subtitle: "28% left",
            icon: "banknote.fill",
            color: .green,
            trend: .down("-$2,000")
        )
    }
    .padding()
}

#Preview("Budget Summary") {
    SummaryCard(
        title: "Budget Summary",
        items: [
            SummaryItem(label: "Total Budget", value: "$25,000", icon: "dollarsign.circle.fill", color: .blue),
            SummaryItem(label: "Spent", value: "$18,000", icon: "creditcard.fill", color: .orange),
            SummaryItem(label: "Remaining", value: "$7,000", icon: "banknote.fill", color: .green),
            SummaryItem(label: "Categories", value: "12", icon: "folder.fill", color: .purple)
        ]
    )
    .padding()
    .frame(width: 350)
}
