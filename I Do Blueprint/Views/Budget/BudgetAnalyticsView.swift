import Charts
import SwiftUI

struct BudgetAnalyticsView: View {
    @StateObject private var budgetStore = BudgetStoreV2()
    @State private var selectedTimeframe: AnalyticsTimeframe = .sixMonths
    @State private var selectedChartType: ChartType = .categoryBreakdown

    private let logger = AppLogger.ui

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Analytics header
                    AnalyticsHeaderView(
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
                        categories: budgetStore.categories,
                        expenses: budgetStore.expenses,
                        benchmarks: budgetStore.categoryBenchmarks)

                    // Insights and recommendations
                    BudgetInsightsView(
                        categories: budgetStore.categories,
                        expenses: budgetStore.expenses,
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
                            await budgetStore.refreshBudgetData()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await budgetStore.loadBudgetData()
        }
    }
}

// MARK: - Analytics Header

struct AnalyticsHeaderView: View {
    let summary: BudgetSummary?
    let stats: BudgetStats

    var body: some View {
        VStack(spacing: 16) {
            if let summary {
                HStack(spacing: 20) {
                    AnalyticsCard(
                        title: "Budget Utilization",
                        value: "\(Int(summary.percentageSpent))%",
                        subtitle: "of total budget",
                        color: summary.isOverBudget ? .red : .blue,
                        icon: "chart.pie.fill")

                    AnalyticsCard(
                        title: "Monthly Burn Rate",
                        value: NumberFormatter.currency.string(from: NSNumber(value: stats.monthlyBurnRate)) ?? "$0",
                        subtitle: "last 30 days",
                        color: .orange,
                        icon: "flame.fill")

                    AnalyticsCard(
                        title: "Categories Over Budget",
                        value: "\(stats.categoriesOverBudget)",
                        subtitle: "of \(stats.totalCategories) total",
                        color: stats.categoriesOverBudget > 0 ? .red : .green,
                        icon: "exclamationmark.triangle.fill")
                }
            }

            // Quick insights
            if stats.projectedOverage > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(
                        "Projected overage: \(NumberFormatter.currency.string(from: NSNumber(value: stats.projectedOverage)) ?? "$0")")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Chart Container

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

// MARK: - Individual Charts

struct CategoryBreakdownChart: View {
    let categories: [BudgetCategory]
    let expenses: [Expense]

    @State private var selectedCategory: (category: BudgetCategory, spending: Double)?
    @State private var showTooltip = false

    private let logger = AppLogger.ui

    private func projectedSpending(for categoryId: UUID) -> Double {
        let categoryExpenses = expenses.filter { $0.budgetCategoryId == categoryId }
        let total = categoryExpenses.reduce(0) { $0 + $1.amount }

        if total > 0 {
            logger.debug("Chart - Category \(categoryId): \(categoryExpenses.count) expenses = $\(total)")
        }

        return total
    }

    private var categoriesWithSpending: [(category: BudgetCategory, spending: Double)] {
        logger.debug("Chart Debug - Categories: \(categories.count), Expenses: \(expenses.count)")
        if !categories.isEmpty {
            logger.debug("First category: \(categories[0].categoryName) (ID: \(categories[0].id))")
        }
        if !expenses.isEmpty {
            logger.debug("First expense: \(expenses[0].expenseName) -> Category ID: \(expenses[0].budgetCategoryId)")
        }

        let result = categories.compactMap { category in
            let spending = projectedSpending(for: category.id)
            return spending > 0 ? (category: category, spending: spending) : nil
        }

        logger.debug("Final result: \(result.count) categories with spending")
        return result
    }

    private var totalSpending: Double {
        categoriesWithSpending.reduce(0) { $0 + $1.spending }
    }

    private func categoryAtLocation(
        _ location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy) -> (category: BudgetCategory, spending: Double)? {
        // Convert location to chart coordinate space
        guard let plotFrame = proxy.plotFrame else { return nil }
        let plotRect = geometry[plotFrame]
        let center = CGPoint(
            x: plotRect.midX,
            y: plotRect.midY)

        // Calculate angle from center
        let deltaX = location.x - center.x
        let deltaY = location.y - center.y
        let angle = atan2(deltaY, deltaX)
        let normalizedAngle = angle < 0 ? angle + 2 * .pi : angle
        let angleDegrees = normalizedAngle * 180 / .pi

        // Find which category this angle corresponds to
        var currentAngle: Double = -90 // Start from top (12 o'clock position)
        for item in categoriesWithSpending {
            let itemAngle = (item.spending / totalSpending) * 360
            let startAngle = currentAngle
            let endAngle = currentAngle + itemAngle

            // Normalize angles for comparison
            let normalizedClickAngle = angleDegrees >= 270 ? angleDegrees - 360 : angleDegrees
            let normalizedStartAngle = startAngle >= 270 ? startAngle - 360 : startAngle
            let normalizedEndAngle = endAngle >= 270 ? endAngle - 360 : endAngle

            if normalizedClickAngle >= normalizedStartAngle, normalizedClickAngle < normalizedEndAngle {
                return item
            }
            currentAngle += itemAngle
        }

        return nil
    }

    var body: some View {
        if categoriesWithSpending.isEmpty {
            ContentUnavailableView(
                "No Budget Data",
                systemImage: "chart.pie",
                description: Text("Add expenses to see category breakdown"))
        } else {
            ZStack {
                Chart(categoriesWithSpending, id: \.category.id) { item in
                    SectorMark(
                        angle: .value("Projected Spending", item.spending),
                        innerRadius: .ratio(0.5),
                        angularInset: 1)
                        .foregroundStyle(Color(hex: item.category.color) ?? .blue)
                        .opacity(selectedCategory?.category.id == item.category.id ? 1.0 : 0.8)
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if let tappedCategory = categoryAtLocation(
                                        location,
                                        proxy: proxy,
                                        geometry: geometry) {
                                        if selectedCategory?.category.id == tappedCategory.category.id {
                                            // Deselect if same category is tapped
                                            selectedCategory = nil
                                            showTooltip = false
                                        } else {
                                            // Select new category
                                            selectedCategory = tappedCategory
                                            showTooltip = true
                                        }
                                    } else {
                                        // Deselect if tapped outside
                                        selectedCategory = nil
                                        showTooltip = false
                                    }
                                }
                            }
                    }
                }

                // Tap tooltip
                if let selectedItem = selectedCategory, showTooltip {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: selectedItem.category.color) ?? .blue)
                                .frame(width: 12, height: 12)
                            Text(selectedItem.category.categoryName)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }

                        Text(
                            "Projected Spending: \(NumberFormatter.currency.string(from: NSNumber(value: selectedItem.spending)) ?? "$0")")
                            .font(.subheadline)

                        Text(
                            "Allocated: \(NumberFormatter.currency.string(from: NSNumber(value: selectedItem.category.allocatedAmount)) ?? "$0")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        let percentage = totalSpending > 0 ? (selectedItem.spending / totalSpending) * 100 : 0
                        Text("Share: \(String(format: "%.1f", percentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if selectedItem.spending > selectedItem.category.allocatedAmount {
                            Text("Over Budget")
                                .font(.caption)
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                        }

                        Text("Tap to dismiss")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 2)
                    }
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 4)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .chartLegend(position: .bottom, alignment: .center) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(categoriesWithSpending, id: \.category.id) { item in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: item.category.color) ?? .blue)
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.category.categoryName)
                                    .font(.caption)
                                    .lineLimit(1)
                                Text(NumberFormatter.currency.string(from: NSNumber(value: item.spending)) ?? "$0")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .opacity(selectedCategory?.category.id == item.category.id ? 1.0 : 0.7)
                        .scaleEffect(selectedCategory?.category.id == item.category.id ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: selectedCategory?.category.id)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedCategory?.category.id == item.category.id {
                                    selectedCategory = nil
                                    showTooltip = false
                                } else {
                                    selectedCategory = item
                                    showTooltip = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SpendingTrendChart: View {
    let expenses: [Expense]
    let timeframe: AnalyticsTimeframe

    private var monthlySpending: [MonthlySpending] {
        let groupedExpenses = Dictionary(grouping: expenses) { expense in
            guard let approvedAt = expense.approvedAt else { return "" }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            return formatter.string(from: approvedAt)
        }

        return groupedExpenses.compactMap { key, expenses in
            guard !key.isEmpty else { return nil }
            let total = expenses.reduce(0) { $0 + $1.paidAmount }
            return MonthlySpending(month: key, amount: total)
        }.sorted { $0.month < $1.month }
    }

    var body: some View {
        if monthlySpending.isEmpty {
            ContentUnavailableView(
                "No Spending Data",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("Record payments to see spending trends"))
        } else {
            Chart(monthlySpending, id: \.month) { data in
                LineMark(
                    x: .value("Month", data.month),
                    y: .value("Amount", data.amount))
                    .foregroundStyle(.blue)
                    .symbol(.circle)

                AreaMark(
                    x: .value("Month", data.month),
                    y: .value("Amount", data.amount))
                    .foregroundStyle(.blue.opacity(0.3))
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
        }
    }
}

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
                        .foregroundStyle(.blue.opacity(0.3))

                    BarMark(
                        x: .value("Category", category.categoryName),
                        y: .value("Projected Spending", projectedAmount))
                        .foregroundStyle(isOverBudget ? .red : .blue)
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

struct BenchmarkComparisonChart: View {
    let categories: [BudgetCategory]
    let benchmarks: [CategoryBenchmark]

    private var comparisonData: [BenchmarkComparison] {
        categories.compactMap { category in
            guard let benchmark = benchmarks.first(where: { $0.categoryName == category.categoryName }),
                  let summary = getBudgetSummary() else { return nil }

            let actualPercentage = (category.allocatedAmount / summary.totalBudget) * 100
            return BenchmarkComparison(
                categoryName: category.categoryName,
                actualPercentage: actualPercentage,
                typicalPercentage: benchmark.typicalPercentage,
                color: category.color)
        }
    }

    var body: some View {
        if comparisonData.isEmpty {
            ContentUnavailableView(
                "No Benchmark Data",
                systemImage: "chart.bar.xaxis",
                description: Text("Benchmark data will be available once categories are set up"))
        } else {
            Chart {
                ForEach(comparisonData, id: \.categoryName) { data in
                    BarMark(
                        x: .value("Category", data.categoryName),
                        y: .value("Typical", data.typicalPercentage))
                        .foregroundStyle(.gray.opacity(0.5))

                    BarMark(
                        x: .value("Category", data.categoryName),
                        y: .value("Your Budget", data.actualPercentage))
                        .foregroundStyle(Color(hex: data.color) ?? .blue)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let percentage = value.as(Double.self) {
                            Text("\(Int(percentage))%")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }

    private func getBudgetSummary() -> BudgetSummary? {
        // In a real implementation, this would come from the budget store
        // For now, calculate from categories
        let totalBudget = categories.reduce(0) { $0 + $1.allocatedAmount }
        guard totalBudget > 0 else { return nil }

        return BudgetSummary(
            id: UUID(),
            coupleId: UUID(),
            totalBudget: totalBudget,
            baseBudget: totalBudget,
            currency: "USD",
            weddingDate: nil,
            notes: nil,
            includesEngagementRings: false,
            engagementRingAmount: 0.0,
            createdAt: Date(),
            updatedAt: Date())
    }
}

// MARK: - Budget Insights

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
                        .foregroundColor(.green)
                    Text("Your budget is looking good! No major issues detected.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
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

// MARK: - Supporting Types

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

struct MonthlySpending {
    let month: String
    let amount: Double
}

struct BenchmarkComparison {
    let categoryName: String
    let actualPercentage: Double
    let typicalPercentage: Double
    let color: String
}

struct BudgetInsight {
    let type: InsightType
    let title: String
    let description: String
    let action: String
}

// MARK: - Insight Action Views

struct BudgetCategoriesListView: View {
    let categories: [BudgetCategory]
    let title: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(category.categoryName)
                                .font(.headline)

                            Spacer()

                            if category.isOverBudget {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                            }
                        }

                        HStack {
                            Text("Allocated:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(NumberFormatter.currency.string(from: NSNumber(value: category.allocatedAmount)) ?? "$0")
                                .font(.caption)
                                .fontWeight(.medium)

                            Spacer()

                            Text("Spent:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(NumberFormatter.currency.string(from: NSNumber(value: category.spentAmount)) ?? "$0")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(category.isOverBudget ? .red : .primary)
                        }

                        if category.isOverBudget {
                            let overAmount = category.spentAmount - category.allocatedAmount
                            Text("Over by: \(NumberFormatter.currency.string(from: NSNumber(value: overAmount)) ?? "$0")")
                                .font(.caption)
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct OverduePaymentsListView: View {
    let expenses: [Expense]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(expenses) { expense in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(expense.expenseName)
                                .font(.headline)

                            Spacer()

                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                        }

                        if let vendor = expense.vendorName, !vendor.isEmpty {
                            Text("Vendor: \(vendor)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            if let dueDate = expense.dueDate {
                                Text("Due: \(dueDate, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.red)

                                Spacer()
                            }

                            Text(NumberFormatter.currency.string(from: NSNumber(value: expense.remainingAmount)) ?? "$0")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }

                        let daysOverdue = expense.dueDate.map { Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0 } ?? 0
                        if daysOverdue > 0 {
                            Text("\(daysOverdue) day\(daysOverdue == 1 ? "" : "s") overdue")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Overdue Payments")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BudgetAllocationGuideView: View {
    let unallocatedAmount: Double
    let categories: [BudgetCategory]

    @Environment(\.dismiss) private var dismiss

    private var recommendations: [AllocationRecommendation] {
        // Calculate recommendations based on typical wedding budget percentages
        let typicalAllocations: [String: Double] = [
            "Venue": 0.30,
            "Catering": 0.25,
            "Photography": 0.10,
            "Music/Entertainment": 0.08,
            "Flowers": 0.07,
            "Attire": 0.05,
            "Other": 0.15
        ]

        return categories.compactMap { category in
            if let typical = typicalAllocations[category.categoryName] {
                let suggestedAmount = unallocatedAmount * typical
                if suggestedAmount > 10 { // Only suggest if meaningful amount
                    return AllocationRecommendation(
                        categoryName: category.categoryName,
                        currentAllocation: category.allocatedAmount,
                        suggestedAllocation: suggestedAmount,
                        percentage: typical)
                }
            }
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Unallocated amount header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available to Allocate")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(NumberFormatter.currency.string(from: NSNumber(value: unallocatedAmount)) ?? "$0")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Divider()

                    // Recommendations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggested Allocation")
                            .font(.title2)
                            .fontWeight(.semibold)

                        if recommendations.isEmpty {
                            Text("Create budget categories to see allocation recommendations.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(recommendations, id: \.categoryName) { recommendation in
                                RecommendationRow(recommendation: recommendation)
                            }
                        }
                    }

                    Divider()

                    // Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips")
                            .font(.title3)
                            .fontWeight(.semibold)

                        TipRow(
                            icon: "lightbulb.fill",
                            text: "Allocate 10-15% as a contingency buffer for unexpected expenses.")

                        TipRow(
                            icon: "chart.pie.fill",
                            text: "Review your allocations monthly and adjust as needed based on actual spending.")

                        TipRow(
                            icon: "dollarsign.circle.fill",
                            text: "Prioritize must-have categories before nice-to-have items.")
                    }
                }
                .padding()
            }
            .navigationTitle("Budget Allocation Guide")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RecommendationRow: View {
    let recommendation: AllocationRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.categoryName)
                    .font(.headline)

                Spacer()

                Text("\(Int(recommendation.percentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Current:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(NumberFormatter.currency.string(from: NSNumber(value: recommendation.currentAllocation)) ?? "$0")
                    .font(.caption)

                Spacer()

                Text("Suggested:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(NumberFormatter.currency.string(from: NSNumber(value: recommendation.suggestedAllocation)) ?? "$0")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AllocationRecommendation {
    let categoryName: String
    let currentAllocation: Double
    let suggestedAllocation: Double
    let percentage: Double
}

// MARK: - Extensions

extension NumberFormatter {
    static let currencyShort: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

#Preview {
    BudgetAnalyticsView()
}
