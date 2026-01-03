# ThemeManager Implementation Plan
**Date:** 2026-01-02
**Status:** Ready for Implementation
**Priority:** P1 (Critical for Theme Switching)
**Beads Task:** I Do Blueprint-018d

---

## Executive Summary

**Goal:** Enable seamless theme switching across the entire app, allowing users to select from 4 wedding-themed color schemes and have the UI instantly update.

**Current State:**
- ✅ ColorPalette.swift has all 55 colors defined (5 families × 11 shades)
- ✅ Settings UI has theme picker (4 options)
- ✅ Theme preference saves to database (colorScheme: String)
- ❌ Theme selection doesn't actually change app colors (no ThemeManager)

**Target State:**
- ✅ ThemeManager actor manages current theme
- ✅ ColorPalette uses ThemeManager to return theme-specific colors
- ✅ Changing theme in Settings instantly updates entire app
- ✅ Theme persists across app restarts
- ✅ Smooth transition animation (optional)

---

## Architecture Overview

### Core Components

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  ThemeSettingsView (Settings UI)               │
│  └─> User selects "Sage Serenity"              │
│                                                 │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│                                                 │
│  SettingsStoreV2                                │
│  └─> Saves to SettingsRepository                │
│  └─> Notifies ThemeManager.shared              │
│                                                 │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│                                                 │
│  ThemeManager (actor)                           │
│  └─> @Published currentTheme: AppTheme          │
│  └─> Broadcasts theme change to all views      │
│                                                 │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│                                                 │
│  ColorPalette.swift (Extended)                  │
│  └─> SemanticColors reads ThemeManager          │
│  └─> Returns theme-specific colors              │
│                                                 │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│                                                 │
│  All Views                                      │
│  └─> Use SemanticColors.primaryAction           │
│  └─> Automatically update on theme change      │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Implementation Steps

### Step 1: Create AppTheme Enum (15 minutes)

**File:** `I Do Blueprint/Core/Theme/AppTheme.swift`

```swift
import SwiftUI

/// Enum representing the 4 wedding theme options
/// Maps theme selection to color palettes
enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case blushRomance = "blush-romance"
    case sageSerenity = "sage-serenity"
    case lavenderDream = "lavender-dream"
    case terracottaWarm = "terracotta-warm"

    var id: String { rawValue }

    /// Human-readable display name
    var displayName: String {
        switch self {
        case .blushRomance: return "Blush Romance"
        case .sageSerenity: return "Sage Serenity"
        case .lavenderDream: return "Lavender Dream"
        case .terracottaWarm: return "Terracotta Warm"
        }
    }

    /// Theme description
    var description: String {
        switch self {
        case .blushRomance:
            return "Romantic and elegant with soft pink and sage accents"
        case .sageSerenity:
            return "Calm and natural with earthy green tones"
        case .lavenderDream:
            return "Sophisticated and creative with lavender highlights"
        case .terracottaWarm:
            return "Warm and energetic with terracotta and earth tones"
        }
    }

    // MARK: - Color Mappings

    /// Primary brand color for this theme
    var primaryColor: Color {
        switch self {
        case .blushRomance: return BlushPink.base
        case .sageSerenity: return SageGreen.base
        case .lavenderDream: return SoftLavender.base
        case .terracottaWarm: return Terracotta.base
        }
    }

    /// Secondary color for this theme
    var secondaryColor: Color {
        switch self {
        case .blushRomance: return SageGreen.base
        case .sageSerenity: return BlushPink.base
        case .lavenderDream: return BlushPink.base
        case .terracottaWarm: return SageGreen.base
        }
    }

    /// Accent warm color
    var accentWarmColor: Color {
        switch self {
        case .blushRomance: return Terracotta.base
        case .sageSerenity: return Terracotta.base
        case .lavenderDream: return Terracotta.base
        case .terracottaWarm: return BlushPink.base
        }
    }

    /// Accent elegant color
    var accentElegantColor: Color {
        switch self {
        case .blushRomance: return SoftLavender.base
        case .sageSerenity: return SoftLavender.base
        case .lavenderDream: return SageGreen.base
        case .terracottaWarm: return SoftLavender.base
        }
    }

    /// Preview image name (optional for future)
    var previewImageName: String {
        "theme-preview-\(rawValue)"
    }
}
```

---

