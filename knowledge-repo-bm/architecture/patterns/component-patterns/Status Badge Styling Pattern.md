---
title: Status Badge Styling Pattern
type: note
permalink: architecture/patterns/status-badge-styling-pattern
tags:
- swiftui
- pattern
- ui-design
- badge
- status
- visual-hierarchy
- color-semantics
- accessibility
---

# Status Badge Styling Pattern

## Problem

When displaying status information (categories, states, metrics), plain text lacks visual hierarchy and scanability:
- Users can't quickly identify status at a glance
- Important information blends with surrounding content
- Positive/negative states aren't immediately obvious

## Solution

Use **styled badges** with consistent visual language:
1. **Icon** - Provides instant recognition
2. **Color** - Conveys meaning (category, status, sentiment)
3. **Background** - Creates visual separation
4. **Rounded corners** - Softens appearance, indicates interactivity

## Badge Types

### 1. Category Badge
Shows item type/category with semantic color.

```
┌─────────────────┐
│ 🏛️ Venue        │  ← Purple background (15% opacity)
└─────────────────┘
```

### 2. Status Badge (Positive)
Shows positive state with green color.

```
┌─────────────────┐
│ ✅ $300.00      │  ← Green background (15% opacity)
└─────────────────┘
```

### 3. Status Badge (Negative)
Shows negative/warning state with red color.

```
┌─────────────────┐
│ ⚠️ -$50.00      │  ← Red background (15% opacity)
└─────────────────┘
```

### 4. Linked Item Badge
Shows related items with type-specific color.

```
┌──────────────────────────┐
│ 💳 Expense Name          │  ← Blue background (10% opacity)
└──────────────────────────┘
┌──────────────────────────┐
│ 🎁 Gift Name             │  ← Green background (10% opacity)
└──────────────────────────┘
```

## Implementation

### Category Badge

```swift
func categoryBadge(_ category: String) -> some View {
    let color = CategoryIcons.color(for: category)
    let icon = CategoryIcons.icon(for: category)
    
    return HStack(spacing: 4) {
        Image(systemName: icon)
            .font(.caption2)
            .foregroundColor(color)
        Text(category)
            .font(.caption)
            .fontWeight(.medium)
    }
    .padding(.horizontal, Spacing.sm)
    .padding(.vertical, 4)
    .background(color.opacity(0.15))
    .cornerRadius(6)
}
```

### Status Badge (Positive/Negative)

```swift
func statusBadge(value: Double, format: String = "%.2f") -> some View {
    let isPositive = value >= 0
    let color: Color = isPositive ? .green : .red
    let icon = isPositive ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
    
    return HStack(spacing: 4) {
        Image(systemName: icon)
            .font(.caption2)
            .foregroundColor(color)
        Text("$\(value, specifier: format)")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
    }
    .padding(.horizontal, Spacing.sm)
    .padding(.vertical, 4)
    .background(color.opacity(0.15))
    .cornerRadius(6)
}
```

### Linked Item Badge

```swift
func linkedItemBadge(
    title: String,
    icon: String,
    color: Color
) -> some View {
    HStack(spacing: 6) {
        Image(systemName: icon)
            .font(.caption2)
            .foregroundColor(color)
        Text(title)
            .font(.caption)
            .lineLimit(1)
        Spacer(minLength: 0)
    }
    .padding(.horizontal, Spacing.sm)
    .padding(.vertical, 4)
    .background(color.opacity(0.1))
    .cornerRadius(4)
}
```

### Section Header

```swift
func sectionHeader(_ title: String) -> some View {
    Text(title)
        .font(.system(size: 9, weight: .semibold))
        .foregroundColor(.secondary)
        .tracking(0.5)  // Letter spacing for uppercase
}
```

## Design Specifications

### Spacing
| Element | Value |
|---------|-------|
| Icon-to-text gap | 4-6px |
| Horizontal padding | `Spacing.sm` (8px) |
| Vertical padding | 4px |
| Corner radius | 4-6px |

### Typography
| Element | Font |
|---------|------|
| Badge text | `.caption` (11pt) |
| Badge icon | `.caption2` (10pt) |
| Section header | `.system(size: 9, weight: .semibold)` |

### Colors
| Type | Background Opacity | Text/Icon |
|------|-------------------|-----------|
| Category | 15% | Category color |
| Positive status | 15% | Green |
| Negative status | 15% | Red |
| Linked item | 10% | Type color |

## Color Semantics

### Status Colors
```swift
// Positive states
Color.green  // Under budget, complete, approved

// Negative states  
Color.red    // Over budget, overdue, rejected

// Warning states
Color.orange // Approaching limit, pending

// Neutral states
Color.gray   // Inactive, archived
```

### Category Colors
Use `CategoryIcons` helper for consistent category colors:
```swift
struct CategoryIcons {
    static func color(for category: String) -> Color {
        switch category.lowercased() {
        case "venue": return .purple
        case "catering", "food": return .orange
        case "photography", "video": return .blue
        case "music", "entertainment": return .pink
        case "flowers", "decor": return .green
        case "attire", "beauty": return .indigo
        default: return .gray
        }
    }
    
    static func icon(for category: String) -> String {
        switch category.lowercased() {
        case "venue": return "building.columns.fill"
        case "catering", "food": return "fork.knife"
        case "photography": return "camera.fill"
        case "music": return "music.note"
        case "flowers": return "leaf.fill"
        case "attire": return "tshirt.fill"
        default: return "tag.fill"
        }
    }
}
```

## Layout Patterns

### Horizontal Badge Row
```swift
HStack(spacing: Spacing.md) {
    categoryBadge(item.category)
    Spacer()
    statusBadge(value: item.remaining)
}
```

### Vertical Badge List
```swift
VStack(alignment: .leading, spacing: 6) {
    sectionHeader("LINKED ITEMS")
    
    VStack(spacing: 4) {
        ForEach(items) { item in
            linkedItemBadge(
                title: item.title,
                icon: item.icon,
                color: item.color
            )
        }
    }
}
```

## Accessibility

```swift
// Add accessibility labels
categoryBadge(category)
    .accessibilityLabel("Category: \(category)")

statusBadge(value: remaining)
    .accessibilityLabel(remaining >= 0 
        ? "\(remaining) dollars remaining, under budget"
        : "\(abs(remaining)) dollars over budget")
```

## When to Use

✅ **Use badges for:**
- Category/type indicators
- Status values (positive/negative)
- Linked/related items
- Tags and labels
- Quick-scan information

❌ **Don't use badges for:**
- Primary content (use regular text)
- Long text (truncation looks bad)
- Actions (use buttons)
- Navigation (use links)

## Consistency Guidelines

1. **Same badge type = same styling** across the app
2. **Color meanings are consistent** (green = positive, red = negative)
3. **Icon + text together** for clarity
4. **Background opacity** distinguishes from solid buttons
5. **Corner radius** matches design system (4-6px for badges)

## Real-World Example

See `BudgetOverviewItemsSection.swift` expanded content for:
- Category badges with semantic colors
- Remaining amount badges (green/red)
- Linked expense/gift badges
- Section headers with tracking

## Related Patterns

- [[Expandable Table Row Pattern]] - Uses badges in expanded content
- [[Dynamic Content-Aware Grid Width Pattern]] - Cards may contain badges
- [[Table-to-Card Responsive Switcher Pattern]] - Cards use badge styling
