---
title: Static Header with Contextual Information Pattern
type: note
permalink: architecture/patterns/component-patterns/static-header-with-contextual-information-pattern
tags:
- swiftui
- pattern
- responsive-design
- header
- search
- contextual-info
- compact-window
- ux
---

# Static Header with Contextual Information Pattern

> **Status:** ✅ PRODUCTION READY  
> **Created:** January 2026  
> **Context:** Payment Schedule Optimization Session  
> **Decision Source:** LLM Council deliberation

---

## Overview

The Static Header with Contextual Information Pattern provides a standardized approach for adding a functional header bar between the unified page header and the main content. Unlike the [[Unified Header with Responsive Actions Pattern]] which focuses on navigation and actions, this pattern focuses on **search and contextual information** that helps users understand the current state of their data.

---

## Problem

Many pages have a gap between the navigation header and the content where users need:
1. **Quick search** - Find specific items without scrolling
2. **Contextual awareness** - Understand what needs attention (next due item, overdue count)
3. **Quick filters** - One-click access to important filtered views

Simply adding a search bar feels incomplete. Adding too many elements creates clutter.

---

## Solution

Create a static header bar that combines:
1. **Search bar** - Primary interaction for finding items
2. **Next item context** - Shows the most relevant upcoming item
3. **Alert badge** - Highlights items needing attention (overdue, urgent)

The layout adapts between compact and regular modes while maintaining all functionality.

---

## Visual Layout

### Regular Mode (≥700px)
```
┌─────────────────────────────────────────────────────────────────────┐
│ [🔍 Search payments...    ]     Next: Vendor - $500 in 3 days  [!2] │
└─────────────────────────────────────────────────────────────────────┘
```

### Compact Mode (<700px)
```
┌─────────────────────────────────┐
│ [🔍 Search payments...        ] │
│ Next: Vendor - $500 in 3 days [!2] │
└─────────────────────────────────┘
```

---

## Implementation

### Component Structure

```swift
struct StaticHeaderWithContext: View {
    let windowSize: WindowSize
    @Binding var searchQuery: String
    @Binding var activeViewMode: ViewMode  // For badge click behavior
    
    // Contextual data
    let nextItem: Item?
    let alertCount: Int
    let alertLabel: String  // e.g., "overdue", "urgent", "pending"
    
    // Actions
    let onAlertClick: () -> Void
    let onNextItemClick: () -> Void
    
    // Formatting
    let userTimezone: TimeZone
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            if windowSize == .compact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
```

### Compact Layout

```swift
private var compactLayout: some View {
    VStack(spacing: Spacing.sm) {
        // Row 1: Search bar (full-width)
        searchField
        
        // Row 2: Context info + Alert badge
        HStack {
            nextItemInfo
            Spacer()
            if alertCount > 0 {
                alertBadge
            }
        }
    }
}
```

### Regular Layout

```swift
private var regularLayout: some View {
    HStack(spacing: Spacing.lg) {
        // Search bar (left, constrained width)
        searchField
            .frame(maxWidth: 300)
        
        Spacer()
        
        // Context info (center)
        nextItemInfo
        
        // Alert badge (right)
        if alertCount > 0 {
            alertBadge
        }
    }
}
```

### Search Field Component

```swift
private var searchField: some View {
    HStack(spacing: Spacing.sm) {
        Image(systemName: "magnifyingglass")
            .foregroundColor(AppColors.textSecondary)
            .font(.system(size: 14))
        
        TextField("Search...", text: $searchQuery)
            .textFieldStyle(.plain)
            .font(Typography.bodyRegular)
        
        if !searchQuery.isEmpty {
            Button {
                searchQuery = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help("Clear search")
        }
    }
    .padding(Spacing.sm)
    .background(Color(NSColor.controlBackgroundColor))
    .cornerRadius(6)
    .overlay(
        RoundedRectangle(cornerRadius: 6)
            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
    )
}
```

### Next Item Context Component

