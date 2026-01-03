# Budget Overview Dashboard - Compact View Implementation Plan

> **Status:** 🔄 REVISION 2 - Fixing Issues  
> **Created:** January 2026  
> **Epic:** `I Do Blueprint-0f4` - Budget Compact Views Optimization  
> **Priority:** P0 (High-Traffic Page)  
> **Estimated Hours:** 3-4 hours

---

## Executive Summary

This plan outlines the implementation of responsive design for the **Budget Overview Dashboard** (`BudgetOverviewDashboardViewV2.swift`), enabling it to work seamlessly in compact windows (640-700px width) on 13" MacBook Air split-screen scenarios.

### Key Deliverables

1. **Unified Header** - Consolidate title, controls, and actions into a single responsive header
2. **Responsive Summary Cards** - 2-2 grid layout for compact mode (vs 4-column in regular)
3. **Content Width Constraint** - Apply the critical fix from Guest Management to prevent edge clipping
4. **Responsive Budget Items** - Adapt card grid and table view for compact windows
5. **Collapsible Filters** - Menu-based approach for search and filters in compact mode

---

## Current State Analysis

### File Structure

```
BudgetOverviewDashboardViewV2.swift (Main View - 380 lines)
├── BudgetOverviewHeader.swift (Header - 120 lines)
├── BudgetOverviewSummaryCards.swift (Summary Cards - 40 lines)
├── BudgetOverviewItemsSection.swift (Items Grid/Table - 280 lines)
├── CircularProgressBudgetCard.swift (Item Card)
├── FolderBudgetCard.swift (Folder Card)
└── BudgetTableRow.swift (Table Row)
```

### Current Issues in Compact Mode

1. **Header Overflow** - Controls (scenario picker, filters, search, view toggle) don't fit in narrow windows
2. **Summary Cards** - 4-column grid forces horizontal scrolling or clipping
3. **No Content Width Constraint** - LazyVGrid calculates columns based on full ScrollView width
4. **Fixed Widths** - Search field has `minWidth: 300` which overflows in compact
5. **No WindowSize Integration** - Components don't receive or respond to window size

