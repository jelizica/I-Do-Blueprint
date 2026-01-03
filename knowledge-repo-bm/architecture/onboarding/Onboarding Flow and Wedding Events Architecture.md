---
title: Onboarding Flow and Wedding Events Architecture
type: note
permalink: architecture/onboarding/onboarding-flow-and-wedding-events-architecture
tags:
- onboarding
- events
- architecture
- guest-attendance
---

# Onboarding Flow and Wedding Events Architecture

## Overview
This document describes how the onboarding flow works and how wedding events are managed across the application.

## Two Event Systems
**NOTE: The settings-based events are being deprecated. The `wedding_events` table is now the single source of truth.**

### 1. Settings-based Events (`couple_settings.settings.global.weddingEvents`) - DEPRECATED
- **Storage**: JSON field in the `couple_settings` table
- **Model**: `SettingsWeddingEvent`
- **Manager**: `SettingsStoreV2`
- **Status**: Being phased out - see Beads issue I Do Blueprint-co0

### 2. Database Events (`wedding_events` table) - PRIMARY
- **Storage**: Dedicated PostgreSQL table
- **Model**: `WeddingEventDB` (aliased as `WeddingEvent`)
- **Manager**: `BudgetStoreV2`
- **Purpose**: Budget linking, guest attendance tracking
- **Event Types**: `ceremony`, `reception`, `rehearsal`, `other`

## WeddingEventType Enum

The `WeddingEventType` enum defines the 4 valid event types:

```swift
enum WeddingEventType: String, Codable, CaseIterable {
    case ceremony = "ceremony"
    case reception = "reception"
    case rehearsal = "rehearsal"
    case other = "other"
}
```

Each type has:
- `displayName` - Human-readable name
- `icon` - SF Symbol icon
- `colorName` - Color for UI display
- `requiresNote` - Whether notes are required (true for "other")
- `defaultEventName` - Default name when creating events

### 1. Settings-based Events (`couple_settings.settings.global.weddingEvents`)
- **Storage**: JSON field in the `couple_settings` table
- **Model**: `SettingsWeddingEvent`
- **Manager**: `SettingsStoreV2`
- **Purpose**: User preferences and display settings

### 2. Database Events (`wedding_events` table)
- **Storage**: Dedicated PostgreSQL table
- **Model**: `WeddingEventDB` (aliased as `WeddingEvent`)
- **Manager**: `BudgetStoreV2`
- **Purpose**: Budget linking, guest attendance tracking

## Onboarding Flow

### Steps
1. **Welcome** - Introduction and mode selection (guided vs express)
2. **Wedding Details** - Partner names, wedding date, venue, events
3. **Default Settings** - Currency, timezone, preferences
4. **Feature Preferences** - Tasks, vendors, guests, documents settings (guided only)
5. **Guest Import** - Optional CSV/XLSX import (guided only)
6. **Vendor Import** - Optional CSV/XLSX import (guided only)
7. **Budget Setup** - Initial budget configuration
8. **Completion** - Summary and finish

### Event Creation During Onboarding

When onboarding completes, `OnboardingSettingsService.createSettings()`:

1. Creates/updates `couple_settings` record with wedding events in JSON
2. **NEW**: Also creates events in `wedding_events` table for guest attendance

```swift
// Events are created in both places:
// 1. Settings JSON (for display preferences)
settings.global.weddingEvents = convertedEvents

// 2. Database table (for guest attendance tracking)
await createWeddingEventsInDatabase(coupleId, events, weddingDate)
```

### Event Type Mapping

The system determines event types based on event names:
- "Ceremony" → `ceremony`
- "Reception" → `reception`
- "Rehearsal", "Welcome", "Dinner" → `rehearsal`
- "Brunch" → `brunch`
- "Party" → `party`
- Main event without match → `ceremony`
- Other → `other`

## Guest Attendance Integration

The `GuestDetailEventAttendance` component reads from `budgetStore.weddingEvents` to dynamically show only events that exist:

```swift
GuestDetailEventAttendance(
    guest: guest,
    weddingEvents: budgetStore.weddingEvents
)
```

### Attendance Mapping
- `rehearsal` type → `guest.attendingRehearsal`
- `ceremony` type → `guest.attendingCeremony`
- `reception` type → `guest.attendingReception`

## Key Files

### Onboarding
- `Services/Stores/OnboardingStoreV2.swift` - Main onboarding state management
- `Services/Stores/Onboarding/OnboardingSettingsService.swift` - Creates settings and events
- `Domain/Models/Onboarding/OnboardingModels.swift` - Onboarding data models
- `Views/Onboarding/WeddingDetailsView.swift` - Event configuration UI

### Events
- `Domain/Models/Shared/Wedding.swift` - `WeddingEventDB` model
- `Domain/Models/Settings/SettingsModel.swift` - `SettingsWeddingEvent` model
- `Services/Stores/BudgetStoreV2.swift` - `weddingEvents` property
- `Views/Settings/WeddingEventsView.swift` - Event management UI

### Guest Attendance
- `Views/Guests/Components/GuestDetailEventAttendance.swift` - Dynamic event display
- `Views/Guests/GuestDetailViewV4.swift` - Injects budget store for events

## Implementation Notes

### Why Two Systems?
1. **Settings events** are part of the user's preferences JSON, easy to modify
2. **Database events** have proper foreign key relationships for budget items

### Sync Strategy
- Onboarding creates events in both places
- Settings view (`WeddingEventsView`) manages database events directly
- Guest attendance reads from database events only

## Related Entities
- [[OnboardingStoreV2]] - Onboarding state management
- [[BudgetStoreV2]] - Wedding events from database
- [[SettingsStoreV2]] - Settings including events JSON
- [[GuestDetailEventAttendance]] - Dynamic event display


## Update (2025-01-01): Event Type Dropdown Implementation

### Changes Made

1. **Added `WeddingEventType` enum** to `Wedding.swift`:
   - 4 valid types: `ceremony`, `reception`, `rehearsal`, `other`
   - Each type has `displayName`, `icon`, `colorName`, `requiresNote`, `defaultEventName`

2. **Updated `OnboardingWeddingEvent`** in `OnboardingModels.swift`:
   - Added `eventType: WeddingEventType` property
   - Added `notes: String` property (required for "other" type)
   - Updated default event factory methods

3. **Updated `WeddingEventCard`** in `WeddingDetailsView.swift`:
   - Added dropdown picker for event type selection
   - Shows notes field when "Other" type is selected
   - Auto-updates event name when type changes

4. **Updated `OnboardingSettingsService`**:
   - Uses `event.eventType.rawValue` directly instead of inferring from name
   - Stores notes in database for "other" type events
   - Clears `settings.global.weddingEvents` (deprecated)

### Technical Debt
- Settings-based events (`couple_settings.settings.global.weddingEvents`) should be fully removed
- See Beads issue I Do Blueprint-co0 for cleanup task
