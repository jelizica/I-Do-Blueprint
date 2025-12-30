# Error Handling Standardization Audit

**Date:** 2025-01-XX  
**Issue:** I Do Blueprint-ded  
**Status:** In Progress

## Overview

Audit of all stores to ensure consistent use of the `StoreErrorHandling` extension's `handleError` method instead of direct `self.error` assignment.

## StoreErrorHandling Extension

Located in: `I Do Blueprint/Services/Stores/StoreErrorHandling.swift`

Provides:
- `handleError(_:operation:context:retry:)` - Centralized error handling with Sentry tracking and user feedback
- `showSuccess(_:)` - Success toast notifications
- `addOperationBreadcrumb(_:category:data:)` - Debugging breadcrumbs

## Completed Stores

### ✅ AffordabilityStore.swift
- **Status:** COMPLETED
- **Catch blocks updated:** 18
- **Pattern:** All catch blocks now use `handleError` with proper context and retry callbacks
- **Changes:**
  - loadScenarios()
  - loadContributions(scenarioId:)
  - saveScenario(_:)
  - deleteScenario(id:)
  - saveContribution(_:)
  - deleteContribution(id:scenarioId:)
  - linkGiftsToScenario(giftIds:scenarioId:)
  - unlinkGiftFromScenario(giftId:scenarioId:)
  - saveChanges()
  - createScenario(name:)
  - deleteScenario(_:)
  - addContribution(name:amount:type:date:)
  - deleteContribution(_:)
  - loadAvailableGifts()
  - linkGifts(giftIds:)
  - updateGift(_:)
  - startEditingGift(contributionId:)

### ✅ SettingsStoreV2.swift
- **Status:** PARTIALLY COMPLETED
- **Uses handleError in:** saveBudgetSettings(), save*Settings() methods
- **Still needs work:** Some catch blocks still use direct error assignment

### ✅ CollaborationStoreV2.swift
- **Status:** PARTIALLY COMPLETED
- **Uses handleError in:** Some operations
- **Pattern:** Includes retry callbacks

### ✅ VisualPlanningStoreV2.swift
- **Status:** PARTIALLY COMPLETED
- **Uses handleError in:** Color palette and seating chart operations

### ✅ DocumentStoreV2.swift
- **Status:** PARTIALLY COMPLETED
- **Uses handleError in:** Delete operations

## Stores Needing Updates

### ❌ ExpenseStoreV2.swift
- **Catch blocks:** ~10
- **Current pattern:** Direct `self.error` assignment
- **Priority:** HIGH (core budget functionality)

### ❌ CategoryStoreV2.swift
- **Catch blocks:** ~8
- **Current pattern:** Direct `self.error` assignment + logger.error
- **Priority:** HIGH (core budget functionality)

### ❌ GiftsStore.swift
- **Catch blocks:** ~12
- **Current pattern:** Direct `self.error` assignment
- **Priority:** MEDIUM

### ❌ PaymentScheduleStore.swift
- **Catch blocks:** ~15
- **Current pattern:** Direct `self.error` assignment + complex rollback logic
- **Priority:** HIGH (payment tracking)

### ❌ BudgetDevelopmentStoreV2.swift
- **Catch blocks:** ~12
- **Current pattern:** logger.error only, no user feedback
- **Priority:** MEDIUM

### ❌ TimelineStoreV2.swift
- **Catch blocks:** ~8
- **Current pattern:** Mixed - some use showSuccess, errors set loadingState
- **Priority:** MEDIUM

### ❌ VendorStoreV2.swift
- **Catch blocks:** ~6
- **Current pattern:** Mixed - some use showSuccess
- **Priority:** MEDIUM

### ❌ GuestStoreV2.swift
- **Catch blocks:** ~5
- **Current pattern:** Sets loadingState.error
- **Priority:** HIGH (core functionality)

### ❌ TaskStoreV2.swift
- **Catch blocks:** ~8
- **Current pattern:** Sets loadingState.error
- **Priority:** MEDIUM

### ❌ NotesStoreV2.swift
- **Catch blocks:** ~8
- **Current pattern:** Sets loadingState.error + rollback
- **Priority:** LOW

### ❌ ActivityFeedStoreV2.swift
- **Catch blocks:** ~5
- **Current pattern:** Sets loadingState.error
- **Priority:** LOW

### ❌ PresenceStoreV2.swift
- **Catch blocks:** ~6
- **Current pattern:** Sets loadingState.error, some silent failures
- **Priority:** LOW

### ❌ OnboardingStoreV2.swift
- **Catch blocks:** ~8
- **Current pattern:** logger.error only
- **Priority:** MEDIUM

