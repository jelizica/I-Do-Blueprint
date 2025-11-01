//
//  EnhancedBudgetCharts.swift
//  My Wedding Planning App
//
//  Enhanced budget visualizations using native Swift Charts
//

import AxisTooltip
import Charts
import SwiftUI

// MARK: - Enhanced Pie Chart with Animation

struct AnimatedBudgetPieChart: View {
    let categories: [BudgetCategory]
    @State private var selectedCategory: String?

    private var validCategories: [BudgetCategory] {
        categories.filter { $0.allocatedAmount > 0 }
    }

    private var selectedCategoryData: BudgetCategory? {
        guard let selectedCategory = selectedCategory else { return nil }
        return validCategories.first { $0.categoryName == selectedCategory }
    }

    var body: some View {
        VStack(spacing: 16) {
            if validCategories.isEmpty {
                Text("No budget allocations yet")
                    .foregroundColor(.secondary)
                    .frame(height: 300)
            } else {
                Chart(validCategories) { category in
                    SectorMark(
                        angle: .value("Amount", category.allocatedAmount),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5)
                        .foregroundStyle(Color(hex: category.color) ?? AppColors.Budget.allocated)
                        .opacity(selectedCategory == nil || selectedCategory == category.categoryName ? 1.0 : 0.5)
                }
                .chartAngleSelection(value: $selectedCategory)
                .chartBackground { _ in
                    GeometryReader { geometry in
                        if let selectedCategoryData = selectedCategoryData {
                            let frame = geometry.frame(in: .local)
                            let center = CGPoint(x: frame.midX, y: frame.midY)

                            VStack(spacing: 4) {
                                Text(selectedCategoryData.categoryName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(formatCurrency(selectedCategoryData.allocatedAmount))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: selectedCategoryData.color) ?? AppColors.Budget.allocated)
                            }
                            .position(center)
                        }
                    }
                }
                .frame(minWidth: 500, idealWidth: 700, minHeight: 500, idealHeight: 600)
            }
        }
        .padding()
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Enhanced Line Chart for Cash Flow

struct AnimatedCashFlowChart: View {
    let expenses: [Expense]
    @State private var selectedMonth: String?

    private var monthlyData: [(month: String, amount: Double)] {
        groupExpensesByMonth()
    }

    private var selectedAmount: Double? {
        guard let selectedMonth = selectedMonth else { return nil }
        return monthlyData.first { $0.month == selectedMonth }?.amount
    }

    var body: some View {
        VStack(spacing: 16) {
            if expenses.isEmpty {
                Text("No expenses recorded yet")
                    .foregroundColor(.secondary)
                    .frame(height: 300)
            } else {
                Chart(monthlyData, id: \.month) { data in
                    LineMark(
                        x: .value("Month", data.month),
                        y: .value("Amount", data.amount))
                        .foregroundStyle(AppColors.Budget.allocated)
                        .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Month", data.month),
                        y: .value("Amount", data.amount))
                        .foregroundStyle(AppColors.Budget.allocated.opacity(0.3))
                        .interpolationMethod(.catmullRom)

                    if let selectedMonth = selectedMonth, data.month == selectedMonth {
                        RuleMark(x: .value("Selected", selectedMonth))
                            .foregroundStyle(AppColors.Budget.allocated.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .top, spacing: 0) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(data.month)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatCurrency(data.amount))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppColors.Budget.allocated)
                                }
                                .padding(Spacing.sm)
                                .background(.background)
                                .cornerRadius(8)
                                .shadow(radius: 4)
                            }
                    }
                }
                .chartXSelection(value: $selectedMonth)
                .frame(minWidth: 500, idealWidth: 800, minHeight: 400, idealHeight: 500)
            }
        }
        .padding()
    }

    private func groupExpensesByMonth() -> [(month: String, amount: Double)] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"

        let grouped = Dictionary(grouping: expenses) { expense -> String in
            dateFormatter.string(from: expense.expenseDate)
        }

        return grouped.map { (month: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.month < $1.month }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Enhanced Bar Chart for Category Comparison

struct CategoryComparisonBarChart: View {
    let categories: [BudgetCategory]
    @State private var selectedCategory: String?

    private var selectedCategoryData: BudgetCategory? {
        guard let selectedCategory = selectedCategory else { return nil }
        return categories.first { $0.categoryName == selectedCategory }
    }

    var body: some View {
        VStack(spacing: 16) {
            if categories.isEmpty {
                Text("No budget categories yet")
                    .foregroundColor(.secondary)
                    .frame(height: 300)
            } else {
                Chart {
                    ForEach(categories) { category in
                        BarMark(
                            x: .value("Category", category.categoryName),
                            y: .value("Spent", category.spentAmount))
                            .foregroundStyle(spentPercentage(category) > 1.0 ? AppColors.Budget.overBudget : AppColors.Budget.underBudget)
                            .opacity(selectedCategory == nil || selectedCategory == category.categoryName ? 1.0 : 0.5)

                        // Add budget line marker
                        RuleMark(
                            y: .value("Budget", category.allocatedAmount))
                            .foregroundStyle(AppColors.Budget.allocated.opacity(0.3))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                            .annotation(position: .trailing, alignment: .leading) {
                                if category == categories.first {
                                    Text("Budget")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.Budget.allocated)
                                }
                            }
                    }
                }
                .chartXSelection(value: $selectedCategory)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let categoryName = value.as(String.self) {
                                Text(categoryName)
                                    .font(.caption)
                                    .rotationEffect(.degrees(-45))
                                    .frame(width: 60, alignment: .trailing)
                            }
                        }
                    }
                }
                .chartOverlay { _ in
                    GeometryReader { geometry in
                        if let selectedCategoryData = selectedCategoryData {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedCategoryData.categoryName)
                                    .font(.headline)
                                Text("Spent: \(formatCurrency(selectedCategoryData.spentAmount))")
                                    .font(.caption)
                                    .foregroundColor(spentPercentage(selectedCategoryData) > 1.0 ? AppColors.Budget.overBudget : AppColors.Budget.underBudget)
                                Text("Budget: \(formatCurrency(selectedCategoryData.allocatedAmount))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(Spacing.sm)
                            .background(.background)
                            .cornerRadius(8)
                            .shadow(radius: 4)
                            .position(x: geometry.size.width / 2, y: 40)
                        }
                    }
                }
                .frame(minWidth: 500, idealWidth: 800, minHeight: 450, idealHeight: 550)
            }
        }
    }

    private func spentPercentage(_ category: BudgetCategory) -> Double {
        guard category.allocatedAmount > 0 else { return 0 }
        return category.spentAmount / category.allocatedAmount
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
