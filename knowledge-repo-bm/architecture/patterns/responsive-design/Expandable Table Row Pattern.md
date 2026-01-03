---
title: Expandable Table Row Pattern
type: note
permalink: architecture/patterns/expandable-table-row-pattern
tags:
- swiftui
- pattern
- responsive-design
- table
- list
- expandable
- compact-window
- disclosure
- accordion
---

# Expandable Table Row Pattern

## Problem

In compact windows, full data tables become unusable:
- Too many columns cause horizontal scrolling
- Truncated content loses important information
- Users can't see all data at once

Simply hiding columns loses information. Switching to cards may not fit the use case (e.g., when users need to scan a list quickly).

## Solution

Create **expandable table rows** that:
1. Show **priority columns** in collapsed state (most important data)
2. Expand on tap to reveal **secondary information**
3. Use visual indicators (chevrons) to show expandability
4. Style expanded content distinctly from the row

This preserves the scannable list format while making all data accessible.

## Visual Layout

### Collapsed State
```
┌─────────────────────────────────────────────────────────────┐
│ ▶  Item Name                           $1,500    $1,200    │
│                                       budgeted    spent     │
├──────���──────────────────────────────────────────────────────┤
│ ▶  Another Item                          $800      $750    │
│                                       budgeted    spent     │
└─────────────────────────────────────────────────────────────┘
```

### Expanded State
```
┌─────────────────────────────────────────────────────────────┐
│ ▼  Item Name                           $1,500    $1,200    │
│                                       budgeted    spent     │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │  🏛️ Venue              ✅ $300.00 remaining             │ │
│ │                                                         │ │
│ │  LINKED ITEMS                                           │ │
│ │  ┌─────────────────────────────────────────────────┐   │ │
│ │  │ 💳 Expense Name                                 │   │ │
│ │  └─────────────────────────────────────────────────┘   │ │
│ └─────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│ ▶  Another Item                          $800      $750    │
└─────────────────────────────────────────────────────────────┘
```

## Implementation

### Step 1: Track Expanded State

```swift
struct ExpandableTableView: View {
    let items: [Item]
    
    // Track which rows are expanded
    @State private var expandedItemIds: Set<String> = []
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(items) { item in
                expandableRow(item)
                Divider()
            }
        }
    }
}
```

### Step 2: Create the Expandable Row

```swift
private func expandableRow(_ item: Item) -> some View {
    let isExpanded = expandedItemIds.contains(item.id)
    
    return VStack(spacing: 0) {
        // Collapsed row (always visible)
        collapsedRow(item, isExpanded: isExpanded)
        
        // Expanded content (conditionally visible)
        if isExpanded {
            expandedContent(item)
        }
    }
}
```

### Step 3: Implement Collapsed Row

```swift
private func collapsedRow(_ item: Item, isExpanded: Bool) -> some View {
    Button(action: {
        withAnimation(.easeInOut(duration: 0.2)) {
            if isExpanded {
                expandedItemIds.remove(item.id)
            } else {
                expandedItemIds.insert(item.id)
            }
        }
    }) {
        HStack(spacing: Spacing.sm) {
            // Chevron indicator
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            // Primary content (item name)
            Text(item.name)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Priority column 1
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(item.budgeted, specifier: "%.0f")")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text("budgeted")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .frame(width: 70)
            
            // Priority column 2
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(item.spent, specifier: "%.0f")")
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                Text("spent")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .frame(width: 70)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
    .buttonStyle(.plain)
}
```

### Step 4: Implement Expanded Content

```swift
private func expandedContent(_ item: Item) -> some View {
    VStack(alignment: .leading, spacing: Spacing.md) {
        // Row 1: Category badge + Remaining badge
        HStack(spacing: Spacing.md) {
            // Category badge
            categoryBadge(item.category)
            
            Spacer()
            
            // Remaining badge
            remainingBadge(item.remaining)
        }
        
        // Row 2: Linked items (if any)
        if !item.linkedItems.isEmpty {
            linkedItemsSection(item.linkedItems)
        }
    }
    .padding(.horizontal, Spacing.md)
    .padding(.vertical, Spacing.md)
    .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    .transition(.opacity.combined(with: .move(edge: .top)))
}
```

