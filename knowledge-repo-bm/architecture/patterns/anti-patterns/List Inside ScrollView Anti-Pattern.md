---
title: List Inside ScrollView Anti-Pattern
type: note
permalink: architecture/patterns/anti-patterns/list-inside-scroll-view-anti-pattern
tags:
- swiftui
- anti-pattern
- scrollview
- list
- lazyvstack
- bug-fix
- critical
- layout
---

# List Inside ScrollView Anti-Pattern

> **Severity:** ⚠️ CRITICAL  
> **Discovery Date:** January 2026  
> **Context:** Payment Schedule Optimization Session  
> **Impact:** Content appears but doesn't render properly, no scrolling, empty space

---

## Problem Summary

When a SwiftUI `List` component is placed inside a `ScrollView`, the List **fails to expand properly** and content may not render. The page appears with empty space where the list should be, with no error messages or warnings.

---

## Symptoms

1. **Content area appears empty** - List items don't render
2. **No scrolling** - ScrollView doesn't scroll because List has zero height
3. **No error messages** - Build succeeds, no runtime errors
4. **Difficult to diagnose** - No obvious cause in logs
5. **Works in isolation** - List works fine when not inside ScrollView

---

## Root Cause

SwiftUI's `List` component has its own internal scrolling mechanism. When placed inside a `ScrollView`, there's a conflict:

1. `List` tries to manage its own scroll behavior
2. `ScrollView` expects to control scrolling for all children
3. `List` doesn't properly report its content size to the parent `ScrollView`
4. Result: `List` collapses to zero or minimal height

---

## Anti-Pattern (DON'T DO THIS)

```swift
// ❌ ANTI-PATTERN: List inside ScrollView
struct PaymentListView: View {
    let payments: [PaymentSchedule]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HeaderView()
                StatsCardsView()
                
                // ❌ List inside ScrollView - BREAKS RENDERING
                List {
                    ForEach(groupedPayments, id: \.key) { group in
                        Section(header: Text(group.key)) {
                            ForEach(group.value) { payment in
                                PaymentRow(payment: payment)
                            }
                        }
                    }
                }
            }
        }
    }
}
```

---

## Correct Pattern

Replace `List` with `LazyVStack` and implement custom section headers:

```swift
// ��� CORRECT: LazyVStack with custom section headers
struct PaymentListView: View {
    let payments: [PaymentSchedule]
    let windowSize: WindowSize
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HeaderView()
                StatsCardsView()
                
                // ✅ LazyVStack instead of List
                LazyVStack(spacing: 0) {
                    ForEach(groupedPayments, id: \.key) { group in
                        VStack(alignment: .leading, spacing: 0) {
                            // Custom section header
                            sectionHeader(group.key)
                            
                            // Section content
                            ForEach(group.value, id: \.id) { payment in
                                VStack(spacing: 0) {
                                    PaymentRow(payment: payment)
                                    
                                    // Custom divider
                                    Divider()
                                        .padding(.leading, Spacing.lg)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, Spacing.md)
            }
        }
    }
    
    // Custom section header to replace List's Section
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(Typography.bodySmall.weight(.semibold))
            .foregroundColor(AppColors.textSecondary)
            .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
    }
}
```

---

## Key Differences: List vs LazyVStack

| Feature | List | LazyVStack |
|---------|------|------------|
| Built-in scrolling | ✅ Yes | ❌ No (needs ScrollView) |
| Section headers | ✅ Built-in | ❌ Manual implementation |
| Dividers | ✅ Automatic | ❌ Manual implementation |
| Selection | ✅ Built-in | ❌ Manual implementation |
| Swipe actions | ✅ Built-in | ❌ Manual implementation |
| Inside ScrollView | ❌ Breaks | ✅ Works |
| Lazy loading | ✅ Yes | ✅ Yes |

---

## When to Use Each

### Use `List` When:
- It's the **only scrollable content** on the page
- You need built-in selection, swipe actions, or edit mode
- You want automatic styling (separators, insets)
- The list IS the page (not part of a larger scrollable layout)

### Use `LazyVStack` When:
- Content is inside a `ScrollView` with other elements
- You need custom styling for rows and sections
- You're building a complex scrollable layout
- You need precise control over spacing and dividers

