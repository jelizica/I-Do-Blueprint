//
//  AccessibilityAnalyzer.swift
//  I Do Blueprint
//
//  WCAG accessibility analysis for color combinations
//

import AppKit
import Foundation

/// Pure functions for accessibility analysis
enum ColorAccessibilityAnalyzer {
    
    // MARK: - Accessibility Info Generation
    
    static func generateAccessibilityInfo(for colors: [ExtractedColor]) -> AccessibilityInfo {
        var contrastPairs: [ContrastPair] = []

        for i in 0 ..< colors.count {
            for j in (i + 1) ..< colors.count {
                let ratio = ColorSpaceConverter.calculateContrastRatio(colors[i].color, colors[j].color)
                contrastPairs.append(ContrastPair(
                    color1: colors[i].color,
                    color2: colors[j].color,
                    ratio: ratio,
                    wcagAA: ratio >= 4.5,
                    wcagAAA: ratio >= 7.0))
            }
        }

        let overallCompliance = contrastPairs.contains { $0.wcagAA }
        let recommendations = generateAccessibilityRecommendations(for: contrastPairs)

        return AccessibilityInfo(
            contrastPairs: contrastPairs,
            overallCompliance: overallCompliance,
            recommendations: recommendations)
    }
    
    // MARK: - Recommendations
    
    static func generateAccessibilityRecommendations(for contrastPairs: [ContrastPair]) -> [String] {
        var recommendations: [String] = []

        let failingPairs = contrastPairs.filter { !$0.wcagAA }
        if !failingPairs.isEmpty {
            recommendations
                .append(
                    "Consider adjusting colors for better contrast - \(failingPairs.count) color pairs don't meet WCAG AA standards")
        }

        let aaaCompliantPairs = contrastPairs.filter(\.wcagAAA)
        if aaaCompliantPairs.count == contrastPairs.count {
            recommendations.append("Excellent! All color combinations meet WCAG AAA standards")
        }

        return recommendations
    }
}
