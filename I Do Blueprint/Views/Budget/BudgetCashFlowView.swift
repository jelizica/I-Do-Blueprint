import Charts
import SwiftUI

struct BudgetCashFlowView: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @State private var selectedTimeframe: CashFlowTimeframe = .sixMonths
    @State private var showingProjections = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Cash Flow Summary Cards - Using Component Library
                StatsGridView(
                    stats: [
                        StatItem(
                            icon: "arrow.down.circle.fill",
                            label: "Total Inflows",
                            value: NumberFormatter.currencyShort.string(from: NSNumber(value: budgetStore.totalInflows)) ?? "$0",
                            color: AppColors.Budget.income
                        ),
                        StatItem(
                            icon: "arrow.up.circle.fill",
                            label: "Total Outflows",
                            value: NumberFormatter.currencyShort.string(from: NSNumber(value: budgetStore.totalOutflows)) ?? "$0",
                            color: AppColors.Budget.expense
                        ),
                        StatItem(
                            icon: "dollarsign.circle.fill",
                            label: "Net Cash Flow",
                            value: NumberFormatter.currencyShort.string(from: NSNumber(value: budgetStore.netCashFlow)) ?? "$0",
                            color: budgetStore.netCashFlow >= 0 ? AppColors.Budget.income : AppColors.Budget.expense
                        )
                    ],
                    columns: 3
                )

                // Controls
                VStack(spacing: 12) {
                    HStack {
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(CashFlowTimeframe.allCases, id: \.self) { timeframe in
                                Text(timeframe.displayName).tag(timeframe)
                            }
                        }
                        .pickerStyle(.segmented)

                        Spacer()

                        Toggle("Show Projections", isOn: $showingProjections)
                            .toggleStyle(SwitchToggleStyle())
                    }
                }
                .padding(.horizontal)

                // Cash Flow Chart
                CashFlowChartView(
                    timeframe: selectedTimeframe,
                    showProjections: showingProjections,
                    cashFlowData: budgetStore.cashFlowData)

                // Detailed Cash Flow Breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text("Cash Flow Breakdown")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(spacing: 12) {
                        CashFlowSection(
                            title: "Income Sources",
                            items: budgetStore.incomeItems,
                            isIncome: true)

                        CashFlowSection(
                            title: "Expense Categories",
                            items: budgetStore.expenseItems,
                            isIncome: false)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Cash Flow Insights
                CashFlowInsightsView(insights: budgetStore.cashFlowInsights)
            }
            .padding()
        }
        .task {
            await budgetStore.refresh()
        }
    }
}

// MARK: - Supporting Views

// Note: CashFlowSummaryCard replaced with StatsGridView from component library

struct CashFlowChartView: View {
    let timeframe: CashFlowTimeframe
    let showProjections: Bool
    let cashFlowData: [CashFlowDataPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Cash Flow")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)

            Chart(cashFlowData, id: \.month) { dataPoint in
                // Income bars
                BarMark(
                    x: .value("Month", dataPoint.month),
                    y: .value("Income", dataPoint.income))
                    .foregroundStyle(AppColors.Budget.income)

                // Expense bars (negative values)
                BarMark(
                    x: .value("Month", dataPoint.month),
                    y: .value("Expenses", -dataPoint.expenses))
                    .foregroundStyle(AppColors.Budget.expense)

                // Net cash flow line
                LineMark(
                    x: .value("Month", dataPoint.month),
                    y: .value("Net Flow", dataPoint.netFlow))
                    .foregroundStyle(AppColors.Budget.allocated)
                    .symbol(.circle)
            }
            .frame(height: 300)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct CashFlowSection: View {
    let title: String
    let items: [CashFlowItem]
    let isIncome: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            ForEach(items, id: \.id) { item in
                HStack {
                    Image(systemName: item.icon)
                        .foregroundColor(isIncome ? AppColors.Budget.income : AppColors.Budget.expense)
                        .frame(width: 20)

                    Text(item.name)
                        .font(.subheadline)

                    Spacer()

                    Text(NumberFormatter.currencyShort.string(from: NSNumber(value: item.amount)) ?? "$0")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isIncome ? AppColors.Budget.income : AppColors.Budget.expense)
                }
                .padding(.vertical, Spacing.xs)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CashFlowInsightsView: View {
    let insights: [CashFlowInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cash Flow Insights")
                .font(.title2)
                .fontWeight(.semibold)

            ForEach(insights, id: \.id) { insight in
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
                }
                .padding()
                .background(insight.type.color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if insights.isEmpty {
                // Using Component Library - InfoCard
                InfoCard(
                    icon: "checkmark.circle.fill",
                    title: "Healthy Cash Flow",
                    content: "Your cash flow is looking healthy! No major issues detected.",
                    color: AppColors.Budget.income
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Types

enum CashFlowTimeframe: String, CaseIterable {
    case threeMonths = "3m"
    case sixMonths = "6m"
    case oneYear = "1y"
    case allTime = "all"

    var displayName: String {
        switch self {
        case .threeMonths: "3 Months"
        case .sixMonths: "6 Months"
        case .oneYear: "1 Year"
        case .allTime: "All Time"
        }
    }
}

struct CashFlowDataPoint {
    let month: String
    let income: Double
    let expenses: Double
    let netFlow: Double
}

struct CashFlowItem {
    let id = UUID()
    let name: String
    let amount: Double
    let icon: String
}

struct CashFlowInsight {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
}
