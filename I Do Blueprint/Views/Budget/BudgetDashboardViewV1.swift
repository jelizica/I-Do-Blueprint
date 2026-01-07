//
//  BudgetDashboardViewV1.swift
//  I Do Blueprint
//
//  Budget Dashboard - Main financial overview with summary cards,
//  charts, affordability tracking, upcoming payments, and quick actions
//
//  Created with reference to HTML mockup: code.html
//

import Charts
import SwiftUI

// MARK: - Main Dashboard View

@MainActor
struct BudgetDashboardViewV1: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @Binding var currentPage: BudgetPage

    // State
    @State private var isLoading = true
    @State private var selectedChartCategory: String?

    private let logger = AppLogger.ui

    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.huge
            let availableWidth = geometry.size.width - (horizontalPadding * 2)

            VStack(spacing: 0) {
                // Header
                BudgetDashboardHeader(
                    windowSize: windowSize,
                    currentPage: $currentPage
                )
                .padding(.horizontal, horizontalPadding)
                .padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)

                if isLoading {
                    loadingView
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: windowSize == .compact ? Spacing.lg : Spacing.xl) {
                            // Summary Cards Row
                            BudgetSummaryCardsRow(
                                windowSize: windowSize,
                                totalBudget: budgetStore.actualTotalBudget,
                                totalSpent: budgetStore.totalSpent,
                                remainingBudget: budgetStore.remainingBudget,
                                percentageSpent: budgetStore.percentageSpent,
                                onNavigate: { page in currentPage = page }
                            )

                            // Charts Section (2-column on regular+)
                            ChartsSection(
                                windowSize: windowSize,
                                categories: budgetStore.categoryStore.categories,
                                categoryBudgetMetrics: budgetStore.categoryBudgetMetrics,
                                expenses: budgetStore.expenseStore.expenses
                            )

                            // Financial Planning Section
                            FinancialPlanningSection(
                                windowSize: windowSize,
                                affordability: budgetStore.affordability,
                                gifts: budgetStore.gifts,
                                onNavigateToCalculator: { currentPage = .calculator },
                                onNavigateToGifts: { currentPage = .moneyTracker }
                            )

                            // Upcoming Payments Table
                            UpcomingPaymentsSection(
                                windowSize: windowSize,
                                upcomingPayments: budgetStore.payments.upcomingPayments,
                                onNavigate: { page in currentPage = page }
                            )

                            // Bottom Row: Needs Approval + Quick Tasks
                            BottomActionsRow(
                                windowSize: windowSize,
                                pendingPayments: budgetStore.payments.pendingPayments,
                                onNavigate: { page in currentPage = page }
                            )
                        }
                        .frame(width: availableWidth)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, windowSize == .compact ? Spacing.md : Spacing.lg)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .task {
            await loadDashboardData()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading budget data...")
                .font(Typography.bodyRegular)
                .foregroundStyle(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadDashboardData() async {
        isLoading = true
        await budgetStore.loadBudgetData()
        isLoading = false
    }
}

// MARK: - Header Component

struct BudgetDashboardHeader: View {
    let windowSize: WindowSize
    @Binding var currentPage: BudgetPage

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Budget Dashboard")
                    .font(Typography.title1)
                    .foregroundStyle(SemanticColors.textPrimary)

                Text("Overview of your wedding finances")
                    .font(Typography.bodyRegular)
                    .foregroundStyle(SemanticColors.textSecondary)
            }

            Spacer()

            // Navigation dropdown
            Menu {
                ForEach(BudgetPage.allCases) { page in
                    Button(action: { currentPage = page }) {
                        Label(page.rawValue, systemImage: page.icon)
                    }
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Text("Navigate")
                        .font(Typography.subheading)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(CornerRadius.md)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, Spacing.lg)
    }
}

// MARK: - Summary Cards Row

struct BudgetSummaryCardsRow: View {
    let windowSize: WindowSize
    let totalBudget: Double
    let totalSpent: Double
    let remainingBudget: Double
    let percentageSpent: Double
    let onNavigate: (BudgetPage) -> Void

    private var isOverBudget: Bool {
        remainingBudget < 0
    }

    var body: some View {
        let columns: [GridItem] = {
            switch windowSize {
            case .compact:
                return [GridItem(.flexible())]
            case .regular:
                return [GridItem(.flexible()), GridItem(.flexible())]
            case .large:
                return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            }
        }()

        LazyVGrid(columns: columns, spacing: Spacing.lg) {
            // Total Budget Card
            BudgetDashboardSummaryCard(
                title: "Total Budget",
                value: formatCurrency(totalBudget),
                icon: "dollarsign.circle.fill",
                color: AppColors.Budget.allocated,
                subtitle: "Planned spending",
                onTap: { onNavigate(.budgetBuilder) }
            )

            // Total Spent Card
            BudgetDashboardSummaryCard(
                title: "Total Spent",
                value: formatCurrency(totalSpent),
                icon: "creditcard.fill",
                color: isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.underBudget,
                subtitle: "\(Int(percentageSpent))% of budget",
                progress: min(percentageSpent / 100, 1.0),
                onTap: { onNavigate(.expenseTracker) }
            )

            // Remaining Budget Card
            BudgetDashboardSummaryCard(
                title: "Remaining",
                value: formatCurrency(abs(remainingBudget)),
                icon: "banknote.fill",
                color: isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.pending,
                subtitle: isOverBudget ? "Over budget" : "Available to spend",
                isNegative: isOverBudget,
                onTap: { onNavigate(.budgetOverview) }
            )

            // Budget Health Card
            BudgetDashboardSummaryCard(
                title: "Budget Health",
                value: budgetHealthLabel,
                icon: budgetHealthIcon,
                color: budgetHealthColor,
                subtitle: budgetHealthSubtitle,
                onTap: { onNavigate(.analytics) }
            )
        }
    }

    private var budgetHealthLabel: String {
        if percentageSpent > 100 {
            return "Over Budget"
        } else if percentageSpent > 85 {
            return "At Risk"
        } else if percentageSpent > 70 {
            return "On Track"
        } else {
            return "Healthy"
        }
    }

