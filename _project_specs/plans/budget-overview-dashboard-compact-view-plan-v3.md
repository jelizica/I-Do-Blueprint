# Budget Overview Dashboard - Compact View Implementation Plan V3

> **Status:** 🔄 IN PROGRESS - Final Polish  
> **Created:** January 2026  
> **Epic:** `I Do Blueprint-0f4` - Budget Compact Views Optimization  
> **Priority:** P0 (High-Traffic Page)  
> **Estimated Hours:** 1.5 hours

---

## Context

V2 fixes are complete but screenshots reveal additional issues that need addressing:

---

## Issues from Screenshots

### Issue 1a: Two Headers Still Showing

**Screenshot Evidence:** Both "Budget" headers are visible - one at top, one below.

**Problem:** Despite deleting old header file, two headers are rendering.

**Root Cause Investigation Needed:**
- Check if `headerSection()` is being called twice
- Check if there's a duplicate VStack in main view
- Verify only one header component in view hierarchy

**Solution:**
1. Investigate view hierarchy in `BudgetOverviewDashboardViewV2.swift`
2. Keep TOP header position (cleaner layout)
3. Merge bottom header's subtext ("Budget Overview • ⭐ Wedding Expenses") into top header
4. Move ellipsis menu to top header
5. Move scenario picker to top header
6. Move search bar to top header

**Desired Layout:**
```
┌─────────────────────────────────────┐
│ Budget                    (⋯) [▼]   │
│ Budget Overview • ⭐ Scenario       │
├─────────────────────────────────────┤
│ [⭐ Scenario Picker ▼]              │
│ 🔍 Search budget items...           │
└─────────────────────────────────────┘
```

---

### Issue 1b: Remove "Search" Label

**Problem:** Search field has both a label above it AND placeholder text inside.

**Solution:** Remove the "Search" label - the placeholder "Search budget items..." is sufficient.

**Code Change:**
```swift
// BEFORE
VStack(alignment: .leading, spacing: 4) {
    Text("Search")  // <-- REMOVE THIS
        .font(.caption)
        .foregroundStyle(.secondary)
    
    searchField
}

// AFTER
searchField  // Just the field, no label
```

---

### Issue 1c: Budget Item Cards Too Large

**Problem:** Cards have too much whitespace compared to Guest/Vendor Management cards.

**Reference:** Guest Management compact cards are much tighter.

**Solution:** Reduce padding and spacing to match Guest/Vendor Management pattern:
- Reduce card padding
- Reduce spacing between elements
- Tighter layout overall
- Keep all information, just more compact

---

### Issue 1.1c: Folder Icon + Badge

**Problem:** Folder cards show "FOLDER" text badge AND folder icon (redundant).

**Solution:** 
- Remove "FOLDER" text badge
- Keep folder icon
- Add badge with count (e.g., "5") overlaid on folder icon
- Use SF Symbol badge overlay pattern

**Visual:**
```
Before: [>] 📁 [FOLDER] Guest Expenses
After:  [>] 📁⑤ Guest Expenses
```

---

### Issue 1.2c: Numbers Must Stay on One Line

**Problem:** Numbers wrapping to multiple lines, making cards uneven heights.

**Solution:**
- Add `.lineLimit(1)` to all number text
- Use `.minimumScaleFactor()` to shrink if needed
- Ensure cards size to longest number
- No wrapping allowed

**Code Pattern:**
```swift
Text(formatCurrency(amount))
    .lineLimit(1)
    .minimumScaleFactor(0.8)
    .fixedSize(horizontal: false, vertical: true)
```

---

## Implementation Plan

### Step 1: Investigate Header Duplication (15 min)

**File:** `BudgetOverviewDashboardViewV2.swift`

**Actions:**
1. Search for all `headerSection` calls
2. Check VStack structure in `body`
3. Verify only ONE header component
4. Add debug prints if needed to trace rendering

---

### Step 2: Consolidate to Single Header (30 min)

**File:** `BudgetOverviewUnifiedHeader.swift`

**Changes:**
1. Keep current position (top of view)
2. Update subtitle to include scenario name: "Budget Overview • ⭐ Wedding Expenses (reduced)"
3. Ensure ellipsis menu is in top header (already done)
4. Ensure scenario picker is in form fields (already done)
5. Ensure search bar is in form fields (already done)

**Remove from main view:**
- Any duplicate header rendering
- Any old header references

---

### Step 3: Remove Search Label (5 min)

**File:** `BudgetOverviewUnifiedHeader.swift`

**Change in `compactFormFields`:**
```swift
// Remove the VStack wrapper around searchField
// Just use searchField directly
searchField  // No label above
```

---

### Step 4: Compact Budget Item Cards (30 min)

**Files:** 
- `CircularProgressBudgetCard.swift`
- `FolderBudgetCard.swift`

**Changes:**
1. Reduce padding from `Spacing.lg` to `Spacing.sm`
2. Reduce spacing between elements
3. Make progress circle smaller
4. Tighter text spacing
5. Reference Guest Management card padding

**Pattern to Follow:**
```swift
// Guest Management compact card padding
.padding(.horizontal, Spacing.sm)
.padding(.vertical, Spacing.xs)
```

---

### Step 5: Folder Icon with Badge (20 min)

**File:** `FolderBudgetCard.swift`

**Changes:**
1. Remove "FOLDER" text badge
2. Keep folder icon
3. Add ZStack overlay with count badge
4. Use circle background with number

**Code Pattern:**
```swift
ZStack(alignment: .topTrailing) {
    Image(systemName: "folder.fill")
        .font(.title2)
        .foregroundColor(.orange)
    
    // Badge with count
    Text("\(itemCount)")
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(.white)
        .padding(4)
        .background(Circle().fill(Color.orange))
        .offset(x: 8, y: -8)
}
```

---

### Step 6: Fix Number Wrapping (10 min)

**Files:**
- `CircularProgressBudgetCard.swift`
- `FolderBudgetCard.swift`

**Changes:**
Add to ALL currency/number text:
```swift
.lineLimit(1)
.minimumScaleFactor(0.8)
.fixedSize(horizontal: false, vertical: true)
```

---

## Files to Modify

| File | Changes |
|------|---------|
| `BudgetOverviewDashboardViewV2.swift` | Fix header duplication |
| `BudgetOverviewUnifiedHeader.swift` | Remove search label, update subtitle |
| `CircularProgressBudgetCard.swift` | Reduce padding, fix number wrapping |
| `FolderBudgetCard.swift` | Icon badge, reduce padding, fix wrapping |

---

## Testing Checklist

- [ ] Only ONE header visible
- [ ] Header shows "Budget Overview • ⭐ Scenario Name"
- [ ] No "Search" label above search field
- [ ] Budget item cards are compact (minimal whitespace)
- [ ] Folder cards show icon with count badge (no "FOLDER" text)
- [ ] All numbers stay on one line (no wrapping)
- [ ] Cards are even height
- [ ] Build succeeds

---

## Beads Issues

Create follow-up issues for:
1. Table view compact mode (from V2)
2. Regular mode summary card text sizes (from V2)

---

## Success Criteria

✅ Single header displayed  
✅ Header subtitle includes scenario name  
✅ No "Search" label  
✅ Budget item cards compact like Guest Management  
✅ Folder icon with count badge (no "FOLDER" text)  
✅ All numbers on one line (no wrapping)  
✅ Build succeeds  

---

**Ready to implement - awaiting approval**