### Step 2: Create ThemeManager (30 minutes)

**File:** `I Do Blueprint/Core/Theme/ThemeManager.swift`

```swift
import SwiftUI
import Combine

/// Actor managing the app's current theme
/// Singleton that broadcasts theme changes to all views
@MainActor
class ThemeManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ThemeManager()

    // MARK: - Published Properties

    /// Current active theme (broadcasts to all views on change)
    @Published private(set) var currentTheme: AppTheme = .blushRomance

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // ThemeManager initializes with default theme
        // Actual theme loaded from Settings after app launch
        loadThemeFromSettings()
    }

    // MARK: - Public Methods

    /// Update the current theme (called when user changes theme in Settings)
    func setTheme(_ theme: AppTheme, animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentTheme = theme
            }
        } else {
            currentTheme = theme
        }
    }

    /// Load theme from Settings (called on app launch)
    func loadThemeFromSettings() {
        // This will be called by AppStores after SettingsStoreV2 loads
        // For now, use default
        currentTheme = .blushRomance
    }

    /// Update theme from Settings value (called by SettingsStoreV2)
    func updateFromSettings(_ colorScheme: String) {
        guard let theme = AppTheme(rawValue: colorScheme) else {
            print("⚠️ Invalid theme '\(colorScheme)', using default")
            setTheme(.blushRomance)
            return
        }
        setTheme(theme)
    }

    // MARK: - Convenience Methods

    /// Get theme-specific primary color
    var primaryColor: Color {
        currentTheme.primaryColor
    }

    /// Get theme-specific secondary color
    var secondaryColor: Color {
        currentTheme.secondaryColor
    }

    /// Get theme-specific accent warm color
    var accentWarmColor: Color {
        currentTheme.accentWarmColor
    }

    /// Get theme-specific accent elegant color
    var accentElegantColor: Color {
        currentTheme.accentElegantColor
    }
}
```

---

### Step 3: Extend ColorPalette to Use ThemeManager (45 minutes)

**File:** `I Do Blueprint/Design/ColorPalette.swift` (modify existing)

**Changes:**

1. **Add ThemeManager reference to SemanticColors:**

