//
//  AnalyticsDashboardView.swift
//  My Wedding Planning App
//
//  Comprehensive analytics dashboard for visual planning insights
//

import Charts
import SwiftUI

struct AnalyticsDashboardView: View {
    @StateObject private var analyticsService = AnalyticsService.shared
    @StateObject private var performanceService = PerformanceOptimizationService.shared
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var selectedMetric: MetricType = .overview

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            // Main dashboard content
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Overview cards
                    overviewCardsSection

                    // Charts section
                    chartsSection

                    // Insights section
                    insightsSection

                    // Performance section
                    performanceSection
                }
                .padding()
            }
        }
        .navigationTitle("Analytics Dashboard")
        .onAppear {
            Task {
                await analyticsService.refreshDashboard(for: "default")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Visual Planning Analytics")
                    .font(.title2)
                    .fontWeight(.semibold)

                if let lastUpdate = analyticsService.lastUpdateDate {
                    Text("Last updated: \(lastUpdate, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                // Timeframe picker
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                        Text(timeframe.displayName).tag(timeframe)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)

                // Refresh button
                Button(action: {
                    Task {
                        await analyticsService.refreshDashboard(for: "default")
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                .disabled(analyticsService.isLoading)

                if analyticsService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Overview Cards

    private var overviewCardsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
            OverviewCard(
                title: "Mood Boards",
                value: "\(analyticsService.dashboardData.overview.totalMoodBoards)",
                icon: "photo.on.rectangle.angled",
                color: .blue,
                trend: calculateTrend(for: .moodBoards))

            OverviewCard(
                title: "Color Palettes",
                value: "\(analyticsService.dashboardData.overview.totalColorPalettes)",
                icon: "paintpalette",
                color: .purple,
                trend: calculateTrend(for: .colorPalettes))

            OverviewCard(
                title: "Seating Charts",
                value: "\(analyticsService.dashboardData.overview.totalSeatingCharts)",
                icon: "tablecells",
                color: .green,
                trend: calculateTrend(for: .seatingCharts))

            OverviewCard(
                title: "Completion Rate",
                value: "\(Int(analyticsService.dashboardData.overview.completionRate * 100))%",
                icon: "checkmark.circle",
                color: .orange,
                trend: .stable)
        }
    }

    // MARK: - Charts Section

    private var chartsSection: some View {
        VStack(spacing: 24) {
            // Activity chart
            ChartCard(title: "Recent Activity") {
                ActivityChart(data: analyticsService.dashboardData.overview.recentActivity)
            }

            HStack(spacing: 24) {
                // Style distribution
                ChartCard(title: "Style Distribution") {
                    StyleDistributionChart(data: analyticsService.dashboardData.styleAnalytics.styleDistribution)
                }

                // Color analysis
                ChartCard(title: "Dominant Colors") {
                    DominantColorsChart(data: analyticsService.dashboardData.colorAnalytics.dominantColors)
                }
            }

            // Usage patterns
            ChartCard(title: "Usage Patterns") {
                UsagePatternsChart(
                    timePatterns: analyticsService.dashboardData.usagePatterns.timePatterns,
                    selectedTimeframe: selectedTimeframe)
            }
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Insights & Recommendations")
                    .font(.headline)

                Spacer()

                Text("\(analyticsService.dashboardData.insights.count) insights")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if analyticsService.dashboardData.insights.isEmpty {
                EmptyInsightsView()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(analyticsService.dashboardData.insights) { insight in
                        InsightCard(insight: insight)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Performance Section

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance & Optimization")
                .font(.headline)

            HStack(spacing: 24) {
                PerformanceMetricCard(
                    title: "Memory Usage",
                    value: "\(Int(analyticsService.dashboardData.performanceMetrics.memoryUsage)) MB",
                    icon: "memorychip",
                    status: memoryStatus)

                PerformanceMetricCard(
                    title: "Cache Size",
                    value: formatBytes(Int(performanceService.imageCacheSize)),
                    icon: "externaldrive",
                    status: cacheStatus)

                PerformanceMetricCard(
                    title: "Optimization",
                    value: performanceService.isOptimizing ? "Running" : "Ready",
                    icon: "speedometer",
                    status: .good)

                Spacer()

                Button("Optimize Now") {
                    Task {
                        await performanceService.optimizeMemoryUsage()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(performanceService.isOptimizing)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    private func calculateTrend(for type: MetricType) -> TrendDirection {
        let recentActivity = analyticsService.dashboardData.overview.recentActivity
        guard recentActivity.count >= 2 else { return .stable }

        let recent = recentActivity.suffix(3)
        let older = recentActivity.prefix(3)

        let recentTotal: Int
        let olderTotal: Int

        switch type {
        case .moodBoards:
            recentTotal = recent.reduce(0) { $0 + $1.moodBoards }
            olderTotal = older.reduce(0) { $0 + $1.moodBoards }
        case .colorPalettes:
            recentTotal = recent.reduce(0) { $0 + $1.colorPalettes }
            olderTotal = older.reduce(0) { $0 + $1.colorPalettes }
        case .seatingCharts:
            recentTotal = recent.reduce(0) { $0 + $1.seatingCharts }
            olderTotal = older.reduce(0) { $0 + $1.seatingCharts }
        default:
            return .stable
        }

        if recentTotal > olderTotal {
            return .up
        } else if recentTotal < olderTotal {
            return .down
        } else {
            return .stable
        }
    }

    private var memoryStatus: MetricStatus {
        let usage = analyticsService.dashboardData.performanceMetrics.memoryUsage
        if usage > 400 { return .warning }
        if usage > 200 { return .caution }
        return .good
    }

    private var cacheStatus: MetricStatus {
        let size = Int(performanceService.imageCacheSize)
        if size > 80_000_000 { return .warning }
        if size > 50_000_000 { return .caution }
        return .good
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Chart Views

struct ActivityChart: View {
    let data: [ActivityMetric]

    var body: some View {
        Chart(data, id: \.date) { metric in
            LineMark(
                x: .value("Date", metric.date),
                y: .value("Total", metric.total))
                .foregroundStyle(.blue)

            AreaMark(
                x: .value("Date", metric.date),
                y: .value("Total", metric.total))
                .foregroundStyle(.blue.opacity(0.1))
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
    }
}

struct StyleDistributionChart: View {
    let data: [StyleCategory: Int]

    var body: some View {
        Chart(data.sorted { $0.value > $1.value }, id: \.key) { item in
            BarMark(
                x: .value("Count", item.value),
                y: .value("Style", item.key.displayName))
                .foregroundStyle(by: .value("Style", item.key.displayName))
        }
        .frame(height: 200)
        .chartLegend(.hidden)
    }
}

struct DominantColorsChart: View {
    let data: [ColorFrequency]

    var body: some View {
        Chart(data.prefix(8), id: \.color.description) { colorFreq in
            BarMark(
                x: .value("Frequency", colorFreq.frequency),
                y: .value("Color", colorFreq.color.description))
                .foregroundStyle(colorFreq.color)
        }
        .frame(height: 200)
    }
}

struct UsagePatternsChart: View {
    let timePatterns: TimePatterns
    let selectedTimeframe: TimeFrame

    var body: some View {
        VStack {
            if selectedTimeframe == .day {
                Chart(timePatterns.hourlyActivity.sorted { $0.key < $1.key }, id: \.key) { item in
                    BarMark(
                        x: .value("Hour", item.key),
                        y: .value("Activity", item.value))
                        .foregroundStyle(.green)
                }
                .chartXAxis {
                    AxisMarks(values: Array(stride(from: 0, through: 23, by: 4))) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel("\(value.as(Int.self) ?? 0):00")
                    }
                }
            } else {
                Chart(timePatterns.dailyActivity.sorted { $0.key < $1.key }, id: \.key) { item in
                    BarMark(
                        x: .value("Day", weekdayName(item.key)),
                        y: .value("Activity", item.value))
                        .foregroundStyle(.orange)
                }
            }
        }
        .frame(height: 200)
    }

    private func weekdayName(_ weekday: Int) -> String {
        let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return weekdays[weekday - 1]
    }
}

// MARK: - Card Components

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Spacer()

                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "green": .green
        case "red": .red
        case "gray": .gray
        case "blue": .blue
        case "orange": .orange
        case "yellow": .yellow
        case "purple": .purple
        default: .primary
        }
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)

            content
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct InsightCard: View {
    let insight: Insight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.type.icon)
                    .foregroundColor(insightTypeColor(insight.type))

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(insight.type.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Circle()
                    .fill(impactColor(insight.impact))
                    .frame(width: 8, height: 8)
            }

            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)

            if insight.actionable {
                Button("Take Action") {
                    // Handle insight action
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(insightTypeColor(insight.type).opacity(0.3), lineWidth: 1))
    }

    private func insightTypeColor(_ type: InsightType) -> Color {
        switch type {
        case .overspending: .red
        case .savings: .green
        case .seasonality: .blue
        case .vendor: .purple
        case .category: .orange
        case .timeline: .cyan
        case .recommendation: .blue
        case .warning: .yellow
        case .alert: .red
        case .info: .blue
        }
    }

    private func impactColor(_ impact: InsightImpact) -> Color {
        switch impact {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }
}

struct PerformanceMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let status: MetricStatus

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(status.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(status.color.opacity(0.3), lineWidth: 1))
    }
}

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lightbulb")
                .font(.title)
                .foregroundColor(.secondary)

            Text("No insights available")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Continue using the app to generate insights")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Types

enum TimeFrame: String, CaseIterable {
    case day
    case week
    case month
    case quarter

    var displayName: String {
        switch self {
        case .day: "Today"
        case .week: "This Week"
        case .month: "This Month"
        case .quarter: "This Quarter"
        }
    }
}

enum MetricType {
    case overview
    case moodBoards
    case colorPalettes
    case seatingCharts
}

enum MetricStatus {
    case good
    case caution
    case warning

    var color: Color {
        switch self {
        case .good: .green
        case .caution: .orange
        case .warning: .red
        }
    }
}

#Preview {
    AnalyticsDashboardView()
        .frame(width: 1200, height: 800)
}
