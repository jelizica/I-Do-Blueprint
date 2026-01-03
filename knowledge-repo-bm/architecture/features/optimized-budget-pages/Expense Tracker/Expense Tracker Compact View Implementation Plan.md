---
title: Expense Tracker Compact View Implementation Plan
type: note
permalink: architecture/plans/expense-tracker-compact-view-implementation-plan
tags:
- expense-tracker
- compact-window
- responsive-design
- implementation-plan
- budget-module
- swiftui
- macos
---

# Expense Tracker Compact View Implementation Plan

> **Status:** ✅ APPROVED - READY TO IMPLEMENT  
> **Created:** January 2026  
> **Epic:** `I Do Blueprint-0f4` - Budget Compact Views Optimization  
> **Beads Issue:** `I Do Blueprint-yhc` - Expense Tracker Compact Window Optimization  
> **Priority:** P1 (High-Traffic Page)  
> **Estimated Hours:** 3-4 hours

---

## Executive Summary

This plan outlines the comprehensive responsive design implementation for the **Expense Tracker** page (`ExpenseTrackerView.swift`), enabling seamless operation in compact windows (640-700px width) for 13" MacBook Air split-screen scenarios.

### Unique Characteristics of Expense Tracker

Unlike other budget pages, the Expense Tracker has several unique elements that require specialized handling:

1. **Dual View Mode Toggle** - Cards vs List view (must work in both compact modes)
2. **Category Benchmarks Section** - Collapsible performance comparison section
3. **Rich Expense Cards** - Multiple status badges (payment + approval), notes preview
4. **Three Filter Dimensions** - Search, Status, Category (more complex than Guest/Vendor)
5. **Inline Action Buttons** - Edit/Delete on each row/card

### Key Deliverables

1. **Unified Header** - Consolidate title, stats, and actions with ellipsis menu
2. **Responsive Filter Bar** - Collapsible menus for compact, inline for regular
3. **Compact Expense Cards** - Tighter layout with essential info visible
4. **Compact List Rows** - Expandable rows with priority columns
5. **Responsive Benchmarks** - Horizontal scroll or collapsible in compact
6. **Content Width Constraint** - Critical fix for edge clipping

---

## Current State Analysis

### Component Hierarchy (Current)

```
ExpenseTrackerView
├── ExpenseTrackerHeader (title + stats + add button)
│   ├── Title Row: "Expense Tracker" + Add Expense button
│   └── StatsGridView (4 columns: Total Spent, Pending, Paid, Count)
│
├── ExpenseFiltersBar (search + filters + view toggle + benchmarks toggle)
│   ├── Search field (fixed 300px max)
│   ├── Status Picker (150px)
│   ├── Category Picker (200px)
│   ├── View Mode Toggle (Cards/List)
│   └── Benchmarks Toggle
│
├── ExpenseListView (cards or list based on viewMode)
│   ├── ExpenseCardsGridView (2-column LazyVGrid)
│   │   └── ExpenseCardView (rich card with badges, notes)
│   └── ExpenseListRowsView (LazyVStack)
│       └── ExpenseTrackerRowView (horizontal row)
│
└── CategoryBenchmarksSection (collapsible)
    └── CategoryBenchmarkRow (progress bars)
```

### Current Issues in Compact Mode

| Issue | Component | Severity | Description |
|-------|-----------|----------|-------------|
| **Header Overflow** | ExpenseTrackerHeader | High | Add button doesn't fit next to title |
| **Stats Clipping** | StatsGridView | High | 4-column grid overflows at <700px |
| **Filter Bar Overflow** | ExpenseFiltersBar | Critical | Fixed widths cause horizontal scroll |
| **Card Grid Clipping** | ExpenseCardsGridView | High | 2-column grid clips at edges |
| **Row Overflow** | ExpenseTrackerRowView | High | Too many columns for narrow width |
| **No WindowSize** | All | Critical | Components don't detect window size |
| **No Content Constraint** | ExpenseTrackerView | Critical | LazyVGrid calculates wrong width |

---

## Implementation Plan

### Phase 1: Foundation (45 min)

#### 1.1 Add GeometryReader and WindowSize Detection

**File:** `ExpenseTrackerView.swift`

