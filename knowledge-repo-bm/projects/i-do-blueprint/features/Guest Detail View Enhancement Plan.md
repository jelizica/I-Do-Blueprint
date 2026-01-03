---
title: Guest Detail View Enhancement Plan
type: note
permalink: projects/i-do-blueprint/features/guest-detail-view-enhancement-plan
tags:
- guest
- ui
- enhancement
- plan
- detail-view
- edit-view
---

# Guest Detail View Enhancement Plan

## Overview
This plan outlines the comprehensive enhancement of the Guest Detail View and Edit Guest interfaces to align with all database fields and improve the user experience.

## Current State Analysis

### Database Fields (guest_list table)
The `guest_list` table contains 39 fields. Here's the complete list with their current UI coverage:

| Field | Type | In Detail View | In Edit View | In Add View |
|-------|------|----------------|--------------|-------------|
| id | uuid | ❌ | ❌ | ❌ |
| created_at | timestamp | ❌ | ❌ | ❌ |
| updated_at | timestamp | ❌ | ❌ | ❌ |
| first_name | text | ✅ (header) | ✅ | ✅ |
| last_name | text | ✅ (header) | ✅ | ✅ |
| email | text | ✅ | ✅ | ✅ |
| phone | text | ✅ | ✅ | ✅ |
| guest_group_id | uuid | ❌ | ❌ | ❌ |
| relationship_to_couple | text | ✅ (header) | ✅ | ✅ |
| invited_by | text | ✅ (header) | ✅ | ✅ |
| rsvp_status | text | ✅ | ✅ | ✅ |
| rsvp_date | date | ❌ | ❌ | ❌ |
| plus_one_allowed | boolean | ✅ | ✅ | ✅ |
| plus_one_name | text | ✅ | ✅ | ✅ |
| plus_one_attending | boolean | ❌ | ✅ | ❌ |
| **attending_ceremony** | boolean | ✅ | ❌ | ✅ |
| **attending_reception** | boolean | ✅ | ❌ | ✅ |
| attending_other_events | text[] | ❌ | ❌ | ❌ |
| dietary_restrictions | text | ✅ | ✅ | ✅ |
| accessibility_needs | text | ❌ | ❌ | ✅ |
| table_assignment | integer | ✅ (additional) | ❌ | ❌ |
| seat_number | integer | ✅ (additional) | ❌ | ❌ |
| preferred_contact_method | text | ✅ (additional) | ❌ | ✅ |
| address_line1 | text | ✅ | ❌ | ✅ |
| address_line2 | text | ✅ | ❌ | ✅ |
| city | text | ✅ | ❌ | ✅ |
| state | text | ✅ | ❌ | ✅ |
| zip_code | text | ✅ | ❌ | ✅ |
| country | text | ✅ | ❌ | ✅ |
| invitation_number | text | ✅ (additional) | ❌ | ❌ |
| is_wedding_party | boolean | ✅ (additional) | ❌ | ✅ |
| wedding_party_role | text | ❌ | ❌ | ✅ |
| preparation_notes | text | ❌ | ❌ | ❌ |
| couple_id | uuid | ❌ | ❌ | ❌ |
| meal_option | text | ✅ | ✅ | ✅ |
| gift_received | boolean | ✅ (additional) | ❌ | ❌ |
| notes | text | ✅ | ✅ | ✅ |
| hair_done | boolean | ❌ | ❌ | ❌ |
| makeup_done | boolean | ❌ | ❌ | ❌ |

### Wedding Events (from database)
The system has 4 wedding events:
1. **Pre-Wedding Expenses** (other) - 2025-12-26
2. **Welcome Dinner** (rehearsal) - 2026-08-10
3. **Wedding Ceremony** (ceremony) - 2026-08-11
4. **Wedding Reception** (reception) - 2026-08-11

### Key Issues Identified

1. **Event Attendance Mismatch**: 
   - UI shows "Ceremony" and "Reception" checkmarks
   - Database has `attending_ceremony`, `attending_reception`, and `attending_other_events[]`
   - User wants: Ceremony/Reception AND Welcome Dinner (not just ceremony/reception)
   - These fields should be **hidden unless guest is attending** (rsvp_status = attending/confirmed)

2. **Missing Fields in Edit View**:
   - attending_ceremony, attending_reception (CRITICAL - shown in detail but not editable!)
   - attending_other_events (Welcome Dinner)
   - accessibility_needs
   - table_assignment, seat_number
   - preferred_contact_method
   - address fields (line1, line2, city, state, zip_code, country)
   - invitation_number
   - is_wedding_party, wedding_party_role
   - gift_received
   - hair_done, makeup_done
   - preparation_notes
   - rsvp_date

