---
title: Search Filtering with View Mode Awareness Pattern
type: note
permalink: architecture/patterns/component-patterns/search-filtering-with-view-mode-awareness-pattern
tags:
- swiftui
- pattern
- search
- filtering
- view-mode
- computed-properties
- ux
---

# Search Filtering with View Mode Awareness Pattern

> **Status:** ✅ PRODUCTION READY  
> **Created:** January 2026  
> **Context:** Payment Schedule Optimization Session  
> **Problem Solved:** Search that works across multiple view modes (Individual/Plans, List/Grid, etc.)

---

## Overview

The Search Filtering with View Mode Awareness Pattern provides a standardized approach for implementing search functionality that respects the current view mode. When a page has multiple ways to display data (e.g., Individual payments vs. Payment Plans), the search should filter the appropriate data set based on which view is active.

---

## Problem

Many pages have multiple view modes:
- **Individual vs. Grouped** (payments, expenses)
- **List vs. Grid** (guests, vendors)
- **Timeline vs. Calendar** (tasks, events)

A naive search implementation might:
1. Only filter one view mode (search works in List but not Grid)
2. Filter the wrong data (search filters Individual data while showing Plans)
3. Require separate search states for each mode (confusing UX)

---

## Solution

1. **Single search state** - One `@State var searchQuery` for all modes
2. **Mode-aware computed properties** - Separate filtered data for each view mode
3. **Conditional rendering** - Use the appropriate filtered data based on current mode

---

## Implementation

### Step 1: Define Search State and View Mode

```swift
struct MultiModeListView: View {
    // Search state (shared across all modes)
    @State private var searchQuery: String = ""
    
    // View mode state
    @State private var showGroupedView: Bool = false
    
    // Raw data from store
    @EnvironmentObject private var store: DataStore
    
    var body: some View {
        VStack(spacing: 0) {
            // Search header (always visible)
            SearchHeader(searchQuery: $searchQuery)
            
            // View mode toggle
            ViewModeToggle(showGroupedView: $showGroupedView)
            
            // Content based on mode
            if showGroupedView {
                GroupedListView(items: filteredGroupedItems)
            } else {
                IndividualListView(items: filteredIndividualItems)
            }
        }
    }
}
```

### Step 2: Create Mode-Aware Filtered Computed Properties

```swift
extension MultiModeListView {
    // MARK: - Individual Mode Filtering
    
    /// Filtered items for Individual view mode
    private var filteredIndividualItems: [Item] {
        let items = store.items
        
        guard !searchQuery.isEmpty else {
            return items
        }
        
        let query = searchQuery.lowercased()
        return items.filter { item in
            item.title.lowercased().contains(query) ||
            item.description.lowercased().contains(query) ||
            item.category.lowercased().contains(query) ||
            formatCurrency(item.amount).contains(query)
        }
    }
    
    // MARK: - Grouped Mode Filtering
    
    /// Filtered groups for Grouped view mode
    private var filteredGroupedItems: [ItemGroup] {
        let groups = store.itemGroups
        
        guard !searchQuery.isEmpty else {
            return groups
        }
        
        let query = searchQuery.lowercased()
        return groups.filter { group in
            // Filter by group name
            group.name.lowercased().contains(query) ||
            // Or by any item within the group
            group.items.contains { item in
                item.title.lowercased().contains(query) ||
                item.description.lowercased().contains(query)
            }
        }
    }
}
```

### Step 3: Handle Different Grouping Strategies

When grouped view has multiple grouping options:

```swift
enum GroupingStrategy: String, CaseIterable {
    case byCategory = "By Category"
    case byVendor = "By Vendor"
    case byDate = "By Date"
}

extension MultiModeListView {
    @State private var groupingStrategy: GroupingStrategy = .byCategory
    
    /// Filtered groups based on current grouping strategy
    private var filteredGroupedItems: [ItemGroup] {
        let groups: [ItemGroup]
        
        switch groupingStrategy {
        case .byCategory:
            groups = store.itemsByCategory
        case .byVendor:
            groups = store.itemsByVendor
        case .byDate:
            groups = store.itemsByDate
        }
        
        guard !searchQuery.isEmpty else {
            return groups
        }
        
        let query = searchQuery.lowercased()
        return groups.filter { group in
            group.name.lowercased().contains(query) ||
            group.items.contains { item in
                item.title.lowercased().contains(query)
            }
        }
    }
}
```

---

## Real-World Example: Payment Schedule

