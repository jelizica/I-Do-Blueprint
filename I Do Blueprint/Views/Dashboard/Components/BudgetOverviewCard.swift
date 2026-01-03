//
//  BudgetOverviewCard.swift
//  I Do Blueprint
//
//  Budget overview with circular progress showing:
//  - Total Budget: From primary budget development scenario
//  - Amount Spent: From paid payments
//

import SwiftUI

struct BudgetOverviewCard: View {
    @ObservedObject var store: BudgetStoreV2

    // Computed properties for budget values
    private var totalBudget: Double {
        // Get from primary budget development scenario
        store.primaryScenarioTotal
    }

    private var amountSpent: Double {
        // Get total from paid payments
        store.payments.totalPaid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Budget Overview")
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text("Paid payments vs total budget")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Spacer()
            }

            // Circular Progress
            HStack {
                Spacer()

                DashboardCircularProgressView(
                    currentValue: amountSpent,
                    goalValue: totalBudget,
                    size: 220,
                    strokeWidth: 20,
                    color: budgetColor
                )

                Spacer()
            }

            // Budget breakdown
            VStack(spacing: Spacing.sm) {
                budgetRow(
                    label: "Total Budget",
                    value: totalBudget,
                    color: SemanticColors.textPrimary
                )

                budgetRow(
                    label: "Paid",
                    value: amountSpent,
                    color: budgetColor
                )

                budgetRow(
                    label: "Remaining",
                    value: max(0, totalBudget - amountSpent),
                    color: remainingColor
                )
            }
            .padding(.top, Spacing.md)
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(SemanticColors.textPrimary.opacity(Opacity.medium))
                .shadow(color: SemanticColors.shadowLight, radius: 8, y: 4)
        )
    }

    private var budgetColor: Color {
        let percentage = totalBudget > 0 ? (amountSpent / totalBudget) * 100 : 0
        if percentage >= 100 {
            return SemanticColors.error
        } else if percentage >= 90 {
            return SemanticColors.warning
        } else {
            return SemanticColors.success
        }
    }

    private var remainingColor: Color {
        let remaining = totalBudget - amountSpent
        return remaining > 0 ? SemanticColors.success : SemanticColors.error
    }

    private func budgetRow(label: String, value: Double, color: Color) -> some View {
        HStack {
            Text(label)
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)

            Spacer()

            Text("$\(Int(value).formatted())")
                .font(Typography.bodySmall)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

#Preview {
    BudgetOverviewCard(store: BudgetStoreV2())
        .frame(width: 400)
        .padding()
}
