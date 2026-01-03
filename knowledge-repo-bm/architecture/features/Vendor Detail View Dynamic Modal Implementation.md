---
title: Vendor Detail View Dynamic Modal Implementation
type: note
permalink: architecture/features/vendor-detail-view-dynamic-modal-implementation
tags:
- vendor-management
- modal
- dynamic-sizing
- adaptive-layout
- macos
- swiftui
---

# Vendor Detail View Dynamic Modal Implementation

> **Status**: ✅ Completed  
> **Date**: January 2, 2025  
> **Pattern**: Parent Window Size Pattern (same as Guest Detail View)

## Summary

Successfully implemented dynamic window/modal sizing for the vendor detail view, matching the pattern established in the guest detail view enhancement. The vendor detail modal now adapts to parent window size and switches between normal and compact modes based on available space.

## Implementation Details

### Files Created

1. **`V3VendorCompactHeader.swift`** (80pt height)
   - Horizontal layout with smaller logo (50pt)
   - Vendor name, type, and status badge
   - Close button
   - Scrolls with content in compact mode

### Files Modified

1. **`VendorDetailViewV3.swift`**
   - Added dynamic sizing constants (400-700pt width, 350-850pt height)
   - Added `@EnvironmentObject private var coordinator: AppCoordinator`
   - Implemented `dynamicSize` computed property (60% width, 75% height minus 40pt chrome buffer)
   - Added `isCompactMode` computed property (threshold: 550pt)
   - Implemented adaptive layout:
     - **Normal mode**: Fixed 280pt hero header, tabs with TabView
     - **Compact mode**: 80pt scrollable header, tabs without TabView wrapper
   - Created separate content views for compact mode with reduced padding

2. **`VendorManagementViewV3.swift`**
   - Added `.environmentObject(AppCoordinator.shared)` to vendor detail sheet presentation

### Existing Components Reused

- **`V3VendorHeroHeader`** (280pt) - Already existed, used for normal mode
- **`V3VendorTabBar`** - Tab selector component
- **`V3VendorOverviewContent`** - Overview tab content
- **`V3VendorFinancialContent`** - Financial tab content
- **`V3VendorDocumentsContent`** - Documents tab content
- **`V3VendorNotesContent`** - Notes tab content

## Key Differences from Guest Detail View

| Aspect | Guest Detail View | Vendor Detail View |
|--------|-------------------|-------------------|
| **Header Height (Normal)** | 200pt | 280pt (hero header with decorative pattern) |
| **Header Height (Compact)** | 80pt | 80pt |
| **Content Organization** | Scrollable sections | Tabs (preserved as requested) |
| **Event Attendance** | Yes (dynamic from database) | No (vendor-specific, not needed) |
| **Logo Upload** | No | Yes (in normal mode header) |
| **Action Buttons** | Fixed at bottom | In header (normal mode) |

## Size Constants

```swift
private let minWidth: CGFloat = 400
private let maxWidth: CGFloat = 700
private let minHeight: CGFloat = 350
private let maxHeight: CGFloat = 850
private let compactHeightThreshold: CGFloat = 550
private let windowChromeBuffer: CGFloat = 40
```

## Dynamic Size Calculation

```swift
private var dynamicSize: CGSize {
    let parentSize = coordinator.parentWindowSize
    let targetWidth = min(maxWidth, max(minWidth, parentSize.width * 0.6))
    let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.75 - windowChromeBuffer))
    return CGSize(width: targetWidth, height: targetHeight)
}
```

## Adaptive Layout Logic

```swift
if isCompactMode {
    // COMPACT MODE: Everything scrolls, 80pt header
    ScrollView {
        V3VendorCompactHeader(...)
        V3VendorTabBar(...)
        tabContent  // Switch statement, no TabView
    }
} else {
    // NORMAL MODE: Fixed 280pt hero header, TabView for tabs
    V3VendorHeroHeader(...)
    V3VendorTabBar(...)
    TabView(selection: $selectedTab) {
        overviewTab.tag(.overview)
        financialTab.tag(.financial)
        documentsTab.tag(.documents)
        notesTab.tag(.notes)
    }
}
```

## Testing Checklist

### Build Validation
- ✅ Build succeeded without errors
- ✅ No SwiftLint violations
- ✅ All components compile correctly

### Manual Testing Required
- [ ] Click vendor card → detail view opens
- [ ] Large window → normal mode with 280pt hero header
- [ ] Small window → compact mode with 80pt header
- [ ] Modal resizes when window resizes
- [ ] Modal doesn't overlap with dock
- [ ] All tabs accessible in both modes
- [ ] Logo upload works in normal mode
- [ ] Edit/delete buttons work
- [ ] Financial data loads correctly
- [ ] Documents load correctly

