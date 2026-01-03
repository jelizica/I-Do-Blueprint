---
title: Table-to-Card Responsive Switcher Pattern
type: note
permalink: architecture/patterns/table-to-card-responsive-switcher-pattern
tags:
- swiftui
- pattern
- responsive-design
- table
- card
- compact-window
- windowsize
---

# Table-to-Card Responsive Switcher Pattern

## Problem

Multi-column tables are essential for power users on large screens but become unusable in compact windows:
- Columns get truncated or require horizontal scrolling
- Inline editing becomes cramped
- Information density overwhelms small screens

Simply hiding columns loses important data. Responsive column widths still hit minimum limits.

## Solution

Create a **switcher component** that renders:
- **Table view** for regular/large windows (≥700px)
- **Card view** for compact windows (<700px)

Both views share the same data bindings and action callbacks, ensuring consistent behavior.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    SwitcherComponent                     │
│  ┌─────────────────────────────────────────────────────┐│
│  │ if windowSize == .compact                           ││
│  │     CardView(items, onUpdate, onDelete, ...)        ││
│  │ else                                                ││
│  │     TableView(items, onUpdate, onDelete, ...)       ││
│  └─────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

## Implementation

### Step 1: Define the Switcher Component

```swift
struct ItemsDisplaySwitcher: View {
    let windowSize: WindowSize
    
    // Shared data bindings
    @Binding var items: [Item]
    
    // Shared action callbacks
    let onAddItem: () -> Void
    let onUpdateItem: (String, String, Any) -> Void
    let onRemoveItem: (String) -> Void
    
    // Additional data needed by both views
    let store: StoreType
    let options: [String]
    
    var body: some View {
        if windowSize == .compact {
            ItemsCardView(
                items: $items,
                store: store,
                options: options,
                onAddItem: onAddItem,
                onUpdateItem: onUpdateItem,
                onRemoveItem: onRemoveItem
            )
        } else {
            ItemsTableView(
                items: $items,
                store: store,
                options: options,
                onAddItem: onAddItem,
                onUpdateItem: onUpdateItem,
                onRemoveItem: onRemoveItem
            )
        }
    }
}
```

### Step 2: Implement the Table View (Regular/Large)

```swift
struct ItemsTableView: View {
    @Binding var items: [Item]
    let store: StoreType
    let options: [String]
    let onAddItem: () -> Void
    let onUpdateItem: (String, String, Any) -> Void
    let onRemoveItem: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Action bar
            HStack {
                Spacer()
                Button(action: onAddItem) {
                    Label("Add Item", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            
            if items.isEmpty {
                emptyState
            } else {
                // Table with pinned header
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section(header: tableHeader) {
                        ForEach(items) { item in
                            TableRowView(
                                item: item,
                                onUpdate: onUpdateItem,
                                onRemove: { onRemoveItem(item.id) }
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("Column 1").frame(width: 120, alignment: .leading)
            Text("Column 2").frame(width: 180, alignment: .leading)
            Text("Column 3").frame(width: 100, alignment: .trailing)
            // ... more columns
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
```

### Step 3: Implement the Card View (Compact)

```swift
struct ItemsCardView: View {
    @Binding var items: [Item]
    let store: StoreType
    let options: [String]
    let onAddItem: () -> Void
    let onUpdateItem: (String, String, Any) -> Void
    let onRemoveItem: (String) -> Void
    
    // View mode toggle (optional)
    @State private var viewMode: ViewMode = .byCategory
    
    // Track expanded cards
    @State private var expandedItemIds: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with view toggle and add button
            headerRow
            
            if items.isEmpty {
                emptyState
            } else {
                itemsList
            }
        }
        .padding(Spacing.md)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var headerRow: some View {
        VStack(spacing: Spacing.sm) {
            // Optional view mode toggle
            if ViewMode.allCases.count > 1 {
                viewModeToggle
            }
            
            // Action buttons
            HStack {
                Spacer()
                Button(action: onAddItem) {
                    Label("Add Item", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var itemsList: some View {
        LazyVStack(spacing: Spacing.md) {
            switch viewMode {
            case .byCategory:
                ForEach(groupedByCategory.keys.sorted(), id: \.self) { category in
                    categorySection(category: category, items: groupedByCategory[category]!)
                }
            case .byFolder:
                folderBasedView
            }
        }
    }
    
    private func categorySection(category: String, items: [Item]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Category header
            categoryHeader(category: category, items: items)
            
            // Item cards
            ForEach(items) { item in
                ItemCard(
                    item: item,
                    isExpanded: expandedItemIds.contains(item.id),
                    onToggleExpand: { toggleExpand(item.id) },
                    onUpdate: onUpdateItem,
                    onRemove: { onRemoveItem(item.id) }
                )
            }
        }
    }
}
```

### Step 4: Use in Parent View

