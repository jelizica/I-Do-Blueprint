---
title: Collapsible Section Pattern
type: note
permalink: architecture/patterns/responsive-design/collapsible-section-pattern
tags:
- swiftui
- pattern
- responsive-design
- collapsible
- chevron
- animation
- compact-window
- disclosure
---

# Collapsible Section Pattern

> **Status:** ✅ PRODUCTION READY  
> **Created:** January 2026  
> **Context:** Expense Tracker Benchmarks Section  
> **User Requirement:** "I hate horizontal scrolling, so I would rather it be collapsible"

---

## Overview

The Collapsible Section Pattern provides a standardized approach for sections that can be expanded or collapsed by the user. This pattern is preferred over horizontal scrolling for content that doesn't fit in compact windows.

---

## Problem

When content doesn't fit in narrow windows, there are two common approaches:

1. **Horizontal scrolling** - Users dislike this; content is hidden and requires extra interaction
2. **Collapsible sections** - Users can choose to show/hide content; cleaner UX

---

## Solution

Use a chevron-based disclosure pattern with smooth animations:
- **Collapsed:** Chevron points right (▶), content hidden
- **Expanded:** Chevron points down (▼), content visible

---

## Implementation

### Basic Structure

```swift
struct CollapsibleSection<Content: View>: View {
    let title: String
    let itemCount: Int?
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            collapsibleHeader
            
            // Content (conditionally visible)
            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.lg)
    }
    
    private var collapsibleHeader: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                // Chevron indicator
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                // Title
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Optional item count
                if let count = itemCount {
                    Text("(\(count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(Spacing.lg)
            .contentShape(Rectangle())  // Expand tap target
        }
        .buttonStyle(.plain)
    }
}
```

### Usage

```swift
struct CategoryBenchmarksSectionV2: View {
    let windowSize: WindowSize
    let benchmarks: [CategoryBenchmarkData]
    @State private var isExpanded: Bool = true
    
    var body: some View {
        CollapsibleSection(
            title: "Category Performance",
            itemCount: benchmarks.count,
            isExpanded: $isExpanded
        ) {
            VStack(spacing: Spacing.sm) {
                ForEach(benchmarks, id: \.category.id) { benchmark in
                    BenchmarkRow(benchmark: benchmark)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
    }
}
```

---

## Animation Details

### Recommended Animation

```swift
withAnimation(.easeInOut(duration: 0.2)) {
    isExpanded.toggle()
}
```

**Why 0.2 seconds?**
- Fast enough to feel responsive
- Slow enough to be perceivable
- Matches Apple's standard disclosure animations

### Content Transition

```swift
.transition(.opacity.combined(with: .move(edge: .top)))
```

This creates a smooth fade + slide effect when content appears/disappears.

---

## Chevron Rotation Alternative

For a rotating chevron instead of swapping icons:

```swift
Image(systemName: "chevron.right")
    .rotationEffect(.degrees(isExpanded ? 90 : 0))
    .animation(.easeInOut(duration: 0.2), value: isExpanded)
```

---

## State Management Options

### 1. Local State (Default Expanded)

```swift
@State private var isExpanded: Bool = true
```

Best for: Sections that should be visible by default

### 2. Local State (Default Collapsed)

```swift
@State private var isExpanded: Bool = false
```

Best for: Secondary information, advanced options

### 3. Persisted State

```swift
@AppStorage("benchmarks_expanded") private var isExpanded: Bool = true
```

Best for: User preference that should persist across sessions

### 4. Parent-Controlled State

```swift
struct ParentView: View {
    @State private var expandedSections: Set<String> = ["benchmarks"]
    
    var body: some View {
        CollapsibleSection(
            title: "Benchmarks",
            isExpanded: Binding(
                get: { expandedSections.contains("benchmarks") },
                set: { if $0 { expandedSections.insert("benchmarks") } 
                       else { expandedSections.remove("benchmarks") } }
            )
        ) {
            // Content
        }
    }
}
```

Best for: Multiple sections where only one should be expanded at a time

---

## Responsive Behavior

### Compact Mode Only

Sometimes collapsible behavior is only needed in compact mode:

```swift
struct ResponsiveSection: View {
    let windowSize: WindowSize
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            if windowSize == .compact {
                // Collapsible header in compact mode
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        Text("Category Performance (\(benchmarks.count))")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            } else {
                // Static header in regular mode
                Text("Category Performance vs Budget")
                    .font(.headline)
            }
            
            // Content
            if windowSize != .compact || isExpanded {
                contentView
            }
        }
    }
}
```

---

## Accessibility

### VoiceOver Support

```swift
Button {
    withAnimation { isExpanded.toggle() }
} label: {
    // ...
}
.accessibilityLabel("\(title), \(isExpanded ? "expanded" : "collapsed")")
.accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
.accessibilityAddTraits(.isButton)
```

### Keyboard Navigation

The button-based implementation automatically supports keyboard navigation (Tab + Space/Enter).

---

## Visual Variants

### With Divider

```swift
VStack(spacing: 0) {
    collapsibleHeader
    
    if isExpanded {
        Divider()
            .padding(.horizontal, Spacing.lg)
        
        content()
    }
}
```

### With Background Highlight

```swift
collapsibleHeader
    .background(isExpanded ? AppColors.primary.opacity(0.05) : Color.clear)
```

### With Count Badge

```swift
HStack {
    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
    Text(title)
    
    // Count badge
    Text("\(itemCount)")
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Capsule().fill(AppColors.primary))
    
    Spacer()
}
```

---

## When to Use

### ✅ Use Collapsible Sections For:

- **Secondary information** - Benchmarks, statistics, details
- **Long lists** - Categories, history, logs
- **Advanced options** - Settings, filters, configurations
- **Compact mode alternatives** - Instead of horizontal scrolling

### ❌ Don't Use For:

- **Primary content** - Main data the user came to see
- **Critical actions** - Buttons that must be visible
- **Single items** - Overhead not worth it for one item
- **Frequently accessed** - If users always expand it, don't collapse

---

## Real-World Implementations

- `CategoryBenchmarksSectionV2.swift` - Budget category benchmarks
- `ExpenseExpandableRow.swift` - Expense details in list view
- `BudgetOverviewItemsSection.swift` - Budget item details

---

## Related Patterns

- [[Expandable Table Row Pattern]] - Row-level expansion in tables
- [[WindowSize Enum and Responsive Breakpoints Pattern]] - Responsive triggers
- [[Dynamic Content-Aware Grid Width Pattern]] - Alternative for grids

---

## Summary

| Aspect | Implementation |
|--------|----------------|
| Chevron collapsed | `chevron.right` (▶) |
| Chevron expanded | `chevron.down` (▼) |
| Animation duration | 0.2 seconds |
| Animation curve | `.easeInOut` |
| Transition | `.opacity.combined(with: .move(edge: .top))` |
| Default state | Usually expanded (`true`) |
| Tap target | Full header width (`contentShape(Rectangle())`) |

---

## Changelog

| Date | Change |
|------|--------|
| January 2026 | Created during Expense Tracker optimization |
| January 2026 | Added responsive behavior section |
