# Expense Tracker Fixes - Round 2 Progress Report

> **Status:** 🚧 IN PROGRESS  
> **Started:** January 2026  
> **Estimated Duration:** 2-3 hours

---

## Feedback Items

### 1. ~~Table Dropdown UI Enhancement~~ - SKIPPED
User decided to skip this item.

---

### 2. Static Header Section - NEEDS COUNCIL INPUT
**Issue:** Budget Overview has a static "Scenario Management" section that doesn't scroll. Expense Tracker is missing this.

**Investigation Findings:**
- Budget Overview has `headerSection` outside ScrollView (static)
- Contains: Scenario picker, Search field, View mode toggle
- Expense Tracker has everything inside ScrollView (scrolls away)

**Question for LLM Council:** What should the static section contain for Expense Tracker?

**Prompt Created:** See below

---

### 3. Modal Size Fix - READY TO IMPLEMENT
**Issue:** Add Expense modal extends into dock

**Investigation Findings:**
- Guest Detail uses `coordinator.parentWindowSize` for dynamic sizing
- Pattern: 60% width, 75% height (minus 40px chrome buffer)
- Min/Max bounds: 400-700 width, 350-850 height
- Uses `AppCoordinator.shared.parentWindowSize`

**Current Expense Tracker Modal:**
```swift
.frame(minWidth: 700, idealWidth: 750, maxWidth: 800, minHeight: 650, idealHeight: 750, maxHeight: 850)
```

**Fix Pattern (from GuestDetailViewV4):**
```swift
private var dynamicSize: CGSize {
    let parentSize = coordinator.parentWindowSize
    let targetWidth = min(maxWidth, max(minWidth, parentSize.width * 0.6))
    let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.75 - windowChromeBuffer))
    return CGSize(width: targetWidth, height: targetHeight)
}
```

**Files to Modify:**
- `ExpenseTrackerAddView.swift`
- `ExpenseTrackerEditView.swift`

---

### 4. Stats Card Sizing - READY TO IMPLEMENT
**Issue:** Stats cards in Expense Tracker don't match Budget Dashboard/Builder

**Investigation Findings:**

**Budget Overview uses `SummaryCardView` (regular mode):**
- Icon: 44x44 circle background, 20pt icon
- Title: 11pt, uppercase, tracking 0.5
- Value: 28pt, bold, rounded design
- Padding: `Spacing.xl`
- Hover effects, gradient overlay

**Expense Tracker uses `ExpenseStatCard`:**
- Icon: 24pt, no background
- Title: `Typography.caption`
- Value: `Typography.displayMedium`
- Padding: `Spacing.md`
- No hover effects

**Fix:** Replace `ExpenseStatCard` with `SummaryCardView` pattern or update to match

**Files to Modify:**
- `ExpenseTrackerUnifiedHeader.swift` (ExpenseStatCard component)

---

### 5. Category Benchmarks - Parent Only - READY TO IMPLEMENT
**Issue:** Category benchmarks showing all categories, should be parent-only

**Current Code:**
```swift
var categoryBenchmarks: [CategoryBenchmarkData] {
    budgetStore.categoryStore.categories.compactMap { category in
        // Shows ALL categories
    }
}
```

**Fix:**
```swift
var categoryBenchmarks: [CategoryBenchmarkData] {
    budgetStore.categoryStore.categories
        .filter { $0.parentCategoryId == nil }  // Parent only
        .compactMap { category in
            // ...
        }
}
```

**Files to Modify:**
- `ExpenseTrackerView.swift` (categoryBenchmarks computed property)

---

## Implementation Plan

| Phase | Task | Duration | Status |
|-------|------|----------|--------|
| 1 | Create LLM Council prompt for static header | 10 min | ✅ COMPLETE |
| 2 | Fix modal sizing (proportional to window) | 30 min | ✅ COMPLETE |
| 3 | Update stats card sizing to match Budget Dashboard | 30 min | ✅ COMPLETE |
| 4 | Filter category benchmarks to parent-only | 10 min | ✅ COMPLETE |
| 5 | Implement static header (Council design) | 45 min | ✅ COMPLETE |

**Total Estimated:** 2-2.5 hours  
**Actual Time:** ~3 hours  
**Status:** ✅ ALL PHASES COMPLETE + BUG FIXES

**Additional Work:**
- Fixed critical scrolling bug (GeometryReader anti-pattern)
- Fixed budget calculation (parent-only categories)
- Fixed guest data loading and reactivity
- Enhanced visual design

