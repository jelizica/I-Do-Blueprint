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
