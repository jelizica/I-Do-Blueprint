---
title: Expandable Card Editor Pattern
type: note
permalink: architecture/patterns/expandable-card-editor-pattern
tags:
- swiftui
- pattern
- responsive-design
- card
- editing
- compact-window
- form
---

# Expandable Card Editor Pattern

## Problem

In compact windows, editing complex data items with many fields is challenging:
- Modal sheets feel heavy for quick edits
- Inline forms take too much vertical space
- Users lose context when navigating away to edit

## Solution

Create **expandable cards** that:
- Show a **collapsed summary** by default (1-2 lines)
- Expand inline to reveal **all editable fields**
- Collapse back after editing
- Support **immediate updates** (no explicit save button)

## Visual Layout

### Collapsed State
```
┌─────────────────────────────────────────┐
│ ▶ Item Name                     $1,234  │
│   Category • Subcategory        incl.tax│
└───────────────────────────────��─────────┘
```

### Expanded State
```
┌─────────────────────────────────────────┐
│ ▼ Item Name                     $1,234  │
│   Category • Subcategory        incl.tax│
├─────────────────────────────────────────┤
│ Item Name                               │
│ [TextField                           ]  │
│                                         │
│ Category          Subcategory           │
│ [Picker ▼]        [Picker ▼]            │
│                                         │
│ Estimate          Tax Rate              │
│ [1000        ]    [10.35% ▼]            │
│                                         │
│ Responsible       Events                │
│ [Picker ▼]        [Select... ▼]         │
│                                         │
│ Notes                                   │
│ [TextField                           ]  │
│                                         │
│ [🗑️ Delete Item]                        │
└─────────────────────────────────────────┘
```

## Implementation

### Step 1: Define the Card Component

```swift
struct ExpandableItemCard: View {
    let item: Item
    let isExpanded: Bool
    
    // Data for pickers
    let categories: [String]
    let subcategories: [String]
    let taxRates: [TaxInfo]
    let options: [String]
    
    // Callbacks
    let onToggleExpand: () -> Void
    let onUpdateItem: (String, String, Any) -> Void  // (itemId, fieldName, newValue)
    let onRemoveItem: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            collapsedView
            
            if isExpanded {
                expandedView
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
```

### Step 2: Implement the Collapsed View

```swift
private var collapsedView: some View {
    Button(action: onToggleExpand) {
        HStack(spacing: Spacing.sm) {
            // Expand/collapse chevron
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            // Primary info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                // Secondary info
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Value/status
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.formattedValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                
                if item.hasModifier {
                    Text("incl. tax")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Spacing.sm)
        .contentShape(Rectangle())  // Make entire row tappable
    }
    .buttonStyle(.plain)
}
```

### Step 3: Implement the Expanded View

```swift
private var expandedView: some View {
    VStack(spacing: 0) {
        Divider()
            .padding(.horizontal, Spacing.sm)
        
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Full-width fields
            nameField
            
            // Two-column grid for paired fields
            twoColumnGrid
            
            // Full-width fields
            notesField
            
            // Delete action
            deleteButton
        }
        .padding(Spacing.md)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
}
```

### Step 4: Implement the Two-Column Grid

```swift
private var twoColumnGrid: some View {
    Grid(alignment: .leading, horizontalSpacing: Spacing.md, verticalSpacing: Spacing.sm) {
        // Row 1: Category & Subcategory
        GridRow {
            labeledField(label: "Category") {
                categoryPicker
            }
            labeledField(label: "Subcategory") {
                subcategoryPicker
            }
        }
        
        // Row 2: Estimate & Tax Rate
        GridRow {
            labeledField(label: "Estimate") {
                estimateField
            }
            labeledField(label: "Tax Rate") {
                taxRatePicker
            }
        }
        
        // Row 3: Responsible & Events
        GridRow {
            labeledField(label: "Responsible") {
                responsiblePicker
            }
            labeledField(label: "Events") {
                eventsSelector
            }
        }
    }
}

/// Helper for consistent field styling
@ViewBuilder
private func labeledField<Content: View>(
    label: String,
    @ViewBuilder content: () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(label)
            .font(.caption)
            .foregroundColor(.secondary)
        content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
```

### Step 5: Implement Immediate Update Bindings

```swift
private var nameField: some View {
    VStack(alignment: .leading, spacing: 4) {
        Text("Item Name")
            .font(.caption)
            .foregroundColor(.secondary)
        
        TextField("Item name", text: Binding(
            get: { item.name },
            set: { onUpdateItem(item.id, "name", $0) }
        ))
        .textFieldStyle(.roundedBorder)
        .font(.subheadline)
    }
}

private var categoryPicker: some View {
    Picker("", selection: Binding(
        get: { item.category },
        set: { onUpdateItem(item.id, "category", $0) }
    )) {
        ForEach(categories, id: \.self) { cat in
            Text(cat).tag(cat)
        }
    }
    .pickerStyle(.menu)
    .labelsHidden()
    .frame(maxWidth: .infinity, alignment: .leading)
}

private var estimateField: some View {
    TextField("0", value: Binding(
        get: { item.estimate },
        set: { onUpdateItem(item.id, "estimate", $0) }
    ), format: .number)
    .textFieldStyle(.roundedBorder)
    .font(.subheadline)
}
```

### Step 6: Handle Complex Pickers (ID-Based Selection)

For pickers where the display value differs from the stored value:

