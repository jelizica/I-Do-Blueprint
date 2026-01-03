---
title: TimelineAPI Service Decomposition
type: note
permalink: architecture/services/timeline-api-service-decomposition
tags:
- architecture
- services
- refactoring
- timeline
- decomposition
- single-responsibility
---

# TimelineAPI Service Decomposition

## Overview
Successfully decomposed TimelineAPI.swift (667 lines) into focused, single-responsibility services following the established Domain Services pattern.

## Problem
TimelineAPI.swift had grown to 667 lines with multiple responsibilities:
- Fetching timeline data from multiple sources (payments, vendors, guests, expenses)
- Transforming database rows into TimelineItem models
- Date parsing in multiple formats
- Timeline item CRUD operations
- Milestone CRUD operations

This violated the single responsibility principle and made the file difficult to maintain and test.

## Solution
Split into 4 focused service files plus refactored coordinator:

### 1. TimelineDateParser.swift
**Purpose**: Centralized date parsing utilities

**Functions**:
- `dateFromString(_:)` - Parse yyyy-MM-dd format
- `iso8601DateFromString(_:)` - Parse ISO8601 with fallbacks
- `stringFromDate(_:)` - Format date to yyyy-MM-dd

**Benefits**:
- Single source of truth for date parsing
- Handles multiple date formats (ISO8601, Postgres timestamps)
- Reusable across timeline services

### 2. TimelineDataTransformer.swift
**Purpose**: Transform database rows into TimelineItem models

**Transformers**:
- `transformPayments(_:)` - Payment rows → TimelineItems
- `transformExpenses(_:)` - Expense rows → TimelineItems
- `transformVendors(_:)` - Vendor rows → TimelineItems
- `transformGuests(_:)` - Guest rows → TimelineItems

**Row Types**:
- `PaymentRow` - Codable struct for payment_plans table
- `ExpenseRow` - Codable struct for expenses table
- `VendorRow` - Codable struct for vendor_information table
- `GuestRow` - Codable struct for guest_list table

**Benefits**:
- Clear separation of data transformation logic
- Easy to test transformations in isolation
- Consistent transformation patterns
- Logging at transformation level

### 3. TimelineItemService.swift
**Purpose**: CRUD operations for timeline items

**Operations**:
- `fetchTimelineItemById(_:)` - Fetch single item
- `createTimelineItem(_:)` - Create new item
- `updateTimelineItem(_:data:)` - Update existing item
- `updateTimelineItemCompletion(_:completed:)` - Update completion status
- `deleteTimelineItem(_:)` - Delete item

**Benefits**:
- Focused on timeline item operations
- Uses TimelineDateParser for date formatting
- Clear error handling
- Consistent API patterns

### 4. MilestoneService.swift
**Purpose**: CRUD operations for milestones

**Operations**:
- `fetchMilestones()` - Fetch all milestones
- `fetchMilestoneById(_:)` - Fetch single milestone
- `createMilestone(_:)` - Create new milestone
- `updateMilestone(_:data:)` - Update existing milestone
- `updateMilestoneCompletion(_:completed:)` - Update completion status
- `deleteMilestone(_:)` - Delete milestone

**Benefits**:
- Separate from timeline items
- Uses TimelineDateParser for date formatting
- Ordered by milestone_date
- Clear error handling

### 5. TimelineAPI.swift (Refactored)
**Purpose**: Coordinator for timeline data aggregation

**Responsibilities**:
- Fetch timeline items from multiple sources in parallel
- Aggregate and sort combined results
- Delegate CRUD operations to specialized services
- Performance logging

**Pattern**: Coordinator + Delegation

```swift
class TimelineAPI {
    private let timelineItemService: TimelineItemService
    private let milestoneService: MilestoneService
    
    // Aggregation logic
    func fetchTimelineItems() async throws -> [TimelineItem] {
        async let payments = fetchPaymentTimelineItems()
        async let vendors = fetchVendorTimelineItems()
        async let guests = fetchGuestTimelineItems()
        
        let (p, v, g) = try await (payments, vendors, guests)
        return (p + v + g).sorted { $0.itemDate < $1.itemDate }
    }
    
    // Delegation to services
    func createTimelineItem(_ data: TimelineItemInsertData) async throws -> TimelineItem {
        try await timelineItemService.createTimelineItem(data)
    }
}
```

