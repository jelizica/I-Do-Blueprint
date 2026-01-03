---
title: Event-Driven Data Loading Pattern (Anti-Timer Polling)
type: note
permalink: architecture/patterns/performance/event-driven-data-loading-pattern
tags:
- swiftui
- pattern
- performance
- anti-pattern
- data-loading
- timer-polling
- event-driven
- best-practice
- environmentobject
---

# Event-Driven Data Loading Pattern (Anti-Timer Polling)

> **Status:** ✅ PRODUCTION PATTERN  
> **Created:** January 2026  
> **Context:** Expense Categories freeze bug fix  
> **Problem Solved:** App freeze after ~5 minutes due to timer-based polling

---

## Overview

The Event-Driven Data Loading Pattern ensures SwiftUI views load data once on appear and update only in response to explicit user actions, avoiding the performance pitfalls of continuous timer-based polling.

---

## Problem: Timer-Based Polling Anti-Pattern

### The Deadly Combination

```swift
// ❌ ANTI-PATTERN: Timer-based polling
var body: some View {
    content
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            recalculateSummaryValues()
        }
}

private func recalculateSummaryValues() {
    // Access store properties
    let categories = budgetStore.categoryStore.categories  // ⚠️ Triggers objectWillChange
    // ... calculations
}
```

### Why This Causes Freezes

1. **Timer fires every 0.5s** → calls `recalculateSummaryValues()`
2. **Store property access** → `budgetStore.categoryStore.categories` triggers `objectWillChange`
3. **objectWillChange forwarding** → `categoryStore.objectWillChange` is forwarded to `budgetStore.objectWillChange` via Combine sinks in `BudgetStoreV2.init()`
4. **@EnvironmentObject subscription** → SwiftUI re-renders view on `objectWillChange`
5. **Feedback loop accumulates** → Over ~5 minutes, this overwhelms the system

### Real-World Impact

- App freezes completely after ~5 minutes
- CPU usage spikes to 100%
- UI becomes unresponsive
- Requires force quit

---

## Solution: Event-Driven Loading

### Core Principle

**Load data once on appear, update only on explicit user actions.**

### Implementation Pattern

```swift
struct MyView: View {
    @EnvironmentObject var store: MyStoreV2
    @State private var cachedData: [Item] = []
    
    var body: some View {
        content
            .task {
                // Load once on appear
                await store.loadData(force: false)
                recalculateCachedValues()
            }
            .onChange(of: searchText) { _, _ in
                // Update on user action
                recalculateCachedValues()
            }
            .onChange(of: filterToggle) { _, _ in
                // Update on user action
                recalculateCachedValues()
            }
            .sheet(isPresented: $showModal, onDismiss: {
                // Update after modal closes
                recalculateCachedValues()
            })
    }
    
    private func recalculateCachedValues() {
        // Single store access at start
        let items = store.items
        
        // Pure computation (no store access)
        cachedData = items.filter { /* ... */ }
    }
}
```

---

## Pattern Components

### 1. Initial Load with `.task`

```swift
.task {
    await store.loadData(force: false)  // Use cached data if available
    recalculateCachedValues()
}
```

**Why `.task` instead of `.onAppear`:**
- Supports async/await naturally
- Automatically cancels on view disappear
- Runs once per view lifecycle

### 2. User Action Triggers

```swift
// Search input
.onChange(of: searchText) { _, _ in
    recalculateCachedValues()
}

// Filter toggle
.onChange(of: showOnlyProblems) { _, _ in
    recalculateCachedValues()
}

// Modal dismissal
.sheet(isPresented: $showModal, onDismiss: {
    recalculateCachedValues()
})
```

### 3. Mutation Callbacks

```swift
private func deleteItem(_ item: Item) async {
    await store.deleteItem(item)
    recalculateCachedValues()  // Update after mutation
}
```

### 4. Cached State

