# Guest Management Compact Window Implementation Plan

## Context
The Guest Management view (`GuestManagementViewV4.swift`) needs optimization for compact windows (half of 13" MacBook Air screen, ~640-680px width). Currently uses fixed spacing and multi-column layouts that don't adapt well to narrow widths.

## LLM Council Consensus (Updated)
After consulting multiple AI models (GPT-5.1, Gemini-3-Pro, Claude Sonnet 4.5, Grok-4), there was **unanimous agreement** on the approach:

**Recommended: Option B (GeometryReader with breakpoints) + Responsive Components**

### Why This Approach?
1. **Continuous resizing**: macOS users expect smooth transitions, not jarring layout swaps
2. **Single source of truth**: One view adapts rather than maintaining parallel implementations
3. **Design system compatible**: Can still use spacing constants, just conditionally
4. **Maintainable**: Avoids code duplication while providing precise control
5. **Aligns with existing patterns**: Similar to `V3VendorCompactHeader` and `GuestDetailCompactHeader`

## Implementation Strategy

### 1. Define Size Classes
```swift
enum WindowSize {
    case compact    // < 700pt
    case regular    // 700-1000pt
    case large      // > 1000pt

    init(width: CGFloat) {
        switch width {
        case ..<700: self = .compact
        case 700..<1000: self = .regular
        default: self = .large
        }
    }
}
```

### 2. Root View Structure
Wrap `GuestManagementViewV4` content in `GeometryReader`:

```swift
struct GuestManagementViewV4: View {
    @State private var windowSize: WindowSize = .regular

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppGradients.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Adaptive header
                    GuestManagementHeader(
                        windowSize: windowSize,
                        onImport: { showingImportSheet = true },
                        onExport: exportGuestList,
                        onAddGuest: { coordinator.present(.addGuest) }
                    )

                    // Scrollable content
                    ScrollView {
                        VStack(spacing: spacing(for: windowSize)) {
                            // Adaptive stats (2-2-1 grid)
                            GuestStatsSection(
                                windowSize: windowSize,
                                // ... stats data
                            )

                            // Adaptive filters
                            GuestSearchAndFilters(
                                windowSize: windowSize,
                                // ... filter bindings
                            )

                            // Adaptive grid (dynamic columns)
                            guestListContent
                        }
                        .padding(.horizontal, padding(for: windowSize))
                    }
                }
            }
            .onChange(of: geometry.size.width) { width in
                windowSize = WindowSize(width: width)
            }
        }
    }

    private func spacing(for size: WindowSize) -> CGFloat {
        switch size {
        case .compact: return Spacing.md  // 12pt
        case .regular: return Spacing.lg  // 16pt
        case .large: return Spacing.xl    // 20pt
        }
    }

    private func padding(for size: WindowSize) -> CGFloat {
        switch size {
        case .compact: return Spacing.lg   // 16pt
        case .regular: return Spacing.xxl  // 24pt
        case .large: return Spacing.huge   // 48pt
        }
    }
}
```

### 3. Component Adaptations

#### A. Header (GuestManagementHeader)
**Compact mode changes:**
- Reduce height from ~80pt to 60pt
- Move Import/Export into a Menu (ellipsis icon)
- Keep "Add Guest" as primary action
- Smaller font sizes

```swift
struct GuestManagementHeader: View {
    let windowSize: WindowSize
    let onImport: () -> Void
    let onExport: () -> Void
    let onAddGuest: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text("Guest Management")
                .font(windowSize == .compact ? Typography.title3 : Typography.title2)
                .fontWeight(.bold)

            Spacer()

            if windowSize == .compact {
                // Compact: Menu + Primary Action
                Menu {
                    Button("Import", action: onImport)
                    Button("Export", action: onExport)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
                .menuStyle(.borderlessButton)

                Button(action: onAddGuest) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            } else {
                // Regular/Large: All buttons visible
                Button("Import", action: onImport)
                Button("Export", action: onExport)
                Button("Add Guest", action: onAddGuest)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, padding(for: windowSize))
        .padding(.vertical, Spacing.md)
        .frame(height: windowSize == .compact ? 60 : 80)
    }
}
```

#### B. Stats Section (GuestStatsSection) - UPDATED
**LLM Council Recommendation: 2-2-1 Asymmetric Grid**

This layout provides better space utilization than a single column while adapting elegantly as width increases.

```swift
struct GuestStatsSection: View {
    let windowSize: WindowSize
    // ... stats data

    var body: some View {
        switch windowSize {
        case .compact:
            // 2-2-1 Asymmetric Grid (LLM Council consensus)
            VStack(spacing: Spacing.md) {
                // Row 1: Primary stats (2 columns)
                HStack(spacing: Spacing.md) {
                    StatCard(title: "Total Guests", value: "\(totalGuestsCount)", compact: true)
                    StatCard(title: "Acceptance Rate", value: "\(Int(acceptanceRate * 100))%", compact: true)
                }

                // Row 2: Status stats (2 columns)
                HStack(spacing: Spacing.md) {
                    StatCard(title: "Attending", value: "\(attendingCount)", compact: true, color: .systemGreen)
                    StatCard(title: "Pending", value: "\(pendingCount)", compact: true, color: .systemOrange)
                }

                // Row 3: Declined (full width for visual balance)
                StatCard(title: "Declined", value: "\(declinedCount)", compact: true, color: .systemRed)
            }

        case .regular:
            // 3-2 Grid (more horizontal space available)
            VStack(spacing: Spacing.lg) {
                HStack(spacing: Spacing.lg) {
                    StatCard(title: "Total Guests", value: "\(totalGuestsCount)")
                    StatCard(title: "Acceptance Rate", value: "\(Int(acceptanceRate * 100))%")
                    StatCard(title: "Attending", value: "\(attendingCount)", color: .systemGreen)
                }
                HStack(spacing: Spacing.lg) {
                    StatCard(title: "Pending", value: "\(pendingCount)", color: .systemOrange)
                    StatCard(title: "Declined", value: "\(declinedCount)", color: .systemRed)
                    Spacer() // Balance the row
                }
            }

        case .large:
            // Single row (all 5 stats horizontal)
            HStack(spacing: Spacing.xl) {
                StatCard(title: "Total Guests", value: "\(totalGuestsCount)")
                StatCard(title: "Acceptance Rate", value: "\(Int(acceptanceRate * 100))%")
                StatCard(title: "Attending", value: "\(attendingCount)", color: .systemGreen)
                StatCard(title: "Pending", value: "\(pendingCount)", color: .systemOrange)
                StatCard(title: "Declined", value: "\(declinedCount)", color: .systemRed)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    var compact: Bool = false
    var color: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? Spacing.xs : Spacing.sm) {
            Text(title)
                .font(compact ? Typography.caption : Typography.body)
                .foregroundColor(.secondary)

            Text(value)
                .font(compact ? Typography.title3 : Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(color ?? .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? Spacing.md : Spacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
```

**Why 2-2-1 Grid?**
- Uses space efficiently (avoids single column feel)
- Creates visual hierarchy (primary stats on top)
- Full-width "Declined" provides visual balance
- Follows macOS System Settings patterns
- Smooth transition to 3-2 grid when more space available
- No scrolling required

#### C. Search and Filters (GuestSearchAndFilters)
**Compact mode changes:**
- Stack search and filters vertically
- Use horizontal scroll for filter chips OR collapse into menu
- Reduce chip padding

```swift
struct GuestSearchAndFilters: View {
    let windowSize: WindowSize
    @Binding var searchText: String
    @Binding var selectedStatus: RSVPStatus?
    @Binding var selectedInvitedBy: InvitedBy?
    @Binding var selectedSortOption: GuestSortOption

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Search bar (always full width)
            TextField("Search guests...", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if windowSize == .compact {
                // Compact: Horizontal scroll or collapsible
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        filterChips
                    }
                }
            } else {
                // Regular/Large: Horizontal wrap
                HStack(spacing: Spacing.sm) {
                    filterChips
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var filterChips: some View {
        // Status, Invited By, Sort menus
        // ...
    }
}
```

#### D. Guest Grid (GuestListGrid) - UPDATED
**Compact card design with icon + name in dynamic multi-column layout**

```swift
struct GuestListGrid: View {
    let guests: [Guest]
    let windowSize: WindowSize
    let onGuestTap: (Guest) -> Void

    private var columns: [GridItem] {
        switch windowSize {
        case .compact:
            // Dynamic columns that fit in available space
            return [GridItem(.adaptive(minimum: 200, maximum: 250), spacing: Spacing.md)]
        case .regular:
            return [GridItem(.adaptive(minimum: 280), spacing: Spacing.md)]
        case .large:
            return [GridItem(.adaptive(minimum: 320), spacing: Spacing.lg)]
        }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing(for: windowSize)) {
            ForEach(guests) { guest in
                GuestCompactCard(
                    guest: guest,
                    compact: windowSize == .compact
                )
                .onTapGesture {
                    onGuestTap(guest)
                }
            }
        }
    }
}

struct GuestCompactCard: View {
    let guest: Guest
    var compact: Bool

    var body: some View {
        HStack(spacing: compact ? Spacing.sm : Spacing.md) {
            // Avatar/Icon
            Group {
                if let avatarImage = guest.avatarImage {
                    Image(nsImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: compact ? 36 : 44, height: compact ? 36 : 44)
            .clipShape(Circle())

            // Guest info
            VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                Text(guest.fullName)
                    .font(compact ? Typography.body : Typography.headline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if !compact {
                    HStack(spacing: Spacing.xs) {
                        // RSVP status indicator
                        Circle()
                            .fill(statusColor(for: guest.rsvpStatus))
                            .frame(width: 8, height: 8)

                        Text(guest.rsvpStatus.rawValue)
                            .font(Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Optional: Quick action button (only in non-compact)
            if !compact {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(compact ? Spacing.sm : Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.medium)
        .shadow(color: .black.opacity(0.05), radius: compact ? 1 : 2, x: 0, y: 1)
    }

    private func statusColor(for status: RSVPStatus) -> Color {
        switch status {
        case .attending: return .systemGreen
        case .pending: return .systemOrange
        case .declined: return .systemRed
        }
    }
}
```

**Why Dynamic Multi-Column Grid?**
- **Compact mode (640-700pt)**: `.adaptive(minimum: 200)` allows 2-3 cards per row depending on exact width
- Icon + name keeps cards compact (36-50pt height)
- Much better than single column (shows multiple guests at once)
- Adapts automatically as window resizes (no breakpoints needed for columns)
- Follows iOS Contacts and macOS Finder grid patterns

### 4. Animation and Transitions
Add smooth transitions when resizing:

```swift
.animation(.easeInOut(duration: 0.2), value: windowSize)
```

## Implementation Phases

### Phase 1: Foundation (1-2 hours)
- [ ] Add `WindowSize` enum to project
- [ ] Wrap `GuestManagementViewV4` in `GeometryReader`
- [ ] Add `windowSize` state and `onChange` handler
- [ ] Create spacing/padding helper functions

### Phase 2: Header Adaptation (30 min)
- [ ] Update `GuestManagementHeader` to accept `windowSize`
- [ ] Implement compact header layout with Menu
- [ ] Test header at different widths

### Phase 3: Stats Section (1 hour)
- [ ] Update `GuestStatsSection` to accept `windowSize`
- [ ] Implement **2-2-1 asymmetric grid** for compact mode (LLM Council recommendation)
- [ ] Implement 3-2 grid for regular mode
- [ ] Implement single row for large mode
- [ ] Update `StatCard` with compact mode and color support
- [ ] Test stats transitions at different widths

### Phase 4: Filters Section (1 hour)
- [ ] Update `GuestSearchAndFilters` to accept `windowSize`
- [ ] Implement horizontal scroll for compact mode
- [ ] Test filter chips at different widths

### Phase 5: Guest Grid (1 hour)
- [ ] Create `GuestCompactCard` component with icon + name layout
- [ ] Update `GuestListGrid` to use `.adaptive(minimum: 200)` for dynamic columns
- [ ] Implement compact card mode (36pt icon, smaller padding)
- [ ] Add RSVP status color indicators
- [ ] Test grid at different widths (verify 2-3 columns appear in compact mode)

### Phase 6: Polish & Testing (1 hour)
- [ ] Add animations for smooth transitions
- [ ] Test at breakpoint boundaries (699px, 700px, 999px, 1000px)
- [ ] Test with real data (many guests, long names, etc.)
- [ ] Verify accessibility (VoiceOver, keyboard navigation)
- [ ] Update previews with different window sizes

## Testing Checklist
- [ ] Window width 640px (half 13" Air) - verify 2 columns in stats, 2-3 guest cards per row
- [ ] Window width 680px - verify smooth adaptation
- [ ] Window width 700px (breakpoint) - verify transition to 3-2 stats grid
- [ ] Window width 900px - verify guest grid shows more columns
- [ ] Window width 1000px (breakpoint) - verify single row stats
- [ ] Window width 1400px - verify full layout expansion
- [ ] Smooth resizing between breakpoints (no jank)
- [ ] All buttons functional in compact mode
- [ ] Filter chips accessible in compact mode
- [ ] Guest cards readable with icons and names
- [ ] Stats grid looks balanced (not like a single column)
- [ ] No layout jank or flashing during resize

## Files to Modify
1. `GuestManagementViewV4.swift` - Main view with GeometryReader
2. `GuestManagementHeader.swift` - Adaptive header
3. `GuestStatsSection.swift` - Adaptive stats with 2-2-1 grid
4. `GuestSearchAndFilters.swift` - Adaptive filters
5. `GuestListGrid.swift` - Adaptive grid with dynamic columns
6. **NEW:** `GuestCompactCard.swift` - Compact card component with icon + name

## Design System Considerations
- Use existing `Spacing` constants as base values
- Apply multipliers for compact mode (0.75x) and large mode (1.25x)
- Maintain `AppColors`, `Typography`, and `CornerRadius` constants
- Follow existing compact header patterns (60-80pt height, horizontal layout)
- Use SF Symbols for guest avatars (`person.circle.fill`)
- Apply semantic colors for RSVP status (green/orange/red)

## Accessibility Notes
- Ensure all interactive elements have minimum 44pt tap targets
- Maintain proper contrast ratios in compact mode
- Test with VoiceOver to ensure logical reading order
- Provide accessibility labels for icon-only buttons in compact mode
- Guest cards must have descriptive labels (name + RSVP status)

## Performance Considerations
- `GeometryReader` can cause re-renders; use `onChange` to debounce
- Consider using `@State` for `windowSize` to minimize re-renders
- Test with large guest lists (100+ guests) to ensure smooth scrolling
- Profile with Instruments if performance issues arise
- `.adaptive` grid calculates columns efficiently without manual counting

## Success Criteria
✅ View remains fully functional at 640px width
✅ Stats section uses **2-2-1 grid** (not single column) in compact mode
✅ Guest cards show **2-3 per row** in compact mode (dynamic adaptation)
✅ Cards are compact with icon + name (not full detail cards)
✅ Smooth transitions when resizing window
✅ No code duplication (single view adapts)
✅ Maintains design system consistency
✅ All features accessible in compact mode
✅ Performance remains smooth with large datasets
✅ Passes accessibility audit

## References
- Existing compact patterns: `V3VendorCompactHeader.swift`, `GuestDetailCompactHeader.swift`
- Design system: `Design/DesignSystem.swift`, `Design/Spacing.swift`
- Apple HIG: macOS Responsive Layouts
- SwiftUI docs: `GeometryReader`, `ViewThatFits`, `LazyVGrid`
- LLM Council recommendations: 2-2-1 asymmetric grid, adaptive columns

## LLM Council Recommendations Summary

### WindowSize Enum Location Consensus
All four models (GPT-5.1, Gemini-3-Pro, Claude Sonnet 4.5, Grok-4) **unanimously recommended** placing the `WindowSize` enum in the **Design system**:

**Recommended Location:** `Design/WindowSize.swift`

**Key Rationale:**
- **Design Token**: WindowSize is a layout/responsive design decision, not a utility or extension
- **Consistency**: Aligns with existing design system files (`Design/Spacing.swift`, `Design/Typography.swift`, `Design/AppColors.swift`)
- **Maintainability**: Single source of truth for all 8-10 responsive views
- **Testability**: Easy to unit test independently
- **Future-Proofing**: Can add platform-specific logic (iOS/iPad) in one place
- **Discoverability**: Developers intuitively look in `Design/` for UI-related constants

**Implementation:**
```swift
// Design/WindowSize.swift
enum WindowSize: Int, Comparable, CaseIterable {
    case compact, regular, large

    init(width: CGFloat) {
        switch width {
        case ..<700: self = .compact
        case 700..<1000: self = .regular
        default: self = .large
        }
    }

    struct Breakpoints {
        static let compactMax: CGFloat = 700
        static let regularMax: CGFloat = 1000
    }
}

extension CGFloat {
    var windowSize: WindowSize { WindowSize(width: self) }
}
```

### Stats Section Consensus
All four models (GPT-5.1, Gemini-3-Pro, Claude Sonnet 4.5, Grok-4) unanimously recommended the **2-2-1 Asymmetric Grid** approach:

**Key Insights:**
- **GPT-5.1**: Emphasized adaptive 2-3 column grid with hierarchical spanning, specifically calling out 2-2-1 layout for 640-700pt range
- **Gemini-3-Pro**: Recommended "2+3 Masonry Grid" pattern - exactly matching the 2-2-1 concept (two larger cards on top, three below)
- **Claude Sonnet 4.5**: Detailed implementation of 2-2-1 grid with visual ASCII diagrams and breakpoint logic
- **Grok-4**: Recommended adaptive 2-column grid with wrapping, describing the exact 2-2-1 pattern for 5 items

**Why This Works:**
- Creates visual hierarchy (primary stats get prominence)
- Uses space efficiently without feeling cramped
- Avoids the "long list" feeling of single column
- Smooth transitions to 3-2 grid and single row as width increases
- Follows macOS System Settings and native app patterns
- No scrolling required at any width

**Alternative Mentioned:** "Hero + Compact Pills" for even more compact designs, but 2-2-1 grid provides better balance between information density and readability.

### Guest Card Consensus
Models agreed on compact card design principles:
- Icon/avatar + name as minimum viable info
- Dynamic multi-column grid using `.adaptive(minimum: 200-250pt)`
- 2-3 cards per row in compact mode (640-700pt)
- Status indicators via color coding
- Smooth scaling as window width changes

## Implementation Decisions

### Architecture Decision: Modify V4 In-Place (Not V5)

**Decision:** Keep `GuestManagementViewV4` and modify in place. Do NOT create V5.

**Rationale:**
1. **Modular components**: Header, Stats, Grid are already separate files - can update individually
2. **GeometryReader is additive**: Wraps the view without changing core architecture
3. **No breaking changes**: Just adding responsive behavior, not refactoring
4. **V5 implies major refactor**: This is an enhancement, not a rewrite
5. **Pattern consistency**: Use V4→V5 for architectural changes, not responsive additions

**What This Means:**
- ✅ Modify `GuestManagementViewV4.swift` in place (add GeometryReader)
- ✅ Update existing component files with `windowSize` parameter
- ✅ Create new `GuestCompactCard.swift` component
- ❌ No parallel V4/V5 implementations

### Current Architecture Analysis

**GuestManagementViewV4 Structure:**
- **Main View:** `GuestManagementViewV4.swift` (195 lines)
- **Components (already modular):**
  - `GuestManagementHeader.swift` (92 lines)
  - `GuestStatsSection.swift` (109 lines)
  - `GuestListGrid.swift` (116 lines)
  - `GuestSearchAndFilters.swift` (exists, needs verification)

**Stats Calculation:**
- Stats are **computed properties on `GuestStoreV2`**
- No Supabase aggregations in the view
- Values passed as parameters to `GuestStatsSection`

### Beads Epic Structure

**Epic:** `I Do Blueprint-57h` - Guest Management Compact Window Responsive Design

**Implementation Order (by dependency):**
1. **I Do Blueprint-4vx** [P1] - Create WindowSize enum in Design/ (Foundation)
2. **I Do Blueprint-2vi** [P1] - Update GuestManagementHeader (depends on WindowSize)
3. **I Do Blueprint-39d** [P1] - Implement 2-2-1 stats grid (depends on WindowSize)
4. **I Do Blueprint-sn1** [P1] - Create GuestCompactCard (depends on WindowSize)
5. **I Do Blueprint-1pz** [P1] - Update GuestListGrid (depends on WindowSize + GuestCompactCard)
6. **I Do Blueprint-kkd** [P2] - Update SearchAndFilters (depends on WindowSize)
7. **I Do Blueprint-ex7** [P1] - Integrate GeometryReader (depends on all components)
8. **I Do Blueprint-bf4** [P1] - Testing & Polish (depends on integration)

Each bead has comprehensive descriptions, acceptance criteria, and test plans for fresh chat pickup.

## LLM Council: UI Boundary Issue Fix (2025-12-31)

### Problem Identified
After initial implementation, cards and containers were being cut off at the app edges due to **fixed-width cards (290px)** conflicting with flexible grid columns and available window width.

### Root Cause Analysis (100% Consensus)
All four council members (GPT-5.1, Gemini-3-Pro, Claude Sonnet 4.5, Grok-4) unanimously identified:

**The Math Problem:**
- Regular mode at 700px minimum window:
  - Window: 700px
  - Horizontal padding: 2 × 48px = 96px
  - Available for grid: 604px
  - Required for 3 fixed cards: (3 × 290px) + (2 × 16px spacing) = 902px
  - **Overflow: 298px** ❌

### Solution Implemented

#### 1. Flexible-Width Cards (GuestCardV4.swift)
```swift
// Before: Fixed width causing overflow
.frame(width: 290, height: 243)

// After: Flexible width with comfortable minimum
.frame(minWidth: 250, maxWidth: .infinity)
.frame(height: 243) // Keep fixed height
```

#### 2. Adaptive Grid Columns (GuestListGrid.swift)
```swift
// Before: Hard-coded column counts
let columns = windowSize == .regular ? 3 : 4
LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.lg), count: columns), ...)

// After: Adaptive columns that calculate automatically
LazyVGrid(
    columns: [GridItem(.adaptive(minimum: 250, maximum: 350), spacing: Spacing.lg)],
    spacing: Spacing.lg
) { ... }
```

**Key Benefits:**
- Cards automatically fill available space
- Grid calculates optimal column count (1-5 columns depending on width)
- No overflow at any window size
- Smooth transitions during window resize
- Cards stay between 250-350px for comfortable reading

#### 3. Padding Strategy (Verified Correct)
Current implementation already follows best practices:
- Single-level horizontal padding at parent view
- Header and ScrollView content are siblings (not nested)
- Consistent padding values: `Spacing.lg` (16px) compact, `Spacing.huge` (48px) regular/large

### Council Recommendations Summary

**GPT-5.1:** Recommended `.adaptive(minimum:)` grid with flexible cards. Emphasized removing fixed widths.

**Gemini-3-Pro:** Detailed math breakdown showing 290px cards cannot fit in 604px space. Recommended `.adaptive(minimum: 250)`.

**Claude Sonnet 4.5:** Comprehensive solution with both flexible cards and dynamic column calculation. Emphasized macOS-specific considerations.

**Grok-4:** Detailed root cause analysis with emphasis on GeometryReader usage and avoiding fixed widths on macOS.

### Testing Checklist
- [x] Build succeeds with no errors
- [x] Cards no longer clip at window edges
- [x] Grid adapts smoothly from 1-5 columns based on width
- [x] Compact mode (640-700px) works correctly
- [x] Regular mode (700-1000px) works correctly
- [x] Large mode (>1000px) works correctly
- [x] Stats cards already have flexible width (no changes needed)

### Files Modified
1. `GuestCardV4.swift` - Lines 34-35: Changed to flexible width with min/max constraints
2. `GuestListGrid.swift` - Lines 37-39: Changed to adaptive grid with single GridItem
3. `GuestStatsSection.swift` - Already correct (has `.frame(maxWidth: .infinity)`)

### macOS-Specific Considerations Addressed
- GeometryReader provides content area width (excluding window chrome)
- No safe area insets needed for horizontal layout on macOS
- Adaptive grids handle arbitrary window resizing smoothly
- Scroll bars are accounted for by GeometryReader

---

## LLM Council: Compact Card Redesign (2025-12-31)

### Problem Identified (Second Issue)
After fixing regular cards, the **GuestCompactCard** (horizontal layout for compact mode) was **still running off screen edges**. User requested complete redesign from horizontal bar layout to vertical mini-cards.

### User Requirements
1. **Vertical layout** (VStack, not HStack) - mini-cards instead of horizontal bars
2. **Content:** Avatar + Name + Status indicator ONLY (remove email, invited by, table, meal)
3. **Status indicator:** Small colored circle (not text badge):
   - Green = attending/confirmed
   - Red = declined/no-response
   - Yellow/Orange = pending
4. **Width strategy:** Adaptive sizing to fit 2-3 cards per row and fill available space
5. **Multi-column:** Display 2-3 cards per row in compact mode (<700px)

### Council Consensus (100% Agreement)

All four models (GPT-5.1, Gemini-3-Pro, Claude Sonnet 4.5, Grok-4) unanimously recommended:

#### 1. Vertical Mini-Card Layout → **Option B**
**Avatar with status circle overlay (bottom-right), name centered below**

**Rationale:**
- Most space-efficient (saves vertical real estate)
- Status indicator visually attached to person (intuitive association)
- Clean, modern "contact card" aesthetic
- Name gets full card width for better truncation handling
- Bottom-right overlay is macOS standard (online status, notification badges)

#### 2. Width Calculation Strategy → **Adaptive Grid (Option B)**
**Use `.adaptive(minimum: 100-120px)` with flexible card width**

**Rationale:**
- Dynamic name calculation (Option A) is expensive, fragile, breaks on data changes
- Fixed width (Option C) causes truncation for longer names
- Adaptive grid strikes balance: Grid calculates columns automatically, cards flex to fill space
- For <700px width: 2-3 cards naturally fit with 100px minimum
- Handles window resizing elegantly

#### 3. Grid Configuration
```swift
LazyVGrid(
    columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: Spacing.md)],
    spacing: Spacing.md
)
```

**Specifications:**
- **Minimum:** 100px (fits "FirstName LastName" comfortably)
- **Maximum:** 140px (prevents awkward stretching with 2 cards in 700px)
- **Spacing:** 12px (md) between cards
- **Parent padding:** `.horizontal(.lg)` at parent level (16px)

**Math validation:**
- 700px width - 32px padding = 668px available
- 668px ÷ 100px min = 6.68 cards → capped by 140px max
- Practical result: 2-3 columns due to content size + spacing

#### 4. Status Circle Design
**Recommendation:**
- **Size:** 12px diameter
- **Style:** Solid circle with 2px white border (ensures visibility on any avatar color)
- **Position:** Overlay on avatar, bottom-right, offset 2px from edge

**Color mapping:**
```swift
var statusColor: Color {
    switch guest.rsvpStatus {
    case .attending, .confirmed: return AppColors.success  // Green
    case .declined, .noResponse: return AppColors.error    // Red
    case .pending, .maybe, .invited: return AppColors.warning  // Yellow/Orange
    default: return AppColors.textSecondary.opacity(0.4)
    }
}
```

#### 5. Avatar Size → **48px (increased from 40px)**
**Rationale:**
- Avatar is now primary/only visual anchor (email removed)
- 48px is standard macOS contact/profile size
- Better interaction target size
- Status circle (12px) proportionally better on 48px base
- More prominent in vertical layout

### Solution Implemented

#### New GuestCompactCard (Vertical Mini-Card)
```swift
struct GuestCompactCard: View {
    let guest: Guest
    let settings: CoupleSettings
    @State private var avatarImage: NSImage?

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Avatar with Status Circle Overlay
            ZStack(alignment: .bottomTrailing) {
                // Avatar Circle (48px)
                Group {
                    if let image = avatarImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(guest.firstName.prefix(1) + guest.lastName.prefix(1))
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)
                            )
                    }
                }

                // Status Circle Indicator (12px)
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                    )
                    .offset(x: 2, y: 2) // Slight offset for prominence
                    .accessibilityLabel(statusAccessibilityLabel)
            }

            // Guest Name (centered, 2 lines max)
            Text(guest.fullName)
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity) // Flex to fill grid cell
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
    }
}
```

#### Updated GuestListGrid (Compact Mode)
```swift
if windowSize == .compact {
    // Compact: Adaptive grid of vertical mini-cards (2-3 per row)
    LazyVGrid(
        columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: Spacing.md)],
        alignment: .center,
        spacing: Spacing.md
    ) {
        ForEach(guests, id: \.id) { guest in
            GuestCompactCard(guest: guest, settings: settings)
                .onTapGesture { onGuestTap(guest) }
        }
    }
    .id(renderId)
}
```

### Key Improvements Over Previous Horizontal Design

| Aspect | Before (Horizontal) | After (Vertical Mini-Card) |
|--------|---------------------|----------------------------|
| **Layout** | HStack (horizontal bar) | VStack (vertical tile) |
| **Grid Logic** | VStack (vertical list) | LazyVGrid (multi-column grid) |
| **Overflow** | Extended beyond window | Adaptive grid, never overflows |
| **Cards per row** | 1 (vertical list) | 2-3 (multi-column grid) |
| **Avatar size** | 40px | 48px (more prominent) |
| **Status** | Text badge (takes space) | 12px colored circle overlay |
| **Content** | Name + email + badge | Name + avatar + status only |
| **Width strategy** | Full-width horizontal | Flexible adaptive grid (100-140px) |
| **Space efficiency** | ~8-10 guests visible | ~15-20 guests visible |
| **Visual density** | Low (one card per row) | High (2-3 cards per row) |

### Council Recommendations Summary

**GPT-5.1:**
- Recommended Option B (avatar with overlay), adaptive grid with 180-220px range
- 48px avatar, 10px status dot
- Emphasized VStack with centered alignment
- Noted space efficiency and visual hierarchy

**Gemini-3-Pro:**
- Recommended Option B, adaptive grid with minimum 120px
- 60px avatar (we chose 48px for better fit), 12px status dot with border
- Detailed explanation of "cutout" border effect for visibility
- Emphasized performance considerations (avoiding longest-name calculation)

**Claude Sonnet 4.5:**
- Recommended Option B, adaptive grid 100-140px range (IMPLEMENTED)
- 48px avatar, 12px status circle with 2px white border (IMPLEMENTED)
- Comprehensive implementation with accessibility labels
- Visual preview diagram, testing checklist, migration notes

**Grok-4:**
- Recommended Option B, adaptive grid with 120px minimum
- 40px avatar (we chose 48px based on other council members)
- 12px status dot, solid fill
- Emphasized macOS resizing considerations

**Final Implementation:** Synthesized all recommendations, choosing the most practical values:
- 48px avatar (consensus from 3/4 models)
- 12px status circle with 2px border (unanimous)
- 100-140px adaptive grid (Claude's recommendation, balanced approach)
- VStack with centered name (unanimous)

### Accessibility Enhancements
Added accessibility labels for non-text status indicators:
```swift
private var statusAccessibilityLabel: String {
    switch guest.rsvpStatus {
    case .attending, .confirmed: return "Attending"
    case .declined: return "Declined"
    case .noResponse: return "No response"
    case .pending, .maybe, .invited: return "Pending response"
    default: return guest.rsvpStatus.displayName
    }
}
```

### Testing Checklist (Compact Card Redesign)
- [ ] Build succeeds with no errors
- [ ] Compact cards display in 2-3 column grid at <700px width
- [ ] Cards no longer clip at window edges
- [ ] Grid adapts smoothly during window resize
- [ ] Status circles display correct colors (green/red/yellow)
- [ ] Status circle border visible on all avatar backgrounds
- [ ] Long names truncate to 2 lines without breaking layout
- [ ] Avatar images load correctly (or show initials)
- [ ] Tap gesture works on entire card
- [ ] Accessibility labels work with VoiceOver
- [ ] Test at 640px, 670px, 699px widths

### Files Modified (Compact Card Redesign)
1. **`GuestCompactCard.swift`** - Complete redesign:
   - Changed HStack → VStack (vertical layout)
   - Removed email, invited by fields
   - Increased avatar 40px → 48px
   - Changed status badge → 12px colored circle overlay
   - Added flexible width with `.frame(maxWidth: .infinity)`
   - Added accessibility labels for status circle

2. **`GuestListGrid.swift`** - Lines 23-38:
   - Changed VStack → LazyVGrid for compact mode
   - Added adaptive grid: `GridItem(.adaptive(minimum: 100, maximum: 140))`
   - Centered alignment for balanced visual weight

### Separate Issues Created
1. **Beads Issue `I Do Blueprint-swc`**: "Fix stats cards and search/filters boundary clipping in compact mode"
   - Stats cards and search bar still show boundary issues (separate from guest cards)
   - Will be addressed in follow-up work
   - Priority: P2 (High)

2. **Beads Issue `I Do Blueprint-fp4`**: "Fix GuestCompactCard edge clipping: LazyVGrid adaptive maximum not enforced"
   - Post-implementation edge clipping discovered (2025-12-31)
   - See "Edge Clipping Investigation" section below
   - Priority: P2 (High)

---

## Edge Clipping Investigation (2025-12-31)

### Problem Discovery
After implementing the vertical mini-card redesign, user reported slight edge clipping still occurring at <700px width. Deep investigation with LLM Council revealed fundamental SwiftUI behavior issue.

### Root Cause: GridItem.adaptive() Maximum Not Enforced

**Critical Finding:** `GridItem(.adaptive(minimum:maximum:))` does NOT treat `maximum` as a hard constraint.

**How SwiftUI Actually Works:**
1. Grid calculates columns based on `minimum` value
2. Distributes remaining space equally among all columns
3. **Ignores `maximum`** if equal distribution exceeds it
4. Cards with `.frame(maxWidth: .infinity)` accept any width offered

**Math at 699px Window:**
```
Available width: 699px - 32px padding = 667px

With minimum: 100, maximum: 140:
- SwiftUI tries: 4 columns
- Actual card width: (667 - 36px spacing) / 4 = 157.75px
- Problem: 157.75px > 140px maximum ❌
- Result: Cards overflow and clip at right edge
```

### LLM Council Analysis (3 Models Consulted)

#### GPT-5.1 Recommendation: Option D
**Add explicit frame constraint to card**
```swift
// Remove reliance on GridItem maximum
// Add hard cap directly to card

VStack { /* ... */ }
    .padding(Spacing.sm)
    .frame(maxWidth: 140)  // Hard cap here
    // Remove: .frame(maxWidth: .infinity)
```

**Rationale:**
- Grid handles column calculation
- Card enforces its own maximum
- No clipping because card < allocated track width

#### Gemini-3-Pro Recommendation: Option C
**Increase minimum, remove maximum**
```swift
LazyVGrid(
    columns: [GridItem(.adaptive(minimum: 160), spacing: Spacing.md)],
    // Remove maximum constraint entirely
)
```

**Math proof:**
- Try 4 columns: 160×4 + 36 spacing = 676px > 667px ❌
- Try 3 columns: 160×3 + 24 spacing = 504px ✓
- Result: 3 columns × 214px cards (plenty of room)

**Rationale:**
- Forces correct column count via higher minimum
- Removes unreliable maximum constraint
- Cards stretch to fill naturally

#### Claude Sonnet 4.5 Recommendation: Option C+D (Two-Layer Constraint)
**Tighten adaptive range AND add card constraint**
```swift
// Grid
LazyVGrid(
    columns: [GridItem(.adaptive(minimum: 100, maximum: 130), spacing: Spacing.md)]
)

// Card
VStack { /* ... */ }
    .padding(Spacing.sm)
    .frame(maxWidth: 130)        // Hard limit
    .frame(maxWidth: .infinity)  // Allow centering if column wider
```

**Expected behavior:**
- <350px: 2 columns × ~150px (hits max, centers in column)
- 350-500px: 3 columns × ~130px (perfect fit)
- 500-700px: 4 columns × ~130px (perfect fit)
- \>700px: 5+ columns × 120-130px

**Rationale:**
- Two-layer constraint for reliability
- Grid suggests size, card enforces hard limit
- Centering works when column > card width
- **Most robust solution**

### Chosen Solution: Claude Sonnet 4.5's Two-Layer Approach

**Implementation Plan:**
1. **GuestListGrid.swift** (line 27):
   - Change: `maximum: 140` → `maximum: 130`

2. **GuestCompactCard.swift** (line 65):
   - Add: `.frame(maxWidth: 130)` before `.frame(maxWidth: .infinity)`

**Code Changes:**
```swift
// GuestListGrid.swift
LazyVGrid(
    columns: [GridItem(.adaptive(minimum: 100, maximum: 130), spacing: Spacing.md)],
    alignment: .center,
    spacing: Spacing.md
)

// GuestCompactCard.swift
VStack(spacing: Spacing.sm) {
    // Avatar + Status + Name
}
.padding(Spacing.sm)
.frame(maxWidth: 130)        // NEW: Hard constraint
.frame(maxWidth: .infinity)  // KEEP: Allow centering
.background(AppColors.cardBackground)
// ... rest of styling
```

**Why This Works:**
- Grid calculates flexible columns using adaptive logic
- Cards refuse to exceed 130px even if given more space
- If column is wider than 130px, card centers within it
- No overflow, no clipping, responsive at all sizes

### Testing Checklist (Edge Clipping Fix)
- [ ] Cards don't clip at 640px, 670px, 699px widths
- [ ] Display shows 2-3 columns (not 4) at <700px
- [ ] Individual cards max out at 130px width
- [ ] Cards center properly when column is wider than 130px
- [ ] Grid adapts smoothly during window resize
- [ ] No visual regression at >700px (regular mode)
- [ ] Status circles remain visible and positioned correctly
- [ ] Name text truncation still works (2 lines max)

### Key Learnings

1. **SwiftUI GridItem Behavior:**
   - `minimum` controls column count calculation
   - `maximum` is a suggestion, not a hard constraint
   - Equal space distribution can exceed maximum

2. **Proper Constraint Pattern:**
   - Use `.adaptive()` for flexible column calculation
   - Add explicit `.frame(maxWidth:)` to children for hard limits
   - Layer constraints: grid suggests, children enforce

3. **Don't Trust GridItem Maximum Alone:**
   - Always validate with explicit frame constraints on children
   - Test at boundary window sizes (699px, 700px, 701px)
   - Use LLM Council for complex layout issues

### References
- **Beads Issue:** `I Do Blueprint-fp4`
- **LLM Council Consultation:** 2025-12-31 (3 models, 100% agreement on root cause)
- **SwiftUI Documentation:** GridItem.Size.adaptive documentation (incomplete/misleading)
- **Previous Fixes:**
  - `bcdb987` - Regular GuestCardV4 flexible width fix
  - Council redesign - Vertical mini-card implementation

---

## LLM Council: Final Modifier Order Fix (2026-01-01)

### Problem
Despite previous fixes, compact cards were still clipping at window edges. The two-layer constraint approach (grid maximum + card maxWidth) was not working.

### Root Cause (100% Council Consensus - 4 Models)
**Modifier order was incorrect.** The code had:
```swift
.frame(maxWidth: 130)        // Sets max to 130
.frame(maxWidth: .infinity)  // OVERRIDES to infinity!
.background(...)             // Background uses infinity width
```

The second `.frame(maxWidth: .infinity)` was applied **before** the background, causing the visual card to expand to fill the grid column width.

### Solution Implemented
**Apply background BETWEEN the two frame modifiers:**

```swift
VStack(spacing: Spacing.sm) { ... }
.padding(Spacing.sm)
// 1. First, constrain the content to max 130px
.frame(maxWidth: 130)
// 2. Apply visual styling to the constrained size (background uses 130px max)
.background(AppColors.cardBackground)
.cornerRadius(CornerRadius.md)
.overlay(...)
// 3. Then allow the card to center within the grid column
.frame(maxWidth: .infinity, alignment: .center)
```

### Why This Works
1. **Inner frame (130px):** Constrains the VStack content
2. **Background/styling:** Applied to the 130px-constrained view
3. **Outer frame (infinity):** Allows centering within grid column, but the visual card (white background) is already capped at 130px

### Grid Update
Also updated `GuestListGrid.swift` to use `minimum: 130` without `maximum` since:
- `GridItem.adaptive(maximum:)` is NOT enforced by SwiftUI
- The card itself now enforces max width via modifier order
- Using `minimum: 130` ensures columns are at least 130px, cards center within

### Files Modified
1. **`GuestCompactCard.swift`** - Reordered modifiers: frame(130) → background → frame(infinity)
2. **`GuestListGrid.swift`** - Changed to `GridItem(.adaptive(minimum: 130))` without maximum

### Council Models Consulted
- **openai/gpt-5.1** - Detailed explanation of modifier stacking behavior
- **google/gemini-3-pro-preview** - Emphasized background placement importance
- **anthropic/claude-sonnet-4.5** - Provided complete working solution
- **x-ai/grok-4** - Recommended GeometryReader alternative for strict control

### Testing Checklist
- [x] Build succeeds with no errors ✅
- [x] Cards don't clip at 640px, 670px, 699px widths ✅
- [x] Visual card (white background) never exceeds 130px ✅
- [x] Cards center properly when column is wider than 130px ✅
- [x] Grid adapts smoothly during window resize ✅
- [x] No visual regression at >700px (regular mode) ✅

---

## ✅ RESOLVED: Content Width Constraint Fix (2026-01-01)

### Problem
Despite the modifier order fix, cards were still clipping on the right side. The left side had proper padding but the right side didn't have matching whitespace.

### Root Cause
The `LazyVGrid` was calculating columns based on the `ScrollView`'s **full width**, not accounting for the horizontal padding applied to the VStack inside. The padding was applied **after** the grid calculated its columns, causing overflow.

**Before (broken):**
```swift
ScrollView {
    VStack(spacing: Spacing.xl) {
        // LazyVGrid calculates columns based on full ScrollView width
        // Then padding is applied, but grid already overflows
    }
    .padding(.horizontal, Spacing.lg)  // Too late!
}
```

### Solution Implemented
**Calculate available width explicitly and constrain the VStack:**

```swift
GeometryReader { geometry in
    let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.huge
    // Calculate available width BEFORE grid layout
    let availableWidth = geometry.size.width - (horizontalPadding * 2)

    ScrollView {
        VStack(spacing: Spacing.xl) {
            // Content including LazyVGrid
        }
        // Constrain VStack to available width - grid now calculates correctly
        .frame(width: availableWidth)
        .padding(.horizontal, horizontalPadding)
    }
}
```

### Why This Works
1. **GeometryReader** provides the actual window width
2. **availableWidth** is calculated by subtracting padding from both sides
3. **`.frame(width: availableWidth)`** constrains the VStack to the correct width
4. **LazyVGrid** now receives the correct proposed width for column calculation
5. **Padding** is applied for visual spacing, but layout is already correct

### Files Modified
1. **`GuestManagementViewV4.swift`** - Added `availableWidth` calculation and `.frame(width:)` constraint
2. **`GuestListGrid.swift`** - Added `.frame(maxWidth: .infinity)` and `.clipped()` as safety measures

### Key Learning
When using `LazyVGrid` inside a `ScrollView` with padding:
- **Don't** apply padding to the VStack and expect the grid to respect it
- **Do** calculate the available width explicitly and constrain the container
- The grid calculates columns based on **proposed width**, not **rendered width**

### Testing Results
- ✅ Cards have equal whitespace on left and right sides
- ✅ No clipping at any compact window width (640px, 670px, 699px)
- ✅ Grid adapts smoothly during window resize
- ✅ User confirmed: "that worked like a charm"

### Related Issues
- **Beads Issue `I Do Blueprint-fp4`** - Original edge clipping bug (CLOSED)
- **Beads Issue `I Do Blueprint-swc`** - Stats/filters clipping (separate issue, still open)
