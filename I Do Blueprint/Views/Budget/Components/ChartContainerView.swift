import SwiftUI

/// Container view that switches between different chart types
struct ChartContainerView: View {
    let chartType: ChartType
    let timeframe: AnalyticsTimeframe
    let categories: [BudgetCategory]
    let expenses: [Expense]
    let benchmarks: [CategoryBenchmark]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(chartType.displayName)
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            Group {
                switch chartType {
                case .categoryBreakdown:
                    // Enhanced animated pie chart from SwiftUICharts
                    AnimatedBudgetPieChart(categories: categories)
                case .spendingTrend:
                    // Enhanced animated cash flow chart
                    AnimatedCashFlowChart(expenses: filteredExpenses)
                case .budgetProgress:
                    // Enhanced bar chart for budget comparison
                    CategoryComparisonBarChart(categories: categories)
                case .benchmarkComparison:
                    // Keep original for benchmark comparison
                    BenchmarkComparisonChart(categories: categories, benchmarks: benchmarks)
                }
            }
            .frame(minHeight: 350)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var filteredExpenses: [Expense] {
        let cutoffDate = Calendar.current
            .date(byAdding: timeframe.dateComponent, value: -timeframe.value, to: Date()) ?? Date()
        return expenses.filter { expense in
            guard let approvedAt = expense.approvedAt else { return false }
            return approvedAt >= cutoffDate
        }
    }
}

enum ChartType: String, CaseIterable {
    case categoryBreakdown = "category_breakdown"
    case spendingTrend = "spending_trend"
    case budgetProgress = "budget_progress"
    case benchmarkComparison = "benchmark_comparison"
    
    var displayName: String {
        switch self {
        case .categoryBreakdown: "Category Breakdown"
        case .spendingTrend: "Spending Trend"
        case .budgetProgress: "Budget Progress"
        case .benchmarkComparison: "vs Benchmarks"
        }
    }
}

enum AnalyticsTimeframe: String, CaseIterable {
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
    
    var dateComponent: Calendar.Component {
        switch self {
        case .threeMonths, .sixMonths: .month
        case .oneYear: .year
        case .allTime: .year
        }
    }
    
    var value: Int {
        switch self {
        case .threeMonths: 3
        case .sixMonths: 6
        case .oneYear: 1
        case .allTime: 10
        }
    }
}

