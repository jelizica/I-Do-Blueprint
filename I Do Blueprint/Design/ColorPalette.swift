//
//  ColorPalette.swift
//  My Wedding Planning App
//
//  Seating Chart Redesign Color Palette
//

import SwiftUI

extension Color {
    // MARK: - Primary Colors (Seating Chart)

    /// Teal accent color for highlights and interactions
    static let seatingAccentTeal = Color(red: 0.0, green: 0.7, blue: 0.7)

    /// Cream background for warm, elegant feel
    static let seatingCream = Color(red: 0.98, green: 0.95, blue: 0.9)

    /// Light blue-gray for subtle backgrounds
    static let seatingLightBlue = Color(red: 0.95, green: 0.98, blue: 0.99)

    // MARK: - Secondary Colors

    /// Soft gold for premium features
    static let seatingGold = Color(red: 0.96, green: 0.85, blue: 0.65)

    /// Warm peach for soft accents
    static let seatingPeach = Color(red: 1.0, green: 0.9, blue: 0.85)

    /// Deep navy for text and strong contrast
    static let seatingDeepNavy = Color(red: 0.15, green: 0.2, blue: 0.35)

    // MARK: - Functional Colors

    /// Success green for completed assignments
    static let seatingSuccess = Color(red: 0.2, green: 0.7, blue: 0.4)

    /// Warning orange for conflicts or issues
    static let seatingWarning = Color(red: 0.95, green: 0.6, blue: 0.2)

    /// Error red for critical issues
    static let seatingError = Color(red: 0.9, green: 0.3, blue: 0.3)

    // MARK: - Guest Group Colors

    static let groupWeddingParty = Color(red: 0.8, green: 0.4, blue: 0.8)  // Purple
    static let groupFamily = Color(red: 0.2, green: 0.6, blue: 0.9)        // Blue
    static let groupFriends = Color(red: 0.3, green: 0.8, blue: 0.5)       // Green
    static let groupColleagues = Color(red: 0.9, green: 0.6, blue: 0.2)    // Orange
    static let groupOther = Color(red: 0.6, green: 0.6, blue: 0.6)         // Gray

    // MARK: - Relationship Colors

    static let relationshipCouple = Color(red: 1.0, green: 0.4, blue: 0.5)     // Pink
    static let relationshipFamily = Color(red: 0.3, green: 0.6, blue: 1.0)     // Blue
    static let relationshipFriend = Color(red: 0.5, green: 0.8, blue: 0.4)     // Green
    static let relationshipConflict = Color(red: 0.9, green: 0.2, blue: 0.2)   // Red

    // MARK: - Table Zone Colors

    static let zoneHeadTable = Color(red: 0.9, green: 0.7, blue: 0.3)      // Gold
    static let zoneFamily = Color(red: 0.4, green: 0.7, blue: 0.9)         // Sky blue
    static let zoneFriends = Color(red: 0.5, green: 0.8, blue: 0.6)        // Mint
    static let zoneGeneral = Color(red: 0.7, green: 0.7, blue: 0.8)        // Lavender
}
