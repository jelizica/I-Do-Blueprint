---
title: Optimized Budget Pages - Expense Categories Compact View
type: note
permalink: architecture/features/optimized-budget-pages/optimized-budget-pages-expense-categories-compact-view
tags:
  - budget
  - expense-categories
  - compact-view
  - responsive-design
  - swiftui
  - macos
  - implementation-complete
  - llm-council
  - patterns
  - architecture
---

# Optimized Budget Pages - Expense Categories Compact View

> **Status:** ✅ COMPLETE  
> **Implementation Date:** January 2-3, 2026  
> **Beads Issue:** I Do Blueprint-bs4  
> **Epic:** Budget Compact Views Optimization (I Do Blueprint-0f4)  
> **Total Implementation Time:** ~7.5 hours

---

## Executive Summary

The Expense Categories page was successfully optimized for compact window layouts (640-700px width), enabling full functionality on 13" MacBook Air split-screen workflows. This implementation followed an LLM Council design decision and applied 4 established architectural patterns from the knowledge repository.

### Key Metrics

| Metric | Value |
|--------|-------|
| New Components Created | 6 files (~1,130 lines) |
| Files Modified | 5 files (~200 lines) |
| Patterns Applied | 4 architectural patterns |
| Build Success Rate | 100% (all 12 phases) |
| Critical Bugs Fixed | 3 (freeze, UI issues, calculation errors) |

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Solution Architecture](#solution-architecture)
3. [LLM Council Design Decision](#llm-council-design-decision)
4. [Implementation Phases](#implementation-phases)
5. [Components Created](#components-created)
6. [Patterns Applied](#patterns-applied)
7. [Critical Bug Fixes](#critical-bug-fixes)
8. [Technical Implementation Details](#technical-implementation-details)
9. [Testing Checklist](#testing-checklist)
10. [Known Issues & Future Work](#known-issues--future-work)
11. [Lessons Learned](#lessons-learned)
12. [Related Documentation](#related-documentation)

---

## Problem Statement

### Original Issues

The Expense Categories page had several limitations preventing effective use on compact windows:

1. **No WindowSize Detection** - Components didn't adapt to window size
2. **Fixed Header Layout** - Title and search bar didn't respond to compact mode
3. **List-Based Display** - Used SwiftUI `List` which has issues inside ScrollView
4. **No Unified Header** - Missing navigation dropdown to other budget pages
5. **No Summary Cards** - Missing at-a-glance metrics like other budget pages
6. **Fixed Modal Sizing** - Add/Edit category modals didn't scale with window

### Target Use Case

A user on a 13" MacBook Air running the app in split-screen mode alongside Safari. The app window is only 640px wide. Without responsive design:
- Headers overflow and clip
- Category hierarchy becomes unusable
- Action buttons disappear off-screen
- Modals extend into the dock

---

## Solution Architecture

### Component Hierarchy (After Optimization)

```
ExpenseCategoriesView
├── GeometryReader (WindowSize detection)
│   ├── VStack(spacing: 0)
│   │   ├── ExpenseCategoriesUnifiedHeader (STATIC)
│   │   │   ├── Title Row: "Budget" + "Expense Categories" subtitle
│   │   │   ├── Actions: Ellipsis menu (⋯) + Navigation dropdown
│   │   │   └── Dual initializer for embedded/standalone
│   │   │
│   │   ├── ExpenseCategoriesStaticHeader (STATIC)
│   │   │   ├── Search Bar
│   │   │   ├── Hierarchy Counts (📁 Parents • 📄 Subcategories)
│   │   │   ├── Over-Budget Alert (clickable filter)
│   │   │   └── Add Category Button
│   │   │
│   │   └── ScrollView
│   │       ├── ExpenseCategoriesSummaryCards
│   │       │   ├── Total Categories
│   │       │   ├── Total Allocated
│   │       │   ├── Total Spent
│   │       │   └── Over Budget Count
│   │       │
│   │       └── LazyVStack (replaces List)
│   │           └── ForEach(parentCategories)
│   │               └── CategorySectionViewV2
│   │                   ├── CategoryFolderRowViewV2 (responsive)
│   │                   └── ForEach(subcategories)
│   │                       └── CategoryRowViewV2 (responsive)
```

### Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| Replace List with LazyVStack | Avoids List Inside ScrollView Anti-Pattern |
| Unified Header Pattern | Consistent with Budget Builder, Expense Tracker, Payment Schedule |
| Summary Cards | 4 cards showing key metrics (matches Budget Overview pattern) |
| Static Header with Hierarchy Counts | Per LLM Council + user requirement |
| Dual Initializer | Support both embedded (hub navigation) and standalone usage |
| Proportional Modal Sizing | Add/Edit modals scale with window |

---

## LLM Council Design Decision

### Council Composition
- GPT-5.1
- Gemini 3 Pro
- Claude Sonnet 4.5
- Grok 4

### Consensus Recommendation

**Core Pattern:** Search + Hierarchy Counts + Clickable Over-Budget Alert + Add Category Button

### Final Design

**Regular Mode (≥700px):**
```
┌──────────────────────────────────────────────────────────────────────────────────��──┐
│ [🔍 Search categories...    ] │ 📁 11 Parents • 📄 25 Subcategories │ ⚠️ 3 over budget │ [+ Add] │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**Compact Mode (<700px):**
```
┌─────────────────────────────────┐
│ [🔍 Search categories...      ] │
│ 📁 11 • 📄 25 • ⚠️ 3 over [+ Add] │
└─────────────────────────────────┘
```

### Design Principles (Per Council)

| Principle | Implementation |
|-----------|----------------|
| Header = Utility Bar | Tools for action, not just display |
| Summary Cards = Metrics Dashboard | Status display below header |
| Visual Style | Minimal background (like Payment Schedule) |
| Hierarchy Counts | Include parent/subcategory counts per user requirement |
| Over-Budget Alert | Clickable badge that filters to problem categories |
| Positive Fallback | "All on track ✓" when no problems |

---

## Implementation Phases

### Phase Summary

| Phase | Description | Duration | Status |
|-------|-------------|----------|--------|
| 0 | Setup & Planning | 15 min | ✅ Complete |
| 1 | Foundation & WindowSize Detection | 30 min | ✅ Complete |
| 2 | Unified Header Component | 45 min | ✅ Complete |
| 3 | Summary Cards Component | 45 min | ✅ Complete |
| 4 | Static Header with Search, Hierarchy & Alert | 60 min | ✅ Complete |
| 5 | Replace List with LazyVStack | 30 min | ✅ Complete |
| 6 | Responsive Category Section | 45 min | ✅ Complete |
| 7 | Responsive Category Rows | 45 min | ✅ Complete |
| 8 | Modal Sizing | 30 min | ✅ Complete |
| 9 | Integration & Polish | 30 min | ✅ Complete |
| 10 | User Feedback Fixes | 60 min | ✅ Complete |
| 11 | Additional UI Fixes | 45 min | ✅ Complete |
| 12 | Critical Freeze Fix | 90 min | ✅ Complete |

**Total Implementation Time:** ~7.5 hours (estimated 5-6 hours)

---

## Components Created

### 1. ExpenseCategoriesUnifiedHeader.swift (~180 lines)

**Purpose:** Unified header with navigation dropdown and actions menu

**Features:**
- Title hierarchy: "Budget" + "Expense Categories" subtitle
- Navigation dropdown to all budget pages
- Ellipsis menu: Export, Import, Expand All, Collapse All
- Dual initializer pattern for embedded/standalone usage
- Responsive layout (compact vs regular)

**Pattern Applied:** [[Unified Header with Responsive Actions Pattern]]

---

### 2. ExpenseCategoriesSummaryCards.swift (~200 lines)

**Purpose:** Summary cards displaying 4 key metrics

**Metrics:**

| Card | Icon | Color | Data Source |
|------|------|-------|-------------|
| Total Categories | 📁 folder.fill | Purple | `categories.count` |
| Total Allocated | 💰 dollarsign.circle | Blue | Sum of leaf category allocations |
| Total Spent | 💳 creditcard.fill | Orange | Sum of category spending |
| Over Budget | ⚠️ exclamationmark.triangle.fill | Red | Count where spent > allocated |

**Layout:**
- Regular (≥700px): 4-column grid
- Compact (<700px): Adaptive grid (2-3 cards per row)

**Pattern Applied:** [[SwiftUI LazyVGrid Adaptive Card Grid Pattern]]

---

### 3. ExpenseCategoriesStaticHeader.swift (~280 lines)

**Purpose:** Static header with search, hierarchy counts, and problem alert

**Features:**
- Search bar with clear button (⌘F keyboard shortcut)
- Hierarchy counts: 📁 Parents • 📄 Subcategories
- Over-budget alert badge (clickable filter toggle)
- Positive fallback: "All on track ✓" when no problems
- Add Category button (⌘N keyboard shortcut)
- Responsive layout (vertical in compact, horizontal in regular)

**Pattern Applied:** [[Static Header with Contextual Information Pattern]]

---

### 4. CategorySectionViewV2.swift (~100 lines)

**Purpose:** Responsive collapsible section for parent categories

**Features:**
- Collapsible parent category with chevron animation
- Card-style background with shadow
- Responsive spacing (compact: md, regular: lg)
- Smooth expand/collapse animation (0.2s easeInOut)
- Passes windowSize to child components

**Pattern Applied:** [[Collapsible Section Pattern]]

---

### 5. CategoryFolderRowViewV2.swift (~250 lines)

**Purpose:** Responsive parent category row

**Compact Layout (<700px):**
```
┌─────────────────────────────────────┐
│ ▼ 📁 Venue (3 subcategories)        │
│    $5,000 / $8,000  ████████░░ 62%  │
└─────────────────────────────────────┘
```

**Regular Layout (≥700px):**
```
┌──────────────────────────────────────────────────────────┐
│ ▼ 📁 Venue (3 subcategories)  ████████░░ 62%  $5K / $8K │
└───────────────────────────────────────────────────────��──┘
```

**Pattern Applied:** [[WindowSize Enum and Responsive Breakpoints Pattern]]

---

### 6. CategoryRowViewV2.swift (~220 lines)

**Purpose:** Responsive subcategory row

**Compact Layout (<700px):**
```
┌─────────────────────────────────────┐
│    📄 Ceremony Venue                │
│       $2,500 / $4,000  ██████░░ 62% │
└─────────────────────────────────────┘
```

**Regular Layout (≥700px):**
```
┌──────────────────────────────────────────────────────────┐
│    📄 Ceremony Venue  ██████░░ 62%  $2.5K / $4K  [⋯]    │
└──────────────────────────────────────────────────────────┘
```

**Pattern Applied:** [[WindowSize Enum and Responsive Breakpoints Pattern]]

---

## Patterns Applied

### 1. WindowSize Enum and Responsive Breakpoints Pattern

**Source:** `knowledge-repo-bm/architecture/patterns/responsive-design/`

**Application:** Foundation for all responsive behavior

```swift
GeometryReader { geometry in
    let windowSize = geometry.size.width.windowSize
    let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl
    let availableWidth = geometry.size.width - (horizontalPadding * 2)
    // ...
}
```

**Breakpoints:**
- Compact: < 700pt
- Regular: 700-1000pt
- Large: > 1000pt

---

### 2. Collapsible Section Pattern

**Source:** `knowledge-repo-bm/architecture/patterns/responsive-design/`

**Application:** CategorySectionViewV2 for parent category expansion

**Key Features:**
- Smooth 0.2s easeInOut animation
- Chevron rotation indicator
- State management via `Set<UUID>`
- Card-style visual grouping

---

### 3. Dual Initializer Pattern for Navigation Binding

**Source:** `knowledge-repo-bm/architecture/patterns/component-patterns/`

**Application:** ExpenseCategoriesView and ExpenseCategoriesUnifiedHeader

```swift
// Embedded usage (with navigation)
init(currentPage: Binding<BudgetPage>) {
    self._currentPage = currentPage
}

// Standalone usage (no navigation)
init() {
    self._currentPage = .constant(.expenseCategories)
}
```

---

### 4. Proportional Modal Sizing Pattern

**Source:** `knowledge-repo-bm/architecture/patterns/component-patterns/`

**Application:** AddCategoryView and EditCategoryView

```swift
private var dynamicSize: CGSize {
    let parentSize = coordinator.parentWindowSize
    let targetWidth = min(maxWidth, max(minWidth, parentSize.width * 0.6))
    let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.75 - windowChromeBuffer))
    return CGSize(width: targetWidth, height: targetHeight)
}
```

**Sizing Constants:**
- Min: 400x400px
- Max: 600x700px
- Proportions: 60% width, 75% height
- Chrome buffer: 40px

---

## Critical Bug Fixes

### Bug 1: App Freeze After ~5 Minutes (Phase 12)

**Severity:** P0 Critical

**Root Cause:** Timer-based polling (`Timer.publish(every: 0.5s)`) combined with:
1. Timer firing every 0.5s → calls `recalculateSummaryValues()`
2. Store property access → triggers `objectWillChange`
3. `objectWillChange` forwarding → via Combine sinks in `BudgetStoreV2.init()`
4. `@EnvironmentObject` subscription → SwiftUI re-renders view
5. Feedback loop accumulates → overwhelms system after ~5 minutes

**Solution:** Remove timer-based polling entirely, follow working views pattern:
1. Load data once on `.task`
2. Recalculate only on user actions (search, filter toggle, modal dismiss, delete)
3. Synchronous calculation on main thread

**Key Lesson:** Never use timer-based polling in SwiftUI views with `@EnvironmentObject` subscriptions to stores with `objectWillChange` forwarding.

---

### Bug 2: Total Allocated Double-Counting (Phase 11)

**Severity:** P1 High

**Root Cause:** Summing all categories including parent folders, which are aggregates of subcategories.

**Solution:** Only sum leaf categories (categories without children):
```swift
private var categoriesWithChildren: Set<UUID> {
    Set(categories.compactMap { $0.parentCategoryId })
}

private var totalAllocated: Double {
    categories
        .filter { !categoriesWithChildren.contains($0.id) }
        .reduce(0) { $0 + $1.allocatedAmount }
}
```

---

### Bug 3: Color Picker Not Functioning (Phase 10)

**Severity:** P1 High

**Root Cause:** `BudgetCategory` model didn't have a stored color property.

**Solution:**
1. Added `color TEXT` column to `budget_categories` table (migration)
2. Updated `BudgetCategory` model with stored color property
3. `AddCategoryView` saves `selectedColor.hexString`
4. `EditCategoryView` loads existing color and saves changes
5. Default color: `#3B82F6` (blue)

---

## Technical Implementation Details

### WindowSize Detection

```swift
GeometryReader { geometry in
    let windowSize = geometry.size.width.windowSize
    let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl
    let availableWidth = geometry.size.width - (horizontalPadding * 2)
    
    VStack(spacing: 0) {
        // Static headers
        ExpenseCategoriesUnifiedHeader(windowSize: windowSize, ...)
        ExpenseCategoriesStaticHeader(windowSize: windowSize, ...)
        
        // Scrollable content
        ScrollView {
            VStack(spacing: Spacing.lg) {
                ExpenseCategoriesSummaryCards(windowSize: windowSize, ...)
                LazyVStack(spacing: Spacing.md) {
                    // Category sections
                }
            }
            .frame(width: availableWidth)
            .padding(.horizontal, horizontalPadding)
        }
    }
}
```

### Cached Summary Values (Performance Optimization)

```swift
// Cached values to prevent scroll freeze
@State private var cachedTotalCategories: Int = 0
@State private var cachedParentCount: Int = 0
@State private var cachedSubcategoryCount: Int = 0
@State private var cachedTotalAllocated: Double = 0
@State private var cachedTotalSpent: Double = 0
@State private var cachedOverBudgetCount: Int = 0
@State private var cachedSpentByCategory: [UUID: Double] = [:]

private func recalculateCachedValues() {
    let categories = budgetStore.categoryStore.categories
    let expenses = budgetStore.expenseStore.expenses
    
    // Build spent dictionary once (O(n) pass)
    var spentDict: [UUID: Double] = [:]
    for expense in expenses {
        if let categoryId = expense.budgetCategoryId {
            spentDict[categoryId, default: 0] += expense.amount
        }
    }
    
    // Calculate all values
    cachedTotalCategories = categories.count
    cachedParentCount = categories.filter { $0.parentCategoryId == nil }.count
    cachedSubcategoryCount = categories.filter { $0.parentCategoryId != nil }.count
    // ... etc
    cachedSpentByCategory = spentDict
}
```

### Over-Budget Filter Logic

```swift
@State private var showOnlyOverBudget: Bool = false

private var filteredParentCategories: [BudgetCategory] {
    var parents = categories.filter { $0.parentCategoryId == nil }
    
    // Apply search filter
    if !searchText.isEmpty {
        parents = parents.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    // Apply over-budget filter
    if showOnlyOverBudget {
        parents = parents.filter { isOverBudget($0) }
    }
    
    return parents
}
```

---

## Testing Checklist

### Window Size Testing

| Width | Expected Behavior | Status |
|-------|-------------------|--------|
| 640px | Full compact layout, no clipping | ⏳ Manual test required |
| 700px | Breakpoint - transition to regular | ⏳ Manual test required |
| 900px | Regular layout | ⏳ Manual test required |
| 1200px | Large layout | ⏳ Manual test required |

### Functional Testing

| Feature | Status |
|---------|--------|
| Search filters categories correctly | ⏳ Manual test required |
| Parent category expansion/collapse works | ⏳ Manual test required |
| Expand All / Collapse All works | ⏳ Manual test required |
| Over budget badge click filters to problem categories | ⏳ Manual test required |
| Filter toggle shows visual state change | ⏳ Manual test required |
| Positive fallback shows when no over-budget categories | ⏳ Manual test required |
| Add category modal opens and sizes correctly | ⏳ Manual test required |
| Edit category modal opens and sizes correctly | ⏳ Manual test required |
| Delete category confirmation works | ⏳ Manual test required |
| Navigation dropdown navigates to other pages | ⏳ Manual test required |
| Budget progress bars display correctly | ⏳ Manual test required |
| Category colors display correctly | ⏳ Manual test required |
| Summary cards show correct values | ⏳ Manual test required |
| Hierarchy counts are accurate | ⏳ Manual test required |
| Keyboard shortcuts work (⌘F, ⌘N) | ⏳ Manual test required |

### Build Verification

| Check | Status |
|-------|--------|
| No compiler errors | ✅ Complete |
| No new warnings | ✅ Complete |
| All existing tests pass | ⏳ Manual test required |

---

## Known Issues & Future Work

### Open Issue: Categories Show "0 / $XXX" - Payment Calculation Incorrect

**Beads Issue:** I Do Blueprint-sp8d  
**Priority:** P2 (Medium)

**Problem:** All categories show "0 spent" because the spent calculation uses `expenses.amount` directly, but should calculate based on **paid payments** from the `payment_plans` table.

**Expected Behavior:** Show percentage of expenses that have been PAID:
```
(sum of paid payments for category expenses) / (total allocated for category) * 100
```

**Solution Approach:**
1. Create new repository method: `fetchPaidAmountsByCategory()`
2. Update `ExpenseCategoriesView.recalculateCachedValues()`
3. Update `CategoryStoreV2.spentAmount()` to support both modes

**Affected Files:**
- `ExpenseCategoriesView.swift`
- `Services/Stores/Budget/CategoryStoreV2.swift`
- `Domain/Repositories/Protocols/BudgetRepositoryProtocol.swift`
- `Domain/Repositories/Live/LiveBudgetRepository.swift`

---

### Future Enhancements

| Enhancement | Priority | Effort |
|-------------|----------|--------|
| CSV Export/Import functionality | P3 | Medium |
| Drag & Drop category reordering | P4 | High |
| Bulk operations (multi-select) | P4 | Medium |
| Category templates | P4 | Low |
| Budget allocation wizard | P4 | High |
| Category analytics/trends | P4 | Medium |

---

## Lessons Learned

### What Went Well

1. **Pattern Reuse** - Leveraging Basic Memory patterns accelerated development
2. **Incremental Builds** - Building and verifying after each phase caught issues early
3. **Component Modularity** - V2 components are highly reusable
4. **LLM Council Decision** - Clear design direction prevented rework
5. **Dual Initializer Pattern** - Seamlessly supports embedded and standalone usage

### Challenges Overcome

1. **List vs LazyVStack** - Replaced List to avoid scrolling issues
2. **State Management** - Used `Set<UUID>` for efficient expansion tracking
3. **Responsive Layouts** - Dual layout approach (compact vs regular) worked well
4. **Modal Sizing** - AppCoordinator integration required careful coordination
5. **Filter Composition** - Search + over-budget filter required AND logic
6. **Performance** - Timer-based polling caused freeze; switched to event-driven updates

### Key Takeaways

1. **Never use timer-based polling** in SwiftUI views with `@EnvironmentObject` subscriptions
2. **Cache expensive calculations** to prevent scroll freeze
3. **Build pre-computed dictionaries** for O(1) lookups in child views
4. **Follow working views pattern** - check how similar views handle data loading
5. **Document decisions** - LLM Council decisions saved significant time

---

## Related Documentation

### Implementation Documents
- [[Expense Categories Compact View Implementation Plan]] - Original plan
- `docs/EXPENSE_CATEGORIES_COMPACT_IMPLEMENTATION_PROGRESS.md` - Progress tracking
- `docs/EXPENSE_CATEGORIES_COMPACT_IMPLEMENTATION_COMPLETE.md` - Completion summary

### LLM Council Decision
- [[LLM Council Prompt - Expense Categories Static Header Design]] - Council prompt
- [[LLM Council Deliberation - Expense Categories Static Header Design]] - Council responses

### Patterns Applied
- [[Collapsible Section Pattern]]
- [[WindowSize Enum and Responsive Breakpoints Pattern]]
- [[Dual Initializer Pattern for Navigation Binding]]
- [[Proportional Modal Sizing Pattern]]
- [[SwiftUI LazyVGrid Adaptive Card Grid Pattern]]
- [[Static Header with Contextual Information Pattern]]
- [[Unified Header with Responsive Actions Pattern]]

### Reference Implementations
- [[Payment Schedule Optimization - Complete Reference]]
- [[Expense Tracker Optimization - Complete Session Reference]]
- [[Budget Dashboard Optimization - Complete Reference]]

### Beads Issues
- `I Do Blueprint-bs4` - Main implementation issue (CLOSED)
- `I Do Blueprint-po39` - Freeze fix (CLOSED)
- `I Do Blueprint-yahc` - Freeze investigation (CLOSED)
- `I Do Blueprint-r3ce` - UI issues and crash (CLOSED)
- `I Do Blueprint-w1u6` - Compact view feedback (CLOSED)
- `I Do Blueprint-vuio` - Leaf category display (CLOSED)
- `I Do Blueprint-sp8d` - Payment calculation (OPEN)

---

## Git Commits

| Commit | Description |
|--------|-------------|
| `ea79e00` | feat: Implement Expense Categories responsive components (Phases 6-7) |
| `d1df43b` | feat: Implement proportional modal sizing for category modals (Phase 8) |
| `4bba89a` | fix: Address user feedback issues (Phases 10) |
| `b76e091` | fix: Complete EditCategoryView fixes |
| `48a8f8d` | fix: UI issues and potential crash |
| `3c5d723` | fix: Cache expensive summary calculations |
| `9e9d4bc` | fix: Pass pre-computed spent amounts to child views |
| `fe06305` | fix: Change success checkmark to circle badge |
| `93ef2cc` | fix: Use debounced onReceive + fix leaf category display |
| `1ae794c` | fix: Use timer-based polling with task cancellation |
| `4e8facb` | fix: FINAL - Remove timer-based polling entirely |

---

## Files Reference

### New Files Created (6)
- `Views/Budget/Components/ExpenseCategoriesUnifiedHeader.swift`
- `Views/Budget/Components/ExpenseCategoriesSummaryCards.swift`
- `Views/Budget/Components/ExpenseCategoriesStaticHeader.swift`
- `Views/Budget/Components/CategorySectionViewV2.swift`
- `Views/Budget/Components/CategoryFolderRowViewV2.swift`
- `Views/Budget/Components/CategoryRowViewV2.swift`

### Files Modified (5)
- `Views/Budget/ExpenseCategoriesView.swift`
- `Views/Budget/BudgetDashboardHubView.swift`
- `Views/Budget/BudgetPage.swift`
- `Views/Budget/AddCategoryView.swift`
- `Views/Budget/EditCategoryView.swift`

---

**Document Created:** January 3, 2026  
**Last Updated:** January 3, 2026  
**Author:** AI Assistant  
**Project:** I Do Blueprint