### Current Header Layout (Problematic)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Budget Overview Dashboard                              [Refresh]        │
│ ⭐ Scenario Name (Primary)                                              │
├─────────────────────────────────────────────────────────────────────────┤
│ Scenario: [Picker▼]  Filters: [Button]  Search: [___________]  [⊞|≡]  │
└─────────────────────────────────────────────────────────────────────────┘
```

**Problem:** At 640px, this layout overflows by ~200px.

---

## Implementation Strategy

### Pattern Reference

Following the established patterns from:
- **Budget Builder** (`BudgetDevelopmentUnifiedHeader.swift`) - Unified header with ellipsis menu
- **Guest Management** (`GuestManagementViewV4.swift`) - Content width constraint fix
- **Unified Header Pattern** (Basic Memory) - Responsive header architecture

### Key Architectural Decisions

1. **Create New Unified Header** - `BudgetOverviewUnifiedHeader.swift`
2. **Modify In-Place** - Update existing components, don't create V3
3. **Apply Content Width Constraint** - The critical fix from Guest Management
4. **Use Established Patterns** - WindowSize enum, collapsible menus, adaptive grids

---

## Detailed Implementation Plan

### Phase 1: Foundation (30 min)

#### 1.1 Add WindowSize to Main View

**File:** `BudgetOverviewDashboardViewV2.swift`

```swift
var body: some View {
    GeometryReader { geometry in
        let windowSize = geometry.size.width.windowSize
        let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl
        let availableWidth = geometry.size.width - (horizontalPadding * 2)
        
        VStack(spacing: 0) {
            // Header section (pass windowSize)
            headerSection(windowSize: windowSize)

            if loading {
                loadingView
            } else if let error {
                errorView(error)
            } else {
                overviewContent(windowSize: windowSize, availableWidth: availableWidth, horizontalPadding: horizontalPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    // ... existing modifiers
}
```

#### 1.2 Apply Content Width Constraint

**Critical Fix:** Constrain ScrollView content to prevent edge clipping.

```swift
private func overviewContent(windowSize: WindowSize, availableWidth: CGFloat, horizontalPadding: CGFloat) -> some View {
    ScrollView(.vertical, showsIndicators: true) {
        VStack(spacing: windowSize == .compact ? Spacing.lg : 24) {
            // Summary cards
            summaryCardsSection(windowSize: windowSize)

            // Budget items grid
            budgetItemsSection(windowSize: windowSize)
        }
        // ⭐ CRITICAL: Constrain to available width
        .frame(width: availableWidth)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, windowSize == .compact ? Spacing.md : Spacing.lg)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
```

---

### Phase 2: Unified Header (1.5 hours)

#### 2.1 Create BudgetOverviewUnifiedHeader.swift

**New File:** `Views/Budget/Components/BudgetOverviewUnifiedHeader.swift`

**Design Goals:**
- Consolidate title, subtitle, and controls
- Move Refresh and View Toggle into ellipsis menu for compact mode
- Stack form fields vertically in compact mode
- Align with Budget Builder header pattern

**Compact Layout:**
```
┌─────────────────────────────────────┐
│ Budget                    (⋯) [▼]   │
│ Budget Overview                     │
├─────────────────────────────────────┤
│ Scenario                            │
│ [Picker ▼] (⋯)                      │
│                                     │
│ 🔍 Search budget items...           │
│                                     │
│ [Status▼]  [Filters▼]  [Sort▼]     │
│       Clear All Filters             │
└─────────────────────────────────────┘
```

**Regular Layout:**
```
┌─────────────────────────────────────────────────────────────┐
│ Budget                                        (⋯) [▼ Nav]   │
│ Budget Overview                                             │
├─────────────────────────────────────────────────────────────┤
│ Scenario: [Picker▼] (⋯)  |  🔍 Search...  |  [Filters▼]  [⊞|≡] │
└─────────────────────────────────────────────────────────────┘
```

**Implementation:**

```swift
struct BudgetOverviewUnifiedHeader: View {
    let windowSize: WindowSize
    @Binding var currentPage: BudgetPage
    
    // Scenario bindings
    @Binding var selectedScenarioId: String
    @Binding var searchQuery: String
    @Binding var viewMode: BudgetOverviewDashboardViewV2.ViewMode
    
    // Data
    let allScenarios: [SavedScenario]
    let currentScenario: SavedScenario?
    let primaryScenario: SavedScenario?
    let loading: Bool
    let activeFilters: [BudgetFilter]
    
    var body: some View {
        VStack(spacing: windowSize == .compact ? Spacing.md : Spacing.lg) {
            // Title row with ellipsis and nav
            titleRow
            
            // Form fields (responsive)
            if windowSize == .compact {
                compactFormFields
            } else {
                regularFormFields
            }
        }
        .padding(windowSize == .compact ? Spacing.md : Spacing.lg)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Title Row
    
    private var titleRow: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Budget")
                    .font(Typography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 8) {
                    Text("Budget Overview")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textSecondary)
                    
                    if let scenario = currentScenario {
                        Text("•")
                            .foregroundColor(AppColors.textSecondary)
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(scenario.scenarioName)
                            .font(Typography.bodySmall)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: Spacing.sm) {
                ellipsisMenu
                budgetPageDropdown
            }
        }
    }
    
    // MARK: - Ellipsis Menu
    
    private var ellipsisMenu: some View {
        Menu {
            // Export Summary (placeholder for future)
            Button(action: {
                AppLogger.ui.info("Export Summary - Not yet implemented")
            }) {
                Label("Export Summary", systemImage: "square.and.arrow.up")
            }
            
            // View mode toggle (compact only)
            if windowSize == .compact {
                Divider()
                
                Section("View Mode") {
                    Button {
                        viewMode = .cards
                    } label: {
                        Label("Cards", systemImage: "square.grid.2x2")
                        if viewMode == .cards {
                            Image(systemName: "checkmark")
                        }
                    }
                    
                    Button {
                        viewMode = .table
                    } label: {
                        Label("Table", systemImage: "list.bullet")
                        if viewMode == .table {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundColor(AppColors.textPrimary)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Navigation Dropdown
    
    private var budgetPageDropdown: some View {
        Menu {
            Button {
                currentPage = .hub
            } label: {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }
            
            Divider()
            
            ForEach(BudgetGroup.allCases) { group in
                Section(group.rawValue) {
                    ForEach(group.pages) { page in
                        Button {
                            currentPage = page
                        } label: {
                            Label(page.rawValue, systemImage: page.icon)
                            if currentPage == page {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: currentPage.icon)
                    .font(.system(size: windowSize == .compact ? 20 : 16))
                if windowSize != .compact {
                    Text(currentPage.rawValue)
                        .font(.headline)
                }
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(AppColors.textPrimary)
            .frame(width: windowSize == .compact ? 44 : nil, height: 44)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Compact Form Fields
    
    @ViewBuilder
    private var compactFormFields: some View {
        VStack(spacing: Spacing.md) {
            // Scenario selector (full width)
            VStack(alignment: .leading, spacing: 4) {
                Text("Scenario")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Picker("Scenario", selection: $selectedScenarioId) {
                    ForEach(allScenarios, id: \.id) { scenario in
                        HStack {
                            if scenario.isPrimary {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                            Text(scenario.scenarioName)
                        }
                        .tag(scenario.id)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Search field (full width)
            searchField
            
            // Filter menus row
            filterMenusRow
        }
    }
    
    // MARK: - Regular Form Fields
    
    @ViewBuilder
    private var regularFormFields: some View {
        HStack(spacing: Spacing.lg) {
            // Scenario selector
            VStack(alignment: .leading, spacing: 4) {
                Text("Scenario")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Picker("Scenario", selection: $selectedScenarioId) {
                    ForEach(allScenarios, id: \.id) { scenario in
                        HStack {
                            if scenario.isPrimary {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                            Text(scenario.scenarioName)
                        }
                        .tag(scenario.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth: 200)
            }
            
            // Search field
            VStack(alignment: .leading, spacing: 4) {
                Text("Search")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                searchField
            }
            
            // Filters button
            VStack(alignment: .leading, spacing: 4) {
                Text("Filters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(activeFilters.isEmpty ? "All Items" : "\(activeFilters.count) filters")
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            // View toggle (regular mode only)
            Picker("View Mode", selection: $viewMode) {
                Image(systemName: "square.grid.2x2")
                    .tag(BudgetOverviewDashboardViewV2.ViewMode.cards)
                Image(systemName: "list.bullet")
                    .tag(BudgetOverviewDashboardViewV2.ViewMode.table)
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
        }
    }
    
    // MARK: - Search Field
    
    @ViewBuilder
    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
            
            TextField("Search budget items...", text: $searchQuery)
                .textFieldStyle(.plain)
            
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.sm)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .frame(maxWidth: windowSize == .compact ? .infinity : 250)
    }
    
    // MARK: - Filter Menus Row (Compact)
    
    @ViewBuilder
    private var filterMenusRow: some View {
        HStack(spacing: Spacing.sm) {
            // Status filter
            Menu {
                ForEach(BudgetFilter.allCases, id: \.self) { filter in
                    Button(filter.displayName) {
                        // Toggle filter
                    }
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.caption)
                    Text(activeFilters.isEmpty ? "Status" : "\(activeFilters.count)")
                        .font(Typography.bodySmall)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.primary)
            
            Spacer()
        }
    }
}
```

---

### Phase 3: Summary Cards Adaptation (30 min)

#### 3.1 Update BudgetOverviewSummaryCards.swift

**Goal:** 2-2 grid in compact mode, 4-column in regular/large.

```swift
struct BudgetOverviewSummaryCards: View {
    let windowSize: WindowSize
    let totalBudget: Double
    let totalExpenses: Double
    let totalRemaining: Double
    let itemCount: Int

    var body: some View {
        switch windowSize {
        case .compact:
            compactLayout
        case .regular, .large:
            regularLayout
        }
    }
    
    // MARK: - Compact Layout (2-2 Grid)
    
    private var compactLayout: some View {
        VStack(spacing: Spacing.md) {
            // Row 1: Budget + Expenses
            HStack(spacing: Spacing.md) {
                SummaryCardView(
                    title: "Total Budget",
                    value: totalBudget,
                    icon: "dollarsign.circle",
                    color: AppColors.Budget.allocated,
                    compact: true
                )
                
                SummaryCardView(
                    title: "Total Expenses",
                    value: totalExpenses,
                    icon: "receipt",
                    color: AppColors.Budget.pending,
                    compact: true
                )
            }
            
            // Row 2: Remaining + Items
            HStack(spacing: Spacing.md) {
                SummaryCardView(
                    title: "Remaining",
                    value: totalRemaining,
                    icon: "target",
                    color: totalRemaining >= 0 ? AppColors.Budget.underBudget : AppColors.Budget.overBudget,
                    compact: true
                )
                
                SummaryCardView(
                    title: "Budget Items",
                    value: Double(itemCount),
                    icon: "list.bullet",
                    color: .purple,
                    formatAsCurrency: false,
                    compact: true
                )
            }
        }
    }
    
    // MARK: - Regular Layout (4-Column)
    
    private var regularLayout: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            SummaryCardView(
                title: "Total Budget",
                value: totalBudget,
                icon: "dollarsign.circle",
                color: AppColors.Budget.allocated
            )

            SummaryCardView(
                title: "Total Expenses",
                value: totalExpenses,
                icon: "receipt",
                color: AppColors.Budget.pending
            )

            SummaryCardView(
                title: "Remaining",
                value: totalRemaining,
                icon: "target",
                color: totalRemaining >= 0 ? AppColors.Budget.underBudget : AppColors.Budget.overBudget
            )

            SummaryCardView(
                title: "Budget Items",
                value: Double(itemCount),
                icon: "list.bullet",
                color: .purple,
                formatAsCurrency: false
            )
        }
    }
}
```

#### 3.2 Update SummaryCardView for Compact Mode

Add `compact` parameter to reduce padding and font sizes:

```swift
struct SummaryCardView: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    var formatAsCurrency: Bool = true
    var compact: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: compact ? Spacing.xs : Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(compact ? .caption : .body)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(formattedValue)
                .font(compact ? Typography.title3 : Typography.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(compact ? Typography.caption : Typography.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? Spacing.md : Spacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.medium)
        .shadow(color: .black.opacity(0.05), radius: compact ? 2 : 4, x: 0, y: 1)
    }
}
```

---

### Phase 4: Budget Items Section Adaptation (45 min)

#### 4.1 Update BudgetOverviewItemsSection.swift

**Goal:** Adapt card grid and table view for compact windows.

```swift
struct BudgetOverviewItemsSection: View {
    let windowSize: WindowSize
    let filteredBudgetItems: [BudgetOverviewItem]
    // ... existing properties
    
    private var columns: [GridItem] {
        switch windowSize {
        case .compact:
            // Single column for compact
            return [GridItem(.flexible(), spacing: Spacing.md)]
        case .regular:
            // 2 columns for regular
            return [
                GridItem(.adaptive(minimum: 280, maximum: 380), spacing: 16)
            ]
        case .large:
            // 3+ columns for large
            return [
                GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
            ]
        }
    }
    
    private var cardsView: some View {
        LazyVGrid(columns: columns, spacing: windowSize == .compact ? Spacing.md : 16) {
            ForEach(topLevelItems) { item in
                if item.isFolder {
                    folderCardView(item)
                } else {
                    regularItemCard(item)
                }
            }
        }
    }
}
```

#### 4.2 Compact Table View Alternative

For compact mode, consider switching to a simplified list view instead of the full table:

```swift
@ViewBuilder
private var tableView: some View {
    if windowSize == .compact {
        // Simplified list for compact
        compactListView
    } else {
        // Full table for regular/large
        fullTableView
    }
}

private var compactListView: some View {
    LazyVStack(spacing: Spacing.sm) {
        ForEach(topLevelItems) { item in
            CompactBudgetItemRow(
                item: item,
                onTap: { /* expand/edit */ }
            )
        }
    }
}
```

---

### Phase 5: Integration & Testing (30 min)

#### 5.1 Wire Up Components

Update `BudgetOverviewDashboardViewV2.swift` to:
1. Pass `windowSize` to all child components
2. Use the new unified header
3. Apply content width constraint

#### 5.2 Testing Checklist

**Compact Mode (640-699px):**
- [ ] Header fits without overflow
- [ ] Summary cards display in 2-2 grid
- [ ] No edge clipping on any content
- [ ] Search field is full-width
- [ ] Filters accessible via menus
- [ ] View toggle in ellipsis menu
- [ ] Budget items display in single column
- [ ] Folders expand/collapse correctly

**Regular Mode (700-1000px):**
- [ ] No visual regression from current design
- [ ] Summary cards in 4-column grid
- [ ] View toggle visible inline
- [ ] Search field has appropriate width

**Transition Testing:**
- [ ] Smooth transition at 699px → 700px
- [ ] No layout jank during resize
- [ ] State preserved during resize

---

## Files to Create/Modify

### New Files

| File | Purpose |
|------|---------|
| `BudgetOverviewUnifiedHeader.swift` | New unified header component |

### Modified Files

| File | Changes |
|------|---------|
| `BudgetOverviewDashboardViewV2.swift` | Add GeometryReader, content width constraint, pass windowSize |
| `BudgetOverviewSummaryCards.swift` | Add windowSize parameter, 2-2 grid for compact |
| `BudgetOverviewItemsSection.swift` | Add windowSize parameter, adaptive columns |
| `SummaryCardView.swift` | Add compact mode support |

### Files to Deprecate

| File | Reason |
|------|--------|
| `BudgetOverviewHeader.swift` | Replaced by unified header |

---

## Risk Assessment

### Low Risk
- Summary cards adaptation (straightforward grid change)
- Content width constraint (proven pattern)

### Medium Risk
- Unified header creation (complex but follows established pattern)
- Table view adaptation (may need simplified compact version)

### Mitigation Strategies
1. **Incremental commits** - Commit after each phase
2. **Feature flag** - Can revert to old header if issues arise
3. **Testing at breakpoints** - Verify at 640px, 699px, 700px, 1000px

---

## Success Criteria

✅ View remains fully functional at 640px width  
✅ No edge clipping at any window width  
✅ Summary cards use 2-2 grid in compact mode  
✅ Header controls accessible via menus in compact mode  
✅ Smooth transitions when resizing window  
✅ No code duplication (single view adapts)  
✅ Maintains design system consistency  
✅ All features accessible in compact mode  
✅ Performance remains smooth with large datasets  
✅ Passes accessibility audit  

---

## Decisions Made

**Approved Approach:**

1. ✅ Unified header approach with navigation dropdown
2. ✅ 2-2 grid for summary cards in compact mode
3. ✅ Single-column card grid for budget items in compact mode
4. ✅ View toggle moved to ellipsis menu in compact mode
5. ✅ Content width constraint pattern from Guest Management

**Clarifications:**

1. **Navigation Dropdown** - ✅ YES - Include navigation dropdown to all 12 budget pages
2. **Filter Behavior** - ✅ Create Beads follow-up issue, keep existing placeholder for now
3. **Table View in Compact** - ✅ Show simplified list with dropdown to show details (non-editable)
4. **Ellipsis Menu** - ✅ Include minimal ellipsis with:
   - Export Summary (placeholder for future)
   - View Mode toggle (compact mode only)
   - NO Refresh button (handled on page load)

---

**✅ APPROVED - Proceeding with implementation**