**Changes:**
```swift
var body: some View {
    GeometryReader { geometry in
        let windowSize = geometry.size.width.windowSize
        let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.huge
        let availableWidth = geometry.size.width - (horizontalPadding * 2)
        
        ZStack {
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: windowSize == .compact ? Spacing.lg : Spacing.xl) {
                    // Header
                    ExpenseTrackerUnifiedHeader(
                        windowSize: windowSize,
                        totalSpent: budgetStore.totalExpensesAmount,
                        pendingAmount: budgetStore.pendingExpensesAmount,
                        paidAmount: budgetStore.paidExpensesAmount,
                        expenseCount: budgetStore.expenseStore.expenses.count,
                        onAddExpense: { showAddExpenseSheet = true }
                    )
                    
                    // Filters
                    ExpenseFiltersBarV2(
                        windowSize: windowSize,
                        searchText: $searchText,
                        selectedFilterStatus: $selectedFilterStatus,
                        selectedCategoryFilter: $selectedCategoryFilter,
                        viewMode: $viewMode,
                        showBenchmarks: $showBenchmarks,
                        categories: budgetStore.categoryStore.categories
                    )
                    
                    // Expense List
                    ExpenseListViewV2(
                        windowSize: windowSize,
                        expenses: filteredExpenses,
                        viewMode: viewMode,
                        isLoading: isLoadingExpenses,
                        onExpenseSelected: { expense in selectedExpense = expense },
                        onExpenseDelete: { expense in
                            expenseToDelete = expense
                            showDeleteAlert = true
                        },
                        onAddExpense: { showAddExpenseSheet = true }
                    )
                    
                    // Benchmarks (conditional)
                    if showBenchmarks {
                        CategoryBenchmarksSectionV2(
                            windowSize: windowSize,
                            benchmarks: categoryBenchmarks
                        )
                    }
                }
                .frame(width: availableWidth)  // ⭐ CRITICAL FIX
                .padding(.horizontal, horizontalPadding)
            }
        }
    }
}
```

**Why This Matters:**
- `GeometryReader` provides actual window width
- `availableWidth` calculated by subtracting padding from both sides
- `.frame(width: availableWidth)` constrains VStack to correct width
- LazyVGrid receives correct proposed width for column calculation

---

### Phase 2: Unified Header (45 min)

#### 2.1 Create ExpenseTrackerUnifiedHeader

**File:** `Views/Budget/Components/ExpenseTrackerUnifiedHeader.swift` (NEW)

**Design:**
```
┌─────────────────────────────────────────────────────────────┐
│ Expense Tracker                               (⋯) [+ Add]   │
│ Track and manage all wedding expenses                       │
├─────────────────────────────────────────────────────────────┤
│ ┌─────��───┐ ┌─────────┐ ┌─────────┐ ┌─────────┐            │
│ │ $X,XXX  │ │ $X,XXX  │ │ $X,XXX  │ │   XX    │            │
│ │ Total   │ │ Pending │ │  Paid   │ │ Count   │            │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘            │
└─────────────────────────────────────────────────────────────┘

COMPACT MODE:
┌─────────────────────────────────┐
│ Expense Tracker       (⋯) [+]   │
│ Track expenses                  │
├─────────────────────────────────┤
│ ┌───────────┐ ┌───────────┐    │
│ │  $X,XXX   │ │  $X,XXX   │    │
│ │  Total    │ │  Pending  │    │
│ └───────────┘ └───────────┘    │
│ ┌───────────┐ ┌───────────┐    │
│ │  $X,XXX   │ │    XX     │    ���
│ │   Paid    │ │  Count    │    │
│ └───────────┘ └───────────┘    │
└─────────────────────────────────┘
```

**Implementation:**
```swift
struct ExpenseTrackerUnifiedHeader: View {
    let windowSize: WindowSize
    let totalSpent: Double
    let pendingAmount: Double
    let paidAmount: Double
    let expenseCount: Int
    let onAddExpense: () -> Void
    
    var body: some View {
        VStack(spacing: windowSize == .compact ? Spacing.md : Spacing.lg) {
            // Title row
            titleRow
            
            // Stats cards (responsive grid)
            statsSection
        }
        .padding(windowSize == .compact ? Spacing.md : Spacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.lg)
    }
    
    private var titleRow: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Expense Tracker")
                    .font(Typography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)
                
                if windowSize != .compact {
                    Text("Track and manage all wedding expenses")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: Spacing.sm) {
                ellipsisMenu
                addButton
            }
        }
        .frame(height: 68)
    }
    
    private var ellipsisMenu: some View {
        Menu {
            Button(action: { /* Export CSV */ }) {
                Label("Export as CSV", systemImage: "tablecells")
            }
            Button(action: { /* Export PDF */ }) {
                Label("Export as PDF", systemImage: "doc.richtext")
            }
            Divider()
            Button(action: { /* Bulk actions */ }) {
                Label("Bulk Edit", systemImage: "pencil.and.list.clipboard")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .help("More actions")
    }
    
    private var addButton: some View {
        Button(action: onAddExpense) {
            if windowSize == .compact {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 44, height: 44)
            } else {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Expense")
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(AppColors.Budget.allocated)
                .foregroundColor(AppColors.textPrimary)
                .cornerRadius(8)
            }
        }
        .buttonStyle(.plain)
        .help("Add new expense")
    }
    
    private var statsSection: some View {
        let stats = [
            StatItem(icon: "dollarsign.circle.fill", label: "Total Spent", 
                     value: formatCurrency(totalSpent), color: AppColors.Budget.expense),
            StatItem(icon: "clock.fill", label: "Pending", 
                     value: formatCurrency(pendingAmount), color: AppColors.Budget.pending),
            StatItem(icon: "checkmark.circle.fill", label: "Paid", 
                     value: formatCurrency(paidAmount), color: AppColors.Budget.income),
            StatItem(icon: "doc.text.fill", label: "Total", 
                     value: "\(expenseCount)", color: .purple)
        ]
        
        if windowSize == .compact {
            // 2x2 grid for compact
            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    CompactStatCard(stat: stats[0])
                    CompactStatCard(stat: stats[1])
                }
                HStack(spacing: Spacing.sm) {
                    CompactStatCard(stat: stats[2])
                    CompactStatCard(stat: stats[3])
                }
            }
        } else {
            // 4-column for regular
            HStack(spacing: Spacing.md) {
                ForEach(stats, id: \.label) { stat in
                    StatCard(stat: stat)
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }
}
```

