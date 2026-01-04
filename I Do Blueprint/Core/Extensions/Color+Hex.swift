//
//  Color+Hex.swift
//  I Do Blueprint
//
//  Created on 2025-12-24.
//

import SwiftUI
import AppKit

extension Color {
    /// Creates a Color from a hex string
    /// - Parameter hex: The hex string (e.g., "#FF5733" or "FF5733")
    /// - Returns: A Color instance, or nil if the hex string is invalid
    static func fromHexString(_ hex: String) -> Color? {
        return Color(hex: hex)
    }

    /// Creates a Color from a hex string (non-optional version)
    /// - Parameter hex: The hex string (e.g., "#FF5733", "FF5733", "RGB", or "ARGB")
    /// - Returns: A Color instance (defaults to black if invalid)
    static func fromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Converts a Color to a hex string
    /// - Returns: A hex string in the format "#RRGGBB" or "#AARRGGBB" (if alpha < 1.0)
    var hexString: String {
        let nsColor = NSColor(self)
        guard let rgb = nsColor.usingColorSpace(.sRGB) else { return "#000000" }
        let alpha = Int(rgb.alphaComponent * 255)
        let red = Int(rgb.redComponent * 255)
        let green = Int(rgb.greenComponent * 255)
        let blue = Int(rgb.blueComponent * 255)

        // Include alpha in ARGB format when alpha < 1.0 to match fromHex expectations
        if rgb.alphaComponent < 1.0 {
            return String(format: "#%02X%02X%02X%02X", alpha, red, green, blue)
        } else {
            return String(format: "#%02X%02X%02X", red, green, blue)
        }
    }

    /// Calculate relative luminance using WCAG formula
    /// Used to determine if text should be light or dark for accessibility
    /// - Returns: A value between 0 (darkest) and 1 (lightest)
    var luminance: Double {
        let nsColor = NSColor(self)
        guard let rgb = nsColor.usingColorSpace(.sRGB) else { return 0 }

        // Convert to linear RGB
        func linearize(_ component: Double) -> Double {
            if component <= 0.03928 {
                return component / 12.92
            } else {
                return pow((component + 0.055) / 1.055, 2.4)
            }
        }

        let r = linearize(rgb.redComponent)
        let g = linearize(rgb.greenComponent)
        let b = linearize(rgb.blueComponent)

        // WCAG relative luminance formula
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Darken a color by a percentage
    /// - Parameter percentage: Amount to darken (0.0 to 1.0, where 0.3 = 30% darker)
    /// - Returns: A darker version of the color
    func darkened(by percentage: Double = 0.3) -> Color {
        let nsColor = NSColor(self)
        guard let rgb = nsColor.usingColorSpace(.sRGB) else { return self }

        let factor = 1.0 - percentage
        return Color(
            .sRGB,
            red: rgb.redComponent * factor,
            green: rgb.greenComponent * factor,
            blue: rgb.blueComponent * factor,
            opacity: rgb.alphaComponent
        )
    }

    /// Lighten a color by a percentage
    /// - Parameter percentage: Amount to lighten (0.0 to 1.0, where 0.3 = 30% lighter)
    /// - Returns: A lighter version of the color
    func lightened(by percentage: Double = 0.3) -> Color {
        let nsColor = NSColor(self)
        guard let rgb = nsColor.usingColorSpace(.sRGB) else { return self }

        let factor = percentage
        return Color(
            .sRGB,
            red: rgb.redComponent + (1.0 - rgb.redComponent) * factor,
            green: rgb.greenComponent + (1.0 - rgb.greenComponent) * factor,
            blue: rgb.blueComponent + (1.0 - rgb.blueComponent) * factor,
            opacity: rgb.alphaComponent
        )
    }

    /// Adjust color saturation
    /// - Parameter percentage: Amount to adjust (-1.0 to 1.0, where -0.5 = 50% less saturated, 0.5 = 50% more saturated)
    /// - Returns: A color with adjusted saturation
    func adjustedSaturation(by percentage: Double) -> Color {
        let nsColor = NSColor(self)
        guard let rgb = nsColor.usingColorSpace(.sRGB) else { return self }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        NSColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let newSaturation = max(0, min(1, saturation + CGFloat(percentage)))

        return Color(hue: Double(hue), saturation: Double(newSaturation), brightness: Double(brightness), opacity: Double(alpha))
    }
}
