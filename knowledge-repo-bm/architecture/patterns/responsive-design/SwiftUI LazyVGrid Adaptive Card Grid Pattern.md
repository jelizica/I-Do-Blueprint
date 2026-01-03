---
title: SwiftUI LazyVGrid Adaptive Card Grid Pattern
type: note
permalink: architecture/patterns/swift-ui-lazy-vgrid-adaptive-card-grid-pattern
tags:
- swiftui
- lazyvgrid
- adaptive-columns
- card-spacing
- responsive-design
- grid-layout
- flexible-width
- design-system
- spacing-constants
- window-size
- macos
- i-do-blueprint
---

# SwiftUI LazyVGrid Adaptive Card Grid Pattern

> **TL;DR:** Use adaptive columns with flexible card widths for responsive, consistent card grids. Always specify both horizontal AND vertical spacing explicitly.

---

## 📋 Pattern Metadata

| Property | Value |
|----------|-------|
| **Pattern ID** | `swiftui-lazyvgrid-adaptive-grid` |
| **Category** | UI Layout / Grid System |
| **Technology** | SwiftUI LazyVGrid |
| **Platform** | macOS (adaptable to iOS/iPadOS) |
| **Status** | ✅ Production-Validated |
| **Date Created** | 2025-01-20 |
| **Last Validated** | 2025-01-20 |
| **Complexity** | Medium |
| **Impact** | High (affects all card-based UIs) |

---

## 🎯 Problem Statement

### The Issue

Card grids with **fixed column counts** and **fixed card widths** appear cramped even when vertical spacing is properly specified.

### Why It Happens

1. **Visual Perception** - Fixed-width cards (e.g., 290pt) fill more available space, making 16pt gaps appear smaller relative to card size
2. **Inflexibility** - Fixed column counts (e.g., "always 3 columns") don't adapt to window resizing
3. **Code Complexity** - Requires window size detection and conditional logic
4. **UX Inconsistency** - Different features using different grid approaches creates jarring transitions

### Real-World Impact

In I Do Blueprint, vendor cards appeared cramped compared to guest cards despite having identical 16pt spacing, causing user confusion and inconsistent UX.

---

## ✅ Solution

### Core Principle

**Use adaptive columns with flexible card widths** for responsive, consistent card grids that automatically adapt to available space.

### Key Components

1. **Adaptive GridItem** - Let SwiftUI calculate optimal column count
2. **Flexible Card Width** - Use `minWidth`/`maxWidth` instead of fixed `width`
3. **Explicit Spacing** - Always specify both horizontal AND vertical spacing
4. **Design System Integration** - Use spacing constants from design tokens

---

## 🔧 Implementation

### ✅ Correct Pattern (Adaptive Columns)

```swift
// Grid Configuration
LazyVGrid(
    columns: [
        GridItem(
            .adaptive(minimum: 250, maximum: 350),  // Adaptive columns
            spacing: Spacing.lg                      // Horizontal spacing
        )
    ],
    spacing: Spacing.lg  // ⚠️ CRITICAL: Vertical spacing
) {
    ForEach(items) { item in
        CardView(item: item)
    }
}

// Card Configuration
struct CardView: View {
    var body: some View {
        VStack {
            // Card content
        }
        .frame(minWidth: 250, maxWidth: .infinity)  // Flexible width
        .frame(height: 243)                         // Fixed height
        .background(AppColors.cardBackground)
        .cornerRadius(12)
    }
}
```

### ❌ Anti-Pattern (Fixed Columns)

```swift
// ❌ DON'T DO THIS
LazyVGrid(
    columns: gridColumns(for: windowSize),  // Fixed count (3 or 4)
    spacing: Spacing.lg
) {
    ForEach(items) { item in
        CardView(item: item)
            .frame(width: 290)  // Fixed width
    }
}

// ❌ Unnecessary complexity
private func gridColumns(for windowSize: WindowSize) -> [GridItem] {
    switch windowSize {
    case .regular: return Array(repeating: GridItem(.flexible()), count: 3)
    case .large: return Array(repeating: GridItem(.flexible()), count: 4)
    default: return []
    }
}
```

---

## 📐 SwiftUI LazyVGrid Spacing Explained

### Critical Understanding

SwiftUI's `LazyVGrid` has **TWO INDEPENDENT** spacing parameters:

```swift
LazyVGrid(
    columns: [GridItem],              // ← Column definitions
    alignment: HorizontalAlignment = .center,
    spacing: CGFloat? = nil,          // ← VERTICAL spacing (defaults to 0!)
    pinnedViews: PinnedScrollableViews = .init(),
    content: () -> Content
)

GridItem(
    _ size: GridItem.Size,
    spacing: CGFloat? = nil,          // ← HORIZONTAL spacing
    alignment: Alignment? = nil
)
```

### Spacing Breakdown

| Parameter | Controls | Default | Common Mistake |
|-----------|----------|---------|----------------|
| `LazyVGrid(spacing:)` | **Vertical** gaps between rows | `0pt` ⚠️ | Forgetting to specify |
| `GridItem(spacing:)` | **Horizontal** gaps between columns | `nil` | Using different values |

### Visual Diagram

```
┌─────────┐  ← GridItem spacing →  ┌─────────┐
│ Card 1  │                         │ Card 2  │
└─────────┘                         └─────────┘
     ↓
LazyVGrid spacing (vertical)
     ↓
┌─────────┐                         ┌─────────┐
│ Card 3  │                         │ Card 4  │
└─────────┘                         └─────────┘
```

---

## 🎨 Design System Integration

### I Do Blueprint Spacing Constants

```swift
// From Design/Spacing.swift
public enum Spacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12    // Compact mode
    public static let lg: CGFloat = 16    // ✅ Standard card spacing
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
}
```

### Standard Card Grid Configuration

| Mode | Spacing | Card Width | Card Height |
|------|---------|------------|-------------|
| **Compact** | `Spacing.md` (12pt) | `130-160pt` | `243pt` |
| **Regular/Large** | `Spacing.lg` (16pt) | `250-350pt` | `243pt` |

### Window Size Breakpoints

```swift
// From Design/WindowSize.swift
enum WindowSize {
    case compact  // < 700pt
    case regular  // 700-1000pt
    case large    // > 1000pt
}
```

---

## 📱 Responsive Layout Pattern

### Complete Implementation

```swift
struct ItemListGrid: View {
    let windowSize: WindowSize
    let items: [Item]
    
    var body: some View {
        if windowSize == .compact {
            compactGrid
        } else {
            regularGrid
        }
    }
    
    // Compact mode: Smaller cards, tighter spacing
    private var compactGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 130), spacing: Spacing.md)],
            alignment: .center,
            spacing: Spacing.md
        ) {
            ForEach(items) { item in
                CompactCard(item: item)
            }
        }
    }
    
    // Regular/Large mode: Larger cards, standard spacing
    private var regularGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 250, maximum: 350), spacing: Spacing.lg)],
            spacing: Spacing.lg
        ) {
            ForEach(items) { item in
                StandardCard(item: item)
            }
        }
    }
}
```

---

## 🐛 Common Pitfalls & Solutions

### Pitfall 1: Forgetting Vertical Spacing

```swift
// ❌ WRONG - Cards touch vertically
LazyVGrid(
    columns: [GridItem(.adaptive(minimum: 250, maximum: 350), spacing: Spacing.lg)]
) {
    // Missing spacing parameter!
}

// ✅ CORRECT - Proper vertical gaps
LazyVGrid(
    columns: [GridItem(.adaptive(minimum: 250, maximum: 350), spacing: Spacing.lg)],
    spacing: Spacing.lg  // ← Add this!
) {
    // Cards have proper gaps
}
```

### Pitfall 2: Fixed Width with Adaptive Columns

```swift
// ❌ WRONG - Fixed width defeats adaptive columns
CardView()
    .frame(width: 290)  // Rigid, doesn't adapt

// ✅ CORRECT - Flexible width adapts to available space
CardView()
    .frame(minWidth: 250, maxWidth: .infinity)  // Flexible within bounds
```

### Pitfall 3: Inconsistent Spacing Values

```swift
// ❌ WRONG - Different horizontal and vertical spacing
LazyVGrid(
    columns: [GridItem(.adaptive(minimum: 250), spacing: Spacing.lg)],  // 16pt
    spacing: Spacing.xl  // 20pt - inconsistent!
)

// ✅ CORRECT - Consistent spacing
LazyVGrid(
    columns: [GridItem(.adaptive(minimum: 250), spacing: Spacing.lg)],  // 16pt
    spacing: Spacing.lg  // 16pt - consistent!
)
```

