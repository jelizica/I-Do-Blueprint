# Unified Component Library

A comprehensive collection of reusable UI components for consistent design and improved maintainability across the I Do Blueprint app.

## Overview

This component library eliminates UI duplication by providing standardized, accessible, and well-tested components that can be used throughout the application. All components follow the design system defined in `Design/DesignSystem.swift` and include full accessibility support.

## Components

### Empty State Components

Located in `EmptyState/`

#### UnifiedEmptyStateView

A unified empty state component that replaces all duplicate empty state implementations.

**Features:**
- Consistent icon, title, message layout
- Optional action button
- Full accessibility support
- Smooth transitions and animations

**Usage:**

```swift
// Using factory methods
UnifiedEmptyStateView(config: .guests(onAdd: {
    showAddGuestSheet = true
}))

UnifiedEmptyStateView(config: .vendors(onAdd: {
    showAddVendorSheet = true
}))

// Search results
UnifiedEmptyStateView(config: .searchResults(query: searchText))

// Custom configuration
UnifiedEmptyStateView(
    config: .custom(
        icon: "star.fill",
        title: "No Favorites",
        message: "Mark items as favorites to see them here.",
        actionTitle: "Browse Items",
        onAction: { navigateToBrowse() }
    )
)
```

**Available Factory Methods:**
- `.guests(onAdd:)` - Guest list empty state
- `.vendors(onAdd:)` - Vendor list empty state
- `.notes(onAdd:)` - Notes empty state
- `.documents(onAdd:)` - Documents empty state
- `.tasks(onAdd:)` - Tasks empty state
- `.timeline(onAdd:)` - Timeline events empty state
- `.moodBoards(onAdd:)` - Mood boards empty state
- `.colorPalettes(onAdd:)` - Color palettes empty state
- `.budgetCategories(onAdd:)` - Budget categories empty state
- `.expenses(onAdd:)` - Expenses empty state
- `.searchResults(query:)` - Search results empty state
- `.filteredResults()` - Filtered results empty state
- `.custom(...)` - Custom configuration

---

### Stats Components

Located in `Stats/`

#### StatsGridView

A grid layout for displaying multiple statistics cards.

**Features:**
- Flexible column configuration
- Adaptive layout support
- Consistent spacing and styling
- Accessibility labels for all stats

**Usage:**

```swift
// Fixed columns
StatsGridView(
    stats: [
        .guestTotal(count: 150),
        .guestConfirmed(count: 120, total: 150),
        .guestPending(count: 25),
        .guestDeclined(count: 5)
    ],
    columns: 2
)

// Adaptive columns (adjusts based on available width)
AdaptiveStatsGridView(
    stats: stats,
    minColumnWidth: 180
)
```

#### StatsCardView

Individual statistics card with icon, value, label, and optional trend indicator.

**Features:**
- Color-coded icons
- Large, readable values
- Trend indicators (up/down/neutral)
- Full accessibility support

**Usage:**

```swift
StatsCardView(stat: .guestTotal(count: 150))

// Custom stat with trend
StatsCardView(
    stat: StatItem(
        icon: "person.3.fill",
        label: "Total Guests",
        value: "150",
        color: .blue,
        trend: .up("+10"),
        accessibilityLabel: "Total guests: 150, up 10 from last week"
    )
)
```

#### StatItem Factory Methods

**Guest Statistics:**
- `.guestTotal(count:)` - Total guests
- `.guestConfirmed(count:total:)` - Confirmed guests with percentage
- `.guestPending(count:)` - Pending responses
- `.guestDeclined(count:)` - Declined guests

**Vendor Statistics:**
- `.vendorTotal(count:)` - Total vendors
- `.vendorBooked(count:)` - Booked vendors
- `.vendorPending(count:)` - Pending vendors
- `.vendorContacted(count:)` - Contacted vendors

**Budget Statistics:**
- `.budgetTotal(amount:currency:)` - Total budget
- `.budgetSpent(amount:total:currency:)` - Amount spent with percentage
- `.budgetRemaining(amount:currency:)` - Remaining budget

**Task Statistics:**
- `.taskTotal(count:)` - Total tasks
- `.taskCompleted(count:total:)` - Completed tasks with percentage
- `.taskOverdue(count:)` - Overdue tasks

---

### Form Components

Located in `Forms/`

#### ValidatedTextField

Text field with built-in validation and error display.

