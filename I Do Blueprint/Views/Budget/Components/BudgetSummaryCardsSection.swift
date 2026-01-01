// Extracted from BudgetDevelopmentView.swift

import SwiftUI

struct BudgetSummaryCardsSection: View {
    let windowSize: WindowSize
    let totalWithoutTax: Double
    let totalTax: Double
    let totalWithTax: Double

    var body: some View {
        Group {
            if windowSize == .compact {
                // Compact: Vertical stack
                VStack(spacing: Spacing.md) {
                    SummaryCardView(
                        title: "Total Without Tax",
                        value: totalWithoutTax,
                        icon: "dollarsign.circle",
                        color: AppColors.Budget.allocated)
                    
                    SummaryCardView(
                        title: "Total Tax",
                        value: totalTax,
                        icon: "percent",
                        color: AppColors.Budget.pending)
                    
                    SummaryCardView(
                        title: "Total With Tax",
                        value: totalWithTax,
                        icon: "calculator",
                        color: AppColors.Budget.income)
                }
            } else {
                // Regular/Large: Horizontal
                HStack(spacing: 16) {
                    SummaryCardView(
                        title: "Total Without Tax",
                        value: totalWithoutTax,
                        icon: "dollarsign.circle",
                        color: AppColors.Budget.allocated)

                    SummaryCardView(
                        title: "Total Tax",
                        value: totalTax,
                        icon: "percent",
                        color: AppColors.Budget.pending)

                    SummaryCardView(
                        title: "Total With Tax",
                        value: totalWithTax,
                        icon: "calculator",
                        color: AppColors.Budget.income)
                }
            }
        }
    }
}