```swift
@State private var cachedTotalCount: Int = 0
@State private var cachedFilteredItems: [Item] = []
@State private var cachedMetrics: [String: Double] = [:]

private func recalculateCachedValues() {
    // Single store access
    let items = store.items
    
    // Pure computation
    cachedTotalCount = items.count
    cachedFilteredItems = items.filter { /* ... */ }
    cachedMetrics = calculateMetrics(items)
}
```

---

## Comparison: Working vs Broken Views

### ✅ Working Views (Event-Driven)

**ExpenseTrackerView:**
```swift
.task {
    await budgetStore.loadBudgetData(force: false)
}
```

**PaymentScheduleView:**
```swift
.task {
    await budgetStore.loadBudgetData(force: false)
}
```

**BudgetDevelopmentView:**
```swift
.task {
    await budgetStore.loadBudgetData(force: false)
}
```

### ❌ Broken View (Timer Polling)

**ExpenseCategoriesView (before fix):**
```swift
.onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
    recalculateSummaryValues()
}
```

---

## When to Update Data

### ✅ Valid Update Triggers

| Trigger | Example | Rationale |
|---------|---------|-----------|
| View appears | `.task` | Initial load |
| User types | `.onChange(of: searchText)` | Filter results |
| User toggles filter | `.onChange(of: filterState)` | Apply filter |
| Modal closes | `.sheet(onDismiss:)` | Refresh after edit |
| Delete completes | After `await store.delete()` | Reflect changes |
| Create completes | After `await store.create()` | Show new item |

### ❌ Invalid Update Triggers

| Anti-Pattern | Why It's Bad |
|--------------|--------------|
| Timer polling | Creates feedback loop with `@EnvironmentObject` |
| `.onReceive(publisher)` on store | Triggers on every store change |
| Computed property accessing store | Recalculates on every render |
| Background task polling | Wastes resources, causes race conditions |

---

## Performance Optimization

### Pre-Compute Expensive Operations

```swift
// ❌ BAD: Compute on every access
private var totalSpent: Double {
    budgetStore.categoryStore.categories.reduce(0) { total, category in
        total + budgetStore.expenseStore.expenses
            .filter { $0.categoryId == category.id }
            .reduce(0) { $0 + $1.amount }
    }
}

// ✅ GOOD: Pre-compute once, cache result
@State private var cachedTotalSpent: Double = 0

private func recalculateCachedValues() {
    let categories = budgetStore.categoryStore.categories
    let expenses = budgetStore.expenseStore.expenses
    
    // Build lookup dictionary once (O(n))
    var spentByCategory: [UUID: Double] = [:]
    for expense in expenses {
        spentByCategory[expense.categoryId, default: 0] += expense.amount
    }
    
    // Calculate total (O(n))
    cachedTotalSpent = categories.reduce(0) { total, category in
        total + (spentByCategory[category.id] ?? 0)
    }
}
```

### Pass Pre-Computed Data to Children

```swift
// ✅ GOOD: Pass dictionary to child views
CategorySectionViewV2(
    category: category,
    spentByCategory: cachedSpentByCategory  // O(1) lookup in child
)

// Child view
struct CategorySectionViewV2: View {
    let category: Category
    let spentByCategory: [UUID: Double]
    
    private var spent: Double {
        spentByCategory[category.id] ?? 0  // O(1) lookup
    }
}
```

---

## Real-World Example: ExpenseCategoriesView Fix

### Before (Broken)

```swift
struct ExpenseCategoriesView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    var body: some View {
        content
            .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                recalculateSummaryValues()
            }
    }
    
    private func recalculateSummaryValues() {
        Task.detached {
            let categories = await budgetStore.categoryStore.categories  // ⚠️ Triggers objectWillChange
            // ... calculations
        }
    }
}
```

**Result:** App freezes after ~5 minutes

### After (Fixed)

