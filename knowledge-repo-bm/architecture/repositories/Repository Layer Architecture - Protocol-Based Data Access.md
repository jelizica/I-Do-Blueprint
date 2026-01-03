---
title: Repository Layer Architecture - Protocol-Based Data Access
type: note
permalink: architecture/repositories/repository-layer-architecture-protocol-based-data-access
tags:
- architecture
- repositories
- data-access
- caching
- supabase
---

# Repository Layer Architecture - Protocol-Based Data Access

## Overview

All data access in I Do Blueprint goes through repository protocols for testability and dependency injection. Repositories abstract away Supabase implementation details and provide a clean interface for stores.

## Repository Pattern Structure

```
Domain/Repositories/
├── Protocols/          # Repository interfaces
├── Live/              # Supabase implementations with caching
├── Mock/              # Test implementations
└── Caching/           # Cache strategies per domain
```

## All Repository Protocols

1. **BudgetRepositoryProtocol** - Budget, categories, expenses, allocations, scenarios
2. **VendorRepositoryProtocol** - Vendor directory, reviews, payments, imports
3. **GuestRepositoryProtocol** - Guest list, RSVPs, meal preferences, seating
4. **TaskRepositoryProtocol** - Tasks, subtasks, assignments
5. **DocumentRepositoryProtocol** - Documents, invoices, file uploads
6. **NotesRepositoryProtocol** - Notes and reminders
7. **CollaborationRepositoryProtocol** - Collaborators, roles, invitations
8. **ActivityFeedRepositoryProtocol** - Activity tracking and statistics
9. **PresenceRepositoryProtocol** - Real-time presence tracking
10. **TimelineRepositoryProtocol** - Timeline and milestones
11. **OnboardingRepositoryProtocol** - Onboarding flow state

## Repository Protocol Pattern

All repositories follow this pattern:

```swift
protocol {Feature}RepositoryProtocol: Sendable {
    // MARK: - Fetch Operations
    func fetch{Entities}() async throws -> [Entity]
    func fetch{Entity}(id: UUID) async throws -> Entity?
    
    // MARK: - Create, Update, Delete
    func create{Entity}(_ entity: Entity) async throws -> Entity
    func update{Entity}(_ entity: Entity) async throws -> Entity
    func delete{Entity}(id: UUID) async throws
    
    // MARK: - Statistics (if applicable)
    func fetch{Entity}Stats() async throws -> EntityStats
}
```

## Live Repository Pattern

Live implementations in `Domain/Repositories/Live/` follow this structure:

```swift
class Live{Feature}Repository: {Feature}RepositoryProtocol {
    private let supabase: SupabaseClient
    private let logger = AppLogger.database
    private let cacheStrategy = {Feature}CacheStrategy()
    
    func fetchEntities() async throws -> [Entity] {
        // 1. Check cache first
        let cacheKey = "entities_\(tenantId.uuidString)"
        if let cached: [Entity] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }
        
        // 2. Fetch from Supabase with retry
        let entities: [Entity] = try await NetworkRetry.withRetry {
            try await supabase.database
                .from("table_name")
                .select()
                .eq("couple_id", value: tenantId) // ✅ UUID directly
                .execute()
                .value
        }
        
        // 3. Cache and return
        await RepositoryCache.shared.set(cacheKey, value: entities, ttl: 60)
        return entities
    }
    
    func createEntity(_ entity: Entity) async throws -> Entity {
        let created = try await createInDatabase(entity)
        // Invalidate affected caches
        await cacheStrategy.invalidate(for: .entityCreated(tenantId: tenantId))
        return created
    }
}
```

## Key Repository Features

### 1. Sendable Conformance
All protocols conform to `Sendable` for Swift concurrency:
```swift
protocol TaskRepositoryProtocol: Sendable { }
```

### 2. UUID Handling - CRITICAL
**ALWAYS pass UUIDs directly to Supabase queries:**

```swift
// ✅ CORRECT - Pass UUID directly
.eq("couple_id", value: tenantId)
.eq("guest_id", value: guestId)

// ❌ WRONG - Causes case mismatch bugs
.eq("couple_id", value: tenantId.uuidString)
```

