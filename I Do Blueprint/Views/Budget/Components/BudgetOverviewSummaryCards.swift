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
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
            SummaryCardView(
                title: "Total Budget",
                value: totalBudget,
                icon: "dollarsign.circle",
                color: .blue)

            SummaryCardView(
                title: "Total Expenses",
                value: totalExpenses,
                icon: "receipt",
                color: .orange)

            SummaryCardView(
                title: "Remaining",
                value: totalRemaining,
                icon: "target",
                color: totalRemaining >= 0 ? .green : .red)

            SummaryCardView(
                title: "Budget Items",
                value: Double(itemCount),
                icon: "list.bullet",
                color: .purple,
                formatAsCurrency: false)
        }
    }
}
