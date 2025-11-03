import SwiftUI

/// Statistics cards section for expense reports
struct ExpenseStatisticsCards: View {
    let statistics: ExpenseStatistics

    var body: some View {
        // Using Component Library - StatsGridView
        StatsGridView(
            stats: [
                StatItem(
                    icon: "receipt.fill",
                    label: "Total Expenses",
                    value: statistics.totalExpenses.formatted(.currency(code: "USD")),
                    color: AppColors.Budget.allocated
                ),
                StatItem(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Average Transaction",
                    value: statistics.averageAmount.formatted(.currency(code: "USD")),
                    color: AppColors.Budget.income
                ),
                StatItem(
                    icon: "tag.fill",
                    label: "Top Category",
                    value: statistics.topCategory.name,
                    color: AppColors.Budget.pending
                ),
                StatItem(
                    icon: "checkmark.circle.fill",
                    label: "Payment Status",
                    value: "\(statistics.statusCounts.paid) Paid",
                    color: .purple
                )
            ],
            columns: 2
        )
    }
}

// Note: StatisticCard replaced with StatsGridView from component library
