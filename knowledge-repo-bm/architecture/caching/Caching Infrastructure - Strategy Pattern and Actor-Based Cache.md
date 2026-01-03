---
title: Caching Infrastructure - Strategy Pattern and Actor-Based Cache
type: note
permalink: architecture/caching/caching-infrastructure-strategy-pattern-and-actor-based-cache
tags:
- architecture
- caching
- performance
- strategy-pattern
- actor
---

# Caching Infrastructure - Strategy Pattern and Actor-Based Cache

## Overview

I Do Blueprint uses a sophisticated caching infrastructure with:
- **Actor-based thread-safe cache** (`RepositoryCache`)
- **Strategy pattern** for domain-specific cache invalidation
- **TTL-based expiration** for automatic cache cleanup
- **Multi-tenant cache keys** for data isolation

## Architecture

```
Repository → CacheStrategy → RepositoryCache (actor)
    ↓            ↓                 ↓
  Check      Invalidate        Get/Set/Remove
  Cache      on Mutation       (Thread-Safe)
```

## Core Components

### 1. RepositoryCache Actor

**File:** `Core/Common/Analytics/RepositoryCache.swift`

Thread-safe cache using Swift actor:
```swift
actor RepositoryCache {
    static let shared = RepositoryCache()
    
    func get<T: Codable>(_ key: String, maxAge: TimeInterval) async -> T?
    func set<T: Codable>(_ key: String, value: T, ttl: TimeInterval) async
    func remove(_ key: String) async
    func clear() async
}
```

**Key Features:**
- Generic Codable support
- TTL-based expiration (checks age on retrieval)
- Thread-safe actor isolation
- Singleton instance for app-wide caching

### 2. Cache Operation Enum

**File:** `Domain/Repositories/Caching/CacheOperation.swift`

Canonical set of cache-triggering operations:

```swift
enum CacheOperation {
    // Guest operations
    case guestCreated(tenantId: UUID)
    case guestUpdated(tenantId: UUID)
    case guestDeleted(tenantId: UUID)
    case guestBulkImport(tenantId: UUID)
    
    // Budget operations
    case categoryCreated
    case categoryUpdated
    case categoryDeleted
    case expenseCreated(tenantId: UUID)
    case expenseUpdated(tenantId: UUID)
    case expenseDeleted(tenantId: UUID)
    
    // Vendor operations
    case vendorCreated(tenantId: UUID, vendorId: Int64?)
    case vendorUpdated(tenantId: UUID, vendorId: Int64?)
    case vendorDeleted(tenantId: UUID, vendorId: Int64?)
    
    // Task operations
    case taskCreated(tenantId: UUID, taskId: UUID)
    case taskUpdated(tenantId: UUID, taskId: UUID)
    case taskDeleted(tenantId: UUID, taskId: UUID)
    case subtaskCreated(tenantId: UUID, taskId: UUID)
    case subtaskUpdated(tenantId: UUID, taskId: UUID)
    
    // Timeline operations
    case timelineItemCreated(tenantId: UUID)
    case timelineItemUpdated(tenantId: UUID)
    case timelineItemDeleted(tenantId: UUID)
    case milestoneCreated(tenantId: UUID)
    case milestoneUpdated(tenantId: UUID)
    case milestoneDeleted(tenantId: UUID)
    
    // Document operations
    case documentCreated(tenantId: UUID)
    case documentUpdated(tenantId: UUID)
    case documentDeleted(tenantId: UUID)
}
```

### 3. Cache Invalidation Strategy Protocol

```swift
protocol CacheInvalidationStrategy {
    func invalidate(for operation: CacheOperation) async
}
```

### 4. Domain-Specific Cache Strategies

All cache strategies in `Domain/Repositories/Caching/`:

1. **GuestCacheStrategy** - Guest list caching
2. **BudgetCacheStrategy** - Budget and expense caching
3. **VendorCacheStrategy** - Vendor directory caching
4. **TaskCacheStrategy** - Task management caching
5. **TimelineCacheStrategy** - Timeline and milestone caching
6. **DocumentCacheStrategy** - Document storage caching

## Cache Strategy Pattern

Each domain has its own strategy actor:

```swift
actor GuestCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared
    
    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .guestCreated(let tenantId),
             .guestUpdated(let tenantId),
             .guestDeleted(let tenantId),
             .guestBulkImport(let tenantId):
            await invalidateGuestCaches(tenantId: tenantId)
        default:
            break
        }
    }
    
    private func invalidateGuestCaches(tenantId: UUID) async {
        let id = tenantId.uuidString
        await cache.remove("guests_\(id)")
        await cache.remove("guest_stats_\(id)")
        await cache.remove("guest_count_\(id)")
        await cache.remove("guest_groups_\(id)")
        await cache.remove("guest_rsvp_summary_\(id)")
        // Related features depending on guests
        await cache.remove("seating_chart_\(id)")
        await cache.remove("meal_selections_\(id)")
    }
}
```

**Pattern Benefits:**
- ✅ Centralized invalidation logic per domain
- ✅ Easy to maintain and update
- ✅ Clear documentation of cache dependencies
- ✅ Thread-safe with actor isolation
- ✅ Prevents stale data bugs

