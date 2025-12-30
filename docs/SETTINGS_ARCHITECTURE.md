# Settings Architecture

## Overview

The settings system in I Do Blueprint uses a hierarchical structure with expandable sections. This document explains the architecture and the relationship between different settings representations.

## Settings Structure

### Main Settings Sections

The settings are organized into the following top-level sections:

1. **Global** (expandable) - Core wedding information
   - Overview - Basic settings (currency, date, timezone, partner info)
   - Wedding Events - Full CRUD interface for wedding events
2. **Theme** - Appearance settings
3. **Budget** - Budget configuration
4. **Tasks** - Task management preferences
5. **Vendors** - Vendor display preferences
6. **Categories** - Custom vendor categories
7. **Guests** - Guest management preferences
8. **Documents** - Document management settings
9. **Collaboration** - Collaborator management
10. **Notifications** - Notification preferences
11. **Links** - Important links
12. **API Keys** - External service integration
13. **Account** - Account management
14. **Feature Flags** - Experimental features
15. **Danger Zone** - Destructive actions

### Expandable Sections

Currently, only the **Global** section is expandable with subsections:
- **Overview**: Basic global settings
- **Wedding Events**: Full event management interface

This pattern can be extended to other sections in the future by:
1. Adding the section to the `hasSubsections` computed property
2. Creating a new subsection enum (e.g., `BudgetSubsection`)
3. Updating the sidebar rendering logic
4. Adding the subsection routing in `sectionContent`

## Wedding Events: Dual Representation

Wedding events exist in two places in the system, serving different purposes:

### 1. Settings JSONB (`couple_settings.settings.global.wedding_events`)

**Type**: `SettingsWeddingEvent`

**Purpose**: Lightweight configuration for basic event information

**Structure**:
```swift
struct SettingsWeddingEvent: Codable, Equatable, Identifiable {
    let id: String
    var eventName: String
    var eventDate: String
    var eventTime: String
    var venueLocation: String
    var description: String
    var isMainEvent: Bool
    var eventOrder: Int
}
```

**Storage**: Stored as JSONB in the `couple_settings` table under `settings.global.wedding_events`

**Use Cases**:
- Quick reference for event names and dates
- Default events created during onboarding
- Lightweight data for dropdowns and selectors

### 2. Database Table (`wedding_events`)

**Type**: `WeddingEvent`

**Purpose**: Full-featured event entities with budget linking and detailed information

**Structure**:
```sql
CREATE TABLE wedding_events (
    id UUID PRIMARY KEY,
    couple_id UUID NOT NULL,
    event_name TEXT NOT NULL,
    event_type TEXT NOT NULL,
    event_date DATE,
    start_time TIME,
    end_time TIME,
    venue_id BIGINT,
    venue_name TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    zip_code TEXT,
    guest_count INTEGER,
    budget_allocated NUMERIC,
    notes TEXT,
    is_confirmed BOOLEAN,
    description TEXT,
    event_order INTEGER,
    is_main_event BOOLEAN,
    venue_location VARCHAR,
    event_time TIME,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
```

**Use Cases**:
- Full CRUD operations on events
- Linking budget items to specific events
- Detailed venue and guest information
- Budget allocation tracking
- Event confirmation status

### Relationship and Synchronization

**Source of Truth**: The `wedding_events` database table is the authoritative source for wedding events.

**Migration Path**:
1. During onboarding, default events are created in `couple_settings.settings.global.wedding_events`
2. These can be migrated to the `wedding_events` table when users need full event management
3. The settings JSONB can be kept for backward compatibility or removed in favor of querying the database table

**Recommendation**: 
- Consider deprecating `SettingsWeddingEvent` in favor of always using the `wedding_events` table
- Add a migration to copy any existing settings events to the database table
- Update code that reads from settings to query the database instead

## UI Navigation

### Sidebar Structure

The settings sidebar uses a `NavigationSplitView` with:
- **List** for top-level sections
- **DisclosureGroup** for expandable sections (currently only Global)
- **Button** for subsection navigation within disclosure groups
- **NavigationLink** for non-expandable sections

### Selection State

The view maintains two state variables:
- `selectedSection: SettingsSection` - Currently selected top-level section
- `selectedGlobalSubsection: GlobalSubsection` - Currently selected subsection within Global

### Navigation Title

The navigation title dynamically updates based on the selected section:
- For Global: "Global - [Subsection Name]" (e.g., "Global - Wedding Events")
- For other sections: "[Section Name]" (e.g., "Budget")

## Implementation Details

### Key Files

- **SettingsView.swift**: Main settings container with sidebar and detail view
- **GlobalSettingsView.swift**: Overview subsection of Global settings
- **WeddingEventsView.swift**: Wedding Events subsection with full CRUD interface
- **SettingsModel.swift**: Data models for settings structure

### Adding New Subsections

To add subsections to another section (e.g., Budget):

1. Update the section enum:
```swift
var hasSubsections: Bool {
    switch self {
    case .global, .budget: true  // Add .budget
    default: false
    }
}
```

2. Create a subsection enum:
```swift
enum BudgetSubsection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case categories = "Categories"
    case taxRates = "Tax Rates"
    
    var id: String { rawValue }
    var icon: String { /* ... */ }
}
```

3. Add state variable:
```swift
@State private var selectedBudgetSubsection: BudgetSubsection = .overview
```

4. Update sidebar rendering to handle the new subsection type

5. Update `sectionContent` to route to subsection views

## Best Practices

1. **Single Source of Truth**: Use the database table for authoritative data
2. **Settings for Configuration**: Use JSONB settings for user preferences, not entity data
3. **Expandable Sections**: Use subsections for logically grouped settings within a domain
4. **Navigation State**: Maintain separate state variables for each expandable section
5. **Consistent Icons**: Use SF Symbols consistently across sections and subsections

## Future Improvements

1. **Migrate Settings Events**: Move all event data to the database table
2. **Add More Subsections**: Consider adding subsections to Budget, Vendors, and Guests
3. **Breadcrumb Navigation**: Add breadcrumb trail for nested navigation
4. **Search**: Add search functionality to quickly find settings
5. **Recent Settings**: Track and display recently accessed settings
6. **Settings Sync**: Implement real-time sync for settings changes across collaborators
