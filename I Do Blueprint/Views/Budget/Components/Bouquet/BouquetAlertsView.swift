//
//  BouquetAlertsView.swift
//  I Do Blueprint
//
//  Alerts component for the Budget Bouquet visualization
//  Shows budget warnings, over-budget alerts, and action recommendations
//

import SwiftUI

// MARK: - Main Alerts View

struct BouquetAlertsView: View {
    let categories: [BudgetCategory]

    // MARK: - Computed Properties

    private var overBudgetCategories: [BudgetCategory] {
        categories.filter { $0.isOverBudget }
    }

    private var nearLimitCategories: [BudgetCategory] {
        categories.filter { category in
            !category.isOverBudget &&
            category.allocatedAmount > 0 &&
            category.percentageSpent >= 80
        }
    }

    private var notStartedCategories: [BudgetCategory] {
        categories.filter { $0.spentAmount == 0 && $0.allocatedAmount > 0 }
    }

    private var hasAlerts: Bool {
        !overBudgetCategories.isEmpty || !nearLimitCategories.isEmpty
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            alertsHeader

            if hasAlerts {
                // Over budget alerts (critical)
                if !overBudgetCategories.isEmpty {
                    alertSection(
                        title: "Over Budget",
                        icon: "exclamationmark.triangle.fill",
                        color: SemanticColors.error,
                        categories: overBudgetCategories,
                        alertType: .overBudget
                    )
                }

                // Approaching limit warnings
                if !nearLimitCategories.isEmpty {
                    alertSection(
                        title: "Approaching Limit",
                        icon: "exclamationmark.circle.fill",
                        color: SemanticColors.statusWarning,
                        categories: nearLimitCategories,
                        alertType: .nearLimit
                    )
                }
            } else {
                // No alerts - show positive message
                noAlertsView
            }

            // Quick tips section
            Divider()
                .padding(.vertical, Spacing.sm)

            quickTipsView
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Header

    private var alertsHeader: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: hasAlerts ? "bell.badge.fill" : "bell.fill")
                .font(.title3)
                .foregroundColor(hasAlerts ? SemanticColors.statusWarning : SemanticColors.textSecondary)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Budget Alerts")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Text(alertSummaryText)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer()

            // Alert count badge
            if hasAlerts {
                Text("\(overBudgetCategories.count + nearLimitCategories.count)")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textOnPrimary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(SemanticColors.error)
                    .cornerRadius(CornerRadius.pill)
            }
        }
    }

    private var alertSummaryText: String {
        if overBudgetCategories.isEmpty && nearLimitCategories.isEmpty {
            return "No issues detected"
        }

        var parts: [String] = []
        if !overBudgetCategories.isEmpty {
            parts.append("\(overBudgetCategories.count) over budget")
        }
        if !nearLimitCategories.isEmpty {
            parts.append("\(nearLimitCategories.count) approaching limit")
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Alert Section

    @ViewBuilder
    private func alertSection(
        title: String,
        icon: String,
        color: Color,
        categories: [BudgetCategory],
        alertType: AlertType
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Section header
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(title)
                    .font(Typography.subheading)
                    .foregroundColor(color)
            }

            // Category alerts
            ForEach(categories) { category in
                AlertRow(
                    category: category,
                    alertType: alertType
                )
            }
        }
    }

    // MARK: - No Alerts View

    private var noAlertsView: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(SemanticColors.statusSuccess)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("All Clear!")
                    .font(Typography.subheading)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("All categories are within budget")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(SemanticColors.statusSuccess.opacity(Opacity.verySubtle))
        .cornerRadius(CornerRadius.md)
    }

    // MARK: - Quick Tips

    private var quickTipsView: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick Tips")
                .font(Typography.subheading)
                .foregroundColor(SemanticColors.textSecondary)

            ForEach(relevantTips, id: \.self) { tip in
                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(SemanticColors.statusPending)

                    Text(tip)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var relevantTips: [String] {
        var tips: [String] = []

        if !overBudgetCategories.isEmpty {
            tips.append("Consider reallocating funds from under-utilized categories to cover over-budget items.")
        }

        if !nearLimitCategories.isEmpty {
            tips.append("Monitor approaching limits closely. Small unexpected costs can push you over budget.")
        }

        if notStartedCategories.count > 3 {
            tips.append("You have \(notStartedCategories.count) categories with no spending yet. Start tracking early!")
        }

        if tips.isEmpty {
            tips.append("Great job staying on budget! Keep tracking expenses to maintain your progress.")
            tips.append("Review your allocations periodically as wedding plans evolve.")
        }

        return Array(tips.prefix(3))
    }
}

