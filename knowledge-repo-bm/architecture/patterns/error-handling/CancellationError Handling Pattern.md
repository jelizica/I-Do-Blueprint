---
title: CancellationError Handling Pattern
type: note
permalink: architecture/patterns/cancellation-error-handling-pattern
tags:
- error-handling
- swiftui
- async
- cancellation
- patterns
- stores
---

# CancellationError Handling Pattern

## Problem Statement

When users switch tabs or navigate away from views in SwiftUI, the `.task` modifier automatically cancels any running async operations. If these cancellation errors are not handled properly, they:

1. **Show false error dialogs** to users (e.g., "Unable to load budget data")
2. **Pollute Sentry** with non-actionable error reports
3. **Create noise in logs** that obscures real issues
4. **Degrade user experience** with unnecessary error states

## Root Cause

SwiftUI's `.task` modifier is designed to automatically cancel when:
- The view disappears (user navigates away)
- The view's identity changes
- A new task replaces the previous one (with `.task(id:)`)

This is **expected behavior**, not an error. The problem occurs when code treats `CancellationError` the same as actual errors.

## Solution Architecture

### Layer 1: StoreErrorHandling Extension (Primary Defense)

The `StoreErrorHandling.swift` extension filters out cancellation errors **before** they reach error handling:

```swift
@MainActor
func handleError(
    _ error: Error,
    operation: String,
    context: [String: Any]? = nil,
    retry: (() async -> Void)? = nil
) async {
    // CRITICAL: Filter out cancellation errors first
    if error is CancellationError {
        AppLogger.database.debug("Task cancelled in \(operation) - expected during view lifecycle")
        return  // Don't show error, don't report to Sentry
    }
    
    // Also check for URLError.cancelled
    if let urlError = error as? URLError, urlError.code == .cancelled {
        AppLogger.database.debug("URL request cancelled in \(operation)")
        return
    }
    
    // Only real errors reach this point
    // ... show user-facing error, report to Sentry
}
```

### Layer 2: UserFacingError Mapping (Defense in Depth)

The `UserFacingError.from()` method maps cancellation to a special `.cancelled` case:

```swift
static func from(_ error: Error) -> UserFacingError {
    // Check cancellation first
    if error is CancellationError {
        return .cancelled
    }
    
    if let urlError = error as? URLError, urlError.code == .cancelled {
        return .cancelled
    }
    
    // ... other error mappings
}

var shouldShowToUser: Bool {
    switch self {
    case .cancelled: return false
    default: return true
    }
}
```

### Layer 3: Async Loop Pattern (For Sequential Operations)

When iterating through items with async operations, handle cancellation to exit early:

```swift
func loadCategoryDependencies() async {
    for category in categories {
        do {
            let deps = try await repository.checkCategoryDependencies(id: category.id)
            categoryDependencies[category.id] = deps
        } catch is CancellationError {
            // Expected during tab switching - exit loop immediately
            logger.debug("Category dependency load cancelled for \(category.id)")
            break  // Don't continue processing
        } catch let urlError as URLError where urlError.code == .cancelled {
            logger.debug("URL request cancelled for \(category.id)")
            break
        } catch {
            // Only report actual errors
            await handleError(error, operation: "loadCategoryDependencies")
        }
    }
}
```

### Layer 4: Task Tracking (For Cancellable Operations)

Track tasks to cancel previous operations when new ones start:

```swift
class BudgetStoreV2: ObservableObject {
    private var loadTask: Task<Void, Never>?
    
    func loadBudgetData(force: Bool = false) async {
        // Cancel any previous load
        loadTask?.cancel()
        
        loadTask = Task { @MainActor in
            do {
                try Task.checkCancellation()  // Early exit if already cancelled
                
                // ... perform loading
                
                try Task.checkCancellation()  // Check again before expensive operations
                
            } catch is CancellationError {
                AppLogger.ui.debug("Load cancelled - expected during tenant switch")
                loadingState = .idle
            } catch {
                loadingState = .error(BudgetError.fetchFailed(underlying: error))
            }
        }
        
        await loadTask?.value
    }
}
```

## Implementation Checklist

When adding new async operations:

- [ ] Use `handleError()` extension which auto-filters cancellations
- [ ] For loops with async operations, catch `CancellationError` and `break`
- [ ] For long-running tasks, add `try Task.checkCancellation()` checkpoints
- [ ] Track tasks with `private var loadTask: Task<Void, Never>?` pattern
- [ ] Cancel previous tasks before starting new ones
- [ ] Log cancellations at **debug** level, not error

