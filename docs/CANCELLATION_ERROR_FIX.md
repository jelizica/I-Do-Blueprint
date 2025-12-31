# Cancellation Error Fix - Settings Tab Switching

## Problem Summary

When switching tabs in Settings, Sentry was receiving multiple `CancellationError` reports from `BudgetCategoryDataSource.checkCategoryDependencies()`. These were being logged as errors and sent to Sentry, creating noise in error tracking.

## Root Cause

1. **`BudgetCategoriesSettingsView`** uses `.task` modifier to load category dependencies
2. When user switches tabs, SwiftUI **automatically cancels** the running `.task`
3. **`CategoryStoreV2.loadCategoryDependencies()`** loops through ALL categories sequentially
4. Each category requires **6 database queries** via `BudgetCategoryDataSource.checkCategoryDependencies()`:
   - Fetch category details
   - Fetch expenses linked to category
   - Fetch subcategories
   - Fetch tasks linked to category
   - Fetch vendors linked to category
   - Fetch budget items (2 queries: by category name, by subcategory name)
5. The code was **not handling `CancellationError`** specifically - treating all cancellations as errors

## Solution

### Fix 1: CategoryStoreV2.swift - Added Cancellation Handling

**File**: `I Do Blueprint/Services/Stores/Budget/CategoryStoreV2.swift`

**Change**: Added specific `CancellationError` catch block in `loadCategoryDependencies()`

```swift
func loadCategoryDependencies() async {
    let start = Date()
    var loadedCount = 0
    
    for category in categories {
        do {
            let deps = try await repository.checkCategoryDependencies(id: category.id)
            categoryDependencies[category.id] = deps
            loadedCount += 1
        } catch is CancellationError {
            // Task was cancelled (e.g., user switched tabs) - this is expected, don't report
            logger.debug("Category dependency load cancelled for category \(category.id)")
            break // Exit loop immediately on cancellation
        } catch {
            // Only report non-cancellation errors
            await handleError(error, operation: "loadCategoryDependencies", context: [
                "categoryId": category.id.uuidString
            ])
        }
    }
    
    let duration = Date().timeIntervalSince(start)
    if loadedCount > 0 {
        logger.info("Loaded dependencies for \(loadedCount)/\(categories.count) categories in \(String(format: "%.2f", duration))s")
    }
}
```

**Key Changes**:
- ✅ Catches `CancellationError` specifically before generic error handler
- ✅ Logs cancellation at **debug level** (not error)
- ✅ **Breaks loop immediately** to stop processing remaining categories
- ✅ Does NOT report cancellations to Sentry
- ✅ Only reports actual errors (non-cancellation) to Sentry

### Existing Protection: BudgetCategoryDataSource.swift

**File**: `I Do Blueprint/Domain/Repositories/Live/Internal/BudgetCategoryDataSource.swift`

**Already Has**: Cancellation checkpoints in `checkCategoryDependencies()`

```swift
func checkCategoryDependencies(id: UUID, tenantId: UUID) async throws -> CategoryDependencies {
    // Check for cancellation before starting expensive operations
    try Task.checkCancellation()
    
    // Fetch category...
    
    // Check for cancellation before continuing with 5 more queries
    try Task.checkCancellation()
    
    // Continue with remaining queries...
}
```

**Benefit**: Stops expensive database operations early if task is cancelled

## Expected Behavior After Fix

### Before Fix
- ❌ Cancellation errors logged as errors
- ❌ Cancellation errors sent to Sentry
- ❌ Loop continued processing all categories even after cancellation
- ❌ Wasted database queries on cancelled operations

### After Fix
- ✅ Cancellation logged at debug level only
- ✅ No Sentry reports for expected cancellations
- ✅ Loop exits immediately on cancellation
- ✅ Database queries stop early via `Task.checkCancellation()`

## Testing

### Manual Test
1. Open Settings
2. Navigate to Budget Categories tab
3. Immediately switch to another Settings tab
4. Check Xcode console - should see debug log: `"Category dependency load cancelled for category <UUID>"`
5. Check Sentry - should NOT see `CancellationError` reports

### Expected Logs
```
[DEBUG] Category dependency load cancelled for category 19112D24-FB3D-475C-A3F4-C984862DA122
[INFO] Loaded dependencies for 3/10 categories in 0.45s
```

## Related Files

- `I Do Blueprint/Services/Stores/Budget/CategoryStoreV2.swift` - Store layer (FIXED)
- `I Do Blueprint/Domain/Repositories/Live/Internal/BudgetCategoryDataSource.swift` - Data source layer (already has checkpoints)
- `I Do Blueprint/Views/Settings/Budget/BudgetCategoriesSettingsView.swift` - View layer (uses `.task`)

## Why This Is Not a Bug

This is **expected SwiftUI behavior**:
- SwiftUI's `.task` modifier automatically cancels when the view disappears
- Tab switching causes the view to disappear
- Cancellation is a normal part of SwiftUI's lifecycle
- The error was in **not handling cancellation gracefully**, not in the cancellation itself

## Best Practices Applied

1. ✅ **Specific error handling**: Catch `CancellationError` before generic `catch`
2. ✅ **Appropriate logging**: Debug level for expected events, error level for problems
3. ✅ **Early exit**: Break loop immediately on cancellation
4. ✅ **Cancellation checkpoints**: Use `Task.checkCancellation()` in expensive operations
5. ✅ **Selective error reporting**: Only report actual errors to Sentry

## Future Considerations

If this pattern appears in other stores, consider:
1. Creating a reusable `handleCancellableLoop` helper
2. Adding cancellation handling to `StoreErrorHandling` extension
3. Documenting this pattern in `best_practices.md`

---

**Date**: 2025-12-31  
**Fixed By**: Claude (Qodo)  
**Sentry Event IDs**: bf7501062cc748b89f5cf69113772fe7, c49b4af013e94b96bf5c48e9e973bf83, c34dddfc781f415b956e653aa54158fe
