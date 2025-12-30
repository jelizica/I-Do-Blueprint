//
//  AnalyticsColorService.swift
//  I Do Blueprint
//
//  Color analytics and harmony analysis service
//

import Foundation
import SwiftUI

/// Service responsible for color analytics, harmony analysis, and seasonal trends
actor AnalyticsColorService {
    private let logger = AppLogger.general
    
    // MARK: - Color Analytics
    
    func generateColorAnalytics(
        moodBoards: [MoodBoard],
        colorPalettes: [ColorPalette],
        preferences: StylePreferences?
    ) -> ColorAnalytics {
        let dominantColors = extractDominantColors(from: moodBoards)
        let colorHarmony = analyzeColorHarmony(colorPalettes: colorPalettes)
        let seasonalTrends = analyzeSeasonalColorTrends(colorPalettes: colorPalettes)
        
        return ColorAnalytics(
            dominantColors: dominantColors,
            colorHarmonyDistribution: colorHarmony,
            seasonalTrends: seasonalTrends,
            paletteUsageStats: calculatePaletteUsageStats(colorPalettes: colorPalettes),
            colorConsistency: calculateColorConsistency(
                moodBoards: moodBoards,
                preferences: preferences
            )
        )
    }
    
    // MARK: - Private Helpers - Color Extraction
    
    private func extractDominantColors(from moodBoards: [MoodBoard]) -> [ColorFrequency] {
        var colorCounts: [String: Int] = [:]
        
        for moodBoard in moodBoards {
            for element in moodBoard.elements {
                if let color = element.elementData.color {
                    let colorKey = colorToHex(color)
                    colorCounts[colorKey, default: 0] += 1
                }
            }
        }
        
        return colorCounts.map {
            ColorFrequency(color: Color.fromHexString($0.key) ?? .clear, frequency: $0.value)
        }
        .sorted { $0.frequency > $1.frequency }
        .prefix(10)
        .map { $0 }
    }
    
    private func colorToHex(_ color: Color) -> String {
        let components = color.cgColor?.components ?? [0, 0, 0, 1]
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    // MARK: - Private Helpers - Color Harmony
    
    private func analyzeColorHarmony(colorPalettes: [ColorPalette]) -> [ColorHarmonyType: Int] {
        var harmonyCount: [ColorHarmonyType: Int] = [:]
        
        for palette in colorPalettes {
            let harmony = analyzeColorHarmonyType(palette: palette)
            harmonyCount[harmony, default: 0] += 1
        }
        
        return harmonyCount
    }
    
    private func analyzeColorHarmonyType(palette: ColorPalette) -> ColorHarmonyType {
        let colors = palette.colors.compactMap { Color.fromHexString($0) }
        guard !colors.isEmpty else { return .monochromatic }
        
        let hues = colors.map { extractHue(from: $0) }
        
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
        let nsColor = NSColor(color)
        
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else {
            return 0.0
        }
        
        let r = rgbColor.redComponent
        let g = rgbColor.greenComponent
        let b = rgbColor.blueComponent
        
        let maxComponent = max(r, g, b)
        let minComponent = min(r, g, b)
        let delta = maxComponent - minComponent
        
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
        
        if hue < 0 {
            hue += 360.0
        }
        
        return hue
    }
    
    // MARK: - Private Helpers - Seasonal Trends
    
    private func analyzeSeasonalColorTrends(
        colorPalettes: [ColorPalette]
    ) -> [WeddingSeason: [ColorFrequency]] {
        var seasonalTrends: [WeddingSeason: [ColorFrequency]] = [:]
        
        for season in WeddingSeason.allCases {
            var colorCounts: [String: Int] = [:]
            
            for palette in colorPalettes {
                for hexColor in palette.colors {
                    colorCounts[hexColor, default: 0] += 1
                }
            }
            
            seasonalTrends[season] = colorCounts.map {
                ColorFrequency(color: Color.fromHexString($0.key) ?? .clear, frequency: $0.value)
            }
            .sorted { $0.frequency > $1.frequency }
            .prefix(5)
            .map { $0 }
        }
        
        return seasonalTrends
    }
    
    // MARK: - Private Helpers - Usage Stats
    
    private func calculatePaletteUsageStats(colorPalettes: [ColorPalette]) -> PaletteUsageStats {
        // Palette usage tracking: Requires database schema addition
        // Future: Add usage_count field to color_palettes table
        let totalUsage = 0
        let favoriteCount = 0
        let avgUsage = 0.0
        let mostUsedPalette = colorPalettes.first
        
        return PaletteUsageStats(
            totalUsage: totalUsage,
            averageUsage: avgUsage,
            favoriteCount: favoriteCount,
            mostUsedPalette: mostUsedPalette?.name
        )
    }
    
    private func calculateColorConsistency(
        moodBoards: [MoodBoard],
        preferences: StylePreferences?
    ) -> Double {
        guard let preferences, !preferences.primaryColors.isEmpty else { return 0 }
        
        return calculateColorAlignment(moodBoards: moodBoards, preferences: preferences)
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
