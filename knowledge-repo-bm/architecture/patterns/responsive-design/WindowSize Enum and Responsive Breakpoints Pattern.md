---
title: WindowSize Enum and Responsive Breakpoints Pattern
type: note
permalink: architecture/patterns/window-size-enum-and-responsive-breakpoints-pattern
tags:
- swiftui
- pattern
- responsive-design
- windowsize
- breakpoints
- compact-window
- macos
- design-system
- geometry-reader
---

# WindowSize Enum and Responsive Breakpoints Pattern

## Overview

The WindowSize Enum and Responsive Breakpoints Pattern provides a **centralized, type-safe system** for detecting window dimensions and adapting UI layouts across the application. This pattern is the foundation for all responsive design in the I Do Blueprint macOS application, enabling seamless operation across different window sizes—from compact split-screen scenarios on 13" MacBook Air to full-width expanded windows.

---

## Problem

### The Challenge

macOS applications must support a wide range of window sizes:

1. **Split-screen on 13" MacBook Air** - Windows as narrow as 640-700px
2. **Standard windows** - Typical 800-1000px widths
3. **Expanded windows** - Full-width or multi-monitor setups (1000px+)

Without a centralized system:
- Magic numbers scattered throughout codebase (`if width < 700`)
- Inconsistent breakpoint values across views
- Difficult to maintain and update breakpoints
- No type safety for window size comparisons
- Repeated boilerplate code in every view

### Real-World Scenario

A user on a 13" MacBook Air runs the app in split-screen mode alongside Safari. The app window is only 640px wide. Without responsive design:
- Headers overflow and clip
- 4-column grids become unusable
- Tables require horizontal scrolling
- Action buttons disappear off-screen

---

## Solution

### Core Components

The pattern consists of three interconnected pieces:

1. **WindowSize Enum** - Type-safe breakpoint definitions
2. **CGFloat Extension** - Convenient width-to-WindowSize conversion
3. **Breakpoints Struct** - Centralized threshold values

### Implementation

**File Location:** `I Do Blueprint/Design/WindowSize.swift`

```swift
import SwiftUI

/// Defines responsive breakpoints for adaptive layouts
/// Used across Guest Management, Vendor Management, Budget, and other views
///
/// Breakpoints:
/// - compact: < 700pt (split screen on 13" MacBook Air)
/// - regular: 700-1000pt (standard window sizes)
/// - large: > 1000pt (expanded windows)
enum WindowSize: Int, Comparable, CaseIterable {
    case compact
    case regular
    case large

    /// Initialize WindowSize based on available width
    /// - Parameter width: The available width in points
    init(width: CGFloat) {
        switch width {
        case ..<WindowSize.Breakpoints.compactMax:
            self = .compact
        case WindowSize.Breakpoints.compactMax..<WindowSize.Breakpoints.regularMax:
            self = .regular
        default:
            self = .large
        }
    }

    /// Breakpoint values for reference and consistency
    struct Breakpoints {
        /// Maximum width for compact mode (below this is compact)
        static let compactMax: CGFloat = 700

        /// Maximum width for regular mode (below this is regular, above is large)
        static let regularMax: CGFloat = 1000
    }

    // MARK: - Comparable Conformance

    /// Enables comparison logic like `if windowSize < .large`
    static func < (lhs: WindowSize, rhs: WindowSize) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - CGFloat Extension

extension CGFloat {
    /// Convenience property to get WindowSize for a width value
    ///
    /// Example:
    /// ```swift
    /// let size = geometry.size.width.windowSize
    /// ```
    var windowSize: WindowSize {
        WindowSize(width: self)
    }
}
```

---

## Breakpoint Values

### Defined Thresholds

| WindowSize | Width Range | Target Scenario |
|------------|-------------|-----------------|
| `.compact` | < 700pt | 13" MacBook Air split-screen, narrow windows |
| `.regular` | 700-999pt | Standard window sizes, typical usage |
| `.large` | ≥ 1000pt | Expanded windows, multi-monitor setups |

### Why These Values?

**700pt Compact Threshold:**
- 13" MacBook Air screen width: 1440pt (Retina)
- Split-screen gives each app ~720pt maximum
- With window chrome, content area is ~640-700pt
- 700pt provides buffer for window decorations

**1000pt Large Threshold:**
- Standard MacBook Pro 14" width: 1512pt
- Comfortable single-window usage starts around 1000pt
- Allows for generous layouts without wasted space

### Decision History

These breakpoints were established through:
1. **LLM Council unanimous recommendation** - Design system location
2. **Real-world testing** on 13" MacBook Air in split-screen
3. **User feedback** on compact window usability
4. **Consistency** with established responsive design patterns

---

## Usage Patterns

### Basic Usage with GeometryReader

The standard pattern for detecting window size in any view:

```swift
struct MyView: View {
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            
            // Use windowSize for layout decisions
            content(windowSize: windowSize)
        }
    }
}
```

### Passing WindowSize to Child Components

```swift
struct ParentView: View {
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            
            VStack(spacing: 0) {
                HeaderComponent(windowSize: windowSize)
                ContentComponent(windowSize: windowSize)
                FooterComponent(windowSize: windowSize)
            }
        }
    }
}

