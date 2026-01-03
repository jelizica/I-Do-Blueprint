---
title: Cached Summary Values Pattern
type: note
permalink: architecture/patterns/performance/cached-summary-values-pattern
tags:
- swiftui
- pattern
- performance
- caching
- state
- optimization
- computed-properties
- best-practice
---

# Cached Summary Values Pattern

> **Status:** ✅ PRODUCTION PATTERN  
> **Created:** January 2026  
> **Context:** Expense Categories scroll freeze fix  
> **Problem Solved:** Expensive calculations on every scroll frame

---

## Overview

The Cached Summary Values Pattern pre-computes expensive aggregate calculations and stores them in `@State` variables, preventing recalculation on every SwiftUI render cycle.

---

## Problem: Computed Properties Recalculate on Every Render

### The Performance Trap

```swift
// ❌ ANTI-PATTERN: Computed property accessing store
private var totalSpent: Double {
    budgetStore.categoryStore.categories.reduce(0) { total, category in
        total + budgetStore.expenseStore.expenses
            .filter { $0.categoryId == category.id }
            .reduce(0) { $0 + $1.amount }
    }
}

var body: some View {
    Text("Total: \(totalSpent.formatted(.currency(code: "USD")))")
}
```

### Why This Causes Scroll Freeze

1. **SwiftUI renders on every scroll frame** (60 FPS = 60 times per second)
2. **Computed property recalculates** on every access
3. **Store access triggers** potential `objectWillChange` notifications
4. **Nested loops** create O(categories × expenses) complexity
5. **Accumulates over time** → UI becomes unresponsive during scrolling

### Complexity Analysis

```swift
// O(n × m) complexity - VERY EXPENSIVE
private var totalSpent: Double {
    categories.reduce(0) { total, category in  // O(n)
        total + expenses
            .filter { $0.categoryId == category.id }  // O(m)
            .reduce(0) { $0 + $1.amount }
    }
}

// With 50 categories and 200 expenses:
// 50 × 200 = 10,000 operations per render
// At 60 FPS: 600,000 operations per second!
```

---

## Solution: Pre-Compute and Cache

### Core Principle

**Calculate once, cache in @State, reuse until data changes.**

### Implementation Pattern

```swift
struct MyView: View {
    @EnvironmentObject var store: MyStoreV2
    
    // Cached summary values
    @State private var cachedTotalCount: Int = 0
    @State private var cachedTotalSpent: Double = 0
    @State private var cachedAverageAmount: Double = 0
    @State private var cachedSpentByCategory: [UUID: Double] = [:]
    
    var body: some View {
        VStack {
            Text("Total: \(cachedTotalCount)")
            Text("Spent: \(cachedTotalSpent.formatted(.currency(code: "USD")))")
            Text("Average: \(cachedAverageAmount.formatted(.currency(code: "USD")))")
        }
        .task {
            await store.loadData(force: false)
            recalculateCachedValues()
        }
        .onChange(of: searchText) { _, _ in
            recalculateCachedValues()
        }
    }
    
    private func recalculateCachedValues() {
        // Single store access
        let items = store.items
        
        // Pure computation (no store access)
        cachedTotalCount = items.count
        cachedTotalSpent = items.reduce(0) { $0 + $1.amount }
        cachedAverageAmount = cachedTotalCount > 0 ? cachedTotalSpent / Double(cachedTotalCount) : 0
        
        // Build lookup dictionary
        var spentDict: [UUID: Double] = [:]
        for item in items {
            spentDict[item.categoryId, default: 0] += item.amount
        }
        cachedSpentByCategory = spentDict
    }
}
```

---

## Pattern Components

### 1. Cached State Variables

```swift
// Summary metrics
@State private var cachedTotalCount: Int = 0
@State private var cachedTotalAllocated: Double = 0
@State private var cachedTotalSpent: Double = 0
@State private var cachedOverBudgetCount: Int = 0

// Lookup dictionaries for O(1) access
@State private var cachedSpentByCategory: [UUID: Double] = [:]
@State private var cachedAllocationByCategory: [UUID: Double] = [:]
```

### 2. Recalculation Function