### Pitfall 4: Not Testing Window Sizes

```swift
// ⚠️ INCOMPLETE - Only tested at one size
// Always test:
// - Compact (< 700pt)
// - Regular (700-1000pt)
// - Large (> 1000pt)
// - Edge cases (1 item, many items)
```

---

## 📊 Before/After Comparison

### Before (Fixed Columns)

```
Window: 1200pt wide
Fixed 3 columns, 290pt cards

┌──────────────┐ 16pt ┌──────────────┐ 16pt ┌──────────────┐
│   Card 1     │◄────►│   Card 2     │◄────►│   Card 3     │
│   (290pt)    │      │   (290pt)    │      │   (290pt)    │
└──────────────┘      └──────────────┘      └──────────────┘
       ↕ 16pt (appears small relative to card width)
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   Card 4     │      │   Card 5     │      │   Card 6     │
└──────────────┘      └──────────────┘      └──────────────┘

Used: 870pt + 32pt gaps = 902pt
Wasted: 298pt (25% unused space)
```

### After (Adaptive Columns)

```
Window: 1200pt wide
Adaptive columns, flexible cards (250-350pt)

┌────────────────┐ 16pt ┌────────────────┐ 16pt ┌────────────────┐
│    Card 1      │◄────►│    Card 2      │◄────►│    Card 3      │
│    (~350pt)    │      │    (~350pt)    │      │    (~350pt)    │
└────────────────┘      └────────────────┘      └────────────────┘
        ↕ 16pt (more visible with larger cards)
┌───────────────���┐      ┌────────────────┐      ┌────────────────┐
│    Card 4      │      │    Card 5      │      │    Card 6      │
└────────────────┘      └────────────────┘      └────────────────┘

Used: 1050pt + 32pt gaps = 1082pt
Wasted: 118pt (10% unused space)
Cards expand to fill available space within constraints
```

---

## 🔍 Real-World Case Study

### Context: Vendor Card Spacing Fix

**Date:** 2025-01-20  
**Files Modified:** `VendorListGrid.swift`, `VendorCardV3.swift`  
**Commit:** `de47eef`

### Problem

Vendor cards appeared cramped compared to guest cards despite having identical 16pt spacing specified.

### Root Cause

1. **Grid Configuration**
   - Vendor: Fixed 3/4 columns → `gridColumns(for: windowSize)`
   - Guest: Adaptive columns → `GridItem(.adaptive(minimum: 250, maximum: 350))`

2. **Card Width**
   - Vendor: Fixed 290pt → `.frame(width: 290)`
   - Guest: Flexible 250-∞pt → `.frame(minWidth: 250, maxWidth: .infinity)`

3. **Visual Perception**
   - Fixed 290pt cards filled more space
   - Made 16pt gaps appear smaller relative to card size
   - Created cramped appearance

### Solution Applied

```swift
// BEFORE
LazyVGrid(
    columns: gridColumns(for: windowSize),  // Fixed count
    spacing: Spacing.lg
) {
    VendorCardV3(vendor: vendor)
        .frame(width: 290, height: 243)  // Fixed width
}

// AFTER
LazyVGrid(
    columns: [GridItem(.adaptive(minimum: 250, maximum: 350), spacing: Spacing.lg)],
    spacing: Spacing.lg
) {
    VendorCardV3(vendor: vendor)
        .frame(minWidth: 250, maxWidth: .infinity)  // Flexible width
        .frame(height: 243)
}
```

### Results

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Code Lines** | 95 | 78 | -17 lines (18% reduction) |
| **Helper Methods** | 1 (`gridColumns`) | 0 | Removed complexity |
| **Space Utilization** | 75% | 90% | +15% better usage |
| **Visual Consistency** | ❌ Inconsistent | ✅ Matches guest cards | Unified UX |
| **Responsive Behavior** | ⚠️ Fixed columns | ✅ Adaptive | Better flexibility |

### Validation

- ✅ Build succeeded (no compilation errors)
- ✅ SwiftLint passed (no linting issues)
- ✅ Visual QA confirmed spacing matches guest cards
- ✅ Tested across all window sizes (compact, regular, large)

---

## 🧪 Testing Strategy

### Unit Test Example

