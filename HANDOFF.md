# Dashboard V7 Step 6 Implementation Handoff

**Session ID**: c24204d3-3407-4b8f-a0f4-6b8b3269b3c7  
**Date**: 2026-01-04  
**Status**: In Progress - Ready for Complex Implementation  
**Issue**: I Do Blueprint-oa33 (in_progress)

---

## 🎯 Current Task

**Implement Step 6: Space-Filling Dynamic Layout with GeometryReader**

User explicitly requested the **FULL COMPLEX VERSION** - not a simplified approach.

---

## ✅ Completed Work (Steps 1-5)

### Step 1: Removed Refresh Button ✓
- Deleted `.toolbar` block from NavigationStack
- Pull-to-refresh via ScrollView remains functional

### Step 2: Fixed Budget Overview Data ✓
- Replaced hardcoded "$3.7M" with `formattedTotal` computed property
- Replaced hardcoded "$7,150" with `formattedSpent` computed property
- Added `spentProgress` and `remainingProgress` calculations
- Progress bars now use real data from `totalBudget` and `totalSpent`

### Step 3: Updated Payments Due Card ✓
- Changed from "next 30 days" to "current month" using `Calendar.isDate(_:equalTo:toGranularity:.month)`
- Increased display limit from 3 to 5 payments
- Added paid/unpaid indicators: `checkmark.circle.fill` (green) vs `circle` (gray)
- Added strikethrough for paid items
- Added 0.6 opacity dimming for paid items
- Overdue unpaid payments show in pink

### Step 4: Guest Avatars with MultiAvatarJSService ✓
- Integrated existing `MultiAvatarJSService` for colorful guest avatars
- Avatars load asynchronously via `guest.fetchAvatar(size: CGSize(width: 80, height: 80))`
- Added `@State private var avatarImage: NSImage?` for avatar state
- Fallback shows initials in status-colored circle
- Maintained white border and shadow for visual consistency

### Step 5: Conditional Card Rendering ✓
- Added computed properties: `shouldShowGuestResponses`, `shouldShowPaymentsDue`, `shouldShowRecentResponses`, `shouldShowVendorList`
- Added helper properties: `currentMonthPayments`, `hasRecentResponses`
- Wrapped cards in if statements - Budget Overview and Task Manager always show
- Other cards conditionally render based on data availability

---

## 🚧 Step 6: Space-Filling Dynamic Layout (IN PROGRESS)

### Implementation Requirements

**File**: `I Do Blueprint/Views/Dashboard/DashboardViewV7.swift` (currently 1419 lines)

### Architecture Overview

```
┌───────────────────────────────────────���─┐
│  GeometryReader (Container)             │
│  ┌───────────────────────────────────┐  │
│  │ Fixed Elements                    │  │
│  │ - Header (~60pt)                  │  │
│  │ - Hero Banner (~150pt)            │  │
│  │ - Metric Cards Row (~120pt)       │  │
│  └───────────────────────────────────┘  │
│                                          │
│  ┌───────────────────────────────────┐  │
│  │ DynamicDashboardGrid              │  │
│  │ (availableHeight calculated)      │  │
│  │                                   │  │
│  │ - Conditional card rendering      │  │
│  │ - Dynamic maxItems per card       │  │
│  │ - Space-filling expansion         │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Implementation Steps

#### 1. Add GeometryReader Wrapper
```swift
var body: some View {
    NavigationStack {
        ZStack {
            MeshGradientBackgroundV7()
                .ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Header
                        DashboardHeaderV7()
                            .padding(.horizontal, Spacing.xxl)

                        // Hero Banner
                        Group {
                            if effectiveHasLoaded {
                                HeroBannerV7(...)
                            } else {
                                DashboardHeroSkeleton()
                            }
                        }
                        .padding(.horizontal, Spacing.xxl)

                        // Metric Cards Row
                        LazyVGrid(columns: metricColumns, ...) {
                            // Metric cards
                        }
                        .padding(.horizontal, Spacing.xxl)

                        // MARK: - Main Content Grid with Dynamic Sizing
                        DynamicDashboardGrid(
                            availableHeight: calculateAvailableHeight(geometry: geometry),
                            viewModel: viewModel,
                            budgetStore: budgetStore,
                            guestStore: guestStore,
                            vendorStore: vendorStore,
                            taskStore: taskStore,
                            settingsStore: settingsStore,
                            coordinator: coordinator,
                            effectiveHasLoaded: effectiveHasLoaded
                        )
                        .padding(.horizontal, Spacing.xxl)
                    }
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
            }
        }
        .navigationTitle("")
    }
    .task {
        if !viewModel.hasLoaded {
            await viewModel.loadDashboardData()
        }
    }
    .onReceive(timer) { time in
        currentTime = time
    }
}
```

#### 2. Add Height Calculation Helper
```swift
private func calculateAvailableHeight(geometry: GeometryProxy) -> CGFloat {
    let headerHeight: CGFloat = 60
    let heroBannerHeight: CGFloat = 150
    let metricCardsHeight: CGFloat = 120
    let spacing: CGFloat = Spacing.xl * 4 // Between sections
    let padding: CGFloat = Spacing.xxl * 2 // Top and bottom
    
    let fixedHeight = headerHeight + heroBannerHeight + metricCardsHeight + spacing + padding
    return max(geometry.size.height - fixedHeight, 400) // Minimum 400pt
}
```

#### 3. Create DynamicDashboardGrid Component
```swift
// MARK: - Dynamic Dashboard Grid