---

### Phase 3: Responsive Filter Bar (45 min)

#### 3.1 Create ExpenseFiltersBarV2

**File:** `Views/Budget/Components/ExpenseFiltersBarV2.swift` (NEW)

**Design:**
```
REGULAR MODE:
┌──────────────────────────────────────────────────────────────────────┐
│ 🔍 Search...  │ [All Status ▼] [All Categories ▼]  [Cards|List] [📊]│
└──────────────────────────────────────────────────────────────────────┘

COMPACT MODE:
┌─────────────────────────────────┐
��� 🔍 Search expenses...        ✕  │  ← Full-width search
└─────────────────────────────────┘
┌────────┬────────┬────────┬─────┐
│Status▼ │Category│Cards/  │ 📊  │  ← Compact controls
│        │   ▼    │ List   │     │
└────────┴────────┴────────┴─────┘
      Clear All Filters            ← Centered (if active)
```

**Implementation:**
```swift
struct ExpenseFiltersBarV2: View {
    let windowSize: WindowSize
    @Binding var searchText: String
    @Binding var selectedFilterStatus: PaymentStatus?
    @Binding var selectedCategoryFilter: UUID?
    @Binding var viewMode: ExpenseViewMode
    @Binding var showBenchmarks: Bool
    let categories: [BudgetCategory]
    
    private var hasActiveFilters: Bool {
        selectedFilterStatus != nil || selectedCategoryFilter != nil || !searchText.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if windowSize == .compact {
                compactLayout
            } else {
                regularLayout
            }
            
            // Clear all button (centered, conditional)
            if hasActiveFilters {
                HStack {
                    Spacer()
                    clearAllFiltersButton
                    Spacer()
                }
            }
        }
        .padding(Spacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.lg)
    }
    
    // MARK: - Compact Layout
    
    private var compactLayout: some View {
        VStack(spacing: Spacing.sm) {
            // Full-width search
            searchField
                .frame(maxWidth: .infinity)
            
            // Filter controls row
            HStack(spacing: Spacing.sm) {
                statusFilterMenu
                categoryFilterMenu
                viewModeToggleCompact
                benchmarksToggle
            }
        }
    }
    
    // MARK: - Regular Layout
    
    private var regularLayout: some View {
        HStack(spacing: Spacing.md) {
            searchField
                .frame(minWidth: 150, idealWidth: 200, maxWidth: 300)
            
            Picker("Status", selection: $selectedFilterStatus) {
                Text("All Status").tag(nil as PaymentStatus?)
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status as PaymentStatus?)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)
            
            Picker("Category", selection: $selectedCategoryFilter) {
                Text("All Categories").tag(nil as UUID?)
                ForEach(categories) { category in
                    Text(category.categoryName).tag(category.id as UUID?)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200)
            
            Spacer()
            
            ExpenseViewModeToggle(viewMode: $viewMode)
            benchmarksToggle
        }
    }
    
    // MARK: - Filter Menus (Compact)
    
    private var statusFilterMenu: some View {
        ZStack(alignment: .trailing) {
            Menu {
                Button("All Status") { selectedFilterStatus = nil }
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    Button(status.displayName) { selectedFilterStatus = status }
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.caption)
                    Text(selectedFilterStatus?.displayName ?? "Status")
                        .font(Typography.bodySmall)
                        .lineLimit(1)
                    if selectedFilterStatus == nil {
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.primary)
            
            if selectedFilterStatus != nil {
                Button { selectedFilterStatus = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.primary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, Spacing.sm)
            }
        }
    }
    
    private var categoryFilterMenu: some View {
        ZStack(alignment: .trailing) {
            Menu {
                Button("All Categories") { selectedCategoryFilter = nil }
                ForEach(categories) { category in
                    Button(category.categoryName) { selectedCategoryFilter = category.id }
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "folder")
                        .font(.caption)
                    Text(categoryName ?? "Category")
                        .font(Typography.bodySmall)
                        .lineLimit(1)
                    if selectedCategoryFilter == nil {
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.bordered)
            .tint(.teal)
            
            if selectedCategoryFilter != nil {
                Button { selectedCategoryFilter = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.teal)
                }
                .buttonStyle(.plain)
                .padding(.trailing, Spacing.sm)
            }
        }
    }
    
    private var categoryName: String? {
        guard let id = selectedCategoryFilter else { return nil }
        return categories.first { $0.id == id }?.categoryName
    }
    
    private var viewModeToggleCompact: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewMode = viewMode == .cards ? .list : .cards
            }
        } label: {
            Image(systemName: viewMode.icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 36, height: 36)
                .background(AppColors.controlBackground)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(viewMode == .cards ? "Switch to List" : "Switch to Cards")
    }
    
    private var benchmarksToggle: some View {
        Button {
            withAnimation { showBenchmarks.toggle() }
        } label: {
            Image(systemName: showBenchmarks ? "chart.bar.fill" : "chart.bar")
                .font(.system(size: 16))
                .foregroundColor(showBenchmarks ? AppColors.primary : AppColors.textPrimary)
                .frame(width: 36, height: 36)
                .background(showBenchmarks ? AppColors.primary.opacity(0.15) : AppColors.controlBackground)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(showBenchmarks ? "Hide Benchmarks" : "Show Benchmarks")
    }
    
    // ... searchField and clearAllFiltersButton implementations
}
```

