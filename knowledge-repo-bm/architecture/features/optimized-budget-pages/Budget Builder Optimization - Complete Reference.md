---
title: Optimized Budget Pages
type: note
permalink: architecture/features/optimized-budget-pages
tags:
- budget
- budget-builder
- budget-development
- compact-window
- responsive-design
- swiftui
- implementation-complete
- source-of-truth
---

# Optimized Budget Pages

## Overview

This document is the **source of truth** for the Budget module's responsive design implementation, specifically the Budget Builder (Budget Development) page. It consolidates implementation progress, architectural decisions, and remaining work for all 12 budget pages.

**Status:** Budget Builder page is **COMPLETE** with unified header and compact card view  
**Last Updated:** Current session  
**Related Epic:** `I Do Blueprint-0f4` (Budget Compact Views Optimization)

---

## Quick Reference

### Budget Module Navigation Structure

| Page | Enum Case | View File | Status |
|------|-----------|-----------|--------|
| **Dashboard** | `.hub` | `BudgetDashboardHubView.swift` | ✅ Complete |
| **Budget Overview** | `.budgetOverview` | `BudgetOverviewDashboardViewV2.swift` | 🔲 Pending |
| **Budget Builder** | `.budgetBuilder` | `BudgetDevelopmentView.swift` | ✅ Complete |
| Analytics Hub | `.analytics` | `BudgetAnalyticsView.swift` | ���� Pending |
| Cash Flow | `.cashFlow` | `BudgetCashFlowView.swift` | 🔲 Pending |
| Calculator | `.calculator` | `BudgetCalculatorView.swift` | 🔲 Pending |
| Expense Tracker | `.expenseTracker` | `ExpenseTrackerView.swift` | 🔲 Pending |
| Expense Reports | `.expenseReports` | `ExpenseReportsView.swift` | 🔲 Pending |
| Expense Categories | `.expenseCategories` | `ExpenseCategoriesView.swift` | 🔲 Pending |
| Payment Schedule | `.paymentSchedule` | `PaymentScheduleView.swift` | 🔲 Pending |
| Money Tracker | `.moneyTracker` | `GiftsAndOwedView.swift` | 🔲 Pending |
| Money Received | `.moneyReceived` | `MoneyReceivedViewV2.swift` | 🔲 Pending |
| Money Owed | `.moneyOwed` | `MoneyOwedView.swift` | 🔲 Pending |

### Window Size Breakpoints

```swift
// From Design/WindowSize.swift
enum WindowSize {
    case compact   // < 700px
    case regular   // 700-1000px  
    case large     // > 1000px
    case expanded  // > 1200px
}
```

---

## Budget Builder Page (Complete)

### Architecture

```
BudgetDevelopmentView
├── BudgetDevelopmentUnifiedHeader (NEW - combines two headers)
│   ├── Title Row: "Budget" + "Budget Development" subtitle
│   ├── Actions: Ellipsis menu (⋯) + Navigation dropdown
│   └── Form Fields: Scenario picker + Tax rate picker
├── ScrollView
���   ├── BudgetSummaryCardsSection (3 summary cards)
│   ├── BudgetItemsTable (switches based on windowSize)
│   │   ├── Compact: BudgetItemsCardView (card-based editor)
│   │   └── Regular/Large: BudgetItemsTableView (10-column table)
│   └── BudgetSummaryBreakdowns (tabbed in compact, 3-column in regular)
└── Sheet modals (TaxRate, Rename, Duplicate, Delete dialogs)
```

### Key Components

#### BudgetDevelopmentUnifiedHeader
**File:** `Views/Budget/Components/BudgetDevelopmentUnifiedHeader.swift`

Consolidates two separate headers into one:
- **Before:** `BudgetManagementHeader` (title + nav) + `BudgetConfigurationHeader` (subtitle + actions)
- **After:** Single unified header with all elements

**Layout:**
```
┌─────────────────────────────────────────────────────────┐
│ Budget                                    (⋯) [▼ Nav]   │
│ Budget Development                                      │
├─────────────────────────────────────────────────────────┤
│ Budget Scenario: [Picker ▼] (⋯)                         │
│ Default Tax Rate: [Picker ▼] [Add]                      │
└─────────────────────────────────────────────────────────┘
```

**Ellipsis Menu Contains:**
- Save scenario
- Upload scenario
- Export submenu (JSON, CSV, Google Drive, Google Sheets)

