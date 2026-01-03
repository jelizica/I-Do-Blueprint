//
//  BudgetDetailedView.swift
//  I Do Blueprint
//
//  Detailed budget view with category breakdown
//

import SwiftUI

struct BudgetDetailedView: View {
    @ObservedObject var store: BudgetStoreV2

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Summary Cards
            HStack(spacing: Spacing.md) {
                DashboardSummaryCard(
                    title: "Total Budget",
                    value: "$\(Int(store.actualTotalBudget).formatted())",
                    icon: "dollarsign.circle.fill",
                    color: .blue
                )

                DashboardSummaryCard(
                    title: "Spent",
                    value: "$\(Int(store.totalSpent).formatted())",
                    icon: "arrow.down.circle.fill",
                    color: .red
                )

                DashboardSummaryCard(
                    title: "Remaining",
                    value: "$\(Int(store.remainingBudget).formatted())",
                    icon: "arrow.up.circle.fill",
                    color: .green
                )
            }

            // Category Breakdown
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Budget by Category")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                ForEach(store.categoryStore.categories) { category in
                    CategoryRow(category: category)
                }
            }
            .padding(Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(SemanticColors.textPrimary.opacity(Opacity.medium))
                    .shadow(color: SemanticColors.shadowLight, radius: 8, y: 4)
            )
        }
    }
}

struct DashboardSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(SemanticColors.textPrimary)

                Text(title)
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(SemanticColors.textPrimary.opacity(Opacity.medium))
                .shadow(color: SemanticColors.shadowLight, radius: 8, y: 4)
        )
    }
}

struct CategoryRow: View {
    let category: BudgetCategory

    private var percentage: Double {
        guard category.allocatedAmount > 0 else { return 0 }
        return min((category.spentAmount / category.allocatedAmount) * 100, 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(category.categoryName)
                    .font(Typography.bodyRegular)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                Text("$\(Int(category.spentAmount).formatted()) / $\(Int(category.allocatedAmount).formatted())")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            ProgressView(value: percentage, total: 100)
                .tint(progressColor)
        }
        .padding(.vertical, Spacing.sm)
    }

    private var progressColor: Color {
        if percentage >= 100 {
            return SemanticColors.error
        } else if percentage >= 90 {
            return SemanticColors.warning
        } else {
            return SemanticColors.success
        }
    }
}

#Preview {
    BudgetDetailedView(store: BudgetStoreV2())
        .padding()
        .frame(width: 800)
}
