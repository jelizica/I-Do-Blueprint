---
title: Multi-Select Filter Pattern
type: note
permalink: architecture/patterns/component-patterns/multi-select-filter-pattern
tags:
- swiftui
- pattern
- filter
- multi-select
- set-uuid
- ui-component
- state-management
---

# Multi-Select Filter Pattern

> **Status:** ✅ PRODUCTION READY  
> **Created:** January 2026  
> **Context:** Expense Tracker Category Filter Implementation

---

## Overview

The Multi-Select Filter Pattern provides a standardized approach for implementing filters that allow users to select multiple items from a list. It uses `Set<UUID>` for efficient state management and provides a consistent display pattern showing selected count.

---

## Problem

Single-select filters (`UUID?`) are limiting when users need to filter by multiple criteria simultaneously. Common issues with naive implementations:

1. **Inefficient lookups** - Using arrays for selection state
2. **Inconsistent display** - Different patterns across the app
3. **Complex state management** - Unclear toggle/clear logic
4. **Poor UX** - No indication of how many items are selected

---

## Solution

Use `Set<UUID>` for selection state with a standardized display pattern:
- **No selection:** "Category"
- **1 selected:** "Venue"
- **2+ selected:** "Venue +2 more"

---

## Implementation

### 1. State Declaration

```swift
// In parent view
@State private var selectedCategories: Set<UUID> = []
```

### 2. Display Text Logic

```swift
private var displayText: String {
    if selectedCategories.isEmpty {
        return "Category"  // Placeholder when nothing selected
    } else if selectedCategories.count == 1 {
        return firstCategoryName  // Show the single selected item
    } else {
        return "\(firstCategoryName) +\(selectedCategories.count - 1) more"
    }
}

private var firstCategoryName: String {
    guard let firstId = selectedCategories.first,
          let category = categories.first(where: { $0.id == firstId }) else {
        return "Category"
    }
    return category.name
}
```

### 3. Toggle Selection

```swift
private func toggleSelection(_ id: UUID) {
    if selectedCategories.contains(id) {
        selectedCategories.remove(id)
    } else {
        selectedCategories.insert(id)
    }
}
```

### 4. Clear All

```swift
private func clearSelection() {
    selectedCategories = []
}
```

### 5. Filter Logic (OR)

```swift
// Apply category filter (OR logic - show items from ANY selected category)
var filteredItems = allItems

if !selectedCategories.isEmpty {
    filteredItems = filteredItems.filter { item in
        selectedCategories.contains(item.categoryId)
    }
}
```

---

## Complete Component Example

```swift
struct MultiSelectCategoryFilter: View {
    @Binding var selectedCategories: Set<UUID>
    let categories: [Category]
    let tintColor: Color
    
    private var displayText: String {
        if selectedCategories.isEmpty {
            return "Category"
        } else if selectedCategories.count == 1 {
            return firstCategoryName
        } else {
            return "\(firstCategoryName) +\(selectedCategories.count - 1) more"
        }
    }
    
    private var firstCategoryName: String {
        guard let firstId = selectedCategories.first,
              let category = categories.first(where: { $0.id == firstId }) else {
            return "Category"
        }
        return category.categoryName
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Menu {
                // Clear all option (when items selected)
                if !selectedCategories.isEmpty {
                    Button("Clear All") {
                        selectedCategories = []
                    }
                    Divider()
                }
                
                // Category options with checkmarks
                ForEach(categories) { category in
                    Button {
                        toggleSelection(category.id)
                    } label: {
                        HStack {
                            Text(category.categoryName)
                            Spacer()
                            if selectedCategories.contains(category.id) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "folder")
                        .font(.caption)
                    Text(displayText)
                        .font(Typography.bodySmall)
                        .lineLimit(1)
                    if selectedCategories.isEmpty {
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.bordered)
            .tint(tintColor)
            
            // Clear button (X) when items selected
            if !selectedCategories.isEmpty {
                Button {
                    selectedCategories = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(tintColor)
                }
                .buttonStyle(.plain)
                .padding(.trailing, Spacing.sm)
            }
        }
    }
    
    private func toggleSelection(_ id: UUID) {
        if selectedCategories.contains(id) {
            selectedCategories.remove(id)
        } else {
            selectedCategories.insert(id)
        }
    }
}
```

---

## Usage in Parent View

