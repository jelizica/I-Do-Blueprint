# Budget Module Optimization Plan

## Date
2026-01-01

## Executive Summary

This document outlines a comprehensive plan to address two major UX issues in the Budget module:

1. **Budget Navigation Redesign** - Eliminate the "double nav" pattern that creates visual clutter
2. **Budget Pages Compact View Optimization** - Apply the successful compact window patterns from Guest and Vendor management

---

# Part 1: Budget Navigation Redesign

## Current State Analysis

### Current Architecture
```
┌─────────────────────────────────────────────────────────────────────┐
│ Main App Sidebar │ Budget Sub-Sidebar │      Content Area          │
│   (260px)        │     (240px)        │                            │
│                  │                    │                            │
│ • Dashboard      │ ▼ Overview         │   Budget Dashboard View    │
│ • Guests         │   • Dashboard      │                            │
│ • Vendors        │   • Analytics      │                            │
│ • Timeline       │   • Cash Flow      │                            │
│ • Team           │   • Development    │                            │
│ • Budget ◄───────│   • Calculator     │                            │
│ • Visual Plan    │ ▼ Expenses         │                            │
│ • Notes          │   • Tracker        │                            │
│ • Documents      │   • Reports        │                            │
│ • Settings       │   • Categories     │                            │
│                  │ ▼ Payments         │                            │
│                  │   • Schedule       │                            │
│                  │ ▼ Gifts & Owed     │                            │
│                  │   • Money Tracker  │                            │
│                  │   • Received       │                            │
│                  │   • Owed           │                            │
└─────────────────────────────────────────────────────────────────────┘
```

### Problems Identified
1. **Double navigation consumes ~500px** - Nearly half of a 1024px window
2. **Inconsistent with other modules** - Guests, Vendors, Timeline don't have sub-sidebars
3. **Always visible** - Budget sidebar shown even when user is focused on content
4. **Poor compact window support** - At <700px, the double nav is unusable
5. **Cognitive overload** - 12 items across 4 groups is overwhelming

### Current Implementation Files
- `I Do Blueprint/Views/Budget/BudgetMainView.swift` - HStack with sidebar + content
- `I Do Blueprint/Views/Budget/BudgetSidebarView.swift` - 240px fixed sidebar
- `I Do Blueprint/Views/Shared/Navigation/AppSidebarView.swift` - Main app sidebar

---

## Proposed Solutions

### Option A: Segmented Control + Tab Bar (RECOMMENDED)

**Description:**
Replace the budget sub-sidebar with a horizontal segmented control at the top of the budget content area. Group the 12 views into 4 logical tabs, with each tab showing its sub-items in a secondary row or dropdown.

**Visual Layout:**
```
┌─────────────────────────────────────────────────────────────────────┐
│ Main Sidebar │              Budget Content Area                     │
│   (260px)    │                                                      │
│              │ ┌──────────────────────────────────────────────────┐ │
│ • Dashboard  │ │ [Overview ▼] [Expenses ▼] [Payments] [Gifts ▼]  │ │
│ • Guests     │ └──────────────────────────────────────────────────┘ │
│ • Vendors    │ ┌──────────────────────────────────────────────────┐ │
│ • Timeline   │ │ Dashboard │ Analytics │ Cash Flow │ Dev │ Calc  │ │
│ • Team       │ └──────────────────────────────────────────────────┘ │
│ • Budget ◄───│                                                      │
│ • Visual     │              [Budget Dashboard Content]              │
│ • Notes      │                                                      │
│ • Documents  │                                                      │
│ • Settings   │                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Implementation:**
```swift
struct BudgetMainViewV2: View {
    @State private var selectedGroup: BudgetGroup = .overview
    @State private var selectedItem: BudgetNavigationItem = .budgetDashboard
    
