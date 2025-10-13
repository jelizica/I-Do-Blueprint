// Extracted from BudgetDevelopmentView.swift

import SwiftUI

struct BudgetSummaryCardsSection: View {
    let totalWithoutTax: Double
    let totalTax: Double
    let totalWithTax: Double

    var body: some View {
        HStack(spacing: 16) {
            SummaryCardView(
                title: "Total Without Tax",
                value: totalWithoutTax,
                icon: "dollarsign.circle",
                color: .blue)

            SummaryCardView(
                title: "Total Tax",
                value: totalTax,
                icon: "percent",
                color: .orange)

            SummaryCardView(
                title: "Total With Tax",
                value: totalWithTax,
                icon: "calculator",
                color: .green)
        }
    }
}
