import Charts
import SwiftUI

struct BudgetCashFlowView: View {
    @StateObject private var budgetStore = BudgetStoreV2()
    @State private var selectedTimeframe: CashFlowTimeframe = .sixMonths
    @State private var showingProjections = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Cash Flow Summary Cards
                HStack(spacing: 16) {
                    CashFlowSummaryCard(
                        title: "Total Inflows",
                        amount: budgetStore.totalInflows,
                        color: .green,
                        icon: "arrow.down.circle.fill")

                    CashFlowSummaryCard(
                        title: "Total Outflows",
                        amount: budgetStore.totalOutflows,
                        color: .red,
                        icon: "arrow.up.circle.fill")

                    CashFlowSummaryCard(
                        title: "Net Cash Flow",
                        amount: budgetStore.netCashFlow,
                        color: budgetStore.netCashFlow >= 0 ? .green : .red,
                        icon: "dollarsign.circle.fill")
                }

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
            await budgetStore.loadCashFlowData()
        }
    }
}

// MARK: - Supporting Views

struct CashFlowSummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            Text(NumberFormatter.currency.string(from: NSNumber(value: amount)) ?? "$0")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

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
                    .foregroundStyle(.green)

                // Expense bars (negative values)
                BarMark(
                    x: .value("Month", dataPoint.month),
                    y: .value("Expenses", -dataPoint.expenses))
                    .foregroundStyle(.red)

                // Net cash flow line
                LineMark(
                    x: .value("Month", dataPoint.month),
                    y: .value("Net Flow", dataPoint.netFlow))
                    .foregroundStyle(.blue)
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
                        .foregroundColor(isIncome ? .green : .red)
                        .frame(width: 20)

                    Text(item.name)
                        .font(.subheadline)

                    Spacer()

                    Text(NumberFormatter.currency.string(from: NSNumber(value: item.amount)) ?? "$0")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isIncome ? .green : .red)
                }
                .padding(.vertical, 4)
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
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Your cash flow is looking healthy! No major issues detected.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
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