---

## Migration Checklist

When replacing `List` with `LazyVStack`:

1. [ ] Wrap in `ScrollView` if not already
2. [ ] Replace `List { }` with `LazyVStack(spacing: 0) { }`
3. [ ] Replace `Section(header:)` with custom header view
4. [ ] Add manual `Divider()` between rows
5. [ ] Add padding to match List's default insets
6. [ ] Implement selection manually if needed
7. [ ] Implement swipe actions manually if needed
8. [ ] Test with empty state
9. [ ] Test with many items (100+)

---

## Custom Section Header Template

```swift
private func sectionHeader(_ title: String, itemCount: Int? = nil) -> some View {
    HStack {
        Text(title)
            .font(Typography.bodySmall.weight(.semibold))
            .foregroundColor(AppColors.textSecondary)
        
        if let count = itemCount {
            Text("(\(count))")
                .font(Typography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        
        Spacer()
    }
    .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
    .padding(.vertical, Spacing.sm)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(NSColor.controlBackgroundColor))
}
```

---

## Empty State Handling

When using `LazyVStack`, handle empty state explicitly:

```swift
if items.isEmpty {
    ContentUnavailableView(
        "No Items",
        systemImage: "tray",
        description: Text("Add items to see them here")
    )
    .frame(minHeight: 400)  // Ensure visible height
} else {
    LazyVStack(spacing: 0) {
        // Content
    }
}
```

---

## Real-World Example

### Before (Broken)

```swift
// IndividualPaymentsListView.swift - BROKEN
struct IndividualPaymentsListView: View {
    var body: some View {
        // Parent view has ScrollView
        List {  // ❌ List inside ScrollView
            ForEach(groupedPayments, id: \.key) { group in
                Section(header: Text(group.key)) {
                    ForEach(group.value) { payment in
                        PaymentScheduleRowView(payment: payment)
                    }
                }
            }
        }
    }
}
```

### After (Fixed)

```swift
// IndividualPaymentsListView.swift - FIXED
struct IndividualPaymentsListView: View {
    let windowSize: WindowSize
    
    var body: some View {
        if filteredPayments.isEmpty {
            ContentUnavailableView(...)
                .frame(minHeight: 400)
        } else {
            LazyVStack(spacing: 0) {  // ✅ LazyVStack
                ForEach(groupedPayments, id: \.key) { group in
                    VStack(alignment: .leading, spacing: 0) {
                        // Custom section header
                        Text(group.key)
                            .font(Typography.bodySmall.weight(.semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.controlBackgroundColor))
                        
                        // Section content
                        ForEach(group.value, id: \.id) { payment in
                            VStack(spacing: 0) {
                                PaymentScheduleRowView(
                                    windowSize: windowSize,
                                    payment: payment,
                                    ...
                                )
                                
                                Divider()
                                    .padding(.leading, windowSize == .compact ? Spacing.md : Spacing.lg)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.md)
        }
    }
}
```

---

## Reference Implementations

Working examples that use `LazyVStack` instead of `List`:

- `IndividualPaymentsListView.swift` - Payment schedule list
- `ExpenseListViewV2.swift` - Expense tracker list
- `GuestListViewV4.swift` - Guest management list

---

## Related Patterns

- [[GeometryReader ScrollView Anti-Pattern]] - Similar ScrollView conflict
- [[WindowSize Enum and Responsive Breakpoints Pattern]] - Responsive layouts
- [[Collapsible Section Pattern]] - Alternative for grouped content

---

## Summary

| Aspect | Anti-Pattern | Correct Pattern |
|--------|--------------|-----------------|
| Component | `List` inside `ScrollView` | `LazyVStack` inside `ScrollView` |
| Section headers | `Section(header:)` | Custom header view |
| Dividers | Automatic | Manual `Divider()` |
| Empty state | List handles it | Explicit `ContentUnavailableView` |
| Styling | Built-in | Manual with design system |

**Remember:** If content doesn't render inside a ScrollView, **check for List components** and replace with LazyVStack.

---

## Changelog

| Date | Change |
|------|--------|
| January 2026 | Discovered during Payment Schedule optimization |
| January 2026 | Documented as critical anti-pattern |