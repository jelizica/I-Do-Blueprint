# Budget Categories RLS Fix

## Issue
Users were unable to create subcategories in the budget development scenario tab. The error was:
```
new row violates row-level security policy for table "budget_categories"
```

## Root Cause
The INSERT RLS policy on `budget_categories` was using the `get_user_couple_ids()` function:
```sql
WITH CHECK (couple_id = ANY (get_user_couple_ids()))
```

This approach had issues because:
1. The function uses `auth.uid()` internally, which may not be properly evaluated during INSERT operations
2. The function returns an array, and the `ANY` operator may not work reliably in all contexts
3. The function is marked as `SECURITY DEFINER`, which can cause permission issues

## Solution
Replaced the INSERT policy with a direct EXISTS check against the `collaborators` table:

```sql
CREATE POLICY budget_categories_insert ON budget_categories
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM collaborators 
            WHERE collaborators.user_id = (SELECT auth.uid())
            AND collaborators.couple_id = budget_categories.couple_id
            AND collaborators.status = 'active'
        )
    );
```

### Why This Works
1. **Direct check**: Directly queries the `collaborators` table instead of using a function
2. **Explicit auth.uid()**: Uses `(SELECT auth.uid())` which is the recommended pattern for RLS policies
3. **Clear logic**: The EXISTS clause is more explicit and easier to debug
4. **Consistent with other policies**: Matches the pattern used in other RLS policies across the database

## Migration Applied
- **File**: `supabase/migrations/[timestamp]_fix_budget_categories_insert_rls.sql`
- **Date**: 2025-12-24
- **Status**: ✅ Applied successfully

## Testing
After applying the migration, users should be able to:
1. Create new budget categories
2. Create subcategories (categories with a parent_category_id)
3. All operations should respect multi-tenant isolation (users can only create categories for couples they are active collaborators for)

## Related Files
- `I Do Blueprint/Domain/Repositories/Live/LiveBudgetRepository.swift` - Budget repository implementation
- `I Do Blueprint/Services/Stores/Budget/BudgetStoreV2.swift` - Budget store that calls the repository
- `docs/database/RLS_POLICIES.md` - RLS policy documentation

## Verification Steps
1. ✅ Verified user has active collaborator records
2. ✅ Verified existing budget_categories exist for the couple_id
3. ✅ Updated INSERT policy to use direct EXISTS check
4. ✅ Confirmed policy syntax is correct

## Notes
- The other policies (SELECT, UPDATE, DELETE) still use `get_user_couple_ids()` and are working correctly
- Consider updating those policies to use the same pattern for consistency
- The `get_user_couple_ids()` function is still used elsewhere and should be kept for now