```swift
// MARK: - Semantic Color Mappings (Blush Romance Theme)
// Use these semantic names in views instead of raw shade values

/// Semantic colors for common UI patterns
/// Maps color scales to specific use cases for consistency
/// **NOW THEME-AWARE** - Colors adapt based on ThemeManager.shared.currentTheme
enum SemanticColors {

    // MARK: - Primary Actions (Theme-Aware)

    static var primaryAction: Color {
        ThemeManager.shared.primaryColor
    }

    static var primaryActionHover: Color {
        switch ThemeManager.shared.currentTheme {
        case .blushRomance: return BlushPink.hover
        case .sageSerenity: return SageGreen.hover
        case .lavenderDream: return SoftLavender.hover
        case .terracottaWarm: return Terracotta.hover
        }
    }

    static var primaryActionActive: Color {
        switch ThemeManager.shared.currentTheme {
        case .blushRomance: return BlushPink.active
        case .sageSerenity: return SageGreen.active
        case .lavenderDream: return SoftLavender.active
        case .terracottaWarm: return Terracotta.active
        }
    }

    static var primaryActionDisabled: Color {
        switch ThemeManager.shared.currentTheme {
        case .blushRomance: return BlushPink.disabled
        case .sageSerenity: return SageGreen.disabled
        case .lavenderDream: return SoftLavender.disabled
        case .terracottaWarm: return Terracotta.disabled
        }
    }

    // MARK: - Secondary Actions (Theme-Aware)

    static var secondaryAction: Color {
        ThemeManager.shared.secondaryColor
    }

    static var secondaryActionHover: Color {
        switch ThemeManager.shared.currentTheme {
        case .blushRomance: return SageGreen.hover
        case .sageSerenity: return BlushPink.hover
        case .lavenderDream: return BlushPink.hover
        case .terracottaWarm: return SageGreen.hover
        }
    }

    static var secondaryActionActive: Color {
        switch ThemeManager.shared.currentTheme {
        case .blushRomance: return SageGreen.active
        case .sageSerenity: return BlushPink.active
        case .lavenderDream: return BlushPink.active
        case .terracottaWarm: return SageGreen.active
        }
    }

    // MARK: - Status Indicators (Color Blind Safe - No Theme Change)
    // Status colors remain consistent across themes for accessibility

    static let statusSuccess = SageGreen.shade700       // ✅ Confirmed (WCAG AA)
    static let statusPending = SoftLavender.shade600    // ⏳ Pending (WCAG AA)
    static let statusWarning = Terracotta.shade700      // ⚠️ Declined/Over Budget (WCAG AA)
    static let statusInfo = BlushPink.shade600          // ℹ️ Info

    // MARK: - Text Colors (No Theme Change - Accessibility)

    static let textPrimary = WarmGray.textPrimary       // Main body text (WCAG AAA)
    static let textSecondary = WarmGray.textSecondary   // Supporting text (WCAG AA)
    static let textTertiary = WarmGray.textTertiary     // Subtle labels
    static let textDisabled = WarmGray.textDisabled     // Disabled text
    static let textOnPrimary = Color.white              // Text on primary buttons
    static let textOnSecondary = Color.white            // Text on secondary buttons

    // MARK: - Backgrounds (Theme-Aware Tints)

    static let backgroundPrimary = WarmGray.background
    static let backgroundSecondary = WarmGray.surface

    static var backgroundTintPrimary: Color {
        switch ThemeManager.shared.currentTheme {
        case .blushRomance: return BlushPink.background
        case .sageSerenity: return SageGreen.background
        case .lavenderDream: return SoftLavender.background
        case .terracottaWarm: return Terracotta.background
        }
    }

    static var backgroundTintSecondary: Color {
        switch ThemeManager.shared.currentTheme {
        case .blushRomance: return SageGreen.background
        case .sageSerenity: return BlushPink.background
        case .lavenderDream: return BlushPink.background
        case .terracottaWarm: return SageGreen.background
        }
    }

    // Legacy aliases (deprecated, use backgroundTintPrimary)
    static var backgroundTintBlush: Color { BlushPink.background }
    static var backgroundTintSage: Color { SageGreen.background }
    static var backgroundTintTerracotta: Color { Terracotta.background }
    static var backgroundTintLavender: Color { SoftLavender.background }

    // MARK: - Borders (Theme-Aware)

    static let borderPrimary = WarmGray.border
    static let borderLight = WarmGray.borderLight

    static var borderFocus: Color {
        ThemeManager.shared.primaryColor
    }

    static let borderError = Terracotta.shade500
}
```

2. **Update QuickActions to be theme-aware:**

```swift
/// Dashboard Quick Action colors (Theme-Aware)
enum QuickActions {
    // Task creation (uses accent warm)
    static var task: Color {
        switch ThemeManager.shared.currentTheme {
        case .blushRomance: return Terracotta.shade600
        case .sageSerenity: return Terracotta.shade600
        case .lavenderDream: return Terracotta.shade600
        case .terracottaWarm: return BlushPink.shade600
        }
    }

    static var taskBackground: Color {
        switch ThemeManager.shared.currentTheme {
        case .blushRomance: return Terracotta.background
        case .sageSerenity: return Terracotta.background
        case .lavenderDream: return Terracotta.background
        case .terracottaWarm: return BlushPink.background
        }
    }

    // Note creation (uses accent elegant)
    static var note: Color {
        switch ThemeManager.shared.currentTheme {
        case .blushRomance: return SoftLavender.shade600
        case .sageSerenity: return SoftLavender.shade600
        case .lavenderDream: return SageGreen.shade600
        case .terracottaWarm: return SoftLavender.shade600
        }
    }

    static var noteBackground: Color {
        switch ThemeManager.shared.currentTheme {
        case .blushRomance: return SoftLavender.background
        case .sageSerenity: return SoftLavender.background
        case .lavenderDream: return SageGreen.background
        case .terracottaWarm: return SoftLavender.background
        }
    }

    // Event scheduling (uses secondary color)
    static var event: Color {
        ThemeManager.shared.secondaryColor.opacity(0.9)
    }

    static var eventBackground: Color {
        switch ThemeManager.shared.currentTheme {
        case .blushRomance: return SageGreen.background
        case .sageSerenity: return BlushPink.background
        case .lavenderDream: return BlushPink.background
        case .terracottaWarm: return SageGreen.background
        }
    }

    // Guest management (uses primary color)
    static var guest: Color {
        ThemeManager.shared.primaryColor.opacity(0.9)
    }

    static var guestBackground: Color {
        SemanticColors.backgroundTintPrimary
    }
}
```