struct HeaderComponent: View {
    let windowSize: WindowSize
    
    var body: some View {
        // Adapt based on windowSize
    }
}
```

### Conditional Layouts

```swift
struct AdaptiveContent: View {
    let windowSize: WindowSize
    
    var body: some View {
        if windowSize == .compact {
            compactLayout
        } else {
            regularLayout
        }
    }
    
    private var compactLayout: some View {
        VStack { /* Vertical stack for narrow windows */ }
    }
    
    private var regularLayout: some View {
        HStack { /* Horizontal layout for wider windows */ }
    }
}
```

### Ternary Expressions for Simple Adaptations

```swift
// Padding
.padding(.horizontal, windowSize == .compact ? Spacing.lg : Spacing.huge)

// Spacing
VStack(spacing: windowSize == .compact ? Spacing.md : Spacing.xl)

// Font sizes
.font(.system(size: windowSize == .compact ? 14 : 16))

// Frame constraints
.frame(width: windowSize == .compact ? 44 : nil, height: 44)
```

### Switch Statements for Complex Logic

```swift
private var columns: [GridItem] {
    switch windowSize {
    case .compact:
        return [GridItem(.flexible())]  // Single column
    case .regular:
        return [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]  // Two columns
    case .large:
        return [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]  // Four columns
    }
}
```

### Comparable Conformance Usage

```swift
// Check if NOT compact
if windowSize != .compact {
    // Show expanded content
}

// Check if at least regular
if windowSize >= .regular {
    // Show additional features
}

// Check if smaller than large
if windowSize < .large {
    // Use condensed layout
}
```

---

## Integration with Design System

### Spacing Constants

The WindowSize pattern integrates with the `Spacing` enum for consistent responsive spacing:

```swift
// Horizontal padding
let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.huge
// compact: 16pt, regular/large: 48pt

// Vertical padding
.padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)
// compact: 16pt, regular/large: 20pt

// Section spacing
VStack(spacing: windowSize == .compact ? Spacing.lg : 24)
// compact: 16pt, regular/large: 24pt
```

**Spacing Reference:**

| Constant | Value | Typical Usage |
|----------|-------|---------------|
| `Spacing.xs` | 4pt | Tight element spacing |
| `Spacing.sm` | 8pt | Compact card padding |
| `Spacing.md` | 12pt | Compact section spacing |
| `Spacing.lg` | 16pt | Compact horizontal padding |
| `Spacing.xl` | 20pt | Regular vertical padding |
| `Spacing.xxl` | 24pt | Regular section spacing |
| `Spacing.huge` | 48pt | Regular horizontal padding |

### Content Width Constraint Pattern

When using WindowSize with ScrollView and LazyVGrid, always apply the content width constraint:

```swift
GeometryReader { geometry in
    let windowSize = geometry.size.width.windowSize
    let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.huge
    let availableWidth = geometry.size.width - (horizontalPadding * 2)
    
    ScrollView {
        VStack {
            // Content
        }
        .frame(width: availableWidth)  // ⭐ CRITICAL
        .padding(.horizontal, horizontalPadding)
    }
}
```

**Why This Matters:** LazyVGrid calculates column widths based on container width. Without the constraint, it uses full ScrollView width (including padding), causing rightmost columns to extend beyond visible area.

---

## Common Adaptations by WindowSize

### Headers

| Aspect | Compact | Regular/Large |
|--------|---------|---------------|
| Actions | Ellipsis menu | Inline buttons |
| Navigation | Icon only | Icon + text |
| Form fields | Vertical stack | Horizontal row |
| Padding | `Spacing.md` | `Spacing.lg` |

### Grids

| Aspect | Compact | Regular | Large |
|--------|---------|---------|-------|
| Columns | 1-2 | 2-3 | 3-4 |
| Card spacing | `Spacing.md` | 16pt | 16pt |
| Card padding | `Spacing.sm` | `Spacing.lg` | `Spacing.lg` |

### Tables

| Aspect | Compact | Regular/Large |
|--------|---------|---------------|
| Display | Expandable rows | Full columns |
| Columns shown | Priority only | All columns |
| Interaction | Tap to expand | Direct editing |

### Stats Cards

| Aspect | Compact | Regular/Large |
|--------|---------|---------------|
| Layout | 2-2-1 asymmetric | 5-column row |
| Card size | Smaller | Standard |
| Text size | Reduced | Standard |

---

## Real-World Examples

### Guest Management View

```swift
struct GuestManagementViewV4: View {
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.huge
            let availableWidth = geometry.size.width - (horizontalPadding * 2)

