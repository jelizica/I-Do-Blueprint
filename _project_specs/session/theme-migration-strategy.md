# Theme Migration Strategy - Make Theme Switching Work App-Wide

**Created:** 2026-01-02
**Status:** In Progress - Phase 1 Complete
**Goal:** Enable seamless theme switching across all 569 view files

## Problem Statement

User clicked default theme in Settings → No visual change in app. Root cause discovered through comprehensive analysis:

**❌ Current State:**
- 2,440 instances of hardcoded `AppColors.*` in 569 view files
- 0 instances of theme-aware `SemanticColors.*` being used
- Theme infrastructure (ThemeManager, AppTheme, SemanticColors) exists but views don't use it
- Quick Actions were hardcoded (fixed in Phase 1)

**✅ Target State:**
- All views use `SemanticColors.*` or `QuickActions.*` or `BudgetCategoryColors.*`
- Theme switching triggers reactive updates across entire app
- All 4 existing themes (+ 5 new themes user is gathering colors for) work seamlessly

## Migration Scope Analysis

### By Color Pattern (grep results)

| Pattern | Count | Migration Target |
|---------|-------|-----------------|
| `AppColors.textSecondary` | 654 | `SemanticColors.textSecondary` |
| `AppColors.textPrimary` | 563 | `SemanticColors.textPrimary` |
| `AppColors.Budget.*` | 476 | `BudgetCategoryColors.*` or `SemanticColors.statusSuccess/statusWarning` |
| `AppColors.primary` | 194 | `SemanticColors.primaryAction` |
| `AppColors.cardBackground` | 136 | `SemanticColors.backgroundPrimary` |
| `AppColors.Dashboard.*` | 11 files | `QuickActions.*` |
| `AppColors.Guest.*` | 13 files | `SemanticColors.statusSuccess/statusPending/statusWarning` |
| Hardcoded opacity (0.05, 0.1, 0.15, 0.5) | 453 | `Opacity.verySubtle/subtle/light/medium/strong` |

### By File (Top 20 Highest Impact)

| File | Instances | Priority |
|------|-----------|----------|
| `V3VendorFinancialContent.swift` | 45 | P0 - Critical |
| `OnboardingGuestImportView.swift` | 36 | P1 - High |
| `OnboardingVendorImportView.swift` | 32 | P1 - High |
| `WeddingDetailsView.swift` | 30 | P1 - High |
| `GuestExportView.swift` | 27 | P1 - High |
| `V3VendorDetailView.swift` | 26 | P1 - High |
| `TimelineView.swift` | 26 | P1 - High |
| `V3VendorCardView.swift` | 23 | P2 - Medium |
| `BudgetDashboardView.swift` | 22 | P0 - Critical (user-facing) |
| `GuestListView.swift` | 21 | P0 - Critical (user-facing) |
| `PaymentScheduleView.swift` | 20 | P0 - Critical (user-facing) |
| `TaskListView.swift` | 19 | P1 - High |
| ... | ... | ... |

## Migration Phases

### ✅ Phase 1: Quick Actions (COMPLETED)

**Files Changed:**
- `AppTheme.swift` - Added `quickActionBudget` and `quickActionVendor`
- `ThemeManager.swift` - Exposed new color accessors
- `ColorPalette.swift` - Extended `QuickActions` enum with budget/vendor
- `QuickActionsCardV4.swift` - Converted to theme-aware colors

**Result:** Quick Actions now change color when theme is switched. Build succeeded.

### 🚧 Phase 2: Critical User-Facing Views (IN PROGRESS)

**Target:** Dashboard, Budget, Guest, Vendor main views
**Files:** ~15 high-priority files
**Estimated Effort:** 2-4 hours

**Prioritized File List:**
1. `BudgetDashboardView.swift` (22 instances)
2. `GuestListView.swift` (21 instances)
3. `PaymentScheduleView.swift` (20 instances)
4. `VendorListView.swift` (18 instances)
5. `TaskListView.swift` (19 instances)
6. `DashboardView.swift` (17 instances)
7. `TimelineView.swift` (26 instances)
8. `SettingsView.swift` (15 instances)

**Migration Pattern:**
```swift
// BEFORE (Hardcoded)
Text("Budget")
    .foregroundColor(AppColors.textPrimary)
    .background(AppColors.cardBackground)
Button("Save")
    .foregroundColor(AppColors.primary)
    .background(AppColors.primary.opacity(0.1))

// AFTER (Theme-Aware)
Text("Budget")
    .foregroundColor(SemanticColors.textPrimary)
    .background(SemanticColors.backgroundPrimary)
Button("Save")
    .foregroundColor(SemanticColors.primaryAction)
    .background(SemanticColors.primaryAction.opacity(Opacity.subtle))
```

### 📋 Phase 3: Feature-Specific Views

**Target:** Onboarding, Export, Import views
**Files:** ~30 medium-priority files
**Estimated Effort:** 4-6 hours

**Categories:**
- Onboarding flows (Guest/Vendor import)
- Export/Import views
- Detail views (Guest/Vendor/Task detail pages)
- Modal/Sheet views

### 📋 Phase 4: Remaining Views

**Target:** All other views with `AppColors.*`
**Files:** ~524 remaining files
**Estimated Effort:** 8-12 hours

**Approach:**
- Batch process by color type (textPrimary, textSecondary, etc.)
- Use migration script where applicable
- Manual review of complex views

### 🔍 Phase 5: Testing & Validation

**Tasks:**
1. Switch between all 4 themes in Settings
2. Navigate to each main feature (Budget, Guests, Vendors, Tasks, Timeline)
3. Verify colors update immediately
4. Check accessibility (WCAG AA/AAA contrast)
5. Test dark mode compatibility (future)