```swift
struct PaymentScheduleView: View {
    @State private var searchQuery: String = ""
    @State private var showPlanView: Bool = false
    @State private var groupingStrategy: PaymentGroupingStrategy = .byPlanId
    
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    
    // MARK: - Individual View Filtering
    
    private var filteredPayments: [PaymentSchedule] {
        let payments = budgetStore.paymentSchedules
        
        guard !searchQuery.isEmpty else {
            return payments
        }
        
        let query = searchQuery.lowercased()
        return payments.filter { payment in
            payment.vendor.lowercased().contains(query) ||
            (payment.notes ?? "").lowercased().contains(query) ||
            formatCurrency(payment.paymentAmount).contains(query)
        }
    }
    
    // MARK: - Plans View Filtering (By Plan ID)
    
    private var filteredPaymentPlanSummaries: [PaymentPlanSummary] {
        let summaries = budgetStore.paymentPlanSummaries
        
        guard !searchQuery.isEmpty else {
            return summaries
        }
        
        let query = searchQuery.lowercased()
        return summaries.filter { summary in
            summary.vendor.lowercased().contains(query) ||
            summary.expenseName.lowercased().contains(query)
        }
    }
    
    // MARK: - Plans View Filtering (By Expense/Vendor)
    
    private var filteredPaymentPlanGroups: [PaymentPlanGroup] {
        let groups: [PaymentPlanGroup]
        
        switch groupingStrategy {
        case .byExpense:
            groups = budgetStore.paymentPlansByExpense
        case .byVendor:
            groups = budgetStore.paymentPlansByVendor
        default:
            return []  // Not applicable for this grouping
        }
        
        guard !searchQuery.isEmpty else {
            return groups
        }
        
        let query = searchQuery.lowercased()
        return groups.filter { group in
            group.groupName.lowercased().contains(query) ||
            group.plans.contains { plan in
                plan.vendor.lowercased().contains(query)
            }
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        if showPlanView {
            // Use appropriate filtered data based on grouping strategy
            switch groupingStrategy {
            case .byPlanId:
                PaymentPlansListView(summaries: filteredPaymentPlanSummaries)
            case .byExpense, .byVendor:
                PaymentPlanGroupsView(groups: filteredPaymentPlanGroups)
            }
        } else {
            IndividualPaymentsListView(payments: filteredPayments)
        }
    }
}
```

---

## Search Field Best Practices

### Searchable Fields by Domain

| Domain | Recommended Searchable Fields |
|--------|------------------------------|
| Payments | vendor, notes, amount (formatted) |
| Expenses | name, vendor, category, notes |
| Guests | name, email, phone, group, notes |
| Vendors | name, category, contact, notes |
| Tasks | title, description, assignee |

### Amount/Currency Search

Include formatted currency in search:

```swift
// Allow searching by amount
formatCurrency(item.amount).contains(query)

// Helper function
private func formatCurrency(_ amount: Double) -> String {
    NumberFormatter.currencyShort.string(from: NSNumber(value: amount)) ?? "$0"
}
```

### Case-Insensitive Search

Always use `.lowercased()` for both query and field:

```swift
let query = searchQuery.lowercased()
item.title.lowercased().contains(query)
```

---

## Empty State Handling

Handle empty search results gracefully:

```swift
@ViewBuilder
private var contentView: some View {
    let items = showGroupedView ? filteredGroupedItems : filteredIndividualItems
    
    if items.isEmpty {
        if searchQuery.isEmpty {
            // No data at all
            ContentUnavailableView(
                "No Items",
                systemImage: "tray",
                description: Text("Add items to get started")
            )
        } else {
            // No search results
            ContentUnavailableView(
                "No Results",
                systemImage: "magnifyingglass",
                description: Text("No items match '\(searchQuery)'")
            )
        }
    } else {
        // Show filtered content
        ListView(items: items)
    }
}
```

---

## Performance Considerations

### For Large Data Sets

Use `@State` with debouncing for search:

```swift
@State private var searchQuery: String = ""
@State private var debouncedQuery: String = ""

var body: some View {
    TextField("Search...", text: $searchQuery)
        .onChange(of: searchQuery) { _, newValue in
            // Debounce search
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)  // 300ms
                if searchQuery == newValue {
                    debouncedQuery = newValue
                }
            }
        }
    
    // Use debouncedQuery for filtering
    ListView(items: filteredItems(query: debouncedQuery))
}
```

### Memoization

For expensive filtering, consider caching:

```swift
// Cache filtered results
@State private var cachedFilteredItems: [Item]?
@State private var lastSearchQuery: String = ""
@State private var lastViewMode: Bool = false

private var filteredItems: [Item] {
    // Return cached if inputs haven't changed
    if searchQuery == lastSearchQuery && showGroupedView == lastViewMode,
       let cached = cachedFilteredItems {
        return cached
    }
    
    // Compute and cache
    let result = computeFilteredItems()
    cachedFilteredItems = result
    lastSearchQuery = searchQuery
    lastViewMode = showGroupedView
    return result
}
```

---

## When to Use

### ✅ Use This Pattern When:
- Page has multiple view modes (Individual/Grouped, List/Grid)
- Search should work across all modes
- Different modes show different data structures
- You want consistent search UX across modes

### ❌ Don't Use When:
- Page has only one view mode
- Each mode should have independent search
- Search is handled by backend/API

---

## Related Patterns

- [[Static Header with Contextual Information Pattern]] - Where search bar lives
- [[WindowSize Enum and Responsive Breakpoints Pattern]] - Responsive search layout
- [[Collapsible Section Pattern]] - Alternative to view mode toggle

---

## Real-World Implementations

- `PaymentScheduleView.swift` - Individual/Plans with multiple grouping strategies
- `ExpenseTrackerView.swift` - List/Card view modes
- `GuestManagementViewV4.swift` - List/Grid view modes

---

## Summary

| Aspect | Implementation |
|--------|----------------|
| Search state | Single `@State var searchQuery` |
| Filtering | Separate computed property per view mode |
| Query handling | `.lowercased()` for case-insensitive |
| Empty state | Different messages for no data vs. no results |
| Performance | Debounce for large data sets |

---

## Changelog

| Date | Change |
|------|--------|
| January 2026 | Created during Payment Schedule optimization |
| January 2026 | Added grouping strategy support |