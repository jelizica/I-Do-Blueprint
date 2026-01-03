---
title: I Do Blueprint - Quick Reference Guide
type: note
permalink: quick-reference/i-do-blueprint-quick-reference-guide
tags:
- quick-reference
- cheat-sheet
- overview
- best-practices
---

# I Do Blueprint - Quick Reference Guide

## Project Identity

**Name:** I Do Blueprint  
**Type:** macOS Wedding Planning Application  
**Platform:** macOS 13.0+  
**Language:** Swift 5.9+ with strict concurrency  
**Backend:** Supabase (PostgreSQL with RLS)  
**Architecture:** MVVM + Repository + Domain Services

## Critical Don'ts (Common Pitfalls)

### ❌ Store Access - NEVER Create Instances
```swift
// ❌ WRONG - Creates duplicate instances
@StateObject private var store = BudgetStoreV2()

// ✅ CORRECT - Use environment
@Environment(\.budgetStore) private var store
// OR
@Environment(\.appStores) private var appStores
```

### ❌ UUID Handling - NEVER Convert to String for Queries
```swift
// ❌ WRONG - Causes case mismatch bugs
.eq("couple_id", value: tenantId.uuidString)

// ✅ CORRECT - Pass UUID directly
.eq("couple_id", value: tenantId)
```

### ❌ Budget Sub-Stores - NEVER Create Delegation Methods
```swift
// ❌ WRONG - Unnecessary indirection
await budgetStore.addCategory(category)

// ✅ CORRECT - Access sub-store directly
await budgetStore.categoryStore.addCategory(category)
```

### ❌ Date Display - NEVER Use TimeZone.current
```swift
// ❌ WRONG - Ignores user preference
let display = date.formatted(.dateTime.timeZone(.current))

// ✅ CORRECT - Use user's configured timezone
let userTz = DateFormatting.userTimeZone(from: settings)
let display = DateFormatting.formatDateMedium(date, timezone: userTz)
```

### ❌ Data Access - NEVER Skip Repository Layer
```swift
// ❌ WRONG - Direct Supabase access from store
let guests = try await supabase.from("guest_list").select()

// ✅ CORRECT - Use repository
let guests = try await repository.fetchGuests()
```

## Architecture Quick Reference

### Data Flow
```
View → Store → Repository → Domain Service (optional) → Supabase
  ↑      ↑         ↑              ↑
  |      |         |              |
 SwiftUI |      Cache          Business
@Published     Actor           Logic
```

### File Organization
```
I Do Blueprint/
├── App/                    # Entry point
├── Core/                   # Common infrastructure
├── Design/                 # Design system
├── Domain/
│   ├── Models/             # Data structures
│   ├── Repositories/       # Data access
│   │   ├── Protocols/
│   │   ├── Live/
│   │   ├── Mock/
│   │   └── Caching/
│   └── Services/           # Business logic
├── Services/
│   ├── Stores/             # State management
│   └── API/                # API clients
├── Utilities/              # Helpers
└── Views/                  # UI
```

## Key Patterns

### Store Pattern
```swift
@MainActor
class FeatureStoreV2: ObservableObject, CacheableStore {
    @Published var loadingState: LoadingState<Data> = .idle
    @Dependency(\.repository) var repository
    
    func load() async {
        loadingState = .loading
        do {
            let data = try await repository.fetch()
            loadingState = .loaded(data)
        } catch {
            await handleError(error, operation: "load") {
                await self.load()
            }
        }
    }
}
```

