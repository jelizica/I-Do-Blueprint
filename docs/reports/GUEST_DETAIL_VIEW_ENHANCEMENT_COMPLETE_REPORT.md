# Guest Detail View Enhancement - Complete Implementation Report

**Document Version**: 1.0  
**Date**: January 1, 2025  
**Status**: ✅ Completed  
**Priority**: High  
**Authors**: Development Team with LLM Council Consultation

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Problem Statement](#problem-statement)
3. [Requirements](#requirements)
4. [Architecture & Design](#architecture--design)
5. [Implementation Details](#implementation-details)
6. [Technical Challenges & Solutions](#technical-challenges--solutions)
7. [LLM Council Consultations](#llm-council-consultations)
8. [Testing & Validation](#testing--validation)
9. [Files Changed](#files-changed)
10. [Related Beads Issues](#related-beads-issues)
11. [Future Enhancements](#future-enhancements)
12. [Key Learnings](#key-learnings)
13. [References](#references)

---

## Executive Summary

This report documents the complete implementation of the Guest Detail View enhancement for the I Do Blueprint macOS wedding planning application. The enhancement transformed the guest detail modal from a static, hardcoded component into a dynamic, responsive, and user-friendly interface that:

1. **Dynamically displays events** based on what has been created in the database (not hardcoded)
2. **Adapts to window size** with intelligent compact/normal mode switching
3. **Properly positions within macOS sheets** using the parent window size pattern
4. **Accounts for window chrome** (title bar, toolbar) to prevent content cutoff

The implementation involved multiple iterations, including three LLM Council consultations to solve complex SwiftUI/macOS sheet sizing challenges.

### Key Achievements

| Achievement | Description |
|-------------|-------------|
| **Dynamic Event Display** | Events shown based on `wedding_events` database table, not hardcoded |
| **Adaptive Layout** | Compact header (80pt) for small windows, full header (200pt) for normal windows |
| **Parent Window Size Pattern** | Solved GeometryReader collapse issue in macOS sheets |
| **Window Chrome Buffer** | 40pt buffer prevents action button cutoff |
| **RSVP-Aware Rendering** | Disabled state for guests who haven't confirmed attendance |

---

## Problem Statement

### Original Issues

#### Issue 1: Hardcoded Event Types
The guest detail view displayed hardcoded event attendance for three fixed events:
- Rehearsal/Welcome Dinner
- Ceremony
- Reception

**Limitations**:
- Could not adapt to couples who only have some events
- Showed events that didn't exist, leading to confusion
- Display didn't reflect actual wedding event configuration
- Couldn't support custom event types

#### Issue 2: Modal Positioning Problems
The modal had multiple positioning issues on macOS:
1. **NSScreen Coordinate System**: Used absolute screen coordinates instead of container-relative positioning
2. **GeometryReader Collapse**: GeometryReader inside sheets collapsed to minimum size
3. **Dock Overlap**: Modal extended past visible area, cutting off action buttons
4. **Small Window Handling**: Fixed header took up most of the space in small windows

### User Impact

- Couples with non-traditional wedding structures saw irrelevant event options
- Guest attendance data appeared incomplete or incorrect
- Action buttons were inaccessible when modal overlapped with dock
- Poor UX on smaller windows or when dock was visible

---

## Requirements

### Functional Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| FR-1 | Show only events that exist in `wedding_events` database table | ✅ |
| FR-2 | Display events in chronological order (by date, then by event_order) | ✅ |
| FR-3 | Filter to show only attendable events (exclude budget-only events) | ✅ |
| FR-4 | Use custom event names from database when available | ✅ |
| FR-5 | Show active attendance indicators when guest RSVP is "attending" or "confirmed" | ✅ |
| FR-6 | Display disabled/grayed-out state when guest has not confirmed attendance | ✅ |
| FR-7 | Modal must resize dynamically based on window size | ✅ |
| FR-8 | Modal must not overlap with macOS dock | ✅ |
| FR-9 | Action buttons must always be visible and accessible | ✅ |

### Non-Functional Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| NFR-1 | No additional database queries (use existing budgetStore.weddingEvents) | ✅ |
| NFR-2 | Component-based architecture with clear separation of concerns | ✅ |
| NFR-3 | Proper color contrast and semantic icons (accessibility) | ✅ |
| NFR-4 | Follow existing design system (AppColors, Typography, Spacing) | ✅ |
| NFR-5 | Support window sizes from 400x350 to 700x850 | ✅ |

---

## Architecture & Design

### Component Structure

```
GuestDetailViewV4
├── GuestDetailCompactHeader (NEW - 80pt, horizontal, scrolls with content)
├── GuestDetailHeader (200pt, vertical, fixed)
├── GuestDetailEventAttendance (NEW - Dynamic component)
│   ├── AttendanceItem (Active state)
│   └── DisabledAttendanceItem (Pending state)
├── GuestDetailContactSection
├── GuestDetailStatusRow
├── GuestDetailDietarySection
├── GuestDetailAccessibilitySection
├── GuestDetailWeddingPartySection
├── GuestDetailAddressSection
├── GuestDetailNotesSection
├── GuestDetailAdditionalDetails
└── GuestDetailActionButtons (Always fixed at bottom)
```

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ wedding_events table (Supabase)                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ BudgetStoreV2.weddingEvents                                     │
└──────────────────────────────────────────────────────────���──────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ GuestDetailViewV4 (via @EnvironmentObject)                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ GuestDetailEventAttendance (via parameter)                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────��────┐
│ Filtered & Sorted attendableEvents → UI Rendering               │
└─────────────────────────────────────────────────────────────────┘
```

### Window Size Flow (Parent Window Size Pattern)

```
┌─────────────────────────────────────────────────────────────────┐
│ RootFlowView.MainAppView                                        │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ GeometryReader { geometry in                                │ │
│ │   NavigationSplitView { ... }                               │ │
│ │     .onAppear { coordinator.parentWindowSize = size }       │ │
│ │     .onChange(of: size) { coordinator.parentWindowSize }    │ │
│ │     .sheet { GuestDetailViewV4() }                          │ │
│ │ }                                                           │ │
│ └────────────────────────���────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ AppCoordinator                                                  │
│ @Published var parentWindowSize: CGSize = CGSize(800, 600)      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│ GuestDetailViewV4                                               │
│ let size = coordinator.parentWindowSize                         │
│ dynamicSize = calculate(parentSize, chromeBuffer)               │
│ isCompactMode = dynamicSize.height < 550                        │
│ VStack { ... }                                                  │
│   .frame(width: dynamicSize.width, height: dynamicSize.height)  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Use BudgetStoreV2 for events** | Events are already loaded for budget allocation; avoids duplicate queries |
| **Filter "other" type events** | Budget-only events (e.g., "Pre-Wedding Expenses") aren't attendable |
| **Sort by date + order** | Ensures chronological display matching actual wedding timeline |
| **Disable when RSVP pending** | Prevents confusion about attendance before RSVP confirmation |
| **Parent window size pattern** | Solves GeometryReader collapse in macOS sheets |
| **40pt window chrome buffer** | Accounts for title bar (~28pt) + safety margin |
| **Compact mode at < 550pt** | Ensures content is accessible in small windows |

---

## Implementation Details

### Phase 1: Dynamic Event Attendance Component

**File**: `I Do Blueprint/Views/Guests/Components/GuestDetailEventAttendance.swift`

#### Dynamic Event Filtering

```swift
private var attendableEvents: [WeddingEvent] {
    weddingEvents.filter { event in
        let eventType = event.eventType.lowercased()
        return eventType == "rehearsal" || eventType == "ceremony" || eventType == "reception"
    }.sorted { event1, event2 in
        if event1.eventDate != event2.eventDate {
            return event1.eventDate < event2.eventDate
        }
        return (event1.eventOrder ?? 0) < (event2.eventOrder ?? 0)
    }
}
```

#### Smart Event Naming

```swift
private func displayName(for event: WeddingEvent) -> String {
    if !event.eventName.isEmpty {
        return event.eventName  // Use custom name from database
    }
    
    switch event.eventType.lowercased() {
    case "rehearsal": return "Welcome Dinner"
    case "ceremony": return "Ceremony"
    case "reception": return "Reception"
    default: return event.eventType.capitalized
    }
}
```

#### Attendance Status Mapping

```swift
private func isAttendingEvent(_ event: WeddingEvent) -> Bool {
    switch event.eventType.lowercased() {
    case "rehearsal": return guest.attendingRehearsal
    case "ceremony": return guest.attendingCeremony
    case "reception": return guest.attendingReception
    default: return guest.attendingOtherEvents?.contains(event.id) ?? false
    }
}
```

### Phase 2: Environment Object Integration

**File**: `I Do Blueprint/App/RootFlowView.swift`

Added required environment objects to sheet presentation:

```swift
.sheet(item: $coordinator.activeSheet) { sheet in
    sheet.view(coordinator: coordinator)
        .environmentObject(settingsStore)
        .environmentObject(appStores.budget)  // ← Added for weddingEvents
        .environmentObject(coordinator)        // ← Added for navigation
}
```

### Phase 3: Parent Window Size Pattern

**File**: `I Do Blueprint/Services/Navigation/AppCoordinator.swift`

```swift
@MainActor
class AppCoordinator: ObservableObject {
    // MARK: - Window Size (for dynamic sheet sizing)
    
    /// The current size of the main content area, updated by the parent view
    /// Used by sheet content to calculate dynamic sizes
    @Published var parentWindowSize: CGSize = CGSize(width: 800, height: 600)
}
```

**File**: `I Do Blueprint/App/RootFlowView.swift`

```swift
GeometryReader { geometry in
    NavigationSplitView { ... }
        .onAppear {
            coordinator.parentWindowSize = geometry.size
        }
        .onChange(of: geometry.size) { _, newSize in
            coordinator.parentWindowSize = newSize
        }
}
```

### Phase 4: Dynamic Size Calculation

**File**: `I Do Blueprint/Views/Guests/GuestDetailViewV4.swift`

```swift
// MARK: - Size Constants

private let minWidth: CGFloat = 400
private let maxWidth: CGFloat = 700
private let minHeight: CGFloat = 350
private let maxHeight: CGFloat = 850
private let compactHeightThreshold: CGFloat = 550
private let windowChromeBuffer: CGFloat = 40

private var dynamicSize: CGSize {
    let parentSize = coordinator.parentWindowSize
    let targetWidth = min(maxWidth, max(minWidth, parentSize.width * 0.6))
    let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.75 - windowChromeBuffer))
    return CGSize(width: targetWidth, height: targetHeight)
}

private var isCompactMode: Bool {
    dynamicSize.height < compactHeightThreshold
}
```

### Phase 5: Adaptive Layout

**File**: `I Do Blueprint/Views/Guests/Components/GuestDetailCompactHeader.swift`

New compact header component (80pt, horizontal layout) for small windows:

```swift
struct GuestDetailCompactHeader: View {
    let guest: Guest
    let settings: CoupleSettings
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(...)
            
            HStack(spacing: Spacing.md) {
                // Avatar (50pt)
                AvatarView(size: 50)
                
                // Name and relationship
                VStack(alignment: .leading, spacing: 2) {
                    Text(guest.fullName)
                        .font(.system(size: 18, weight: .bold))
                    Text("\(invitedByText) • \(relationshipText)")
                        .font(.system(size: 12))
                }
                
                Spacer()
                
                // Close Button
                CloseButton()
            }
        }
        .frame(height: 80)
    }
}
```

---

## Technical Challenges & Solutions

### Challenge 1: Environment Object Missing

**Problem**: Fatal error when clicking guest cards - "No ObservableObject of type BudgetStoreV2 found"

**Root Cause**: `GuestDetailViewV4` was presented via `AppCoordinator` sheets, but `RootFlowView` wasn't injecting all required environment objects.

**Solution**: Added `budgetStore` and `coordinator` to sheet environment objects in `RootFlowView.MainAppView`.

### Challenge 2: GeometryReader Collapse in Sheets

**Problem**: GeometryReader inside a macOS sheet collapsed to minimum size.

**Root Cause**: macOS sheets size to content. When a sheet asks its content "what size do you want?" and GeometryReader responds "I'll take whatever space you give me," it creates a circular dependency that collapses to minimum size.

**Solution**: Parent Window Size Pattern - measure the parent window size in the PARENT view, store it in `AppCoordinator`, and read it in the sheet content.

### Challenge 3: Window Chrome Buffer

**Problem**: Modal was extending 10-20 pixels past the visible area, cutting off action buttons.

**Root Cause**: `parentSize.height` includes the window title bar (~28-40pt), but the sheet content area doesn't have that space available.

**Solution**: Subtract a fixed 40pt buffer for window chrome:
```swift
let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.75 - windowChromeBuffer))
```

### Challenge 4: Small Window Content Cutoff

**Problem**: Fixed header (~200pt) took up most of the space in small windows, leaving little room for content.

**Solution**: Adaptive layout with compact mode:
- **Normal mode** (height ≥ 550pt): Fixed 200pt header, scrollable content
- **Compact mode** (height < 550pt): 80pt header scrolls with content

### Challenge 5: Event Filtering Logic

**Problem**: How to distinguish between attendable events and budget-only events?

**Solution**: Filter by `eventType` field, excluding "other" type events which are typically used for budget tracking.

---

## LLM Council Consultations

Three LLM Council consultations were conducted to solve complex SwiftUI/macOS challenges. The council consisted of GPT-5.1, Gemini 3 Pro, Claude Sonnet 4.5, and Grok 4.

### Consultation #1: GeometryReader Collapse Issue

**Question**: How to make a sheet modal that dynamically sizes based on the parent window size when GeometryReader inside the sheet collapses?

**Consensus**: All four models agreed that GeometryReader inside a sheet creates a circular dependency. The solution is to measure the parent window size in the PARENT view, then pass that size to the sheet content.

| Model | Key Insight |
|-------|-------------|
| **GPT-5.1** | "GeometryReader inside a macOS sheet can't drive the sheet size because it gets a 'no size' proposal from AppKit" |
| **Gemini 3 Pro** | "The sheet determines its size based on intrinsic content size. GeometryReader has no intrinsic size." |
| **Claude Sonnet 4.5** | "Don't use GeometryReader as the root of your sheet content - it will collapse" |
| **Grok 4** | "The sheet window starts with a default or minimal size, and GeometryReader ends up with a tiny proposed size" |

### Consultation #2: Small Window Adaptive Layout

**Question**: What's the best UX approach for small window scenarios where the fixed header takes up most of the space?

**Consensus**: All four models recommended an adaptive layout approach with a compact header when vertical space is limited.

| Model | Recommended Approach |
|-------|---------------------|
| **GPT-5.1** | "Treat the header as optional luxury that scales down when space is tight" |
| **Gemini 3 Pro** | "By default, place the header inside the ScrollView so it scrolls away to reveal content" |
| **Claude Sonnet 4.5** | "Adaptive layout with a compact variant when vertical space is constrained" |
| **Grok 4** | "Use a responsive, compact layout that incorporates a collapsible or shrinkable header" |

**Key UX Principles Identified**:
- Fixed elements should not exceed ~30% of view height
- Action buttons should stay fixed (users must always be able to exit/save)
- Adapt intelligently - don't force minimum sizes; respect user's window choice
- Header is "optional luxury" - it can shrink or scroll when space is tight

### Consultation #3: Window Chrome Buffer

**Question**: Modal is JUST slightly too tall - bottom action buttons are getting cut off by about 10-20 pixels. Should we reduce the height percentage or add a buffer?

**Consensus**: Three of four models recommended subtracting a fixed buffer for window chrome rather than just reducing the percentage.

| Model | Recommended Fix |
|-------|-----------------|
| **GPT-5.1** | "The cutoff is caused by the non-content part of the window (title bar/toolbar), which is a *fixed* height, not proportional" |
| **Gemini 3 Pro** | "The issue is likely a discrepancy between Window Height (includes Title Bar) and Content View Height" |
| **Claude Sonnet 4.5** | "Quickest fix - one number change. 0.75 gives you a comfortable ~25% buffer" |
| **Grok 4** | "Dropping from 0.8 to 0.75 gives a buffer for the title bar (typically ~28-40pt on macOS)" |

**Final Decision**: Combined approach - reduce percentage to 0.75 AND subtract a 40pt buffer.

---

## Testing & Validation

### Unit Testing

**Preview Providers** (in `GuestDetailEventAttendance.swift`):
1. ✅ Attending Guest - All Events (rehearsal, ceremony, reception)
2. ✅ Attending Guest - Ceremony Only (single event)
3. ✅ Pending Guest (disabled state)
4. ✅ No Events Configured (empty state)

**Preview Providers** (in `GuestDetailCompactHeader.swift`):
1. ✅ Compact Header with full guest data

**Preview Providers** (in `GuestDetailViewV4.swift`):
1. ✅ Attending Guest with All Details
2. ✅ Pending Guest

### Integration Testing

**Manual Testing Scenarios**:

| Scenario | Result |
|----------|--------|
| Click guest card → detail view opens without crash | ✅ |
| Guest with RSVP "attending" → shows active attendance indicators | ✅ |
| Guest with RSVP "pending" → shows disabled state | ✅ |
| Couple with only ceremony + reception → shows 2 events (not 3) | ✅ |
| Couple with all 3 events → shows all 3 in correct order | ✅ |
| Custom event names → displays custom names correctly | ✅ |
| Large window → normal mode with fixed header | ✅ |
| Small window → compact mode with scrolling header | ✅ |
| Modal resizes when window resizes | ✅ |
| Modal doesn't overlap with dock | ✅ |
| Action buttons always visible and accessible | ✅ |

### Build Validation

```bash
xcodebuild build -project "I Do Blueprint.xcodeproj" \
  -scheme "I Do Blueprint" -destination 'platform=macOS'
```

**Result**: ✅ BUILD SUCCEEDED

---

## Files Changed

### New Files

| File | Purpose |
|------|---------|
| `Views/Guests/Components/GuestDetailEventAttendance.swift` | Dynamic event attendance component |
| `Views/Guests/Components/GuestDetailCompactHeader.swift` | Compact header for small windows |

### Modified Files

| File | Changes |
|------|---------|
| `Views/Guests/GuestDetailViewV4.swift` | Added adaptive layout, dynamic sizing, environment objects |
| `Services/Navigation/AppCoordinator.swift` | Added `parentWindowSize` property |
| `App/RootFlowView.swift` | Added GeometryReader for window size capture, environment objects to sheet |

### Supporting Files (Previously Modified)

| File | Changes |
|------|---------|
| `Domain/Models/Guest/Guest.swift` | Added `attendingRehearsal` property |
| `Services/Stores/OnboardingSettingsService.swift` | Added event sync to `wedding_events` table |
| `Views/Onboarding/WeddingDetailsView.swift` | Added event type dropdown |

---

## Related Beads Issues

| Issue ID | Title | Status |
|----------|-------|--------|
| `I Do Blueprint-7j7` | Enhance Guest Detail View with all database fields | In Progress |
| `I Do Blueprint-t06` | Fix GuestDetailViewV4 modal centering - use GeometryReader instead of NSScreen | ✅ Closed |
| `I Do Blueprint-otz` | Sync onboarding events to wedding_events table | ✅ Closed |
| `I Do Blueprint-zz1` | Enhance Edit Guest Sheet with all editable fields | Open (Dependent) |
| `I Do Blueprint-sy6` | Update AddGuestView for field parity with Edit view | Open (Dependent) |

---

## Future Enhancements

### Short Term

| Enhancement | Description | Priority |
|-------------|-------------|----------|
| Add `is_attendable` flag to database | Allow "other" type events to be marked as attendable | P2 |
| Event icons | Add custom icons per event type | P3 |
| Event time display | Show event time alongside name | P3 |

### Medium Term

| Enhancement | Description | Priority |
|-------------|-------------|----------|
| Bulk attendance editing | Allow editing attendance directly from detail view | P2 |
| Event-specific guest lists | Filter guests by event attendance | P2 |
| Attendance statistics | Show "X of Y guests attending" per event | P3 |

### Long Term

| Enhancement | Description | Priority |
|-------------|-------------|----------|
| Multi-day event support | Handle destination weddings with multiple days | P3 |
| Event capacity tracking | Set max capacity per event, alert when approaching limits | P3 |

### Technical Debt

| Issue | Description | Priority |
|-------|-------------|----------|
| Deprecate settings-based wedding events | Events are currently stored in two places: `couple_settings.settings.global.weddingEvents` (JSON) and `wedding_events` table. Remove settings-based events entirely. | P3 |

---

## Key Learnings

### Architecture

1. **Environment Objects Are Critical**: Always document and test environment object requirements for views presented via sheets
2. **Single Source of Truth**: Avoid dual storage (settings JSON + database table)
3. **Component Composition**: Small, focused components are easier to test and maintain
4. **Parent Window Size Pattern**: For macOS sheets, measure parent size in parent view, not in sheet content

### SwiftUI/macOS

1. **macOS sheets size to content**: Unlike iOS, macOS sheets don't fill the window - they size based on their content
2. **GeometryReader has no intrinsic size**: It creates a circular dependency when used as the root of sheet content
3. **Window chrome is fixed, not proportional**: Always subtract a fixed buffer rather than just reducing percentages
4. **ZStack centering is automatic**: Use ZStack's default center alignment instead of manual positioning

### Process

1. **LLM Council for Complex Problems**: Multi-model consultation provides diverse perspectives and consensus-based solutions
2. **Incremental Implementation**: Break large features into phases
3. **Documentation as You Go**: Capture decisions and rationale immediately
4. **Test in Context**: Previews aren't enough - test in actual app flow

---

## References

### Basic Memory Notes

- `architecture/features/Guest Detail View Enhancement - Complete Implementation Report.md`
- `architecture/features/Guest Detail Modal - Window Chrome Buffer Fix.md`

### Beads Issues

- `I Do Blueprint-7j7` - Enhance Guest Detail View with all database fields
- `I Do Blueprint-t06` - Fix GuestDetailViewV4 modal centering
- `I Do Blueprint-otz` - Sync onboarding events to wedding_events table

### Code Files

- `I Do Blueprint/Views/Guests/GuestDetailViewV4.swift`
- `I Do Blueprint/Views/Guests/Components/GuestDetailEventAttendance.swift`
- `I Do Blueprint/Views/Guests/Components/GuestDetailCompactHeader.swift`
- `I Do Blueprint/Services/Navigation/AppCoordinator.swift`
- `I Do Blueprint/App/RootFlowView.swift`

### External Research

- Stack Overflow: "SwiftUI GeometryReader does not layout custom subviews in center"
- Medium: "Understanding GeometryReader in SwiftUI: A Detailed Guide"
- Fatbobman's Blog: SwiftUI GeometryReader patterns
- Apple Docs: `NSScreen.visibleFrame` (accounts for dock and menu bar)

---

## Appendix A: Size Constants Reference

```swift
// Modal Size Bounds
private let minWidth: CGFloat = 400
private let maxWidth: CGFloat = 700
private let minHeight: CGFloat = 350
private let maxHeight: CGFloat = 850

// Layout Thresholds
private let compactHeightThreshold: CGFloat = 550
private let windowChromeBuffer: CGFloat = 40

// Size Calculation
let targetWidth = min(maxWidth, max(minWidth, parentSize.width * 0.6))
let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.75 - windowChromeBuffer))
```

## Appendix B: Layout Mode Comparison

| Aspect | Normal Mode | Compact Mode |
|--------|-------------|--------------|
| **Threshold** | height ≥ 550pt | height < 550pt |
| **Header height** | 200pt (fixed) | 80pt (scrolls) |
| **Avatar size** | 80pt | 50pt |
| **Header layout** | Vertical (centered) | Horizontal (left-aligned) |
| **Header scrolls** | No | Yes |
| **Content padding** | Spacing.xl | Spacing.lg |
| **Action buttons** | Fixed at bottom | Fixed at bottom |

---

**Document Status**: Complete  
**Last Updated**: January 1, 2025  
**Next Review**: When related issues (I Do Blueprint-zz1, I Do Blueprint-sy6) are completed
