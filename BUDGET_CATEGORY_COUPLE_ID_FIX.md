# Budget Category Creation Fix - Couple ID Issue

## Problem Summary

When users attempted to create new budget categories or subcategories in the Budget Development scenario, they received an RLS (Row Level Security) policy violation error:

```
Error: new row violates row-level security policy for table "budget_categories"
PostgrestError(code: "42501", message: "new row violates row-level security policy for table \"budget_categories\"")
```

## Root Cause

The issue was in the Swift code, not the database. Two files were creating `BudgetCategory` objects with **random UUIDs** for the `coupleId` field instead of using the actual tenant's couple ID:

### Affected Files:
1. **BudgetItemManagement.swift** - Budget Development view
2. **AddBudgetCategoryView.swift** - Add Category modal

### The Bug:
```swift
// ❌ WRONG: Creates random UUID
let newCategory = BudgetCategory(
    id: UUID(),
    coupleId: UUID(),  // <-- This generates a random UUID!
    categoryName: trimmedName,
    // ... other fields
)
```

This random UUID would never match any collaborator records in the database, causing the RLS policy to reject the insert operation.

## The Fix

Changed both files to use `SessionManager.shared.getTenantId()` to get the actual couple ID:

```swift
// ✅ CORRECT: Uses actual tenant ID
guard let coupleId = SessionManager.shared.getTenantId() else {
    logger.error("Cannot create category: No couple selected")
    return
}

let newCategory = BudgetCategory(
    id: UUID(),
    coupleId: coupleId,  // <-- Uses actual couple ID
    categoryName: trimmedName,
    // ... other fields
)
```

## Files Modified

### 1. BudgetItemManagement.swift
**Location:** `I Do Blueprint/Views/Budget/Components/Development/BudgetItemManagement.swift`

**Changes:**
- Fixed `handleNewCategoryName()` function to use actual couple ID
- Fixed `handleNewSubcategoryName()` function to use actual couple ID
- Added guard statements to check for valid tenant ID before creating categories
- Added error logging when tenant ID is missing

**Lines Changed:**
- Line 119: Added guard statement and changed `coupleId: UUID()` to `coupleId: coupleId`
- Line 161: Added guard statement and changed `coupleId: UUID()` to `coupleId: coupleId`

### 2. AddBudgetCategoryView.swift
**Location:** `I Do Blueprint/Views/Budget/AddBudgetCategoryView.swift`

**Changes:**
- Fixed `saveBudgetCategory()` function to use actual couple ID
- Added guard statement to check for valid tenant ID
- Added error logging when tenant ID is missing

**Lines Changed:**
- Line 217: Added guard statement and changed `coupleId: UUID()` to `coupleId: coupleId`

## RLS Policy Status

The RLS policy on `budget_categories` table is **correct** and working as designed:

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

This policy ensures that:
1. User must be authenticated
2. User must have an active collaborator record
3. The `couple_id` in the new category must match a couple the user has access to

The policy was correctly rejecting inserts with random UUIDs because those UUIDs didn't match any valid couple IDs.

## Build Verification

✅ **Build Status: SUCCESS**

The Xcode project was built successfully after applying the fixes:
```
** BUILD SUCCEEDED **
```

No compilation errors or warnings related to the changes.

## Testing Checklist

After applying this fix, verify:

- [ ] User can create new top-level budget categories in Budget Development
- [ ] User can create subcategories (with parent_category_id) in Budget Development
- [ ] User can create categories from the Add Category modal
- [ ] Error is logged if user somehow doesn't have a tenant ID
- [ ] Categories are properly scoped to the user's couple
- [ ] RLS policy continues to prevent unauthorized access

## Related Code Patterns

### ✅ Correct Pattern (Already Used Elsewhere)
```swift
// ExpenseCategoriesView.swift - CORRECT
guard let coupleId = SessionManager.shared.getTenantId() else {
    return
}

let category = BudgetCategory(
    id: UUID(),
    coupleId: coupleId,  // ✅ Uses actual tenant ID
    // ...
)
```

### ❌ Anti-Pattern (Now Fixed)
```swift
// WRONG - Don't do this!
let category = BudgetCategory(
    id: UUID(),
    coupleId: UUID(),  // ❌ Random UUID
    // ...
)
```

## Prevention

To prevent similar issues in the future:

1. **Code Review**: Always check that `coupleId` uses `SessionManager.shared.getTenantId()`
2. **Linting**: Consider adding a SwiftLint rule to detect `coupleId: UUID()`
3. **Testing**: Add integration tests that verify RLS policies work correctly
4. **Documentation**: Update best practices to emphasize proper tenant ID usage

## Best Practices

When creating any multi-tenant entity (Guest, Vendor, Task, etc.):

```swift
// 1. Always get tenant ID first
guard let coupleId = SessionManager.shared.getTenantId() else {
    logger.error("Cannot create entity: No couple selected")
    return
}

// 2. Use it in the entity creation
let entity = Entity(
    id: UUID(),
    coupleId: coupleId,  // ✅ Use the actual tenant ID
    // ... other fields
)

// 3. Log the operation
logger.info("Created entity for couple: \(coupleId)")
```

## Impact

- **Severity**: High (blocking feature)
- **Scope**: Budget category creation in 2 views
- **Users Affected**: All users trying to create categories in Budget Development
- **Data Impact**: None (no data corruption, just prevented creation)
- **Migration Required**: No (code-only fix)
- **Build Impact**: None (builds successfully)

## References

- **RLS Documentation**: `docs/database/RLS_POLICIES.md`
- **Best Practices**: `best_practices.md` (Multi-Tenant Security Pattern)
- **Previous Fix**: `BUDGET_CATEGORIES_SUBCATEGORY_FIX_SUMMARY.md` (RLS policy fix)
- **Session Management**: `I Do Blueprint/Services/Auth/SessionManager.swift`
- **Tenant Context**: `I Do Blueprint/Core/Common/Auth/TenantContext.swift`

## Status

- **Issue**: ✅ Fixed
- **Root Cause**: ✅ Identified (random UUID instead of tenant ID)
- **Code Changes**: ✅ Applied
- **Build Verification**: ✅ Passed
- **Testing**: ⏳ Pending user verification
- **Documentation**: ✅ Complete

---

**Date Fixed**: 2025-01-26  
**Fixed By**: AI Assistant  
**Build Status**: ✅ SUCCESS  
**Breaking Changes**: None  
**Deployment**: Code change only, no migration required
