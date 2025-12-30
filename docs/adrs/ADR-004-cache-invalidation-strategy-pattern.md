# ADR-004: Cache Invalidation Strategy Pattern

## Status
Accepted

## Context
The application uses caching at multiple levels (repository, store) to improve performance. However, cache invalidation was becoming problematic:
- Cache invalidation logic was scattered across repositories
- Difficult to track which caches needed invalidation for each operation
- Easy to miss cache invalidation, leading to stale data
- No consistent pattern for related cache invalidation
- Hard to maintain as the application grew

## Decision
We implemented a Strategy Pattern for cache invalidation:

1. **CacheOperation Enum**:
   - Defines all operations that trigger cache invalidation
   - Organized by domain (guest, budget, vendor, etc.)
   - Example:
     ```swift
     enum CacheOperation {
         case guestCreated(tenantId: UUID)
         case guestUpdated(tenantId: UUID)
         case guestDeleted(tenantId: UUID)
         case guestBulkImport(tenantId: UUID)
     }
     ```

2. **CacheInvalidationStrategy Protocol**:
   ```swift
   protocol CacheInvalidationStrategy: Actor {
       func invalidate(for operation: CacheOperation) async
   }
   ```

3. **Domain-Specific Strategies**:
   - One strategy per domain (e.g., `GuestCacheStrategy`)
   - Strategies are actors for thread safety
   - Encapsulate all cache invalidation logic for that domain
   - Located in `Domain/Repositories/Caching/`

4. **Repository Integration**:
   - Each repository has a `cacheStrategy` property
   - Repositories call strategy after mutations
   - Example:
     ```swift
     func createGuest(_ guest: Guest) async throws -> Guest {
         let created = try await createInDatabase(guest)
         await cacheStrategy.invalidate(for: .guestCreated(tenantId: tenantId))
         return created
     }
     ```

5. **RepositoryCache Actor**:
   - Thread-safe cache with TTL support
   - Generic caching infrastructure
   - Used by all repositories

## Consequences

### Positive
- **Maintainability**: All cache invalidation logic for a domain in one place
- **Discoverability**: Easy to find what caches are invalidated for each operation
- **Consistency**: Ensures related caches are always invalidated together
- **Thread Safety**: Actor-based strategies prevent race conditions
- **Testability**: Strategies can be tested independently
- **Extensibility**: Easy to add new cache invalidation rules

### Negative
- **Boilerplate**: Each domain needs its own strategy
- **Indirection**: One more layer between repository and cache
- **Learning Curve**: Developers must understand the strategy pattern
- **Potential Over-Invalidation**: May invalidate more caches than strictly necessary

## Implementation Notes

### Creating a New Cache Strategy

1. **Define Operations**:
   ```swift
   enum CacheOperation {
       case myDomainCreated(tenantId: UUID)
       case myDomainUpdated(tenantId: UUID)
       case myDomainDeleted(tenantId: UUID)
   }
   ```

2. **Implement Strategy**:
   ```swift
   actor MyDomainCacheStrategy: CacheInvalidationStrategy {
       func invalidate(for operation: CacheOperation) async {
           switch operation {
           case .myDomainCreated(let tenantId),
                .myDomainUpdated(let tenantId),
                .myDomainDeleted(let tenantId):
               let idString = tenantId.uuidString
               await RepositoryCache.shared.remove("mydomain_\(idString)")
               await RepositoryCache.shared.remove("mydomain_stats_\(idString)")
           default:
               break
           }
       }
   }
   ```

3. **Use in Repository**:
   ```swift
   class LiveMyDomainRepository: MyDomainRepositoryProtocol {
       private let cacheStrategy = MyDomainCacheStrategy()
       
       func create(_ item: MyDomain) async throws -> MyDomain {
           let created = try await createInDatabase(item)
           await cacheStrategy.invalidate(for: .myDomainCreated(tenantId: tenantId))
           return created
       }
   }
   ```

### Cache Key Patterns
- Use tenant ID in all cache keys: `"resource_\(tenantId.uuidString)"`
- Use descriptive names: `"guests_"`, `"guest_stats_"`, `"guest_count_"`
- Group related caches with common prefixes

### When to Invalidate
- **Create**: Invalidate list caches, stats, counts
- **Update**: Invalidate specific item cache, list caches, stats
- **Delete**: Invalidate specific item cache, list caches, stats, counts
- **Bulk Operations**: Invalidate all related caches

## Related Documents
- `best_practices.md` - Section 5: Cache Invalidation Strategy Pattern
- `CACHE_ARCHITECTURE.md` - Detailed cache architecture
- `Domain/Repositories/Caching/` - Cache strategy implementations
- `Domain/Repositories/RepositoryCache.swift` - Cache infrastructure
