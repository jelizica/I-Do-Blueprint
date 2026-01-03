# Budget Overview Dashboard - Compact View Implementation Plan V2

> **Status:** 🔄 IN PROGRESS - Fixing Issues from V1  
> **Created:** January 2026  
> **Epic:** `I Do Blueprint-0f4` - Budget Compact Views Optimization  
> **Priority:** P0 (High-Traffic Page)  
> **Estimated Hours:** 2 hours (fixes only)

---

## Context

V1 implementation is complete but has several issues that need to be addressed:

1. **Header Duplication** - Two headers showing (old + new unified header)
2. **Scenario Label Duplication** - "Scenario" appears twice in compact mode
3. **Summary Cards Too Large** - Single column in compact wastes space, should use adaptive grid
4. **Table View Broken** - Table is completely cut off in compact mode (see screenshot)
5. **Summary Card Text Sizes** - Don't match Budget Builder's text sizes

---

## Issues to Fix

### Issue 1: Header Duplication

**Problem:** Both `BudgetOverviewHeader.swift` (old) and `BudgetOverviewUnifiedHeader.swift` (new) are being rendered.

**Root Cause:** The main view is using the unified header, but there may be duplicate header rendering somewhere.

**Solution:**
1. Merge any missing elements from old header into unified header
2. Delete `BudgetOverviewHeader.swift`
3. Ensure only unified header is rendered

**Files:**
- `BudgetOverviewUnifiedHeader.swift` - Update with any missing elements
- `BudgetOverviewHeader.swift` - DELETE after merge
- `BudgetOverviewDashboardViewV2.swift` - Verify single header usage

---

### Issue 2: Scenario Label Duplication

**Problem:** In compact mode, "Scenario" appears twice:
```
Current (wrong):
Scenario
Scenario [Picker ▼]

Desired:
Scenario
[Picker ▼]
```

**Root Cause:** The `compactFormFields` has a label AND the Picker has its own label.

**Solution:** Remove the "Scenario" text from inside the Picker row, keep only the label above.

**File:** `BudgetOverviewUnifiedHeader.swift`

**Code Change:**
```swift
// BEFORE (wrong)
VStack(alignment: .leading, spacing: 4) {
    Text("Scenario")
        .font(.caption)
        .foregroundStyle(.secondary)
    
    Picker("Scenario", selection: $selectedScenarioId) {  // <-- "Scenario" here too
        // ...
    }
}

// AFTER (correct)
VStack(alignment: .leading, spacing: 4) {
    Text("Scenario")
        .font(.caption)
        .foregroundStyle(.secondary)
    
    Picker("", selection: $selectedScenarioId) {  // <-- Empty label
        // ...
    }
    .labelsHidden()  // <-- Hide the picker's built-in label
}
```

---

### Issue 3: Summary Cards Too Large

**Problem:** In compact mode, cards display in a single column which wastes space and looks bad.

**Reference:** Guest Management and Vendor Management use `.adaptive()` grid to fit as many cards as possible.

**Solution:** Use adaptive grid like Budget Builder's `BudgetSummaryCardsSection.swift`:

```swift
// Use adaptive grid that fits as many cards as possible
LazyVGrid(columns: [
    GridItem(.adaptive(minimum: 140, maximum: 200), spacing: Spacing.sm)
], spacing: Spacing.sm) {
    // Cards...
}
```

**File:** `BudgetOverviewSummaryCards.swift`

---

### Issue 4: Table View Broken in Compact

**Problem:** The table view is completely cut off in compact mode (see screenshot). Columns don't fit and content is clipped.

**Current Table Columns:**
- Item (text)
- Category (text + badge)
- Budgeted (currency)
- Spent (currency)
- Remaining (currency)

**Solution Options (Need Council Input):**

**Option A: Horizontal Scroll**
- Keep full table but allow horizontal scrolling
- Pros: All data visible, familiar pattern
- Cons: Requires scrolling, not ideal UX

**Option B: Simplified List with Expandable Details**
- Show minimal info in collapsed row
- Expand to show full details
- Pros: No scrolling, clean UX
- Cons: More taps to see data

**Option C: Card-Based Table Alternative**
- Convert table rows to mini-cards in compact mode
- Each card shows all info in vertical layout
- Pros: All data visible, no scrolling
- Cons: Takes more vertical space

**Option D: Priority Columns**
- Show only essential columns (Item, Budgeted, Spent)
- Hide Category and Remaining in compact
- Pros: Simple, fits in width
- Cons: Loses some data visibility

**Action:** Run LLM Council to deliberate on best approach.

**File:** `BudgetOverviewItemsSection.swift`

---

### Issue 5: Summary Card Text Sizes

**Problem:** Summary card text sizes don't match Budget Builder's implementation.

**Reference:** `BudgetSummaryCardsSection.swift` uses `BudgetCompactCard` with specific sizes:
- Title: `.system(size: 9, weight: .medium)` uppercase
- Value: `.system(size: 14, weight: .bold, design: .rounded)`

**Current SummaryCardView Compact:**
- Title: `Typography.caption`
- Value: `Typography.title3`

**Solution:** Match Budget Builder's exact text sizes for consistency.

**File:** `SummaryCardView.swift`

---

## Implementation Order

1. **Fix Header Duplication** (15 min)
   - Merge old header elements into unified header
   - Delete old header file
   - Verify single header rendering

2. **Fix Scenario Label** (5 min)
   - Remove duplicate "Scenario" label
   - Use `.labelsHidden()` on Picker

3. **Fix Summary Cards** (20 min)
   - Change to adaptive grid
   - Match Budget Builder text sizes

4. **Run Council for Table View** (15 min)
   - Use `council` CLI tool
   - Get recommendation for compact table approach

5. **Implement Table Fix** (45 min)
   - Based on council recommendation
   - Test at various widths

6. **Final Testing** (15 min)
   - Test at 640px, 699px, 700px, 1000px
   - Verify no regressions

---

## Files to Modify

| File | Changes |
|------|---------|
| `BudgetOverviewUnifiedHeader.swift` | Fix scenario label duplication |
| `BudgetOverviewSummaryCards.swift` | Use adaptive grid |
| `SummaryCardView.swift` | Match Budget Builder text sizes |
| `BudgetOverviewItemsSection.swift` | Fix table view for compact |
| `BudgetOverviewHeader.swift` | **DELETE** after merge |

---

## Council Query for Table View

**Query to run:**
```
council "For a macOS SwiftUI budget overview table that shows Item, Category, Budgeted, Spent, and Remaining columns - what's the best approach for compact windows (640-700px) where the full table doesn't fit? Options: A) Horizontal scroll, B) Expandable list rows, C) Card-based alternative, D) Priority columns only. Consider UX, data visibility, and implementation complexity."
```

---

## Success Criteria

✅ Single header displayed (no duplication)  
✅ Scenario label appears once above picker  
✅ Summary cards use adaptive grid (fit as many as possible)  
✅ Summary card text matches Budget Builder  
✅ Table view functional in compact mode  
✅ No edge clipping at any width  
✅ Build succeeds with no errors  

---

## Reference Files

- **Budget Builder Header:** `BudgetDevelopmentUnifiedHeader.swift`
- **Budget Builder Cards:** `BudgetSummaryCardsSection.swift`
- **Guest Management:** `GuestManagementViewV4.swift`
- **Guest Management Note:** Basic Memory - "Guest Management Compact Window - Complete Session Implementation"