```swift
struct ParentView: View {
    @State var items: [Item] = []
    
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    PageHeader(windowSize: windowSize)
                    
                    // Content switches based on window size
                    ItemsDisplaySwitcher(
                        windowSize: windowSize,
                        items: $items,
                        onAddItem: addItem,
                        onUpdateItem: updateItem,
                        onRemoveItem: removeItem,
                        store: store,
                        options: options
                    )
                }
                .padding(.horizontal, windowSize == .compact ? Spacing.lg : Spacing.huge)
            }
        }
    }
}
```

## Key Design Decisions

### 1. Shared Callback Signatures

Both views must use identical callback signatures:

```swift
// ✅ Good: Same signature for both views
let onUpdateItem: (String, String, Any) -> Void  // (itemId, fieldName, newValue)
let onRemoveItem: (String) -> Void               // (itemId)

// ❌ Bad: Different signatures
// Table: onUpdateItem: (Item) -> Void
// Card:  onUpdateItem: (String, Any) -> Void
```

### 2. State Management

Keep state in the **parent view**, not in the switcher:

```swift
// ✅ Good: Parent owns state
struct ParentView: View {
    @State var items: [Item] = []
    
    var body: some View {
        ItemsDisplaySwitcher(items: $items, ...)
    }
}

// ❌ Bad: Switcher owns state
struct ItemsDisplaySwitcher: View {
    @State var items: [Item] = []  // Don't do this
}
```

### 3. View Mode Toggle (Optional)

For card views with multiple grouping options:

```swift
enum ViewMode: String, CaseIterable {
    case byCategory = "By Category"
    case byFolder = "By Folder"
    
    var icon: String {
        switch self {
        case .byCategory: return "square.grid.2x2"
        case .byFolder: return "folder"
        }
    }
}
```

### 4. Empty State Consistency

Both views should show the same empty state:

```swift
private var emptyState: some View {
    VStack(spacing: Spacing.md) {
        Image(systemName: "doc.text")
            .font(.system(size: 48))
            .foregroundStyle(.secondary)
        
        Text("No items yet")
            .font(.headline)
            .foregroundStyle(.secondary)
        
        Text("Tap 'Add Item' to get started")
            .font(.subheadline)
            .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, Spacing.xl)
}
```

## Data Transformation

### Grouping for Card View

```swift
// Group items by category
private var groupedByCategory: [String: [Item]] {
    Dictionary(grouping: items.filter { !$0.isFolder }) { item in
        item.category.isEmpty ? "Uncategorized" : item.category
    }
}

// Calculate totals per group
private func categoryTotal(_ items: [Item]) -> Double {
    items.reduce(0.0) { $0 + $1.amount }
}
```

### Hierarchy for Folder View

```swift
// Get root-level folders
private var rootFolders: [Item] {
    items.filter { $0.isFolder && $0.parentFolderId == nil }
}

// Get items in a folder
private func itemsInFolder(_ folderId: String) -> [Item] {
    items.filter { !$0.isFolder && $0.parentFolderId == folderId }
}

// Get items without folder
private var uncategorizedItems: [Item] {
    items.filter { !$0.isFolder && $0.parentFolderId == nil }
}
```

## Performance Considerations

### 1. Use LazyVStack

```swift
// ✅ Good: Lazy loading for long lists
LazyVStack(spacing: Spacing.md) {
    ForEach(items) { item in
        ItemCard(item: item, ...)
    }
}

// ❌ Bad: Eager loading
VStack(spacing: Spacing.md) {
    ForEach(items) { item in
        ItemCard(item: item, ...)
    }
}
```

### 2. Minimize Re-renders

```swift
// ✅ Good: Only expanded state changes
@State private var expandedItemIds: Set<String> = []

private func toggleExpand(_ itemId: String) {
    withAnimation(.easeInOut(duration: 0.2)) {
        if expandedItemIds.contains(itemId) {
            expandedItemIds.remove(itemId)
        } else {
            expandedItemIds.insert(itemId)
        }
    }
}
```

## When to Use

✅ **Use this pattern when:**
- Table has 5+ columns
- Table minimum width exceeds 700px
- All columns contain important data
- Inline editing is required

❌ **Don't use when:**
- Table has 2-3 columns (just make responsive)
- Data is read-only (simpler list may suffice)
- Items are simple key-value pairs

## Real-World Example

See `BudgetItemsTable.swift` for the switcher and `BudgetItemsCardView.swift` for the card implementation:
- 10-column budget table → expandable cards
- Category and folder grouping modes
- Full inline editing in both views
- Shared callbacks for CRUD operations

## Related Patterns

- [[Unified Header with Responsive Actions Pattern]] - For the header above the switcher
- [[Expandable Card Editor Pattern]] - For the individual card component
- [[SwiftUI LazyVGrid Adaptive Card Grid Pattern]] - Alternative grid-based approach