**Features:**
- Inline validation with error messages
- Required field indicator
- Keyboard type configuration
- Accessibility support
- Validates on blur and change

**Usage:**

```swift
@State private var name = ""
@State private var email = ""
@State private var phone = ""

ValidatedTextField(
    label: "Name",
    text: $name,
    placeholder: "Enter name",
    validation: .requiredName,
    isRequired: true
)

ValidatedTextField(
    label: "Email",
    text: $email,
    placeholder: "email@example.com",
    validation: .requiredEmail,
    isRequired: true,
    keyboardType: .emailAddress,
    autocapitalization: .never,
    autocorrection: false
)

ValidatedTextField(
    label: "Phone",
    text: $phone,
    placeholder: "(555) 123-4567",
    validation: PhoneRule(),
    keyboardType: .phonePad
)
```

#### ValidatedTextEditor

Multi-line text editor with validation support.

**Usage:**

```swift
@State private var notes = ""

ValidatedTextEditor(
    label: "Notes",
    text: $notes,
    placeholder: "Enter your notes here...",
    validation: RequiredRule(fieldName: "Notes"),
    isRequired: true,
    minHeight: 150
)
```

#### Validation Rules

**Built-in Rules:**
- `RequiredRule` - Field must not be empty
- `EmailRule` - Valid email format
- `PhoneRule` - Valid phone number
- `URLRule` - Valid URL format
- `NumericRule` - Numeric input only
- `CurrencyRule` - Valid currency amount
- `MinLengthRule` - Minimum character length
- `MaxLengthRule` - Maximum character length
- `DateRule` - Valid date format

**Composite Rules:**
- `.requiredEmail` - Required + email validation
- `.requiredPhone` - Required + phone validation
- `.requiredURL` - Required + URL validation
- `.requiredName` - Required + 2-50 characters
- `.requiredCurrency` - Required + positive amount

**Custom Rules:**

```swift
struct CustomRule: ValidationRule {
    func validate(_ value: String) -> ValidationResult {
        if value.contains("invalid") {
            return .invalid("Value cannot contain 'invalid'")
        }
        return .valid
    }
}

// Combine multiple rules
let compositeRule = CompositeRule(rules: [
    RequiredRule(fieldName: "Username"),
    MinLengthRule(minLength: 3, fieldName: "Username"),
    MaxLengthRule(maxLength: 20, fieldName: "Username")
])
```

---

### Loading Components

Located in `Loading/`

#### LoadingStateView

Generic loading state handler for async data.

**Features:**
- Handles idle, loading, loaded, and error states
- Optional retry functionality
- Smooth transitions between states
- Accessibility support

**Usage:**

```swift
@State private var loadingState: LoadingState<[Guest]> = .idle

LoadingStateView(
    state: loadingState,
    content: { guests in
        List(guests) { guest in
            GuestRow(guest: guest)
        }
    },
    onRetry: {
        Task {
            await loadGuests()
        }
    }
)
```

#### LoadingView

Simple loading indicator with message.

**Usage:**

```swift
LoadingView(message: "Loading guests...")
```

#### InlineLoadingView

Compact loading indicator for smaller spaces.

**Usage:**

```swift
InlineLoadingView(message: "Saving...")
```

#### ErrorStateView

Full-screen error display with retry option.

**Usage:**

```swift
ErrorStateView(
    error: error,
    onRetry: {
        Task {
            await retryLoad()
        }
    }
)
```

#### InlineErrorView

Compact error display for inline use.

**Usage:**

```swift
InlineErrorView(
    message: "Failed to save changes",
    onRetry: {
        Task {
            await retrySave()
        }
    }
)
```

#### ErrorBannerView

Top banner for error notifications.

**Usage:**

```swift
ErrorBannerView(
    message: "Network connection lost",
    onDismiss: {
        dismissError()
    }
)
```

---

## Design Principles

### Consistency

All components follow the design system:
- Use `Spacing` constants for padding and margins
- Use `Typography` for text styles
- Use `AppColors` for colors
- Use `CornerRadius` for rounded corners
- Use `AnimationStyle` for animations

### Accessibility

All components include:
- Proper accessibility labels
- Accessibility hints where appropriate
- VoiceOver support
- Keyboard navigation support
- High contrast support
- Dynamic type support

### Reusability

Components are designed to be:
- Highly configurable through parameters
- Easy to use with factory methods
- Composable with other components
- Type-safe with Swift's type system

### Performance