### Step 5: Style the Badges

```swift
private func categoryBadge(_ category: String) -> some View {
    HStack(spacing: 4) {
        Image(systemName: CategoryIcons.icon(for: category))
            .font(.caption2)
            .foregroundColor(CategoryIcons.color(for: category))
        Text(category)
            .font(.caption)
            .fontWeight(.medium)
    }
    .padding(.horizontal, Spacing.sm)
    .padding(.vertical, 4)
    .background(CategoryIcons.color(for: category).opacity(0.15))
    .cornerRadius(6)
}

private func remainingBadge(_ remaining: Double) -> some View {
    let isPositive = remaining >= 0
    
    return HStack(spacing: 4) {
        Image(systemName: isPositive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            .font(.caption2)
            .foregroundColor(isPositive ? .green : .red)
        Text("$\(remaining, specifier: "%.2f")")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(isPositive ? .green : .red)
    }
    .padding(.horizontal, Spacing.sm)
    .padding(.vertical, 4)
    .background((isPositive ? Color.green : Color.red).opacity(0.15))
    .cornerRadius(6)
}
```

### Step 6: Style Linked Items

```swift
private func linkedItemsSection(_ items: [LinkedItem]) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text("LINKED ITEMS")
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(.secondary)
            .tracking(0.5)
        
        VStack(spacing: 4) {
            ForEach(items.prefix(2), id: \.id) { item in
                HStack(spacing: 6) {
                    Image(systemName: item.icon)
                        .font(.caption2)
                        .foregroundColor(item.color)
                    Text(item.title)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 4)
                .background(item.color.opacity(0.1))
                .cornerRadius(4)
            }
        }
    }
}
```

## Column Priority Guidelines

### Priority 1 (Always Visible)
- Item identifier (name, title)
- Primary metric (amount, count, status)
- Secondary metric (if space allows)

### Priority 2 (Expanded Only)
- Category/type
- Calculated values (remaining, percentage)
- Related items
- Metadata (dates, notes)

### Priority 3 (Consider Hiding)
- IDs, codes
- Timestamps
- Audit information

## Animation Best Practices

```swift
// Smooth expand/collapse
withAnimation(.easeInOut(duration: 0.2)) {
    expandedItemIds.toggle(item.id)
}

// Transition for expanded content
.transition(.opacity.combined(with: .move(edge: .top)))
```

## Accessibility Considerations

```swift
Button(action: toggleExpand) {
    // Row content
}
.accessibilityLabel("\(item.name), \(isExpanded ? "expanded" : "collapsed")")
.accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand") details")
.accessibilityAddTraits(isExpanded ? .isSelected : [])
```

## When to Use

✅ **Use this pattern when:**
- Table has 5+ columns that don't fit in compact mode
- Users need to scan a list quickly
- Secondary information is important but not always needed
- Data has clear primary/secondary hierarchy

❌ **Don't use when:**
- All columns are equally important
- Users need to compare secondary data across rows
- Table has only 2-3 columns (just show them all)
- Cards would work better for the use case

## Comparison with Alternatives

| Approach | Pros | Cons |
|----------|------|------|
| **Expandable Rows** | Scannable list, all data accessible | Requires tap to see details |
| **Horizontal Scroll** | All columns visible | Hard to use, loses context |
| **Hide Columns** | Simple | Loses information |
| **Switch to Cards** | Rich display | Loses list scannability |

## Real-World Example

See `BudgetOverviewItemsSection.swift` `compactItemRow()` for a complete implementation with:
- Chevron expand/collapse indicator
- Priority columns (name, budgeted, spent)
- Expanded content (category badge, remaining badge, linked items)
- Smooth animations
- Proper styling hierarchy

## Related Patterns

- [[Table-to-Card Responsive Switcher Pattern]] - Alternative approach using cards
- [[Dynamic Content-Aware Grid Width Pattern]] - For card-based layouts
- [[Status Badge Styling Pattern]] - For styling the expanded content badges
