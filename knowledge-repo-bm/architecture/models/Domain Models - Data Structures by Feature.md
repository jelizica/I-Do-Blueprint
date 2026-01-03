---
title: Domain Models - Data Structures by Feature
type: note
permalink: architecture/models/domain-models-data-structures-by-feature
tags:
- architecture
- models
- domain
- codable
- sendable
---

# Domain Models - Data Structures by Feature

## Overview

Domain models in I Do Blueprint are organized by feature domain in `Domain/Models/`. All models conform to `Codable` for Supabase serialization and many conform to `Sendable` for Swift concurrency.

## Model Organization

```
Domain/Models/
├── Budget/         # Budget and financial models (25+ files)
├── Guest/          # Guest management models
├── Vendor/         # Vendor directory models
├── Task/           # Task and checklist models
├── Timeline/       # Timeline and milestone models
├── Document/       # Document management models
├── Notes/          # Notes and reminders models
├── VisualPlanning/ # Mood boards, palettes, seating
├── Collaboration/  # Multi-user collaboration models
├── Settings/       # Application settings models
├── Onboarding/     # Onboarding flow models
├── Dashboard/      # Dashboard widgets models
└── Shared/         # Common models and enums
```

## Model Patterns

### 1. Codable for Database Mapping

All models conform to `Codable` for Supabase:
```swift
struct Guest: Codable, Identifiable {
    let id: UUID
    let coupleId: UUID
    let fullName: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case fullName = "full_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
```

### 2. Sendable for Concurrency

Models crossing actor boundaries conform to `Sendable`:
```swift
struct Guest: Codable, Sendable, Identifiable { }
```

### 3. Test Data Builders

Models have `.makeTest()` factory methods:
```swift
extension Guest {
    static func makeTest(
        id: UUID = UUID(),
        fullName: String = "Test Guest",
        rsvpStatus: RSVPStatus = .pending
    ) -> Guest {
        Guest(id: id, fullName: fullName, rsvpStatus: rsvpStatus)
    }
}
```

Location: `I Do BlueprintTests/Helpers/ModelBuilders.swift`

### 4. Error Types

Each domain has an error enum:
```swift
enum GuestError: Error, LocalizedError {
    case invalidData
    case duplicateGuest
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidData: return "Invalid guest data"
        case .duplicateGuest: return "Guest already exists"
        case .networkError: return "Network error"
        }
    }
}
```

## Major Domain Models

### Budget Domain (25+ Files)

**Core Models:**
- `Budget` - Overall budget structure
- `BudgetCategory` - Category definitions with benchmarks
- `BudgetItem` / `BudgetDevelopmentItem` - Line items in scenarios
- `Expense` - Actual expense tracking
- `ExpenseAllocation` - Expense-to-budget-item mapping
- `PaymentSchedule` - Payment plans and schedules
- `GiftOrOwed` - Gift tracking and money owed

**Aggregation Models:**
- `BudgetOverviewItem` - Budget overview with spent/budgeted
- `BudgetSummary` - Summary statistics
- `BudgetStats` - Analytics and trends
- `PaymentPlanSummary` - Payment plan overview
- `FolderTotals` - Cached folder calculations

**Scenario Models:**
- `BudgetDevelopmentScenario` - Scenario definitions
- `SavedScenario` - Saved scenario snapshots
- `AffordabilityScenario` - Affordability calculator scenarios

**Supporting Models:**
- `TaxInfo` - Tax rate information
- `CategoryBenchmark` - Industry benchmark data
- `BudgetFilter` - Filtering options
- `PaymentPlanGroup` - Payment grouping
- `BudgetEnums` - Enums (PaymentType, Frequency, etc.)

### Guest Domain

**Core Models:**
- `Guest` - Guest information with RSVP
- `GuestStats` - Guest list statistics

**Enums:**
- `RSVPStatus` - Pending, Accepted, Declined
- `MealPreference` - Meal selection options
- `GuestRelationship` - Relationship to couple

**Features:**
- Invitation number tracking
- Meal preference tracking
- Dietary restrictions
- +1 guest support
- Wedding party identification

### Vendor Domain

**Core Models:**
- `Vendor` - Vendor information
- `VendorReview` - Vendor ratings and reviews
- `VendorContract` - Contract tracking
- `VendorPaymentSummary` - Payment overview
- `VendorStats` - Vendor statistics

**Supporting Models:**
- `VendorType` - Vendor category enum
- `VendorDetailTab` - UI tab enum
- `VendorError` - Error handling

**Features:**
- Budget category association
- Multi-contact support
- Payment tracking
- Review system
- Archive functionality

### Task Domain

**Core Models:**
- `WeddingTask` - Task definition
- `TaskStats` - Task statistics

**Enums:**
- `TaskStatus` - NotStarted, InProgress, Completed
- `WeddingTaskPriority` - Low, Medium, High, Critical
- `TaskSortOption` - Sort ordering options

**Features:**
- Subtask support
- Due date tracking
- Priority levels
- Assignment tracking
- Status filtering

### Timeline Domain

**Core Models:**
- `TimelineItem` - Timeline event
- `Milestone` - Major milestone
- `WeddingEvent` - Event definitions (ceremony, reception, etc.)

**Features:**
- Event categorization
- Date tracking
- Milestone tracking
- Timeline visualization