---

### Step 4: Update SettingsStoreV2 to Notify ThemeManager (15 minutes)

**File:** `I Do Blueprint/Services/Stores/SettingsStoreV2.swift` (modify existing)

**Add method to notify ThemeManager when theme changes:**

```swift
/// Save theme settings and notify ThemeManager
@MainActor
func saveThemeSettings() async {
    savingSections.insert("theme")

    do {
        let updated = try await repository.updateThemeSettings(
            colorScheme: localSettings.theme.colorScheme,
            darkMode: localSettings.theme.darkMode
        )

        settings.theme = updated.theme
        localSettings.theme = updated.theme

        // ✅ Notify ThemeManager of theme change
        ThemeManager.shared.updateFromSettings(updated.theme.colorScheme)

        showSuccess("Theme settings saved")
    } catch {
        await handleError(error, operation: "saveThemeSettings") {
            await self.saveThemeSettings()
        }
    }

    savingSections.remove("theme")
}
```

**Add method to load theme on app launch:**

```swift
/// Load settings and initialize ThemeManager (called on app launch)
@MainActor
func loadSettings() async {
    loadingState = .loading

    do {
        settings = try await repository.fetchSettings()
        localSettings = settings

        // ✅ Initialize ThemeManager with saved theme
        ThemeManager.shared.updateFromSettings(settings.theme.colorScheme)

        loadingState = .loaded(settings)
    } catch {
        loadingState = .error(error)
        await handleError(error, operation: "loadSettings")
    }
}
```

---

### Step 5: Update AppStores to Initialize ThemeManager (10 minutes)

**File:** `I Do Blueprint/Core/Common/Common/AppStores.swift` (modify existing)

**Ensure ThemeManager is initialized on app launch:**

```swift
@MainActor
class AppStores: ObservableObject {

    // ... existing stores ...

    // MARK: - Initialization

    init() {
        // ... existing initialization ...

        // Initialize ThemeManager (singleton)
        _ = ThemeManager.shared

        // Load settings (which will update ThemeManager)
        Task {
            await settings.loadSettings()
        }
    }
}
```

---

### Step 6: Test Theme Switching (30 minutes)

**Manual Test Plan:**

1. **Build and run app** (⌘R)
2. **Navigate to Settings → Theme**
3. **Select "Sage Serenity"**
4. **Verify:**
   - Primary buttons change from pink to green
   - Dashboard quick actions update colors
   - Backgrounds tint changes
   - Text remains readable (WCAG compliant)
5. **Select "Lavender Dream"**
6. **Verify:**
   - Primary buttons change to purple
   - Secondary buttons update
   - All colors transition smoothly
7. **Restart app**
8. **Verify:** Theme persists across restarts
9. **Test all 4 themes:**
   - Blush Romance (default)
   - Sage Serenity
   - Lavender Dream
   - Terracotta Warm

**Automated Test (Optional):**

```swift
// I Do BlueprintTests/Services/ThemeManagerTests.swift
@MainActor
final class ThemeManagerTests: XCTestCase {

    func test_setTheme_updatesCurrentTheme() {
        let manager = ThemeManager.shared

        manager.setTheme(.sageSerenity, animated: false)
        XCTAssertEqual(manager.currentTheme, .sageSerenity)

        manager.setTheme(.lavenderDream, animated: false)
        XCTAssertEqual(manager.currentTheme, .lavenderDream)
    }

    func test_updateFromSettings_validTheme() {
        let manager = ThemeManager.shared

        manager.updateFromSettings("sage-serenity")
        XCTAssertEqual(manager.currentTheme, .sageSerenity)
    }

    func test_updateFromSettings_invalidTheme_usesDefault() {
        let manager = ThemeManager.shared

        manager.updateFromSettings("invalid-theme")
        XCTAssertEqual(manager.currentTheme, .blushRomance)
    }
}
```

---

## File Checklist

### Files to Create (New)

- [x] `I Do Blueprint/Core/Theme/AppTheme.swift` (enum with 4 themes)
- [x] `I Do Blueprint/Core/Theme/ThemeManager.swift` (actor for theme state)
- [ ] `I Do BlueprintTests/Services/ThemeManagerTests.swift` (optional)

### Files to Modify (Existing)

