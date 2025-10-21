//
//  AnalyticsDashboardView.swift
//  My Wedding Planning App
//
//  Comprehensive analytics dashboard for visual planning insights
//

import SwiftUI

struct AnalyticsDashboardView: View {
    @StateObject var analyticsService = AnalyticsService.shared
    @StateObject var performanceService = PerformanceOptimizationService.shared
    @State var selectedTimeframe: TimeFrame = .week
    @State var selectedMetric: MetricType = .overview

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
}

#Preview {
    AnalyticsDashboardView()
        .frame(width: 1200, height: 800)
}