## Error Types to Handle

| Error Type | How to Detect | Action |
|------------|---------------|--------|
| `CancellationError` | `error is CancellationError` | Log debug, return early |
| `URLError.cancelled` | `urlError.code == .cancelled` | Log debug, return early |
| Task cancellation | `try Task.checkCancellation()` | Throws `CancellationError` |

## Files Modified for This Pattern

1. **`Services/Stores/StoreErrorHandling.swift`** - Primary filter for all stores
2. **`Domain/Models/Shared/UserFacingError.swift`** - Added `.cancelled` case
3. **`Services/Stores/Budget/CategoryStoreV2.swift`** - Loop cancellation handling
4. **`Services/Stores/BudgetStoreV2+PaymentStatus.swift`** - Loop cancellation handling
5. **`Services/Stores/BudgetStoreV2.swift`** - Task tracking pattern

## Testing

### Manual Test
1. Open Settings → Budget Categories
2. Wait for categories to start loading
3. Immediately switch to Budget Configuration tab
4. **Expected**: No error dialog, debug log shows "cancelled"
5. **Verify Sentry**: No `CancellationError` reports

### Expected Console Output
```
[DEBUG] Task cancelled in loadCategoryDependencies - expected during view lifecycle
[DEBUG] Category dependency load cancelled for category 19112D24-FB3D-475C-A3F4-C984862DA122
```

## Anti-Patterns to Avoid

```swift
// ❌ BAD: Treating cancellation as error
} catch {
    await handleError(error, operation: "loadData")  // Shows error dialog for cancellation!
}

// ❌ BAD: Not breaking loop on cancellation
} catch is CancellationError {
    logger.debug("Cancelled")
    // Missing break - continues processing!
}

// ❌ BAD: Logging cancellation as error
} catch is CancellationError {
    logger.error("Operation cancelled")  // Wrong level!
}
```

## Related Documentation

- `docs/CANCELLATION_ERROR_FIX.md` - Original fix documentation
- `best_practices.md` - Error handling guidelines
- SwiftUI `.task` modifier documentation

## Observations

- Cancellation is a **normal part of SwiftUI lifecycle**, not an error
- The fix is in **error handling**, not in preventing cancellation
- Defense in depth: multiple layers catch cancellation at different points
- Always log at **debug** level for expected cancellations


---

## ✅ Status: VERIFIED WORKING (2025-01-01)

This pattern has been fully implemented and tested. The fix successfully prevents false error dialogs when switching between Settings tabs.

---

## Real-World Case Study: CategoryStoreV2

### The Problem

**Issue**: `CancellationError` was being reported to Sentry when users switched tabs in Settings view, creating noise in error monitoring.

**Root Cause**: SwiftUI's `.task` modifier automatically cancels async operations when views disappear (e.g., tab switching). The `CategoryStoreV2.loadCategoryDependencies()` method was catching all errors generically and reporting them to Sentry, including expected cancellations.

### The Solution Applied

```swift
// ✅ CORRECT: Handle cancellations specifically
for item in items {
    do {
        try await processItem(item)
    } catch is CancellationError {
        logger.debug("Operation cancelled")
        break // Exit immediately
    } catch {
        await handleError(error, ...) // Only actual errors
    }
}
```

### Implementation Details

- **File**: `Services/Stores/Budget/CategoryStoreV2.swift`
- **Method**: `loadCategoryDependencies()`
- **Commit**: 4a39c47
- **Message**: "fix: Handle CancellationError gracefully in CategoryStoreV2"
- **Status**: Pushed to origin/main

### The SwiftUI Cancellation Flow

1. **View Layer** (`BudgetCategoriesSettingsView.swift`):
   - Uses `.task` modifier to call `loadCategoryDependencies()`
   - SwiftUI automatically cancels the task when view disappears

2. **Store Layer** (`CategoryStoreV2.swift`):
   - Loops through ALL categories sequentially
   - Each category requires 6 database queries
   - Now catches CancellationError specifically

3. **Data Source Layer** (`BudgetCategoryDataSource.swift`):
   - Already had `Task.checkCancellation()` checkpoints
   - Throws `CancellationError` when task is cancelled

### Testing Verification

#### Manual Test Steps
1. Navigate to Settings → Budget Categories
2. Wait for loading to start (spinner appears)
3. Switch to another tab immediately
4. Check Sentry: Should NOT see CancellationError events
5. Check Xcode console: Should see debug log "Category dependency load cancelled"

