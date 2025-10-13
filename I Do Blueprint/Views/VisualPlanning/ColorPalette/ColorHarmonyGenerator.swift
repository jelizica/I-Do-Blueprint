//
//  ColorHarmonyGenerator.swift
//  My Wedding Planning App
//
//  Generates color harmonies based on color theory principles
//

import SwiftUI

enum ColorHarmonyGenerator {
    static func generateHarmony(baseColor: Color, type: ColorHarmonyType) -> [Color] {
        let hsbComponents = baseColor.hsbComponents
        let baseHue = hsbComponents.hue
        let baseSaturation = hsbComponents.saturation
        let baseBrightness = hsbComponents.brightness

        switch type {
        case .complementary:
            return generateComplementary(hue: baseHue, saturation: baseSaturation, brightness: baseBrightness)

        case .triadic:
            return generateTriadic(hue: baseHue, saturation: baseSaturation, brightness: baseBrightness)

        case .analogous:
            return generateAnalogous(hue: baseHue, saturation: baseSaturation, brightness: baseBrightness)

        case .splitComplementary:
            return generateSplitComplementary(hue: baseHue, saturation: baseSaturation, brightness: baseBrightness)

        case .tetradic:
            return generateTetradic(hue: baseHue, saturation: baseSaturation, brightness: baseBrightness)

        case .monochromatic:
            return generateMonochromatic(hue: baseHue, saturation: baseSaturation, brightness: baseBrightness)

        case .custom:
            // For custom harmony, return the base color
            return [baseColor]
        }
    }

    // MARK: - Harmony Generation Methods

    private static func generateComplementary(hue: Double, saturation: Double, brightness: Double) -> [Color] {
        let complementaryHue = normalizeHue(hue + 0.5)

        return [
            Color(hue: complementaryHue, saturation: saturation * 0.8, brightness: brightness * 0.9),
            Color(hue: hue, saturation: saturation * 0.6, brightness: brightness * 1.1),
            Color(hue: complementaryHue, saturation: saturation * 0.4, brightness: brightness * 0.7)
        ]
    }

    private static func generateTriadic(hue: Double, saturation: Double, brightness: Double) -> [Color] {
        let hue1 = normalizeHue(hue + 1.0 / 3.0)
        let hue2 = normalizeHue(hue + 2.0 / 3.0)

        return [
            Color(hue: hue1, saturation: saturation * 0.8, brightness: brightness * 0.9),
            Color(hue: hue2, saturation: saturation * 0.7, brightness: brightness * 1.0),
            Color(hue: hue, saturation: saturation * 0.5, brightness: brightness * 0.8)
        ]
    }

    private static func generateAnalogous(hue: Double, saturation: Double, brightness: Double) -> [Color] {
        let hue1 = normalizeHue(hue - 1.0 / 12.0) // -30 degrees
        let hue2 = normalizeHue(hue + 1.0 / 12.0) // +30 degrees

        return [
            Color(hue: hue1, saturation: saturation * 0.9, brightness: brightness * 0.95),
            Color(hue: hue2, saturation: saturation * 0.8, brightness: brightness * 1.05),
            Color(hue: hue, saturation: saturation * 0.6, brightness: brightness * 0.85)
        ]
    }

    private static func generateSplitComplementary(hue: Double, saturation: Double, brightness: Double) -> [Color] {
        let complementary = normalizeHue(hue + 0.5)
        let hue1 = normalizeHue(complementary - 1.0 / 12.0) // -30 degrees from complementary
        let hue2 = normalizeHue(complementary + 1.0 / 12.0) // +30 degrees from complementary

        return [
            Color(hue: hue1, saturation: saturation * 0.8, brightness: brightness * 0.9),
            Color(hue: hue2, saturation: saturation * 0.7, brightness: brightness * 1.0),
            Color(hue: hue, saturation: saturation * 0.5, brightness: brightness * 0.8)
        ]
    }

    private static func generateTetradic(hue: Double, saturation: Double, brightness: Double) -> [Color] {
        let hue1 = normalizeHue(hue + 0.25) // +90 degrees
        let hue2 = normalizeHue(hue + 0.5) // +180 degrees (complementary)
        let hue3 = normalizeHue(hue + 0.75) // +270 degrees

        return [
            Color(hue: hue1, saturation: saturation * 0.8, brightness: brightness * 0.9),
            Color(hue: hue2, saturation: saturation * 0.7, brightness: brightness * 1.0),
            Color(hue: hue3, saturation: saturation * 0.6, brightness: brightness * 0.8)
        ]
    }

    private static func generateMonochromatic(hue: Double, saturation: Double, brightness: Double) -> [Color] {
        [
            Color(hue: hue, saturation: saturation * 0.7, brightness: brightness * 1.2),
            Color(hue: hue, saturation: saturation * 0.5, brightness: brightness * 0.8),
            Color(hue: hue, saturation: saturation * 0.3, brightness: brightness * 0.6)
        ]
    }

    // MARK: - Utility Methods

    private static func normalizeHue(_ hue: Double) -> Double {
        var normalizedHue = hue
        while normalizedHue >= 1.0 {
            normalizedHue -= 1.0
        }
        while normalizedHue < 0.0 {
            normalizedHue += 1.0
        }
        return normalizedHue
    }

    // MARK: - Wedding-Specific Color Schemes

