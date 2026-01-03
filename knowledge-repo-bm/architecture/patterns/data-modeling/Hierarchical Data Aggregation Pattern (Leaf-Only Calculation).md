---
title: Hierarchical Data Aggregation Pattern (Leaf-Only Calculation)
type: note
permalink: architecture/patterns/data-modeling/hierarchical-data-aggregation-pattern
tags:
- pattern
- data-modeling
- hierarchical-data
- aggregation
- tree-structure
- parent-child
- calculation
- best-practice
---

# Hierarchical Data Aggregation Pattern (Leaf-Only Calculation)

> **Status:** ✅ PRODUCTION PATTERN  
> **Created:** January 2026  
> **Context:** Expense Categories double-counting bug fix  
> **Problem Solved:** Total allocated calculation counting parent folders twice

---

## Overview

The Hierarchical Data Aggregation Pattern ensures correct calculation of totals in parent-child hierarchies by summing only leaf nodes (nodes without children), avoiding double-counting of parent aggregates.

---

## Problem: Double-Counting Parent Aggregates

### The Trap

In hierarchical data structures (trees), parent nodes often represent aggregates of their children. Summing all nodes including parents results in double-counting.

```swift
// ❌ ANTI-PATTERN: Sums all nodes including parents
private var totalAllocated: Double {
    categories.reduce(0) { $0 + $1.allocatedAmount }
}

// Example data:
// Venue (parent): $10,000
//   ├─ Ceremony: $4,000
//   └─ Reception: $6,000
//
// Incorrect total: $10,000 + $4,000 + $6,000 = $20,000
// Correct total: $4,000 + $6,000 = $10,000
```

### Why This Happens

1. **Parent folders store aggregates** - The parent's `allocatedAmount` is the sum of its children
2. **Naive sum includes parents** - Summing all nodes counts the parent's aggregate AND its children
3. **Result is double (or more)** - Each level of hierarchy multiplies the error

---

## Solution: Sum Only Leaf Nodes

### Core Principle

**In a hierarchy where parents aggregate children, sum only the leaf nodes (nodes without children).**

### Implementation Pattern

```swift
struct MyView: View {
    @State private var cachedTotal: Double = 0
    
    private func recalculateTotal() {
        let items = store.items
        
        // 1. Build set of items that have children: O(n)
        let itemsWithChildren = Set(items.compactMap { $0.parentId })
        
        // 2. Sum only leaf items (items not in the set): O(n)
        cachedTotal = items
            .filter { !itemsWithChildren.contains($0.id) }
            .reduce(0) { $0 + $1.amount }
    }
}
```

---

## Pattern Components

### 1. Identify Leaf Nodes

```swift
// Build set of all parent IDs
let itemsWithChildren = Set(items.compactMap { $0.parentId })

// Filter to leaf nodes only
let leafItems = items.filter { !itemsWithChildren.contains($0.id) }
```

### 2. Sum Leaf Values

```swift
let total = leafItems.reduce(0) { $0 + $1.amount }
```

### 3. Optimize with Cached Set

```swift
@State private var cachedItemsWithChildren: Set<UUID> = []
@State private var cachedTotal: Double = 0

private func recalculateCachedValues() {
    let items = store.items
    
    // Cache the set for reuse
    cachedItemsWithChildren = Set(items.compactMap { $0.parentId })
    
    // Calculate total using cached set
    cachedTotal = items
        .filter { !cachedItemsWithChildren.contains($0.id) }
        .reduce(0) { $0 + $1.amount }
}
```

---

## Real-World Example: Budget Categories

### Data Structure

```
Budget Categories:
├─ Venue (parent) - $10,000 allocated
│  ├─ Ceremony (leaf) - $4,000 allocated
│  └─ Reception (leaf) - $6,000 allocated
├─ Catering (parent) - $15,000 allocated
│  ├─ Food (leaf) - $10,000 allocated
│  └─ Drinks (leaf) - $5,000 allocated
└─ Photography (leaf) - $5,000 allocated

Correct total: $4,000 + $6,000 + $10,000 + $5,000 + $5,000 = $30,000
Incorrect total (all nodes): $10,000 + $4,000 + $6,000 + $15,000 + $10,000 + $5,000 + $5,000 = $55,000
```

### Before (Incorrect)

```swift
struct ExpenseCategoriesView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    private var totalAllocated: Double {
        budgetStore.categoryStore.categories.reduce(0) { $0 + $1.allocatedAmount }
    }
    
    var body: some View {
        Text("Total: \(totalAllocated)")  // Shows $55,000 (wrong!)
    }
}
```

### After (Correct)

```swift
struct ExpenseCategoriesView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    @State private var cachedTotalAllocated: Double = 0
    @State private var categoriesWithChildren: Set<UUID> = []
    
    var body: some View {
        Text("Total: \(cachedTotalAllocated)")  // Shows $30,000 (correct!)
            .task {
                await budgetStore.loadBudgetData(force: false)
                recalculateCachedValues()
            }
    }
    
    private func recalculateCachedValues() {
        let categories = budgetStore.categoryStore.categories
        
        // Build set of categories that have children: O(n)
        categoriesWithChildren = Set(categories.compactMap { $0.parentCategoryId })
        
        // Sum only leaf categories: O(n)
        cachedTotalAllocated = categories
            .filter { !categoriesWithChildren.contains($0.id) }
            .reduce(0) { $0 + $1.allocatedAmount }
    }
}
```

---

## Complexity Analysis

### Naive Approach (Incorrect)

```swift
// O(n) - but gives wrong answer
let total = items.reduce(0) { $0 + $1.amount }
```

### Leaf-Only Approach (Correct)