#### BudgetItemsCardView
**File:** `Views/Budget/Components/BudgetItemsCardView.swift`

Card-based editor for compact mode (replaces 10-column table):

**Features:**
- View mode toggle: "By Category" / "By Folder"
- Collapsible category sections
- Expandable item cards for editing
- All fields editable: name, category, subcategory, events, estimate, tax rate, responsible, notes
- Dynamic total calculation: `estimate × (1 + taxRate/100)`

**Card Layout (Collapsed):**
```
┌─────────────────────────────────────────┐
│ 📄 Item Name                    $X,XXX  │
│    Category • Subcategory       incl.tax│
└─────────────────────────────────────────┘
```

**Card Layout (Expanded):**
```
┌─────────────────────────────────────────┐
│ Item Name: [TextField]                  │
│ Category: [Picker]  Subcategory: [Picker]│
│ Events: [Multi-select popover]          │
│ Estimate: [Field]   Tax: [Picker]       │
│ Responsible: [Picker]                   │
│ Notes: [TextField]                      │
│ [Cancel]                    [Save]      │
└─────────────────────────────────────────┘
```

#### BudgetSummaryCardsSection
**File:** `Views/Budget/Components/BudgetSummaryCardsSection.swift`

**Compact Mode:** Horizontal compact cards using `LazyVGrid` with adaptive columns (min 140px)
**Regular Mode:** Full-size horizontal cards

#### BudgetSummaryBreakdowns
**File:** `Views/Budget/Components/BudgetSummaryBreakdowns.swift`

**Compact Mode:** Tabbed interface (Events / Categories / Responsibility)
**Regular Mode:** 3-column horizontal layout

### Implementation Details

#### Dual Initializer Pattern
`BudgetDevelopmentView` supports two usage modes:

```swift
// With external binding (from BudgetDashboardHubView)
init(currentPage: Binding<BudgetPage>) {
    self.externalCurrentPage = currentPage
}

// Standalone (from BudgetPage.view)
init() {
    self.externalCurrentPage = nil
}
```

This allows the unified header's navigation dropdown to work when embedded in the hub, while still supporting standalone usage.

#### Tax Rate Storage Format
**Critical:** Two different storage formats exist:
- `TaxInfo.taxRate`: Stored as **decimal** (e.g., `0.1035` for 10.35%)
- `BudgetItem.taxRate`: Stored as **percentage** (e.g., `10.35` for 10.35%)

When updating tax rate, convert: `selectedRate.taxRate * 100`

#### Event Display
Events are stored as UUID arrays (`eventIds: [String]`). To display names:
```swift
let eventNames = budgetStore.weddingEvents
    .filter { eventIds.contains($0.id) }
    .map(\.eventName)
    .joined(separator: ", ")
```

---

## Completed Work Log

### Session Commits

| Commit | Description |
|--------|-------------|
| `2e7fd12` | Fixed nested ScrollView hierarchy |
| `67d4c64` | Created BudgetItemsCardView component |
| `1cd1b62` | Compact summary cards with adaptive grid |
| `aba6ed8` | View mode toggle, editable fields, event display |
| `4b11bab` | Tax rate display fix, Grid layout alignment |
| `d3f16a0` | Tax rate picker ID-based selection |
| `c12534a` | Dynamic total calculation, editable events |
| `d8a5d35` | Fixed total not updating on tax rate change |
| `8408a99` | Unified header for Budget Development |
| `8197876` | Removed duplicate buttons, improved spacing |

### Key Fixes Applied

1. **Tax Rate Display:** Changed from value-based to ID-based picker selection
2. **Total Calculation:** Uses `item.vendorEstimateWithTax` (parent recalculates on change)
3. **Event Names:** Resolved UUIDs to names via `weddingEvents` lookup
4. **Header Consolidation:** Merged two headers into unified component
5. **Form Spacing:** Increased from `Spacing.md` to `Spacing.lg` for less cramped appearance

---

## Remaining Work

### Phase 1: High-Traffic Pages (P0)

| Issue ID | Page | Estimated Hours |
|----------|------|-----------------|
| `I Do Blueprint-yhc` | ExpenseTrackerView | 2-3 |
| `I Do Blueprint-dra` | BudgetOverviewDashboardViewV2 | 3-4 |
| `I Do Blueprint-dy9` | PaymentScheduleView | 2-3 |

### Phase 2: Secondary Pages (P1)