struct DynamicDashboardGrid: View {
    let availableHeight: CGFloat
    let viewModel: DashboardViewModel
    let budgetStore: BudgetStoreV2
    let guestStore: GuestStoreV2
    let vendorStore: VendorStoreV2
    let taskStore: TaskStoreV2
    let settingsStore: SettingsStoreV2
    let coordinator: AppCoordinator
    let effectiveHasLoaded: Bool
    
    // MARK: - Layout Calculations
    
    private var visibleCards: [DashboardCard] {
        var cards: [DashboardCard] = [
            .budgetOverview, // Always show
            .taskManager     // Always show
        ]
        
        if !guestStore.guests.isEmpty {
            cards.append(.guestResponses)
        }
        
        if !currentMonthPayments.isEmpty {
            cards.append(.paymentsDue)
        }
        
        if hasRecentResponses {
            cards.append(.recentResponses)
        }
        
        if !vendorStore.vendors.isEmpty {
            cards.append(.vendorList)
        }
        
        return cards
    }
    
    private var heightPerCard: CGFloat {
        let cardCount = max(visibleCards.count, 1)
        return availableHeight / CGFloat(cardCount)
    }
    
    private var maxItemsPerCard: Int {
        let itemRowHeight: CGFloat = 60
        let cardHeaderHeight: CGFloat = 80
        let cardPadding: CGFloat = 40
        
        let availableHeightForItems = heightPerCard - cardHeaderHeight - cardPadding
        return max(Int(availableHeightForItems / itemRowHeight), 3) // Minimum 3 items
    }
    
    // MARK: - Data Helpers
    
    private var currentMonthPayments: [PaymentSchedule] {
        let now = Date()
        let calendar = Calendar.current
        return budgetStore.payments.paymentSchedules.filter { schedule in
            calendar.isDate(schedule.paymentDate, equalTo: now, toGranularity: .month)
        }
    }
    
    private var hasRecentResponses: Bool {
        guestStore.guests.contains { $0.rsvpDate != nil }
    }
    
    // MARK: - Body
    
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 300, maximum: 500), spacing: Spacing.lg, alignment: .top)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, alignment: .top, spacing: Spacing.lg) {
            if effectiveHasLoaded {
                // Budget Overview - Always show
                BudgetOverviewCardV7(
                    totalBudget: viewModel.totalBudget,
                    totalSpent: viewModel.totalPaid
                )
                
                // Task Manager - Always show
                TaskManagerCardV7(
                    store: taskStore,
                    maxItems: maxItemsPerCard
                )
                
                // Guest Responses - Conditional
                if visibleCards.contains(.guestResponses) {
                    GuestResponsesCardV7(
                        store: guestStore,
                        maxItems: maxItemsPerCard
                    )
                    .environmentObject(settingsStore)
                    .environmentObject(budgetStore)
                    .environmentObject(coordinator)
                }
                
                // Payments Due - Conditional
                if visibleCards.contains(.paymentsDue) {
                    PaymentsDueCardV7(
                        maxItems: maxItemsPerCard
                    )
                }
                
                // Recent Responses - Conditional
                if visibleCards.contains(.recentResponses) {
                    RecentResponsesCardV7(
                        store: guestStore,
                        maxItems: maxItemsPerCard
                    )
                }
                
                // Vendor List - Conditional
                if visibleCards.contains(.vendorList) {
                    VendorListCardV7(
                        store: vendorStore,
                        maxItems: maxItemsPerCard
                    )
                }
            } else {
                // Skeletons
                DashboardBudgetCardSkeleton()
                DashboardTasksCardSkeleton()
                DashboardGuestsCardSkeleton()
                DashboardVendorsCardSkeleton()
            }
        }
    }
}

