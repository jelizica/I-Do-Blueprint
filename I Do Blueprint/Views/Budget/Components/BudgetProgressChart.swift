import Charts
import SwiftUI

/// Bar chart showing budget progress by category
struct BudgetProgressChart: View {
    let categories: [BudgetCategory]
    let expenses: [Expense]

    private func projectedSpending(for categoryId: UUID) -> Double {
        let categoryExpenses = expenses.filter { $0.budgetCategoryId == categoryId }
        return categoryExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        if categories.isEmpty {
            ContentUnavailableView(
                "No Budget Categories",
                systemImage: "chart.bar.xaxis",
                description: Text("Add budget categories to see progress"))
        } else {
            Chart {
                ForEach(categories, id: \.id) { category in
                    let projectedAmount = projectedSpending(for: category.id)
                    let isOverBudget = projectedAmount > category.allocatedAmount

                    BarMark(
                        x: .value("Category", category.categoryName),
                        y: .value("Allocated", category.allocatedAmount))
                        .foregroundStyle(AppColors.Budget.allocated.opacity(0.3))

                    BarMark(
                        x: .value("Category", category.categoryName),
                        y: .value("Projected Spending", projectedAmount))
                        .foregroundStyle(isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.allocated)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(NumberFormatter.currencyShort.string(from: NSNumber(value: amount)) ?? "$0")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption)
                }
            }
        }
    }
}

