---
title: Proportional Modal Sizing Pattern
type: note
permalink: architecture/patterns/component-patterns/proportional-modal-sizing-pattern
tags:
- swiftui
- pattern
- modal
- sheet
- sizing
- responsive
- macos
- window
---

# Proportional Modal Sizing Pattern

> **Status:** ✅ PRODUCTION READY  
> **Created:** January 2026  
> **Context:** Expense Tracker Add/Edit Modal Fix  
> **Problem Solved:** Modals extending into dock on small windows

---

## Overview

The Proportional Modal Sizing Pattern ensures modals scale appropriately with the parent window size, preventing them from extending beyond the visible area (into the dock, menu bar, or off-screen).

---

## Problem

### Fixed Modal Sizes

```swift
// ❌ PROBLEM: Fixed sizes don't adapt to window
.frame(minWidth: 700, idealWidth: 750, maxWidth: 800,
       minHeight: 650, idealHeight: 750, maxHeight: 850)
```

**Issues:**
1. Modal may be larger than parent window
2. Modal extends into dock on small screens
3. Modal may be off-screen on 13" MacBook Air
4. No relationship to actual available space

---

## Solution

Calculate modal size as a **proportion of parent window size** with min/max bounds:

```swift
private var dynamicSize: CGSize {
    let parentSize = coordinator.parentWindowSize
    
    // Target: 60% width, 75% height
    let targetWidth = min(maxWidth, max(minWidth, parentSize.width * 0.6))
    let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.75 - windowChromeBuffer))
    
    return CGSize(width: targetWidth, height: targetHeight)
}
```

---

## Implementation

### 1. Define Constants

```swift
struct ExpenseTrackerAddView: View {
    // Size constraints
    private let minWidth: CGFloat = 400
    private let maxWidth: CGFloat = 700
    private let minHeight: CGFloat = 350
    private let maxHeight: CGFloat = 850
    private let windowChromeBuffer: CGFloat = 40  // Account for title bar, etc.
    
    // Proportions
    private let widthProportion: CGFloat = 0.6   // 60% of parent width
    private let heightProportion: CGFloat = 0.75 // 75% of parent height
}
```

### 2. Access Parent Window Size

```swift
@EnvironmentObject var coordinator: AppCoordinator

// Or inject directly
@ObservedObject var coordinator = AppCoordinator.shared
```

### 3. Calculate Dynamic Size

```swift
private var dynamicSize: CGSize {
    let parentSize = coordinator.parentWindowSize
    
    // Calculate proportional size
    let targetWidth = parentSize.width * widthProportion
    let targetHeight = parentSize.height * heightProportion - windowChromeBuffer
    
    // Clamp to min/max bounds
    let finalWidth = min(maxWidth, max(minWidth, targetWidth))
    let finalHeight = min(maxHeight, max(minHeight, targetHeight))
    
    return CGSize(width: finalWidth, height: finalHeight)
}
```

### 4. Apply to View

```swift
var body: some View {
    ScrollView {
        // Modal content
    }
    .frame(width: dynamicSize.width, height: dynamicSize.height)
}
```

---

## Complete Example

```swift
struct ExpenseTrackerAddView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss
    
    // Size constraints
    private let minWidth: CGFloat = 400
    private let maxWidth: CGFloat = 700
    private let minHeight: CGFloat = 350
    private let maxHeight: CGFloat = 850
    private let windowChromeBuffer: CGFloat = 40
    
    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        let targetWidth = min(maxWidth, max(minWidth, parentSize.width * 0.6))
        let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.75 - windowChromeBuffer))
        return CGSize(width: targetWidth, height: targetHeight)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            modalHeader
            
            // Content
            ScrollView {
                formContent
            }
            
            // Footer
            modalFooter
        }
        .frame(width: dynamicSize.width, height: dynamicSize.height)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
```

---

## Recommended Proportions