## Architecture Pattern

```
TimelineAPI (Coordinator)
├── TimelineItemService (CRUD)
│   └── TimelineDateParser (Utilities)
├── MilestoneService (CRUD)
│   └── TimelineDateParser (Utilities)
└── TimelineDataTransformer (Transformations)
    └── TimelineDateParser (Utilities)
```

## Benefits

### 1. Single Responsibility
Each service has one clear purpose:
- TimelineDateParser: Date parsing
- TimelineDataTransformer: Row-to-model conversion
- TimelineItemService: Timeline item CRUD
- MilestoneService: Milestone CRUD
- TimelineAPI: Coordination and aggregation

### 2. Easier Testing
- Test date parsing in isolation
- Test transformations with mock data
- Test CRUD operations independently
- Mock services for coordinator tests

### 3. Better Code Organization
- Related functionality grouped together
- Clear file structure in Timeline/ directory
- Easy to find specific functionality
- Reduced cognitive load

### 4. Maintainability
- Smaller files are easier to understand
- Changes to one area don't affect others
- Clear boundaries between services
- Reusable utilities

### 5. Performance
- Parallel fetching maintained
- Performance logging at coordinator level
- Individual service timing available

## Usage Examples

### Direct Service Access
```swift
// Use specialized services directly
let parser = TimelineDateParser.self
let date = parser.dateFromString("2025-12-31")

let transformer = TimelineDataTransformer.self
let items = transformer.transformPayments(paymentRows)

let service = TimelineItemService()
let item = try await service.fetchTimelineItemById(id)
```

### Through Coordinator
```swift
// Use coordinator for aggregated data
let api = TimelineAPI()
let allItems = try await api.fetchTimelineItems()

// Delegate CRUD operations
let newItem = try await api.createTimelineItem(data)
try await api.updateTimelineItemCompletion(id, completed: true)
```

## Migration Path

### Phase 1: Completed ✅
- Split services
- Maintain backward compatibility
- Create Timeline/ directory structure

### Phase 2: Future
- Add unit tests for each service
- Consider caching strategies
- Optimize parallel fetching

### Phase 3: Future
- Add integration tests
- Performance benchmarking
- Consider repository pattern migration

## File Structure

```
Services/API/Timeline/
├── TimelineDateParser.swift
├── TimelineDataTransformer.swift
├── TimelineItemService.swift
└── MilestoneService.swift

Services/API/
└── TimelineAPI.swift (coordinator)
```

## Related Work
- Beads Issue: I Do Blueprint-0vc
- Epic: I Do Blueprint-0t9 (Large Service Files Decomposition)
- Pattern: Domain Services Architecture
- Previous: AlertPresenter Service Decomposition

## Lessons Learned

### 1. Parallel Fetching Preserved
The coordinator pattern allows us to maintain parallel fetching while keeping transformation logic separate.

### 2. Date Parsing Centralization
Creating a dedicated date parser eliminates duplication and provides a single source of truth for date handling.

### 3. Row Types as Nested Structs
Keeping row types in the transformer makes it clear they're only used for transformation.

### 4. Service Delegation
The coordinator delegates CRUD operations rather than duplicating code, maintaining DRY principles.

## Next Steps
1. Apply same pattern to DocumentsAPI.swift (747 lines)
2. Apply same pattern to VisualPlanningSearchService.swift (604 lines)
3. Add unit tests for timeline services
4. Document service decomposition pattern in best practices

## Files Modified
- Created: 4 new service files in Timeline/ directory
- Refactored: TimelineAPI.swift
- Reduced: From 667 to ~200 lines

## Build Status
✅ Xcode project builds successfully
✅ All existing functionality preserved
✅ Backward compatibility maintained