    private var budgetHealthIcon: String {
        if percentageSpent > 100 {
            return "exclamationmark.triangle.fill"
        } else if percentageSpent > 85 {
            return "exclamationmark.circle.fill"
        } else if percentageSpent > 70 {
            return "checkmark.circle.fill"
        } else {
            return "heart.fill"
        }
    }

    private var budgetHealthColor: Color {
        if percentageSpent > 100 {
            return AppColors.Budget.overBudget
        } else if percentageSpent > 85 {
            return AppColors.warning
        } else if percentageSpent > 70 {
            return AppColors.Budget.pending
        } else {
            return AppColors.Budget.underBudget
        }
    }

    private var budgetHealthSubtitle: String {
        if percentageSpent > 100 {
            return "Review expenses"
        } else if percentageSpent > 85 {
            return "Monitor closely"
        } else if percentageSpent > 70 {
            return "Good progress"
        } else {
            return "Great job!"
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Budget Dashboard Summary Card

struct BudgetDashboardSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String = ""
    var progress: Double? = nil
    var isNegative: Bool = false
    var onTap: (() -> Void)? = nil

    @State private var isHovered = false

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(color)

                    Spacer()

                    if isNegative {
                        Image(systemName: "arrow.down.right")
                            .font(.caption)
                            .foregroundStyle(AppColors.Budget.overBudget)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(Typography.caption)
                        .foregroundStyle(SemanticColors.textSecondary)

                    Text(value)
                        .font(Typography.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(SemanticColors.textPrimary)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(Typography.caption)
                            .foregroundStyle(SemanticColors.textTertiary)
                    }

                    if let progress {
                        ProgressView(value: progress)
                            .tint(color)
                            .scaleEffect(y: 0.5)
                    }
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: isHovered ? color.opacity(0.2) : .clear, radius: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(isHovered ? color.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint(subtitle)
    }
}

// MARK: - Charts Section

struct ChartsSection: View {
    let windowSize: WindowSize
    let categories: [BudgetCategory]
    let categoryBudgetMetrics: [CategoryBudgetMetrics]
    let expenses: [Expense]

    var body: some View {
        let columns: [GridItem] = windowSize == .compact
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]

        LazyVGrid(columns: columns, spacing: Spacing.lg) {
            // Interactive Category Distribution Chart (Grouped Bar)
            // Uses calculated metrics from RPC function for accurate values
            BudgetChartCard(
                title: "Budget by Category",
                icon: "chart.bar.fill"
            ) {
                InteractiveBudgetCategoryChart(metrics: categoryBudgetMetrics)
            }

            // Spending Distribution Donut
            // Uses CategoryBudgetMetrics for accurate spend data from RPC
            BudgetChartCard(
                title: "Spend Distribution",
                icon: "chart.pie.fill"
            ) {
                SpendDistributionDonut(metrics: categoryBudgetMetrics)
            }
        }
    }
}

// MARK: - Budget Chart Card Wrapper

struct BudgetChartCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.Budget.allocated)
                Text(title)
                    .font(Typography.heading)
                    .foregroundStyle(SemanticColors.textPrimary)
                Spacer()
            }

            content()
                .frame(minHeight: 200)
        }
        .padding(Spacing.lg)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Category Type for Chart Filtering

enum BudgetCategoryType: String, CaseIterable {
    case parent = "Parent"
    case leaf = "Leaf"

    var description: String {
        switch self {
        case .parent: return "Categories with sub-categories"
        case .leaf: return "Standalone categories"
        }
    }
}

// MARK: - Chart Data Point for Grouped Bar Chart

struct CategoryChartDataPoint: Identifiable {
    let id = UUID()
    let categoryName: String
    let categoryColor: Color
    let seriesType: BudgetSeriesType
    let amount: Double
}

enum BudgetSeriesType: String, CaseIterable {
    case allocated = "Allocated"
    case forecasted = "Forecasted"
    case spent = "Spent"

    var color: Color {
        switch self {
        case .allocated: return Color.fromHex("3B82F6") // Blue
        case .forecasted: return Color.fromHex("EC4899") // Magenta/Pink
        case .spent: return Color.fromHex("22C55E") // Green
        }
    }
}

// MARK: - Interactive Grouped Bar Chart

struct InteractiveBudgetCategoryChart: View {
    /// Calculated metrics from the database RPC function (preferred - uses live data)
    let metrics: [CategoryBudgetMetrics]

    @State private var selectedCategoryType: BudgetCategoryType = .parent
    @State private var hoveredCategory: String?
    @State private var hoveredDataPoint: CategoryChartDataPoint?
    @State private var tooltipPosition: CGPoint = .zero
    @State private var isTooltipVisible: Bool = false
    @State private var hoverDebounceTask: Task<Void, Never>?

    // Identify parent categories (have children based on parentCategoryId being nil)
    private var parentCategoryIds: Set<UUID> {
        Set(metrics.compactMap { $0.parentCategoryId })
    }

    // Parent categories: top-level with children (categories that have children pointing to them)
    private var parentCategories: [CategoryBudgetMetrics] {
        metrics.filter { metric in
            metric.isParentCategory && parentCategoryIds.contains(metric.categoryId)
        }
        .sorted { $0.allocated > $1.allocated }
    }

    // Leaf categories: top-level with NO children (standalone)
    private var leafCategories: [CategoryBudgetMetrics] {
        metrics.filter { metric in
            metric.isParentCategory && !parentCategoryIds.contains(metric.categoryId)
        }
        .sorted { $0.allocated > $1.allocated }
    }

    private var displayCategories: [CategoryBudgetMetrics] {
        let cats = selectedCategoryType == .parent ? parentCategories : leafCategories
        return Array(cats.prefix(6)) // Top 6 for readability
    }

    private var chartDataPoints: [CategoryChartDataPoint] {
        displayCategories.flatMap { metric in
            BudgetSeriesType.allCases.map { series in
                CategoryChartDataPoint(
                    categoryName: metric.categoryName,
                    categoryColor: Color(hex: metric.color) ?? AppColors.Budget.allocated,
                    seriesType: series,
                    amount: amountForSeries(metric: metric, series: series)
                )
            }
        }
    }