| Modal Type | Width | Height | Use Case |
|------------|-------|--------|----------|
| Small form | 50% | 60% | Quick add, confirmation |
| Standard form | 60% | 75% | Add/Edit with multiple fields |
| Large form | 70% | 85% | Complex forms, multi-step |
| Detail view | 65% | 80% | Read-only detail display |

---

## Size Bounds by Modal Type

### Small Modal (Quick Add)

```swift
private let minWidth: CGFloat = 300
private let maxWidth: CGFloat = 500
private let minHeight: CGFloat = 250
private let maxHeight: CGFloat = 500
```

### Standard Modal (Add/Edit)

```swift
private let minWidth: CGFloat = 400
private let maxWidth: CGFloat = 700
private let minHeight: CGFloat = 350
private let maxHeight: CGFloat = 850
```

### Large Modal (Complex Form)

```swift
private let minWidth: CGFloat = 500
private let maxWidth: CGFloat = 900
private let minHeight: CGFloat = 450
private let maxHeight: CGFloat = 950
```

---

## Window Chrome Buffer

The `windowChromeBuffer` accounts for:
- Title bar (~28px)
- Toolbar (if present)
- Safe area insets
- Dock visibility

**Recommended value:** 40px

```swift
private let windowChromeBuffer: CGFloat = 40
```

---

## AppCoordinator Integration

### Tracking Parent Window Size

```swift
class AppCoordinator: ObservableObject {
    @Published var parentWindowSize: CGSize = CGSize(width: 1200, height: 800)
    
    func updateWindowSize(_ size: CGSize) {
        parentWindowSize = size
    }
}
```

### In Root View

```swift
struct RootView: View {
    @StateObject var coordinator = AppCoordinator.shared
    
    var body: some View {
        GeometryReader { geometry in
            MainContent()
                .onChange(of: geometry.size) { _, newSize in
                    coordinator.updateWindowSize(newSize)
                }
                .onAppear {
                    coordinator.updateWindowSize(geometry.size)
                }
        }
        .environmentObject(coordinator)
    }
}
```

---

## Presenting the Modal

```swift
// In parent view
.sheet(isPresented: $showAddExpense) {
    ExpenseTrackerAddView()
        .environmentObject(coordinator)
}
```

---

## Testing Checklist

| Window Size | Expected Modal Size |
|-------------|---------------------|
| 1200 x 800 | 700 x 560 (clamped to max width) |
| 900 x 700 | 540 x 485 |
| 700 x 600 | 420 x 410 |
| 600 x 500 | 400 x 335 (clamped to min) |

### Test Scenarios

- [ ] Modal fits within parent window at all sizes
- [ ] Modal doesn't extend into dock
- [ ] Modal doesn't extend into menu bar
- [ ] Modal respects minimum size (usable)
- [ ] Modal respects maximum size (not too large)
- [ ] Resizing parent window updates modal size
- [ ] Content scrolls if needed within modal

---

## Alternative: Sheet Presentation

For simpler cases, use SwiftUI's built-in sheet sizing:

```swift
.sheet(isPresented: $showModal) {
    ModalContent()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
```

**Note:** This works better on iOS; macOS sheets have different behavior.

---

## Real-World Implementations

- `ExpenseTrackerAddView.swift` - Add expense modal
- `ExpenseTrackerEditView.swift` - Edit expense modal
- `GuestDetailViewV4.swift` - Guest detail modal
- `VendorDetailViewV3.swift` - Vendor detail modal

---

## Related Patterns

- [[WindowSize Enum and Responsive Breakpoints Pattern]] - Window size detection
- [[Unified Header with Responsive Actions Pattern]] - Modal header design

---

## Summary

| Aspect | Value |
|--------|-------|
| Width proportion | 60% of parent |
| Height proportion | 75% of parent |
| Chrome buffer | 40px |
| Min width | 400px (standard) |
| Max width | 700px (standard) |
| Min height | 350px (standard) |
| Max height | 850px (standard) |

---

## Changelog

| Date | Change |
|------|--------|
| January 2026 | Created during Expense Tracker optimization |
| January 2026 | Added size bounds by modal type |
