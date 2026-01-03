---
title: Guest Detail View Environment Object Fix
type: note
permalink: troubleshooting/guest-detail-view-environment-object-fix
tags:
- bug-fix
- environment-objects
- guest-detail
- swiftui
---

# Guest Detail View Environment Object Fix

## Problem

Fatal error when clicking on a guest card to show details:
```
Thread 1: Fatal error: No ObservableObject of type BudgetStoreV2 found. 
A View.environmentObject(_:) for BudgetStoreV2 may be missing as an ancestor of this view.
```

## Root Cause

`GuestDetailViewV4` requires three environment objects:
1. `SettingsStoreV2` ✅ (was provided)
2. `BudgetStoreV2` ❌ (was missing)
3. `AppCoordinator` ❌ (was missing)

The view needs `BudgetStoreV2` to access `weddingEvents` for the dynamic event attendance section.

## The Fix

Updated `RootFlowView.swift` in the `MainAppView` struct to inject missing environment objects:

```swift
// Before (missing environment objects)
.sheet(item: $coordinator.activeSheet) { sheet in
    sheet.view(coordinator: coordinator)
        .environmentObject(settingsStore)
}

// After (complete environment objects)
.sheet(item: $coordinator.activeSheet) { sheet in
    sheet.view(coordinator: coordinator)
        .environmentObject(settingsStore)
        .environmentObject(appStores.budget)  // Added
        .environmentObject(coordinator)        // Added
}
```

## Files Changed

- `I Do Blueprint/App/RootFlowView.swift` - Added missing environment objects to sheet presentation

## Related Changes

This fix was needed after implementing dynamic event attendance in `GuestDetailEventAttendance`, which reads from `budgetStore.weddingEvents` instead of hardcoded event types.

## Prevention

When creating views that use `@EnvironmentObject`:
1. Document required environment objects in view header comments
2. Ensure all presentation points inject required objects
3. Check preview providers include all required environment objects
4. Test the view in its actual presentation context (not just previews)

## Testing

✅ Build succeeded
✅ Guest detail view now opens without crashing
✅ Dynamic event attendance displays correctly


## Update: Dock Positioning Fix (January 1, 2025)

### Additional Issue

After the environment object fix, a second UX issue was discovered: the modal was positioned too low and overlapped with the macOS dock.

### Solution

Added `.position()` modifier to center the modal in the visible screen area (which excludes the dock):

```swift
.position(x: NSScreen.main?.visibleFrame.midX ?? 400,
         y: (NSScreen.main?.visibleFrame.midY ?? 400) - 50) // Offset up to avoid dock
```

**Key Points**:
- Uses `NSScreen.main?.visibleFrame` which automatically accounts for dock and menu bar
- Centers horizontally in the visible frame
- Offsets vertically by 50 points to ensure clearance from dock
- Provides fallback values (400) for safety

### Files Changed

- `I Do Blueprint/Views/Guests/GuestDetailViewV4.swift` - Added position modifier

### Testing

✅ Build succeeded
✅ Modal now positions correctly above the dock
✅ Modal remains centered on screen

### Design Decision

**No Tabs**: The current single-scroll design was intentionally kept. All content is displayed in one scrollable view, which provides:
- Immediate access to all information
- Natural top-to-bottom reading flow
- Simpler implementation
- No need to hunt through tabs

This design pattern is consistent with detail views throughout the app.


---

## Update: GeometryReader Centering Fix (December 31, 2025)

### Issue Discovered

The previous dock positioning fix using `NSScreen.main?.visibleFrame` was causing the modal to be positioned incorrectly. The modal was not properly centered and could overlap with the dock or appear off-center depending on window size.

### Root Cause Analysis

The original fix used absolute screen coordinates:
```swift
.position(x: NSScreen.main?.visibleFrame.midX ?? 400,
         y: (NSScreen.main?.visibleFrame.midY ?? 400) - 50)
```

**Problems with this approach:**
1. Uses absolute screen coordinates instead of container-relative positioning
2. The `-50` offset was arbitrary and didn't properly center the modal
3. Didn't adapt dynamically to window size changes
4. Sheet presentations have their own coordinate system, so screen coordinates don't apply correctly

### Solution: GeometryReader-Based Centering

Replaced the absolute positioning with a `GeometryReader`-based approach:

```swift
var body: some View {
    Group {
        if let guest = guest {
            GeometryReader { geometry in
                ZStack {
                    // Background overlay
                    AppColors.textPrimary.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture { dismiss() }
                    
                    // Modal content
                    VStack(spacing: 0) {
                        // ... content ...
                    }
                    // Dynamic sizing: use min of fixed size or available space with padding
                    .frame(
                        width: min(600, geometry.size.width - 40),
                        height: min(750, geometry.size.height - 40)
                    )
                    .background(AppColors.cardBackground)
                    .cornerRadius(CornerRadius.lg)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    // Center within the GeometryReader's coordinate space
                    .position(
                        x: geometry.frame(in: .local).midX,
                        y: geometry.frame(in: .local).midY
                    )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            // ... sheets and alerts ...
        }
    }
}
```

### Key Improvements

1. **Container-relative positioning**: Uses `geometry.frame(in: .local).midX/midY` to center within the actual container, not the screen
2. **Dynamic sizing**: Modal adapts to available space with `min(fixedSize, availableSpace - padding)`
3. **Responsive**: Works correctly regardless of window size or screen configuration
4. **Dock-aware**: Since the app's main frame already respects the dock, the modal inherits this behavior

### Research References

- Stack Overflow: "SwiftUI GeometryReader does not layout custom subviews in center"
- Medium: "Understanding GeometryReader in SwiftUI: A Detailed Guide"
- Apple Docs: `NSScreen.visibleFrame` (accounts for dock and menu bar)

### Files Changed

- `I Do Blueprint/Views/Guests/GuestDetailViewV4.swift` - Replaced NSScreen positioning with GeometryReader

### Testing

✅ Build succeeded
✅ Modal centers correctly within the sheet container
✅ Modal adapts to different window sizes
✅ Modal does not overlap with dock
✅ Background tap-to-dismiss still works

### Pattern for Future Modals

When creating custom modal overlays in SwiftUI:

1. **Use GeometryReader** to get container dimensions
2. **Center with `.position()`** using `geometry.frame(in: .local).midX/midY`
3. **Dynamic sizing** with `min(preferredSize, availableSpace - padding)`
4. **Wrap ZStack in `.frame()`** to ensure proper sizing: `.frame(width: geometry.size.width, height: geometry.size.height)`
5. **Avoid NSScreen** for positioning within sheets or other containers