            ZStack {
                AppGradients.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header adapts to windowSize
                    GuestManagementHeader(
                        windowSize: windowSize,
                        onImport: { showingImportSheet = true },
                        onExport: exportGuestList,
                        onAddGuest: { coordinator.present(.addGuest) }
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)

                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Stats adapt to windowSize
                            GuestStatsSection(windowSize: windowSize, ...)
                            
                            // Filters adapt to windowSize
                            GuestSearchAndFilters(windowSize: windowSize, ...)
                            
                            // Grid adapts to windowSize
                            GuestListGrid(windowSize: windowSize, ...)
                        }
                        .frame(width: availableWidth)
                        .padding(.horizontal, horizontalPadding)
                    }
                }
            }
        }
    }
}
```

### Budget Development View

```swift
struct BudgetDevelopmentView: View {
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl
            let availableWidth = geometry.size.width - (horizontalPadding * 2)

            VStack(spacing: 0) {
                // Unified header with responsive form fields
                BudgetDevelopmentUnifiedHeader(
                    windowSize: windowSize,
                    currentPage: $currentPage,
                    // ... other bindings
                )

                ScrollView {
                    VStack(spacing: windowSize == .compact ? Spacing.lg : 24) {
                        // Summary cards adapt
                        BudgetSummaryCardsSection(windowSize: windowSize, ...)
                        
                        // Items table/cards adapt
                        BudgetItemsTable(windowSize: windowSize, ...)
                    }
                    .frame(width: availableWidth)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)
                }
            }
        }
    }
}
```

### Adaptive Grid Columns

```swift
struct BudgetDashboardHubView: View {
    private func gridColumns(for windowSize: WindowSize) -> [GridItem] {
        if windowSize == .compact {
            return [GridItem(.flexible())]  // 1 column
        } else if windowSize == .large {
            return Array(repeating: GridItem(.flexible()), count: 4)  // 4 columns
        } else {
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]  // 3 columns
        }
    }
}
```

---

## Testing Considerations

### Preview Configurations

Always test views at multiple window sizes:

```swift
#Preview("Compact 640x700") {
    MyView()
        .frame(width: 640, height: 700)
}

#Preview("Regular 900x700") {
    MyView()
        .frame(width: 900, height: 700)
}

#Preview("Large 1400x900") {
    MyView()
        .frame(width: 1400, height: 900)
}
```

### Critical Test Points

| Width | WindowSize | Test Focus |
|-------|------------|------------|
| 640px | `.compact` | Minimum viable width |
| 699px | `.compact` | Just below breakpoint |
| 700px | `.regular` | At breakpoint |
| 701px | `.regular` | Just above breakpoint |
| 999px | `.regular` | Just below large |
| 1000px | `.large` | At large breakpoint |
| 1400px | `.large` | Typical large window |

### Transition Testing

- Resize window across breakpoints
- Verify no layout jank during transitions
- Ensure state is preserved during resize
- Check animations are smooth

---

## Anti-Patterns to Avoid

### ❌ Magic Numbers

```swift
// BAD: Magic number scattered in code
if geometry.size.width < 700 {
    // compact layout
}

// GOOD: Use WindowSize enum
if windowSize == .compact {
    // compact layout
}
```

### ❌ Inconsistent Breakpoints

```swift
// BAD: Different breakpoints in different files
// File A: if width < 700
// File B: if width < 750
// File C: if width < 680

// GOOD: Single source of truth
// All files use: windowSize == .compact
```

### ❌ Repeated GeometryReader

```swift
// BAD: GeometryReader in every child component
struct ChildView: View {
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            // ...
        }
    }
}

// GOOD: Pass windowSize from parent
struct ChildView: View {
    let windowSize: WindowSize
    
    var body: some View {
        // Use passed windowSize
    }
}
```

### ❌ Missing Content Width Constraint

```swift
// BAD: LazyVGrid without width constraint
ScrollView {
    LazyVGrid(columns: columns) {
        // Content clips at edges
    }
    .padding(.horizontal, padding)
}

// GOOD: Constrain content width
ScrollView {
    LazyVGrid(columns: columns) {
        // Content properly contained
    }
    .frame(width: availableWidth)
    .padding(.horizontal, padding)
}
```

### ❌ Hardcoded Spacing

```swift
// BAD: Hardcoded values
.padding(.horizontal, 16)