#### Expected Behavior
- ✅ No Sentry errors for tab switching
- ✅ Debug logs show cancellation
- ✅ Actual errors still reported to Sentry
- ✅ UI remains responsive

---

## Additional Layer: Domain Error Unwrapping (2025-01-01)

### The Problem

The initial fix filtered `CancellationError` at the top level, but domain errors like `BudgetError.fetchFailed(underlying: CancellationError)` were still being shown because the cancellation was wrapped inside the domain error.

### Layer 5: Domain Error Unwrapping in UserFacingError.from()

```swift
// Check for BudgetError with underlying cancellation
if let budgetError = error as? BudgetError {
    switch budgetError {
    case .fetchFailed(let underlying), .createFailed(let underlying),
         .updateFailed(let underlying), .deleteFailed(let underlying):
        // Recursively check if underlying error is cancellation
        let underlyingUserError = UserFacingError.from(underlying)
        if case .cancelled = underlyingUserError {
            return .cancelled
        }
        return .serverError
    case .networkUnavailable:
        return .networkUnavailable
    case .unauthorized:
        return .unauthorized
    default:
        return .serverError
    }
}
```

Same pattern applied to:
- `GuestError`
- `VendorError`
- `TaskError`

### Layer 6: ErrorAlertService Guard

```swift
func showUserFacingError(_ error: UserFacingError, retryAction: (() async -> Void)? = nil) async {
    // CRITICAL: Don't show alerts for cancellation errors
    guard error.shouldShowToUser else {
        AppLogger.ui.debug("Skipping alert for non-user-facing error")
        return
    }
    // ... show alert
}
```

### Complete Defense in Depth Architecture

```
Layer 1: StoreErrorHandling.handleError()
         ↓ filters CancellationError, returns early
         
Layer 2: UserFacingError.from() - Direct check
         ↓ checks error is CancellationError
         
Layer 3: UserFacingError.from() - URLError check
         ↓ checks URLError.code == .cancelled
         
Layer 4: UserFacingError.from() - Domain error unwrapping
         ↓ unwraps BudgetError/GuestError/VendorError/TaskError
         ↓ recursively checks underlying error
         
Layer 5: UserFacingError.shouldShowToUser
         ↓ returns false for .cancelled
         
Layer 6: ErrorAlertService.showUserFacingError()
         ↓ guards on shouldShowToUser before showing alert
         
Layer 7: Individual store loops
         ↓ catch CancellationError, break immediately
```

### Files Modified (Complete List)

| File | Change |
|------|--------|
| `Services/Stores/StoreErrorHandling.swift` | Primary cancellation filter |
| `Domain/Models/Shared/UserFacingError.swift` | Added `.cancelled` case + domain error unwrapping |
| `Services/UI/ErrorAlertService.swift` | Guard on shouldShowToUser |
| `Services/Stores/Budget/CategoryStoreV2.swift` | Loop-level cancellation handling |
| `Services/Stores/BudgetStoreV2+PaymentStatus.swift` | Loop-level cancellation handling |
| `Services/Stores/BudgetStoreV2.swift` | Task tracking pattern |

---

## Key Takeaways

1. **CancellationError is NOT a bug** - It's expected SwiftUI behavior
2. **Always catch CancellationError specifically** before generic error handlers
3. **Break loops immediately** on cancellation to avoid wasted work
4. **Log at debug level** - Cancellations are informational, not errors
5. **Don't report to Sentry** - Cancellations are expected, not exceptional
6. **Unwrap domain errors** - Check for underlying cancellations in wrapped errors
7. **Defense in depth** - Multiple layers catch different cancellation scenarios

---

## Pattern Template for Other Stores

Apply this pattern to any store that:
- Uses `.task` modifier in views
- Performs sequential async operations
- Reports errors to Sentry

```swift
func loadData() async {
    for item in items {
        do {
            try await processItem(item)
        } catch is CancellationError {
            logger.debug("Operation cancelled for item \(item.id)")
            break // Exit immediately
        } catch {
            await handleError(error, operation: "loadData", ...)
        }
    }
}
```

---

## References

- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [SwiftUI Task Modifier](https://developer.apple.com/documentation/swiftui/view/task(priority:_:))
- Project: `docs/CANCELLATION_ERROR_FIX.md` - Complete fix documentation
- Project: `best_practices.md` - Error Handling section
- Project: `AGENTS.md` - Repository guidelines