```swift
private func recalculateCachedValues() {
    // 1. Single store access at start
    let categories = budgetStore.categoryStore.categories
    let expenses = budgetStore.expenseStore.expenses
    
    // 2. Build lookup dictionaries (O(n) pass)
    var spentDict: [UUID: Double] = [:]
    for expense in expenses {
        if let categoryId = expense.budgetCategoryId {
            spentDict[categoryId, default: 0] += expense.amount
        }
    }
    
    // 3. Calculate aggregates (O(n) pass)
    var totalAllocated: Double = 0
    var overBudgetCount: Int = 0
    
    for category in categories {
        totalAllocated += category.allocatedAmount
        
        let spent = spentDict[category.id] ?? 0
        if spent > category.allocatedAmount && category.allocatedAmount > 0 {
            overBudgetCount += 1
        }
    }
    
    // 4. Update cached state
    cachedTotalCategories = categories.count
    cachedTotalAllocated = totalAllocated
    cachedTotalSpent = spentDict.values.reduce(0, +)
    cachedOverBudgetCount = overBudgetCount
    cachedSpentByCategory = spentDict
}
```

### 3. Update Triggers

```swift
.task {
    await store.loadData(force: false)
    recalculateCachedValues()  // Initial calculation
}
.onChange(of: searchText) { _, _ in
    recalculateCachedValues()  // Recalculate on filter change
}
.sheet(isPresented: $showModal, onDismiss: {
    recalculateCachedValues()  // Recalculate after edit
})
```

---

## Optimization Techniques

### 1. Build Lookup Dictionaries

```swift
// ❌ BAD: O(n × m) - nested loops
private var totalSpent: Double {
    categories.reduce(0) { total, category in
        total + expenses
            .filter { $0.categoryId == category.id }
            .reduce(0) { $0 + $1.amount }
    }
}

// ✅ GOOD: O(n + m) - single pass each
private func recalculateCachedValues() {
    let categories = store.categories
    let expenses = store.expenses
    
    // Build dictionary: O(m)
    var spentDict: [UUID: Double] = [:]
    for expense in expenses {
        spentDict[expense.categoryId, default: 0] += expense.amount
    }
    
    // Calculate total: O(n)
    cachedTotalSpent = categories.reduce(0) { total, category in
        total + (spentDict[category.id] ?? 0)  // O(1) lookup
    }
}
```

### 2. Pass Pre-Computed Data to Children

```swift
// ✅ GOOD: Pass dictionary to child views
ForEach(categories) { category in
    CategoryRow(
        category: category,
        spent: cachedSpentByCategory[category.id] ?? 0  // O(1) lookup
    )
}

// Child view doesn't need to recalculate
struct CategoryRow: View {
    let category: Category
    let spent: Double  // Pre-computed
    
    var body: some View {
        HStack {
            Text(category.name)
            Text(spent.formatted(.currency(code: "USD")))
        }
    }
}
```

### 3. Filter Leaf Categories Only

```swift
// ❌ BAD: Double-counting parent folders
private var totalAllocated: Double {
    categories.reduce(0) { $0 + $1.allocatedAmount }
}

// ✅ GOOD: Only sum leaf categories
private func recalculateCachedValues() {
    let categories = store.categories
    
    // Build set of categories that have children: O(n)
    let categoriesWithChildren = Set(categories.compactMap { $0.parentCategoryId })
    
    // Sum only leaf categories: O(n)
    cachedTotalAllocated = categories
        .filter { !categoriesWithChildren.contains($0.id) }
        .reduce(0) { $0 + $1.allocatedAmount }
}
```

---

## Real-World Example: ExpenseCategoriesView

### Before (Slow)

```swift
struct ExpenseCategoriesView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    // Computed properties - recalculate on every render
    private var totalCategories: Int {
        budgetStore.categoryStore.categories.count
    }
    
    private var totalSpent: Double {
        budgetStore.categoryStore.categories.reduce(0) { total, category in
            total + budgetStore.categoryStore.spentAmount(
                for: category.id,
                expenses: budgetStore.expenseStore.expenses
            )
        }
    }
    
    var body: some View {
        ScrollView {
            Text("Categories: \(totalCategories)")  // Recalculates on scroll
            Text("Spent: \(totalSpent)")  // Recalculates on scroll
        }
    }
}
```

**Result:** Scroll freeze after a few seconds

### After (Fast)

