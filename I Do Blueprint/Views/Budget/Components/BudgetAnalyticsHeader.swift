import SwiftUI

/// Header component for Budget Analytics displaying key metrics and quick insights
struct BudgetAnalyticsHeader: View {
    let summary: BudgetSummary?
    let stats: BudgetStats
    
    var body: some View {
        VStack(spacing: 16) {
            if let summary {
                // Using Component Library - StatsGridView
                StatsGridView(
                    stats: [
                        StatItem(
                            icon: "chart.pie.fill",
                            label: "Budget Utilization",
                            value: "\(Int(summary.percentageSpent))%",
                            color: summary.isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.allocated
                        ),
                        StatItem(
                            icon: "flame.fill",
                            label: "Monthly Burn Rate",
                            value: NumberFormatter.currency.string(from: NSNumber(value: stats.monthlyBurnRate)) ?? "$0",
                            color: AppColors.Budget.pending
                        ),
                        StatItem(
                            icon: "exclamationmark.triangle.fill",
                            label: "Categories Over Budget",
                            value: "\(stats.categoriesOverBudget)",
                            color: stats.categoriesOverBudget > 0 ? AppColors.Budget.overBudget : AppColors.Budget.underBudget
                        )
                    ],
                    columns: 3
                )
            }
            
            // Quick insights - Using Component Library
            if stats.projectedOverage > 0 {
                InfoCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Projected Overage",
                    content: NumberFormatter.currency.string(from: NSNumber(value: stats.projectedOverage)) ?? "$0",
                    color: AppColors.Budget.overBudget
                )
            }
        }
    }
}

