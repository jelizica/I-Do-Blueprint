//
//  AnalyticsService.swift
//  My Wedding Planning App
//
//  Advanced analytics and insights for visual planning
//

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

            dashboardData = generateAnalytics(
                moodBoards: boards,
                colorPalettes: palettes,
                seatingCharts: charts,
                stylePreferences: preferences)

            lastUpdateDate = Date()
        } catch {
            logger.warning("Analytics refresh failed: \(error.localizedDescription)")
        }
    }

    private func generateAnalytics(
        moodBoards: [MoodBoard],
        colorPalettes: [ColorPalette],
        seatingCharts: [SeatingChart],
        stylePreferences: StylePreferences?) -> AnalyticsDashboard {
        var analytics = AnalyticsDashboard()

        // Overview metrics
        analytics.overview = generateOverviewMetrics(
            moodBoards: moodBoards,
            colorPalettes: colorPalettes,
            seatingCharts: seatingCharts)

        // Style analytics
        analytics.styleAnalytics = generateStyleAnalytics(
            moodBoards: moodBoards,
            preferences: stylePreferences)

        // Color analytics
        analytics.colorAnalytics = generateColorAnalytics(
            moodBoards: moodBoards,
            colorPalettes: colorPalettes,
            preferences: stylePreferences)

        // Usage patterns
        analytics.usagePatterns = generateUsagePatterns(
            moodBoards: moodBoards,
            colorPalettes: colorPalettes,
            seatingCharts: seatingCharts)

        // Performance metrics
        analytics.performanceMetrics = performanceService.performanceMetrics

        // Insights and recommendations
        analytics.insights = generateInsights(
            moodBoards: moodBoards,
            colorPalettes: colorPalettes,
            seatingCharts: seatingCharts,
            preferences: stylePreferences)

        return analytics
    }

    // MARK: - Overview Metrics

    private func generateOverviewMetrics(
        moodBoards: [MoodBoard],
        colorPalettes: [ColorPalette],
        seatingCharts: [SeatingChart]) -> OverviewMetrics {
        let totalElements = moodBoards.reduce(into: 0) { $0 += $1.elements.count }

        // Export tracking: Requires database schema addition
        // Future: Add export_count field to mood_boards, color_palettes, and seating_charts tables
        // Then sum: moodBoards.reduce(0) { $0 + ($1.exportCount ?? 0) } + ...
        let totalExports = 0

        let recentActivity = calculateRecentActivity(
            moodBoards: moodBoards,
            colorPalettes: colorPalettes,
            seatingCharts: seatingCharts)

        return OverviewMetrics(
            totalMoodBoards: moodBoards.count,
            totalColorPalettes: colorPalettes.count,
            totalSeatingCharts: seatingCharts.count,
            totalElements: totalElements,
            totalExports: totalExports,
            recentActivity: recentActivity,
            completionRate: calculateCompletionRate(moodBoards: moodBoards, seatingCharts: seatingCharts))
    }

    private func calculateRecentActivity(
        moodBoards: [MoodBoard],
        colorPalettes: [ColorPalette],
        seatingCharts: [SeatingChart]) -> [ActivityMetric] {
        let calendar = Calendar.current
        let now = Date()
        var activities: [ActivityMetric] = []

        // Last 7 days
        for i in 0 ..< 7 {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let moodBoardCount = moodBoards.filter {
                $0.createdAt >= dayStart && $0.createdAt < dayEnd
            }.count

            let paletteCount = colorPalettes.filter {
                $0.createdAt >= dayStart && $0.createdAt < dayEnd
            }.count

            let chartCount = seatingCharts.filter {
                $0.createdAt >= dayStart && $0.createdAt < dayEnd
            }.count

            activities.append(ActivityMetric(
                date: dayStart,
                moodBoards: moodBoardCount,
                colorPalettes: paletteCount,
                seatingCharts: chartCount))
        }

        return activities.reversed()
    }

    private func calculateCompletionRate(moodBoards: [MoodBoard], seatingCharts: [SeatingChart]) -> Double {
        let completedBoards = moodBoards.filter { !$0.elements.isEmpty }.count
        let finalizedCharts = seatingCharts.filter(\.isFinalized).count
        let totalItems = moodBoards.count + seatingCharts.count

        guard totalItems > 0 else { return 0 }
        return Double(completedBoards + finalizedCharts) / Double(totalItems)
    }

    // MARK: - Style Analytics

    private func generateStyleAnalytics(
        moodBoards: [MoodBoard],
        preferences: StylePreferences?) -> StyleAnalytics {
        let styleDistribution = Dictionary(grouping: moodBoards, by: { $0.styleCategory })
            .mapValues { $0.count }

        let mostUsedStyle = styleDistribution.max(by: { $0.value < $1.value })?.key
        let styleConsistency = calculateStyleConsistency(moodBoards: moodBoards, preferences: preferences)

        let trendingStyles = calculateTrendingStyles(moodBoards: moodBoards)

        return StyleAnalytics(
            styleDistribution: styleDistribution,
            mostUsedStyle: mostUsedStyle,
            styleConsistency: styleConsistency,
            trendingStyles: trendingStyles,
            preferenceAlignment: calculatePreferenceAlignment(moodBoards: moodBoards, preferences: preferences))
    }

    private func calculateStyleConsistency(moodBoards: [MoodBoard], preferences: StylePreferences?) -> Double {
        guard let primaryStyle = preferences?.primaryStyle else { return 0 }

        let matchingBoards = moodBoards.filter { $0.styleCategory == primaryStyle }.count
        guard !moodBoards.isEmpty else { return 0 }

        return Double(matchingBoards) / Double(moodBoards.count)
    }

    private func calculateTrendingStyles(moodBoards: [MoodBoard]) -> [StyleTrend] {
        let recentDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        let recentBoards = moodBoards.filter { $0.createdAt >= recentDate }

        let trendCounts = Dictionary(grouping: recentBoards, by: { $0.styleCategory })
            .mapValues { $0.count }

        return trendCounts.map { style, count in
            StyleTrend(style: style, count: count, growth: calculateStyleGrowth(style: style, moodBoards: moodBoards))
        }.sorted { $0.count > $1.count }
    }

    private func calculateStyleGrowth(style: StyleCategory, moodBoards: [MoodBoard]) -> Double {
        let calendar = Calendar.current
        let thisMonth = calendar.date(byAdding: .month, value: 0, to: Date())!
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date())!

        let thisMonthCount = moodBoards.filter {
            $0.styleCategory == style && $0.createdAt >= thisMonth
        }.count

        let lastMonthCount = moodBoards.filter {
            $0.styleCategory == style && $0.createdAt >= lastMonth && $0.createdAt < thisMonth
        }.count

        guard lastMonthCount > 0 else { return thisMonthCount > 0 ? 1.0 : 0.0 }
        return Double(thisMonthCount - lastMonthCount) / Double(lastMonthCount)
    }

    private func calculatePreferenceAlignment(moodBoards: [MoodBoard], preferences: StylePreferences?) -> Double {
        guard let preferences else { return 0 }

        var alignmentScore = 0.0
        var totalChecks = 0

        // Check primary style alignment
        if let primaryStyle = preferences.primaryStyle {
            let alignedBoards = moodBoards.filter { $0.styleCategory == primaryStyle }.count
            alignmentScore += Double(alignedBoards) / Double(max(moodBoards.count, 1))
            totalChecks += 1
        }

        // Check color alignment
        if !preferences.primaryColors.isEmpty {
            let colorAlignment = calculateColorAlignment(moodBoards: moodBoards, preferences: preferences)
            alignmentScore += colorAlignment
            totalChecks += 1
        }

        return totalChecks > 0 ? alignmentScore / Double(totalChecks) : 0
    }

    // MARK: - Color Analytics

    private func generateColorAnalytics(
        moodBoards: [MoodBoard],
        colorPalettes: [ColorPalette],
        preferences: StylePreferences?) -> ColorAnalytics {
        let dominantColors = extractDominantColors(from: moodBoards)
        let colorHarmony = analyzeColorHarmony(colorPalettes: colorPalettes)
        let seasonalTrends = analyzeSeasonalColorTrends(colorPalettes: colorPalettes)

        return ColorAnalytics(
            dominantColors: dominantColors,
            colorHarmonyDistribution: colorHarmony,
            seasonalTrends: seasonalTrends,
            paletteUsageStats: calculatePaletteUsageStats(colorPalettes: colorPalettes),
            colorConsistency: calculateColorConsistency(moodBoards: moodBoards, preferences: preferences))
    }

    private func extractDominantColors(from moodBoards: [MoodBoard]) -> [ColorFrequency] {
        var colorCounts: [String: Int] = [:]

        for moodBoard in moodBoards {
            for element in moodBoard.elements {
                if let color = element.elementData.color {
                    // Convert Color to hex string
                    let components = color.cgColor?.components ?? [0, 0, 0, 1]
                    let r = Int(components[0] * 255)
                    let g = Int(components[1] * 255)
                    let b = Int(components[2] * 255)
                    let colorKey = String(format: "#%02X%02X%02X", r, g, b)
                    colorCounts[colorKey, default: 0] += 1
                }
            }
        }

        return colorCounts.map { ColorFrequency(color: Color.fromHexString($0.key) ?? .clear, frequency: $0.value) }
            .sorted { $0.frequency > $1.frequency }
            .prefix(10)
            .map { $0 }
    }

    private func analyzeColorHarmony(colorPalettes: [ColorPalette]) -> [ColorHarmonyType: Int] {
        var harmonyCount: [ColorHarmonyType: Int] = [:]

        for palette in colorPalettes {
            let harmony = analyzeColorHarmonyType(palette: palette)
            harmonyCount[harmony, default: 0] += 1
        }

        return harmonyCount
    }

    private func analyzeColorHarmonyType(palette: ColorPalette) -> ColorHarmonyType {
        // Simplified harmony analysis - in production this would use advanced color theory
        // Convert hex strings to Colors and analyze
        let colors = palette.colors.compactMap { Color.fromHexString($0) }
        guard !colors.isEmpty else { return .monochromatic }

        let hues = colors.map { color -> Double in
            // Extract hue from Color using HSB color space
            extractHue(from: color)
        }

        let hueDifferences = zip(hues, hues.dropFirst()).map { abs($0.0 - $0.1) }
        guard !hueDifferences.isEmpty else { return .monochromatic }
        let avgDifference = hueDifferences.reduce(0, +) / Double(hueDifferences.count)

        switch avgDifference {
        case 0 ..< 30: return .monochromatic
        case 30 ..< 60: return .analogous
        case 150 ..< 210: return .complementary
        case 90 ..< 150: return .triadic
        default: return .tetradic
        }
    }

    /// Extract hue value from Color in degrees (0-360)
    private func extractHue(from color: Color) -> Double {
        // Convert SwiftUI Color to NSColor to access RGB components
        let nsColor = NSColor(color)

        // Convert to RGB color space
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else {
            return 0.0
        }

        let r = rgbColor.redComponent
        let g = rgbColor.greenComponent
        let b = rgbColor.blueComponent

        let maxComponent = max(r, g, b)
        let minComponent = min(r, g, b)
        let delta = maxComponent - minComponent

        // If no saturation, hue is undefined (return 0)
        guard delta > 0.0001 else {
            return 0.0
        }

        var hue: Double = 0.0

        if maxComponent == r {
            hue = 60.0 * (((g - b) / delta).truncatingRemainder(dividingBy: 6.0))
        } else if maxComponent == g {
            hue = 60.0 * (((b - r) / delta) + 2.0)
        } else {
            hue = 60.0 * (((r - g) / delta) + 4.0)
        }

        // Normalize to 0-360 range
        if hue < 0 {
            hue += 360.0
        }

        return hue
    }

    private func analyzeSeasonalColorTrends(colorPalettes: [ColorPalette]) -> [WeddingSeason: [ColorFrequency]] {
        var seasonalTrends: [WeddingSeason: [ColorFrequency]] = [:]

        // Since ColorPalette no longer has season info, we'll analyze all palettes
        // In a future update, we could add season metadata back
        for season in WeddingSeason.allCases {
            var colorCounts: [String: Int] = [:]

            // Extract colors from all palettes
            for palette in colorPalettes {
                for hexColor in palette.colors {
                    colorCounts[hexColor, default: 0] += 1
                }
            }

            seasonalTrends[season] = colorCounts.map {
                ColorFrequency(color: Color.fromHexString($0.key) ?? .clear, frequency: $0.value)
            }.sorted { $0.frequency > $1.frequency }.prefix(5).map { $0 }
        }

        return seasonalTrends
    }

    private func calculatePaletteUsageStats(colorPalettes: [ColorPalette]) -> PaletteUsageStats {
        // Palette usage tracking: Requires database schema addition
        // Future: Add usage_count field to color_palettes table
        // Track when palettes are applied to mood boards or used in designs
        let totalUsage = 0

        // Favorite tracking: Requires database schema addition
        // Future: Add is_favorite field to color_palettes table
        let favoriteCount = 0

        let avgUsage = 0.0

        let mostUsedPalette = colorPalettes.first

        return PaletteUsageStats(
            totalUsage: totalUsage,
            averageUsage: avgUsage,
            favoriteCount: favoriteCount,
            mostUsedPalette: mostUsedPalette?.name)
    }

    private func calculateColorAlignment(moodBoards: [MoodBoard], preferences: StylePreferences) -> Double {
        // Calculate how well mood board colors align with style preferences
        let preferenceColors = Set(preferences.primaryColors.map { $0.toHex() })
        guard !preferenceColors.isEmpty else { return 0 }

        var totalElements = 0
        var alignedElements = 0

        for moodBoard in moodBoards {
            for element in moodBoard.elements {
                if let elementColor = element.elementData.color {
                    totalElements += 1
                    if preferenceColors.contains(elementColor.toHex()) ||
                        preferences.primaryColors.contains(where: { colorsSimilar($0, elementColor) }) {
                        alignedElements += 1
                    }
                }
            }
        }

        return totalElements > 0 ? Double(alignedElements) / Double(totalElements) : 0
    }

    private func calculateColorConsistency(moodBoards: [MoodBoard], preferences: StylePreferences?) -> Double {
        guard let preferences, !preferences.primaryColors.isEmpty else { return 0 }

        return calculateColorAlignment(moodBoards: moodBoards, preferences: preferences)
    }

    // MARK: - Usage Patterns

    private func generateUsagePatterns(
        moodBoards: [MoodBoard],
        colorPalettes: [ColorPalette],
        seatingCharts: [SeatingChart]) -> UsagePatterns {
        let timePatterns = analyzeTimePatterns(
            moodBoards: moodBoards,
            colorPalettes: colorPalettes,
            seatingCharts: seatingCharts)

        let featureUsage = analyzeFeatureUsage(
            moodBoards: moodBoards,
            colorPalettes: colorPalettes,
            seatingCharts: seatingCharts)

        return UsagePatterns(
            timePatterns: timePatterns,
            featureUsage: featureUsage,
            exportPatterns: analyzeExportPatterns(seatingCharts: seatingCharts),
            collaborationStats: analyzeCollaborationStats())
    }

    private func analyzeTimePatterns(
        moodBoards: [MoodBoard],
        colorPalettes: [ColorPalette],
        seatingCharts: [SeatingChart]) -> TimePatterns {
        let calendar = Calendar.current
        var hourlyActivity: [Int: Int] = [:]
        var dailyActivity: [Int: Int] = [:]

        let allDates = moodBoards.map(\.createdAt) +
            colorPalettes.map(\.createdAt) +
            seatingCharts.map(\.createdAt)

        for date in allDates {
            let hour = calendar.component(.hour, from: date)
            let weekday = calendar.component(.weekday, from: date)

            hourlyActivity[hour, default: 0] += 1
            dailyActivity[weekday, default: 0] += 1
        }

        let peakHour = hourlyActivity.max { $0.value < $1.value }?.key ?? 14
        let peakDay = dailyActivity.max { $0.value < $1.value }?.key ?? 1

        return TimePatterns(
            hourlyActivity: hourlyActivity,
            dailyActivity: dailyActivity,
            peakUsageHour: peakHour,
            peakUsageDay: peakDay)
    }

    private func analyzeFeatureUsage(
        moodBoards: [MoodBoard],
        colorPalettes: [ColorPalette],
        seatingCharts: [SeatingChart]) -> FeatureUsage {
        // Export usage tracking: Requires database schema addition
        // Future: Track export events in separate exports table with timestamps
        // Then count: SELECT COUNT(*) FROM exports WHERE tenant_id = ?
        let exportUsage = 0.0

        return FeatureUsage(
            moodBoardUsage: Double(moodBoards.count),
            colorPaletteUsage: Double(colorPalettes.count),
            seatingChartUsage: Double(seatingCharts.count),
            templateUsage: Double(moodBoards.filter(\.isTemplate).count),
            exportUsage: exportUsage
        )
    }

    private func analyzeExportPatterns(seatingCharts: [SeatingChart]) -> ExportPatterns {
        // Export patterns tracking: Requires database schema addition
        // Future implementation:
        // 1. Create exports table: (id, tenant_id, item_id, item_type, format, exported_at)
        // 2. Track exports when user exports mood boards, palettes, or charts
        // 3. Query: SELECT COUNT(*) FROM exports WHERE item_type = 'seating_chart'
        // 4. Calculate: SELECT item_id, COUNT(*) as count FROM exports GROUP BY item_id
        let totalExports = 0
        let chartsWithExports = 0
        let avgExports = totalExports > 0 && seatingCharts.count > 0
            ? Double(totalExports) / Double(seatingCharts.count)
            : 0.0

        return ExportPatterns(
            totalExports: totalExports,
            averageExportsPerChart: avgExports,
            mostExportedChart: seatingCharts.first?.chartName)
    }

    private func analyzeCollaborationStats() -> CollaborationStats {
        // In a real implementation, this would analyze sharing and collaboration data
        CollaborationStats(
            sharedItems: 0,
            collaborators: 0,
            avgCollaborationTime: 0)
    }

    // MARK: - Insights Generation

    private func generateInsights(
        moodBoards: [MoodBoard],
        colorPalettes _: [ColorPalette],
        seatingCharts _: [SeatingChart],
        preferences: StylePreferences?) -> [Insight] {
        var insights: [Insight] = []

        // Style consistency insight
        if let preferences {
            let consistency = calculateStyleConsistency(moodBoards: moodBoards, preferences: preferences)
            if consistency < 0.7 {
                insights.append(Insight(
                    id: "style-consistency",
                    type: .recommendation,
                    title: "Style Consistency",
                    description: "Your mood boards show varied styles. Consider focusing on \(preferences.primaryStyle?.displayName ?? "your preferred style") for better cohesion.",
                    impact: .medium,
                    actionable: true))
            }
        }

        // Color palette usage insight - commented out until usage tracking is implemented
        // let unusedPalettes = colorPalettes.filter { $0.usageCount == 0 }
        // if unusedPalettes.count > 3 {
        //     insights.append(Insight(
        //         id: "unused-palettes",
        //         type: .recommendation,
        //         title: "Unused Color Palettes",
        //         description: "You have \(unusedPalettes.count) unused color palettes. Consider applying them to mood boards or removing them.",
        //         impact: .low,
        //         actionable: true
        //     ))
        // }

        // Export recommendation - commented out until export tracking is implemented
        // let unexportedCharts = seatingCharts.filter { $0.exportCount == 0 && $0.isFinalized }
        // if unexportedCharts.count > 0 {
        //     insights.append(Insight(
        //         id: "export-reminder",
        //         type: .recommendation,
        //         title: "Export Finalized Charts",
        //         description: "You have \(unexportedCharts.count) finalized seating charts that haven't been exported yet.",
        //         impact: .high,
        //         actionable: true
        //     ))
        // }

        // Performance insight
        if performanceService.performanceMetrics.memoryUsage > 400 {
            insights.append(Insight(
                id: "performance-warning",
                type: .recommendation,
                title: "High Memory Usage",
                description: "Memory usage is high. Consider optimizing images or clearing cache.",
                impact: .medium,
                actionable: true))
        }

        return insights.sorted { $0.impact.rawValue > $1.impact.rawValue }
    }

    // MARK: - Helper Methods

    private func colorsSimilar(_ color1: Color, _ color2: Color, threshold: Double = 30) -> Bool {
        let hsb1 = color1.hsb
        let hsb2 = color2.hsb

        let hueDiff = abs(hsb1.hue - hsb2.hue)
        let satDiff = abs(hsb1.saturation - hsb2.saturation)
        let brightDiff = abs(hsb1.brightness - hsb2.brightness)

        return hueDiff + satDiff + brightDiff < threshold
    }

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
