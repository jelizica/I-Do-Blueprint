---
title: AlertPresenter Service Decomposition
type: note
permalink: architecture/services/alert-presenter-service-decomposition
tags:
- architecture
- services
- refactoring
- alert-presenter
- decomposition
- single-responsibility
---

# AlertPresenter Service Decomposition

## Overview
Successfully decomposed AlertPresenter.swift (556 lines) into focused, single-responsibility services following the Domain Services pattern established in the codebase.

## Problem
AlertPresenter.swift had grown to 556 lines with multiple responsibilities:
- Standard alerts
- Confirmation dialogs
- Error alerts with retry logic
- Success alerts
- Toast notifications
- Progress indicators
- Mock implementations for testing

This violated the single responsibility principle and made the file difficult to maintain and test.

## Solution
Split into 7 focused service files:

### 1. AlertPresenterProtocol.swift
- Protocol definition for alert presentation
- ToastType enum
- Defines the contract all alert presenters must follow

### 2. ToastService.swift
- Non-blocking toast notifications
- ToastConfig and ToastView
- Handles success, error, warning, and info toasts
- Auto-dismissal with configurable duration

### 3. ErrorAlertService.swift
- Error-specific alert presentation
- Retry action support
- Network error handling
- UserFacingError integration

### 4. ConfirmationAlertService.swift
- Confirmation dialogs with Yes/No buttons
- Async/await support
- Deprecated callback-based API for backward compatibility

### 5. ProgressAlertService.swift
- Progress indicators for long-running operations
- Custom accessory views with NSProgressIndicator
- Automatic success/error handling

### 6. PreviewAlertPresenter.swift
- Lightweight mock for SwiftUI previews
- No-op implementations for non-blocking previews
- Lives in main target for preview support

### 7. MockAlertPresenter.swift
- Full mock implementation for testing
- Call recording for verification
- Configurable responses
- Moved to test target (I Do BlueprintTests/Helpers/)

### 8. AlertPresenter.swift (Refactored)
- Now acts as coordinator
- Delegates to specialized services
- Maintains backward compatibility
- Reduced from 556 to ~200 lines

## Architecture Pattern

```swift
// Coordinator pattern
@MainActor
class AlertPresenter: ObservableObject, AlertPresenterProtocol {
    private let errorService = ErrorAlertService.shared
    private let confirmationService = ConfirmationAlertService.shared
    private let toastService = ToastService.shared
    private let progressService = ProgressAlertService.shared
    
    // Delegates to specialized services
    func showError(...) async {
        await errorService.showError(...)
    }
}
```

## Benefits

### 1. Single Responsibility
Each service has one clear purpose:
- ToastService: Non-blocking notifications
- ErrorAlertService: Error presentation
- ConfirmationAlertService: User confirmations
- ProgressAlertService: Long operations

### 2. Easier Testing
- Test individual alert types in isolation
- Mock only what you need
- Clear separation between test and preview mocks

### 3. Better Code Organization
- Related functionality grouped together
- Easier to find and modify specific alert types
- Reduced cognitive load

### 4. Maintainability
- Smaller files are easier to understand
- Changes to one alert type don't affect others
- Clear boundaries between services

### 5. Backward Compatibility
- Existing code continues to work
- AlertPresenter.shared still available
- Gradual migration possible

## Usage Examples

### Direct Service Access
```swift
// Use specialized services directly
await ErrorAlertService.shared.showError(
    title: "Network Error",
    message: "Failed to connect",
    retryAction: { await retry() }
)

ToastService.shared.showSuccessToast("Saved successfully")
```

### Through Coordinator
```swift
// Use coordinator for consistency
await AlertPresenter.shared.showError(
    title: "Error",
    message: "Something went wrong"
)

AlertPresenter.shared.showToast(
    message: "Processing...",
    type: .info
)
```

### In Tests
```swift
let mock = MockAlertPresenter()
mock.confirmationResponse = true

await withDependencies {
    $0.alertPresenter = mock
} operation: {
    // Test code
}

XCTAssertEqual(mock.confirmationCalls.count, 1)
```

### In Previews
```swift
#Preview {
    withDependencies {
        $0.alertPresenter = PreviewAlertPresenter()
    } operation: {
        MyView()
    }
}
```

## Migration Path

### Phase 1: Completed ✅
- Split services
- Maintain backward compatibility
- Update dependency injection

### Phase 2: Future
- Migrate views to use specialized services directly
- Remove coordinator delegation where appropriate
- Update documentation

### Phase 3: Future
- Consider removing deprecated callback-based APIs
- Evaluate if coordinator is still needed
- Optimize for most common use cases

## Related Work
- Beads Issue: I Do Blueprint-yzn
- Epic: I Do Blueprint-0t9 (Large Service Files Decomposition)
- Pattern: Domain Services Architecture

## Lessons Learned

### 1. Start with Protocol
Defining the protocol first helped maintain consistency across all implementations.

### 2. Separate Test and Preview Mocks
- MockAlertPresenter: Full featured, lives in test target
- PreviewAlertPresenter: Lightweight, lives in main target

### 3. Coordinator Pattern Works Well
Maintaining AlertPresenter as a coordinator provides:
- Single entry point for existing code
- Gradual migration path
- Flexibility to use services directly

### 4. ObservableObject Requires Combine
Don't forget to import Combine when using @Published properties.

## Next Steps
1. Apply same pattern to other large service files:
   - TimelineAPI.swift (667 lines)
   - DocumentsAPI.swift (747 lines)
   - ExportService.swift (475 lines)
2. Document service decomposition pattern in best practices
3. Create guidelines for when to split services

## Files Modified
- Created: 7 new service files
- Refactored: AlertPresenter.swift
- Updated: DependencyValues.swift
- Moved: MockAlertPresenter.swift to test target

## Build Status
✅ Xcode project builds successfully
✅ All existing functionality preserved
✅ Backward compatibility maintained
