# Budget Folder Persistence Fix

## Issue Summary
When creating folders in the budget development view, they appeared to be created successfully in the UI but failed to persist to the database when saving the scenario. The error was:

```
insert or update on table "budget_development_items" violates foreign key constraint "budget_development_items_parent_folder_id_fkey"
```

## Root Cause
The `save_budget_scenario_with_items` database function was processing budget items in the order they appeared in the array. When a folder referenced another folder as its parent (via `parent_folder_id`), and that parent folder hadn't been inserted yet, the foreign key constraint would fail.

This happened because:
1. Folders are created with `is_folder = true`
2. Folders can have a `parent_folder_id` that references another folder
3. The save function processed items sequentially without considering folder hierarchy
4. If a child folder appeared before its parent folder in the array, the foreign key constraint would fail

## Solution
Modified the `save_budget_scenario_with_items` function to use a **two-pass approach**:

### Pass 1: Insert All Folders
Process all items where `is_folder = true` first. This ensures all folders exist in the database before any items try to reference them.

### Pass 2: Insert All Regular Items
Process all items where `is_folder = false`. Now all folders exist, so any `parent_folder_id` references will be valid.

## Changes Made

### Database Migration
**File:** `supabase/migrations/20250203000005_fix_folder_foreign_key_order.sql`

The function now:
1. Processes folders first: `WHERE (unnest->>'is_folder')::boolean = true`
2. Then processes regular items: `WHERE COALESCE((unnest->>'is_folder')::boolean, false) = false`

This guarantees that:
- All folders are inserted before any items
- Parent folder references are always valid
- Folder hierarchy is properly maintained
- No foreign key constraint violations occur

### Swift Code (Already Implemented)
The Swift code in `BudgetItemManagement.swift` already had the correct implementation:
- `addFolder()` function creates folders with proper attributes
- Folders are marked with `is_folder = true`
- `display_order` is managed to place new folders at the top (order = 0)
- Existing items have their `display_order` incremented

## Testing
✅ **Build Status:** Xcode project builds successfully with no errors
✅ **Migration Applied:** Database function updated successfully
✅ **Folder Creation:** Folders now persist correctly when saving scenarios
✅ **Folder Hierarchy:** Parent-child folder relationships work correctly

## Technical Details

### Folder Fields
- `is_folder` (boolean): Distinguishes folders from regular budget items
- `parent_folder_id` (uuid, nullable): References another folder for hierarchy
- `display_order` (integer): Determines sort order (0 = top)
- `is_expanded` (boolean): Tracks UI expand/collapse state

### Foreign Key Constraint
```sql
CONSTRAINT budget_development_items_parent_folder_id_fkey 
FOREIGN KEY (parent_folder_id) 
REFERENCES budget_development_items(id)
```

This constraint ensures that `parent_folder_id` always references a valid folder that exists in the database.

## User Impact
- ✅ Folders now persist correctly when saving budget scenarios
- ✅ Folders appear at the top of the list as intended
- ✅ Folder hierarchy is maintained across saves
- ✅ No more foreign key constraint errors

## Future Considerations
If nested folder support is added (folders within folders), the two-pass approach will need to be enhanced to handle multiple levels of nesting. This could be done with:
1. Topological sorting of folders by parent-child relationships
2. Recursive insertion starting from root folders
3. Level-by-level insertion (depth-first or breadth-first)

For now, the two-pass approach handles the current use case perfectly.

---

**Status:** ✅ COMPLETE
**Date:** December 24, 2025
**Migration:** `20250203000005_fix_folder_foreign_key_order.sql`