    var body: some View {
        VStack(spacing: 0) {
            // Primary segmented control for groups
            BudgetGroupSelector(selectedGroup: $selectedGroup)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
            
            // Secondary tab bar for items within group
            BudgetItemTabBar(
                group: selectedGroup,
                selectedItem: $selectedItem
            )
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            
            Divider()
            
            // Content area
            selectedItem.view
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
```

**Pros:**
- ✅ Eliminates 240px sidebar, reclaims horizontal space
- ✅ Consistent with macOS System Preferences pattern
- ✅ Works well at all window sizes
- ✅ Maintains discoverability of all 12 views
- ✅ Familiar pattern for macOS users
- ✅ Groups provide logical organization

**Cons:**
- ⚠️ Two rows of navigation (group + items) still visible
- ⚠️ Medium implementation complexity
- ⚠️ Requires state management for group/item selection

**Implementation Complexity:** Medium

**Recommended:** ✅ YES - Best balance of space efficiency and discoverability

---

### Option B: Toolbar Menu + Breadcrumb

**Description:**
Use a toolbar-based navigation with a dropdown menu for view selection. Show current location via breadcrumb. Similar to Finder's path bar.

**Visual Layout:**
```
┌─────────────────────────────────────────────────────────────────────┐
│ Main Sidebar │              Budget Content Area                     │
│   (260px)    │                                                      │
│              │ ┌──────────────────────────────────────────────────┐ │
│ • Dashboard  │ │ Budget > Overview > Dashboard    [≡ Views ▼]    ��� │
│ • Guests     │ └──────────────────────────────────────────────────┘ │
│ • Vendors    │                                                      │
│ • Timeline   │              [Budget Dashboard Content]              │
│ • Team       │                                                      │
│ • Budget ◄───│                                                      │
│ • Visual     │                                                      │
│ • Notes      │                                                      │
│ • Documents  │                                                      │
│ • Settings   │                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Implementation:**
```swift
struct BudgetMainViewV2: View {
    @State private var selectedItem: BudgetNavigationItem = .budgetDashboard
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar with breadcrumb and menu
            HStack {
                // Breadcrumb
                BudgetBreadcrumb(item: selectedItem)
                
                Spacer()
                
                // Views menu
                Menu {
                    ForEach(BudgetGroup.allCases, id: \.self) { group in
                        Section(group.rawValue) {
                            ForEach(group.items) { item in
                                Button(item.title) {
                                    selectedItem = item
                                }
                            }
                        }
                    }
                } label: {
                    Label("Views", systemImage: "list.bullet")
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            
            Divider()
            
            // Content
            selectedItem.view
        }
    }
}
```

**Pros:**
- ✅ Maximum content space (only one toolbar row)
- ✅ Clean, minimal interface
- ✅ Follows Finder/Safari patterns

**Cons:**
- ⚠️ All 12 views hidden in menu - reduced discoverability
- ⚠️ Extra click required to switch views
- ⚠️ Users may not discover all available views

**Implementation Complexity:** Low

**Recommended:** ❌ NO - Too much hidden, poor discoverability for 12 views

---

### Option C: Collapsible Sidebar (Inspector Pattern)

**Description:**
Keep the budget sidebar but make it collapsible/toggleable. When collapsed, show only icons. Similar to Xcode's navigator.

**Visual Layout (Expanded):**
```
┌─────────────────────────────────────────────────────────────────────┐
│ Main Sidebar │ Budget Nav │         Content Area                   │
│   (260px)    │  (200px)   │                                        │
│              │            │                                        │
│ • Dashboard  │ ▼ Overview │        [Budget Dashboard]              │
│ • Guests     │   Dashboard│                                        │
│ • Vendors    │   Analytics│                                        │
│ • Budget ◄───│   ...      │                                        │
└─────────────────────────────────────────────────────────────────────┘
```

**Visual Layout (Collapsed):**
```
┌─────────────���───────────────────────────────────────────────────────┐
│ Main Sidebar │ │              Content Area                         │
│   (260px)    │44│                                                   │
│              │px│                                                   │
│ • Dashboard  │📊│           [Budget Dashboard]                      │
│ • Guests     │📈│                                                   │
│ • Vendors    │💰│                                                   │
│ • Budget ◄───│📅│                                                   │
└─────────────────────────────────────────────────────────────────────┘
```

**Pros:**
- ✅ User controls when sidebar is visible
- ✅ Familiar Xcode/IDE pattern
- ✅ Icons provide quick access when collapsed

**Cons:**
- ⚠️ Still double navigation when expanded
- ⚠️ Icons alone may not be clear for 12 views
- ⚠️ Adds complexity (toggle state, animations)
- ⚠️ Inconsistent with other modules

**Implementation Complexity:** Medium-High

**Recommended:** ❌ NO - Doesn't solve the core problem, adds complexity

---

### Option D: Flat List in Main Sidebar (Expand Budget Section)

**Description:**
Eliminate the budget sub-sidebar entirely. Instead, expand the Budget section in the main app sidebar to show all 12 items directly, organized into collapsible groups.

**Visual Layout:**
```
┌─────────────────────────────────────────────────────────────────────┐
│     Main Sidebar (260px)     │         Content Area                │
│                              │                                      │
│ • Dashboard                  │                                      │
│ • Guests                     │                                      │
│ • Vendors                    │                                      │
│ • Timeline                   │                                      │
│ • Team                       │                                      │
│ ▼ Budget                     │        [Budget Dashboard]            │
│   ▼ Overview                 │                                      │
│     • Dashboard              │                                      │
│     • Analytics              │                                      │
│     • Cash Flow              │                                      │
│     • Development            │                                      │
│     • Calculator             │                                      │
│   ▶ Expenses (3)             │                                      │
│   ▶ Payments (1)             │                                      │
│   ▶ Gifts & Owed (3)         │                                      │
│ • Visual Planning            │                                      │
│ • Notes                      │                                      │
│ • Documents                  │                                      │
│ • Settings                   │                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Pros:**
- ✅ Single sidebar - consistent with other modules
- ✅ All views accessible from one place
- ✅ Collapsible groups reduce visual noise
- ✅ Low implementation complexity

**Cons:**
- ⚠️ Main sidebar becomes very long when Budget expanded
- ⚠️ May require scrolling in main sidebar
- ⚠️ 12 items is a lot for one section
- ⚠️ Sidebar width may need to increase

**Implementation Complexity:** Low

**Recommended:** ⚠️ MAYBE - Simple but may make sidebar too long

---

### Option E: Dashboard Hub with Quick Actions (ALTERNATIVE RECOMMENDATION)

**Description:**
Make the Budget Dashboard the primary view with prominent cards/tiles linking to all other budget views. Remove the sub-sidebar entirely. Users navigate from dashboard to specific views and back.

**Visual Layout:**
```
┌─────────────────────────────────────────────────────────────────────┐
│ Main Sidebar │              Budget Dashboard                        │
│   (260px)    │                                                      │
│              │ ┌─────────────────────────────────────────────────┐  │
│ • Dashboard  │ │  Summary Stats: $88,774 Budget | $85,240 Spent  │  │
│ • Guests     │ └─────────────────────────────────────────────────┘  │
│ • Vendors    │                                                      │
│ • Timeline   │ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│ • Team       │ │ Expense  │ │ Payment  │ │ Analytics│ │ Cash     │ │
│ • Budget ◄───│ │ Tracker  │ │ Schedule │ │ Hub      │ │ Flow     │ │
│ • Visual     │ │ 46 items │ │ 12 due   │ │ Charts   │ │ Timeline │ │
│ • Notes      │ └──────────┘ └──────────┘ └──────────┘ └──────────┘ │
│ • Documents  │                                                      │
│ • Settings   │ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│              │ │ Budget   │ │ Expense  │ │ Money    │ │ Money    │ │
│              │ │ Dev      │ │ Reports  │ │ Tracker  │ │ Received │ │
│              │ └──────────┘ └──────────┘ └──────────┘ └──────────┘ │
│              │                                                      │
│              │ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │
│              │ │ Expense  │ │ Money    │ │Calculator│ │ More...  │ │
│              │ │ Category │ │ Owed     │ │          │ │          │ │
│              │ └──────────┘ └──────────┘ └──────────┘ └──────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

**Implementation:**
```swift
struct BudgetDashboardHubView: View {
    @State private var selectedView: BudgetNavigationItem?
    
    var body: some View {
        if let selected = selectedView {
            // Show selected view with back button
            VStack(spacing: 0) {
                HStack {
                    Button {
                        selectedView = nil
                    } label: {
                        Label("Budget", systemImage: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    
                    Text(selected.title)
                        .font(.headline)
                    
                    Spacer()
                }
                .padding()
                
                Divider()
                
                selected.view
            }
        } else {
            // Show dashboard hub
            BudgetDashboardHub(onSelectView: { selectedView = $0 })
        }
    }
}
```

**Pros:**
- ✅ Maximum content space
- ✅ Dashboard provides overview + navigation
- ✅ Cards can show live data (counts, amounts)
- ✅ Very discoverable - all options visible
- ✅ Works great at all window sizes

**Cons:**
- ⚠️ Extra click to reach specific views
- ⚠️ No persistent navigation while in sub-view
- ⚠️ Back button pattern less common on macOS
- ⚠️ Higher implementation complexity

**Implementation Complexity:** Medium-High

**Recommended:** ⚠️ ALTERNATIVE - Great for discoverability but changes navigation paradigm

---

## Recommendation Summary

| Option | Space Efficiency | Discoverability | Consistency | Complexity | Recommended |
|--------|-----------------|-----------------|-------------|------------|-------------|
| A: Segmented Control | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Medium | ✅ **YES** |
| B: Toolbar Menu | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | Low | ❌ No |
| C: Collapsible Sidebar | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | Medium-High | ❌ No |
| D: Flat List | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Low | ⚠️ Maybe |
| E: Dashboard Hub | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Medium-High | ⚠️ Alternative |

### Primary Recommendation: Option A (Segmented Control + Tab Bar)

**Rationale:**
1. Best balance of space efficiency and discoverability
2. Follows established macOS patterns (System Preferences, App Store)
3. Groups provide logical organization without hiding content
4. Works well at all window sizes including compact (<700px)
5. Medium complexity is manageable

### Alternative Recommendation: Option E (Dashboard Hub)

**Consider if:**
- Users primarily work from the dashboard
- Live data in navigation cards adds value
- Team prefers a more "app-like" navigation paradigm

---

## Implementation Plan for Option A

### Phase 1: Create New Navigation Components

**Files to Create:**
1. `BudgetGroupSelector.swift` - Segmented control for 4 groups
2. `BudgetItemTabBar.swift` - Tab bar for items within selected group
3. `BudgetMainViewV2.swift` - New main view with horizontal navigation

**BudgetGroupSelector.swift:**
```swift
struct BudgetGroupSelector: View {
    @Binding var selectedGroup: BudgetGroup
    let windowSize: WindowSize
    
    var body: some View {
        if windowSize == .compact {
            // Compact: Use picker/menu
            Menu {
                ForEach(BudgetGroup.allCases, id: \.self) { group in
                    Button {
                        selectedGroup = group
                    } label: {
                        Label(group.rawValue, systemImage: group.icon)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedGroup.icon)
                    Text(selectedGroup.rawValue)
                    Image(systemName: "chevron.down")
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(AppColors.cardBackground)
                .cornerRadius(CornerRadius.md)
            }
        } else {
            // Regular/Large: Segmented control
            HStack(spacing: Spacing.sm) {
                ForEach(BudgetGroup.allCases, id: \.self) { group in
                    Button {
                        selectedGroup = group
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: group.icon)
                                .font(.system(size: 14))
                            Text(group.rawValue)
                                .font(Typography.bodySmall)
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            selectedGroup == group 
                                ? AppColors.primary 
                                : AppColors.cardBackground
                        )
                        .foregroundColor(
                            selectedGroup == group 
                                ? .white 
                                : AppColors.textPrimary
                        )
                        .cornerRadius(CornerRadius.md)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
```

**BudgetItemTabBar.swift:**
```swift
struct BudgetItemTabBar: View {
    let group: BudgetGroup
    @Binding var selectedItem: BudgetNavigationItem
    let windowSize: WindowSize
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: windowSize == .compact ? Spacing.xs : Spacing.sm) {
                ForEach(group.items) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: item.icon)
                                .font(.system(size: 12))
                            if windowSize != .compact {
                                Text(item.title)
                                    .font(Typography.caption)
                            }
                        }
                        .padding(.horizontal, windowSize == .compact ? Spacing.sm : Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            selectedItem == item
                                ? AppColors.primary.opacity(0.15)
                                : Color.clear
                        )
                        .foregroundColor(
                            selectedItem == item
                                ? AppColors.primary
                                : AppColors.textSecondary
                        )
                        .cornerRadius(CornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
```

### Phase 2: Update BudgetMainView

**BudgetMainViewV2.swift:**
```swift
struct BudgetMainViewV2: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @State private var selectedGroup: BudgetGroup = .overview
    @State private var selectedItem: BudgetNavigationItem = .budgetDashboard
    
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl
            
            VStack(spacing: 0) {
                // Navigation header
                VStack(spacing: Spacing.sm) {
                    // Group selector
                    BudgetGroupSelector(
                        selectedGroup: $selectedGroup,
                        windowSize: windowSize
                    )
                    
                    // Item tab bar
                    BudgetItemTabBar(
                        group: selectedGroup,
                        selectedItem: $selectedItem,
                        windowSize: windowSize
                    )
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, Spacing.md)
                .background(AppColors.cardBackground.opacity(0.5))
                
                Divider()
                
                // Content area
                selectedItem.view
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .environmentObject(budgetStore)
        .onChange(of: selectedGroup) { _, newGroup in
            // Auto-select first item in new group
            selectedItem = newGroup.defaultItem
        }
        .onAppear {
            Task {
                await budgetStore.loadBudgetData(force: true)
            }
        }
    }
}
```

### Phase 3: Update AppCoordinator

Update `AppCoordinator.swift` to use the new `BudgetMainViewV2`:

```swift
extension AppCoordinator.AppTab {
    @ViewBuilder
    var view: some View {
        switch self {
        case .budget:
            BudgetMainViewV2()  // Changed from BudgetMainView
        // ... other cases
        }
    }
}
```

### Phase 4: Remove Old Sidebar

1. Archive `BudgetSidebarView.swift` (don't delete yet)
2. Archive `BudgetMainView.swift` (don't delete yet)
3. Update any references to use new components

### Phase 5: Testing

1. Test at all window sizes (640px, 700px, 900px, 1200px)
2. Verify all 12 views are accessible
3. Test keyboard navigation
4. Test VoiceOver accessibility
5. Verify state persistence across navigation

---

# Part 2: Budget Pages Compact View Optimization

## Current State Analysis

### Existing Compact View Patterns (from Guest/Vendor)

Based on the successful implementations in `GuestManagementViewV4` and `VendorManagementViewV3`:

1. **GeometryReader wrapper** - Detect window size
2. **WindowSize enum** - compact (<700px), regular (700-1000px), large (>1000px)
3. **Responsive padding** - `Spacing.lg` compact, `Spacing.huge` regular/large
4. **Available width calculation** - `geometry.size.width - (padding * 2)`
5. **Adaptive grids** - `.adaptive(minimum:)` for flexible columns
6. **Compact card variants** - Smaller cards with essential info only
7. **Collapsible filters** - Menu-based filters in compact mode

### Budget Pages Requiring Optimization

| Page | Current State | Priority | Complexity |
|------|---------------|----------|------------|
| BudgetOverviewDashboardViewV2 | No WindowSize | P1 | Medium |
| ExpenseTrackerView | No WindowSize | P1 | Medium |
| ExpenseReportsView | No WindowSize | P2 | Medium |
| ExpenseCategoriesView | No WindowSize | P2 | Low |
| PaymentScheduleView | No WindowSize | P1 | Medium |
| BudgetAnalyticsView | No WindowSize | P2 | High |
| BudgetCashFlowView | No WindowSize | P2 | Medium |
| BudgetDevelopmentView | No WindowSize | P3 | High |
| BudgetCalculatorView | No WindowSize | P3 | Medium |
| GiftsAndOwedView | No WindowSize | P2 | Medium |
| MoneyReceivedViewV2 | No WindowSize | P2 | Low |
| MoneyOwedView | No WindowSize | P2 | Low |

---

## Implementation Pattern

### Standard Compact View Template

Apply this pattern to each budget page:

```swift
struct BudgetPageTemplate: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    // State variables...
    
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.huge
            let availableWidth = geometry.size.width - (horizontalPadding * 2)
            
            ZStack {
                AppGradients.appBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header (responsive)
                    PageHeader(windowSize: windowSize, ...)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)
                        .padding(.bottom, Spacing.lg)
                    
                    // Scrollable content
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Stats section (responsive)
                            StatsSection(windowSize: windowSize, ...)
                            
                            // Filters section (responsive)
                            FiltersSection(windowSize: windowSize, ...)
                            
                            // Content grid (responsive)
                            ContentGrid(windowSize: windowSize, ...)
                        }
                        .frame(width: availableWidth)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, windowSize == .compact ? Spacing.lg : Spacing.huge)
                    }
                }
            }
        }
    }
}
```

---

## Page-Specific Implementation Plans

### 1. BudgetOverviewDashboardViewV2 (P1)

**Current Issues:**
- Fixed padding values
- Summary cards don't adapt
- Budget items grid doesn't respond to window size

**Changes Required:**

1. **Add GeometryReader wrapper**
2. **Update BudgetOverviewSummaryCards:**
   - Compact: 2-2 grid (4 cards in 2 rows)
   - Regular/Large: 4 cards in single row

3. **Update BudgetOverviewItemsSection:**
   - Compact: 1-2 columns for budget item cards
   - Regular: 2-3 columns
   - Large: 3-4 columns

4. **Update BudgetOverviewHeader:**
   - Compact: Stack scenario selector and filters vertically
   - Compact: Use menu for view mode toggle

**Implementation:**
```swift
// BudgetOverviewSummaryCards.swift
struct BudgetOverviewSummaryCards: View {
    let windowSize: WindowSize
    let totalBudget: Double
    let totalExpenses: Double
    let totalRemaining: Double
    let itemCount: Int
    
    var body: some View {
        if windowSize == .compact {
            // 2-2 grid
            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    SummaryCard(title: "Total Budget", value: totalBudget, ...)
                    SummaryCard(title: "Total Expenses", value: totalExpenses, ...)
                }
                HStack(spacing: Spacing.md) {
                    SummaryCard(title: "Remaining", value: totalRemaining, ...)
                    SummaryCard(title: "Budget Items", value: Double(itemCount), ...)
                }
            }
        } else {
            // Single row
            HStack(spacing: Spacing.lg) {
                SummaryCard(title: "Total Budget", value: totalBudget, ...)
                SummaryCard(title: "Total Expenses", value: totalExpenses, ...)
                SummaryCard(title: "Remaining", value: totalRemaining, ...)
                SummaryCard(title: "Budget Items", value: Double(itemCount), ...)
            }
        }
    }
}
```

### 2. ExpenseTrackerView (P1)

**Current Issues:**
- Fixed 20px spacing
- No responsive header
- Card/table view doesn't adapt

**Changes Required:**

1. **Add GeometryReader wrapper**
2. **Update ExpenseTrackerHeader:**
   - Compact: Stack stats vertically (2-2 grid)
   - Compact: Combine Import/Export into menu

3. **Update ExpenseFiltersBar:**
   - Compact: Full-width search
   - Compact: Filter menus instead of toggles

4. **Update ExpenseListView:**
   - Compact: Force card view (no table)
   - Compact: 1-2 columns for cards

### 3. PaymentScheduleView (P1)

**Current Issues:**
- Complex timeline visualization
- Fixed column widths

**Changes Required:**

1. **Add GeometryReader wrapper**
2. **Compact mode:**
   - Simplified timeline (list instead of calendar)
   - Collapsible payment groups
   - Essential info only in cards

### 4. ExpenseReportsView (P2)

**Changes Required:**
- Responsive chart sizing
- Compact: Stack tabs vertically or use segmented control
- Compact: Simplified table with fewer columns

### 5. BudgetAnalyticsView (P2)

**Changes Required:**
- Responsive chart containers
- Compact: Single chart per row
- Compact: Collapsible insight sections

### 6. GiftsAndOwedView (P2)

**Changes Required:**
- Responsive gift/owed cards
- Compact: 1-2 columns
- Compact: Essential info only

### 7-12. Remaining Pages (P3)

Apply standard pattern with page-specific adjustments.

---

## Testing Checklist

### Window Sizes to Test
- [ ] 640px (minimum compact)
- [ ] 699px (maximum compact)
- [ ] 700px (minimum regular)
- [ ] 900px (mid regular)
- [ ] 1000px (minimum large)
- [ ] 1400px (large)

### Components to Verify
- [ ] Headers adapt correctly
- [ ] Stats cards reflow
- [ ] Filters collapse to menus
- [ ] Grids adjust columns
- [ ] No horizontal overflow
- [ ] No content clipping
- [ ] Touch targets remain accessible (44pt minimum)

---

## Implementation Timeline

### Week 1: Navigation Redesign
- [ ] Day 1-2: Create BudgetGroupSelector and BudgetItemTabBar
- [ ] Day 3: Create BudgetMainViewV2
- [ ] Day 4: Update AppCoordinator, test integration
- [ ] Day 5: Polish, accessibility, edge cases

### Week 2: P1 Compact Views
- [ ] Day 1-2: BudgetOverviewDashboardViewV2
- [ ] Day 3: ExpenseTrackerView
- [ ] Day 4: PaymentScheduleView
- [ ] Day 5: Testing and fixes

### Week 3: P2 Compact Views
- [ ] Day 1: ExpenseReportsView
- [ ] Day 2: ExpenseCategoriesView
- [ ] Day 3: BudgetAnalyticsView
- [ ] Day 4: BudgetCashFlowView
- [ ] Day 5: GiftsAndOwedView, MoneyReceivedViewV2, MoneyOwedView

### Week 4: P3 Compact Views + Polish
- [ ] Day 1-2: BudgetDevelopmentView
- [ ] Day 3: BudgetCalculatorView
- [ ] Day 4-5: Final testing, documentation, cleanup

---

## Success Criteria

### Navigation Redesign
- ✅ No double sidebar
- ✅ All 12 views accessible
- ✅ Works at <700px width
- ✅ Consistent with other modules
- ✅ Keyboard navigable
- ✅ VoiceOver accessible

### Compact Views
- ✅ No horizontal overflow at any width
- ✅ Content readable at 640px
- ✅ Touch targets ≥44pt
- ✅ Smooth transitions between sizes
- ✅ No layout jank during resize

---

## Files to Create/Modify

### New Files
1. `Views/Budget/BudgetMainViewV2.swift`
2. `Views/Budget/Components/BudgetGroupSelector.swift`
3. `Views/Budget/Components/BudgetItemTabBar.swift`

### Files to Modify
1. `Views/Budget/BudgetOverviewDashboardViewV2.swift`
2. `Views/Budget/Components/BudgetOverviewSummaryCards.swift`
3. `Views/Budget/Components/BudgetOverviewHeader.swift`
4. `Views/Budget/Components/BudgetOverviewItemsSection.swift`
5. `Views/Budget/ExpenseTrackerView.swift`
6. `Views/Budget/Components/ExpenseTrackerHeader.swift`
7. `Views/Budget/Components/ExpenseFiltersBar.swift`
8. `Views/Budget/Components/ExpenseListView.swift`
9. `Views/Budget/PaymentScheduleView.swift`
10. `Views/Budget/ExpenseReportsView.swift`
11. `Views/Budget/ExpenseCategoriesView.swift`
12. `Views/Budget/BudgetAnalyticsView.swift`
13. `Views/Budget/BudgetCashFlowView.swift`
14. `Views/Budget/BudgetDevelopmentView.swift`
15. `Views/Budget/BudgetCalculatorView.swift`
16. `Views/Budget/GiftsAndOwedView.swift`
17. `Views/Budget/MoneyReceived/MoneyReceivedViewV2.swift`
18. `Views/Budget/MoneyOwedView.swift`
19. `Core/Common/Common/AppCoordinator.swift` (update tab view)

### Files to Archive (Not Delete)
1. `Views/Budget/BudgetMainView.swift`
2. `Views/Budget/BudgetSidebarView.swift`

---

## Approval Required

**This plan requires user approval before implementation begins.**

### Key Decisions for User Review

#### Navigation Redesign
1. **Approve Option A (Segmented Control + Tab Bar)?**
   - Alternative: Option E (Dashboard Hub) if preferred
2. **Group organization acceptable?**
   - Overview (5), Expenses (3), Payments (1), Gifts & Owed (3)
3. **Compact mode behavior?**
   - Group selector becomes dropdown menu
   - Item tabs show icons only

#### Compact Views
1. **Priority order acceptable?**
   - P1: Dashboard, Expense Tracker, Payment Schedule
   - P2: Reports, Categories, Analytics, Cash Flow, Gifts
   - P3: Development, Calculator
2. **Stats card layout in compact?**
   - 2-2 grid (4 cards in 2 rows)
3. **Grid column counts?**
   - Compact: 1-2 columns
   - Regular: 2-3 columns
   - Large: 3-4 columns

### Questions for User
1. Are there any budget views that should be prioritized differently?
2. Should we implement Option A or Option E for navigation?
3. Any specific compact mode behaviors you'd like to see?
4. Should we implement in phases or all at once?

---

**Status:** ��️ **AWAITING USER APPROVAL**

**Next Steps:**
1. User reviews plan
2. User approves or requests changes
3. Implementation begins after approval
4. Testing and iteration
5. Documentation and handoff