| Issue ID | Page | Estimated Hours |
|----------|------|-----------------|
| `I Do Blueprint-08q` | GiftsAndOwedView | 2 |
| `I Do Blueprint-qwd` | ExpenseReportsView | 2-3 |
| `I Do Blueprint-66o` | BudgetAnalyticsView | 3 |

### Phase 3: Tertiary Pages (P2)

| Issue ID | Page | Estimated Hours |
|----------|------|-----------------|
| `I Do Blueprint-989` | MoneyReceivedViewV2 | 1-2 |
| `I Do Blueprint-2s4` | MoneyOwedView | 1-2 |
| `I Do Blueprint-bs4` | ExpenseCategoriesView | 1-2 |

### Phase 4: Utility Pages (P3)

| Issue ID | Page | Estimated Hours |
|----------|------|-----------------|
| `I Do Blueprint-8vy` | BudgetCashFlowView | 2 |
| `I Do Blueprint-bre` | BudgetCalculatorView | 1-2 |

**Total Estimated:** 22-30 hours

---

## Implementation Pattern

For remaining pages, follow this standard pattern:

```swift
struct BudgetPageView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.huge
            let availableWidth = geometry.size.width - (horizontalPadding * 2)
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Page content adapts based on windowSize
                    if windowSize == .compact {
                        compactLayout
                    } else {
                        regularLayout
                    }
                }
                .frame(width: availableWidth)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)
            }
        }
    }
}
```

### Adaptation Guidelines

| Element | Compact | Regular/Large |
|---------|---------|---------------|
| Horizontal Padding | `Spacing.lg` (16px) | `Spacing.huge` (32px) |
| Stats Grid | 1-2 columns | 3-4 columns |
| Card Grid | 1 column | 2-3 columns |
| Filter Bar | Collapsed menu | Inline |
| Table View | Card fallback | Full table |
| Actions | Ellipsis menu | Inline buttons |

---

## File Reference

### Core Files

| File | Purpose |
|------|---------|
| `Domain/Models/Budget/BudgetPage.swift` | Navigation enum with 12 pages + 3 groups |
| `Views/Budget/BudgetDashboardHubView.swift` | Central hub with navigation |
| `Views/Budget/BudgetDevelopmentView.swift` | Budget Builder main view |
| `Views/Budget/Components/BudgetDevelopmentUnifiedHeader.swift` | Unified header component |
| `Views/Budget/Components/BudgetItemsCardView.swift` | Compact card-based editor |
| `Views/Budget/Components/BudgetItemsTable.swift` | Table/card switcher |
| `Views/Budget/Components/BudgetManagementHeader.swift` | Standard header for other pages |

### Supporting Components

| File | Purpose |
|------|---------|
| `BudgetConfigurationHeader.swift` | Legacy header (still used for form fields) |
| `BudgetSummaryCardsSection.swift` | Summary cards (responsive) |
| `BudgetSummaryBreakdowns.swift` | Breakdown sections (tabbed/columns) |
| `BudgetItemsTableView.swift` | 10-column table for regular mode |
| `BudgetItemRow.swift` | Table row component |
| `EventMultiSelectorPopover.swift` | Event multi-select UI |

---

## Testing Checklist

### Budget Builder Page ✅

- [x] Test at 640px width (compact)
- [x] Test at 700px width (breakpoint)
- [x] Test at 900px width (regular)
- [x] Test at 1200px width (large)
- [x] Verify header actions in ellipsis menu
- [x] Verify scenario selector works
- [x] Verify tax rate picker displays correctly
- [x] Verify card-based editor displays items
- [x] Verify item editing works in card mode
- [x] Verify view mode toggle (Category/Folder)
- [x] Verify add item/folder works
- [x] Verify delete item works
- [x] Verify summary breakdowns tabs work
- [x] Verify all modals work
- [x] Verify save/upload functionality
- [x] Verify export functionality

### Remaining Pages

Use same checklist for each page as implemented.

---

## Related Documentation

- [[SwiftUI LazyVGrid Adaptive Card Grid Pattern]] - Grid pattern used for cards
- [[Management View Header Alignment Pattern]] - Header standardization
- [[Budget Store Architecture]] - BudgetStoreV2 and sub-stores
- [[Responsive Design Guidelines]] - WindowSize breakpoints

## Related Issues

- Epic: `I Do Blueprint-0f4` - Budget Compact Views Optimization
- Closed: `I Do Blueprint-b1x` - Integrate Budget Builder into Navigation
- Closed: `I Do Blueprint-v3t` - Budget Main View Sidebar Collapse