---

### Phase 4: Responsive Expense Cards (45 min)

#### 4.1 Create ExpenseCompactCard

**File:** `Views/Budget/Components/ExpenseCompactCard.swift` (NEW)

**Design:**
```
┌─────────────────────────────────┐
│ $1,234.56              [⋯]     │  ← Amount + menu
│ ┌──────┐ ┌────────┐            │
│ │ Paid │ │Approved│            │  ← Status badges (if meaningful)
│ └──────┘ └────────┘            │
│                                 │
│ Venue Deposit                   │  ← Name (2 lines max)
│                                 │
│ 🏛️ Venue  •  📅 Jan 15         │  ← Category + Date
│ 💳 Credit Card                  │  ← Payment method
└─────────────────────────────────┘
```

**Implementation:**
```swift
struct ExpenseCompactCard: View {
    let expense: Expense
    let onEdit: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    private var category: BudgetCategory? {
        budgetStore.categoryStore.categories.first { $0.id == expense.budgetCategoryId }
    }
    
    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Amount + Menu row
                HStack {
                    Text(String(format: "$%.2f", expense.amount))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                    
                    Menu {
                        Button("Edit", action: onEdit)
                        Divider()
                        Button("Delete", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                            .padding(Spacing.xs)
                            .background(AppColors.textPrimary.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Status badges row
                HStack(spacing: Spacing.xs) {
                    paymentStatusBadge
                    if shouldShowApprovalStatus {
                        approvalStatusBadge
                    }
                }
                
                // Expense name
                Text(expense.expenseName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Category + Date row
                HStack(spacing: Spacing.sm) {
                    if let category {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: category.color) ?? AppColors.Budget.allocated)
                                .frame(width: 6, height: 6)
                            Text(category.categoryName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(expense.expenseDate, style: .date)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                // Payment method
                HStack(spacing: 4) {
                    Image(systemName: paymentMethodIcon)
                        .font(.caption2)
                    Text(paymentMethodDisplayName)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .padding(Spacing.md)
            .background(Color(NSColor.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.textSecondary.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // ... badge implementations
}
```

#### 4.2 Update ExpenseCardsGridView for Responsive Layout

**File:** `Views/Budget/Components/ExpenseListView.swift`

**Changes:**
```swift
struct ExpenseCardsGridViewV2: View {
    let windowSize: WindowSize
    let expenses: [Expense]
    let onExpenseSelected: (Expense) -> Void
    let onExpenseDelete: (Expense) -> Void
    
    private var columns: [GridItem] {
        if windowSize == .compact {
            // Single column for compact, using compact cards
            [GridItem(.flexible(), spacing: Spacing.md)]
        } else {
            // 2 columns for regular/large
            [
                GridItem(.flexible(), spacing: Spacing.lg),
                GridItem(.flexible(), spacing: Spacing.lg)
            ]
        }
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: windowSize == .compact ? Spacing.md : Spacing.lg) {
            ForEach(expenses, id: \.id) { expense in
                if windowSize == .compact {
                    ExpenseCompactCard(
                        expense: expense,
                        onEdit: { onExpenseSelected(expense) },
                        onDelete: { onExpenseDelete(expense) }
                    )
                } else {
                    ExpenseCardView(
                        expense: expense,
                        onEdit: { onExpenseSelected(expense) },
                        onDelete: { onExpenseDelete(expense) }
                    )
                }
            }
        }
        .padding(windowSize == .compact ? Spacing.md : Spacing.lg)
    }
}
```