## Cache Key Convention

All cache keys use multi-tenant format:

```swift
"{resource_type}_{tenantId.uuidString}"
```

**Examples:**
- `guests_123e4567-e89b-12d3-a456-426614174000`
- `guest_stats_123e4567-e89b-12d3-a456-426614174000`
- `vendors_123e4567-e89b-12d3-a456-426614174000`
- `budget_categories_primary`

**Why UUID String:**
- Cache keys are strings (for dictionary lookup)
- UUIDs stored as UUID type elsewhere
- Conversion only for keys, not queries

## TTL Configuration

Different resources have different cache validity durations:

| Resource Type | TTL | Reason |
|--------------|-----|---------|
| Guests | 60s | Moderate changes |
| Vendors | 600s (10min) | Slow-changing |
| Tasks | 60s | Frequent updates |
| Budget Categories | 300s (5min) | Infrequent changes |
| Documents | 120s | Moderate activity |
| Stats/Aggregations | 60s | Need fresh data |

## Repository Integration

Repositories use strategy on mutations:

```swift
class LiveGuestRepository: GuestRepositoryProtocol {
    private let cacheStrategy = GuestCacheStrategy()
    
    func fetchGuests() async throws -> [Guest] {
        // 1. Check cache first
        let cacheKey = "guests_\(tenantId.uuidString)"
        if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }
        
        // 2. Fetch from database
        let guests = try await fetchFromDatabase()
        
        // 3. Cache result
        await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
        
        return guests
    }
    
    func createGuest(_ guest: Guest) async throws -> Guest {
        let created = try await createInDatabase(guest)
        
        // Invalidate affected caches
        await cacheStrategy.invalidate(for: .guestCreated(tenantId: tenantId))
        
        return created
    }
}
```

## Cache Dependencies

Some caches depend on others and must be invalidated together:

### Guest Cache Dependencies
When guests change, also invalidate:
- `guest_stats` - Statistics depend on guest list
- `guest_count` - Count depends on guest list
- `guest_groups` - Grouping depends on guest list
- `guest_rsvp_summary` - RSVP summary depends on guests
- `seating_chart` - Seating depends on guest list
- `meal_selections` - Meal choices depend on guests

### Budget Cache Dependencies
When budget items change, also invalidate:
- `budget_overview` - Overview depends on items
- `budget_summary` - Summary depends on categories
- `expense_allocations` - Allocations depend on expenses

### Vendor Cache Dependencies
When vendors change, also invalidate:
- `vendor_stats` - Statistics depend on vendor list
- `vendor_by_category` - Category views depend on vendors

## Performance Monitoring

Cache operations tracked via `PerformanceMonitor`:
- Cache hit rate
- Cache miss rate
- Average fetch time with cache
- Average fetch time without cache

**Related Issue:** I Do Blueprint-09l (Cache Strategy Consolidation and Monitoring)

## Store-Level Caching

Stores implementing `CacheableStore` protocol:

```swift
protocol CacheableStore {
    var lastLoadTime: Date? { get set }
    var cacheValidityDuration: TimeInterval { get }
}

extension CacheableStore {
    var isCacheValid: Bool {
        guard let lastLoad = lastLoadTime else { return false }
        return Date().timeIntervalSince(lastLoad) < cacheValidityDuration
    }
}
```

Stores with cache:
- GuestStoreV2 (10 min)
- VendorStoreV2 (10 min)
- TaskStoreV2 (5 min)
- BudgetStoreV2 (varies by sub-store)

## Cache Warming

**File:** `Services/Analytics/CacheWarmer.swift`

Pre-loads frequently accessed data on app launch:
- Guest list for current couple
- Vendor directory
- Budget categories
- Active tasks

## Best Practices

### ✅ Do's
1. **Use cache strategies** for all mutations
2. **Set appropriate TTLs** based on data change frequency
3. **Invalidate related caches** when dependencies exist
4. **Use multi-tenant keys** for data isolation
5. **Monitor cache hit rates** for optimization
6. **Use actor isolation** for thread safety

### ❌ Don'ts
1. **Don't skip cache invalidation** on mutations
2. **Don't use overly long TTLs** (causes stale data)
3. **Don't cache sensitive data** (passwords, tokens)
4. **Don't forget related caches** when invalidating
5. **Don't use cache for real-time data** (presence, activity)

## Future Improvements (from beads)

**Issue:** I Do Blueprint-09l (Cache Strategy Consolidation and Monitoring)

Planned improvements:
- Centralized cache monitoring dashboard
- Automatic cache hit rate tracking
- Cache size limits with LRU eviction
- Redis integration for distributed caching
- Cache preloading strategies
- Memory pressure monitoring

## References
- Related Issue: I Do Blueprint-09l (Cache strategy consolidation)
- File: `Core/Common/Analytics/RepositoryCache.swift` - Cache actor
- File: `Services/Analytics/CacheWarmer.swift` - Pre-loading
- File: `Utilities/PerformanceMonitor.swift` - Performance tracking