3. **Missing Fields in Detail View**:
   - rsvp_date
   - plus_one_attending
   - attending_other_events (Welcome Dinner)
   - accessibility_needs
   - wedding_party_role (when is_wedding_party is true)
   - preparation_notes
   - hair_done, makeup_done

## Proposed Solution

### Phase 1: Update Guest Detail View (GuestDetailViewV4)

#### 1.1 Reorganize into Logical Sections
The detail view should be organized into clear sections:

1. **Header Section** (existing - keep as is)
   - Avatar, Name, Relationship, Invited By

2. **Contact Section** (enhance)
   - Email, Phone, Plus One info
   - Add: Preferred Contact Method

3. **RSVP & Status Section** (enhance)
   - RSVP Status, Meal Choice
   - Add: RSVP Date (when available)

4. **Event Attendance Section** (MAJOR CHANGE)
   - **Conditional visibility**: Only show when rsvp_status is "attending" or "confirmed"
   - Show: Welcome Dinner, Ceremony, Reception attendance
   - Use wedding_events table to dynamically show events

5. **Dietary & Accessibility Section** (new combined section)
   - Dietary Restrictions
   - Add: Accessibility Needs

6. **Address Section** (existing - keep as is)

7. **Wedding Party Section** (new - conditional)
   - Only show if is_wedding_party = true
   - Show: Wedding Party Role
   - Show: Hair Done, Makeup Done toggles
   - Show: Preparation Notes

8. **Additional Details Section** (enhance)
   - Preferred Contact Method
   - Invitation Number
   - Gift Received
   - Table Assignment, Seat Number

9. **Notes Section** (existing - keep as is)

### Phase 2: Update Edit Guest View (EditGuestSheetV2)

#### 2.1 Add Missing Fields
Reorganize into a tabbed interface similar to AddGuestView:

**Tab 1: Basic Info**
- First Name, Last Name (existing)
- Relationship (existing)
- Invited By (existing)
- RSVP Status (existing)
- RSVP Date (NEW)

**Tab 2: Event Attendance** (NEW - conditional)
- Only enabled/visible when RSVP status is "attending" or "confirmed"
- Welcome Dinner attendance toggle
- Ceremony attendance toggle
- Reception attendance toggle

**Tab 3: Contact & Address**
- Email, Phone (existing)
- Preferred Contact Method (NEW)
- Address fields (NEW): line1, line2, city, state, zip, country

**Tab 4: Plus One**
- Plus One Allowed (existing)
- Plus One Name (existing)
- Plus One Attending (existing)

**Tab 5: Meal & Dietary**
- Meal Option (existing)
- Dietary Restrictions (existing)
- Accessibility Needs (NEW)

**Tab 6: Wedding Party** (conditional)
- Is Wedding Party toggle
- Wedding Party Role (when enabled)
- Hair Done toggle (when enabled)
- Makeup Done toggle (when enabled)
- Preparation Notes (when enabled)

**Tab 7: Additional**
- Invitation Number (NEW)
- Table Assignment (NEW)
- Seat Number (NEW)
- Gift Received (NEW)
- Notes (existing)

### Phase 3: Update Add Guest View (AddGuestView)

Similar structure to Edit view, ensuring all fields are available.

## Implementation Details

### Event Attendance Logic
```swift
// Show event attendance section only when guest is attending
var shouldShowEventAttendance: Bool {
    guest.rsvpStatus == .attending || guest.rsvpStatus == .confirmed
}

// Map attending_other_events to specific events
// "welcome_dinner" -> Welcome Dinner event
// Use wedding_events table IDs for proper mapping
```

### Conditional Field Visibility
```swift
// Wedding Party section visibility
var shouldShowWeddingPartySection: Bool {
    guest.isWeddingParty
}

// Hair/Makeup fields only for wedding party members
var shouldShowPreparationFields: Bool {
    guest.isWeddingParty
}
```

### Database Event Mapping
The `attending_other_events` field is a text array. We should map it to the wedding_events:
- `["welcome_dinner"]` -> Welcome Dinner event (id: b635a772-540f-4ac1-9f56-1725ddae52f5)

## Files to Modify

### Detail View Components
1. `GuestDetailViewV4.swift` - Main view orchestration
2. `GuestDetailEventAttendance.swift` - Add Welcome Dinner, conditional visibility
3. `GuestDetailAdditionalDetails.swift` - Add missing fields
4. NEW: `GuestDetailWeddingPartySection.swift` - Wedding party specific info
5. NEW: `GuestDetailAccessibilitySection.swift` - Accessibility needs

### Edit View
1. `EditGuestSheetV2.swift` - Complete overhaul with tabs and all fields

### Add View
1. `AddGuestView.swift` - Ensure parity with edit view

### Supporting Files
1. `Guest.swift` - Model already complete, no changes needed