### ❌ BudgetStoreV2.swift
- **Catch blocks:** ~3
- **Current pattern:** Sets loadingState.error
- **Priority:** HIGH (main budget store)

### ❌ DocumentUploadStore.swift
- **Catch blocks:** ~3
- **Current pattern:** Mixed patterns
- **Priority:** MEDIUM

### ❌ DocumentBatchStore.swift
- **Catch blocks:** ~5
- **Current pattern:** AppLogger.ui.error only
- **Priority:** LOW

### ❌ VendorCategoryStore.swift
- **Catch blocks:** ~3
- **Current pattern:** Sets self.error + onError callback
- **Priority:** LOW

### ❌ SettingsSectionStore.swift
- **Catch blocks:** ~2
- **Current pattern:** setValue(original) rollback
- **Priority:** LOW

### ❌ SettingsLoadingService.swift
- **Catch blocks:** ~3
- **Current pattern:** Mixed patterns
- **Priority:** LOW

### ❌ SettingsSaveHelper.swift
- **Catch blocks:** ~2
- **Current pattern:** Rollback + onError callback
- **Priority:** LOW

### ❌ OnboardingProgressService.swift
- **Catch blocks:** ~6
- **Current pattern:** logger.error only
- **Priority:** LOW

### ❌ OnboardingCollaboratorService.swift
- **Catch blocks:** ~1
- **Current pattern:** Silent failure (empty catch)
- **Priority:** LOW

### ❌ BudgetStoreV2+PaymentStatus.swift
- **Catch blocks:** ~2
- **Current pattern:** logger.error only
- **Priority:** MEDIUM

## API Files (Lower Priority)

These files have catch blocks but are not stores:
- DocumentsAPI.swift
- Various service files

## Recommended Approach

### Phase 1: High Priority Stores (Core Functionality)
1. ✅ AffordabilityStore.swift - COMPLETED
2. ExpenseStoreV2.swift
3. CategoryStoreV2.swift
4. PaymentScheduleStore.swift
5. GuestStoreV2.swift
6. BudgetStoreV2.swift

### Phase 2: Medium Priority Stores
1. GiftsStore.swift
2. BudgetDevelopmentStoreV2.swift
3. TimelineStoreV2.swift
4. VendorStoreV2.swift
5. TaskStoreV2.swift
6. OnboardingStoreV2.swift
7. DocumentUploadStore.swift
8. BudgetStoreV2+PaymentStatus.swift

### Phase 3: Low Priority Stores
1. NotesStoreV2.swift
2. ActivityFeedStoreV2.swift
3. PresenceStoreV2.swift
4. DocumentBatchStore.swift
5. VendorCategoryStore.swift
6. SettingsSectionStore.swift
7. SettingsLoadingService.swift
8. SettingsSaveHelper.swift
9. OnboardingProgressService.swift
10. OnboardingCollaboratorService.swift

### Phase 4: Complete Partial Implementations
1. SettingsStoreV2.swift
2. CollaborationStoreV2.swift
3. VisualPlanningStoreV2.swift
4. DocumentStoreV2.swift

## Standard Pattern

```swift
func someOperation() async {
    do {
        // Operation logic
        let result = try await repository.performOperation()
        
        // Update state
        self.data = result
        
        // Optional: Show success
        showSuccess("Operation completed successfully")
        
    } catch {
        // Use handleError extension
        await handleError(
            error,
            operation: "someOperation",
            context: [
                "key1": "value1",
                "key2": value2
            ]
        ) { [weak self] in
            // Optional: Retry callback
            await self?.someOperation()
        }
        
        // Still set local error for UI state
        self.error = .operationFailed(underlying: error)
    }
}
```

## Benefits of Standardization

1. **Consistent Sentry Tracking:** All errors automatically captured with context
2. **User Feedback:** Consistent error messages and retry options
3. **Debugging:** Breadcrumbs for error investigation
4. **Maintainability:** Single source of truth for error handling
5. **Testing:** Easier to mock and test error scenarios

## Testing Checklist

After updating each store:
- [ ] Build succeeds
- [ ] Error scenarios show user-facing alerts
- [ ] Sentry captures errors with context
- [ ] Retry callbacks work correctly
- [ ] Rollback logic preserved where needed
- [ ] Loading states updated appropriately

## Notes

- Some stores use `LoadingState<T>` enum instead of separate error properties
- Rollback logic should be preserved in catch blocks
- Silent failures (empty catch blocks) should be evaluated case-by-case
- Some operations intentionally don't show user errors (e.g., heartbeats, background sync)
