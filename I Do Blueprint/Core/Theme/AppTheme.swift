//
//  AppTheme.swift
//  I Do Blueprint
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI

/// Defines the 4 wedding-themed color schemes available in the app.
/// Each theme provides a complete set of color mappings for primary, secondary, accent, and neutral colors.
enum AppTheme: String, Codable, CaseIterable, Sendable {
    case blushRomance = "blush-romance"
    case sageSerenity = "sage-serenity"
    case lavenderDream = "lavender-dream"
    case terracottaWarm = "terracotta-warm"

    // MARK: - Theme Metadata

    var displayName: String {
        switch self {
        case .blushRomance: return "Blush Romance"
        case .sageSerenity: return "Sage Serenity"
        case .lavenderDream: return "Lavender Dream"
        case .terracottaWarm: return "Terracotta Warm"
        }
    }

    var description: String {
        switch self {
        case .blushRomance:
            return "Romance, warmth, celebration – traditional romantic weddings"
        case .sageSerenity:
            return "Calm, nature, balance – garden weddings, rustic themes"
        case .lavenderDream:
            return "Elegance, sophistication – evening weddings, luxury themes"
        case .terracottaWarm:
            return "Warmth, energy, creativity – fall weddings, bohemian themes"
        }
    }

    // MARK: - Primary Colors

    var primaryColor: Color {
        switch self {
        case .blushRomance: return BlushPink.base
        case .sageSerenity: return SageGreen.base
        case .lavenderDream: return SoftLavender.base
        case .terracottaWarm: return Terracotta.base
        }
    }

    var primaryShade700: Color {
        switch self {
        case .blushRomance: return BlushPink.shade700
        case .sageSerenity: return SageGreen.shade700
        case .lavenderDream: return SoftLavender.shade700
        case .terracottaWarm: return Terracotta.shade700
        }
    }

    var primaryShade800: Color {
        switch self {
        case .blushRomance: return BlushPink.shade800
        case .sageSerenity: return SageGreen.shade800
        case .lavenderDream: return SoftLavender.shade800
        case .terracottaWarm: return Terracotta.shade800
        }
    }

    var primaryShade50: Color {
        switch self {
        case .blushRomance: return BlushPink.shade50
        case .sageSerenity: return SageGreen.shade50
        case .lavenderDream: return SoftLavender.shade50
        case .terracottaWarm: return Terracotta.shade50
        }
    }

    var primaryShade100: Color {
        switch self {
        case .blushRomance: return BlushPink.shade100
        case .sageSerenity: return SageGreen.shade100
        case .lavenderDream: return SoftLavender.shade100
        case .terracottaWarm: return Terracotta.shade100
        }
    }

    var primaryHover: Color {
        switch self {
        case .blushRomance: return BlushPink.hover
        case .sageSerenity: return SageGreen.hover
        case .lavenderDream: return SoftLavender.hover
        case .terracottaWarm: return Terracotta.hover
        }
    }

    // MARK: - Secondary Colors

    var secondaryColor: Color {
        switch self {
        case .blushRomance: return SageGreen.base
        case .sageSerenity: return BlushPink.base
        case .lavenderDream: return BlushPink.base
        case .terracottaWarm: return SageGreen.base
        }
    }

    var secondaryShade700: Color {
        switch self {
        case .blushRomance: return SageGreen.shade700
        case .sageSerenity: return BlushPink.shade700
        case .lavenderDream: return BlushPink.shade700
        case .terracottaWarm: return SageGreen.shade700
        }
    }

    var secondaryShade800: Color {
        switch self {
        case .blushRomance: return SageGreen.shade800
        case .sageSerenity: return BlushPink.shade800
        case .lavenderDream: return BlushPink.shade800
        case .terracottaWarm: return SageGreen.shade800
        }
    }

    var secondaryShade50: Color {
        switch self {
        case .blushRomance: return SageGreen.shade50
        case .sageSerenity: return BlushPink.shade50
        case .lavenderDream: return BlushPink.shade50
        case .terracottaWarm: return SageGreen.shade50
        }
    }

    var secondaryHover: Color {
        switch self {
        case .blushRomance: return SageGreen.hover
        case .sageSerenity: return BlushPink.hover
        case .lavenderDream: return BlushPink.hover
        case .terracottaWarm: return SageGreen.hover
        }
    }

    // MARK: - Accent Warm Colors

    var accentWarmColor: Color {
        switch self {
        case .blushRomance: return Terracotta.base
        case .sageSerenity: return Terracotta.base
        case .lavenderDream: return Terracotta.base
        case .terracottaWarm: return BlushPink.base
        }
    }

    var accentWarmShade700: Color {
        switch self {
        case .blushRomance: return Terracotta.shade700
        case .sageSerenity: return Terracotta.shade700
        case .lavenderDream: return Terracotta.shade700
        case .terracottaWarm: return BlushPink.shade700
        }
    }

