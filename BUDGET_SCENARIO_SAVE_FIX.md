# Budget Scenario Save Function - Column Names Fix

## Problem
When saving items to the primary budget development scenario, the app was failing with:
```
HTTP 409 Conflict
Error: column "total_estimate" of relation "budget_development_scenarios" does not exist
PostgreSQL Error Code: 42703
```

## Root Cause
The RPC function `save_budget_scenario_with_items` was attempting to insert into non-existent columns:
- ❌ `total_estimate` (doesn't exist)
- ❌ `total_with_tax` (exists, but was being used incorrectly)

The actual columns in the `budget_development_scenarios` table are:
- ✅ `total_without_tax` (numeric)
- ✅ `total_tax` (numeric)
- ✅ `total_with_tax` (numeric)

## Investigation
1. **Examined SavedScenario model** (`Domain/Models/Budget/Budget.swift`)
   - Found correct field mappings in CodingKeys:
     - `totalWithoutTax` → `total_without_tax`
     - `totalTax` → `total_tax`
     - `totalWithTax` → `total_with_tax`

2. **Examined RPC function** (`supabase/migrations/20250224000000_create_save_budget_scenario_with_items_rpc.sql`)
   - Found it was trying to insert `total_estimate` and `total_with_tax` only
   - Missing `total_without_tax` and `total_tax` columns

3. **Verified client code** (`Domain/Repositories/Live/LiveBudgetRepository.swift`)
   - `saveBudgetScenarioWithItems()` method correctly encodes SavedScenario
   - Client code was correct; RPC function was wrong

## Solution
Updated both RPC migration files to use correct column names:

### File 1: `20250224000000_create_save_budget_scenario_with_items_rpc.sql`
**Changed:**
```sql
-- BEFORE (WRONG)
INSERT INTO public.budget_development_scenarios (
    id,
    couple_id,
    scenario_name,
    total_estimate,           -- ❌ DOESN'T EXIST
    total_with_tax,           -- ❌ INCOMPLETE
    is_primary,
    created_at,
    updated_at
)
VALUES (
    v_scenario_id,
    v_couple_id,
    p_scenario->>'scenario_name',
    (p_scenario->>'total_estimate')::numeric,      -- ❌ WRONG FIELD
    (p_scenario->>'total_with_tax')::numeric,      -- ❌ INCOMPLETE
    ...
)
ON CONFLICT (id) DO UPDATE SET
    scenario_name = EXCLUDED.scenario_name,
    total_estimate = EXCLUDED.total_estimate,      -- ❌ WRONG
    total_with_tax = EXCLUDED.total_with_tax,      -- ❌ INCOMPLETE
    is_primary = EXCLUDED.is_primary,
    updated_at = now();

-- AFTER (CORRECT)
INSERT INTO public.budget_development_scenarios (
    id,
    couple_id,
    scenario_name,
    total_without_tax,        -- ✅ CORRECT
    total_tax,                -- ✅ CORRECT
    total_with_tax,           -- ✅ CORRECT
    is_primary,
    created_at,
    updated_at
)
VALUES (
    v_scenario_id,
    v_couple_id,
    p_scenario->>'scenario_name',
    (p_scenario->>'total_without_tax')::numeric,   -- ✅ CORRECT FIELD
    (p_scenario->>'total_tax')::numeric,           -- ✅ CORRECT FIELD
    (p_scenario->>'total_with_tax')::numeric,      -- ✅ CORRECT FIELD
    ...
)
ON CONFLICT (id) DO UPDATE SET
    scenario_name = EXCLUDED.scenario_name,
    total_without_tax = EXCLUDED.total_without_tax,  -- ✅ CORRECT
    total_tax = EXCLUDED.total_tax,                  -- ✅ CORRECT
    total_with_tax = EXCLUDED.total_with_tax,        -- ✅ CORRECT
    is_primary = EXCLUDED.is_primary,
    updated_at = now();
```

### File 2: `20250224000001_fix_save_budget_scenario_function_overload.sql`
**Applied same fix** to the duplicate function definition

### Documentation Update
Updated function comment to reflect correct parameters:
```sql
-- BEFORE
'Parameters:
  - p_scenario: JSON object with scenario data (id, couple_id, scenario_name, total_estimate, total_with_tax, is_primary)'

-- AFTER
'Parameters:
  - p_scenario: JSON object with scenario data (id, couple_id, scenario_name, total_without_tax, total_tax, total_with_tax, is_primary)'
```

## Impact
- ✅ Budget scenario saves will now succeed
- ✅ All three total columns will be properly persisted
- ✅ No changes needed to client code (SavedScenario model was already correct)
- ✅ No changes needed to database schema (columns already exist)

## Testing
To verify the fix works:
1. Navigate to Budget → Development Scenarios
2. Create or edit a budget scenario
3. Add items to the scenario
4. Click "Save" button
5. Verify the scenario saves without errors
6. Verify all three total columns are populated in the database:
   ```sql
   SELECT id, scenario_name, total_without_tax, total_tax, total_with_tax 
   FROM budget_development_scenarios 
   WHERE couple_id = '<your-couple-id>' 
   ORDER BY created_at DESC 
   LIMIT 1;
   ```

## Files Modified
1. `/supabase/migrations/20250224000000_create_save_budget_scenario_with_items_rpc.sql`
2. `/supabase/migrations/20250224000001_fix_save_budget_scenario_function_overload.sql`

## Related Code
- **Model**: `I Do Blueprint/Domain/Models/Budget/Budget.swift` (SavedScenario struct)
- **Repository**: `I Do Blueprint/Domain/Repositories/Live/LiveBudgetRepository.swift` (saveBudgetScenarioWithItems method)
- **RPC Calls**: Both migrations define the same function with correct column names

## Notes
- The error was a mismatch between what the RPC function expected and what the database table actually had
- The client code was correct all along
- This is a good example of why it's important to keep RPC function definitions in sync with actual database schema
- The fix ensures data consistency across all three total columns (without tax, tax amount, and with tax)
