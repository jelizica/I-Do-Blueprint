# Semantic Colors Enhancement Plan

**Date:** 2026-01-03  
**Status:** Proposed  
**Priority:** P1 (High)  
**Related Issue:** I Do Blueprint-sp16 (Phase 6 Migration)

---

## Executive Summary

Based on industry best practices research (Material Design 3, Apple HIG, design token standards), our current `SemanticColors` enum is incomplete. This plan proposes enhancing it to be a complete semantic color system before continuing the migration.

---

## Current State Analysis

### What We Have

```
SemanticColors (Current)
├── Primary Actions
│   ├── primaryAction ✅
│   ├── primaryActionHover ✅
│   ├── primaryActionActive ✅
│   └── primaryActionDisabled ✅
├── Secondary Actions
│   ├── secondaryAction ✅
│   ├── secondaryActionHover ✅
│   └── secondaryActionActive ✅
├── Status Indicators
│   ├── statusSuccess ✅
│   ├── statusPending ✅
│   ├── statusWarning ✅
│   └── statusInfo ✅
├── Text Colors
│   ��── textPrimary ✅
│   ├── textSecondary ✅
│   ├── textTertiary ✅
│   ├── textDisabled ✅
│   ├── textOnPrimary ✅
│   └── textOnSecondary ✅
├── Backgrounds
│   ├── backgroundPrimary ✅
│   ├── backgroundSecondary ✅
│   ├── backgroundTintPrimary ✅
│   ├── backgroundTintSecondary ✅
│   ├── backgroundTintWarm ✅
│   └── backgroundTintElegant ✅
└── Borders
    ├── borderPrimary ✅
    ├── borderLight ✅
    ├── borderFocus ✅
    └── borderError ✅
```

### What's Missing

```
SemanticColors (Missing)
├── Status Light Variants (for alert backgrounds)
│   ├── statusSuccessLight ❌
│   ├── statusWarningLight ❌
│   ├── statusErrorLight ❌
│   └── statusInfoLight ❌
├── Error Color
│   └── statusError ❌ (critical - currently using AppColors.error)
├── Shadow Colors
│   ├── shadow ❌
│   └── shadowLight ❌
├── Interactive States
│   ├── hover ❌
│   ├── pressed ❌
│   └── selected ❌
├── Accent Color
│   └── accent ❌
└── Disabled States
    └── backgroundDisabled ❌
```

---

## Proposed Enhancement

### Phase 1: Add Missing Status Colors

Add to `SemanticColors`:

```swift
// MARK: - Status Colors (Full Set)
static var statusSuccess: Color { ThemeManager.shared.statusSuccess }
static var statusSuccessLight: Color { SageGreen.shade100 }  // Light green for backgrounds
static var statusWarning: Color { ThemeManager.shared.statusWarning }
static var statusWarningLight: Color { Terracotta.shade100 }  // Light orange for backgrounds
static var statusError: Color { AppColors.error }  // Red for errors
static var statusErrorLight: Color { AppColors.errorLight }  // Light red for backgrounds
static var statusInfo: Color { ThemeManager.shared.primaryShade700 }
static var statusInfoLight: Color { ThemeManager.shared.primaryShade100 }  // Light primary for backgrounds
static var statusPending: Color { ThemeManager.shared.statusPending }
static var statusPendingLight: Color { SoftLavender.shade100 }  // Light lavender for backgrounds
```

### Phase 2: Add Shadow Colors

```swift
// MARK: - Shadow Colors
static var shadow: Color { AppColors.shadowMedium }
static var shadowLight: Color { AppColors.shadowLight }
static var shadowHeavy: Color { AppColors.shadowHeavy }
```

### Phase 3: Add Interactive States

```swift
// MARK: - Interactive States
static var hover: Color { AppColors.hoverBackground }
static var pressed: Color { ThemeManager.shared.primaryShade700 }
static var selected: Color { ThemeManager.shared.primaryShade100 }
static var backgroundDisabled: Color { WarmGray.shade100 }
```

### Phase 4: Add Accent Color

```swift
// MARK: - Accent Color
static var accent: Color { ThemeManager.shared.accentWarmColor }
static var accentLight: Color { ThemeManager.shared.accentWarmColor.opacity(Opacity.subtle) }
```

---

## Implementation Steps

### Step 1: Update ColorPalette.swift

Add the missing properties to `SemanticColors` enum.

### Step 2: Update ThemeManager.swift

Add any new theme-aware properties needed.

### Step 3: Update AppTheme.swift

Add any new theme-specific color mappings.

### Step 4: Update Migration Script

Update `migrate-appcolors-to-semantic.py` with correct mappings:

| AppColors | SemanticColors |
|-----------|----------------|
| `textPrimary` | `textPrimary` |
| `textSecondary` | `textSecondary` |
| `textTertiary` | `textTertiary` |
| `primary` | `primaryAction` |
| `secondary` | `secondaryAction` |
| `accent` | `accent` |
| `success` | `statusSuccess` |
| `successLight` | `statusSuccessLight` |
| `warning` | `statusWarning` |
| `warningLight` | `statusWarningLight` |
| `error` | `statusError` |
| `errorLight` | `statusErrorLight` |
| `info` | `statusInfo` |
| `infoLight` | `statusInfoLight` |
| `background` | `backgroundPrimary` |
| `backgroundSecondary` | `backgroundSecondary` |
| `cardBackground` | `backgroundSecondary` |
| `border` | `borderPrimary` |
| `borderLight` | `borderLight` |
| `divider` | `borderPrimary` |
| `shadow` | `shadow` |
| `shadowLight` | `shadowLight` |
| `hover` | `hover` |
| `disabled` | `textDisabled` |
| `selected` | `selected` |

### Step 5: Run Migration

After enhancing SemanticColors, run the migration script.

---

## Benefits

1. **Complete Semantic System** - All UI colors have semantic names
2. **Theme-Aware** - Colors adapt to user's selected theme
3. **WCAG Compliant** - All colors meet accessibility standards
4. **Maintainable** - Single source of truth for colors
5. **Scalable** - Easy to add new themes or colors
6. **Industry Standard** - Follows Material Design 3 and Apple HIG patterns

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Breaking existing views | Run build after each phase |
| Theme inconsistency | Test all 4 themes after changes |
| Accessibility regression | Run WCAG contrast tests |
| Migration script errors | Use --dry-run first |

---

## Timeline

| Phase | Effort | Priority |
|-------|--------|----------|
| Phase 1: Status Colors | 30 min | P0 |
| Phase 2: Shadow Colors | 15 min | P1 |
| Phase 3: Interactive States | 20 min | P1 |
| Phase 4: Accent Color | 10 min | P2 |
| Update Migration Script | 30 min | P0 |
| Run Migration | 1 hour | P0 |
| Testing | 1 hour | P0 |

**Total Estimated Time:** ~3.5 hours

---

## Decision

**Recommended Approach:** Implement this enhancement plan before continuing the migration.

**Rationale:**
1. Current migration is blocked by missing SemanticColors properties
2. Enhancing now prevents future migration issues
3. Results in a complete, industry-standard color system
4. One-time investment with long-term benefits

---

## Next Steps

1. [ ] Review and approve this plan
2. [ ] Implement Phase 1-4 in ColorPalette.swift
3. [ ] Update ThemeManager.swift and AppTheme.swift
4. [ ] Update migration script with correct mappings
5. [ ] Run migration with --dry-run
6. [ ] Apply migration
7. [ ] Build and test
8. [ ] Commit and push