    var accentWarmShade600: Color {
        switch self {
        case .blushRomance: return Terracotta.shade600
        case .sageSerenity: return Terracotta.shade600
        case .lavenderDream: return Terracotta.shade600
        case .terracottaWarm: return BlushPink.shade600
        }
    }

    // MARK: - Accent Elegant Colors

    var accentElegantColor: Color {
        switch self {
        case .blushRomance: return SoftLavender.base
        case .sageSerenity: return SoftLavender.base
        case .lavenderDream: return SageGreen.base
        case .terracottaWarm: return SoftLavender.base
        }
    }

    var accentElegantShade600: Color {
        switch self {
        case .blushRomance: return SoftLavender.shade600
        case .sageSerenity: return SoftLavender.shade600
        case .lavenderDream: return SageGreen.shade600
        case .terracottaWarm: return SoftLavender.shade600
        }
    }

    // MARK: - Status Colors (Consistent Across All Themes)

    /// Success status color (always SageGreen for consistency)
    var statusSuccess: Color { SageGreen.shade700 }

    /// Warning status color (always Terracotta for consistency)
    var statusWarning: Color { Terracotta.shade700 }

    /// Pending status color (always SoftLavender for consistency)
    var statusPending: Color { SoftLavender.shade600 }

    // MARK: - Neutral Colors (Consistent Across All Themes)

    var textPrimary: Color { WarmGray.shade800 }
    var textSecondary: Color { WarmGray.shade600 }
    var textTertiary: Color { WarmGray.shade500 }

    var backgroundPrimary: Color { .white }
    var backgroundSecondary: Color { WarmGray.shade50 }
    var backgroundTertiary: Color { WarmGray.shade100 }

    var border: Color { WarmGray.shade300 }
    var borderLight: Color { WarmGray.shade200 }

    // MARK: - Quick Actions Colors (Theme-Specific)

    var quickActionTask: Color { accentWarmShade600 }
    var quickActionNote: Color { accentElegantShade600 }
    var quickActionEvent: Color { secondaryShade700 }
    var quickActionGuest: Color { primaryShade700 }
    var quickActionBudget: Color { statusSuccess }        // Budget uses success green (consistent)
    var quickActionVendor: Color { accentElegantShade600 } // Vendor uses elegant accent

    // MARK: - Dashboard Colors (Theme-Aware)

    var dashboardBackground: Color {
        switch self {
        case .blushRomance: return Color.fromHex("1A1A1A")      // Dark charcoal (unchanged)
        case .sageSerenity: return Color.fromHex("1A1F1A")     // Dark green-tinted
        case .lavenderDream: return Color.fromHex("1A1A1F")    // Dark purple-tinted
        case .terracottaWarm: return Color.fromHex("1F1A1A")   // Dark warm-tinted
        }
    }

    var dashboardQuickActionsBackground: Color {
        dashboardBackground // Same as main background
    }

    var dashboardBudgetCard: Color {
        switch self {
        case .blushRomance: return BlushPink.shade200          // Soft pink
        case .sageSerenity: return SageGreen.shade200          // Soft sage
        case .lavenderDream: return SoftLavender.shade200      // Soft lavender
        case .terracottaWarm: return Terracotta.shade200       // Soft terracotta
        }
    }

    var dashboardRsvpCard: Color {
        switch self {
        case .blushRomance: return BlushPink.shade600          // Vibrant pink
        case .sageSerenity: return SageGreen.shade600          // Vibrant sage
        case .lavenderDream: return SoftLavender.shade600      // Vibrant lavender
        case .terracottaWarm: return Terracotta.shade600       // Vibrant terracotta
        }
    }

    var dashboardVendorCard: Color {
        switch self {
        case .blushRomance: return Color.fromHex("2A2A2A")     // Dark gray (unchanged)
        case .sageSerenity: return Color.fromHex("2A2F2A")     // Dark green-tinted
        case .lavenderDream: return Color.fromHex("2A2A2F")    // Dark purple-tinted
        case .terracottaWarm: return Color.fromHex("2F2A2A")   // Dark warm-tinted
        }
    }

    var dashboardGuestCard: Color {
        switch self {
        case .blushRomance: return Color.fromHex("4A4A4A")     // Medium gray (unchanged)
        case .sageSerenity: return Color.fromHex("4A4F4A")     // Medium green-tinted
        case .lavenderDream: return Color.fromHex("4A4A4F")    // Medium purple-tinted
        case .terracottaWarm: return Color.fromHex("4F4A4A")   // Medium warm-tinted
        }
    }