## Architecture Alignment

This implementation follows the **Parent Window Size Pattern** established in the guest detail view:

1. **Measure in parent**: `RootFlowView` measures window size with GeometryReader
2. **Store in coordinator**: `AppCoordinator.parentWindowSize` published property
3. **Calculate in sheet**: Modal calculates dynamic size based on parent size
4. **Apply explicit frame**: `.frame(width: dynamicSize.width, height: dynamicSize.height)`

## Related Documentation

- **Source of Truth**: `Guest Detail View Enhancement - Source of Truth` (Basic Memory)
- **Complete Report**: `GUEST_DETAIL_VIEW_ENHANCEMENT_COMPLETE_REPORT.md`
- **Pattern**: Parent Window Size Pattern for macOS sheets

## Future Enhancements

### Short Term
- Add edit/delete buttons to compact header
- Optimize tab switching animation in compact mode
- Add keyboard shortcuts for tab navigation

### Medium Term
- Persist selected tab preference per user
- Add quick actions menu in compact mode
- Implement drag-to-resize for modal

## Key Learnings

1. **Reuse existing components**: V3VendorHeroHeader was already perfect for normal mode
2. **Tab preservation**: Kept tabs as requested, but adapted TabView usage for compact mode
3. **Consistent patterns**: Following guest detail view pattern ensures maintainability
4. **Window chrome buffer**: 40pt buffer prevents content cutoff on macOS

## Build Output

```
** BUILD SUCCEEDED **
```

No errors or warnings (except standard SwiftLint run script warning).

---

**Tags**: #vendor-management #modal #dynamic-sizing #adaptive-layout #macos #swiftui #architecture #parent-window-size-pattern

**Relationships**:
- implements: Guest Detail View Enhancement pattern
- relates_to: VendorStoreV2, AppCoordinator
- supersedes: Fixed 650x700 vendor detail modal


## Update: Icon-Only Tab Mode (January 2, 2025)

### Enhancement

Added responsive tab bar that switches to icon-only mode when width is constrained, preventing text wrapping to multiple lines.

### Implementation

**File Modified**: `V3VendorTabBar.swift`

#### Width Threshold
```swift
private let iconOnlyThreshold: CGFloat = 500
```

When modal width < 500pt, tabs display icons only (no text labels).

#### Adaptive Tab Button
```swift
// Icon size increases in icon-only mode for better visibility
Image(systemName: isSelected ? tab.iconFilled : tab.icon)
    .font(.system(size: showIconOnly ? 18 : 14, weight: isSelected ? .semibold : .regular))

// Text only shown when width allows
if !showIconOnly {
    Text(tab.title)
        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
}

// Badge (document count) always shown
if let badge = badge, badge > 0 {
    Text("\(badge)")
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(AppColors.primary)
        .clipShape(Capsule())
}
```

#### GeometryReader Integration
```swift
GeometryReader { geometry in
    HStack {
        Spacer()
        HStack(spacing: Spacing.sm) {
            ForEach(VendorDetailTab.allCases) { tab in
                V3TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    badge: tab == .documents && documentCount > 0 ? documentCount : nil,
                    showIconOnly: geometry.size.width < iconOnlyThreshold
                )
            }
        }
        Spacer()
    }
}
.frame(height: 60) // Fixed height for tab bar
```

### Visual Behavior

| Width | Display Mode | Icon Size | Text | Badge |
|-------|-------------|-----------|------|-------|
| ≥ 500pt | Full | 14pt | ✅ Shown | ✅ Shown |
| < 500pt | Icon-only | 18pt | ❌ Hidden | ✅ Shown |

### Accessibility

- Accessibility labels remain unchanged (full tab names)
- Accessibility hints provide context
- Selected state properly announced
- Hover states work in both modes

### Build Status

```
** BUILD SUCCEEDED **
```

### Benefits

1. **Prevents text wrapping**: No more multi-line tab labels in narrow modals
2. **Maintains usability**: Larger icons compensate for missing text
3. **Preserves badges**: Document count always visible
4. **Smooth transition**: GeometryReader enables responsive switching
5. **Accessibility preserved**: Screen readers get full context

### Testing Checklist

- [ ] Width ≥ 500pt → Full labels shown
- [ ] Width < 500pt → Icons only
- [ ] Document badge visible in both modes
- [ ] Tab selection works in both modes
- [ ] Hover states work in both modes
- [ ] Accessibility labels correct in both modes
- [ ] Smooth transition when resizing window

---

**Updated**: January 2, 2025  
**Enhancement**: Icon-only tab mode for narrow modals