```swift
/// Tax rate picker - uses ID for selection
/// TaxInfo.taxRate is stored as decimal (0.1035)
/// Item.taxRate is stored as percentage (10.35)
private var taxRatePicker: some View {
    Picker("", selection: Binding<Int64?>(
        get: {
            // Find matching tax rate by comparing stored percentage to TaxInfo decimal * 100
            let closestRate = taxRates.min(by: {
                abs($0.taxRate * 100 - item.taxRate) < abs($1.taxRate * 100 - item.taxRate)
            })
            return closestRate?.id
        },
        set: { newId in
            if let newId = newId,
               let selectedRate = taxRates.first(where: { $0.id == newId }) {
                // Convert decimal to percentage for storage
                onUpdateItem(item.id, "taxRate", selectedRate.taxRate * 100)
            }
        }
    )) {
        ForEach(taxRates, id: \.id) { rate in
            Text("\(rate.region) (\(String(format: "%.2f", rate.taxRate * 100))%)")
                .tag(rate.id as Int64?)
        }
    }
    .pickerStyle(.menu)
    .labelsHidden()
}
```

### Step 7: Handle Multi-Select Fields

For fields that allow multiple selections:

```swift
@State private var showingEventSelector = false

private var eventsSelector: some View {
    Button(action: { showingEventSelector = true }) {
        HStack {
            Text(eventDisplayText)
                .font(.subheadline)
                .foregroundColor(item.eventIds.isEmpty ? .secondary : AppColors.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    .buttonStyle(.plain)
    .popover(isPresented: $showingEventSelector) {
        EventMultiSelectorPopover(
            selectedEventIds: Binding(
                get: { Set(item.eventIds) },
                set: { onUpdateItem(item.id, "eventIds", Array($0)) }
            ),
            availableEvents: events
        )
    }
}

private var eventDisplayText: String {
    if item.eventIds.isEmpty {
        return "Select events..."
    }
    let names = events
        .filter { item.eventIds.contains($0.id) }
        .map(\.name)
        .joined(separator: ", ")
    return names.isEmpty ? "Select events..." : names
}
```

### Step 8: Manage Expansion State in Parent

```swift
struct ItemsCardView: View {
    @Binding var items: [Item]
    
    // Track which cards are expanded
    @State private var expandedItemIds: Set<String> = []
    
    var body: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(items) { item in
                ExpandableItemCard(
                    item: item,
                    isExpanded: expandedItemIds.contains(item.id),
                    categories: categories,
                    subcategories: subcategories(for: item.category),
                    taxRates: taxRates,
                    options: options,
                    onToggleExpand: { toggleExpand(item.id) },
                    onUpdateItem: onUpdateItem,
                    onRemoveItem: { onRemoveItem(item.id) }
                )
            }
        }
    }
    
    private func toggleExpand(_ itemId: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedItemIds.contains(itemId) {
                expandedItemIds.remove(itemId)
            } else {
                expandedItemIds.insert(itemId)
            }
        }
    }
}
```

## Key Design Decisions

### 1. Immediate Updates vs. Save Button

**Immediate updates** (recommended for most cases):
```swift
// Changes apply immediately via binding
TextField("", text: Binding(
    get: { item.name },
    set: { onUpdateItem(item.id, "name", $0) }
))
```

**Explicit save** (for complex validation):
```swift
// Local state + save button
@State private var editedName: String = ""

TextField("", text: $editedName)

Button("Save") {
    onUpdateItem(item.id, "name", editedName)
    onToggleExpand()  // Collapse after save
}
```

### 2. Chevron Position

Place chevron on the **left** for consistency with disclosure groups:
```swift
HStack {
    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
    // Content...
}
```

### 3. Animation

Use subtle animation for expand/collapse:
```swift
withAnimation(.easeInOut(duration: 0.2)) {
    expandedItemIds.insert(itemId)
}
```

### 4. Delete Placement

Place delete button at the **bottom** of expanded view:
```swift
private var deleteButton: some View {
    HStack {
        Button(role: .destructive, action: onRemoveItem) {
            Label("Delete Item", systemImage: "trash")
        }
        .buttonStyle(.borderless)
        .foregroundColor(.red)
        
        Spacer()
    }
}
```

## Computed Properties for Display

### Formatted Values

```swift
extension Item {
    var formattedValue: String {
        "$\(String(format: "%.0f", totalWithTax))"
    }
    
    var totalWithTax: Double {
        estimate * (1 + taxRate / 100)
    }
    
    var subtitle: String? {
        [category, subcategory]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
    }
}
```

### Dynamic Subcategories

```swift
private func subcategories(for categoryName: String) -> [String] {
    guard let parent = store.categories.first(where: {
        $0.name == categoryName && $0.parentId == nil
    }) else {
        return []
    }
    
    return store.categories
        .filter { $0.parentId == parent.id }
        .map(\.name)
        .sorted()
}
```

## When to Use

✅ **Use this pattern when:**
- Items have 5+ editable fields
- Quick inline editing is important
- Context preservation matters
- Space is limited (compact windows)

❌ **Don't use when:**
- Items have 1-2 fields (just show inline)
- Complex validation requires a form
- Editing is rare (use modal sheet)
- Items are read-only

## Real-World Example

See `BudgetItemsCardView.swift` and `BudgetItemCard` struct for a complete implementation with:
- 8 editable fields (name, category, subcategory, estimate, tax rate, responsible, events, notes)
- ID-based tax rate picker with format conversion
- Multi-select event popover
- Two-column grid layout
- Immediate update bindings

## Related Patterns

- [[Table-to-Card Responsive Switcher Pattern]] - Parent pattern that uses this
- [[Unified Header with Responsive Actions Pattern]] - For the page header
- [[SwiftUI Grid Layout Pattern]] - For the two-column field layout