    static func generateWeddingScheme(style: StyleCategory, baseColor: Color) -> [Color] {
        let hsbComponents = baseColor.hsbComponents
        let baseHue = hsbComponents.hue
        let baseSaturation = hsbComponents.saturation
        let baseBrightness = hsbComponents.brightness

        switch style {
        case .romantic:
            return generateRomanticScheme(hue: baseHue, saturation: baseSaturation, brightness: baseBrightness)

        case .modern:
            return generateModernScheme(hue: baseHue, saturation: baseSaturation, brightness: baseBrightness)

        case .rustic:
            return generateRusticScheme(hue: baseHue, saturation: baseSaturation, brightness: baseBrightness)

        case .garden:
            return generateGardenScheme(hue: baseHue, saturation: baseSaturation, brightness: baseBrightness)

        case .vintage:
            return generateVintageScheme(hue: baseHue, saturation: baseSaturation, brightness: baseBrightness)

        case .minimalist:
            return generateMinimalistScheme(hue: baseHue, saturation: baseSaturation, brightness: baseBrightness)

        default:
            return generateComplementary(hue: baseHue, saturation: baseSaturation, brightness: baseBrightness)
        }
    }

    private static func generateRomanticScheme(hue: Double, saturation: Double, brightness: Double) -> [Color] {
        // Soft, muted colors with pink and cream tones
        [
            Color(hue: normalizeHue(hue + 0.1), saturation: saturation * 0.6, brightness: brightness * 1.1),
            Color(hue: 0.95, saturation: 0.3, brightness: 0.95), // Soft pink
            Color(hue: 0.15, saturation: 0.1, brightness: 0.98) // Cream
        ]
    }

    private static func generateModernScheme(hue: Double, saturation: Double, brightness: Double) -> [Color] {
        // Bold, clean colors with high contrast
        [
            Color(hue: normalizeHue(hue + 0.5), saturation: saturation * 1.0, brightness: brightness * 0.8),
            Color(hue: 0.0, saturation: 0.0, brightness: 0.9), // Light gray
            Color(hue: 0.0, saturation: 0.0, brightness: 0.1) // Dark gray
        ]
    }

    private static func generateRusticScheme(hue _: Double, saturation _: Double, brightness _: Double) -> [Color] {
        // Earth tones and warm colors
        [
            Color(hue: 0.08, saturation: 0.6, brightness: 0.7), // Warm brown
            Color(hue: 0.12, saturation: 0.4, brightness: 0.8), // Beige
            Color(hue: 0.25, saturation: 0.7, brightness: 0.6) // Forest green
        ]
    }

    private static func generateGardenScheme(hue _: Double, saturation _: Double, brightness _: Double) -> [Color] {
        // Natural greens and florals
        [
            Color(hue: 0.33, saturation: 0.7, brightness: 0.7), // Green
            Color(hue: 0.85, saturation: 0.5, brightness: 0.9), // Soft purple
            Color(hue: 0.15, saturation: 0.3, brightness: 0.95) // Ivory
        ]
    }

    private static func generateVintageScheme(hue: Double, saturation: Double, brightness: Double) -> [Color] {
        // Muted, aged colors
        [
            Color(hue: normalizeHue(hue - 0.1), saturation: saturation * 0.5, brightness: brightness * 0.8),
            Color(hue: 0.05, saturation: 0.4, brightness: 0.85), // Dusty rose
            Color(hue: 0.15, saturation: 0.2, brightness: 0.9) // Antique white
        ]
    }

    private static func generateMinimalistScheme(hue: Double, saturation: Double, brightness: Double) -> [Color] {
        // Simple, neutral palette
        [
            Color(hue: hue, saturation: saturation * 0.3, brightness: brightness * 1.0),
            Color(hue: 0.0, saturation: 0.0, brightness: 0.95), // Off-white
            Color(hue: 0.0, saturation: 0.0, brightness: 0.2) // Charcoal
        ]
    }
}

// MARK: - Color Analysis Tools

enum ColorAnalyzer {
    static func getColorTemperature(_ color: Color) -> ColorTemperature {
        let hue = color.hsbComponents.hue

        if (hue >= 0.0 && hue <= 0.16) || (hue >= 0.83 && hue <= 1.0) {
            return .warm // Reds, oranges, yellows
        } else if hue >= 0.33, hue <= 0.66 {
            return .cool // Greens, blues, purples
        } else {
            return .neutral
        }
    }

    static func getColorMood(_ color: Color) -> ColorMood {
        let hsb = color.hsbComponents

        if hsb.saturation > 0.7, hsb.brightness > 0.7 {
            return .energetic
        } else if hsb.saturation < 0.3, hsb.brightness > 0.8 {
            return .peaceful
        } else if hsb.brightness < 0.4 {
            return .dramatic
        } else {
            return .balanced
        }
    }

    static func isColorSuitableForWedding(_ color: Color, style: StyleCategory) -> Bool {
        let mood = getColorMood(color)
        let temperature = getColorTemperature(color)

        switch style {
        case .romantic:
            return mood == .peaceful || mood == .balanced
        case .modern:
            return mood == .dramatic || mood == .balanced
        case .rustic:
            return temperature == .warm && (mood == .peaceful || mood == .balanced)
        case .garden:
            return temperature == .cool && mood != .dramatic
        default:
            return true
        }
    }
}

enum ColorTemperature {
    case warm, cool, neutral
}

enum ColorMood {
    case energetic, peaceful, dramatic, balanced
}
