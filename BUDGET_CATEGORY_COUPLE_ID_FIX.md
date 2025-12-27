# Budget Category Couple ID Fix

## Issue
Users were unable to create new budget categories or subcategories from the Budget Development page. The error was:
```
new row violates row-level security policy for table "budget_categories"
```

## Root Cause
When creating new `BudgetCategory` objects in `BudgetItemManagement.swift` and `AddBudgetCategoryView.swift`, the `coupleId` was being set to a **random UUID** instead of the current user's tenant ID:

```swift
// ❌ WRONG - Creates a random UUID that doesn't match any collaborator record
let newCategory = BudgetCategory(
    id: UUID(),
    coupleId: UUID(),  // This was the bug!
    categoryName: trimmedName,
    ...
)
```

The RLS policy on `budget_categories` requires that the `couple_id` matches one of the user's active collaborator records. Since a random UUID was being used, the INSERT was always rejected.

## Solution
Updated all places where `BudgetCategory` is created to use `SessionManager.shared.getTenantId()` to get the current user's couple ID:

```swift
// ✅ CORRECT - Uses the current tenant's couple ID
guard let coupleId = SessionManager.shared.getTenantId() else {
    logger.error("Cannot create category: No couple selected")
    return
}

let newCategory = BudgetCategory(
    id: UUID(),
    coupleId: coupleId,  // Now uses the correct couple ID
    categoryName: trimmedName,
    ...
)
```

## Files Modified

### 1. `I Do Blueprint/Views/Budget/Components/Development/BudgetItemManagement.swift`
- Fixed `handleNewCategoryName()` function
- Fixed `handleNewSubcategoryName()` function

### 2. `I Do Blueprint/Views/Budget/AddBudgetCategoryView.swift`
- Fixed `saveBudgetCategory()` function

## Files Already Correct
- `I Do Blueprint/Views/Budget/ExpenseCategoriesView.swift` - Already using `SessionManager.shared.getTenantId()`

## RLS Policy Reference
The INSERT policy on `budget_categories` requires:
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

This policy ensures users can only create categories for couples they are active collaborators for.

## Testing
After this fix, users should be able to:
1. Create new budget categories from the Budget Development page
2. Create new subcategories from the Budget Development page
3. Create categories from the Add Budget Category view

## Date
2025-12-26