```swift
private var nextItemInfo: some View {
    Button(action: onNextItemClick) {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "calendar.badge.clock")
                .foregroundColor(AppColors.primary)
                .font(.system(size: 14))
            
            if let item = nextItem {
                Text("Next: \(item.title)")
                    .font(Typography.bodySmall)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                Text("•")
                    .foregroundColor(AppColors.textSecondary)
                    .font(Typography.bodySmall)
                
                Text(formatValue(item.value))
                    .font(Typography.bodySmall.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                Text("in \(daysUntil(item.dueDate)) days")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            } else {
                Text("No upcoming items")
                    .font(Typography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    .buttonStyle(.plain)
    .help(nextItem != nil ? "Click to scroll to this item" : "")
}
```

### Alert Badge Component

```swift
private var alertBadge: some View {
    Button(action: onAlertClick) {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
            Text("\(alertCount)")
                .font(.caption2.weight(.bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red)
        .cornerRadius(10)
    }
    .buttonStyle(.plain)
    .help("Click to filter \(alertLabel) items")
}
```

---

## Alert Badge Click Behavior

When the alert badge is clicked, it should:
1. **Switch to the appropriate view mode** (if multiple views exist)
2. **Apply the relevant filter** (e.g., "overdue" filter)
3. **Scroll to the first matching item** (optional)

```swift
// In parent view
private func handleOverdueClick() {
    // 1. Switch to Individual view (if on Plans view)
    if showPlanView {
        showPlanView = false
    }
    
    // 2. Apply overdue filter
    selectedFilter = .overdue
    
    // 3. Optionally scroll to first overdue item
    // scrollToFirstOverdue()
}
```

---

## Computed Properties for Context

```swift
// In parent view
private var nextUpcomingItem: Item? {
    items
        .filter { !$0.isComplete && $0.dueDate > Date() }
        .sorted { $0.dueDate < $1.dueDate }
        .first
}

private var alertItemCount: Int {
    items
        .filter { !$0.isComplete && $0.dueDate < Date() }
        .count
}
```

---

## Design Decisions

### 1. Search Bar Width
- **Compact:** Full width (fills available space)
- **Regular:** Max 300px (prevents overly wide search field)

### 2. Context Info Position
- **Compact:** Below search, left-aligned
- **Regular:** Center of header, between search and badge

### 3. Alert Badge Color
- **Red:** For overdue/urgent items
- **Orange:** For warnings/approaching deadlines
- **Blue:** For informational counts

### 4. Typography
- Search placeholder: `Typography.bodyRegular`
- Context text: `Typography.bodySmall`
- Time remaining: `Typography.caption`
- Badge count: `.caption2.weight(.bold)`

---

## When to Use

### ✅ Use This Pattern When:
- Page has searchable content
- There's a concept of "next" or "upcoming" items
- Items can be overdue or need attention
- Users benefit from at-a-glance status

### ❌ Don't Use When:
- Page has no searchable content
- No concept of time-based urgency
- Content is static/reference material
- [[Unified Header with Responsive Actions Pattern]] is sufficient

---

## Comparison with Other Header Patterns

| Pattern | Primary Purpose | Key Elements |
|---------|-----------------|--------------|
| [[Unified Header with Responsive Actions Pattern]] | Navigation + Actions | Title, ellipsis menu, nav dropdown |
| **Static Header with Contextual Information** | Search + Awareness | Search bar, next item, alert badge |
| [[Management View Header Alignment Pattern]] | Title alignment | Module title, page subtitle |

These patterns can be **combined** - use Unified Header for navigation, then Static Header for search/context below it.

---

## Real-World Implementation

See `PaymentScheduleStaticHeader.swift` for a complete implementation with:
- Search bar filtering vendor names, notes, and amounts
- Next payment context showing vendor, amount, and days until due
- Overdue badge with count that switches to Individual view and applies filter
- Full compact/regular responsive layouts

---

## Related Patterns

- [[Unified Header with Responsive Actions Pattern]] - For navigation and actions
- [[WindowSize Enum and Responsive Breakpoints Pattern]] - For responsive layouts
- [[Search Filtering with View Mode Awareness Pattern]] - For search implementation

---

## Changelog

| Date | Change |
|------|--------|
| January 2026 | Created during Payment Schedule optimization |
| January 2026 | LLM Council decision: Search + Next Payment Context |