## Automated Migration Script

**Location:** `Scripts/migrate-colors.sh`

**Available Commands:**
```bash
# Scan for migration opportunities
./Scripts/migrate-colors.sh scan

# Migrate Dashboard quick actions
./Scripts/migrate-colors.sh migrate-dashboard

# Migrate Guest status colors
./Scripts/migrate-colors.sh migrate-guest

# Migrate hardcoded opacity values
./Scripts/migrate-colors.sh migrate-opacity

# Run all migrations (use with caution)
./Scripts/migrate-colors.sh migrate-all
```

**Scan Results:**
- 11 files using `AppColors.Dashboard.*` → `QuickActions.*`
- 13 files using `AppColors.Guest.*` → `SemanticColors.status*`
- 453 hardcoded opacity values → `Opacity.*` enum

## Color Mapping Reference

### Text Colors
| Old | New |
|-----|-----|
| `AppColors.textPrimary` | `SemanticColors.textPrimary` |
| `AppColors.textSecondary` | `SemanticColors.textSecondary` |
| `AppColors.textTertiary` | `SemanticColors.textTertiary` |
| `AppColors.textQuaternary` | `SemanticColors.textDisabled` |

### Backgrounds
| Old | New |
|-----|-----|
| `AppColors.background` | `SemanticColors.backgroundPrimary` |
| `AppColors.cardBackground` | `SemanticColors.backgroundSecondary` |
| `AppColors.backgroundSecondary` | `SemanticColors.backgroundTertiary` |

### Actions
| Old | New |
|-----|-----|
| `AppColors.primary` | `SemanticColors.primaryAction` |
| `AppColors.primaryLight` | `SemanticColors.primaryActionHover` |

### Status (Guest)
| Old | New |
|-----|-----|
| `AppColors.Guest.confirmed` | `SemanticColors.statusSuccess` |
| `AppColors.Guest.pending` | `SemanticColors.statusPending` |
| `AppColors.Guest.declined` | `SemanticColors.statusWarning` |

### Status (Budget)
| Old | New |
|-----|-----|
| `AppColors.Budget.income` | `SemanticColors.statusSuccess` |
| `AppColors.Budget.expense` | `SemanticColors.statusWarning` |
| `AppColors.Budget.pending` | `SemanticColors.statusPending` |

### Quick Actions
| Old | New |
|-----|-----|
| `AppColors.Dashboard.taskAction` | `QuickActions.task` |
| `AppColors.Dashboard.noteAction` | `QuickActions.note` |
| `AppColors.Dashboard.eventAction` | `QuickActions.event` |
| `AppColors.Dashboard.guestAction` | `QuickActions.guest` |
| `AppColors.info` (Budget) | `QuickActions.budget` |
| `AppColors.success` (Vendor) | `QuickActions.vendor` |

### Opacity Values
| Old | New |
|-----|-----|
| `.opacity(0.05)` | `.opacity(Opacity.verySubtle)` |
| `.opacity(0.1)` | `.opacity(Opacity.subtle)` |
| `.opacity(0.15)` | `.opacity(Opacity.light)` |
| `.opacity(0.5)` | `.opacity(Opacity.medium)` |
| `.opacity(0.95)` | `.opacity(Opacity.strong)` |

## Testing Strategy

### Per-Phase Testing
After each phase:
1. Build project (`⌘B`)
2. Run app
3. Navigate to Settings → Theme
4. Switch between all 4 themes:
   - Blush Romance (default)
   - Sage Serenity
   - Lavender Dream
   - Terracotta Warm
5. Verify migrated views change colors
6. Check for visual regressions

### Final Validation
After all phases complete:
1. Systematic theme switching in all major views
2. Accessibility audit (contrast ratios)
3. Dark mode compatibility check (future)
4. Screenshot comparison (before/after each theme)

## Git Workflow

### Per Phase
```bash
# Stage changes
git add <changed-files>

# Commit with descriptive message
git commit -m "feat(theme): Migrate <feature> to theme-aware colors

- Converted <count> instances in <view-name>
- Replaced AppColors.* with SemanticColors.*
- Theme switching now works in <feature> views

Phase: <phase-number>
Files: <list>
Instances: <count>"

# Sync beads
bd sync

# Push to remote
git push
```

### Session Close Protocol
```bash
# 1. Check what changed
git status

# 2. Stage code changes
git add <files>

# 3. Sync beads changes
bd sync

# 4. Commit code
git commit -m "..."

# 5. Sync any new beads changes
bd sync

# 6. Push to remote
git push
```

## Success Criteria

- [ ] Phase 1: Quick Actions theme-aware ✅
- [ ] Phase 2: Critical views (Dashboard, Budget, Guest, Vendor) theme-aware
- [ ] Phase 3: Feature-specific views theme-aware
- [ ] Phase 4: All 569 views theme-aware
- [ ] Phase 5: Testing complete, no regressions
- [ ] User can switch themes in Settings and see instant color changes app-wide
- [ ] All 4 existing themes work correctly
- [ ] Infrastructure ready for 5 new themes user is gathering colors for

## Next Steps

1. **Commit Phase 1 changes** ✅ (in progress)
2. **Begin Phase 2:** Migrate BudgetDashboardView.swift
3. **Iterate:** One critical view at a time
4. **Test:** After each file, verify theme switching works
5. **Repeat:** Until all 569 files migrated

## Notes

- **Don't skip testing:** Theme switching is fragile, test after each phase
- **Use migration script cautiously:** Some views need manual review
- **Preserve semantics:** Don't just swap names, ensure color meanings match
- **Track progress:** Update this doc after each phase completion