// GOOD: Design system constants with responsive selection
.padding(.horizontal, windowSize == .compact ? Spacing.lg : Spacing.huge)
```

---

## Performance Considerations

### GeometryReader Efficiency

- GeometryReader recalculates on every frame during resize
- Keep calculations minimal inside GeometryReader
- Extract complex logic to computed properties or functions
- Avoid heavy computations in the geometry closure

```swift
// GOOD: Minimal work in GeometryReader
GeometryReader { geometry in
    let windowSize = geometry.size.width.windowSize
    let padding = windowSize == .compact ? Spacing.lg : Spacing.huge
    let width = geometry.size.width - (padding * 2)
    
    // Pass pre-calculated values to content
    content(windowSize: windowSize, availableWidth: width, padding: padding)
}
```

### Caching WindowSize

For complex views with many child components, consider caching:

```swift
struct ComplexView: View {
    @State private var cachedWindowSize: WindowSize = .regular
    
    var body: some View {
        GeometryReader { geometry in
            let newWindowSize = geometry.size.width.windowSize
            
            content
                .onChange(of: newWindowSize) { _, new in
                    cachedWindowSize = new
                }
                .onAppear {
                    cachedWindowSize = newWindowSize
                }
        }
    }
}
```

---

## Extension Points

### Adding New Breakpoints

If needed, the pattern can be extended:

```swift
enum WindowSize: Int, Comparable, CaseIterable {
    case compact      // < 700pt
    case regular      // 700-1000pt
    case large        // 1000-1400pt
    case extraLarge   // ≥ 1400pt (NEW)
    
    struct Breakpoints {
        static let compactMax: CGFloat = 700
        static let regularMax: CGFloat = 1000
        static let largeMax: CGFloat = 1400  // NEW
    }
}
```

### Platform-Specific Breakpoints

For future iOS/iPadOS support:

```swift
enum WindowSize {
    #if os(macOS)
    struct Breakpoints {
        static let compactMax: CGFloat = 700
        static let regularMax: CGFloat = 1000
    }
    #elseif os(iOS)
    struct Breakpoints {
        static let compactMax: CGFloat = 428  // iPhone Pro Max width
        static let regularMax: CGFloat = 768  // iPad portrait
    }
    #endif
}
```

---

## Related Patterns

- [[Unified Header with Responsive Actions Pattern]] - Headers that adapt using WindowSize
- [[Dynamic Content-Aware Grid Width Pattern]] - Grid sizing based on content and WindowSize
- [[Expandable Table Row Pattern]] - Tables that collapse in compact mode
- [[Table-to-Card Responsive Switcher Pattern]] - Switching between table and card views
- [[Budget Dashboard Optimization - Complete Reference]] - Full implementation example
- [[Guest Management Compact Window - Complete Session Implementation]] - Another implementation example

---

## Files Using This Pattern

### Core Definition
- `I Do Blueprint/Design/WindowSize.swift` - Pattern definition

### Views Implementing Pattern
- `GuestManagementViewV4.swift`
- `VendorManagementViewV3.swift`
- `BudgetDevelopmentView.swift`
- `BudgetOverviewDashboardViewV2.swift`
- `BudgetDashboardHubView.swift`

### Components Using WindowSize
- `GuestManagementHeader.swift`
- `GuestStatsSection.swift`
- `GuestSearchAndFilters.swift`
- `GuestListGrid.swift`
- `VendorManagementHeader.swift`
- `VendorStatsSection.swift`
- `VendorSearchAndFilters.swift`
- `VendorListGrid.swift`
- `BudgetDevelopmentUnifiedHeader.swift`
- `BudgetOverviewUnifiedHeader.swift`
- `BudgetManagementHeader.swift`
- `BudgetConfigurationHeader.swift`
- `BudgetSummaryCardsSection.swift`
- `BudgetSummaryBreakdowns.swift`
- `BudgetOverviewItemsSection.swift`
- `BudgetItemsTable.swift`

---

## Summary

The WindowSize Enum and Responsive Breakpoints Pattern provides:

1. **Type Safety** - Enum prevents magic numbers and typos
2. **Centralization** - Single source of truth for breakpoints
3. **Consistency** - Same breakpoints across all views
4. **Maintainability** - Change breakpoints in one place
5. **Readability** - `windowSize == .compact` is self-documenting
6. **Comparability** - `windowSize < .large` for range checks
7. **Integration** - Works seamlessly with design system spacing

This pattern is **foundational** to all responsive design in the application and should be used whenever UI needs to adapt to window size.

---

## Changelog

| Date | Change | Reason |
|------|--------|--------|
| January 2026 | Initial implementation | Support 13" MacBook Air split-screen |
| January 2026 | Added Comparable conformance | Enable range comparisons |
| January 2026 | Added CGFloat extension | Simplify usage pattern |
| January 2026 | Documented in Basic Memory | Establish as authoritative reference |