//
//  AnalyticsHelpers.swift
//  I Do Blueprint
//
//  Helper functions for analytics dashboard
//

import Foundation

// MARK: - Analytics Helpers

extension AnalyticsDashboardView {

    func calculateTrend(for type: MetricType) -> TrendDirection {
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

    var memoryStatus: MetricStatus {
        let usage = analyticsService.dashboardData.performanceMetrics.memoryUsage
        if usage > 400 { return .warning }
        if usage > 200 { return .caution }
        return .good
    }

    var cacheStatus: MetricStatus {
        let size = Int(performanceService.imageCacheSize)
        if size > 80_000_000 { return .warning }
        if size > 50_000_000 { return .caution }
        return .good
    }

    func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