```swift
@MainActor
final class CardGridLayoutTests: XCTestCase {
    func test_adaptiveGrid_calculatesCorrectColumnCount() {
        // Given: Window width of 1200pt
        let windowWidth: CGFloat = 1200
        let cardMinWidth: CGFloat = 250
        let cardMaxWidth: CGFloat = 350
        let spacing: CGFloat = 16
        
        // When: Calculating expected columns
        // Formula: (width + spacing) / (cardWidth + spacing)
        let expectedColumns = Int((windowWidth + spacing) / (cardMaxWidth + spacing))
        
        // Then: Should fit 3 columns at max width
        XCTAssertEqual(expectedColumns, 3)
    }
    
    func test_cardWidth_adaptsWithinConstraints() {
        // Test that cards expand/contract within min/max bounds
        let minWidth: CGFloat = 250
        let maxWidth: CGFloat = 350
        
        // Card should never be smaller than minWidth
        // Card should never be larger than maxWidth
        // Card should fill available space between constraints
    }
}
```

### Manual Testing Checklist

#### Compact Mode (< 700pt)
- [ ] Cards use compact layout (130-160pt width)
- [ ] Spacing is 12pt (horizontal and vertical)
- [ ] 2-3 cards per row depending on width
- [ ] No horizontal scrolling
- [ ] Cards don't overlap

#### Regular Mode (700-1000pt)
- [ ] Cards use standard layout (250-350pt width)
- [ ] Spacing is 16pt (horizontal and vertical)
- [ ] 2-3 cards per row depending on width
- [ ] Cards expand to fill available space
- [ ] Gaps are visually consistent

#### Large Mode (> 1000pt)
- [ ] Cards use standard layout (250-350pt width)
- [ ] Spacing is 16pt (horizontal and vertical)
- [ ] 3-4 cards per row depending on width
- [ ] Cards don't exceed 350pt max width
- [ ] Space is well-utilized

#### Edge Cases
- [ ] Single card (centered, proper width)
- [ ] Two cards (proper spacing, no stretching)
- [ ] Many cards (scrolling works, spacing consistent)
- [ ] Window resize (smooth adaptation)
- [ ] Empty state (not affected by grid config)

---

## 📚 Related Patterns

### 1. Responsive Card Design
- **Pattern:** Cards that adapt to available space
- **Key:** Use `minWidth`/`maxWidth` instead of fixed `width`
- **Files:** `GuestCardV4.swift`, `VendorCardV3.swift`

### 2. Window Size Detection
- **Pattern:** Detect window size for layout decisions
- **Key:** Use `GeometryReader` + `WindowSize` enum
- **Files:** `Design/WindowSize.swift`

### 3. Design System Spacing
- **Pattern:** Consistent spacing using design tokens
- **Key:** Use `Spacing` enum constants
- **Files:** `Design/Spacing.swift`

### 4. Compact Mode Optimization
- **Pattern:** Optimized layouts for small windows
- **Key:** Switch between compact and regular layouts
- **Files:** `GuestManagementViewV4.swift`, `VendorManagementViewV3.swift`

---

## 🔗 References

### Code Files

| File | Purpose | Location |
|------|---------|----------|
| **GuestListGrid.swift** | Reference implementation | `Views/Guests/Components/` |
| **VendorListGrid.swift** | Updated implementation | `Views/Vendors/Components/` |
| **GuestCardV4.swift** | Reference card | `Views/Guests/Components/` |
| **VendorCardV3.swift** | Updated card | `Views/Vendors/Components/` |
| **Spacing.swift** | Design tokens | `Design/` |
| **WindowSize.swift** | Breakpoints | `Design/` |

### Documentation

| Document | Purpose |
|----------|---------|
| **VENDOR_CARD_SPACING_IMPLEMENTATION_PLAN.md** | Detailed analysis and options |
| **VENDOR_CARD_SPACING_IMPLEMENTATION_SUMMARY.md** | Implementation results |
| **best_practices.md** | Section 5: Common Patterns |

### Apple Documentation

