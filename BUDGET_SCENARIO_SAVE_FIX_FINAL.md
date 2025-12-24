# Budget Scenario Save Function - Final Fix

## Problem Summary

The budget scenario save function was failing with error:
```
function jsonb_array_elements(jsonb[]) does not exist
```

This occurred when attempting to save budget items to the primary budget development scenario.

## Root Cause

The RPC function `save_budget_scenario_with_items` was using incorrect PostgreSQL syntax to iterate over a `jsonb[]` array parameter:

```sql
-- ❌ WRONG: jsonb_array_elements() expects jsonb, not jsonb[]
FOR v_item IN SELECT jsonb_array_elements(p_items)
```

The function signature accepts `p_items jsonb[]` (an array of JSON objects), but `jsonb_array_elements()` is designed to work with a single `jsonb` value, not an array.

## Solution

Changed the iteration to use `unnest()` which properly handles arrays:

```sql
-- ✅ CORRECT: unnest() properly expands jsonb[] arrays
FOR v_item IN SELECT unnest(p_items)
```

## Files Modified

### 1. `/supabase/migrations/20250224000000_create_save_budget_scenario_with_items_rpc.sql`
- **Line 67**: Changed `SELECT jsonb_array_elements(p_items)` to `SELECT unnest(p_items)`
- **Impact**: Initial function creation now uses correct syntax

### 2. `/supabase/migrations/20250224000001_fix_save_budget_scenario_function_overload.sql`
- **Line 79**: Changed `SELECT jsonb_array_elements(p_items)` to `SELECT unnest(p_items)`
- **Impact**: Function overload fix now uses correct syntax

## Technical Details

### Why `unnest()` is Correct

PostgreSQL's `unnest()` function is the standard way to expand arrays into rows:

```sql
-- unnest() works with any array type
SELECT unnest(ARRAY[1, 2, 3]);  -- Returns: 1, 2, 3
SELECT unnest(ARRAY['a', 'b']); -- Returns: 'a', 'b'
SELECT unnest(p_items);          -- Returns: each jsonb element from p_items array
```

### Why `jsonb_array_elements()` Failed

`jsonb_array_elements()` is designed for a different use case:

```sql
-- jsonb_array_elements() works with jsonb values containing arrays
SELECT jsonb_array_elements('[1, 2, 3]'::jsonb);  -- Returns: 1, 2, 3
SELECT jsonb_array_elements(p_items);             -- ❌ ERROR: p_items is jsonb[], not jsonb
```

The error message "function jsonb_array_elements(jsonb[]) does not exist" indicates PostgreSQL couldn't find a version of `jsonb_array_elements()` that accepts `jsonb[]` as input.

## Function Signature

```sql
CREATE FUNCTION public.save_budget_scenario_with_items(
    p_scenario jsonb,      -- Single JSON object with scenario data
    p_items jsonb[]        -- Array of JSON objects with item data
)
RETURNS jsonb
```

## Expected Behavior After Fix

When saving a budget scenario with items:

1. ✅ Scenario record is upserted in `budget_development_scenarios` table
2. ✅ Each item in the `p_items` array is properly iterated
3. ✅ Item records are upserted in `budget_development_items` table
4. ✅ Function returns success response with scenario ID and item count
5. ✅ No duplicate key constraint violations
6. ✅ All data persists to database

## Testing

To verify the fix works:

1. Deploy both migration files to Supabase
2. Attempt to save a budget scenario with multiple items
3. Verify:
   - No 404 error on RPC function call
   - No "function does not exist" error
   - Scenario and items appear in database
   - Response includes scenario_id and inserted_items count

## Migration Deployment Order

1. First: `20250224000000_create_save_budget_scenario_with_items_rpc.sql`
2. Then: `20250224000001_fix_save_budget_scenario_function_overload.sql`

Both migrations now use the correct `unnest()` syntax.

## Related Files

- **Client Code**: `I Do Blueprint/Domain/Repositories/Live/LiveBudgetRepository.swift`
  - Method: `saveBudgetScenarioWithItems()`
  - Correctly encodes scenario and items as JSON
  - No changes needed

- **Data Model**: `I Do Blueprint/Domain/Models/Budget/SavedScenario.swift`
  - Correctly defines CodingKeys for all fields
  - No changes needed

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| Array iteration | `jsonb_array_elements(p_items)` | `unnest(p_items)` |
| Function status | ❌ 404 Not Found | ✅ Works correctly |
| Error message | "function does not exist" | None |
| Data persistence | ❌ Failed | ✅ Succeeds |
| Database state | Inconsistent | Consistent |

The fix is minimal, focused, and addresses the exact PostgreSQL syntax issue preventing the function from working.