// MARK: - Alert Type

private enum AlertType {
    case overBudget
    case nearLimit

    var badgeText: String {
        switch self {
        case .overBudget: return "Over"
        case .nearLimit: return "80%+"
        }
    }

    var badgeColor: Color {
        switch self {
        case .overBudget: return SemanticColors.error
        case .nearLimit: return SemanticColors.statusWarning
        }
    }
}

// MARK: - Alert Row

private struct AlertRow: View {
    let category: BudgetCategory
    let alertType: AlertType

    private var overAmount: Double {
        max(0, category.spentAmount - category.allocatedAmount)
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Category color indicator
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.fromHex(category.color))
                .frame(width: 4, height: 40)

            // Category info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(category.categoryName)
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: Spacing.xs) {
                    Text(formatCurrency(category.spentAmount))
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    Text("/")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textTertiary)

                    Text(formatCurrency(category.allocatedAmount))
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textTertiary)
                }
            }

            Spacer()

            // Status badge
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(alertType.badgeText)
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textOnPrimary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(alertType.badgeColor)
                    .cornerRadius(CornerRadius.pill)

                if alertType == .overBudget && overAmount > 0 {
                    Text("+\(formatCurrency(overAmount))")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.error)
                } else {
                    Text("\(Int(category.percentageSpent))%")
                        .font(Typography.caption2)
                        .foregroundColor(alertType.badgeColor)
                }
            }
        }
        .padding(Spacing.sm)
        .background(alertType.badgeColor.opacity(Opacity.verySubtle))
        .cornerRadius(CornerRadius.md)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Preview

#Preview("Budget Alerts - With Issues") {
    BouquetAlertsView(
        categories: [
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Catering",
                allocatedAmount: 8000,
                spentAmount: 9500,
                priorityLevel: 1,
                isEssential: true,
                forecastedAmount: 8500,
                confidenceLevel: 0.7,
                lockedAllocation: false,
                color: "#8F24F5",
                createdAt: Date()
            ),
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Venue",
                allocatedAmount: 15000,
                spentAmount: 14000,
                priorityLevel: 1,
                isEssential: true,
                forecastedAmount: 15000,
                confidenceLevel: 0.9,
                lockedAllocation: false,
                color: "#EF2A78",
                createdAt: Date()
            ),
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Photography",
                allocatedAmount: 5000,
                spentAmount: 4200,
                priorityLevel: 2,
                isEssential: true,
                forecastedAmount: 5000,
                confidenceLevel: 0.8,
                lockedAllocation: false,
                color: "#83A276",
                createdAt: Date()
            ),
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Flowers",
                allocatedAmount: 3000,
                spentAmount: 0,
                priorityLevel: 3,
                isEssential: false,
                forecastedAmount: 3000,
                confidenceLevel: 0.6,
                lockedAllocation: false,
                color: "#DB643D",
                createdAt: Date()
            )
        ]
    )
    .frame(width: 300)
    .padding()
    .background(SemanticColors.backgroundPrimary)
}

#Preview("Budget Alerts - All Clear") {
    BouquetAlertsView(
        categories: [
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Venue",
                allocatedAmount: 15000,
                spentAmount: 10000,
                priorityLevel: 1,
                isEssential: true,
                forecastedAmount: 15000,
                confidenceLevel: 0.9,
                lockedAllocation: false,
                color: "#EF2A78",
                createdAt: Date()
            ),
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Photography",
                allocatedAmount: 5000,
                spentAmount: 2500,
                priorityLevel: 2,
                isEssential: true,
                forecastedAmount: 5000,
                confidenceLevel: 0.8,
                lockedAllocation: false,
                color: "#83A276",
                createdAt: Date()
            )
        ]
    )
    .frame(width: 300)
    .padding()
    .background(SemanticColors.backgroundPrimary)
}