```swift
// O(n) to build set + O(n) to filter and sum = O(2n) = O(n)
let itemsWithChildren = Set(items.compactMap { $0.parentId })  // O(n)
let total = items
    .filter { !itemsWithChildren.contains($0.id) }  // O(n)
    .reduce(0) { $0 + $1.amount }
```

**Both are O(n), but leaf-only gives the correct answer.**

---

## When to Use This Pattern

### ✅ Use Leaf-Only Calculation When:

| Scenario | Example |
|----------|---------|
| Parent stores aggregate | Budget category parent = sum of subcategories |
| Hierarchical totals | Organization chart with department budgets |
| Tree structures | File system with folder sizes |
| Nested categories | Product categories with subcategories |

### ❌ Don't Use When:

| Scenario | Why Not |
|----------|---------|
| Parents have independent values | Each node has its own distinct value |
| Flat list | No parent-child relationships |
| Parents are metadata only | Parent doesn't store a value |

---

## Variations

### 1. Multi-Level Hierarchies

```swift
// Works for any depth of hierarchy
let itemsWithChildren = Set(items.compactMap { $0.parentId })
let leafItems = items.filter { !itemsWithChildren.contains($0.id) }
let total = leafItems.reduce(0) { $0 + $1.amount }
```

### 2. Conditional Aggregation

```swift
// Sum only leaf items matching a condition
let total = items
    .filter { !itemsWithChildren.contains($0.id) }
    .filter { $0.status == .active }
    .reduce(0) { $0 + $1.amount }
```

### 3. Multiple Aggregates

```swift
// Calculate multiple totals at once
let leafItems = items.filter { !itemsWithChildren.contains($0.id) }

cachedTotalAllocated = leafItems.reduce(0) { $0 + $1.allocatedAmount }
cachedTotalSpent = leafItems.reduce(0) { $0 + $1.spentAmount }
cachedTotalRemaining = cachedTotalAllocated - cachedTotalSpent
```

---

## Testing Strategy

### Unit Tests

```swift
func testTotalAllocated_withHierarchy_sumsOnlyLeafCategories() {
    // Given: Hierarchy with parent and children
    let parent = BudgetCategory(id: UUID(), name: "Venue", allocatedAmount: 10000, parentCategoryId: nil)
    let child1 = BudgetCategory(id: UUID(), name: "Ceremony", allocatedAmount: 4000, parentCategoryId: parent.id)
    let child2 = BudgetCategory(id: UUID(), name: "Reception", allocatedAmount: 6000, parentCategoryId: parent.id)
    
    let categories = [parent, child1, child2]
    
    // When: Calculate total
    let itemsWithChildren = Set(categories.compactMap { $0.parentCategoryId })
    let total = categories
        .filter { !itemsWithChildren.contains($0.id) }
        .reduce(0) { $0 + $1.allocatedAmount }
    
    // Then: Total should be sum of children only
    XCTAssertEqual(total, 10000)  // 4000 + 6000
}

func testTotalAllocated_withoutHierarchy_sumsAllCategories() {
    // Given: Flat list (no parents)
    let cat1 = BudgetCategory(id: UUID(), name: "Venue", allocatedAmount: 10000, parentCategoryId: nil)
    let cat2 = BudgetCategory(id: UUID(), name: "Catering", allocatedAmount: 15000, parentCategoryId: nil)
    
    let categories = [cat1, cat2]
    
    // When: Calculate total
    let itemsWithChildren = Set(categories.compactMap { $0.parentCategoryId })
    let total = categories
        .filter { !itemsWithChildren.contains($0.id) }
        .reduce(0) { $0 + $1.allocatedAmount }
    
    // Then: Total should be sum of all
    XCTAssertEqual(total, 25000)  // 10000 + 15000
}
```

---

## Common Mistakes

### ❌ Mistake 1: Summing All Nodes

```swift
// Wrong: Includes parents
let total = categories.reduce(0) { $0 + $1.allocatedAmount }
```

### ❌ Mistake 2: Filtering by Parent ID Null

```swift
// Wrong: Only gets top-level items, misses nested leaves
let total = categories
    .filter { $0.parentCategoryId == nil }
    .reduce(0) { $0 + $1.allocatedAmount }
```

### ❌ Mistake 3: Recursive Calculation

```swift
// Wrong: Inefficient and complex
func calculateTotal(for category: Category) -> Double {
    let children = categories.filter { $0.parentCategoryId == category.id }
    if children.isEmpty {
        return category.allocatedAmount
    } else {
        return children.reduce(0) { $0 + calculateTotal(for: $1) }
    }
}
```

### ✅ Correct: Leaf-Only Filter

```swift
// Right: Simple, efficient, correct
let itemsWithChildren = Set(categories.compactMap { $0.parentCategoryId })
let total = categories
    .filter { !itemsWithChildren.contains($0.id) }
    .reduce(0) { $0 + $1.allocatedAmount }
```

---

## Related Patterns

- [[Cached Summary Values Pattern]] - Cache the leaf set for performance
- [[Event-Driven Data Loading Pattern]] - When to recalculate aggregates

---

## Key Takeaways

1. **In hierarchies where parents aggregate children, sum only leaf nodes**
2. **Build a set of parent IDs** for O(1) lookup
3. **Filter to items not in the parent set** to get leaves
4. **Cache the parent set** if used multiple times
5. **Test with multi-level hierarchies** to verify correctness

---

## Files Using This Pattern

- `ExpenseCategoriesView.swift` - Budget category totals
- `ExpenseCategoriesSummaryCards.swift` - Summary card calculations

---

## Changelog

| Date | Change | Reason |
|------|--------|--------|
| January 2026 | Pattern identified | Expense Categories double-counting bug |
| January 2026 | Pattern documented | Prevent future calculation errors |

---

**Created:** January 2026  
**Author:** AI Assistant  
**Project:** I Do Blueprint