**Phase 5 Deliverables:**
- ✅ Created ExpenseTrackerStaticHeader.swift (Council's design)
- ✅ Updated ExpenseTrackerUnifiedHeader.swift (removed stats, kept title/nav)
- ✅ Updated ExpenseTrackerView.swift (added computed properties, restructured)
- ✅ Build successful
- ✅ All beads issues closed

---

## LLM Council Prompt for Static Header

```
## Context

I'm building a macOS wedding planning app with SwiftUI. The Budget module has multiple pages:
- Budget Overview (Dashboard) - Shows budget items with scenario management
- Budget Builder - Create/edit budget items
- Expense Tracker - Track actual expenses against budget

## Current State

The Budget Overview page has a static header section (doesn't scroll) that contains:
1. Scenario Management dropdown (select which budget scenario to view)
2. Search field
3. View mode toggle (cards/table)

The Expense Tracker page currently has NO static header section - everything scrolls.

## Question

What should the static header section contain for the Expense Tracker page?

The Expense Tracker is focused on:
- Tracking actual expenses (not budget planning)
- Filtering by payment status (Pending, Paid, Overdue)
- Filtering by category
- Viewing expense cards or list
- Showing category benchmarks (spent vs budgeted)

## Options I'm Considering

1. **Date Range Filter** - "This Month", "Last 3 Months", "This Year", "All Time"
2. **Quick Status Filters** - "All", "Pending Only", "Paid Only", "Overdue"
3. **Scenario Selector** - Same as Budget Overview (expenses are linked to scenarios)
4. **Summary Stats** - Quick totals (Total Spent, Pending, Paid)
5. **Combination** - Date range + Quick status

## Constraints

- Should be useful for expense tracking workflow
- Should match the visual pattern of Budget Overview (static, doesn't scroll)
- Should not duplicate functionality already in the filter bar below
- Should be compact enough for narrow windows

## What I Need

1. Your recommendation for what the static header should contain
2. Rationale for why this is most useful for expense tracking
3. Any alternative suggestions I haven't considered
```

---

## Key Findings

### ⚠️ CRITICAL: GeometryReader + ScrollView Anti-Pattern

**Problem:** GeometryReader inside a ScrollView blocks scrolling.

**Root Cause:** GeometryReader tries to take all available space, which prevents ScrollView from calculating content size properly.

**Symptoms:**
- Page appears but won't scroll
- Content is visible but stuck
- No error messages

**Anti-Pattern (DON'T DO THIS):**
```swift
ScrollView {
    VStack {
        // Other content...
        
        SomeComponent()  // Contains GeometryReader internally!
    }
}

// Inside SomeComponent:
struct SomeComponent: View {
    var body: some View {
        GeometryReader { geometry in  // ❌ BLOCKS SCROLLING!
            LazyVGrid(columns: ...) {
                // content
            }
        }
    }
}
```

**Correct Pattern:**
```swift
ScrollView {
    VStack {
        // Other content...
        
        SomeComponent()  // NO GeometryReader inside
    }
}

// Inside SomeComponent:
struct SomeComponent: View {
    var body: some View {
        LazyVGrid(columns: columns) {  // ✅ No GeometryReader wrapper
            // content
        }
    }
    
    private var columns: [GridItem] {
        // Use adaptive or flexible GridItems instead
        [GridItem(.adaptive(minimum: 160, maximum: 250))]
    }
}
```

**Key Insight:** The parent view (with GeometryReader at the top level) should pass `windowSize` down to child components. Child components should NOT have their own GeometryReader.

**Reference:** Budget Builder's `BudgetItemsTableView` uses `LazyVStack` without GeometryReader - scrolling works perfectly.

---

### Modal Sizing Pattern
```swift
// From GuestDetailViewV4.swift
private let minWidth: CGFloat = 400
private let maxWidth: CGFloat = 700
private let minHeight: CGFloat = 350
private let maxHeight: CGFloat = 850
private let windowChromeBuffer: CGFloat = 40

private var dynamicSize: CGSize {
    let parentSize = coordinator.parentWindowSize
    let targetWidth = min(maxWidth, max(minWidth, parentSize.width * 0.6))
    let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.75 - windowChromeBuffer))
    return CGSize(width: targetWidth, height: targetHeight)
}
```

### Stats Card Pattern (SummaryCardView)
- Icon: 44x44 circle, 20pt icon
- Title: 11pt uppercase with tracking
- Value: 28pt bold rounded
- Padding: `Spacing.xl`
- Hover effects with scale and shadow

---

## Files to Modify

1. `ExpenseTrackerAddView.swift` - Dynamic modal sizing
2. `ExpenseTrackerEditView.swift` - Dynamic modal sizing
3. `ExpenseTrackerUnifiedHeader.swift` - Stats card sizing
4. `ExpenseTrackerView.swift` - Parent-only benchmarks, static header structure

---

**Next Step:** Create LLM Council prompt, then implement phases 2-4 while waiting for Council input