---

### Phase 5: Expandable List Rows (30 min)

#### 5.1 Create ExpenseExpandableRow

**File:** `Views/Budget/Components/ExpenseExpandableRow.swift` (NEW)

**Design:**
```
COLLAPSED:
┌─────────────────────────────────────────────────────────────┐
│ ▶  Venue Deposit                           $1,234   [Paid] │
└─────────────────────────────────────────────────────────────┘

EXPANDED:
┌─────────────────────────────────────────────────────────────┐
│ ▼  Venue Deposit                           $1,234   [Paid] │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │  🏛️ Venue              📅 Jan 15, 2026                  │ │
│ │  💳 Credit Card        ✅ Approved                      │ │
│ │                                                         │ │
│ │  📝 "Deposit for reception venue..."                    │ │
│ │                                                         │ │
│ │  [Edit]                              [Delete]           │ │
│ └─────────────────────────────────────────────────────────┘ │
└────────────────────────��────────────────────────────────────┘
```

**Implementation:**
```swift
struct ExpenseExpandableRow: View {
    let expense: Expense
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    private var category: BudgetCategory? {
        budgetStore.categoryStore.categories.first { $0.id == expense.budgetCategoryId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Collapsed row (always visible)
            collapsedRow
            
            // Expanded content (conditionally visible)
            if isExpanded {
                expandedContent
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
    
    private var collapsedRow: some View {
        Button(action: onToggleExpand) {
            HStack(spacing: Spacing.sm) {
                // Chevron indicator
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                // Status indicator
                Circle()
                    .fill(expense.paymentStatus == .paid ? AppColors.Budget.income : AppColors.Budget.pending)
                    .frame(width: 8, height: 8)
                
                // Expense name
                Text(expense.expenseName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Amount
                Text(String(format: "$%.2f", expense.amount))
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 80, alignment: .trailing)
                
                // Status badge
                Text(expense.paymentStatus.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Row 1: Category + Date
            HStack(spacing: Spacing.lg) {
                if let category {
                    categoryBadge(category)
                }
                dateBadge
            }
            
            // Row 2: Payment method + Approval status
            HStack(spacing: Spacing.lg) {
                paymentMethodBadge
                if shouldShowApprovalStatus {
                    approvalBadge
                }
            }
            
            // Notes (if any)
            if let notes = expense.notes, !notes.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.caption2)
                    Text(notes)
                        .font(.caption)
                        .lineLimit(2)
                }
                .foregroundColor(.secondary)
            }
            
            // Action buttons
            HStack {
                Button("Edit", action: onEdit)
                    .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Delete", role: .destructive, action: onDelete)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .background(AppColors.controlBackground.opacity(0.3))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // ... badge implementations
}
```

---

### Phase 6: Responsive Benchmarks Section (20 min)

#### 6.1 Update CategoryBenchmarksSection

**File:** `Views/Budget/Components/CategoryBenchmarksSectionV2.swift` (NEW)

**Design:**
```
REGULAR MODE:
┌─────────────────────────────────────────────────────────────┐
│ Category Performance vs Budget                              │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Venue        $5,000 of $8,000    ████████░░░░ 62.5%    │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Catering     $3,500 of $5,000    ███████░░░░░ 70.0%    │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

COMPACT MODE:
┌─────────────────────────────────┐
│ Category Performance            │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ Venue                       │ │
│ │ $5,000 / $8,000             │ │
│ │ ████████░░░░ 62.5%          │ │
│ │ ✅ On Track                 │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**Implementation:**
```swift
struct CategoryBenchmarksSectionV2: View {
    let windowSize: WindowSize
    let benchmarks: [CategoryBenchmarkData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(windowSize == .compact ? "Category Performance" : "Category Performance vs Budget")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView {
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(benchmarks, id: \.category.id) { benchmark in
                        if windowSize == .compact {
                            CompactBenchmarkRow(benchmark: benchmark)
                        } else {
                            CategoryBenchmarkRow(
                                category: benchmark.category,
                                spent: benchmark.spent,
                                percentage: benchmark.percentage,
                                status: benchmark.status
                            )
                        }
                    }
                }
            }
            .frame(maxHeight: windowSize == .compact ? 250 : 300)
        }
        .padding(Spacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.lg)
    }
}

struct CompactBenchmarkRow: View {
    let benchmark: CategoryBenchmarkData
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(benchmark.category.categoryName)
                .font(.system(size: 13, weight: .semibold))
            
