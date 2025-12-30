//
//  AnalyticsStyleService.swift
//  I Do Blueprint
//
//  Style analytics calculation service
//

import Foundation
import SwiftUI

/// Service responsible for style analytics and trend analysis
actor AnalyticsStyleService {
    private let logger = AppLogger.general
    
    // MARK: - Style Analytics
    
    func generateStyleAnalytics(
        moodBoards: [MoodBoard],
        preferences: StylePreferences?
    ) -> StyleAnalytics {
        let styleDistribution = Dictionary(grouping: moodBoards, by: { $0.styleCategory })
            .mapValues { $0.count }
        
        let mostUsedStyle = styleDistribution.max(by: { $0.value < $1.value })?.key
        let styleConsistency = calculateStyleConsistency(
            moodBoards: moodBoards,
            preferences: preferences
        )
        
        let trendingStyles = calculateTrendingStyles(moodBoards: moodBoards)
        
        return StyleAnalytics(
            styleDistribution: styleDistribution,
            mostUsedStyle: mostUsedStyle,
            styleConsistency: styleConsistency,
            trendingStyles: trendingStyles,
            preferenceAlignment: calculatePreferenceAlignment(
                moodBoards: moodBoards,
                preferences: preferences
            )
        )
    }
    
    // MARK: - Private Helpers
    
    private func calculateStyleConsistency(
        moodBoards: [MoodBoard],
        preferences: StylePreferences?
    ) -> Double {
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
            StyleTrend(
                style: style,
                count: count,
                growth: calculateStyleGrowth(style: style, moodBoards: moodBoards)
            )
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
    
    private func calculatePreferenceAlignment(
        moodBoards: [MoodBoard],
        preferences: StylePreferences?
    ) -> Double {
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
            let colorAlignment = calculateColorAlignment(
                moodBoards: moodBoards,
                preferences: preferences
            )
            alignmentScore += colorAlignment
            totalChecks += 1
        }
        
        return totalChecks > 0 ? alignmentScore / Double(totalChecks) : 0
    }
    
    private func calculateColorAlignment(
        moodBoards: [MoodBoard],
        preferences: StylePreferences
    ) -> Double {
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
    
    private func colorsSimilar(_ color1: Color, _ color2: Color, threshold: Double = 30) -> Bool {
        let hsb1 = color1.hsb
        let hsb2 = color2.hsb
        
        let hueDiff = abs(hsb1.hue - hsb2.hue)
        let satDiff = abs(hsb1.saturation - hsb2.saturation)
        let brightDiff = abs(hsb1.brightness - hsb2.brightness)
        
        return hueDiff + satDiff + brightDiff < threshold
    }
}
