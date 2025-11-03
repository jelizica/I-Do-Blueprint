import SwiftUI

/// View displaying budget insights and recommendations
struct BudgetInsightsView: View {
    let categories: [BudgetCategory]
    let expenses: [Expense]
    let benchmarks: [CategoryBenchmark]
    let summary: BudgetSummary?

    @State private var showingCategorySheet = false
    @State private var showingPaymentSheet = false
    @State private var showingBudgetAllocationSheet = false

    private var insights: [BudgetInsight] {
        var results: [BudgetInsight] = []

        // Over budget categories
        let overBudgetCategories = categories.filter(\.isOverBudget)
        if !overBudgetCategories.isEmpty {
            results.append(BudgetInsight(
                type: InsightType.warning,
                title: "Categories Over Budget",
                description: "\(overBudgetCategories.count) categories are over budget. Consider reallocating funds or reducing expenses.",
                action: "Review Categories"))
        }

        // Overdue payments
        let overdueExpenses = expenses.filter(\.isOverdue)
        if !overdueExpenses.isEmpty {
            results.append(BudgetInsight(
                type: InsightType.alert,
                title: "Overdue Payments",
                description: "\(overdueExpenses.count) payments are overdue. Total amount: \(NumberFormatter.currency.string(from: NSNumber(value: overdueExpenses.reduce(0) { $0 + $1.remainingAmount })) ?? "$0")",
                action: "View Payments"))
        }

        // Budget allocation recommendations
        if let summary {
            let unallocatedAmount = summary.totalBudget - summary.totalAllocated
            if unallocatedAmount > 100 {
                results.append(BudgetInsight(
                    type: InsightType.info,
                    title: "Unallocated Budget",
                    description: "You have \(NumberFormatter.currency.string(from: NSNumber(value: unallocatedAmount)) ?? "$0") not allocated to any category.",
                    action: "Allocate Funds"))
            }
        }

        return results
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights & Recommendations")
                .font(.title2)
                .fontWeight(.semibold)

            if insights.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.Budget.underBudget)
                    Text("Your budget is looking good! No major issues detected.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(AppColors.Budget.underBudget.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(insights, id: \.title) { insight in
                    InsightRowView(
                        insight: insight,
                        onAction: { action in
                            handleInsightAction(action)
                        })
                }
            }
        }
        .sheet(isPresented: $showingCategorySheet) {
            BudgetCategoriesListView(
                categories: categories.filter(\.isOverBudget),
                title: "Over Budget Categories")
        }
        .sheet(isPresented: $showingPaymentSheet) {
            OverduePaymentsListView(
                expenses: expenses.filter(\.isOverdue))
        }
        .sheet(isPresented: $showingBudgetAllocationSheet) {
            BudgetAllocationGuideView(
                unallocatedAmount: summary.map { $0.totalBudget - $0.totalAllocated } ?? 0,
                categories: categories)
        }
    }

    private func handleInsightAction(_ action: String) {
        switch action {
        case "Review Categories":
            showingCategorySheet = true
        case "View Payments":
            showingPaymentSheet = true
        case "Allocate Funds":
            showingBudgetAllocationSheet = true
        default:
            break
        }
    }
}

struct BudgetInsight {
    let type: InsightType
    let title: String
    let description: String
    let action: String
}

struct InsightRowView: View {
    let insight: BudgetInsight
    let onAction: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.type.icon)
                .foregroundColor(insight.type.color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(insight.action) {
                onAction(insight.action)
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding()
        .background(insight.type.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

