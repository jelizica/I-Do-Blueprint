//
//  ThemeManager.swift
//  I Do Blueprint
//
//  Created by Claude Code on 2026-01-02.
//

import SwiftUI
import Combine

/// Thread-safe theme manager that broadcasts theme changes to all views.
/// Views access the current theme via `SemanticColors` which delegates to this manager.
///
/// Usage:
/// ```swift
/// // In SettingsStoreV2 when user changes theme
/// await ThemeManager.shared.setTheme(.sageSerenity, animated: true)
///
/// // In AppStores to initialize theme on launch
/// await ThemeManager.shared.initializeTheme(from: settingsStore.settings.theme.colorScheme)
/// ```
@MainActor
final class ThemeManager: ObservableObject {
    /// Singleton instance (thread-safe via @MainActor)
    static let shared = ThemeManager()

    /// Current active theme (triggers UI updates when changed)
    @Published private(set) var currentTheme: AppTheme = .blushRomance

    private let logger = AppLogger.general

    private init() {
        logger.info("ThemeManager initialized with default theme: \(currentTheme.displayName)")
    }

    // MARK: - Public Interface

    /// Initialize theme from user's saved preference
    /// - Parameter colorScheme: Color scheme string from SettingsModel (e.g., "blush-romance")
    func initializeTheme(from colorScheme: String) {
        let theme = AppTheme(from: colorScheme)
        if theme != currentTheme {
            currentTheme = theme
            logger.info("Theme initialized from settings: \(theme.displayName)")
        }
    }

    /// Change the current theme with optional animation
    /// - Parameters:
    ///   - theme: The new theme to apply
    ///   - animated: Whether to animate the transition (default: true)
    func setTheme(_ theme: AppTheme, animated: Bool = true) {
        guard theme != currentTheme else {
            logger.debug("Theme already set to \(theme.displayName), skipping change")
            return
        }

        logger.info("Changing theme from \(currentTheme.displayName) to \(theme.displayName)")

        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentTheme = theme
            }
        } else {
            currentTheme = theme
        }
    }

    /// Get the current theme (synchronous access)
    func getCurrentTheme() -> AppTheme {
        currentTheme
    }

    // MARK: - Color Accessors (Used by SemanticColors)

    var primaryColor: Color { currentTheme.primaryColor }
    var primaryShade700: Color { currentTheme.primaryShade700 }
    var primaryShade800: Color { currentTheme.primaryShade800 }
    var primaryShade50: Color { currentTheme.primaryShade50 }
    var primaryShade100: Color { currentTheme.primaryShade100 }
    var primaryHover: Color { currentTheme.primaryHover }

    var secondaryColor: Color { currentTheme.secondaryColor }
    var secondaryShade700: Color { currentTheme.secondaryShade700 }
    var secondaryShade800: Color { currentTheme.secondaryShade800 }
    var secondaryShade50: Color { currentTheme.secondaryShade50 }
    var secondaryHover: Color { currentTheme.secondaryHover }

    var accentWarmColor: Color { currentTheme.accentWarmColor }
    var accentWarmShade700: Color { currentTheme.accentWarmShade700 }
    var accentWarmShade600: Color { currentTheme.accentWarmShade600 }

    var accentElegantColor: Color { currentTheme.accentElegantColor }
    var accentElegantShade600: Color { currentTheme.accentElegantShade600 }

    var statusSuccess: Color { currentTheme.statusSuccess }
    var statusWarning: Color { currentTheme.statusWarning }
    var statusPending: Color { currentTheme.statusPending }

    var textPrimary: Color { currentTheme.textPrimary }
    var textSecondary: Color { currentTheme.textSecondary }
    var textTertiary: Color { currentTheme.textTertiary }

    var backgroundPrimary: Color { currentTheme.backgroundPrimary }
    var backgroundSecondary: Color { currentTheme.backgroundSecondary }
    var backgroundTertiary: Color { currentTheme.backgroundTertiary }

    var border: Color { currentTheme.border }
    var borderLight: Color { currentTheme.borderLight }

    var quickActionTask: Color { currentTheme.quickActionTask }
    var quickActionNote: Color { currentTheme.quickActionNote }
    var quickActionEvent: Color { currentTheme.quickActionEvent }
    var quickActionGuest: Color { currentTheme.quickActionGuest }
    var quickActionBudget: Color { currentTheme.quickActionBudget }
    var quickActionVendor: Color { currentTheme.quickActionVendor }
}