Swift uses uppercase UUID strings, PostgreSQL uses lowercase. Passing UUID directly avoids this bug.

### 3. Multi-Tenancy with couple_id
All queries MUST filter by `couple_id` (tenant ID):
```swift
.eq("couple_id", value: tenantId) // UUID type
```

### 4. Cache-First Pattern
Repositories check `RepositoryCache` before network calls:
```swift
let cacheKey = "guests_\(tenantId.uuidString)"
if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
    return cached
}
```

### 5. Network Retry Pattern
All network operations use `NetworkRetry.withRetry()`:
```swift
return try await NetworkRetry.withRetry {
    try await supabase.database
        .from("guest_list")
        .select()
        .execute()
        .value
}
```

### 6. Cache Invalidation Strategies
Each repository uses a domain-specific cache strategy:
```swift
private let cacheStrategy = GuestCacheStrategy()

await cacheStrategy.invalidate(for: .guestCreated(tenantId: tenantId))
```

See: `Domain/Repositories/Caching/` for all strategies

## Notable Repository Features

### BudgetRepositoryProtocol
- Scenario-based budget development
- Expense allocation management
- Budget overview aggregation
- Payment plan tracking
- Gift and money owed tracking

### VendorRepositoryProtocol
- Vendor import from CSV/XLSX
- Review management
- Payment tracking
- Budget category synchronization
- Archive functionality

### GuestRepositoryProtocol
- RSVP tracking
- Meal preference management
- Seating assignments
- Guest statistics and analytics
- Invitation number tracking

### CollaborationRepositoryProtocol
- Role-based access control
- Invitation management
- Multi-user collaboration
- Permission checks

### PresenceRepositoryProtocol
- Real-time presence tracking
- Editing state management
- Heartbeat mechanism (30-60 second intervals)
- Active view tracking

### ActivityFeedRepositoryProtocol
- Activity event logging
- Statistics by action type
- Statistics by resource type
- Recent activity tracking (24 hours)

## Dependency Registration

All repositories registered in `Core/Common/Common/DependencyValues.swift`:

```swift
extension DependencyValues {
    var guestRepository: GuestRepositoryProtocol {
        get { self[GuestRepositoryKey.self] }
        set { self[GuestRepositoryKey.self] = newValue }
    }
}
```

## Testing with Mock Repositories

Mock implementations in `I Do BlueprintTests/Helpers/MockRepositories.swift`:

```swift
class MockGuestRepository: GuestRepositoryProtocol {
    var guests: [Guest] = []
    var shouldThrowError = false
    
    func fetchGuests() async throws -> [Guest] {
        if shouldThrowError { throw AppError.networkError }
        return guests
    }
}
```

## Common Repository Operations

### Bulk Operations
```swift
func importVendors(_ vendors: [VendorImportData]) async throws -> [Vendor]
```

### Statistics
```swift
func fetchGuestStats() async throws -> GuestStats
func fetchActivityStats() async throws -> ActivityStats
```

### Filtering
```swift
func fetchDocuments(type: DocumentType) async throws -> [Document]
func fetchNotesByType(_ type: NoteRelatedType) async throws -> [Note]
```

### Relationship Management
```swift
func fetchSubtasks(parentId: UUID) async throws -> [WeddingTask]
func fetchAllocationsForExpense(expenseId: UUID) async throws -> [ExpenseAllocation]
```

## Error Handling

Repositories throw errors for:
- Network failures
- Database errors
- Authentication/authorization failures
- Validation errors (duplicate records, invalid data)
- Missing tenant context

## Performance Considerations

1. **Caching** - Frequently accessed data cached with TTL
2. **Batch Operations** - Bulk inserts for imports
3. **N+1 Prevention** - Bulk fetch methods for related data
4. **Index Usage** - All queries filter by indexed `couple_id`

## Related Documentation
- File: `Domain/Repositories/Caching/CacheOperation.swift` - Cache operations enum
- File: `Domain/Repositories/Caching/{Feature}CacheStrategy.swift` - Per-domain strategies
- File: `Utilities/NetworkRetry.swift` - Retry logic
- File: `Core/Common/Analytics/RepositoryCache.swift` - Actor-based cache
- Related Issue: I Do Blueprint-0wo (MockBudgetRepository reduction)