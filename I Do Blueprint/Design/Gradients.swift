//
//  Gradients.swift
//  I Do Blueprint
//
//  Gradient definitions for the application
//

import SwiftUI

// MARK: - Gradients

enum AppGradients {
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