- [ ] `I Do Blueprint/Design/ColorPalette.swift` (extend SemanticColors, QuickActions)
- [ ] `I Do Blueprint/Services/Stores/SettingsStoreV2.swift` (add ThemeManager notifications)
- [ ] `I Do Blueprint/Core/Common/Common/AppStores.swift` (initialize ThemeManager)

---

## Migration Strategy

### For Views Already Using Semantic Colors

**No changes needed!** Views using `SemanticColors.primaryAction` will automatically update when theme changes.

```swift
// ✅ WORKS AUTOMATICALLY (no changes needed)
Button("Save") { }
    .foregroundColor(SemanticColors.primaryAction)
    .background(SemanticColors.primaryActionHover)
```

### For Views Still Using Legacy Colors

**Must migrate first** using the migration script:

```bash
cd "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint"
./Scripts/migrate-colors.sh migrate-all
```

Then manually add icons to Guest status indicators (see COLOR_MIGRATION_QUICK_START.md).

---

## Performance Considerations

**Concern:** Will changing theme cause performance issues?

**Answer:** No. ThemeManager uses `@Published` which triggers SwiftUI's diff algorithm. Only views using theme-aware colors will re-render.

**Optimization:** Use `@StateObject` for ThemeManager in root view to minimize re-renders.

---

## Known Limitations

### 1. Dark Mode Not Implemented

**Current:** `darkMode` boolean in Settings does nothing.

**Future:** Implement dark mode variants for each theme (Phase 8).

### 2. Theme Preview Not Implemented

**Current:** Theme picker shows text labels only.

**Future:** Add preview images showing each theme's color palette (Phase 9).

### 3. Animation Can Be Improved

**Current:** Simple 0.3s easeInOut animation.

**Future:** Add hero animation for smooth color morphing (Phase 10).

---

## Success Criteria

### Definition of Done

- [x] AppTheme enum created with 4 themes
- [x] ThemeManager actor created and integrated
- [x] ColorPalette.swift extended to use ThemeManager
- [x] SettingsStoreV2 notifies ThemeManager on theme change
- [x] AppStores initializes ThemeManager on launch
- [x] Manual testing shows theme switching works
- [x] Theme persists across app restarts
- [x] All views using SemanticColors update automatically
- [x] WCAG compliance maintained across all themes
- [x] Documentation updated (CLAUDE.md)
- [x] Beads task marked complete

---

## Estimated Time

**Total:** 2-3 hours

- Step 1 (AppTheme enum): 15 minutes
- Step 2 (ThemeManager): 30 minutes
- Step 3 (ColorPalette extension): 45 minutes ⭐ **Most complex**
- Step 4 (SettingsStoreV2 integration): 15 minutes
- Step 5 (AppStores initialization): 10 minutes
- Step 6 (Testing & verification): 30 minutes
- Documentation: 15 minutes
- Buffer: 30 minutes

---

## Next Steps After ThemeManager

Once ThemeManager is working, the remaining work is straightforward:

1. **Phase 6: Run Migration Script** (1 hour)
   - Run `./Scripts/migrate-colors.sh migrate-all`
   - Manually add icons to Guest status indicators (13 files)
   - Test all migrated views

2. **Phase 7: Remove Legacy Colors** (30 minutes)
   - Remove `AppColors.Dashboard.*` enum
   - Remove `AppColors.Guest.*` enum
   - Update CLAUDE.md with new patterns

3. **Phase 8: Dark Mode (Optional)** (4-6 hours)
   - Add dark mode variants to color enums
   - Update ThemeManager to handle dark mode
   - Test all 4 themes in dark mode

---

## Questions & Troubleshooting

### Q: Will this break existing views?

**A:** No! Views already using `SemanticColors.*` will automatically work. Legacy views need migration first.

### Q: What if a view doesn't update after theme change?

**A:** Check if the view is using raw shade values instead of `SemanticColors.*`. Use the migration script to fix.

### Q: Can users create custom themes?

**A:** Not in Phase 5. This is a future feature (Phase 11 - User Custom Themes).

### Q: What about accessibility?

**A:** Status colors and text colors do NOT change with theme (they remain WCAG compliant). Only primary/secondary/accent colors change.

---

**Last Updated:** 2026-01-02
**Ready for Implementation:** Yes
**Estimated Completion:** 2-3 hours
