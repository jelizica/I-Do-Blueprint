# Cache Architecture

This document describes the centralized, strategy-based cache invalidation architecture used in the app. It replaces scattered, duplicated cache key removals across repositories with cohesive, testable strategies per domain.

## Goals
- Maintainability: one place to evolve cache invalidation logic per domain
- Consistency: tenant-aware, uniform invalidation behavior
- Safety: fewer opportunities to forget key removals during feature work
- Testability: unit tests can assert that the right keys are invalidated

## Core Concepts

- Strategy pattern per domain: each strategy implements `CacheInvalidationStrategy` and responds to `CacheOperation` values
- Canonical operations: `CacheOperation` is the single source of truth for events that trigger cache invalidation
- Repository integration: repositories call `strategy.invalidate(for: ...)` in mutation paths
- Tenant-awareness: all tenant-scoped keys include the `UUID` namespace (e.g., `_\(tenantId.uuidString)`).

## File Index
- `Domain/Repositories/Caching/CacheInvalidationStrategy.swift`
- `Domain/Repositories/Caching/CacheOperation.swift`
- `Domain/Repositories/Caching/GuestCacheStrategy.swift`
- `Domain/Repositories/Caching/BudgetCacheStrategy.swift`
- `Domain/Repositories/Caching/VendorCacheStrategy.swift`
- `Domain/Repositories/Caching/TaskCacheStrategy.swift`
- `Domain/Repositories/Caching/TimelineCacheStrategy.swift`
- `Domain/Repositories/Caching/DocumentCacheStrategy.swift`

## Cache Key Conventions

- Global keys: no tenant suffix (e.g., `budget_categories`, `budget_summary`)
- Tenant keys: `*_\(tenantId.uuidString)` (e.g., `guests_<tenant>`, `tasks_<tenant>`)
- Composite keys: include extra identifiers (e.g., `vendor_reviews_<vendorId>_<tenant>`, `task_<taskId>_<tenant>`)
- TTL guidance: short for volatile lists (10–60s), longer for summaries (minutes) where UX permits

## Operations → Keys Map (By Domain)

### Guests (GuestCacheStrategy)
Operations:
- `guestCreated(tenantId)`
- `guestUpdated(tenantId)`
- `guestDeleted(tenantId)`
- `guestBulkImport(tenantId)`

Invalidated keys:
- `guests_<tenant>`
- `guest_stats_<tenant>`
- `guest_count_<tenant>`
- `guest_groups_<tenant>`
- `guest_rsvp_summary_<tenant>`
- Related: `seating_chart_<tenant>`, `meal_selections_<tenant>`

### Budget (BudgetCacheStrategy)
Operations:
- `categoryCreated`, `categoryUpdated`, `categoryDeleted`
- `expenseCreated(tenantId)`, `expenseUpdated(tenantId)`, `expenseDeleted(tenantId)`

Invalidated keys:
- Categories: `budget_categories`, `budget_summary`
- Expenses: `expenses_<tenant>`, `budget_summary`, `budget_overview_items`

### Vendors (VendorCacheStrategy)
Operations:
- `vendorCreated(tenantId, vendorId?)`
- `vendorUpdated(tenantId, vendorId?)`
- `vendorDeleted(tenantId, vendorId?)`

Invalidated keys:
- `vendors_<tenant>`, `vendor_stats_<tenant>`
- If `vendorId` present:
  - `vendor_reviews_<vendorId>_<tenant>`
  - `vendor_review_stats_<vendorId>_<tenant>`
  - `vendor_payment_summary_<vendorId>_<tenant>`
  - `vendor_contract_summary_<vendorId>_<tenant>`

### Tasks (TaskCacheStrategy)
Operations:
- `taskCreated(tenantId, taskId)`
- `taskUpdated(tenantId, taskId)`
- `taskDeleted(tenantId, taskId)`
- `subtaskCreated(tenantId, taskId)`
- `subtaskUpdated(tenantId, taskId)`

Invalidated keys:
- `tasks_<tenant>`, `task_stats_<tenant>`
- `task_<taskId>_<tenant>`, `subtasks_<taskId>_<tenant>`

### Timeline (TimelineCacheStrategy)
Operations:
- `timelineItemCreated(tenantId)`, `timelineItemUpdated(tenantId)`, `timelineItemDeleted(tenantId)`
- `milestoneCreated(tenantId)`, `milestoneUpdated(tenantId)`, `milestoneDeleted(tenantId)`

Invalidated keys:
- Timeline items: `timeline_items_<tenant>`, `timeline_stats_<tenant>`
- Milestones: `milestones_<tenant>`

### Documents (DocumentCacheStrategy)
Operations:
- `documentCreated(tenantId)`, `documentUpdated(tenantId)`, `documentDeleted(tenantId)`

Invalidated keys:
- `documents_<tenant>`
- Type/bucket-specific keys if tracked (pattern placeholders):
  - `documents_type_*_<tenant>`
  - `documents_bucket_*_<tenant>`

Note: If/when we formalize type/bucket cache keys, replace wildcards with explicit removals.

## Repository Integration Pattern

- Define a private strategy instance in the repository (actor-safe):
  - `private let cacheStrategy = <Domain>CacheStrategy()`
- On mutations (create/update/delete), after successful DB ops:
  - Resolve required IDs (tenant, taskId, vendorId, etc.)
  - Call `await cacheStrategy.invalidate(for: .<operation>(...))`
- Remove legacy inline cache removals (`RepositoryCache.shared.remove(...)`)

## How to Add a New Cached Feature
1. Define/extend a `CacheOperation` that represents the mutation(s)
2. Update or add a `<Domain>CacheStrategy` to map operation → cache key removals
3. Integrate in the repository mutation path(s)
4. Write unit tests (see Testing)

## Testing

- Unit tests per strategy (e.g., `GuestCacheStrategyTests`):
  - Seed cache keys
  - Invoke `invalidate(for:)`
  - Assert keys are cleared
- Integration tests per repository mutation path:
  - Perform mutation
  - Assert relevant cache keys are invalidated (and refetch repopulates as expected)

## Migration Notes

- Inline removals have been replaced in Guests, Budget (categories/expenses), Vendors, Tasks (tasks/subtasks), Timeline (items/milestones), Documents.
- If a new cache key is introduced, prefer updating the relevant strategy instead of adding inline removals.

## Future Enhancements
- Cache warming for critical paths post-invalidation
- Event-based invalidation hooks for cross-feature coordination
- Key registry for discoverability and static validation
- Visualization of dependency graph (operation → keys)

## FAQ
- Why strategies instead of helpers? Strategies encode domain knowledge and are easy to test/migrate independently.
- Why enums for operations? Enums provide compiler-checked coverage and make it clear which mutations exist per domain.
- Are strategies actors? Yes, to keep access to `RepositoryCache.shared` serialized in async contexts.
