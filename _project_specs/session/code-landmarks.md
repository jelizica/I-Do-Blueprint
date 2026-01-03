<!--
UPDATE WHEN:
- Adding new entry points or key files
- Introducing new patterns
- Discovering non-obvious behavior

Helps quickly navigate the codebase when resuming work.
-->

# Code Landmarks

Quick reference to important parts of the codebase.

## Entry Points
| Location | Purpose |
|----------|---------|
| App/App.swift | Main application entry |
| App/RootFlowView.swift | Root view routing (auth flow vs main app) |

## Core Business Logic
| Location | Purpose |
|----------|---------|
| Domain/Services/ | Domain services (business logic actors) |
| Domain/Repositories/Live/ | Supabase implementations with caching |
| Services/Stores/ | State management (V2 pattern) |

## Store Composition
| Location | Purpose |
|----------|---------|
| Services/Stores/BudgetStoreV2.swift | Budget composition root |
| Services/Stores/Budget/ | BudgetStoreV2 sub-stores (6 specialized stores) |

## Configuration
| Location | Purpose |
|----------|---------|
| Core/Configuration/AppConfig.swift | App configuration (hardcoded fallback) |
| Core/Common/Common/DependencyValues.swift | Dependency injection registration |
| Core/Common/Common/AppStores.swift | Singleton store access |

## Key Patterns
| Pattern | Example Location | Notes |
|---------|------------------|-------|
| Repository Pattern | Domain/Repositories/Protocols/ | All data access |
| Cache Strategies | Domain/Repositories/Caching/ | Per-domain cache invalidation |
| Domain Services | Domain/Services/ | Complex business logic separation |
| Store Composition | Services/Stores/BudgetStoreV2.swift | Sub-store pattern |
| Multi-tenancy | All repositories | couple_id scoping with RLS |

## Testing
| Location | Purpose |
|----------|---------|
| I Do BlueprintTests/ | Test files |
| I Do BlueprintTests/Helpers/MockRepositories.swift | Mock implementations |
| I Do BlueprintTests/Helpers/ModelBuilders.swift | .makeTest() factories |

## Gotchas & Non-Obvious Behavior
| Location | Issue | Notes |
|----------|-------|-------|
| Domain/Repositories/Live/ | UUID handling | MUST pass UUID directly to queries (not .uuidString) - case mismatch |
| Core/Common/Common/AppStores.swift | Store access | NEVER create store instances in views - use AppStores.shared or @Environment |
| Services/Stores/Budget/ | Store composition | Access sub-stores directly (no delegation methods) |
| Utilities/DateFormatting.swift | Timezone handling | NEVER use TimeZone.current - use user's configured timezone |
| Utilities/NetworkRetry.swift | Network calls | Always wrap Supabase calls in NetworkRetry.withRetry |
