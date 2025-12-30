# ADR-001: Repository Pattern with Domain Services Architecture

## Status
Accepted

## Context
The application needed a clear separation between data access, business logic, and UI layers to improve testability, maintainability, and code organization. Without this separation:
- Views were directly accessing Supabase, mixing UI and data access concerns
- Business logic was scattered across stores and repositories
- Testing required mocking Supabase directly, making tests brittle
- Complex aggregation logic was difficult to maintain and reuse

## Decision
We adopted a layered architecture with:

1. **Repository Pattern**: All data access goes through repository protocols
   - Protocols define the contract (e.g., `GuestRepositoryProtocol`)
   - Live implementations handle Supabase interactions
   - Mock implementations enable isolated testing
   - Repositories handle CRUD operations and caching

2. **Domain Services Layer**: Complex business logic separated from repositories
   - Services are actors for thread safety
   - Handle aggregations, calculations, and complex queries
   - Repositories delegate to services for complex operations
   - Examples: `BudgetAggregationService`, `BudgetAllocationService`

3. **Data Flow**:
   ```
   View → Store → Repository → Domain Service (if needed) → Supabase
   ```

4. **Dependency Injection**: Using Swift's `@Dependency` macro
   - Repositories registered in `DependencyValues.swift`
   - Stores inject repositories via `@Dependency`
   - Tests inject mock repositories

## Consequences

### Positive
- **Testability**: Stores can be tested with mock repositories without Supabase
- **Maintainability**: Clear separation of concerns makes code easier to understand
- **Reusability**: Domain services can be reused across multiple repositories
- **Flexibility**: Easy to swap implementations (e.g., switch from Supabase to another backend)
- **Type Safety**: Protocol-based design catches errors at compile time
- **Thread Safety**: Actor-based services prevent data races

### Negative
- **Boilerplate**: Requires creating protocols, live implementations, and mocks
- **Learning Curve**: Developers need to understand the layered architecture
- **Indirection**: More layers between UI and data can make debugging harder
- **Initial Setup**: New features require more upfront work (protocol, implementation, mock, service)

## Implementation Notes
- All new data access must go through repositories
- Complex business logic (>50 lines) should be extracted to domain services
- Mock repositories must be maintained alongside live implementations
- Services should be actors when managing shared state
- Follow the pattern established in `BudgetAggregationService` for new services

## Related Documents
- `best_practices.md` - Section 5: Repository Pattern
- `DOMAIN_SERVICES_ARCHITECTURE.md` - Detailed service architecture
- `Domain/Repositories/` - Repository implementations
- `Domain/Services/` - Domain service implementations
