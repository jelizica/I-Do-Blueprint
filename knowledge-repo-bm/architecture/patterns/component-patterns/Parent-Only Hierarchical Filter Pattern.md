---
title: Parent-Only Hierarchical Filter Pattern
type: note
permalink: architecture/patterns/component-patterns/parent-only-hierarchical-filter-pattern
tags:
- swiftui
- pattern
- filter
- hierarchical-data
- parent-child
- database
- budget-categories
---

# Parent-Only Hierarchical Filter Pattern

> **Status:** ✅ PRODUCTION READY  
> **Created:** January 2026  
> **Context:** Expense Tracker Category Filter  
> **Problem Solved:** Showing 36 categories instead of 11 parent categories

---

## Overview

When working with hierarchical data (parent-child relationships), filters should typically show only parent-level items to avoid overwhelming users and prevent double-counting in aggregations.

---

## Problem

### Scenario

Budget categories have a parent-child structure:
- **Parent:** "Vendors" (no parent_category_id)
- **Children:** "DJ/Music", "Photographer", "Venue" (parent_category_id = Vendors.id)

### Issues with Showing All Categories

1. **Overwhelming UI** - 36 items instead of 11
2. **Confusing hierarchy** - Users don't know which are parents vs children
3. **Double-counting** - Filtering by parent AND child shows duplicates
4. **Inconsistent behavior** - Some items are containers, others are leaf nodes

---

## Solution

Filter to show only parent categories using `parentCategoryId == nil`:

```swift
private var parentCategories: [BudgetCategory] {
    categories.filter { $0.parentCategoryId == nil }
}
```

---

## Database Investigation Pattern

Before implementing hierarchical filters, always investigate the database structure:

```sql
-- Query to understand parent/child structure
SELECT id, category_name, parent_category_id, couple_id
FROM budget_categories 
WHERE couple_id = '<current_couple_id>'
ORDER BY parent_category_id NULLS FIRST, category_name;
```

### Expected Results

| category_name | parent_category_id |
|---------------|-------------------|
| Airline / Travel | NULL (parent) |
| Attire | NULL (parent) |
| Beauty | NULL (parent) |
| Decor | NULL (parent) |
| ... | ... |
| DJ/Music | `<vendors_id>` (child) |
| Photographer | `<vendors_id>` (child) |
| Venue | `<vendors_id>` (child) |

---

## Implementation

### 1. Model Definition

```swift
struct BudgetCategory: Identifiable, Codable {
    let id: UUID
    let categoryName: String
    let parentCategoryId: UUID?  // nil for parent categories
    let coupleId: UUID
    let allocatedAmount: Double
    // ...
}
```

### 2. Filter to Parents Only

```swift
struct CategoryFilter: View {
    let categories: [BudgetCategory]
    @Binding var selectedCategories: Set<UUID>
    
    // Filter to parent categories only
    private var parentCategories: [BudgetCategory] {
        categories.filter { $0.parentCategoryId == nil }
    }
    
    var body: some View {
        Menu {
            ForEach(parentCategories) { category in
                Button {
                    toggleSelection(category.id)
                } label: {
                    HStack {
                        Text(category.categoryName)
                        if selectedCategories.contains(category.id) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Text(displayText)
        }
    }
}
```

### 3. Filtering Items by Parent Category

When filtering items (like expenses), you may need to include items from child categories:

```swift
// Option 1: Filter by parent category only (items directly assigned to parent)
let filtered = expenses.filter { expense in
    selectedCategories.contains(expense.budgetCategoryId)
}

// Option 2: Filter by parent OR any of its children
let filtered = expenses.filter { expense in
    // Check if expense's category is a selected parent
    if selectedCategories.contains(expense.budgetCategoryId) {
        return true
    }
    
    // Check if expense's category's parent is selected
    if let category = categories.first(where: { $0.id == expense.budgetCategoryId }),
       let parentId = category.parentCategoryId,
       selectedCategories.contains(parentId) {
        return true
    }
    
    return false
}
```

---

## Budget Calculation Pattern

When calculating totals from hierarchical categories, **sum only parent categories** to avoid double-counting:

### ❌ Wrong: Sum All Categories

```swift
// This double-counts because parent totals include children
let totalBudget = categories.reduce(0) { $0 + $1.allocatedAmount }
```

### ✅ Correct: Sum Parent Categories Only

```swift
let totalBudget = categories
    .filter { $0.parentCategoryId == nil }  // Parents only
    .reduce(0) { $0 + $1.allocatedAmount }
```

---

## Real-World Example

### Before (Broken)

```swift
// ExpenseFiltersBarV2.swift
ForEach(categories) { category in  // Shows ALL 36 categories
    Button(category.categoryName) {
        selectedCategory = category.id
    }
}
```

### After (Fixed)

```swift
// ExpenseFiltersBarV2.swift
private var parentCategories: [BudgetCategory] {
    categories.filter { $0.parentCategoryId == nil }
}

ForEach(parentCategories) { category in  // Shows only 11 parents
    Button(category.categoryName) {
        toggleSelection(category.id)
    }
}
```

---

## When to Show Children

Sometimes you DO want to show children, but with visual hierarchy:

```swift
Menu {
    ForEach(parentCategories) { parent in
        // Parent as section header
        Section(parent.categoryName) {
            // Children as options
            ForEach(childrenOf(parent)) { child in
                Button(child.categoryName) {
                    selectedCategory = child.id
                }
            }
        }
    }
}

private func childrenOf(_ parent: BudgetCategory) -> [BudgetCategory] {
    categories.filter { $0.parentCategoryId == parent.id }
}
```

---

## Database Schema Considerations

### Recommended Schema

```sql
CREATE TABLE budget_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_name TEXT NOT NULL,
    parent_category_id UUID REFERENCES budget_categories(id),
    couple_id UUID NOT NULL REFERENCES couples(id),
    allocated_amount DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for efficient parent/child queries
CREATE INDEX idx_budget_categories_parent ON budget_categories(parent_category_id);
```

### Query for Parent Categories

```sql
SELECT * FROM budget_categories 
WHERE couple_id = $1 
  AND parent_category_id IS NULL
ORDER BY category_name;
```

### Query for Children of a Parent

```sql
SELECT * FROM budget_categories 
WHERE parent_category_id = $1
ORDER BY category_name;
```

---

## Testing Checklist

- [ ] Query database to confirm parent/child structure
- [ ] Count parent categories (should be ~10-15, not 30+)
- [ ] Verify filter shows only parents
- [ ] Test filtering includes items from child categories (if desired)
- [ ] Verify budget totals don't double-count
- [ ] Test with categories that have no children
- [ ] Test with deeply nested categories (if applicable)

---

## Related Patterns

- [[Multi-Select Filter Pattern]] - How to implement the filter UI
- [[Dynamic Content-Aware Grid Width Pattern]] - Displaying hierarchical data in grids

---

## Summary

| Aspect | Implementation |
|--------|----------------|
| Parent detection | `parentCategoryId == nil` |
| Filter query | `.filter { $0.parentCategoryId == nil }` |
| Budget calculation | Sum parents only |
| Item filtering | Include children of selected parents |
| Database index | On `parent_category_id` column |

---

## Changelog

| Date | Change |
|------|--------|
| January 2026 | Created during Expense Tracker optimization |
| January 2026 | Added budget calculation pattern |
