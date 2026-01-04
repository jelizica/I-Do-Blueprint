//
//  Gradients.swift
//  I Do Blueprint
//
//  Gradient definitions for the application
//

import SwiftUI

// MARK: - Gradients

enum AppGradients {
    // MARK: - Mesh Gradient Background (V7 Dashboard)
    
    /// Mesh gradient background inspired by glassmorphism design
    /// Creates a soft, multi-color background with blurred color blobs
    /// Use for: Dashboard V7 background, premium screens
    static let meshGradientBackground = LinearGradient(
        colors: [
            Color.fromHex("F3F4F6"),  // Base gray
            Color.fromHex("F4D0D0").opacity(0.6),  // Soft pink
            Color.fromHex("D0E8D0").opacity(0.6),  // Soft sage
            Color.fromHex("F5F5DC").opacity(0.4)   // Soft cream
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Wedding pink accent color for glassmorphism UI
    static let weddingPink = Color.fromHex("FF5C8D")
    
    /// Soft pink for backgrounds
    static let softPink = Color.fromHex("F0C8C8")
    
    /// Sage green for accents
    static let sageGreen = Color.fromHex("C8E1C8")
    
    /// Dark sage for text/icons
    static let sageDark = Color.fromHex("8FAE8F")
    
    // MARK: - Theme-Aware Mesh Gradient Colors
    
    /// Returns mesh gradient colors based on theme settings
    /// - Parameter themeSettings: The user's theme settings
    /// - Returns: A tuple of (baseColor, blob1Color, blob2Color, blob3Color)
    static func meshGradientColors(for themeSettings: ThemeSettings) -> (base: Color, blob1: Color, blob2: Color, blob3: Color) {
        if themeSettings.useCustomWeddingColors {
            // Derive colors from custom wedding colors
            let color1 = Color.fromHex(themeSettings.weddingColor1.replacingOccurrences(of: "#", with: ""))
            let color2 = Color.fromHex(themeSettings.weddingColor2.replacingOccurrences(of: "#", with: ""))
            
            return (
                base: Color.fromHex("F3F4F6"),  // Keep neutral base
                blob1: color1.opacity(0.6),
                blob2: color2.opacity(0.6),
                blob3: color1.opacity(0.4)  // Lighter version of color1
            )
        } else {
            // Use theme-based colors
            return meshGradientColorsForScheme(themeSettings.colorScheme)
        }
    }
    
    /// Returns mesh gradient colors for a specific color scheme
    /// - Parameter colorScheme: The theme name
    /// - Returns: A tuple of (baseColor, blob1Color, blob2Color, blob3Color)
    private static func meshGradientColorsForScheme(_ colorScheme: String) -> (base: Color, blob1: Color, blob2: Color, blob3: Color) {
        switch colorScheme {
        case "sage-serenity":
            return (
                base: Color.fromHex("F3F4F6"),
                blob1: Color.fromHex("E8F5E9").opacity(0.6),  // Light sage
                blob2: Color.fromHex("5A9070").opacity(0.6),  // Eucalyptus green
                blob3: Color.fromHex("C8E6C9").opacity(0.5)   // Soft sage
            )
        case "lavender-dream":
            return (
                base: Color.fromHex("F3F4F6"),
                blob1: Color.fromHex("EDE7F6").opacity(0.6),  // Light lavender
                blob2: Color.fromHex("7E57C2").opacity(0.6),  // Deep lavender
                blob3: Color.fromHex("D1C4E9").opacity(0.5)   // Soft lavender
            )
        case "terracotta-warm":
            return (
                base: Color.fromHex("F3F4F6"),
                blob1: Color.fromHex("FBE9E7").opacity(0.6),  // Light terracotta
                blob2: Color.fromHex("BF6952").opacity(0.6),  // Warm terracotta
                blob3: Color.fromHex("FFCCBC").opacity(0.5)   // Soft terracotta
            )
        case "blush-romance":
            fallthrough
        default:
            // Default blush romance theme (original colors)
            return (
                base: Color.fromHex("F3F4F6"),
                blob1: Color.fromHex("F4D0D0").opacity(0.6),  // Soft pink
                blob2: Color.fromHex("D0E8D0").opacity(0.6),  // Soft sage
                blob3: Color.fromHex("F5F5DC").opacity(0.4)   // Soft cream
            )
        }
    }
    
    /// App-wide background gradient used on the dashboard background
    static let appBackground = LinearGradient(
        colors: [
            Color.fromHex("F8F9FA"),
            Color.fromHex("E9ECEF")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Dashboard header gradient: light purple → eucalyptus green (default)
    static let dashboardHeader = LinearGradient(
        colors: [
            Color.fromHex("EAE2FF"), // light purple
            Color.fromHex("5A9070")  // eucalyptus green (from AppColors.Dashboard.eventAction)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Creates a custom dashboard header gradient from user's wedding colors
    /// - Parameters:
    ///   - color1: First hex color (left side of gradient)
    ///   - color2: Second hex color (right side of gradient)
    /// - Returns: A LinearGradient using the custom colors
    static func customDashboardHeader(color1: String, color2: String) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.fromHex(color1.replacingOccurrences(of: "#", with: "")),
                Color.fromHex(color2.replacingOccurrences(of: "#", with: ""))
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Creates a dashboard header gradient based on theme settings
    /// - Parameter themeSettings: The user's theme settings
    /// - Returns: Either the custom wedding colors gradient or the default theme gradient
    static func dashboardHeader(for themeSettings: ThemeSettings) -> LinearGradient {
        if themeSettings.useCustomWeddingColors {
            return customDashboardHeader(
                color1: themeSettings.weddingColor1,
                color2: themeSettings.weddingColor2
            )
        } else {
            // Use theme-based colors
            return themeGradient(for: themeSettings.colorScheme)
        }
    }

    /// Returns a gradient based on the selected color scheme/theme
    /// - Parameter colorScheme: The theme name (e.g., "blush-romance", "sage-serenity")
    /// - Returns: A LinearGradient matching the theme
    static func themeGradient(for colorScheme: String) -> LinearGradient {
        switch colorScheme {
        case "sage-serenity":
            return LinearGradient(
                colors: [
                    Color.fromHex("E8F5E9"), // light sage
                    Color.fromHex("5A9070")  // eucalyptus green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "lavender-dream":
            return LinearGradient(
                colors: [
                    Color.fromHex("EDE7F6"), // light lavender
                    Color.fromHex("7E57C2")  // deep lavender
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "terracotta-warm":
            return LinearGradient(
                colors: [
                    Color.fromHex("FBE9E7"), // light terracotta
                    Color.fromHex("BF6952")  // warm terracotta
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "blush-romance":
            fallthrough
        default:
            // Default blush romance theme
            return LinearGradient(
                colors: [
                    Color.fromHex("EAE2FF"), // light purple/blush
                    Color.fromHex("5A9070")  // eucalyptus green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