```swift
struct ExpenseTrackerView: View {
    @State private var selectedCategoryFilter: Set<UUID> = []
    
    var filteredExpenses: [Expense] {
        var results = allExpenses
        
        // Apply category filter (OR logic)
        if !selectedCategoryFilter.isEmpty {
            results = results.filter { expense in
                selectedCategoryFilter.contains(expense.budgetCategoryId)
            }
        }
        
        return results
    }
    
    var body: some View {
        VStack {
            MultiSelectCategoryFilter(
                selectedCategories: $selectedCategoryFilter,
                categories: budgetStore.categoryStore.categories,
                tintColor: .teal
            )
            
            // Display filtered content
            ForEach(filteredExpenses) { expense in
                ExpenseRow(expense: expense)
            }
        }
    }
}
```

---

## Display Pattern Examples

| Selection State | Display Text |
|-----------------|--------------|
| None selected | "Category" |
| 1 selected (Venue) | "Venue" |
| 2 selected (Venue, Catering) | "Venue +1 more" |
| 3 selected (Venue, Catering, Decor) | "Venue +2 more" |
| 5 selected | "Venue +4 more" |

---

## Color Coding Convention

Use consistent colors across the app for different filter types:

| Filter Type | Color | Usage |
|-------------|-------|-------|
| Status filters | Blue (`.blue`) | Payment status, RSVP status |
| Category filters | Teal (`.teal`) | Budget categories, vendor categories |
| Date filters | Orange (`.orange`) | Date ranges, due dates |
| Custom filters | Purple (`.purple`) | Tags, custom attributes |

---

## Accessibility Considerations

1. **VoiceOver:** Include selection count in accessibility label
2. **Clear button:** Provide clear affordance for clearing selection
3. **Checkmarks:** Visual indication of selected state in menu

```swift
.accessibilityLabel("\(displayText), \(selectedCategories.count) selected")
.accessibilityHint("Double tap to open category filter menu")
```

---

## Performance Considerations

### Why Set<UUID>?

| Operation | Array | Set |
|-----------|-------|-----|
| Contains check | O(n) | O(1) |
| Insert | O(1) | O(1) |
| Remove | O(n) | O(1) |
| Count | O(1) | O(1) |

For filters with many options, `Set<UUID>` provides constant-time lookups.

### Filtering Large Lists

```swift
// Efficient: Single pass through items
if !selectedCategories.isEmpty {
    results = results.filter { selectedCategories.contains($0.categoryId) }
}

// Inefficient: Multiple passes
// DON'T DO THIS
for categoryId in selectedCategories {
    results += allItems.filter { $0.categoryId == categoryId }
}
```

---

## Migration from Single-Select

When converting from single-select (`UUID?`) to multi-select (`Set<UUID>`):

### Before (Single-Select)

```swift
@State private var selectedCategory: UUID? = nil

// Clear
selectedCategory = nil

// Filter
if let categoryId = selectedCategory {
    results = results.filter { $0.categoryId == categoryId }
}
```

### After (Multi-Select)

```swift
@State private var selectedCategories: Set<UUID> = []

// Clear
selectedCategories = []

// Filter (OR logic)
if !selectedCategories.isEmpty {
    results = results.filter { selectedCategories.contains($0.categoryId) }
}
```

---

## Related Patterns

- [[Collapsible Filter Menu Pattern]] - Filter bar layout in compact mode
- [[Parent-Only Hierarchical Filter Pattern]] - Filtering hierarchical data
- [[WindowSize Enum and Responsive Breakpoints Pattern]] - Responsive filter layouts

---

## Real-World Implementations

- `ExpenseFiltersBarV2.swift` - Category multi-select filter
- `GuestSearchAndFilters.swift` - Group multi-select filter
- `VendorSearchAndFilters.swift` - Category multi-select filter

---

## Summary

| Aspect | Implementation |
|--------|----------------|
| State type | `Set<UUID>` |
| Display (0 selected) | "Category" |
| Display (1 selected) | Item name |
| Display (2+ selected) | "Name +N more" |
| Filter logic | OR (any selected) |
| Clear action | `selectedItems = []` |
| Toggle action | `insert`/`remove` |

---

## Changelog

| Date | Change |
|------|--------|
| January 2026 | Created during Expense Tracker optimization |
| January 2026 | Added color coding convention |
