//
//  AvatarHelpers.swift
//  My Wedding Planning App
//
//  DiceBear Personas API integration helpers
//  Created for Seating Chart V2
//

import Foundation
import SwiftUI

/// Helper utilities for generating and managing DiceBear Personas avatars
struct AvatarHelpers {

    // MARK: - Color Palette

    /// Wedding theme color palette for avatar backgrounds
    static let weddingAvatarColors = [
        "d9a5d9",  // Lavender
        "ffe0d4",  // Peach
        "d1f2e8",  // Mint
        "f2d1e0"   // Rose
    ]

    // MARK: - URL Generation

    /// Generates a DiceBear Personas API URL for a guest
    /// - Parameters:
    ///   - guestId: UUID of the guest (used as seed for deterministic generation)
    ///   - size: Size of the avatar in pixels
    /// - Returns: URL for fetching the avatar SVG
    static func avatarURL(for guestId: UUID, size: Int = 80) -> URL? {
        let seed = guestId.uuidString

        // DiceBear API expects backgroundColor as repeated query parameters
        var components = URLComponents(string: "https://api.dicebear.com/9.x/personas/svg")
        var queryItems = [
            URLQueryItem(name: "seed", value: seed),
            URLQueryItem(name: "size", value: "\(size)")
        ]

        // Add each background color as a separate backgroundColor parameter
        for color in weddingAvatarColors {
            queryItems.append(URLQueryItem(name: "backgroundColor", value: color))
        }

        components?.queryItems = queryItems

        let url = components?.url
        #if DEBUG
        if let url = url {
            AppLogger.ui.debug("DiceBear Avatar URL: \(url.absoluteString)")
        }
        #endif

        return url
    }

    /// Generates avatar URL with custom background colors
    static func avatarURL(for guestId: UUID, size: Int = 80, colors: [String]) -> URL? {
        let seed = guestId.uuidString
        let bgColors = colors.joined(separator: ",")

        var components = URLComponents(string: "https://api.dicebear.com/9.x/personas/svg")
        components?.queryItems = [
            URLQueryItem(name: "seed", value: seed),
            URLQueryItem(name: "backgroundColor", value: bgColors),
            URLQueryItem(name: "size", value: "\(size)")
        ]

        return components?.url
    }

    // MARK: - Fallback Colors

    /// SwiftUI color palette for fallback avatars (when API fails)
    static let fallbackColors: [Color] = [
        Color(red: 0.85, green: 0.82, blue: 0.95),  // Lavender
        Color(red: 1.0, green: 0.88, blue: 0.82),   // Peach
        Color(red: 0.82, green: 0.95, blue: 0.88),  // Mint
        Color(red: 0.95, green: 0.82, blue: 0.88),  // Rose
        Color(red: 0.0, green: 0.7, blue: 0.7)      // Teal
    ]

    /// Gets a deterministic fallback color based on guest initials
    static func fallbackColor(for initials: String) -> Color {
        let hash = abs(initials.hashValue)
        return fallbackColors[hash % fallbackColors.count]
    }

    // MARK: - VIP Indicator Colors

    static let vipBorderColor = Color.yellow
    static let regularBorderColor = Color.white.opacity(0.3)
    static let vipBorderWidth: CGFloat = 2
    static let regularBorderWidth: CGFloat = 1
}

// MARK: - Additional Color Extensions for Avatars

extension Color {
    /// Avatar-specific colors (seatingAccentTeal and seatingCream already defined in ColorPalette.swift)
    static let avatarLavender = Color(red: 0.85, green: 0.82, blue: 0.95)
    static let avatarPeach = Color(red: 1.0, green: 0.88, blue: 0.82)
    static let avatarMint = Color(red: 0.82, green: 0.95, blue: 0.88)
    static let avatarRose = Color(red: 0.95, green: 0.82, blue: 0.88)
}
