//
//  AnalyticsInsightsService.swift
//  I Do Blueprint
//
//  Insights generation and recommendations service
//

import Foundation

/// Service responsible for generating insights and recommendations
actor AnalyticsInsightsService {
    private let logger = AppLogger.general
    
    // MARK: - Insights Generation
    
    func generateInsights(
        moodBoards: [MoodBoard],
        colorPalettes: [ColorPalette],
        seatingCharts: [SeatingChart],
        preferences: StylePreferences?,
        styleConsistency: Double,
        memoryUsage: Double
    ) -> [Insight] {
        var insights: [Insight] = []
        
        // Style consistency insight
        if let preferences {
            if styleConsistency < 0.7 {
                insights.append(Insight(
                    id: "style-consistency",
                    type: .recommendation,
                    title: "Style Consistency",
                    description: "Your mood boards show varied styles. Consider focusing on \(preferences.primaryStyle?.displayName ?? "your preferred style") for better cohesion.",
                    impact: .medium,
                    actionable: true
                ))
            }
        }
        
        // Color palette usage insight - commented out until usage tracking is implemented
        // let unusedPalettes = colorPalettes.filter { $0.usageCount == 0 }
        // if unusedPalettes.count > 3 {
        //     insights.append(Insight(
        //         id: "unused-palettes",
        //         type: .recommendation,
        //         title: "Unused Color Palettes",
        //         description: "You have \(unusedPalettes.count) unused color palettes.",
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
        //         description: "You have \(unexportedCharts.count) finalized seating charts.",
        //         impact: .high,
        //         actionable: true
        //     ))
        // }
        
        // Performance insight
        if memoryUsage > 400 {
            insights.append(Insight(
                id: "performance-warning",
                type: .recommendation,
                title: "High Memory Usage",
                description: "Memory usage is high. Consider optimizing images or clearing cache.",
                impact: .medium,
                actionable: true
            ))
        }
        
        return insights.sorted { $0.impact.rawValue > $1.impact.rawValue }
    }
}