## Testing Considerations

1. Test conditional visibility of event attendance based on RSVP status
2. Test wedding party section visibility
3. Test all field persistence through edit flow
4. Test data integrity between detail view and edit view

## Estimated Effort

- Phase 1 (Detail View): 2-3 hours
- Phase 2 (Edit View): 3-4 hours  
- Phase 3 (Add View): 1-2 hours
- Testing: 1-2 hours

**Total: 7-11 hours**

## Success Criteria

1. All 39 database fields are viewable in detail view (where applicable)
2. All editable fields are available in edit view
3. Event attendance section only shows when guest is attending
4. Welcome Dinner is included in event attendance options
5. Wedding party section shows preparation fields (hair, makeup, notes)
6. UI maintains clean, organized appearance with logical groupings

## Related Entities
- [[Guest Model]] - Domain model for guest data
- [[GuestStoreV2]] - State management for guests
- [[Wedding Events]] - Event data for attendance tracking
- [[EditGuestSheetV2]] - Current edit interface
- [[AddGuestView]] - Current add interface


## Implementation Progress
### Completed ✅

#### Phase 1: Database Migration
- [x] Added `attending_rehearsal` column to `guest_list` table
- [x] Set default value to `true`
- [x] Updated existing guests: `attending_rehearsal = attending_ceremony`

#### Phase 2: Model Updates
- [x] Added `attendingRehearsal: Bool` property to `Guest.swift`
- [x] Added `attendingRehearsal` CodingKey mapping
- [x] Added `isAttending` computed property for convenience

#### Phase 3: Detail View Components
- [x] Updated `GuestDetailEventAttendance.swift`:
  - Added Welcome Dinner (rehearsal) attendance display
  - Added conditional visibility (grayed out when not attending)
  - Shows disabled state with explanatory message for non-attending guests
- [x] Created `GuestDetailWeddingPartySection.swift`:
  - Shows wedding party role
  - Hair/makeup status with checkmarks
  - Preparation notes
  - Only displayed for `isWeddingParty = true`
- [x] Created `GuestDetailAccessibilitySection.swift`:
  - Displays accessibility needs with info styling
- [x] Updated `GuestDetailAdditionalDetails.swift`:
  - Added RSVP date display
  - Added table/seat assignment
  - Added plus one attending status
  - Added gift received indicator

#### Phase 4: Main Detail View
- [x] Updated `GuestDetailViewV4.swift`:
  - Added computed properties for section visibility
  - Integrated all new sections
  - Proper conditional rendering based on guest data

#### Phase 5: Supporting Files
- [x] Updated `AddGuestView.swift` - added `attendingRehearsal` field
- [x] Updated `EditGuestSheetV2.swift` preview - added `attendingRehearsal`
- [x] Updated `GuestConversionService.swift` - CSV import support
- [x] Updated `GuestExportView.swift` preview
- [x] Updated `GuestManagementViewV4.swift` preview
- [x] Updated `SupabaseDataModels.swift` - GuestDTO conversion
- [x] Updated `LiveGuestRepository.swift` - importGuests function
- [x] Updated `ModelBuilders.swift` - test helper

### Build Status
- ✅ **BUILD SUCCEEDED** - All compilation errors resolved
- ✅ **Code committed and pushed** - Commit 893a2d1

### Remaining Work

#### Phase 6: Edit Guest Sheet Enhancement (Next)
- [ ] Add tabbed interface to `EditGuestSheetV2.swift`
- [ ] Add Event Attendance tab (conditional on RSVP status)
- [ ] Add Wedding Party tab (conditional on `isWeddingParty`)
- [ ] Add all missing editable fields:
  - Event attendance (ceremony, reception, rehearsal)
  - Accessibility needs
  - Table/seat assignment
  - Preferred contact method
  - Full address fields
  - Invitation number
  - Wedding party role
  - Hair/makeup done
  - Preparation notes
  - RSVP date
  - Gift received

#### Phase 7: Add Guest View Enhancement
- [ ] Mirror edit sheet structure
- [ ] Add conditional sections


### Completed ✅

#### Phase 1: Database Migration
- [x] Added `attending_rehearsal` column to `guest_list` table
- [x] Set default value to `true`
- [x] Updated existing guests: `attending_rehearsal = attending_ceremony`

#### Phase 2: Model Updates
- [x] Added `attendingRehearsal: Bool` property to `Guest.swift`
- [x] Added `attendingRehearsal` CodingKey mapping
- [x] Added `isAttending` computed property for convenience

#### Phase 3: Detail View Components
- [x] Updated `GuestDetailEventAttendance.swift`:
  - Added Welcome Dinner (rehearsal) attendance display
  - Added conditional visibility (grayed out when not attending)
  - Shows disabled state with explanatory message for non-attending guests
