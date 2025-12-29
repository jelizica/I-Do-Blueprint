import Charts
import SwiftUI

struct BudgetAnalyticsView: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @State private var selectedTimeframe: AnalyticsTimeframe = .sixMonths
    @State private var selectedChartType: ChartType = .categoryBreakdown

    private let logger = AppLogger.ui

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Analytics header
                    BudgetAnalyticsHeader(
                        summary: budgetStore.budgetSummary,
                        stats: budgetStore.stats)

                    // Chart controls
                    VStack(spacing: 12) {
                        HStack {
                            Picker("Chart Type", selection: $selectedChartType) {
                                ForEach(ChartType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)

                            Spacer()

                            Picker("Timeframe", selection: $selectedTimeframe) {
                                ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                                    Text(timeframe.displayName).tag(timeframe)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .padding(.horizontal)

                    // Main chart
                    ChartContainerView(
                        chartType: selectedChartType,
                        timeframe: selectedTimeframe,
                        categories: budgetStore.categoryStore.categories,
                        expenses: budgetStore.expenseStore.expenses,
                        benchmarks: budgetStore.categoryBenchmarks)

                    // Insights and recommendations
                    BudgetInsightsView(
                        categories: budgetStore.categoryStore.categories,
                        expenses: budgetStore.expenseStore.expenses,
                        benchmarks: budgetStore.categoryBenchmarks,
                        summary: budgetStore.budgetSummary)
                }
                .padding()
            }
            .navigationTitle("Budget Analytics")
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    Button(action: {
                        Task {
                            await budgetStore.refresh()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await budgetStore.loadBudgetData(force: true)
        }
    }
}

