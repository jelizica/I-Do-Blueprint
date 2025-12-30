//
//  AnalyticsService.swift
//  My Wedding Planning App
//
//  Advanced analytics and insights for visual planning
//

// swiftlint:disable file_length

import Combine
import Foundation
import SwiftUI

@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()

    @Published var dashboardData: AnalyticsDashboard = .init()
    @Published var isLoading = false
    @Published var lastUpdateDate: Date?

    private let supabaseService: SupabaseVisualPlanningService
    private let performanceService = PerformanceOptimizationService.shared
    private var analyticsTimer: Timer?
    private let logger = AppLogger.general
    
    // MARK: - Domain Services
    
    private let overviewService = AnalyticsOverviewService()
    private let styleService = AnalyticsStyleService()
    private let colorService = AnalyticsColorService()
    private let usageService = AnalyticsUsageService()
    private let insightsService = AnalyticsInsightsService()

    // MARK: - Network Analytics

    /// Track network operation metrics
    /// - Parameters:
    ///   - operation: Name of the operation (e.g., "fetchVendors", "createGuest")
    ///   - outcome: Success or failure outcome
    ///   - duration: Duration of the operation in seconds
    nonisolated static func trackNetwork(
        operation: String,
        outcome: NetworkOperationOutcome,
        duration: TimeInterval
    ) {
        let logger = AppLogger.network
        let outcomeString = outcome.isSuccess ? "success" : "failure"

        logger.info("""
            Network Analytics - Operation: \(operation), \
            Outcome: \(outcomeString), \
            Duration: \(String(format: "%.3f", duration))s
            """)

        // Additional metrics could be sent to an analytics backend here
        // For now, we're just logging structured data
    }

    init() {
        supabaseService = SupabaseVisualPlanningService()

        // Only start periodic updates if feature flag allows
        if PerformanceFeatureFlags.enablePeriodicAnalytics {
            startPeriodicUpdates()
        }
    }

    init(supabaseService: SupabaseVisualPlanningService) {
        self.supabaseService = supabaseService

        // Only start periodic updates if feature flag allows
        if PerformanceFeatureFlags.enablePeriodicAnalytics {
            startPeriodicUpdates()
        }
    }

    // MARK: - Dashboard Data Collection

    func refreshDashboard(for tenantId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let moodBoards = supabaseService.fetchMoodBoards(for: tenantId)
            async let colorPalettes = supabaseService.fetchColorPalettes(for: tenantId)
            async let seatingCharts = supabaseService.fetchSeatingCharts(for: tenantId)
            async let stylePreferences = supabaseService.fetchStylePreferences(for: tenantId)

            let (boards, palettes, charts, preferences) = try await (
                moodBoards,
                colorPalettes,
                seatingCharts,
                stylePreferences)

            dashboardData = await generateAnalytics(
                moodBoards: boards,
                colorPalettes: palettes,
                seatingCharts: charts,
                stylePreferences: preferences
            )

            lastUpdateDate = Date()
        } catch {
            logger.warning("Analytics refresh failed: \(error.localizedDescription)")
        }
    }

    private func generateAnalytics(
        moodBoards: [MoodBoard],
        colorPalettes: [ColorPalette],
        seatingCharts: [SeatingChart],
        stylePreferences: StylePreferences?
    ) async -> AnalyticsDashboard {
        var analytics = AnalyticsDashboard()

        // Delegate to domain services
        async let overview = overviewService.generateOverviewMetrics(
            moodBoards: moodBoards,
            colorPalettes: colorPalettes,
            seatingCharts: seatingCharts
        )
        
        async let styleAnalytics = styleService.generateStyleAnalytics(
            moodBoards: moodBoards,
            preferences: stylePreferences
        )
        
        async let colorAnalytics = colorService.generateColorAnalytics(
            moodBoards: moodBoards,
            colorPalettes: colorPalettes,
            preferences: stylePreferences
        )
        
        async let usagePatterns = usageService.generateUsagePatterns(
            moodBoards: moodBoards,
            colorPalettes: colorPalettes,
            seatingCharts: seatingCharts
        )

        // Await all parallel operations
        analytics.overview = await overview
        analytics.styleAnalytics = await styleAnalytics
        analytics.colorAnalytics = await colorAnalytics
        analytics.usagePatterns = await usagePatterns
        
        // Performance metrics (synchronous)
        analytics.performanceMetrics = performanceService.performanceMetrics

        // Insights generation (needs style consistency and memory usage)
        analytics.insights = await insightsService.generateInsights(
            moodBoards: moodBoards,
            colorPalettes: colorPalettes,
            seatingCharts: seatingCharts,
            preferences: stylePreferences,
            styleConsistency: analytics.styleAnalytics.styleConsistency,
            memoryUsage: performanceService.performanceMetrics.memoryUsage
        )

        return analytics
    }

    // MARK: - Periodic Updates

    private func startPeriodicUpdates() {
        // Only start if feature flag allows (disabled by default to save memory)
        guard PerformanceFeatureFlags.enablePeriodicAnalytics else {
            logger.debug("Periodic analytics updates disabled via feature flag")
            return
        }

        analyticsTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            // Auto-refresh every 5 minutes
            Task { @MainActor in
                await self?.refreshDashboard(for: "default") // This would use actual tenant ID
            }
        }
    }

    deinit {
        analyticsTimer?.invalidate()
    }
}

