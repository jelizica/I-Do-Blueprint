//
//  AnalyticsOverviewService.swift
//  I Do Blueprint
//
//  Overview metrics calculation service
//

import Foundation

/// Service responsible for calculating overview metrics
actor AnalyticsOverviewService {
    private let logger = AppLogger.general
    
    // MARK: - Overview Metrics
    
    func generateOverviewMetrics(
        moodBoards: [MoodBoard],
        colorPalettes: [ColorPalette],
        seatingCharts: [SeatingChart]
    ) -> OverviewMetrics {
        let totalElements = moodBoards.reduce(into: 0) { $0 += $1.elements.count }
        
        // Export tracking: Requires database schema addition
        // Future: Add export_count field to mood_boards, color_palettes, and seating_charts tables
        let totalExports = 0
        
        let recentActivity = calculateRecentActivity(
            moodBoards: moodBoards,
            colorPalettes: colorPalettes,
            seatingCharts: seatingCharts
        )
        
        return OverviewMetrics(
            totalMoodBoards: moodBoards.count,
            totalColorPalettes: colorPalettes.count,
            totalSeatingCharts: seatingCharts.count,
            totalElements: totalElements,
            totalExports: totalExports,
            recentActivity: recentActivity,
            completionRate: calculateCompletionRate(
                moodBoards: moodBoards,
                seatingCharts: seatingCharts
            )
        )
    }
    
    // MARK: - Private Helpers
    
    private func calculateRecentActivity(
        moodBoards: [MoodBoard],
        colorPalettes: [ColorPalette],
        seatingCharts: [SeatingChart]
    ) -> [ActivityMetric] {
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
                seatingCharts: chartCount
            ))
        }
        
        return activities.reversed()
    }
    
    private func calculateCompletionRate(
        moodBoards: [MoodBoard],
        seatingCharts: [SeatingChart]
    ) -> Double {
        let completedBoards = moodBoards.filter { !$0.elements.isEmpty }.count
        let finalizedCharts = seatingCharts.filter(\.isFinalized).count
        let totalItems = moodBoards.count + seatingCharts.count
        
        guard totalItems > 0 else { return 0 }
        return Double(completedBoards + finalizedCharts) / Double(totalItems)
    }
}