### Repository Pattern
```swift
class LiveRepository: RepositoryProtocol {
    private let cacheStrategy = CacheStrategy()
    
    func fetch() async throws -> [Data] {
        // 1. Check cache
        if let cached = await cache.get(key, maxAge: 60) {
            return cached
        }
        
        // 2. Fetch with retry
        let data = try await NetworkRetry.withRetry {
            try await supabase.database
                .from("table")
                .select()
                .eq("couple_id", value: tenantId) // ✅ UUID
                .execute()
                .value
        }
        
        // 3. Cache and return
        await cache.set(key, value: data, ttl: 60)
        return data
    }
    
    func create(_ item: Data) async throws -> Data {
        let created = try await createInDB(item)
        await cacheStrategy.invalidate(for: .itemCreated(tenantId))
        return created
    }
}
```

### Domain Service Pattern
```swift
actor ServiceName {
    private let repository: RepositoryProtocol
    
    func complexOperation() async throws -> Result {
        let start = Date()
        
        // Parallel fetching
        async let data1 = repository.fetch1()
        async let data2 = repository.fetch2()
        
        let result = try await processData(data1, data2)
        
        // Performance tracking
        await PerformanceMonitor.shared.recordOperation(
            "operation",
            duration: Date().timeIntervalSince(start)
        )
        
        return result
    }
}
```

## All V2 Stores

1. **BudgetStoreV2** (composition: 6 sub-stores)
   - affordability, payments, gifts
   - categoryStore, expenseStore, development
2. **GuestStoreV2** - Guest list management
3. **VendorStoreV2** - Vendor directory
4. **TaskStoreV2** - Task management
5. **DocumentStoreV2** (composition: 3 sub-stores)
   - upload, filter, batch
6. **CollaborationStoreV2** - Multi-user collaboration
7. **NotesStoreV2** - Notes and reminders
8. **OnboardingStoreV2** - Onboarding flow
9. **VisualPlanningStoreV2** - Mood boards, palettes, seating
10. **TimelineStoreV2** - Timeline and milestones
11. **SettingsStoreV2** - Application settings

## All Repository Protocols

1. BudgetRepositoryProtocol
2. VendorRepositoryProtocol
3. GuestRepositoryProtocol
4. TaskRepositoryProtocol
5. DocumentRepositoryProtocol
6. NotesRepositoryProtocol
7. CollaborationRepositoryProtocol
8. ActivityFeedRepositoryProtocol
9. PresenceRepositoryProtocol
10. TimelineRepositoryProtocol
11. OnboardingRepositoryProtocol

## All Domain Services

1. **BudgetAggregationService** - Overview aggregation
2. **BudgetAllocationService** - Expense allocation
3. **BudgetDevelopmentService** - Scenario management
4. **ExpensePaymentStatusService** - Payment status
5. **CollaborationPermissionService** - Permission checks
6. **CollaborationInvitationService** - Invitation workflow

## Cache TTLs

| Resource | TTL | Update Frequency |
|----------|-----|------------------|
| Guests | 60s | Moderate |
| Vendors | 600s | Slow |
| Tasks | 60s | Frequent |
| Categories | 300s | Infrequent |
| Documents | 120s | Moderate |
| Stats | 60s | Need fresh data |

## Database Tables (Key Tables)

### User & Couple
- couple_profiles
- couple_settings
- tenant_memberships
- collaborators
- collaboration_roles

### Core Features
- guest_list (18 fields)
- vendor_information
- budget_categories
- budget_development_items
- expenses
- expense_budget_allocations
- tasks
- timeline
- documents
- mood_boards
- color_palettes
- seating_charts

### Supporting
- activity_events
- collaborator_presence
- payment_plans
- gifts_and_owed
- monthly_cash_flow

## RLS Pattern (All Tables)

```sql
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couples manage their data"
    ON table_name
    FOR ALL
    USING (couple_id = get_user_couple_id())
    WITH CHECK (couple_id = get_user_couple_id());
```

## Testing Pattern

```swift
@MainActor
final class StoreTests: XCTestCase {
    var mockRepo: MockRepository!
    var store: StoreV2!
    
    override func setUp() async throws {
        mockRepo = MockRepository()
        store = await withDependencies {
            $0.repository = mockRepo
        } operation: {
            StoreV2()
        }
    }
    
    func test_operation_success() async {
        // Given
        mockRepo.data = [.makeTest()]
        
        // When
        await store.load()
        
        // Then
        XCTAssertEqual(store.items.count, 1)
    }
}
```

