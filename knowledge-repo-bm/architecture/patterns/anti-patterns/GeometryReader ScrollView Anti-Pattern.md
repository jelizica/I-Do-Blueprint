---
title: GeometryReader ScrollView Anti-Pattern
type: note
permalink: troubleshooting/geometry-reader-scroll-view-anti-pattern
tags:
- swiftui
- anti-pattern
- scrollview
- geometryreader
- bug-fix
- critical
- scrolling
- layout
---

# GeometryReader ScrollView Anti-Pattern

> **Severity:** ⚠️ CRITICAL  
> **Discovery Date:** January 2026  
> **Context:** Expense Tracker Optimization Session  
> **Impact:** Completely blocks scrolling with no error messages

---

## Problem Summary

When a `GeometryReader` is placed inside a `ScrollView` (either directly or within a child component), it **completely blocks scrolling**. The content appears but cannot be scrolled, with no error messages or warnings.

---

## Symptoms

1. **Page appears but won't scroll** - Content is visible but stuck
2. **No error messages** - Build succeeds, no runtime errors
3. **Content is visible but frozen** - User cannot interact with scroll
4. **Difficult to diagnose** - No obvious cause in logs

---

## Root Cause

`GeometryReader` tries to take all available space in its container. When placed inside a `ScrollView`, it interferes with the ScrollView's ability to calculate content size properly, effectively "locking" the scroll position.

---

## Anti-Pattern (DON'T DO THIS)

```swift
// ❌ ANTI-PATTERN: GeometryReader inside ScrollView
ScrollView {
    VStack {
        HeaderComponent()
        
        SomeGridComponent()  // Contains GeometryReader internally!
    }
}

// Inside SomeGridComponent:
struct SomeGridComponent: View {
    var body: some View {
        GeometryReader { geometry in  // ❌ BLOCKS SCROLLING!
            LazyVGrid(columns: columns) {
                ForEach(items) { item in
                    CardView(item: item)
                }
            }
        }
    }
}
```

---

## Correct Pattern

```swift
// ✅ CORRECT: GeometryReader at TOP LEVEL, pass windowSize down
struct ParentView: View {
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            
            ScrollView {
                VStack {
                    HeaderComponent(windowSize: windowSize)
                    
                    SomeGridComponent(windowSize: windowSize)  // NO GeometryReader inside
                }
            }
        }
    }
}

// Inside SomeGridComponent:
struct SomeGridComponent: View {
    let windowSize: WindowSize  // Passed from parent
    
    var body: some View {
        LazyVGrid(columns: columns) {  // ✅ No GeometryReader wrapper
            ForEach(items) { item in
                CardView(item: item)
            }
        }
    }
    
    private var columns: [GridItem] {
        // Use adaptive or flexible GridItems instead of GeometryReader
        if windowSize == .compact {
            return [GridItem(.adaptive(minimum: 160, maximum: 250))]
        } else {
            return [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }
}
```

---

## Key Principles

### 1. Single GeometryReader at Top Level

Only ONE `GeometryReader` should exist, at the **outermost level** of the view hierarchy, **outside** the `ScrollView`.

```swift
GeometryReader { geometry in  // ✅ Outside ScrollView
    ScrollView {
        // Content here
    }
}
```

### 2. Pass WindowSize Down

Calculate `windowSize` once and pass it to all child components:

```swift
let windowSize = geometry.size.width.windowSize

ChildComponent(windowSize: windowSize)
```

### 3. Use Adaptive GridItems

Instead of using `GeometryReader` to calculate grid widths, use adaptive `GridItem`:

```swift
// ❌ BAD: Using GeometryReader for width
GeometryReader { geo in
    let width = geo.size.width / 2
    // ...
}

// ✅ GOOD: Using adaptive GridItem
[GridItem(.adaptive(minimum: 160, maximum: 250))]
```

### 4. Check Child Components

When scrolling breaks, **check all child components** for hidden `GeometryReader` usage. The culprit may be several levels deep.

---

## Debugging Checklist

When scrolling stops working:

1. [ ] Search for `GeometryReader` in the view file
2. [ ] Search for `GeometryReader` in ALL child components
3. [ ] Check if any child component uses `geometry.size` internally
4. [ ] Verify GeometryReader is OUTSIDE ScrollView
5. [ ] Ensure windowSize is passed down, not recalculated

---

## Real-World Example

### Before (Broken)

```swift
// ExpenseTrackerView.swift
ScrollView {
    VStack {
        ExpenseFiltersBarV2(...)
        ExpenseListViewV2(...)  // Contains GeometryReader!
    }
}

// ExpenseListView.swift - ExpenseCardsGridViewV2
struct ExpenseCardsGridViewV2: View {
    var body: some View {
        GeometryReader { geometry in  // ❌ BREAKS SCROLLING
            let availableWidth = geometry.size.width
            LazyVGrid(columns: columns(availableWidth: availableWidth)) {
                // ...
            }
        }
    }
}
```

### After (Fixed)

```swift
// ExpenseTrackerView.swift
GeometryReader { geometry in
    let windowSize = geometry.size.width.windowSize
    
    ScrollView {
        VStack {
            ExpenseFiltersBarV2(windowSize: windowSize, ...)
            ExpenseListViewV2(windowSize: windowSize, ...)  // No GeometryReader
        }
    }
}

// ExpenseListView.swift - ExpenseCardsGridViewV2
struct ExpenseCardsGridViewV2: View {
    let windowSize: WindowSize  // Passed from parent
    
    var body: some View {
        LazyVGrid(columns: columns) {  // ✅ No GeometryReader
            // ...
        }
    }
    
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 160, maximum: 250))]
    }
}
```

---

## Reference Implementations

Working examples that follow this pattern:

- `BudgetDevelopmentView.swift` - Uses `LazyVStack` without GeometryReader
- `BudgetOverviewDashboardViewV2.swift` - GeometryReader at top level only
- `GuestManagementViewV4.swift` - Passes windowSize to all children
- `VendorManagementViewV3.swift` - Adaptive grids without GeometryReader

---

## Related Patterns

- [[WindowSize Enum and Responsive Breakpoints Pattern]] - How to detect window size
- [[Dynamic Content-Aware Grid Width Pattern]] - Alternative to GeometryReader for grids
- [[SwiftUI LazyVGrid Adaptive Card Grid Pattern]] - Proper grid implementation

---

## Summary

| Aspect | Anti-Pattern | Correct Pattern |
|--------|--------------|-----------------|
| GeometryReader location | Inside ScrollView | Outside ScrollView |
| Width calculation | Per-component GeometryReader | Pass windowSize from parent |
| Grid columns | Calculated from geometry | Adaptive GridItems |
| Child components | May contain GeometryReader | Receive windowSize as parameter |

**Remember:** If scrolling breaks with no error, **search for GeometryReader in child components**.

---

## Changelog

| Date | Change |
|------|--------|
| January 2026 | Discovered during Expense Tracker optimization |
| January 2026 | Documented as critical anti-pattern |