```swift
struct ExpenseCategoriesView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    @State private var cachedTotalCategories: Int = 0
    @State private var cachedTotalSpent: Double = 0
    @State private var cachedSpentByCategory: [UUID: Double] = [:]
    
    var body: some View {
        content
            .task {
                await budgetStore.loadBudgetData(force: false)
                recalculateCachedValues()
            }
            .onChange(of: searchText) { _, _ in
                recalculateCachedValues()
            }
            .onChange(of: showOnlyOverBudget) { _, _ in
                recalculateCachedValues()
            }
            .sheet(isPresented: $showAddCategory, onDismiss: {
                recalculateCachedValues()
            })
    }
    
    private func recalculateCachedValues() {
        // Single store access
        let categories = budgetStore.categoryStore.categories
        let expenses = budgetStore.expenseStore.expenses
        
        // Build lookup dictionary once
        var spentDict: [UUID: Double] = [:]
        for expense in expenses {
            if let categoryId = expense.budgetCategoryId {
                spentDict[categoryId, default: 0] += expense.amount
            }
        }
        
        // Cache results
        cachedTotalCategories = categories.count
        cachedTotalSpent = spentDict.values.reduce(0, +)
        cachedSpentByCategory = spentDict
    }
}
```

**Result:** No freeze, smooth performance

---

## Debugging Timer Polling Issues

### Symptoms

- App freezes after several minutes
- CPU usage spikes
- UI becomes unresponsive
- Memory usage grows over time

### Diagnostic Steps

1. **Search for timer polling:**
   ```bash
   grep -r "Timer.publish" Views/
   grep -r "onReceive.*Timer" Views/
   ```

2. **Check for store access in timers:**
   ```swift
   // Look for patterns like:
   .onReceive(timer) { _ in
       let data = store.property  // ⚠️ Red flag
   }
   ```

3. **Compare with working views:**
   - Check how similar views handle data loading
   - Look for `.task` instead of `.onReceive`

4. **Profile with Instruments:**
   - Time Profiler: Look for hot paths in timer callbacks
   - Allocations: Check for memory growth over time

---

## Migration Checklist

When converting timer-based polling to event-driven:

- [ ] Remove `Timer.publish` and `.onReceive`
- [ ] Add `.task` for initial load
- [ ] Add `.onChange` for user actions
- [ ] Add `onDismiss` callbacks for modals
- [ ] Add post-mutation updates
- [ ] Cache expensive computations in `@State`
- [ ] Pre-compute lookup dictionaries
- [ ] Pass pre-computed data to child views
- [ ] Test for 10+ minutes to verify no freeze
- [ ] Profile with Instruments to confirm

---

## Related Patterns

- [[WindowSize Enum and Responsive Breakpoints Pattern]] - Efficient geometry calculations
- [[Cached Summary Values Pattern]] - Performance optimization for computed properties

---

## Anti-Patterns to Avoid

### ❌ Timer Polling with Store Access

```swift
.onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
    updateFromStore()
}
```

### ❌ Computed Properties Accessing Store

```swift
private var expensiveCalculation: Double {
    store.items.reduce(0) { /* expensive operation */ }
}
```

### ❌ Background Task Polling

```swift
Task {
    while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))
        await updateData()
    }
}
```

---

## Key Takeaways

1. **Never use timer-based polling** in SwiftUI views with `@EnvironmentObject` subscriptions
2. **Load data once** on view appear with `.task`
3. **Update only on user actions** (search, filter, modal dismiss, mutations)
4. **Cache expensive calculations** in `@State` variables
5. **Pre-compute lookup dictionaries** for O(1) access in child views
6. **Follow working views pattern** - check how similar views handle data loading

---

## Files Using This Pattern

### Correct Implementations
- `ExpenseTrackerView.swift` - Event-driven loading
- `PaymentScheduleView.swift` - Event-driven loading
- `BudgetDevelopmentView.swift` - Event-driven loading
- `ExpenseCategoriesView.swift` - Fixed to use event-driven loading

### Historical Anti-Pattern (Fixed)
- `ExpenseCategoriesView.swift` (before commit `4e8facb`) - Timer polling

---

## Changelog

| Date | Change | Reason |
|------|--------|--------|
| January 2026 | Pattern identified | Expense Categories freeze bug |
| January 2026 | Pattern documented | Prevent future occurrences |

---

**Created:** January 2026  
**Author:** AI Assistant  
**Project:** I Do Blueprint