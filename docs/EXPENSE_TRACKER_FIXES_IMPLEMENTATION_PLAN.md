# Expense Tracker Fixes - Implementation Plan

> **Status:** 🚧 IN PROGRESS  
> **Started:** January 2026  
> **Estimated Duration:** 2 hours

---

## Issues to Fix

### 1. Navigation & Header Structure ⚠️
**Problem:** Missing navigation dropdown, incorrect header format
**Current:** "Expense Tracker" as title, no navigation
**Expected:** "Budget" (title) + "Expense Tracker" (subtitle) + navigation dropdown

**Changes Required:**
- Update ExpenseTrackerUnifiedHeader to match Budget Builder/Overview pattern
- Add navigation dropdown with all budget pages
- Move "Add Expense" button into ellipsis menu
- Match exact navigation structure from completed pages

---

### 2. Sticky Header Investigation 🔍
**Problem:** Need to determine if header should be sticky
**Action:** Investigate Budget Builder and Budget Overview implementations
**Decision:** Match their behavior for consistency

---

### 3. Single Column Card Width 📏
**Problem:** Cards don't fill full width in single column layout
**Current:** Max width 250px even in single column
**Expected:** Full width when only 1 card fits per row

**Changes Required:**
- Detect when grid shows single column
- Remove max width constraint for single column
- Use `maxWidth: .infinity` for full-width cards

---

### 4. Category Filter - Parent Categories Only 🗂️
**Problem:** Showing all categories including subcategories
**Current:** All categories displayed (30+ items)
**Expected:** Only top-level parent categories

**Changes Required:**
- Query Supabase to understand parent/child structure
- Filter categories to show only `parent_category_id == nil`
- Implement multi-select with "Category +2 more" display pattern
- Store selected categories as Set<UUID>

---

### 5. Ellipsis Menu Placeholders 📋
**Problem:** Menu items not implemented
**Action:** Create beads issues for future implementation

**Items:**
- Export as CSV (not implemented)
- Export as PDF (not implemented)
- Bulk Edit (not implemented)
- Add Expense (FUNCTIONAL - move from header)

---

## Implementation Phases

### Phase 1: Database Investigation (15 min)
**Objective:** Understand category structure

**Tasks:**
1. Use Supabase MCP to query `budget_categories` table
2. Identify parent/child relationship structure
3. Confirm parent_category_id field usage
4. Document findings

**Query:**
```sql
SELECT id, category_name, parent_category_id, couple_id
FROM budget_categories
WHERE couple_id = '<current_couple_id>'
ORDER BY parent_category_id NULLS FIRST, category_name;
```

---

### Phase 2: Header Navigation (45 min)
**Objective:** Fix header structure and add navigation

**Tasks:**
1. Read Budget Builder unified header implementation
2. Read Budget Overview unified header implementation
3. Update ExpenseTrackerUnifiedHeader:
   - Change title to "Budget"
   - Add subtitle "Expense Tracker"
   - Add navigation dropdown (same as other pages)
   - Move Add button to ellipsis menu
4. Investigate sticky header behavior
5. Apply sticky positioning if used in other pages

**Files to Modify:**
- `ExpenseTrackerUnifiedHeader.swift`

**Files to Reference:**
- `BudgetDevelopmentUnifiedHeader.swift` (Budget Builder)
- `BudgetOverviewUnifiedHeader.swift` (Budget Overview)

---

### Phase 3: Multi-Select Category Filter (30 min)
**Objective:** Implement parent-only, multi-select category filter

**Tasks:**
1. Update ExpenseFiltersBarV2:
   - Filter categories to parent-only
   - Change from single-select to multi-select
   - Implement "Category +2 more" display pattern
   - Update state management (UUID? → Set<UUID>)
2. Update ExpenseTrackerView:
   - Change selectedCategoryFilter type
   - Update filtering logic for multiple categories
3. Test with actual data

**Files to Modify:**
- `ExpenseFiltersBarV2.swift`
- `ExpenseTrackerView.swift`

**Display Logic:**
```swift
// No selection: "Category"
// 1 selected: "Venue"
// 2+ selected: "Venue +2 more"
```

---

### Phase 4: Single Column Card Width (15 min)
**Objective:** Make cards full-width in single column

**Tasks:**
1. Update ExpenseCardsGridViewV2:
   - Detect single column layout
   - Remove max width constraint for single column
   - Keep max width for multi-column
2. Test at various widths

**Files to Modify:**
- `ExpenseListView.swift` (ExpenseCardsGridViewV2)

**Logic:**
```swift
// If only 1 card fits: maxWidth = .infinity
// If 2+ cards fit: maxWidth = 250
```

---

### Phase 5: Create Beads Issues (15 min)
**Objective:** Document future work

**Issues to Create:**
1. "Implement CSV Export for Expense Tracker"
2. "Implement PDF Export for Expense Tracker"
3. "Implement Bulk Edit for Expense Tracker"

---

## Acceptance Criteria

### Header Navigation ✅
- [ ] Title shows "Budget"
- [ ] Subtitle shows "Expense Tracker"
- [ ] Navigation dropdown present with all budget pages
- [ ] Add button moved to ellipsis menu as "Add Expense"
- [ ] Sticky behavior matches Budget Builder/Overview
- [ ] Build succeeds

### Category Filter ✅
- [ ] Only parent categories shown (no subcategories)
- [ ] Multi-select works (can select multiple)
- [ ] Display shows "Category" when none selected
- [ ] Display shows "Venue" when 1 selected
- [ ] Display shows "Venue +2 more" when 3+ selected
- [ ] Filtering works with multiple categories (OR logic)
- [ ] Build succeeds

### Card Width ✅
- [ ] Cards fill full width in single column
- [ ] Cards respect max width in multi-column
- [ ] Smooth transition between layouts
- [ ] Build succeeds

### Beads Issues ✅
- [ ] CSV Export issue created
- [ ] PDF Export issue created
- [ ] Bulk Edit issue created

---

## Files to Modify

1. `ExpenseTrackerUnifiedHeader.swift` - Navigation, title/subtitle, add button
2. `ExpenseFiltersBarV2.swift` - Multi-select category filter
3. `ExpenseTrackerView.swift` - Category filter state and logic
4. `ExpenseListView.swift` - Single column card width

---

## Files to Reference

1. `BudgetDevelopmentUnifiedHeader.swift` - Navigation pattern
2. `BudgetOverviewUnifiedHeader.swift` - Navigation pattern
3. Budget category data structure (Supabase)

---

## Estimated Timeline

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 1: Database Investigation | 15 min | 15 min |
| Phase 2: Header Navigation | 45 min | 1 hour |
| Phase 3: Multi-Select Category Filter | 30 min | 1.5 hours |
| Phase 4: Single Column Card Width | 15 min | 1.75 hours |
| Phase 5: Create Beads Issues | 15 min | 2 hours |

**Total:** 2 hours

---

## Notes

- All changes maintain existing responsive behavior
- Multi-select uses Set<UUID> for efficient lookups
- Category filtering uses OR logic (show expenses from ANY selected category)
- Navigation dropdown matches exact structure from Budget Builder/Overview
- Add Expense functionality remains intact, just moved to menu

---

**Ready to implement!**