```swift
struct ExpenseCategoriesView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    // Cached values - calculated once
    @State private var cachedTotalCategories: Int = 0
    @State private var cachedTotalSpent: Double = 0
    @State private var cachedSpentByCategory: [UUID: Double] = [:]
    
    var body: some View {
        ScrollView {
            Text("Categories: \(cachedTotalCategories)")  // No recalculation
            Text("Spent: \(cachedTotalSpent)")  // No recalculation
            
            ForEach(categories) { category in
                CategoryRow(
                    category: category,
                    spent: cachedSpentByCategory[category.id] ?? 0
                )
            }
        }
        .task {
            await budgetStore.loadBudgetData(force: false)
            recalculateCachedValues()
        }
    }
    
    private func recalculateCachedValues() {
        let categories = budgetStore.categoryStore.categories
        let expenses = budgetStore.expenseStore.expenses
        
        // Build spent dictionary once: O(m)
        var spentDict: [UUID: Double] = [:]
        for expense in expenses {
            if let categoryId = expense.budgetCategoryId {
                spentDict[categoryId, default: 0] += expense.amount
            }
        }
        
        // Calculate totals: O(n)
        cachedTotalCategories = categories.count
        cachedTotalSpent = spentDict.values.reduce(0, +)
        cachedSpentByCategory = spentDict
    }
}
```

**Result:** Smooth scrolling, no freeze

---

## Performance Comparison

### Computed Properties (Before)

| Metric | Value |
|--------|-------|
| Complexity | O(n × m) per render |
| Renders per second | 60 (during scroll) |
| Operations per second | 600,000 (50 categories × 200 expenses × 60 FPS) |
| Result | Freeze after 5 seconds |

### Cached Values (After)

| Metric | Value |
|--------|-------|
| Complexity | O(n + m) once, then O(1) per render |
| Recalculations | Only on user actions (~5 per minute) |
| Operations per second | 0 (during scroll) |
| Result | Smooth 60 FPS scrolling |

---

## When to Recalculate

### ✅ Valid Recalculation Triggers

| Trigger | Example | Frequency |
|---------|---------|-----------|
| Initial load | `.task` | Once per view lifecycle |
| Search input | `.onChange(of: searchText)` | ~1-2 per second while typing |
| Filter toggle | `.onChange(of: filterState)` | Once per toggle |
| Modal dismiss | `.sheet(onDismiss:)` | Once per modal |
| After mutation | Post-delete/create | Once per operation |

### ❌ Invalid Recalculation Triggers

| Anti-Pattern | Why It's Bad |
|--------------|--------------|
| On every render | Computed properties recalculate 60 times per second |
| Timer polling | Continuous recalculation even when idle |
| On scroll | Triggers 60 times per second during scrolling |

---

## Testing Checklist

- [ ] Profile with Instruments Time Profiler
- [ ] Verify no hot paths in render cycle
- [ ] Test scrolling for 30+ seconds
- [ ] Monitor CPU usage (should stay < 20%)
- [ ] Check memory usage (should be stable)
- [ ] Verify calculations update on user actions
- [ ] Test with large datasets (100+ items)

---

## Related Patterns

- [[Event-Driven Data Loading Pattern]] - When to trigger recalculation
- [[WindowSize Enum and Responsive Breakpoints Pattern]] - Efficient geometry calculations

---

## Anti-Patterns to Avoid

### ❌ Computed Properties Accessing Store

```swift
private var expensiveValue: Double {
    store.items.reduce(0) { /* expensive operation */ }
}
```

### ❌ Nested Loops in Computed Properties

```swift
private var total: Double {
    categories.reduce(0) { total, category in
        total + expenses.filter { $0.categoryId == category.id }.reduce(0) { $0 + $1.amount }
    }
}
```

### ❌ Store Access in View Body

```swift
var body: some View {
    let items = store.items  // ⚠️ Recalculates on every render
    Text("Count: \(items.count)")
}
```

---

## Key Takeaways

1. **Cache expensive calculations** in `@State` variables
2. **Build lookup dictionaries** for O(1) access
3. **Pass pre-computed data** to child views
4. **Recalculate only on user actions**, not on every render
5. **Profile with Instruments** to verify performance
6. **Test with large datasets** to catch performance issues early

---

## Files Using This Pattern

- `ExpenseCategoriesView.swift` - Cached summary values
- `BudgetOverviewDashboardViewV2.swift` - Cached budget metrics
- `GuestManagementViewV4.swift` - Cached guest statistics

---

## Changelog

| Date | Change | Reason |
|------|--------|--------|
| January 2026 | Pattern identified | Expense Categories scroll freeze |
| January 2026 | Pattern documented | Prevent future performance issues |

---

**Created:** January 2026  
**Author:** AI Assistant  
**Project:** I Do Blueprint