# Component Library Quick Reference

Quick lookup guide for choosing the right component.

## When to Use Each Component

### Empty States
| Scenario | Component | Example |
|----------|-----------|---------|
| No items in list | `UnifiedEmptyStateView` | `.guests(onAdd: {})` |
| Search no results | `UnifiedEmptyStateView` | `.searchResults(query: text)` |
| Filtered no results | `UnifiedEmptyStateView` | `.filteredResults()` |
| Custom empty state | `UnifiedEmptyStateView` | `.custom(...)` |

### Stats & Metrics
| Scenario | Component | Example |
|----------|-----------|---------|
| Single stat | `StatsCardView` | `StatsCardView(stat: .guestTotal(150))` |
| Multiple stats | `StatsGridView` | `StatsGridView(stats: [...], columns: 3)` |
| Dashboard widget | `CompactSummaryCard` | With icon, value, subtitle |
| Aggregated data | `SummaryCard` | Multiple `SummaryItem`s |

### Forms
| Scenario | Component | Example |
|----------|-----------|---------|
| Text input | `ValidatedTextField` | With validation rules |
| Multi-line text | `ValidatedTextEditor` | For notes, descriptions |
| Email field | `ValidatedTextField` | `.requiredEmail` validation |
| Phone field | `ValidatedTextField` | `.requiredPhone` validation |
| Currency field | `ValidatedTextField` | `.requiredCurrency` validation |

### Loading & Errors
| Scenario | Component | Example |
|----------|-----------|---------|
| Full screen loading | `LoadingView` | `LoadingView(message: "Loading...")` |
| Inline loading | `InlineLoadingView` | Compact spinner |
| Full screen error | `ErrorStateView` | With retry button |
| Inline error | `InlineErrorView` | Compact error message |
| Banner error | `ErrorBannerView` | Top notification |
| Generic state handler | `LoadingStateView` | Handles all states |

### Cards
| Scenario | Component | Example |
|----------|-----------|---------|
| Display info | `InfoCard` | Icon, title, content |
| Call to action | `ActionCard` | With button |
| Quick action | `CompactActionCard` | Smaller version |
| Summary data | `SummaryCard` | Multiple metrics |
| Dashboard widget | `CompactSummaryCard` | With trend |

### Lists
| Scenario | Component | Example |
|----------|-----------|---------|
| Basic list row | `StandardListRow` | Icon, title, subtitle |
| With navigation | `StandardListRow` | `.chevron` accessory |
| With toggle | `StandardListRow` | `.toggle($binding)` accessory |
| With button | `StandardListRow` | `.button("Title", {})` accessory |
| Multi-select | `SelectableListRow` | With selection state |
| Section header | `ListHeader` | With optional action |
| Sticky header | `StickyListHeader` | Stays on scroll |
| Collapsible header | `CollapsibleListHeader` | Expand/collapse |
| Grouped content | `ListSection` | With header/footer |
| Card section | `CardListSection` | Card-styled |

### Progress
| Scenario | Component | Example |
|----------|-----------|---------|
| Linear progress | `ProgressBar` | Horizontal bar |
| Circular progress | `CircularProgress` | Ring indicator |
| Step indicator | `StepProgress` | Dot-based steps |
| Labeled steps | `LabeledStepProgress` | With step names |

### Search
| Scenario | Component | Example |
|----------|-----------|---------|
| Standard search | `SearchBar` | Full width |
| Toolbar search | `CompactSearchBar` | Expandable |

---

## Component Cheat Sheet

### Empty State
```swift
UnifiedEmptyStateView(config: .guests(onAdd: { /* action */ }))
```

### Stats Grid
```swift
StatsGridView(stats: [
    .guestTotal(count: 150),
    .guestConfirmed(count: 120, total: 150)
], columns: 2)
```

### Validated Field
```swift
ValidatedTextField(
    label: "Email",
    text: $email,
    validation: .requiredEmail,
    isRequired: true
)
```

### Loading State
```swift
LoadingStateView(
    state: loadingState,
    content: { data in /* content */ },
    onRetry: { /* retry */ }
)
```

### Info Card
```swift
InfoCard(
    icon: "calendar",
    title: "Wedding Date",
    content: "June 15, 2024",
    color: .blue
)
```

### Action Card
```swift
ActionCard(
    icon: "person.badge.plus",
    title: "Add Guests",
    description: "Build your guest list",
    buttonTitle: "Get Started",
    color: .blue,
    action: { /* action */ }
)
```

### Summary Card
```swift
SummaryCard(
    title: "Overview",
    items: [
        SummaryItem(label: "Total", value: "150"),
        SummaryItem(label: "Confirmed", value: "120", icon: "checkmark.circle.fill", color: .green)
    ]
)
```

### List Row
```swift
StandardListRow(
    icon: "person.fill",
    iconColor: .blue,
    title: "John Smith",
    subtitle: "john@example.com",
    accessory: .chevron,
    action: { /* action */ }
)
```

### List Section
```swift
ListSection(
    title: "Confirmed",
    count: 120,
    icon: "checkmark.circle.fill",
    color: .green
) {
    ForEach(items) { item in
        StandardListRow(...)
    }
}
```