            HStack {
                Text(String(format: "$%.0f", benchmark.spent))
                    .font(.caption)
                    .fontWeight(.medium)
                Text("/")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "$%.0f", benchmark.category.allocatedAmount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.textSecondary.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(benchmark.status.color)
                        .frame(
                            width: min(CGFloat(benchmark.percentage / 100) * geometry.size.width, geometry.size.width),
                            height: 6
                        )
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
            
            HStack {
                Image(systemName: benchmark.status.icon)
                    .font(.caption2)
                Text(benchmark.status.label)
                    .font(.caption)
                Spacer()
                Text(String(format: "%.1f%%", benchmark.percentage))
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(benchmark.status.color)
        }
        .padding(Spacing.md)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
}
```

---

## Files Summary

### New Files (6)

| File | Purpose | Lines (Est.) |
|------|---------|--------------|
| `ExpenseTrackerUnifiedHeader.swift` | Unified header with stats | ~200 |
| `ExpenseFiltersBarV2.swift` | Responsive filter bar | ~250 |
| `ExpenseCompactCard.swift` | Compact expense card | ~150 |
| `ExpenseExpandableRow.swift` | Expandable list row | ~180 |
| `ExpenseListViewV2.swift` | Updated list view | ~100 |
| `CategoryBenchmarksSectionV2.swift` | Responsive benchmarks | ~120 |

### Modified Files (1)

| File | Changes | Lines Changed |
|------|---------|---------------|
| `ExpenseTrackerView.swift` | GeometryReader, WindowSize, content constraint | ~80 |

**Total:** 7 files, ~1,080 lines

---

## Testing Checklist

### Functional Requirements

- [ ] View remains fully functional at 640px width
- [ ] No edge clipping at any window width
- [ ] Stats cards use 2x2 grid in compact mode
- [ ] Header controls accessible via menus in compact mode
- [ ] Smooth transitions when resizing window
- [ ] No code duplication (single view adapts)
- [ ] Maintains design system consistency
- [ ] All features accessible in compact mode
- [ ] Performance remains smooth with large datasets
- [ ] Passes accessibility audit

### Component-Specific Tests

**Header:**
- [ ] Title displays correctly in all modes
- [ ] Stats grid adapts (4-col → 2x2)
- [ ] Ellipsis menu works
- [ ] Add button works (icon in compact, text+icon in regular)

**Filters:**
- [ ] Search field is full-width in compact
- [ ] Status filter menu works with X clear button
- [ ] Category filter menu works with X clear button
- [ ] View mode toggle works
- [ ] Benchmarks toggle works
- [ ] Clear All button appears when filters active

**Cards View:**
- [ ] Single column in compact mode
- [ ] Compact cards display all essential info
- [ ] Edit/Delete menu works
- [ ] Status badges display correctly

**List View:**
- [ ] Expandable rows work
- [ ] Priority columns visible in collapsed state
- [ ] Expanded content shows all details
- [ ] Edit/Delete buttons work in expanded state

**Benchmarks:**
- [ ] Compact layout displays correctly
- [ ] Progress bars render properly
- [ ] Status colors correct

### Window Size Tests

| Width | Expected Behavior |
|-------|-------------------|
| 640px | Full compact layout, no clipping |
| 670px | Compact layout, 1-2 cards per row |
| 699px | Compact layout, no overflow |
| 700px | Regular layout transition |
| 900px | Regular layout, 2-column cards |
| 1000px | Large layout, 2-column cards |

---

## Patterns Applied

### From Previous Implementations

1. **Content Width Constraint Pattern** (from Guest Management)
   - Calculate `availableWidth` before grid layout
   - Apply `.frame(width: availableWidth)` to content VStack

2. **Unified Header with Responsive Actions Pattern** (from Budget Builder)
   - Single header with ellipsis menu for secondary actions
   - Icon-only buttons in compact mode

3. **Collapsible Filter Menu Pattern** (from Guest Management)
   - Menu-based filters with X clear buttons
   - Color-coded filter types (blue for status, teal for category)

4. **Expandable Table Row Pattern** (from Budget Overview)
   - Priority columns in collapsed state
   - Full details in expanded state

5. **2x2 Stats Grid Pattern** (from Vendor Management)
   - 4-column → 2x2 grid in compact mode

### Unique to Expense Tracker

1. **Dual View Mode Responsiveness**
   - Both Cards and List views adapt to compact mode
   - View mode toggle works in all window sizes

2. **Collapsible Benchmarks Section**
   - Compact benchmark rows with vertical layout
   - Reduced height in compact mode

3. **Rich Status Badge Display**
   - Payment status + Approval status (when meaningful)
   - Conditional display logic preserved

---

## Success Criteria

✅ Single unified header displayed  
✅ Stats grid adapts to 2x2 in compact mode  
✅ Filter bar uses menus in compact mode  
✅ Expense cards compact and readable  
✅ List rows expandable with priority columns  
✅ Benchmarks section responsive  
✅ No horizontal scrolling at any width  
✅ All numbers on one line (no wrapping)  
✅ Build succeeds with no errors  
✅ All Beads issues closed  

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Complex filter state management | Medium | Medium | Reuse proven patterns from Guest Management |
| Dual view mode complexity | Medium | Low | Test both modes at each breakpoint |
| Benchmark section overflow | Low | Low | Use ScrollView with max height |
| Performance with many expenses | Low | Medium | Use LazyVStack/LazyVGrid throughout |

---

## Dependencies

- `Design/WindowSize.swift` - Already exists
- `Design/DesignSystem.swift` - Typography, Spacing, Colors
- `BudgetStoreV2` - Expense data access
- `ExpenseViewMode` enum - Already exists

---

## Estimated Timeline

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 1: Foundation | 45 min | 45 min |
| Phase 2: Unified Header | 45 min | 1.5 hours |
| Phase 3: Responsive Filters | 45 min | 2.25 hours |
| Phase 4: Responsive Cards | 45 min | 3 hours |
| Phase 5: Expandable Rows | 30 min | 3.5 hours |
| Phase 6: Responsive Benchmarks | 20 min | 3.8 hours |
| Testing & Polish | 20 min | 4 hours |

**Total Estimated:** 4 hours

---

## Approval Request

This plan is ready for review. Key decisions requiring approval:

1. **Unified Header Approach** - Consolidate title, stats, and actions into single component
2. **Dual View Mode Strategy** - Both Cards and List views get compact variants
3. **Expandable Row Pattern** - Use for List view in compact mode
4. **Benchmark Section** - Compact vertical layout with reduced height

**Please confirm approval to proceed with implementation.**

---

## Related Documentation

- [[Budget Dashboard Optimization - Complete Reference]]
- [[Guest Management Compact Window - Complete Session Implementation]]
- [[Vendor Management Compact Window Implementation]]
- [[Unified Header with Responsive Actions Pattern]]
- [[Expandable Table Row Pattern]]
- [[SwiftUI LazyVGrid Adaptive Card Grid Pattern]]

---

## User Feedback Incorporated

### 1. NO Horizontal Scrolling - Collapsible Benchmarks ✅

**User Request:** "I hate horizontal scrolling, so I would rather it be collapsible"

**Implementation:** Phase 6 updated to use collapsible pattern with chevron expand/collapse:

```swift
struct CategoryBenchmarksSectionV2: View {
    @State private var isExpanded: Bool = true  // Collapsible in compact mode
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Collapsible header in compact mode
            if windowSize == .compact {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        Text("Category Performance (\(benchmarks.count))")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
            
            // Content (collapsible in compact mode)
            if isExpanded {
                // Benchmark rows...
            }
        }
    }
}
```

**Benefits:**
- Zero horizontal scrolling
- User controls visibility
- Smooth animations
- Saves vertical space when collapsed

---

### 2. Header Duplication Prevention ✅

**User Request:** "Make sure to disable the group header across all budget pages to avoid duplication"

**Implementation:** Phase 1 updated to include `BudgetDashboardHubView` modification:

**File:** `Views/Budget/BudgetDashboardHubView.swift`

```swift
// Add expenseTracker to exclusion list
if currentPage != .budgetBuilder && 
   currentPage != .budgetOverview && 
   currentPage != .expenseTracker {  // ⭐ NEW
    BudgetManagementHeader(...)
}
```

**Pattern Established:**
- Pages with unified headers are explicitly excluded
- Prevents duplicate headers across ALL budget pages
- Establishes pattern for remaining 9 budget pages

**Future Applications:**
- Payment Schedule
- Budget Analytics
- Expense Reports
- Gifts and Owed
- Expense Categories
- Money Owed
- Money Received
- Budget Calculator
- Budget Cash Flow

---

### 3. Dynamic Content-Aware Grid Width Pattern ✅

**User Request:** "Can we use the dynamic, context-aware grid pattern (Dynamic Content-Aware Grid Width Pattern in basic memory) here?"

**Implementation:** Phase 4 updated with three-factor dynamic width calculation:

**Pattern Applied:** [[Dynamic Content-Aware Grid Width Pattern]] from Budget Overview

```swift
struct ExpenseCardsGridViewV2: View {
    // Dynamic width calculation based on actual expense data
    private var dynamicMinimumCardWidth: CGFloat {
        // FACTOR 1: Currency Width (8.5px per character)
        let maxAmount = expenses.map { $0.amount }.max() ?? 0
        let digitCount = String(format: "%.2f", maxAmount).count
        let currencyWidth = CGFloat(digitCount) * 8.5 + 10
        
        // FACTOR 2: Longest Word (9px per character)
        let longestWord = expenses
            .flatMap { $0.expenseName.split(separator: " ") }
            .map { String($0) }
            .max(by: { $0.count < $1.count }) ?? ""
        let longestWordWidth = CGFloat(longestWord.count) * 9 + 10
        
        // FACTOR 3: Minimum Usability
        let minimumUsable: CGFloat = 140
        
        // Calculate minimum that satisfies all constraints
        let calculatedWidth = max(
            currencyWidth + 80,  // Amount + padding + menu
            longestWordWidth + 40,  // Name + padding
            minimumUsable
        )
        
        return min(max(calculatedWidth, 140), 250)
    }
    