    private func amountForSeries(metric: CategoryBudgetMetrics, series: BudgetSeriesType) -> Double {
        switch series {
        case .allocated: return metric.allocated
        case .forecasted: return metric.forecasted
        case .spent: return metric.spent
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Category Type Toggle
            categoryTypeToggle

            if displayCategories.isEmpty {
                emptyState
            } else {
                ZStack(alignment: .topLeading) {
                    // Main Chart
                    chartView

                    // Tooltip overlay - allowsHitTesting(false) prevents tooltip from intercepting hover events
                    if isTooltipVisible, let dataPoint = hoveredDataPoint {
                        tooltipView(for: dataPoint)
                            .position(tooltipPosition)
                            .allowsHitTesting(false)
                            .transition(.opacity.animation(.easeInOut(duration: 0.15)))
                    }
                }
            }

            // Legend
            legendView
        }
    }

    // MARK: - Category Type Toggle

    private var categoryTypeToggle: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(BudgetCategoryType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategoryType = type
                        hoveredDataPoint = nil
                    }
                } label: {
                    Text(type.rawValue)
                        .font(Typography.caption.weight(.medium))
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            selectedCategoryType == type
                                ? AppColors.Budget.allocated
                                : Color.clear
                        )
                        .foregroundStyle(
                            selectedCategoryType == type
                                ? .white
                                : SemanticColors.textSecondary
                        )
                        .cornerRadius(CornerRadius.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .stroke(
                                    selectedCategoryType == type
                                        ? Color.clear
                                        : SemanticColors.borderLight,
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
                .help(type.description)
            }
            Spacer()
        }
    }

    // MARK: - Chart View

    private var chartView: some View {
        GeometryReader { geometry in
            Chart(chartDataPoints) { dataPoint in
                BarMark(
                    x: .value("Category", dataPoint.categoryName),
                    y: .value("Amount", dataPoint.amount)
                )
                .foregroundStyle(by: .value("Series", dataPoint.seriesType.rawValue))
                .position(by: .value("Series", dataPoint.seriesType.rawValue))
                .cornerRadius(3)
                .opacity(
                    hoveredCategory == nil || hoveredCategory == dataPoint.categoryName
                        ? 1.0
                        : 0.4
                )
            }
            .chartForegroundStyleScale([
                BudgetSeriesType.allocated.rawValue: BudgetSeriesType.allocated.color,
                BudgetSeriesType.forecasted.rawValue: BudgetSeriesType.forecasted.color,
                BudgetSeriesType.spent.rawValue: BudgetSeriesType.spent.color
            ])
            .chartLegend(.hidden) // We use custom legend
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(SemanticColors.borderLight)
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(formatShortCurrency(amount))
                                .font(.caption2)
                                .foregroundStyle(SemanticColors.textSecondary)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { overlayGeometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    hoverDebounceTask?.cancel()
                                    handleHover(at: value.location, in: proxy, geometry: overlayGeometry)
                                    isTooltipVisible = true
                                }
                                .onEnded { _ in
                                    // Use same debounce pattern for touch/drag
                                    hoverDebounceTask?.cancel()
                                    hoverDebounceTask = Task {
                                        try? await Task.sleep(for: .milliseconds(100))
                                        if !Task.isCancelled {
                                            hoveredCategory = nil
                                            hoveredDataPoint = nil
                                            isTooltipVisible = false
                                        }
                                    }
                                }
                        )
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                // Cancel any pending hide operation
                                hoverDebounceTask?.cancel()
                                handleHover(at: location, in: proxy, geometry: overlayGeometry)
                                isTooltipVisible = true
                            case .ended:
                                // Debounce the hide to prevent flickering
                                hoverDebounceTask?.cancel()
                                hoverDebounceTask = Task {
                                    try? await Task.sleep(for: .milliseconds(100))
                                    if !Task.isCancelled {
                                        hoveredCategory = nil
                                        hoveredDataPoint = nil
                                        isTooltipVisible = false
                                    }
                                }
                            }
                        }
                }
            }
        }
    }

    private func handleHover(at location: CGPoint, in proxy: ChartProxy, geometry: GeometryProxy) {
        guard let categoryName: String = proxy.value(atX: location.x) else {
            hoveredCategory = nil
            hoveredDataPoint = nil
            return
        }

        hoveredCategory = categoryName

        // Find the data point closest to the hover position
        guard displayCategories.contains(where: { $0.categoryName == categoryName }) else { return }

        // Determine which series is being hovered based on x position within the category group
        let matchingPoints = chartDataPoints.filter { $0.categoryName == categoryName }

        // For simplicity, show the allocated amount by default
        if let point = matchingPoints.first(where: { $0.seriesType == .allocated }) {
            hoveredDataPoint = point

            // Calculate tooltip position with bounds checking
            let tooltipX = min(max(location.x + 80, 100), geometry.size.width - 100)
            let tooltipY = max(location.y - 60, 60)
            tooltipPosition = CGPoint(x: tooltipX, y: tooltipY)
        }
    }

    // MARK: - Tooltip View

    private func tooltipView(for dataPoint: CategoryChartDataPoint) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Category name header
            Text(dataPoint.categoryName)
                .font(Typography.caption.weight(.bold))
                .foregroundStyle(SemanticColors.textPrimary)

            Divider()
                .frame(width: 120)

            // All three values for this category
            if let metric = displayCategories.first(where: { $0.categoryName == dataPoint.categoryName }) {
                ForEach(BudgetSeriesType.allCases, id: \.self) { series in
                    HStack(spacing: Spacing.sm) {
                        Circle()
                            .fill(series.color)
                            .frame(width: 8, height: 8)
                        Text(series.rawValue)
                            .font(Typography.caption)
                            .foregroundStyle(SemanticColors.textSecondary)
                        Spacer()
                        Text(formatCurrency(amountForSeries(metric: metric, series: series)))
                            .font(Typography.caption.weight(.medium))
                            .foregroundStyle(SemanticColors.textPrimary)
                    }
                }

                // Show variance (using the computed remaining property)
                let varianceColor = metric.remaining >= 0 ? AppColors.success : AppColors.error
                HStack {
                    Text("Remaining")
                        .font(Typography.caption)
                        .foregroundStyle(SemanticColors.textSecondary)
                    Spacer()
                    Text(formatCurrency(metric.remaining))
                        .font(Typography.caption.weight(.bold))
                        .foregroundStyle(varianceColor)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.md)
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: AppColors.shadowMedium, radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
    }

    // MARK: - Legend View

    private var legendView: some View {
        HStack(spacing: Spacing.lg) {
            ForEach(BudgetSeriesType.allCases, id: \.self) { series in
                HStack(spacing: Spacing.xs) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(series.color)
                        .frame(width: 12, height: 12)
                    Text(series.rawValue.uppercased())
                        .font(Typography.caption)
                        .foregroundStyle(SemanticColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32))
                .foregroundStyle(SemanticColors.textTertiary)
            Text(selectedCategoryType == .parent
                ? "No parent categories yet"
                : "No standalone categories yet")
                .font(Typography.bodyRegular)
                .foregroundStyle(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Formatting Helpers

    private func formatShortCurrency(_ amount: Double) -> String {
        if amount >= 1000 {
            return "$\(Int(amount / 1000))K"
        }
        return "$\(Int(amount))"
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Legacy Category Bar Chart (kept for reference)

struct CategoryBarChart: View {
    let categories: [BudgetCategory]

    private var topCategories: [BudgetCategory] {
        Array(categories.sorted { $0.allocatedAmount > $1.allocatedAmount }.prefix(6))
    }

    var body: some View {
        if categories.isEmpty {
            emptyState
        } else {
            Chart(topCategories) { category in
                BarMark(
                    x: .value("Amount", category.allocatedAmount),
                    y: .value("Category", category.categoryName)
                )
                .foregroundStyle(Color(hex: category.color) ?? AppColors.Budget.allocated)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(formatShortCurrency(amount))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32))
                .foregroundStyle(SemanticColors.textTertiary)
            Text("No categories yet")
                .font(Typography.bodyRegular)
                .foregroundStyle(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formatShortCurrency(_ amount: Double) -> String {
        if amount >= 1000 {
            return "$\(Int(amount / 1000))K"
        }
        return "$\(Int(amount))"
    }
}

// MARK: - Spend Distribution View Mode

/// Toggle between viewing allocated (expenses) vs paid (payment plans) distribution
enum SpendDistributionMode: String, CaseIterable {
    case allocated = "Allocated"
    case paid = "Paid"

    var icon: String {
        switch self {
        case .allocated: return "chart.pie.fill"
        case .paid: return "creditcard.fill"
        }
    }

    var description: String {
        switch self {
        case .allocated: return "Budget allocation from expenses"
        case .paid: return "Actual payments made"
        }
    }

    var color: Color {
        switch self {
        case .allocated: return AppColors.Budget.allocated
        case .paid: return AppColors.Budget.underBudget
        }
    }
}

// MARK: - Spend Distribution Donut

/// Enhanced spend distribution donut chart with dropdown category selector
/// and detailed insights panel. Shows budget spend percentages with
/// interactive highlighting when a category is selected.
/// Uses CategoryBudgetMetrics for accurate spend data from RPC function.
/// Supports toggling between Allocated (expenses) and Paid (payment plans) views.
struct SpendDistributionDonut: View {
    /// Metrics from the database RPC function with accurate spend data
    let metrics: [CategoryBudgetMetrics]

    /// Selected category ID - nil means "All Categories"
    @State private var selectedCategoryId: UUID?

    /// View mode toggle: Allocated vs Paid
    @State private var viewMode: SpendDistributionMode = .paid

    // MARK: - Computed Properties

    /// Get the value to display based on current view mode
    private func valueForMode(_ metric: CategoryBudgetMetrics) -> Double {
        switch viewMode {
        case .allocated: return metric.allocated
        case .paid: return metric.spent
        }
    }

    /// Top-level parent categories with data, sorted by selected metric descending
    /// Only shows categories that are parents (have children) and have actual values
    private var validCategories: [CategoryBudgetMetrics] {
        // Get IDs of categories that have children (are parents)
        let parentCategoryIds = Set(metrics.compactMap { $0.parentCategoryId })

        // Filter to top-level categories that:
        // 1. Are parent categories (parentCategoryId is nil)
        // 2. Have children pointing to them (are actual parent categories with subcategories)
        // 3. Have value > 0 for the selected mode
        return metrics
            .filter { metric in
                metric.isParentCategory &&
                parentCategoryIds.contains(metric.categoryId) &&
                valueForMode(metric) > 0
            }
            .sorted { valueForMode($0) > valueForMode($1) }
    }

    /// Total value across all valid categories for current mode
    private var totalValue: Double {
        validCategories.reduce(0) { $0 + valueForMode($1) }
    }

    /// Currently selected category data
    private var selectedCategoryData: CategoryBudgetMetrics? {
        guard let id = selectedCategoryId else { return nil }
        return validCategories.first { $0.categoryId == id }
    }

    /// Calculate percentage for a category based on current mode
    private func percentage(for metric: CategoryBudgetMetrics) -> Double {
        guard totalValue > 0 else { return 0 }
        return (valueForMode(metric) / totalValue) * 100
    }

    /// Format percentage for display
    private func formatPercentage(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    // MARK: - Body

    var body: some View {
        if validCategories.isEmpty {
            emptyState
        } else {
            VStack(spacing: Spacing.sm) {
                // View Mode Toggle
                viewModeToggle

                // Main content: Donut on left, Stats on right
                HStack(alignment: .top, spacing: Spacing.lg) {
                    // Left side: Donut Chart with picker
                    VStack(spacing: Spacing.sm) {
                        donutChart
                            .frame(width: 140, height: 140)

                        // Category Dropdown Picker
                        categoryPicker
                    }
                    .frame(width: 160)

                    // Right side: Stats Panel (always visible)
                    statsPanel
                        .frame(maxWidth: .infinity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: selectedCategoryId)
            .animation(.easeInOut(duration: 0.25), value: viewMode)
        }
    }

    // MARK: - Stats Panel (Always Visible)

    private var statsPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header showing current selection
            HStack(spacing: Spacing.xs) {
                if let metric = selectedCategoryData {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: metric.color) ?? AppColors.Budget.allocated)
                        .frame(width: 3, height: 16)
                    Text(metric.categoryName)
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(SemanticColors.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(formatPercentage(percentage(for: metric)))
                        .font(Typography.caption.weight(.bold))
                        .foregroundStyle(Color(hex: metric.color) ?? AppColors.Budget.allocated)
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(viewMode.color)
                        .frame(width: 3, height: 16)
                    Text("All Categories")
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(SemanticColors.textPrimary)
                    Spacer()
                    Text(formatCurrency(totalValue))
                        .font(Typography.caption.weight(.bold))
                        .foregroundStyle(viewMode.color)
                }
            }

            Divider()

            // Compact metrics grid
            if let metric = selectedCategoryData {
                compactMetricsGrid(for: metric)
            } else {
                // Show summary for all categories
                allCategoriesSummary
            }
        }
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderLight, lineWidth: 1)
                )
        )
    }

    // MARK: - Compact Metrics Grid

    private func compactMetricsGrid(for metric: CategoryBudgetMetrics) -> some View {
        VStack(spacing: Spacing.xs) {
            // Row 1: Allocated & Spent
            HStack(spacing: Spacing.md) {
                compactMetric(
                    label: "Allocated",
                    value: formatCurrency(metric.allocated),
                    color: AppColors.Budget.allocated
                )
                compactMetric(
                    label: "Spent",
                    value: formatCurrency(metric.spent),
                    color: Color(hex: metric.color) ?? AppColors.Budget.underBudget
                )
            }

            // Row 2: Remaining & Usage
            HStack(spacing: Spacing.md) {
                compactMetric(
                    label: "Remaining",
                    value: formatCurrency(abs(metric.remaining)),
                    color: metric.remaining >= 0 ? AppColors.Budget.underBudget : AppColors.Budget.overBudget,
                    isNegative: metric.remaining < 0
                )
                compactMetric(
                    label: "Used",
                    value: "\(Int(metric.percentageSpent.rounded()))%",
                    color: metric.percentageSpent > 100 ? AppColors.Budget.overBudget
                        : metric.percentageSpent > 80 ? AppColors.warning
                        : AppColors.Budget.underBudget
                )
            }

            // Progress bar
            GeometryReader { geometry in
                let usagePercent = metric.allocated > 0
                    ? min((metric.spent / metric.allocated), 1.0)
                    : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(SemanticColors.borderLight)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            usagePercent > 1.0 ? AppColors.Budget.overBudget
                                : usagePercent > 0.8 ? AppColors.warning
                                : Color(hex: metric.color) ?? AppColors.Budget.allocated
                        )
                        .frame(width: geometry.size.width * usagePercent, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - All Categories Summary

    private var allCategoriesSummary: some View {
        VStack(spacing: Spacing.xs) {
            // Total value for current mode
            HStack(spacing: Spacing.md) {
                compactMetric(
                    label: viewMode == .allocated ? "Total Allocated" : "Total Paid",
                    value: formatCurrency(totalValue),
                    color: viewMode.color
                )
                compactMetric(
                    label: "Categories",
                    value: "\(validCategories.count)",
                    color: SemanticColors.textSecondary
                )
            }

            // Top 3 categories mini-list
            VStack(spacing: Spacing.xxs) {
                ForEach(Array(validCategories.prefix(3)), id: \.categoryId) { metric in
                    HStack(spacing: Spacing.xs) {
                        Circle()
                            .fill(Color(hex: metric.color) ?? AppColors.Budget.allocated)
                            .frame(width: 6, height: 6)
                        Text(metric.categoryName)
                            .font(.caption2)
                            .foregroundStyle(SemanticColors.textSecondary)
                            .lineLimit(1)
                        Spacer()
                        Text(formatPercentage(percentage(for: metric)))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(SemanticColors.textPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Compact Metric

    private func compactMetric(
        label: String,
        value: String,
        color: Color,
        isNegative: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(SemanticColors.textTertiary)
            HStack(spacing: 1) {
                if isNegative {
                    Text("-")
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(color)
                }
                Text(value)
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(SpendDistributionMode.allCases, id: \.self) { mode in
                Button {
                    viewMode = mode
                    // Reset category selection when switching modes
                    selectedCategoryId = nil
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12))
                        Text(mode.rawValue)
                            .font(Typography.caption.weight(.medium))
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        viewMode == mode
                            ? mode.color
                            : Color.clear
                    )
                    .foregroundStyle(
                        viewMode == mode
                            ? .white
                            : SemanticColors.textSecondary
                    )
                    .cornerRadius(CornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .stroke(
                                viewMode == mode
                                    ? Color.clear
                                    : SemanticColors.borderLight,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .help(mode.description)
            }
            Spacer()
        }
    }

    // MARK: - Donut Chart

    private var donutChart: some View {
        Chart(validCategories, id: \.categoryId) { metric in
            SectorMark(
                angle: .value("Value", valueForMode(metric)),
                innerRadius: .ratio(0.65),
                outerRadius: selectedCategoryId == metric.categoryId
                    ? .ratio(1.0)  // Expand selected segment
                    : .ratio(0.95),
                angularInset: 1.5
            )
            .cornerRadius(3)
            .foregroundStyle(Color(hex: metric.color) ?? AppColors.Budget.allocated)
            .opacity(segmentOpacity(for: metric))
        }
        .chartLegend(.hidden)
        .chartBackground { _ in
            GeometryReader { geometry in
                centerContent
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }

    /// Determine opacity for a segment based on selection state
    private func segmentOpacity(for metric: CategoryBudgetMetrics) -> Double {
        if selectedCategoryId == nil {
            return 1.0  // All segments fully visible when nothing selected
        }
        return selectedCategoryId == metric.categoryId ? 1.0 : 0.3
    }

    /// Center content showing percentage and category name
    @ViewBuilder
    private var centerContent: some View {
        if let metric = selectedCategoryData {
            // Selected category view
            VStack(spacing: Spacing.xxs) {
                Text(formatPercentage(percentage(for: metric)))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: metric.color) ?? AppColors.Budget.allocated)

                Text(metric.categoryName.uppercased())
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(SemanticColors.textSecondary)
                    .tracking(1.0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        } else {
            // Default "All Categories" view
            VStack(spacing: Spacing.xxs) {
                Text("100%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(viewMode.color)

                Text(viewMode.rawValue.uppercased())
                    .font(Typography.caption.weight(.semibold))
                    .foregroundStyle(SemanticColors.textSecondary)
                    .tracking(1.0)
            }
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        Picker(selection: $selectedCategoryId) {
            // "All Categories" option
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(SemanticColors.textTertiary)
                    .frame(width: 10, height: 10)
                Text("All Categories")
            }
            .tag(nil as UUID?)

            Divider()

            // Individual categories with percentages
            ForEach(validCategories, id: \.categoryId) { metric in
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(Color(hex: metric.color) ?? AppColors.Budget.allocated)
                        .frame(width: 10, height: 10)
                    Text("\(metric.categoryName) (\(formatPercentage(percentage(for: metric))))")
                }
                .tag(metric.categoryId as UUID?)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderLight, lineWidth: 1)
                )
        )
    }

    // MARK: - Category Insights Panel

    private func categoryInsightsPanel(for metric: CategoryBudgetMetrics) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with category color indicator
            HStack(spacing: Spacing.sm) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: metric.color) ?? AppColors.Budget.allocated)
                    .frame(width: 4, height: 20)

                Text(metric.categoryName)
                    .font(Typography.subheading.weight(.semibold))
                    .foregroundStyle(SemanticColors.textPrimary)

                Spacer()

                // Percentage badge
                Text(formatPercentage(percentage(for: metric)))
                    .font(Typography.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color(hex: metric.color) ?? AppColors.Budget.allocated)
                    .cornerRadius(CornerRadius.sm)
            }

            Divider()

            // Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                // Spent Amount
                insightMetric(
                    label: "Spent",
                    value: formatCurrency(metric.spent),
                    icon: "creditcard.fill",
                    color: Color(hex: metric.color) ?? AppColors.Budget.allocated
                )

                // Allocated Budget
                insightMetric(
                    label: "Allocated",
                    value: formatCurrency(metric.allocated),
                    icon: "chart.pie.fill",
                    color: AppColors.Budget.allocated
                )

                // Remaining (using computed property from model)
                insightMetric(
                    label: "Remaining",
                    value: formatCurrency(abs(metric.remaining)),
                    icon: metric.remaining >= 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                    color: metric.remaining >= 0 ? AppColors.Budget.underBudget : AppColors.Budget.overBudget,
                    isNegative: metric.remaining < 0
                )

                // Budget Usage (using computed property from model)
                insightMetric(
                    label: "Budget Used",
                    value: "\(Int(metric.percentageSpent.rounded()))%",
                    icon: "gauge.with.needle.fill",
                    color: metric.percentageSpent > 100 ? AppColors.Budget.overBudget
                        : metric.percentageSpent > 80 ? AppColors.warning
                        : AppColors.Budget.underBudget
                )
            }

            // Progress bar showing budget usage
            VStack(alignment: .leading, spacing: Spacing.xs) {
                let usagePercent = metric.allocated > 0
                    ? min((metric.spent / metric.allocated), 1.5)
                    : 0

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(SemanticColors.borderLight)
                            .frame(height: 8)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                usagePercent > 1.0 ? AppColors.Budget.overBudget
                                    : usagePercent > 0.8 ? AppColors.warning
                                    : Color(hex: metric.color) ?? AppColors.Budget.allocated
                            )
                            .frame(width: geometry.size.width * min(usagePercent, 1.0), height: 8)

                        // Over-budget indicator
                        if usagePercent > 1.0 {
                            Rectangle()
                                .fill(AppColors.Budget.overBudget.opacity(0.3))
                                .frame(width: geometry.size.width * min(usagePercent - 1.0, 0.5), height: 8)
                                .offset(x: geometry.size.width)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(
                            Color(hex: metric.color)?.opacity(0.3) ?? SemanticColors.borderLight,
                            lineWidth: 1
                        )
                )
        )
    }

    /// Individual metric display for insights panel
    private func insightMetric(
        label: String,
        value: String,
        icon: String,
        color: Color,
        isNegative: Bool = false
    ) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Typography.caption)
                    .foregroundStyle(SemanticColors.textTertiary)

                HStack(spacing: 2) {
                    if isNegative {
                        Text("-")
                            .font(Typography.subheading.weight(.semibold))
                            .foregroundStyle(color)
                    }
                    Text(value)
                        .font(Typography.subheading.weight(.semibold))
                        .foregroundStyle(SemanticColors.textPrimary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "chart.pie")
                .font(.system(size: 32))
                .foregroundStyle(SemanticColors.textTertiary)
            Text("No spending recorded")
                .font(Typography.bodyRegular)
                .foregroundStyle(SemanticColors.textSecondary)
            Text("Start tracking expenses to see your spend distribution")
                .font(Typography.caption)
                .foregroundStyle(SemanticColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Formatting Helpers

    private func formatCurrency(_ amount: Double) -> String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Financial Planning Section

struct FinancialPlanningSection: View {
    let windowSize: WindowSize
    let affordability: AffordabilityStore
    let gifts: GiftsStore
    let onNavigateToCalculator: () -> Void
    let onNavigateToGifts: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Financial Planning")
                .font(Typography.title3)
                .foregroundStyle(SemanticColors.textPrimary)

            let columns: [GridItem] = windowSize == .compact
                ? [GridItem(.flexible())]
                : [GridItem(.flexible()), GridItem(.flexible())]

            LazyVGrid(columns: columns, spacing: Spacing.lg) {
                // Monthly Affordability Card
                MonthlyAffordabilityCard(
                    affordability: affordability,
                    onTap: onNavigateToCalculator
                )

                // Gifts & Contributions Card
                GiftsContributionsCard(
                    gifts: gifts,
                    onTap: onNavigateToGifts
                )
            }
        }
    }
}

// MARK: - Monthly Affordability Card V2

/// A clean, modern affordability card matching the Financial Planning design.
/// Shows monthly contribution, savings progress, and months remaining.
struct MonthlyAffordabilityCard: View {
    let affordability: AffordabilityStore
    let onTap: () -> Void

    @State private var isHovered = false

    /// Monthly contribution from both partners
    private var monthlyContribution: Double {
        affordability.editedPartner1Monthly + affordability.editedPartner2Monthly
    }

    /// Months remaining until wedding
    private var monthsRemaining: Int {
        affordability.monthsLeft
    }

    /// Progress as percentage (0.0 to 1.0)
    private var progress: Double {
        affordability.progressPercentage / 100.0
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Header with icon and title
                HStack(spacing: Spacing.md) {
                    // Calendar icon with blue background
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(AppColors.Budget.allocated.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "calendar")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(AppColors.Budget.allocated)
                    }

                    Text("Monthly Affordability")
                        .font(Typography.heading)
                        .foregroundStyle(SemanticColors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(SemanticColors.textTertiary)
                }

                Divider()
                    .background(SemanticColors.borderLight)

                // Monthly Contribution
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Monthly Contribution")
                        .font(Typography.bodySmall)
                        .foregroundStyle(SemanticColors.textSecondary)

                    Text(formatCurrency(monthlyContribution))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.Budget.income)
                }

                // Savings Progress
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Savings Progress")
                            .font(Typography.bodySmall)
                            .foregroundStyle(SemanticColors.textSecondary)

                        Spacer()

                        Text("\(Int(progress * 100))%")
                            .font(Typography.bodySmall)
                            .foregroundStyle(SemanticColors.textSecondary)
                    }

                    // Custom progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 4)
                                .fill(SemanticColors.borderLight)
                                .frame(height: 8)

                            // Progress fill
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.Budget.allocated)
                                .frame(width: max(geometry.size.width * progress, 8), height: 8)
                        }
                    }
                    .frame(height: 8)

                    // Months remaining
                    Text("\(monthsRemaining) months remaining")
                        .font(Typography.caption)
                        .foregroundStyle(SemanticColors.textTertiary)
                }
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(isHovered ? AppColors.Budget.allocated.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .shadow(
                color: isHovered ? AppColors.Budget.allocated.opacity(0.1) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Gifts & Contributions Card

struct GiftsContributionsCard: View {
    let gifts: GiftsStore
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColors.Budget.income)
                    Text("Gifts & Contributions")
                        .font(Typography.heading)
                        .foregroundStyle(SemanticColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(SemanticColors.textTertiary)
                }

                Divider()

                // Summary Stats
                HStack(spacing: Spacing.xl) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Received")
                            .font(Typography.caption)
                            .foregroundStyle(SemanticColors.textSecondary)
                        Text(formatCurrency(gifts.totalReceived))
                            .font(Typography.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.Budget.underBudget)
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Pending")
                            .font(Typography.caption)
                            .foregroundStyle(SemanticColors.textSecondary)
                        Text(formatCurrency(gifts.totalPending))
                            .font(Typography.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.Budget.pending)
                    }
                }

                // Mini donut preview
                if !gifts.giftsAndOwed.isEmpty {
                    GiftsMiniDonut(
                        received: gifts.totalReceived,
                        pending: gifts.totalPending
                    )
                    .frame(height: 60)
                }
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(isHovered ? AppColors.Budget.income.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Gifts Mini Donut

struct GiftsMiniDonut: View {
    let received: Double
    let pending: Double

    var body: some View {
        HStack(spacing: Spacing.lg) {
            Chart {
                SectorMark(
                    angle: .value("Received", received),
                    innerRadius: .ratio(0.7)
                )
                .foregroundStyle(AppColors.Budget.underBudget)

                SectorMark(
                    angle: .value("Pending", pending),
                    innerRadius: .ratio(0.7)
                )
                .foregroundStyle(AppColors.Budget.pending)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(AppColors.Budget.underBudget)
                        .frame(width: 8, height: 8)
                    Text("Received")
                        .font(.caption2)
                        .foregroundStyle(SemanticColors.textSecondary)
                }
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(AppColors.Budget.pending)
                        .frame(width: 8, height: 8)
                    Text("Pending")
                        .font(.caption2)
                        .foregroundStyle(SemanticColors.textSecondary)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Upcoming Payments Section

struct UpcomingPaymentsSection: View {
    let windowSize: WindowSize
    let upcomingPayments: [PaymentSchedule]
    let onNavigate: (BudgetPage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Upcoming Payments")
                    .font(Typography.title3)
                    .foregroundStyle(SemanticColors.textPrimary)

                Spacer()

                Button(action: { onNavigate(.paymentSchedule) }) {
                    HStack(spacing: Spacing.xs) {
                        Text("View All")
                            .font(Typography.caption)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(AppColors.Budget.allocated)
                }
                .buttonStyle(.plain)
            }

            if upcomingPayments.isEmpty {
                emptyPaymentsState
            } else {
                VStack(spacing: 0) {
                    // Header
                    DashboardPaymentTableHeader()

                    Divider()

                    // Rows (show top 5)
                    ForEach(Array(upcomingPayments.prefix(5))) { payment in
                        DashboardPaymentTableRow(payment: payment)
                        if payment.id != upcomingPayments.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(CornerRadius.lg)
            }
        }
    }

    private var emptyPaymentsState: some View {
        HStack {
            Spacer()
            VStack(spacing: Spacing.md) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 32))
                    .foregroundStyle(SemanticColors.textTertiary)
                Text("No upcoming payments")
                    .font(Typography.bodyRegular)
                    .foregroundStyle(SemanticColors.textSecondary)
                Text("All payments are up to date")
                    .font(Typography.caption)
                    .foregroundStyle(SemanticColors.textTertiary)
            }
            .padding(Spacing.xl)
            Spacer()
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Dashboard Payment Table Header

struct DashboardPaymentTableHeader: View {
    var body: some View {
        HStack {
            Text("Vendor / Description")
                .font(Typography.caption)
                .foregroundStyle(SemanticColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Due Date")
                .font(Typography.caption)
                .foregroundStyle(SemanticColors.textSecondary)
                .frame(width: 100, alignment: .leading)

            Text("Amount")
                .font(Typography.caption)
                .foregroundStyle(SemanticColors.textSecondary)
                .frame(width: 100, alignment: .trailing)

            Text("Status")
                .font(Typography.caption)
                .foregroundStyle(SemanticColors.textSecondary)
                .frame(width: 80, alignment: .center)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Dashboard Payment Table Row

struct DashboardPaymentTableRow: View {
    let payment: PaymentSchedule

    @State private var isHovered = false

    private var dueStatus: DueStatus {
        let now = Date()
        let daysUntil = Calendar.current.dateComponents([.day], from: now, to: payment.paymentDate).day ?? 0

        if payment.paid {
            return .paid
        } else if daysUntil < 0 {
            return .overdue
        } else if daysUntil <= 7 {
            return .dueSoon
        } else {
            return .upcoming
        }
    }

    var body: some View {
        HStack {
            // Vendor / Description
            VStack(alignment: .leading, spacing: 2) {
                Text(payment.vendor)
                    .font(Typography.subheading)
                    .foregroundStyle(SemanticColors.textPrimary)
                    .lineLimit(1)

                if let notes = payment.notes, !notes.isEmpty {
                    Text(notes)
                        .font(Typography.caption)
                        .foregroundStyle(SemanticColors.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Due Date
            Text(formatDate(payment.paymentDate))
                .font(Typography.bodyRegular)
                .foregroundStyle(dueStatus.textColor)
                .frame(width: 100, alignment: .leading)

            // Amount
            Text(formatCurrency(payment.paymentAmount))
                .font(Typography.subheading)
                .fontWeight(.medium)
                .foregroundStyle(SemanticColors.textPrimary)
                .frame(width: 100, alignment: .trailing)

            // Status Badge
            Text(dueStatus.label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(dueStatus.textColor)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs)
                .background(dueStatus.backgroundColor)
                .cornerRadius(CornerRadius.sm)
                .frame(width: 80, alignment: .center)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(isHovered ? Color(NSColor.selectedControlColor).opacity(0.1) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatCurrency(_ amount: Double) -> String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Due Status

enum DueStatus {
    case paid
    case overdue
    case dueSoon
    case upcoming

    var label: String {
        switch self {
        case .paid: return "Paid"
        case .overdue: return "Overdue"
        case .dueSoon: return "Due Soon"
        case .upcoming: return "Upcoming"
        }
    }

    var textColor: Color {
        switch self {
        case .paid: return AppColors.Budget.underBudget
        case .overdue: return AppColors.Budget.overBudget
        case .dueSoon: return AppColors.warning
        case .upcoming: return SemanticColors.textSecondary
        }
    }

    var backgroundColor: Color {
        switch self {
        case .paid: return AppColors.Budget.underBudget.opacity(0.15)
        case .overdue: return AppColors.Budget.overBudget.opacity(0.15)
        case .dueSoon: return AppColors.warning.opacity(0.15)
        case .upcoming: return Color(NSColor.controlBackgroundColor)
        }
    }
}

// MARK: - Bottom Actions Row

struct BottomActionsRow: View {
    let windowSize: WindowSize
    let pendingPayments: [PaymentSchedule]
    let onNavigate: (BudgetPage) -> Void

    var body: some View {
        let columns: [GridItem] = windowSize == .compact
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]

        LazyVGrid(columns: columns, spacing: Spacing.lg) {
            // Needs Your Approval
            NeedsApprovalCard(
                pendingCount: pendingPayments.count,
                onTap: { onNavigate(.paymentSchedule) }
            )

            // Quick Tasks
            QuickTasksCard(
                onNavigate: onNavigate
            )
        }
    }
}

// MARK: - Needs Approval Card

struct NeedsApprovalCard: View {
    let pendingCount: Int
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColors.warning)

                    Text("Needs Your Approval")
                        .font(Typography.heading)
                        .foregroundStyle(SemanticColors.textPrimary)

                    Spacer()

                    if pendingCount > 0 {
                        Text("\(pendingCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(AppColors.warning)
                            .cornerRadius(CornerRadius.pill)
                    }
                }

                if pendingCount > 0 {
                    Text("You have \(pendingCount) pending payment\(pendingCount == 1 ? "" : "s") to review")
                        .font(Typography.bodyRegular)
                        .foregroundStyle(SemanticColors.textSecondary)
                } else {
                    Text("All caught up! No pending approvals.")
                        .font(Typography.bodyRegular)
                        .foregroundStyle(SemanticColors.textSecondary)
                }

                HStack {
                    Spacer()
                    Text("Review Now")
                        .font(Typography.caption)
                        .foregroundStyle(AppColors.Budget.allocated)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(AppColors.Budget.allocated)
                }
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(isHovered ? AppColors.warning.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Quick Tasks Card

struct QuickTasksCard: View {
    let onNavigate: (BudgetPage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppColors.Budget.allocated)

                Text("Quick Tasks")
                    .font(Typography.heading)
                    .foregroundStyle(SemanticColors.textPrimary)

                Spacer()
            }

            VStack(spacing: Spacing.sm) {
                QuickTaskButton(
                    icon: "plus.circle.fill",
                    title: "Add Expense",
                    color: AppColors.Budget.expense
                ) {
                    onNavigate(.expenseTracker)
                }

                QuickTaskButton(
                    icon: "calendar.badge.plus",
                    title: "Schedule Payment",
                    color: AppColors.Budget.pending
                ) {
                    onNavigate(.paymentSchedule)
                }

                QuickTaskButton(
                    icon: "chart.bar.doc.horizontal",
                    title: "View Analytics",
                    color: AppColors.Budget.allocated
                ) {
                    onNavigate(.analytics)
                }
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Quick Task Button

struct QuickTaskButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(title)
                    .font(Typography.subheading)
                    .foregroundStyle(SemanticColors.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(SemanticColors.textTertiary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(isHovered ? color.opacity(0.1) : Color.clear)
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var currentPage: BudgetPage = .hub

    BudgetDashboardViewV1(currentPage: $currentPage)
        .environmentObject(BudgetStoreV2())
        .frame(width: 1200, height: 900)
}