    var dashboardCountdownCard: Color {
        switch self {
        case .blushRomance: return BlushPink.shade700          // Deep pink
        case .sageSerenity: return SageGreen.shade700          // Deep sage
        case .lavenderDream: return SoftLavender.shade700      // Deep lavender
        case .terracottaWarm: return Terracotta.shade700       // Deep terracotta
        }
    }

    var dashboardBudgetVisualizationCard: Color {
        switch self {
        case .blushRomance: return BlushPink.shade50           // Very light pink
        case .sageSerenity: return SageGreen.shade50           // Very light sage
        case .lavenderDream: return SoftLavender.shade50       // Very light lavender
        case .terracottaWarm: return Terracotta.shade50        // Very light terracotta
        }
    }

    var dashboardTaskProgressCard: Color {
        // Use secondary color for task progress
        secondaryShade700
    }

    // MARK: - Category Tints (Theme-Aware for Budget Charts)

    var categoryTintVenue: Color {
        switch self {
        case .blushRomance: return BlushPink.shade400          // Pink
        case .sageSerenity: return SageGreen.shade400          // Sage
        case .lavenderDream: return SoftLavender.shade400      // Lavender
        case .terracottaWarm: return Terracotta.shade400       // Terracotta
        }
    }

    var categoryTintCatering: Color {
        switch self {
        case .blushRomance: return SageGreen.shade400          // Sage (secondary)
        case .sageSerenity: return BlushPink.shade400          // Pink (secondary)
        case .lavenderDream: return BlushPink.shade400         // Pink (secondary)
        case .terracottaWarm: return SageGreen.shade400        // Sage (secondary)
        }
    }

    var categoryTintPhotography: Color {
        switch self {
        case .blushRomance: return SoftLavender.shade400       // Lavender (accent)
        case .sageSerenity: return SoftLavender.shade400       // Lavender (accent)
        case .lavenderDream: return SageGreen.shade400         // Sage (accent)
        case .terracottaWarm: return SoftLavender.shade400     // Lavender (accent)
        }
    }

    var categoryTintFlorals: Color {
        switch self {
        case .blushRomance: return Terracotta.shade300         // Soft terracotta
        case .sageSerenity: return Terracotta.shade300         // Soft terracotta
        case .lavenderDream: return Terracotta.shade300        // Soft terracotta
        case .terracottaWarm: return BlushPink.shade300        // Soft pink
        }
    }

    var categoryTintMusic: Color {
        switch self {
        case .blushRomance: return SoftLavender.shade500       // Vibrant lavender
        case .sageSerenity: return SoftLavender.shade500       // Vibrant lavender
        case .lavenderDream: return Terracotta.shade500        // Vibrant terracotta
        case .terracottaWarm: return SoftLavender.shade500     // Vibrant lavender
        }
    }

    var categoryTintOther: Color {
        WarmGray.shade400 // Neutral gray (consistent across themes)
    }

    // MARK: - Vendor Type Tints (Theme-Aware for Badges/Avatars)

    var vendorTintPhotography: Color {
        switch self {
        case .blushRomance: return BlushPink.shade100          // Very light pink
        case .sageSerenity: return SageGreen.shade100          // Very light sage
        case .lavenderDream: return SoftLavender.shade100      // Very light lavender
        case .terracottaWarm: return Terracotta.shade100       // Very light terracotta
        }
    }

    var vendorTintCatering: Color {
        switch self {
        case .blushRomance: return SageGreen.shade100          // Very light sage
        case .sageSerenity: return BlushPink.shade100          // Very light pink
        case .lavenderDream: return BlushPink.shade100         // Very light pink
        case .terracottaWarm: return SageGreen.shade100        // Very light sage
        }
    }

    var vendorTintFlorals: Color {
        switch self {
        case .blushRomance: return Terracotta.shade100         // Very light terracotta
        case .sageSerenity: return Terracotta.shade100         // Very light terracotta
        case .lavenderDream: return Terracotta.shade100        // Very light terracotta
        case .terracottaWarm: return BlushPink.shade100        // Very light pink
        }
    }

    var vendorTintMusic: Color {
        switch self {
        case .blushRomance: return SoftLavender.shade100       // Very light lavender
        case .sageSerenity: return SoftLavender.shade100       // Very light lavender
        case .lavenderDream: return SageGreen.shade100         // Very light sage
        case .terracottaWarm: return SoftLavender.shade100     // Very light lavender
        }
    }

    var vendorTintGeneric: Color {
        WarmGray.shade100 // Neutral (consistent across themes)
    }

    // MARK: - Helper Methods

    /// Initialize from SettingsModel string value
    init(from colorScheme: String) {
        self = AppTheme(rawValue: colorScheme) ?? .blushRomance
    }

    /// Check if this is the default theme
    var isDefault: Bool {
        self == .blushRomance
    }
}