    private var columns: [GridItem] {
        if windowSize == .compact {
            // Adaptive grid with dynamic minimum width
            [GridItem(.adaptive(minimum: dynamicMinimumCardWidth, maximum: 250), spacing: Spacing.md)]
        } else {
            // 2 columns for regular/large
            [
                GridItem(.flexible(), spacing: Spacing.lg),
                GridItem(.flexible(), spacing: Spacing.lg)
            ]
        }
    }
}
```

**Benefits:**
- Cards automatically size to fit content without wrapping
- Adapts to user's actual expense data (not fixed widths)
- Maximizes space efficiency while maintaining readability
- Prevents number wrapping (critical for currency)
- Prevents word breaking in expense names
- Automatically fits 1-3 cards per row based on content

**Why Three Factors?**
1. **Currency Width** - Prevents "$12,345.67" from wrapping
2. **Longest Word** - Prevents "Photographer" from breaking mid-word
3. **Minimum Usability** - Ensures cards remain readable (140px minimum)

---

## Updated Timeline

| Phase | Duration | Cumulative | Changes |
|-------|----------|------------|---------|
| Phase 1: Foundation + Header Skip | 45 min | 45 min | Added BudgetDashboardHubView update |
| Phase 2: Unified Header | 45 min | 1.5 hours | No change |
| Phase 3: Responsive Filters | 45 min | 2.25 hours | No change |
| Phase 4: Dynamic Width Cards | 60 min | 3.25 hours | +15 min for dynamic calculation |
| Phase 5: Expandable Rows | 30 min | 3.75 hours | No change |
| Phase 6: Collapsible Benchmarks | 25 min | 4 hours | +5 min for collapse logic |
| Testing & Polish | 20 min | 4.3 hours | No change |

**Total Estimated:** 4.3 hours (was 4 hours)

---

## Updated Patterns Applied

### From Previous Implementations

1. **Content Width Constraint Pattern** (from Guest Management)
2. **Unified Header with Responsive Actions Pattern** (from Budget Builder)
3. **Collapsible Filter Menu Pattern** (from Guest Management)
4. **Expandable Table Row Pattern** (from Budget Overview)
5. **2x2 Stats Grid Pattern** (from Vendor Management)
6. **Dynamic Content-Aware Grid Width Pattern** (from Budget Overview) ⭐ NEW
7. **Header Duplication Prevention Pattern** (from Budget Builder) ⭐ NEW

### Unique to Expense Tracker

1. **Dual View Mode Responsiveness**
2. **Collapsible Benchmarks Section** ⭐ UPDATED (chevron-based, no horizontal scroll)
3. **Rich Status Badge Display**
4. **Dynamic Card Width Calculation** ⭐ NEW (adapts to actual expense data)

---

## Implementation Notes

### Critical Implementation Details

1. **BudgetDashboardHubView Update** - Must add `.expenseTracker` to header exclusion list
2. **Dynamic Width Calculation** - Recalculates on data changes for optimal fit
3. **Collapsible Benchmarks** - State managed with `@State private var isExpanded: Bool = true`
4. **No Horizontal Scrolling** - All content uses collapsible or vertical patterns

### Files Modified Summary

| File | Purpose | Changes | Lines |
|------|---------|---------|-------|
| `ExpenseTrackerView.swift` | Main view | GeometryReader, WindowSize, content constraint | ~80 |
| `BudgetDashboardHubView.swift` | Header skip | Add `.expenseTracker` to exclusion list | ~5 |
| `ExpenseTrackerUnifiedHeader.swift` | NEW | Unified header with stats | ~200 |
| `ExpenseFiltersBarV2.swift` | NEW | Responsive filter bar | ~250 |
| `ExpenseCompactCard.swift` | NEW | Compact expense card | ~150 |
| `ExpenseExpandableRow.swift` | NEW | Expandable list row | ~180 |
| `ExpenseListViewV2.swift` | NEW | Updated list view with dynamic width | ~120 |
| `CategoryBenchmarksSectionV2.swift` | NEW | Collapsible benchmarks | ~140 |

**Total:** 8 files (6 new, 2 modified), ~1,125 lines

---

## Status: ✅ APPROVED - READY TO IMPLEMENT

All user feedback has been incorporated:
1. ✅ NO horizontal scrolling - collapsible benchmarks
2. ✅ Header duplication prevention across all budget pages
3. ✅ Dynamic content-aware grid width pattern applied

**Ready to begin implementation.**