// MARK: - Network Operation Outcome

/// Network operation outcome for analytics
enum NetworkOperationOutcome {
    case success
    case failure(code: String?)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

// MARK: - Analytics Data Models

struct AnalyticsDashboard {
    var overview = OverviewMetrics()
    var styleAnalytics = StyleAnalytics()
    var colorAnalytics = ColorAnalytics()
    var usagePatterns = UsagePatterns()
    var performanceMetrics = PerformanceMetrics()
    var insights: [Insight] = []
}

struct OverviewMetrics {
    var totalMoodBoards = 0
    var totalColorPalettes = 0
    var totalSeatingCharts = 0
    var totalElements = 0
    var totalExports = 0
    var recentActivity: [ActivityMetric] = []
    var completionRate = 0.0
}

struct ActivityMetric {
    let date: Date
    let moodBoards: Int
    let colorPalettes: Int
    let seatingCharts: Int

    var total: Int {
        moodBoards + colorPalettes + seatingCharts
    }
}

struct StyleAnalytics {
    var styleDistribution: [StyleCategory: Int] = [:]
    var mostUsedStyle: StyleCategory?
    var styleConsistency = 0.0
    var trendingStyles: [StyleTrend] = []
    var preferenceAlignment = 0.0
}

struct StyleTrend {
    let style: StyleCategory
    let count: Int
    let growth: Double
}

struct ColorAnalytics {
    var dominantColors: [ColorFrequency] = []
    var colorHarmonyDistribution: [ColorHarmonyType: Int] = [:]
    var seasonalTrends: [WeddingSeason: [ColorFrequency]] = [:]
    var paletteUsageStats = PaletteUsageStats()
    var colorConsistency = 0.0
}

struct ColorFrequency {
    let color: Color
    let frequency: Int
}

struct PaletteUsageStats {
    var totalUsage = 0
    var averageUsage = 0.0
    var favoriteCount = 0
    var mostUsedPalette: String?
}

struct UsagePatterns {
    var timePatterns = TimePatterns()
    var featureUsage = FeatureUsage()
    var exportPatterns = ExportPatterns()
    var collaborationStats = CollaborationStats()
}

struct TimePatterns {
    var hourlyActivity: [Int: Int] = [:]
    var dailyActivity: [Int: Int] = [:]
    var peakUsageHour = 0
    var peakUsageDay = 0
}

struct FeatureUsage {
    var moodBoardUsage = 0.0
    var colorPaletteUsage = 0.0
    var seatingChartUsage = 0.0
    var templateUsage = 0.0
    var exportUsage = 0.0
}

struct ExportPatterns {
    var totalExports = 0
    var averageExportsPerChart = 0.0
    var mostExportedChart: String?
}

struct CollaborationStats {
    var sharedItems = 0
    var collaborators = 0
    var avgCollaborationTime = 0.0
}

struct Insight: Identifiable {
    let id: String
    let type: InsightType
    let title: String
    let description: String
    let impact: InsightImpact
    let actionable: Bool
}

enum InsightImpact: Int, Comparable {
    case low = 1
    case medium = 2
    case high = 3

    static func < (lhs: InsightImpact, rhs: InsightImpact) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