### Search Bar
```swift
SearchBar(
    text: $searchText,
    placeholder: "Search...",
    onSubmit: { /* search */ }
)
```

### Progress Bar
```swift
ProgressBar(
    value: 0.75,
    color: .blue,
    showPercentage: true
)
```

### Circular Progress
```swift
CircularProgress(
    value: 0.75,
    color: .blue,
    size: 80
)
```

---

## Factory Methods Quick Reference

### Empty States
- `.guests(onAdd:)`
- `.vendors(onAdd:)`
- `.notes(onAdd:)`
- `.documents(onAdd:)`
- `.tasks(onAdd:)`
- `.timeline(onAdd:)`
- `.moodBoards(onAdd:)`
- `.colorPalettes(onAdd:)`
- `.searchResults(query:)`
- `.filteredResults()`
- `.custom(...)`

### Stats
**Guests:**
- `.guestTotal(count:)`
- `.guestConfirmed(count:total:)`
- `.guestPending(count:)`
- `.guestDeclined(count:)`

**Vendors:**
- `.vendorTotal(count:)`
- `.vendorBooked(count:)`
- `.vendorPending(count:)`
- `.vendorContacted(count:)`

**Budget:**
- `.budgetTotal(amount:currency:)`
- `.budgetSpent(amount:total:currency:)`
- `.budgetRemaining(amount:currency:)`

**Tasks:**
- `.taskTotal(count:)`
- `.taskCompleted(count:total:)`
- `.taskOverdue(count:)`

### Validation Rules
- `.requiredEmail` - Required + email format
- `.requiredPhone` - Required + phone format
- `.requiredURL` - Required + URL format
- `.requiredName` - Required + 2-50 chars
- `.requiredCurrency` - Required + positive amount

---

## Accessory Types (StandardListRow)

| Accessory | Usage | Example |
|-----------|-------|---------|
| `.none` | No accessory | Plain row |
| `.chevron` | Navigation | `accessory: .chevron` |
| `.checkmark` | Completion | `accessory: .checkmark` |
| `.toggle($binding)` | Switch | `accessory: .toggle($enabled)` |
| `.button("Title", {})` | Action | `accessory: .button("Download", {})` |

---

## Color Palette

Use semantic colors from `AppColors`:

**Status:**
- `AppColors.success` - Green
- `AppColors.error` - Red
- `AppColors.warning` - Orange
- `AppColors.info` - Blue
- `AppColors.pending` - Yellow

**Text:**
- `AppColors.textPrimary`
- `AppColors.textSecondary`
- `AppColors.textTertiary`

**Background:**
- `AppColors.background`
- `AppColors.cardBackground`
- `AppColors.contentBackground`

**Feature-Specific:**
- `AppColors.Guest.*` - Guest colors
- `AppColors.Vendor.*` - Vendor colors
- `AppColors.Budget.*` - Budget colors

---

## Typography

Use semantic typography from `Typography`:

**Titles:**
- `Typography.title1`
- `Typography.title2`
- `Typography.title3`

**Headings:**
- `Typography.heading`
- `Typography.subheading`

**Body:**
- `Typography.bodyLarge`
- `Typography.bodyRegular`
- `Typography.bodySmall`

**Numbers:**
- `Typography.numberLarge`
- `Typography.numberMedium`
- `Typography.numberSmall`

---

## Spacing

Use semantic spacing from `Spacing`:

- `Spacing.xs` - 4pt
- `Spacing.sm` - 8pt
- `Spacing.md` - 12pt
- `Spacing.lg` - 16pt
- `Spacing.xl` - 20pt
- `Spacing.xxl` - 24pt
- `Spacing.xxxl` - 32pt

---

## Decision Tree

### "I need to show..."

**Empty content** → `UnifiedEmptyStateView`

**Statistics** → 
- Single stat → `StatsCardView`
- Multiple stats → `StatsGridView`
- Dashboard widget → `CompactSummaryCard`

**Form input** →
- Text → `ValidatedTextField`
- Multi-line → `ValidatedTextEditor`

**Loading** →
- Full screen → `LoadingView`
- Inline → `InlineLoadingView`
- With states → `LoadingStateView`

**Error** →
- Full screen → `ErrorStateView`
- Inline → `InlineErrorView`
- Banner → `ErrorBannerView`

**List item** →
- Basic → `StandardListRow`
- Selectable → `SelectableListRow`

**Progress** →
- Linear → `ProgressBar`
- Circular → `CircularProgress`
- Steps → `StepProgress` or `LabeledStepProgress`

**Card** →
- Info → `InfoCard`
- Action → `ActionCard`
- Summary → `SummaryCard`

**Search** →
- Full → `SearchBar`
- Compact → `CompactSearchBar`

---

## Tips

1. **Always use factory methods** when available
2. **Check previews** for usage examples
3. **Follow design system** for colors and spacing
4. **Add accessibility labels** for custom content
5. **Test with VoiceOver** after implementation
6. **Use semantic colors** instead of hardcoded values
7. **Leverage composition** - combine components
8. **Keep it simple** - don't over-customize

---

## Need More Help?

1. Check `README.md` for detailed documentation
2. Review `MIGRATION_GUIDE.md` for examples
3. Look at component preview code
4. Check already-migrated views
5. Consult design system documentation
