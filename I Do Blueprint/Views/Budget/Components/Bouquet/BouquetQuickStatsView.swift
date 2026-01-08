//
//  BouquetQuickStatsView.swift
//  I Do Blueprint
//
//  Quick stats sidebar component for the Budget Bouquet visualization
//  Shows total budget, spent, remaining, and top expenses
//

import SwiftUI

// MARK: - Main Quick Stats View

struct BouquetQuickStatsView: View {
    let totalBudget: Double
    let totalSpent: Double
    let totalRemaining: Double
    let overallProgress: Double
    let categories: [BudgetCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            Text("Quick Stats")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)

            // Main stats cards
            statsGrid

            Divider()
                .padding(.vertical, Spacing.sm)

            // Progress indicator
            overallProgressView

            Divider()
                .padding(.vertical, Spacing.sm)

            // Top expenses
            topExpensesView
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                BouquetStatCard(
                    title: "Total Budget",
                    value: formatCurrency(totalBudget),
                    icon: "dollarsign.circle.fill",
                    color: SemanticColors.primaryAction
                )

                BouquetStatCard(
                    title: "Spent",
                    value: formatCurrency(totalSpent),
                    icon: "creditcard.fill",
                    color: SemanticColors.statusWarning
                )
            }

            HStack(spacing: Spacing.md) {
                BouquetStatCard(
                    title: "Remaining",
                    value: formatCurrency(totalRemaining),
                    icon: "banknote.fill",
                    color: totalRemaining >= 0
                        ? SemanticColors.statusSuccess
                        : SemanticColors.error
                )

                BouquetStatCard(
                    title: "Categories",
                    value: "\(categories.count)",
                    icon: "square.grid.2x2.fill",
                    color: SemanticColors.secondaryAction
                )
            }
        }
    }

    // MARK: - Overall Progress

    private var overallProgressView: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Overall Progress")
                    .font(Typography.subheading)
                    .foregroundColor(SemanticColors.textSecondary)

                Spacer()

                Text("\(Int(overallProgress * 100))%")
                    .font(Typography.numberSmall)
                    .foregroundColor(progressColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: CornerRadius.pill)
                        .fill(SemanticColors.borderLight)
                        .frame(height: 8)

                    // Progress fill
                    RoundedRectangle(cornerRadius: CornerRadius.pill)
                        .fill(
                            LinearGradient(
                                colors: [progressColor, progressColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * min(overallProgress, 1.0),
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            // Status message
            Text(progressStatusMessage)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
        }
    }

    // MARK: - Top Expenses

    private var topExpensesView: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Top Expenses")
                .font(Typography.subheading)
                .foregroundColor(SemanticColors.textSecondary)

            if topExpenseCategories.isEmpty {
                Text("No expenses recorded yet")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textTertiary)
                    .padding(.vertical, Spacing.sm)
            } else {
                ForEach(topExpenseCategories.prefix(3)) { category in
                    TopExpenseRow(category: category, totalSpent: totalSpent)
                }
            }
        }
    }

    // MARK: - Helpers

    private var progressColor: Color {
        if overallProgress >= 1.0 {
            return SemanticColors.statusWarning
        } else if overallProgress >= 0.8 {
            return SemanticColors.statusPending
        } else {
            return SemanticColors.statusSuccess
        }
    }

    private var progressStatusMessage: String {
        if overallProgress >= 1.0 {
            return "Budget fully utilized"
        } else if overallProgress >= 0.8 {
            return "Approaching budget limit"
        } else if overallProgress >= 0.5 {
            return "Good progress, stay on track"
        } else {
            return "Early stages of planning"
        }
    }

    private var topExpenseCategories: [BudgetCategory] {
        categories
            .filter { $0.spentAmount > 0 }
            .sorted { $0.spentAmount > $1.spentAmount }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Bouquet Stat Card

private struct BouquetStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Text(value)
                .font(Typography.numberMedium)
                .foregroundColor(SemanticColors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(SemanticColors.backgroundTertiary)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Top Expense Row

private struct TopExpenseRow: View {
    let category: BudgetCategory
    let totalSpent: Double

    private var percentage: Double {
        guard totalSpent > 0 else { return 0 }
        return (category.spentAmount / totalSpent) * 100
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Color indicator
            Circle()
                .fill(Color.fromHex(category.color))
                .frame(width: 8, height: 8)

            // Category name
            Text(category.categoryName)
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textPrimary)
                .lineLimit(1)

            Spacer()

            // Amount and percentage
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(formatCurrency(category.spentAmount))
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("\(Int(percentage))%")
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textTertiary)
            }
        }
        .padding(.vertical, Spacing.xs)
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

#Preview("Quick Stats") {
    BouquetQuickStatsView(
        totalBudget: 50000,
        totalSpent: 32000,
        totalRemaining: 18000,
        overallProgress: 0.64,
        categories: [
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Venue",
                allocatedAmount: 15000,
                spentAmount: 15000,
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
                categoryName: "Catering",
                allocatedAmount: 8000,
                spentAmount: 10000,
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
                categoryName: "Photography",
                allocatedAmount: 5000,
                spentAmount: 5000,
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
                spentAmount: 2000,
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