### Document Domain

**Core Models:**
- `Document` - Document metadata
- `DocumentType` - Document category enum
- `DocumentBucket` - Storage bucket enum

**Features:**
- Multi-bucket support (invoices, general, etc.)
- Vendor association
- File type tracking
- Relationship management

### Visual Planning Domain

**Core Models:**
- `MoodBoard` - Mood board collection
- `ColorPalette` - Color scheme
- `SeatingChart` - Seating arrangement
- `GuestGroup` - Guest grouping
- `VisualElement` - Generic visual elements

**Features:**
- Image management
- Color palette tools
- Seating assignments
- Table planning

### Collaboration Domain

**Core Models:**
- `Collaborator` - Collaborator information
- `CollaborationRole` - Role definitions
- `Invitation` - Invitation data
- `UserCollaboration` - User's collaboration memberships
- `ActivityEvent` - Activity feed events
- `Presence` - Real-time presence tracking

**Role Types:**
- Owner - Full access
- Editor - Edit permissions
- Viewer - Read-only

**Features:**
- Role-based access control
- Invitation system
- Activity logging
- Real-time presence

### Settings Domain

**Core Models:**
- `SettingsModel` - Application settings
- `StylePreferences` - UI preferences

**Features:**
- Partner name tracking
- Wedding date
- Timezone preferences
- Onboarding progress
- Hidden categories

### Shared Domain

**Core Models:**
- `Wedding` - Wedding information
- `CoupleMembership` - Couple-user association
- `RecentCouple` - Recent couple tracking
- `UserFacingError` - User-friendly error messages
- `PaginatedResult<T>` - Pagination support
- `LoadingState<T>` - Async loading state enum

**Shared Enums:**
- `SortOrder` - Ascending, Descending
- `FilterOption` - Common filtering options

## Common Model Features

### 1. Identifiable Conformance

Most models conform to `Identifiable`:
```swift
struct Guest: Identifiable {
    let id: UUID
}
```

### 2. Computed Properties

Models include computed properties for UI:
```swift
extension Guest {
    var displayName: String {
        fullName.isEmpty ? "Unnamed Guest" : fullName
    }
    
    var isConfirmed: Bool {
        rsvpStatus == .accepted
    }
}
```

### 3. Validation Logic

Models include validation:
```swift
extension Guest {
    func validate() throws {
        guard !fullName.isEmpty else {
            throw GuestError.invalidData
        }
    }
}
```

### 4. Date Handling

All dates use `Date` type (never strings):
```swift
let createdAt: Date // ✅ Correct
let createdAtString: String // ❌ Wrong
```

Use `DateFormatting` utility for timezone-aware display:
```swift
let display = DateFormatting.formatDateMedium(date, timezone: userTimezone)
```

### 5. Optional vs Non-Optional

**Non-optional when:**
- Required by database schema
- Always has a value
- Part of core identity

**Optional when:**
- User input may be missing
- Feature is optional
- Nullable in database

## Model Extensions

**File Pattern:** `{Model}+{Purpose}.swift`

Examples:
- `Vendor+Extensions.swift` - Additional vendor methods
- `PaymentSchedule+Migration.swift` - Migration helpers
- `Guest+TestHelpers.swift` - Test utilities (in test target)

## Loading State Pattern

Used throughout the app for async data:

```swift
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
    
    var value: T? {
        if case .loaded(let data) = self {
            return data
        }
        return nil
    }
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
}
```

## Statistics Models Pattern

Stats models for analytics:

```swift
struct GuestStats: Codable {
    let totalGuests: Int
    let confirmedGuests: Int
    let declinedGuests: Int
    let pendingGuests: Int
    let totalExpectedGuests: Int // Including +1s
}

struct VendorStats: Codable {
    let totalVendors: Int
    let bookedVendors: Int
    let paidVendors: Int
}

struct TaskStats: Codable {
    let totalTasks: Int
    let completedTasks: Int
    let overdueTasks: Int
}
```

## Budget Model Complexity

Budget domain is the most complex with:
- **25+ model files**
- Scenario-based budgeting
- Expense allocation system
- Payment plan tracking
- Gift and contribution tracking
- Folder hierarchy support
- Tax calculation
- Industry benchmarks

Key relationships:
- BudgetCategory → BudgetItem (1:many)
- BudgetItem → ExpenseAllocation (1:many)
- Expense → ExpenseAllocation (1:many)
- BudgetItem → Gift (1:1 optional)
- Scenario → BudgetItem (1:many)
- Folder → BudgetItem (1:many hierarchical)

## Testing Support

All models support testing:
- `.makeTest()` factory methods
- Mock data generation
- Test builders with defaults
- Easy property customization

Example:
```swift
let guest = Guest.makeTest(
    fullName: "John Doe",
    rsvpStatus: .accepted
)

let vendor = Vendor.makeTest(
    vendorName: "Acme Catering",
    isBooked: true
)
```

## References
- File: `I Do BlueprintTests/Helpers/ModelBuilders.swift` - Test factories
- File: `Utilities/DateFormatting.swift` - Date utilities
- File: `Core/Common/Errors/AppError.swift` - Error handling
- Related: Store Layer Architecture (uses models)
- Related: Repository Layer (fetches/saves models)