// MARK: - Dashboard Card Enum

enum DashboardCard: Equatable {
    case budgetOverview
    case taskManager
    case guestResponses
    case paymentsDue
    case recentResponses
    case vendorList
}
```

#### 4. Update Card Components to Accept maxItems

**Cards to Update**:
1. `TaskManagerCardV7` - Add `let maxItems: Int` parameter
2. `GuestResponsesCardV7` - Add `let maxItems: Int` parameter
3. `PaymentsDueCardV7` - Add `let maxItems: Int` parameter
4. `RecentResponsesCardV7` - Add `let maxItems: Int` parameter
5. `VendorListCardV7` - Add `let maxItems: Int` parameter

**Example Pattern**:
```swift
struct TaskManagerCardV7: View {
    @ObservedObject var store: TaskStoreV2
    let maxItems: Int  // ✅ New parameter
    
    private var recentTasks: [WeddingTask] {
        store.tasks
            .sorted { /* sorting logic */ }
            .prefix(maxItems)  // ✅ Use dynamic limit
            .map { $0 }
    }
    // ...
}
```

---

## 📊 Current State

### File Status
- **File**: `I Do Blueprint/Views/Dashboard/DashboardViewV7.swift`
- **Current Lines**: 1419
- **Expected Growth**: +200-300 lines (DynamicDashboardGrid component)
- **Build Status**: ✅ Compiles successfully
- **Git Status**: ✅ All changes committed and pushed

### Beads Status
- **Issue**: `I Do Blueprint-oa33`
- **Status**: `in_progress`
- **Priority**: P2
- **Type**: feature

### Empirica Status
- **Session**: `c24204d3-3407-4b8f-a0f4-6b8b3269b3c7`
- **PREFLIGHT**: Complete (know: 0.70, do: 0.65, uncertainty: 0.45)
- **Handoff**: Created with full context

---

## 🔍 Key Unknowns to Resolve

1. **Exact height values** - Need to measure or estimate:
   - Header height (estimated: 60pt)
   - Hero banner height (estimated: 150pt)
   - Metric cards height (estimated: 120pt)

2. **State management** - Should we use `@State` for caching:
   - `visibleCards` array
   - `maxItemsPerCard` calculation

3. **Edge cases** - How to handle:
   - Very small windows (< 700pt height)
   - Very large windows (> 1400pt height)
   - Window resizing during use

4. **Component location** - Should `DynamicDashboardGrid`:
   - Stay in same file (simpler)
   - Extract to separate file (cleaner)

---

## 🎯 Implementation Order

1. **Start with GeometryReader wrapper** - Wrap ScrollView content
2. **Add calculateAvailableHeight()** - Helper function for height calculation
3. **Create DynamicDashboardGrid struct** - With visibleCards and maxItems logic
4. **Add DashboardCard enum** - For card identification
5. **Update TaskManagerCardV7** - Simplest card, test pattern
6. **Update GuestResponsesCardV7** - More complex with avatar loading
7. **Update PaymentsDueCardV7** - Has current month filtering
8. **Update RecentResponsesCardV7** - Has RSVP date filtering
9. **Update VendorListCardV7** - Has vendor type categorization
10. **Build and test** - After each major change
11. **Test window resizing** - Verify dynamic behavior
12. **Commit and push** - Complete implementation

---

## 📚 Reference Documents

- **Implementation Plan**: `knowledge-repo-bm/architecture/implementation-plans/Dashboard V7 Space-Filling Adaptive Layout Implementation Plan.md`
- **Current File**: `I Do Blueprint/Views/Dashboard/DashboardViewV7.swift`
- **Design System**: `I Do Blueprint/Design/DesignSystem.swift`

---

## ⚠️ Critical Notes

1. **User explicitly wants COMPLEX version** - Do not simplify
2. **GeometryReader is required** - Not optional
3. **All 6 cards must accept maxItems** - No shortcuts
4. **Build after each major change** - Catch errors early
5. **Test with different window sizes** - Verify dynamic behavior

---

## 🚀 Next Session Start Commands

```bash
# 1. Check current status
bd show oa33
git status

# 2. Start new Empirica session
empirica session-create --ai-id qodo-gen --output json

# 3. Submit PREFLIGHT
empirica preflight-submit -

# 4. Begin implementation
# Start with GeometryReader wrapper in DashboardViewV7.swift
```

---

**Estimated Complexity**: High (4-6 hours per implementation plan)  
**Current Progress**: 0% of Step 6  
**Ready for**: Full complex implementation with GeometryReader
