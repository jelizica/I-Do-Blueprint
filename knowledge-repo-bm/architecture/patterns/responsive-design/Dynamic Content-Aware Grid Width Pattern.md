---
title: Dynamic Content-Aware Grid Width Pattern
type: note
permalink: architecture/patterns/dynamic-content-aware-grid-width-pattern
tags:
- swiftui
- pattern
- responsive-design
- grid
- lazyvgrid
- dynamic-layout
- content-aware
- adaptive
- compact-window
---

# Dynamic Content-Aware Grid Width Pattern

## Problem

When displaying data in a card grid layout, fixed minimum widths create two issues:
1. **Too wide:** Wastes space when content is small, showing fewer cards per row
2. **Too narrow:** Causes text wrapping or truncation when content is large

Users want cards to be "as narrow as possible without text wrapping" - but the optimal width depends on the actual data being displayed.

## Solution

Calculate the minimum card width **dynamically** based on the actual content, considering multiple constraints:
1. **Non-wrapping content** (numbers, currency) - must fit on one line
2. **Word integrity** (names, titles) - words can't break mid-word
3. **Fixed elements** (icons, progress indicators) - have minimum sizes

Use `max()` to ensure ALL constraints are satisfied, then apply to an adaptive grid.

## Visual Concept

### Before (Fixed Width)
```
┌─────────────────────┐  ┌─────────────────────┐
│  $500               │  │  $500               │
│  (lots of space)    │  │  (lots of space)    │
└─────────────────────┘  └─────────────────────┘
```

### After (Dynamic Width)
```
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  $500    │  │  $500    │  │  $500    │  │  $500    │
└──────────┘  └──────────┘  └──────────┘  └──────────┘
```

## Implementation

### Step 1: Define the Dynamic Calculation

```swift
private var dynamicMinimumCardWidth: CGFloat {
    // Factor 1: Find largest currency value
    let maxBudgeted = items.map { $0.budgeted }.max() ?? 0
    let maxSpent = items.map { $0.spent }.max() ?? 0
    let maxValue = max(maxBudgeted, maxSpent)
    
    // Estimate width for currency text
    // Format: "$XX,XXX.XX" - ~8.5px per character
    let digitCount = String(format: "%.2f", maxValue).count
    let estimatedCurrencyWidth: CGFloat = CGFloat(digitCount) * 8.5 + 10
    
    // Factor 2: Find longest word (words can't break)
    let longestWord = items
        .flatMap { $0.name.split(separator: " ") }
        .map { String($0) }
        .max(by: { $0.count < $1.count }) ?? ""
    
    // Estimate width for longest word (~9px per character for headline font)
    let longestWordWidth: CGFloat = CGFloat(longestWord.count) * 9 + 10
    
    // Factor 3: Fixed element minimums
    let progressCircleMin: CGFloat = 80
    let labelWidth: CGFloat = 70  // "BUDGETED", "SPENT", etc.
    let horizontalPadding: CGFloat = 16
    let safetyMargin: CGFloat = 20
    
    // Calculate minimum satisfying ALL constraints
    let calculatedWidth = max(
        labelWidth + estimatedCurrencyWidth + horizontalPadding + safetyMargin,
        progressCircleMin + horizontalPadding + safetyMargin,
        longestWordWidth + horizontalPadding + safetyMargin
    )
    
    // Clamp between reasonable bounds
    return min(max(calculatedWidth, 150), 250)
}
```

### Step 2: Apply to Adaptive Grid

```swift
private var columns: [GridItem] {
    let minWidth = dynamicMinimumCardWidth
    let maxWidth = minWidth + 60  // Allow flexibility
    
    switch windowSize {
    case .compact:
        return [GridItem(.adaptive(minimum: minWidth, maximum: maxWidth), spacing: Spacing.md)]
    case .regular:
        return [GridItem(.adaptive(minimum: minWidth + 20, maximum: maxWidth + 20), spacing: 16)]
    case .large:
        return [GridItem(.adaptive(minimum: minWidth + 40, maximum: maxWidth + 40), spacing: 16)]
    }
}
```

### Step 3: Use in LazyVGrid

```swift
var body: some View {
    LazyVGrid(columns: columns, spacing: Spacing.md) {
        ForEach(items) { item in
            CardView(item: item)
        }
    }
}
```

## Character Width Estimates

Use these estimates for common fonts:

| Font Style | Approx. Width per Character |
|------------|----------------------------|
| Headline (16pt) | ~9px |
| Subheadline (14pt) | ~8.5px |
| Body (13pt) | ~8px |
| Caption (11pt) | ~7px |
| Caption2 (10pt) | ~6.5px |

**Note:** These are estimates. For pixel-perfect accuracy, use `NSAttributedString` measurement, but estimates are usually sufficient.

## Constraint Types

### 1. Non-Wrapping Content
Content that MUST stay on one line:
- Currency amounts (`$1,234.56`)
- Percentages (`99%`)
- Dates (`Jan 15, 2026`)
- Status codes (`APPROVED`)

**Calculation:** Character count × font width estimate

### 2. Word Integrity
Content where words can't break mid-word:
- Names (`"Accommodations"` can't become `"Accommo-dations"`)
- Titles
- Labels

**Calculation:** Longest word character count × font width estimate

### 3. Fixed Elements
Elements with minimum sizes:
- Progress circles (80px minimum for readability)
- Icons (24-44px depending on touch target)
- Buttons (44px minimum touch target)

**Calculation:** Fixed pixel values

## Example Scenarios

| Data | Max Currency | Longest Word | Calculated Width | Cards/Row (640px) |
|------|--------------|--------------|------------------|-------------------|
| Small budget | $500 | "Venue" (5) | ~150px | 4 |
| Medium budget | $5,000 | "Expenses" (8) | ~165px | 3-4 |
| Large budget | $50,000 | "Accommodations" (14) | ~180px | 3 |
| Very large | $500,000 | "Transportation" (14) | ~195px | 3 |

## Performance Considerations

### Complexity
- Currency max: O(n)
- Longest word: O(n × m) where m = average words per name
- Overall: O(n × m) - acceptable for < 1000 items

### Optimization (if needed)
```swift
// Cache the calculation
@State private var cachedMinWidth: CGFloat?

private var dynamicMinimumCardWidth: CGFloat {
    if let cached = cachedMinWidth {
        return cached
    }
    let calculated = calculateMinWidth()
    cachedMinWidth = calculated
    return calculated
}

// Invalidate on data change
.onChange(of: items) { _ in
    cachedMinWidth = nil
}
```

## When to Use

✅ **Use this pattern when:**
- Card content varies significantly in size
- Space efficiency is important
- Content has non-wrapping constraints
- Data changes dynamically

❌ **Don't use when:**
- All cards have similar content sizes
- Fixed layouts are acceptable
- Performance is critical with 1000+ items
- Content can freely wrap/truncate

## Real-World Example

See `BudgetOverviewItemsSection.swift` for a complete implementation with:
- Currency amounts (budgeted, spent, remaining)
- Item names with varying lengths
- Progress circles
- Responsive window size handling

## Related Patterns

- [[Table-to-Card Responsive Switcher Pattern]] - Switches between table and cards
- [[Unified Header with Responsive Actions Pattern]] - Header above the grid
- [[Expandable Table Row Pattern]] - Alternative to cards for compact views
