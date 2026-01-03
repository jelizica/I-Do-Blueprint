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