Components are optimized for:
- Lazy loading where appropriate
- Efficient rendering with SwiftUI best practices
- Minimal state management
- Smooth animations

---

## Migration Guide

### Replacing Empty States

**Before:**
```swift
if guests.isEmpty {
    EmptyGuestListView()
}
```

**After:**
```swift
if guests.isEmpty {
    UnifiedEmptyStateView(config: .guests(onAdd: {
        showAddGuestSheet = true
    }))
}
```

### Replacing Stats Views

**Before:**
```swift
LazyVGrid(columns: columns) {
    ModernStatCard(title: "Total", value: "\(count)", icon: "person.3.fill", color: .blue)
    ModernStatCard(title: "Confirmed", value: "\(confirmed)", icon: "checkmark.circle.fill", color: .green)
}
```

**After:**
```swift
StatsGridView(
    stats: [
        .guestTotal(count: count),
        .guestConfirmed(count: confirmed, total: count)
    ],
    columns: 2
)
```

### Replacing Form Fields

**Before:**
```swift
TextField("Name", text: $name)
    .textFieldStyle(.roundedBorder)
```

**After:**
```swift
ValidatedTextField(
    label: "Name",
    text: $name,
    placeholder: "Enter name",
    validation: .requiredName,
    isRequired: true
)
```

---

## Testing

All components include:
- SwiftUI previews for visual testing
- Accessibility testing support
- Example usage in previews
- Multiple states demonstrated

To test components:
1. Open the component file in Xcode
2. Enable Canvas (⌥⌘↩)
3. View all preview variants
4. Test with VoiceOver enabled
5. Test in light and dark mode

---

## Contributing

When adding new components:

1. **Follow the design system** - Use existing spacing, colors, and typography
2. **Add accessibility** - Include proper labels, hints, and traits
3. **Create factory methods** - For common use cases
4. **Write documentation** - Update this README with usage examples
5. **Add previews** - Include multiple preview variants
6. **Test thoroughly** - Test in different states and modes

---

## Support

For questions or issues with components:
1. Check this README for usage examples
2. Review the component's preview code
3. Check the design system documentation
4. Consult with the design team

---

## Version History

### v1.0.0 (Current)
- Initial component library release
- Empty state components
- Stats components
- Form validation components
- Loading state components
- Comprehensive documentation

---

## Card Components

Located in `Cards/`

### InfoCard

Informational card for displaying key details with icon, title, and content.

**Usage:**

```swift
InfoCard(
    icon: "calendar",
    title: "Wedding Date",
    content: "June 15, 2024",
    color: .blue
)

// With action
InfoCard(
    icon: "mappin.circle.fill",
    title: "Venue",
    content: "Grand Ballroom, Downtown Hotel",
    color: .purple,
    action: {
        navigateToVenue()
    }
)
```

### ActionCard

Action card for prominent call-to-action buttons.

**Usage:**

```swift
ActionCard(
    icon: "person.badge.plus",
    title: "Add Guests",
    description: "Start building your guest list and track RSVPs.",
    buttonTitle: "Add Your First Guest",
    color: .blue,
    action: {
        showAddGuestSheet = true
    }
)

// Compact version
CompactActionCard(
    icon: "calendar.badge.plus",
    title: "Add Event",
    color: .blue,
    action: { showAddEventSheet = true }
)
```

### SummaryCard

Summary card for displaying aggregated data with multiple metrics.

**Usage:**

```swift
SummaryCard(
    title: "Wedding Overview",
    items: [
        SummaryItem(label: "Total Guests", value: "150", icon: "person.3.fill", color: .blue),
        SummaryItem(label: "Confirmed", value: "120", icon: "checkmark.circle.fill", color: .green),
        SummaryItem(label: "Pending", value: "25", icon: "clock.fill", color: .orange)
    ],
    action: {
        navigateToGuestList()
    }
)

// Compact version for dashboards
CompactSummaryCard(
    title: "Total Budget",
    value: "$25,000",
    subtitle: "Allocated",
    icon: "dollarsign.circle.fill",
    color: .blue,
    trend: .up("+$2,000")
)
```

---

## List Components

Located in `Lists/`

### StandardListRow

Standard list row with icon, title, subtitle, and optional accessories.

**Usage:**