- [x] Created `GuestDetailWeddingPartySection.swift`:
  - Shows wedding party role
  - Hair/makeup status with checkmarks
  - Preparation notes
  - Only displayed for `isWeddingParty = true`
- [x] Created `GuestDetailAccessibilitySection.swift`:
  - Displays accessibility needs with info styling
- [x] Updated `GuestDetailAdditionalDetails.swift`:
  - Added RSVP date display
  - Added table/seat assignment
  - Added plus one attending status
  - Added gift received indicator

#### Phase 4: Main Detail View
- [x] Updated `GuestDetailViewV4.swift`:
  - Added computed properties for section visibility
  - Integrated all new sections
  - Proper conditional rendering based on guest data

#### Phase 5: Supporting Files
- [x] Updated `AddGuestView.swift` - added `attendingRehearsal` field
- [x] Updated `EditGuestSheetV2.swift` preview - added `attendingRehearsal`
- [x] Updated `GuestConversionService.swift` - CSV import support
- [x] Updated `GuestExportView.swift` preview
- [x] Updated `GuestManagementViewV4.swift` preview
- [x] Updated `SupabaseDataModels.swift` - GuestDTO conversion
- [x] Updated `LiveGuestRepository.swift` - importGuests function
- [x] Updated `ModelBuilders.swift` - test helper

### Build Status
- ✅ **BUILD SUCCEEDED** - All compilation errors resolved

### Remaining Work

#### Phase 6: Edit Guest Sheet Enhancement (Next)
- [ ] Add tabbed interface to `EditGuestSheetV2.swift`
- [ ] Add Event Attendance tab (conditional on RSVP status)
- [ ] Add Wedding Party tab (conditional on `isWeddingParty`)
- [ ] Add all missing editable fields:
  - Event attendance (ceremony, reception, rehearsal)
  - Accessibility needs
  - Table/seat assignment
  - Preferred contact method
  - Full address fields
  - Invitation number
  - Wedding party role
  - Hair/makeup done
  - Preparation notes
  - RSVP date
  - Gift received

#### Phase 7: Add Guest View Enhancement
- [ ] Mirror edit sheet structure
- [ ] Add conditional sections



## Dynamic Event Attendance Implementation (2025-01-01)

### Overview
Implemented dynamic event attendance display based on events created in the database. The event attendance section now only shows events that actually exist for the couple, rather than hardcoded ceremony/reception/rehearsal options.

### Changes Made

#### 1. GuestDetailEventAttendance.swift
- **Added `weddingEvents` parameter** - Component now accepts wedding events from the database
- **Dynamic event filtering** - Only shows attendable events (rehearsal, ceremony, reception types)
- **Excludes "other" type events** - Events like "Pre-Wedding Expenses" are filtered out
- **Smart sorting** - Events sorted by date, then by event order
- **Display name logic** - Uses event name from database, falls back to formatted type
- **Attendance status mapping** - Maps event types to guest attendance properties:
  - `rehearsal` → `guest.attendingRehearsal`
  - `ceremony` → `guest.attendingCeremony`
  - `reception` → `guest.attendingReception`
- **Empty state handling** - Shows "No events have been set up yet" when no events exist

#### 2. GuestDetailViewV4.swift
- **Added BudgetStoreV2 dependency** - `@EnvironmentObject private var budgetStore: BudgetStoreV2`
- **Passes wedding events to component** - `GuestDetailEventAttendance(guest: guest, weddingEvents: budgetStore.weddingEvents)`
- **Updated previews** - Added `BudgetStoreV2()` to environment objects

### How It Works
1. Wedding events are fetched from the `wedding_events` table via `BudgetStoreV2.weddingEvents`
2. The `GuestDetailEventAttendance` component filters to only show attendable event types
3. Events are displayed dynamically based on what exists in the database
4. If a couple only has a ceremony event, only ceremony attendance is shown
5. If they have rehearsal + ceremony + reception, all three are shown

### Database Event Types
The system recognizes these event types for attendance:
- `rehearsal` - Welcome Dinner / Rehearsal events
- `ceremony` - Wedding Ceremony
- `reception` - Wedding Reception
- `other` - Excluded from attendance display (e.g., "Pre-Wedding Expenses")

### Build Status
- ✅ **BUILD SUCCEEDED** - All compilation errors resolved

### Related Files
- `I Do Blueprint/Views/Guests/Components/GuestDetailEventAttendance.swift`
- `I Do Blueprint/Views/Guests/GuestDetailViewV4.swift`
- `I Do Blueprint/Domain/Models/Shared/Wedding.swift` (WeddingEvent model)
- `I Do Blueprint/Services/Stores/BudgetStoreV2.swift` (weddingEvents property)