## Build Commands

```bash
# Build
xcodebuild build -project "I Do Blueprint.xcodeproj" \
    -scheme "I Do Blueprint" -destination 'platform=macOS'

# Test
xcodebuild test -project "I Do Blueprint.xcodeproj" \
    -scheme "I Do Blueprint" -destination 'platform=macOS'

# Specific test
xcodebuild test -project "I Do Blueprint.xcodeproj" \
    -scheme "I Do Blueprint" -destination 'platform=macOS' \
    -only-testing:"I Do BlueprintTests/BudgetStoreV2Tests/test_method"
```

## Active Issues (from beads)

**In Progress:**
- I Do Blueprint-aip - Complete error handling (CLOSED - recently completed)
- I Do Blueprint-0wo - Reduce MockBudgetRepository size

**Open (High Priority):**
- I Do Blueprint-0t9 - Large service files decomposition (EPIC)
- I Do Blueprint-s2q - Add API layer integration tests
- I Do Blueprint-bji - Add domain service unit tests
- I Do Blueprint-09l - Cache strategy consolidation

**Ready to Work:** 9 issues

## Recent Major Work (Last 30 Days)

1. ✅ Error handling standardization (all stores)
2. ✅ View complexity reduction (epic completed)
3. ✅ Payment plan enhancements
4. ✅ Budget folder support
5. ✅ Activity logging fixes

## Security Checklist

✅ RLS enabled on all tables  
✅ All queries filter by couple_id  
✅ Use (SELECT auth.uid()) not auth.uid()  
✅ UUIDs passed directly to queries  
✅ Anon key only in client (never service_role)  
✅ Helper functions for authorization  
✅ Admin actions audited  
✅ Real-time respects RLS

## Performance Patterns

1. **Parallel Loading**
   ```swift
   async let data1 = fetch1()
   async let data2 = fetch2()
   let result = (try await data1, try await data2)
   ```

2. **N+1 Prevention**
   ```swift
   // ✅ Bulk fetch
   let allocs = try await repo.fetchAllocationsForScenario(id)
   let byItem = Dictionary(grouping: allocs, by: \.budgetItemId)
   ```

3. **Cache First**
   ```swift
   if let cached = await cache.get(key, maxAge: 60) {
       return cached
   }
   ```

4. **Network Retry**
   ```swift
   return try await NetworkRetry.withRetry {
       try await supabase.fetch()
   }
   ```

## Error Handling

```swift
do {
    let data = try await repository.fetch()
    // Success
} catch {
    await handleError(error, operation: "fetch", context: [
        "key": "value"
    ]) { [weak self] in
        await self?.fetch() // Retry
    }
}
```

## Date Formatting

```swift
// Get user timezone
let userTz = DateFormatting.userTimeZone(from: settings)

// Display
let display = DateFormatting.formatDateMedium(date, timezone: userTz)
let relative = DateFormatting.formatRelativeDate(date, timezone: userTz)

// Database (always UTC)
let dbDate = DateFormatting.formatForDatabase(date)
let parsed = DateFormatting.parseDateFromDatabase(string)

// Calculations
let days = DateFormatting.daysBetween(from: date1, to: date2, in: userTz)
```

## References in Basic Memory

All documentation stored in `i-do-blueprint` project:
- `projects/i-do-blueprint/` - Project overview
- `architecture/stores/` - Store layer docs
- `architecture/repositories/` - Repository layer docs
- `architecture/services/` - Domain services docs
- `architecture/models/` - Domain models docs
- `architecture/caching/` - Caching infrastructure docs
- `database/` - Database schema docs
- `security/` - Security and RLS docs
- `testing/` - Testing infrastructure docs