//
//  BudgetOverviewSummaryCards.swift
//  I Do Blueprint
//
//  Created by Claude on 10/9/25.
//

import SwiftUI

struct BudgetOverviewSummaryCards: View {
    let totalBudget: Double
    let totalExpenses: Double
    let totalRemaining: Double
    let itemCount: Int

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            SummaryCardView(
                title: "Total Budget",
                value: totalBudget,
                icon: "dollarsign.circle",
                color: AppColors.Budget.allocated)

            SummaryCardView(
                title: "Total Expenses",
                value: totalExpenses,
                icon: "receipt",
                color: AppColors.Budget.pending)

            SummaryCardView(
                title: "Remaining",
                value: totalRemaining,
                icon: "target",
                color: totalRemaining >= 0 ? AppColors.Budget.underBudget : AppColors.Budget.overBudget)

            SummaryCardView(
                title: "Budget Items",
                value: Double(itemCount),
                icon: "list.bullet",
                color: .purple,
                formatAsCurrency: false)
        }
    }
}