```swift
// Basic row
StandardListRow(
    icon: "person.fill",
    iconColor: .blue,
    title: "John Smith",
    subtitle: "john@example.com",
    accessory: .chevron,
    action: { selectGuest() }
)

// With badge
StandardListRow(
    icon: "building.2.fill",
    iconColor: .purple,
    title: "Grand Ballroom",
    subtitle: "Downtown Hotel • Booked",
    badge: "Confirmed",
    badgeColor: .green,
    accessory: .checkmark
)

// With toggle
StandardListRow(
    icon: "bell.fill",
    iconColor: .orange,
    title: "Push Notifications",
    subtitle: "Receive updates",
    accessory: .toggle($notificationsEnabled)
)

// With button
StandardListRow(
    icon: "doc.fill",
    iconColor: .red,
    title: "Contract.pdf",
    subtitle: "2.4 MB",
    accessory: .button("Download", { downloadFile() })
)
```

**Accessory Types:**
- `.none` - No accessory
- `.chevron` - Right chevron indicator
- `.checkmark` - Checkmark icon
- `.toggle(Binding<Bool>)` - Toggle switch
- `.button(String, () -> Void)` - Action button

### SelectableListRow

List row with selection state for multi-select lists.

**Usage:**

```swift
SelectableListRow(
    icon: "person.fill",
    iconColor: .blue,
    title: "John Smith",
    subtitle: "Attending",
    isSelected: selectedGuests.contains(guest.id),
    action: {
        toggleSelection(guest.id)
    }
)
```

### ListHeader

Standard list header with title and optional action.

**Usage:**

```swift
ListHeader(
    title: "Recent Guests",
    count: 25
)

// With action
ListHeader(
    title: "Vendors",
    count: 12,
    action: ListHeader.ActionConfig(
        title: "Add",
        icon: "plus",
        handler: { showAddVendor = true }
    )
)
```

### StickyListHeader

Sticky header that stays at top during scroll.

**Usage:**

```swift
StickyListHeader(
    title: "Confirmed",
    count: 120,
    icon: "checkmark.circle.fill",
    color: .green
)
```

### CollapsibleListHeader

Header with expand/collapse functionality.

**Usage:**

```swift
CollapsibleListHeader(
    title: "Pending Responses",
    count: 25,
    isExpanded: $isPendingExpanded
)
```

### ListSection

Standard list section with header and content.

**Usage:**

```swift
ListSection(
    title: "Confirmed Guests",
    count: 120,
    icon: "checkmark.circle.fill",
    color: .green,
    footer: "All guests have confirmed"
) {
    ForEach(confirmedGuests) { guest in
        StandardListRow(
            icon: "person.fill",
            title: guest.name,
            subtitle: "Attending",
            accessory: .chevron
        )
    }
}
```

### CollapsibleListSection

List section with expand/collapse functionality.

**Usage:**

```swift
CollapsibleListSection(
    title: "Confirmed",
    count: 120,
    isExpandedByDefault: true
) {
    ForEach(confirmedGuests) { guest in
        GuestRow(guest: guest)
    }
}
```

### CardListSection

List section styled as a card.

**Usage:**

```swift
CardListSection(
    title: "Recent Activity",
    subtitle: "Last 7 days",
    action: ListHeader.ActionConfig(
        title: "View All",
        handler: { showAllActivity() }
    )
) {
    ForEach(recentActivities) { activity in
        ActivityRow(activity: activity)
    }
}
```

---

## Common Components

Located in `Common/`

### SearchBar

Standard search bar with clear button.

**Usage:**

```swift
SearchBar(
    text: $searchText,
    placeholder: "Search guests...",
    onSubmit: {
        performSearch()
    }
)

// Compact version for toolbars
CompactSearchBar(
    text: $searchText,
    placeholder: "Search..."
)
```

### ProgressIndicator

Various progress indicator components.

**Linear Progress Bar:**

```swift
ProgressBar(
    value: 0.75,
    color: .blue,
    height: 8,
    showPercentage: true
)
```

**Circular Progress:**

```swift
CircularProgress(
    value: 0.75,
    color: .blue,
    size: 80,
    showPercentage: true
)
```

**Step Progress:**

```swift
StepProgress(
    currentStep: 2,
    totalSteps: 4,
    color: .blue
)

// With labels
LabeledStepProgress(
    steps: ["Details", "Guests", "Vendors", "Review"],
    currentStep: 2,
    color: .blue
)
```

---

## Future Enhancements

Potential additions:
- Additional validation rules
- More factory methods for common scenarios
- Component composition examples
- Advanced form layouts
- Date picker components
- File upload components
