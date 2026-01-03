---
title: SwiftUI Frame Modifier Order for Constrained Cards in Adaptive Grids
type: note
permalink: architecture/swiftui-patterns/swift-ui-frame-modifier-order-for-constrained-cards-in-adaptive-grids
tags:
- swiftui
- layout
- responsive
- macos
- grid
- frame-modifier
- llm-council
---

# SwiftUI Frame Modifier Order for Constrained Cards in Adaptive Grids

## Problem
When using `LazyVGrid` with `.adaptive(minimum:maximum:)` columns, cards can overflow and clip at window edges even when using `.frame(maxWidth:)` constraints.

## Root Cause
**Modifier order matters in SwiftUI.** The common mistake:

```swift
VStack { ... }
.padding(8)
.frame(maxWidth: 130)        // Sets max to 130
.frame(maxWidth: .infinity)  // OVERRIDES to infinity!
.background(Color.white)     // Background uses infinity width
.cornerRadius(8)
```

The second `.frame(maxWidth: .infinity)` is applied **before** the background, causing the visual card to expand to fill the grid column width.

## Key Insight: GridItem.adaptive(maximum:) is NOT Enforced
SwiftUI's `GridItem(.adaptive(minimum:maximum:))` does NOT treat `maximum` as a hard constraint:
1. Grid calculates columns based on `minimum` value
2. Distributes remaining space equally among all columns
3. **Ignores `maximum`** if equal distribution exceeds it
4. Cards with `.frame(maxWidth: .infinity)` accept any width offered

## Solution: Apply Background BETWEEN Frame Modifiers

```swift
VStack(spacing: 8) { ... }
.padding(8)
// 1. First, constrain the content to max width
.frame(maxWidth: 130)
// 2. Apply visual styling to the constrained size
.background(Color.white)
.cornerRadius(8)
.overlay(
    RoundedRectangle(cornerRadius: 8)
        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
)
// 3. Then allow the card to center within the grid column
.frame(maxWidth: .infinity, alignment: .center)
```

## Why This Works
1. **Inner frame (130px):** Constrains the VStack content
2. **Background/styling:** Applied to the 130px-constrained view
3. **Outer frame (infinity):** Allows centering within grid column, but the visual card (white background) is already capped at 130px

## Grid Configuration
Since `GridItem.adaptive(maximum:)` is not enforced, use only `minimum`:

```swift
LazyVGrid(
    columns: [GridItem(.adaptive(minimum: 130), spacing: 12)],
    alignment: .center,
    spacing: 12
) {
    ForEach(items) { item in
        CardView(item: item)
    }
}
```

The card itself enforces the max width via modifier order.

## Math Example at 699px Window
- Window: 699px
- Horizontal padding: 2 × 16px = 32px
- Available: 667px
- With minimum: 130px, SwiftUI calculates 4 columns
- Column width: (667 - 36px spacing) / 4 = ~157px
- Card visual width: 130px (capped by inner frame)
- Extra space: 27px per column (card centers within)

## Testing Checklist
- [ ] Cards don't clip at boundary widths (e.g., 640px, 670px, 699px)
- [ ] Visual card (background) never exceeds max width
- [ ] Cards center properly when column is wider than card max
- [ ] Grid adapts smoothly during window resize
- [ ] No visual regression at larger widths

## Related
- [[Guest Management Compact Window Plan]]
- [[SwiftUI LazyVGrid Patterns]]

## Tags
#swiftui #layout #responsive #macos #grid #frame-modifier