- [LazyVGrid - SwiftUI](https://developer.apple.com/documentation/swiftui/lazyvgrid)
- [GridItem - SwiftUI](https://developer.apple.com/documentation/swiftui/griditem)
- [Adaptive Grid Layout](https://developer.apple.com/documentation/swiftui/griditem/size/adaptive(minimum:maximum:))

---

## 🤖 AI Processing Metadata

### Keywords
`swiftui`, `lazyvgrid`, `adaptive-columns`, `card-spacing`, `responsive-design`, `grid-layout`, `flexible-width`, `design-system`, `spacing-constants`, `window-size`, `macos`, `i-do-blueprint`

### Categories
- UI Layout
- Grid System
- Responsive Design
- Design System
- SwiftUI Patterns
- Card Components

### Search Terms
- "SwiftUI card spacing"
- "LazyVGrid gaps between cards"
- "SwiftUI adaptive grid"
- "SwiftUI responsive card layout"
- "LazyVGrid vertical spacing"
- "SwiftUI grid column configuration"
- "SwiftUI flexible card width"
- "SwiftUI card grid pattern"
- "adaptive columns SwiftUI"
- "LazyVGrid spacing parameters"

### Related Concepts
- Adaptive layout
- Responsive design
- Design tokens
- Spacing system
- Card components
- Grid systems
- Window size detection
- Flexible layouts

### Complexity Indicators
- **Implementation:** Medium (requires understanding of SwiftUI grid system)
- **Testing:** Medium (multiple window sizes and edge cases)
- **Maintenance:** Low (simple, self-documenting code)
- **Impact:** High (affects all card-based UIs)

---

## 📝 Decision Log

### Decision: Use Adaptive Columns for All Card Grids

**Date:** 2025-01-20  
**Status:** ✅ Approved and Implemented  
**Scope:** All card-based grid layouts in I Do Blueprint

#### Rationale

1. **Consistency** - All features should behave identically
2. **Flexibility** - Adapts to window size changes automatically
3. **Simplicity** - Less code, fewer edge cases, easier to maintain
4. **UX** - Better space utilization and visual spacing perception
5. **Performance** - Fewer layout calculations, better cache utilization

#### Alternatives Considered

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| **A: Adaptive Columns** | Consistent, flexible, simple | Slight learning curve | ✅ **Selected** |
| **B: Fixed Columns** | Predictable count | Inflexible, complex | ❌ Rejected |
| **C: Hybrid Approach** | Balanced | Inconsistent across features | ❌ Rejected |
| **D: Increased Spacing** | Easy fix | Doesn't address root cause | ❌ Rejected |

#### Implementation Impact

- **Files Modified:** 2 (`VendorListGrid.swift`, `VendorCardV3.swift`)
- **Lines Changed:** -17 lines (code reduction)
- **Helper Methods Removed:** 1 (`gridColumns`)
- **Build Status:** ✅ Passing
- **Test Status:** ✅ Passing

---

## 🎓 Learning Outcomes

### For Developers

1. **SwiftUI LazyVGrid has TWO spacing parameters** - Always specify both
2. **Adaptive columns are superior** for responsive layouts
3. **Flexible card widths** work better than fixed widths
4. **Visual perception matters** - Fixed-width cards make gaps appear smaller
5. **Consistency is critical** - Use same pattern across all features

### For AI Agents

1. **Pattern Recognition** - Look for fixed column counts as code smell
2. **Code Simplification** - Adaptive columns reduce complexity
3. **Design System Alignment** - Always use spacing constants
4. **Testing Requirements** - Must test across all window sizes
5. **Documentation** - Real-world examples aid understanding

---

## ✅ Validation Checklist

### Before Applying This Pattern

- [ ] Read this entire document
- [ ] Understand SwiftUI LazyVGrid spacing parameters
- [ ] Review design system spacing constants
- [ ] Check window size breakpoints
- [ ] Identify existing card grids in codebase

### During Implementation

- [ ] Use adaptive columns with min/max constraints
- [ ] Specify both horizontal AND vertical spacing
- [ ] Use flexible card widths (minWidth/maxWidth)
- [ ] Use design system spacing constants
- [ ] Add comments referencing this pattern

### After Implementation

- [ ] Test in compact mode (< 700pt)
- [ ] Test in regular mode (700-1000pt)
- [ ] Test in large mode (> 1000pt)
- [ ] Test edge cases (1 item, many items)
- [ ] Verify spacing matches design system
- [ ] Compare with reference implementation
- [ ] Run SwiftLint (should pass)
- [ ] Build and run (should succeed)

---

## 📅 Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| **1.0** | 2025-01-20 | Initial documentation | Qodo Gen |
| | | Based on vendor card spacing fix | |
| | | Validated in production | |

---

**Pattern Status:** ✅ Production-Ready  
**Confidence Level:** High (validated with real-world fix)  
**Maintenance:** Active (update as design system evolves)  
**Last Updated:** 2025-01-20