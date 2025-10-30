# Cont3xt MCP Knowledge Base: Rules & ADR Patterns

**Project**: I Do Blueprint - Wedding Planning Application
**Platform**: macOS (SwiftUI)
**Architecture**: MVVM + Repository Pattern + Multi-Tenant SaaS
**Backend**: Supabase (PostgreSQL with RLS)
**Generated**: 2025-01-24
**Version**: 1.0

---

## Table of Contents

1. [Architecture Decision Records (ADRs)](#architecture-decision-records-adrs)
2. [Coding Rules by Domain](#coding-rules-by-domain)
3. [Database Patterns](#database-patterns)
4. [Security Patterns](#security-patterns)
5. [Performance Patterns](#performance-patterns)
6. [Testing Patterns](#testing-patterns)
7. [Error Handling Patterns](#error-handling-patterns)
8. [Store Management Patterns](#store-management-patterns)

---

## Architecture Decision Records (ADRs)

### ADR-001: Repository Pattern with Actor-Based Caching

**Title**: Repository Pattern with Actor-Based Caching

**Context**:
The application required a type-safe data access layer with automatic caching and multi-tenant isolation across all feature modules. Without a consistent abstraction, the codebase was experiencing scattered Supabase client usage, inconsistent caching strategies, and difficulties in testing due to direct database dependencies. The need for thread-safe caching to support Swift's modern concurrency model was critical, as multiple views could trigger concurrent data fetches that needed proper synchronization.

**Decision**:
All data access in the application goes through repository protocols such as `GuestRepositoryProtocol`, `BudgetRepositoryProtocol`, and `VendorRepositoryProtocol`. Each repository has both a Live implementation for production use with real Supabase connections and a Mock implementation for testing purposes. Caching is implemented using a thread-safe `RepositoryCache` actor that prevents race conditions during concurrent access. All repositories are registered via the dependency injection system using Point-Free's Dependencies framework, allowing runtime configuration and easy substitution during testing.

Implementation example:
```swift
// Protocol definition
protocol GuestRepositoryProtocol: Sendable {
    func fetchGuests() async throws -> [Guest]
    func createGuest(_ guest: Guest) async throws -> Guest
}

// Live implementation with caching
actor LiveGuestRepository: GuestRepositoryProtocol {
    func fetchGuests() async throws -> [Guest] {
        let cacheKey = "guests_\(tenantId.uuidString)"
        if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }
        let guests = try await fetchFromDatabase()
        await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
        return guests
    }
}
```

**Consequences**:

This decision significantly improved testability across the codebase, making 95% test coverage achievable through the use of mock repositories. The consistent caching strategy eliminated redundant network calls and provided predictable performance characteristics. Type-safe data access through protocols prevents runtime errors that could occur with direct database queries. The actor-based caching system prevents race conditions that were previously possible when multiple concurrent operations accessed shared cache state. Dependency injection enables runtime configuration, making it easy to swap implementations for testing, development, and production environments.

However, this pattern requires strict discipline to prevent developers from bypassing repositories and accessing the database directly, which would undermine the abstraction. Cache invalidation must be manually managed on all mutation operations, creating potential for cache inconsistency if developers forget to invalidate affected keys. The additional abstraction layer adds initial complexity to the codebase, requiring more upfront code for each feature. New developers must understand both the protocol-oriented programming pattern and how the specific repository implementations work, increasing the learning curve.

**Status**: Adopted (2024-10)

**Tags**: `architecture`, `data-access`, `caching`, `testing`, `actor-concurrency`

**Related PR URLs**: N/A

**Related Files**: `I Do Blueprint/Domain/Repositories/Live/*.swift`, `I Do Blueprint/Domain/Repositories/Mock/*.swift`, `I Do Blueprint/Domain/Repositories/Protocols/*RepositoryProtocol.swift`, `I Do Blueprint/Services/Network/RepositoryCache.swift`

---

### ADR-002: StoreV2 Pattern for State Management

**Title**: StoreV2 Pattern for State Management

**Context**:
The application needed consistent state management across feature modules with proper error handling, memory-efficient store access, and seamless SwiftUI integration. Previous patterns allowed views to create duplicate store instances using `@StateObject`, which caused significant memory bloat as each store would load entire datasets (500KB to 2MB per instance). Multiple instances of the same store also created state synchronization issues where updates in one view wouldn't reflect in others. The lack of standardized async operation tracking led to inconsistent loading states and error handling across different features.

**Decision**:
All stores follow the V2 naming convention such as `BudgetStoreV2`, `GuestStoreV2`, and `VendorStoreV2` to distinguish them from previous implementations. Stores are implemented as `@MainActor` `ObservableObject` classes to ensure thread-safe UI updates through SwiftUI's observation system. The `LoadingState<T>` enum provides consistent async operation state tracking across all stores, with states for idle, loading, loaded with data, and error conditions. Repositories are injected via the `@Dependency` macro from Point-Free Dependencies framework for testability. The `AppStores` singleton serves as the single source of truth for all store instances, preventing memory duplication. There are four approved access patterns in priority order: Environment injection using `@Environment(\.appStores)`, direct environment store injection using `@Environment(\.budgetStore)`, passing stores as parameters from parent views, and direct singleton access as a last resort for edge cases.

Implementation example:
```swift
@MainActor
class GuestStoreV2: ObservableObject {
    @Published var loadingState: LoadingState<[Guest]> = .idle
    @Published private(set) var error: GuestError?
    @Dependency(\.guestRepository) var repository

    func loadGuests() async {
        guard loadingState.isIdle || loadingState.hasError else { return }
        loadingState = .loading
        do {
            let guests = try await repository.fetchGuests()
            loadingState = .loaded(guests)
        } catch {
            loadingState = .error(GuestError.fetchFailed(underlying: error))
            logger.error("Failed to load guests", error: error)
        }
    }
}
```

**Consequences**:

The consistent state management pattern across all feature modules eliminated the architectural inconsistencies that plagued the previous implementation. Proper async/await integration with SwiftUI's observation system provides reactive UI updates that feel natural and performant. Thread-safe UI updates via `@MainActor` isolation prevent data races and ensure all UI modifications happen on the main thread. The memory-efficient single instance per store type dramatically reduced the app's memory footprint, particularly in views with complex hierarchies where multiple instances could easily accumulate. Dependency injection with mock repositories makes unit testing straightforward and reliable. Type-safe loading states eliminate entire categories of UI state bugs where views might render incorrect states during async operations.

However, developers must always access stores via the `AppStores` singleton or environment injection, never creating new instances with `@StateObject`, which can be violated easily without vigilance. The memory rules are easy to break accidentally, requiring strict code review processes and clear documentation for all team members. New developers face an additional learning curve understanding both the dependency injection pattern and the singleton access pattern. The pattern requires developers to understand multiple advanced Swift concepts simultaneously including `@MainActor`, property wrappers, dependency injection, and the observation system, which can be overwhelming for junior developers or those new to the codebase.

**Status**: Adopted (2024-10)

**Tags**: `architecture`, `state-management`, `swiftui`, `memory`, `dependency-injection`

**Related PR URLs**: N/A

**Related Files**: `I Do Blueprint/Services/Stores/*StoreV2.swift`, `I Do Blueprint/Core/Common/AppStores.swift`, `I Do Blueprint/Core/Common/LoadingState.swift`

---

### ADR-003: UUID Best Practices for Multi-Tenant Data

**Title**: UUID Best Practices for Multi-Tenant Data

**Context**:
The application encountered case mismatch issues between Swift's UUID.uuidString format (uppercase) and PostgreSQL's uuid storage format (lowercase), causing dictionary lookup failures and query inefficiencies. When Swift code converted UUIDs to strings for use as dictionary keys or cache keys, subsequent lookups would fail if the key format didn't match exactly. This created subtle bugs in cache retrieval, data aggregation operations that grouped by UUID keys, and anywhere dictionary lookups depended on string representations of UUIDs. The issue was particularly problematic in multi-tenant scenarios where couple_id values needed consistent handling across both Swift code and database queries.

**Decision**:
The application always passes UUID values directly to Supabase queries without converting to `.uuidString`, leveraging the native UUID type support in both Swift and PostgreSQL. String conversions are minimized and only performed when absolutely necessary such as cache key generation, logging, or dictionary key creation. When creating dictionaries with UUID-based keys, the code normalizes all keys to lowercase using `.lowercased()` at the point of dictionary creation to ensure consistent lookup behavior. Converted UUID strings are reused throughout a single operation rather than repeatedly calling `.uuidString`, which both improves performance by reducing string allocations and ensures consistent formatting within that operation's scope.

The Supabase Swift client supports UUID types natively, making string conversion unnecessary for database operations. PostgreSQL's UUID type handles case-insensitivity for comparisons at the database level. However, Swift's dictionary lookups require exact key matching, so the normalization to lowercase is essential for reliable dictionary operations. Reusing converted strings also eliminates redundant string allocations and prevents subtle bugs from mixed case usage within a single code path.

Implementation examples:
```swift
// ✅ GOOD: Pass UUID directly
let guests: [Guest] = try await supabase.database
    .from("guest_list")
    .select()
    .eq("couple_id", value: tenantId) // UUID type
    .execute()
    .value

// ✅ GOOD: Normalize dictionary keys
var allocationsByItem: [String: [Allocation]] = [:]
for allocation in allocations {
    let itemId = allocation.budgetItemId.uuidString.lowercased()
    allocationsByItem[itemId, default: []].append(allocation)
}

// ✅ GOOD: Reuse converted string
let tenantIdString = tenantId.uuidString
await cache.remove("guests_\(tenantIdString)")
await cache.remove("stats_\(tenantIdString)")

// ❌ BAD: Converting for database query
.eq("couple_id", value: tenantId.uuidString) // Unnecessary

// ❌ BAD: Repeated conversions
await cache.remove("guests_\(id.uuidString)")
await cache.remove("stats_\(id.uuidString)")
```

**Consequences**:

The normalization strategy eliminated all case mismatch bugs in dictionary operations, which had previously caused intermittent failures in cache lookups and data aggregation. Better performance resulted from fewer string allocations, as UUID values are passed directly to database queries and string conversions happen only when necessary and are reused within operations. The query code became cleaner and more idiomatic by leveraging native UUID type support in the Supabase SDK rather than working around it with string conversions. The approach reduced the potential for case-sensitivity bugs throughout the codebase by establishing clear patterns for when and how to convert UUIDs to strings.

However, developers must remember to normalize to lowercase when mixing Swift UUIDs with database-returned strings, which isn't always obvious when writing new code. The pattern requires code review discipline to catch violations, as there's no compile-time enforcement of the normalization rule. Debugging UUID mismatches can be subtle because the values look identical in logs but differ only in case. New developers joining the project may not immediately be aware of the case sensitivity issues between Swift and PostgreSQL, leading to bugs that only manifest in specific data scenarios.

**Status**: Adopted (2024-11)

**Tags**: `database`, `performance`, `data-types`, `multi-tenant`, `best-practices`

**Related PR URLs**: N/A

**Related Files**: `UUID_CASE_MISMATCH_FIX.md`, `UUID_FIX_COMPLETION_SUMMARY.md`, `I Do Blueprint/Domain/Repositories/Live/*.swift`

---

### ADR-004: Multi-Tenant Security with RLS

**Title**: Multi-Tenant Security with Row Level Security

**Context**:
The application required secure data isolation between wedding couples who share the same database infrastructure. Without proper isolation, queries from one tenant could potentially access or modify another tenant's data, creating a critical security vulnerability. The multi-tenant architecture needed a reliable, database-enforced mechanism to ensure that each couple could only access their own wedding planning data, including guests, vendors, budget information, and timeline events. Previous application-level filtering was error-prone and didn't provide defense-in-depth security guarantees.

**Decision**:
All multi-tenant tables include a `couple_id` column for tenant scoping, which serves as the foreign key to the couple_profiles table. Row Level Security is enabled on all multi-tenant tables with a single policy per table using the `FOR ALL` command that handles SELECT, INSERT, UPDATE, and DELETE operations in one declaration. The policy naming pattern follows `couples_manage_own_{resource}` for consistency and clarity. A helper function `get_user_couple_id()` provides consistent tenant scoping across all policies, eliminating code duplication. Most critically, all RLS policies and helper functions use `(SELECT auth.uid())` with a SELECT wrapper instead of calling `auth.uid()` directly, which prevents per-row function evaluation and provides dramatic performance improvements.

The RLS approach enforces security at the database level rather than relying solely on application code, providing defense-in-depth security guarantees. The single policy per table using `FOR ALL` simplifies policy management by consolidating what would otherwise be four separate policies into one. The subquery wrapper around `auth.uid()` prevents per-row function evaluation, which was discovered to cause significant performance degradation on large datasets where the function would be called once per row instead of once per query.

**Implementation**:
```sql
-- Enable RLS
ALTER TABLE guest_list ENABLE ROW LEVEL SECURITY;

-- Create policy (single policy for all operations)
CREATE POLICY "couples_manage_own_guests"
  ON guest_list
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- Helper function
CREATE OR REPLACE FUNCTION get_user_couple_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT couple_id
  FROM couple_profiles
  WHERE id = (SELECT auth.uid())  -- ✅ With SELECT wrapper
  LIMIT 1;
$$;
```

**Performance Impact**:
Without the SELECT wrapper, calling `auth.uid()` directly results in 1000 function calls for a query returning 1000 rows, as the function is evaluated for each row individually. With the SELECT wrapper `(SELECT auth.uid())`, the same query results in only 1 function call total, as PostgreSQL evaluates the subquery once and reuses the result for all rows. This provides a 50-90% performance improvement for large datasets, which was documented in the JES-149 performance fix.

**Consequences**:

Database-level security enforcement through RLS provides guarantees that cannot be bypassed by application code bugs or oversights. No cross-tenant data leakage is possible as the database itself enforces the security boundary, creating defense-in-depth beyond application-level checks. Policy management is dramatically simplified with 1 policy per table instead of 4 separate policies for each CRUD operation. The dramatic performance improvement from the SELECT wrapper optimization prevents the performance degradation that was initially observed with naive RLS implementations.

However, tenant isolation must be thoroughly tested in development and staging environments to ensure the policies work correctly across all edge cases and scenarios. Policy changes require database migrations, which adds deployment complexity and requires careful rollout procedures. There is an initial learning curve for developers unfamiliar with Row Level Security concepts. Policy debugging can be challenging as RLS violations sometimes result in empty result sets rather than explicit errors.

**Status**: Adopted (2024-10)

**Tags**: `security`, `multi-tenant`, `database`, `rls`, `performance`

**Related PR URLs**: N/A

**Related Files**: `docs/database/RLS_POLICIES.md`, `JES-149_RLS_PERFORMANCE_FIX_SUMMARY.md`, `supabase/migrations/*_rls_policies.sql`

---

### ADR-005: Database Function Security Hardening

**Title**: Database Function Security Hardening with search_path Protection

**Context**:
A security vulnerability was discovered where mutable `search_path` in database functions could enable SQL injection attacks through schema poisoning. Without explicit `SET search_path = ''`, an attacker could create malicious functions or objects in a schema they control and manipulate the search_path to have PostgreSQL resolve function calls to their malicious implementations instead of the intended ones. This vulnerability was rated as HIGH severity and affected 42+ tables using trigger functions like `update_updated_at_column`. The issue was particularly critical because trigger functions execute with elevated privileges and could potentially be exploited to bypass security policies or modify data inappropriately.

**Decision**:
All database functions must explicitly include `SET search_path = ''` in their function definition, setting the search path to empty. Functions requiring elevated privileges use the `SECURITY DEFINER` attribute, which is common for trigger functions and administrative operations. The security rationale for using empty search_path must be documented in function comments to ensure future maintainers understand why this pattern exists. This pattern is applied retroactively to all existing trigger functions and prospectively to all new database functions, with particular attention to the `update_updated_at_column` function used by 42+ tables.

Empty search_path prevents schema poisoning attacks by forcing all object references to be fully-qualified, meaning attackers cannot inject malicious functions in their schema and trick PostgreSQL into resolving to them. The pattern forces developers to use fully-qualified object names like `public.function_name` or `pg_catalog.now()`, which eliminates ambiguity in function resolution. This protection is critical for functions used by many tables, as a single compromised function could affect the entire application.

**Implementation**:
```sql
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''  -- ✅ Prevents schema poisoning
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;
```

**Consequences**:

The implementation eliminates a HIGH severity security vulnerability that could have allowed attackers to execute arbitrary SQL code through schema poisoning. Protection extends to 42+ tables using trigger functions, significantly reducing the attack surface. The pattern prevents SQL injection via search path manipulation, a subtle but dangerous attack vector that is often overlooked in database security audits. The explicit security setting provides clear documentation of security intent in the codebase itself.

However, all existing functions must be updated to include the search_path protection, requiring careful migration planning and testing to ensure no functions are missed. Requires ongoing security advisor monitoring through Supabase advisors to catch any new functions that don't follow the pattern. Developers must remember to include the SET clause in all new functions, which isn't enforced at compile time and requires code review discipline. The use of SECURITY DEFINER requires additional scrutiny since these functions run with elevated privileges.

**Status**: Adopted (2025-01)

**Tags**: `security`, `database`, `sql-injection`, `functions`, `high-severity`

**Related PR URLs**: N/A

**Related Files**: `JES-146_SECURITY_FIX_SUMMARY.md`, `supabase/migrations/*_fix_search_path.sql`, `docs/database/SECURITY.md`

---

### ADR-006: Store Access Patterns (CRITICAL)

**Title**: Critical Store Access Patterns for Memory Management

**Context**:
The application experienced memory explosion from SwiftUI views creating duplicate store instances using `@StateObject`. Each store loads full datasets ranging from 500KB to 2MB, and views that created their own instances were unknowingly allocating 1-5MB of duplicate data per view. In complex view hierarchies with multiple levels of navigation, this memory duplication compounded dramatically, causing the app to consume hundreds of megabytes unnecessarily. Beyond memory concerns, duplicate store instances created state synchronization issues where updates made through one instance wouldn't reflect in views using different instances, leading to confusing UI inconsistencies.

**Decision**:
Views must never create new store instances directly using `@StateObject` or manual initialization. All store access must go through the `AppStores` singleton, which maintains single instances of each store type. There are four approved patterns for accessing stores, listed in priority order of preference. First preference is environment access using `@Environment(\.appStores) private var appStores` to access the AppStores container and then extracting the needed store. Second preference is direct environment store injection using `@Environment(\.budgetStore) private var store` for when a view only needs one specific store. Third preference is passing stores as parameters from parent views using `@ObservedObject var budgetStore: BudgetStoreV2`, which works well for child views that receive stores from their parents. Fourth and last resort is direct singleton access using `AppStores.shared.settings` for edge cases where environment injection isn't available.

Each store loads full datasets with BudgetStoreV2 consuming approximately 500KB-2MB, GuestStoreV2 consuming 200KB-1MB, and VendorStoreV2 consuming 300KB-1MB. Creating duplicate instances wastes 1-5MB per view, which multiplies quickly in navigation hierarchies. State synchronization issues arise with multiple instances because SwiftUI views observe their own store copies and don't receive updates made to other instances. The singleton pattern ensures a single source of truth for all application state.

**Implementation**:
```swift
// ✅ GOOD: Environment access
struct SettingsView: View {
    @Environment(\.appStores) private var appStores

    private var store: SettingsStoreV2 {
        appStores.settings
    }
}

// ✅ GOOD: Direct environment store
struct BudgetView: View {
    @Environment(\.budgetStore) private var store
}

// ✅ GOOD: Pass from parent
struct BudgetDetailView: View {
    @ObservedObject var budgetStore: BudgetStoreV2
}
BudgetDetailView(budgetStore: appStores.budget)

// ❌ BAD: Creates duplicate instance
struct SettingsView: View {
    @StateObject private var store = SettingsStoreV2()  // DON'T DO THIS!
}
```

**Consequences**:

The strict store access patterns prevent memory explosion by ensuring only one instance of each store exists throughout the application's lifecycle. State consistency is guaranteed because all views observe the same store instances, so updates in one part of the app immediately reflect everywhere. The dramatically reduced memory footprint improves overall app performance and allows the application to handle larger datasets without running into memory pressure. The patterns provide clear guidance for developers on how to access stores correctly.

However, the patterns require strict code review enforcement because violations are syntactically valid Swift code that compiles successfully. The memory rules are easy to violate accidentally, especially for developers unfamiliar with the rationale behind the singleton pattern. New team members may instinctively use `@StateObject` based on standard SwiftUI patterns, unaware of the memory implications in this specific architecture. There's no compile-time enforcement of these patterns, making them vulnerable to regression without vigilant code review and testing.

**Status**: Adopted (2024-10) - CRITICAL

**Tags**: `architecture`, `memory`, `state-management`, `swiftui`, `critical`, `performance`

**Related PR URLs**: N/A

**Related Files**: `I Do Blueprint/Core/Common/AppStores.swift`, `ARCHITECTURE_ANALYSIS_2025-10-19.md`, `best_practices.md`

---

### ADR-007: Network Retry with Exponential Backoff

**Title**: Network Retry with Exponential Backoff for Resilience

**Context**:
Network failures were causing frequent user-facing errors and the application showed poor resilience on unstable connections. Users experienced failures during WiFi-to-cellular transitions, in areas with weak signal, and when backend services had temporary availability issues. Without automatic retry logic, users had to manually retry operations by navigating away and back, creating a poor user experience. The lack of retry logic also made the application appear unreliable, increasing support burden from users reporting network-related issues that were actually transient failures.

**Decision**:
All network operations use `NetworkRetry.withRetry()` wrapper to automatically retry failed requests with exponential backoff. The default configuration provides max 3 attempts with exponential backoff delays starting at 1 second, which handles most transient failures without excessive delay. Critical operations like data submission or payment processing use custom configuration with 5 attempts and longer delays to maximize success probability. Timeout support is available for slow operations to prevent indefinite waiting, with configurable timeout values based on operation type.

Transient network failures are common in mobile environments due to WiFi transitions, cellular tower handoffs, and mobile data connectivity issues. Exponential backoff prevents overwhelming servers by increasing delays between retries, giving backend services time to recover from temporary overload. User experience improves dramatically because most transient failures resolve automatically without manual intervention. The configurable nature allows tuning retry behavior based on operation criticality and expected duration.

**Implementation**:
```swift
// Simple retry (default config)
let guests = try await NetworkRetry.withRetry {
    try await repository.fetchGuests()
}

// Custom retry config
let config = RetryConfiguration(
    maxAttempts: 5,
    baseDelay: 1.0,
    maxDelay: 10.0,
    jitterFactor: 0.3
)
let data = try await NetworkRetry.withRetry(config: config) {
    try await repository.fetchLargeDataset()
}

// With timeout
let result = try await NetworkRetry.withRetryAndTimeout(
    timeoutSeconds: 30
) {
    try await repository.fetchData()
}
```

**Consequences**:

Application resilience on poor networks improved dramatically, with most transient failures recovering automatically before users notice issues. User experience is significantly better as operations that would have failed now succeed automatically, eliminating the frustration of manual retries. Support burden from network-related error reports decreased substantially because transient issues resolve themselves. The retry logic handles edge cases like WiFi-to-cellular transitions that previously caused consistent failures.

However, operations take longer when failures occur due to retry delays, which can be noticeable on very poor connections where multiple retries are needed. The retry logic must be applied consistently across the entire codebase to provide uniform behavior, requiring vigilance during code review. Operations that genuinely should fail immediately might be delayed by retry attempts before surfacing the error to users. Developers must understand when to use custom configurations versus defaults to balance user experience with operation criticality.

**Status**: Adopted (2024-10)

**Tags**: `networking`, `resilience`, `performance`, `ux`, `error-handling`

**Related PR URLs**: N/A

**Related Files**: `I Do Blueprint/Services/Network/NetworkRetry.swift`, `I Do Blueprint/Domain/Repositories/Live/*.swift`, `ARCHITECTURE_ANALYSIS_2025-10-19.md`

---

### ADR-008: Error Handling Standardization

**Status**: Adopted (Phase 3 Complete)
**Date**: 2025-01
**Context**: Inconsistent error handling across repositories leading to poor debugging and user experience

**Decision**:
All repository methods use a standardized error handling pattern with domain-specific error types including BudgetError, GuestError, and VendorError. The pattern uses an outer do-catch block wrapping the entire operation with error logging before throwing to ensure all errors are captured. All existing caching, retry, and performance tracking logic is preserved to maintain performance optimizations. Repository methods first check caches, perform operations with retry logic, track performance metrics, and then cache results before the outer catch block handles any errors by logging them with contextual information and wrapping them in domain-specific error types.

**Rationale**:
Consistent error handling improves debugging across the entire application by providing predictable error flows. Domain-specific errors enable better error messages that are meaningful to users and developers. Logging before throwing ensures all errors are captured even if higher layers swallow them. Preserving all optimizations maintains the performance characteristics that were carefully tuned in each repository method.

**Implementation**:
```swift
func fetchCategories() async throws -> [BudgetCategory] {
    do {
        let cacheKey = "budget_categories"

        // Check cache
        if let cached: [BudgetCategory] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }

        let client = try getClient()
        let startTime = Date()

        // Fetch with retry
        let categories: [BudgetCategory] = try await RepositoryNetwork.withRetry {
            try await client
                .from("budget_categories")
                .select()
                .execute()
                .value
        }

        let duration = Date().timeIntervalSince(startTime)
        logger.info("Fetched categories in \(duration)s")

        // Cache result
        await RepositoryCache.shared.set(cacheKey, value: categories, ttl: 60)

        return categories
    } catch {
        logger.error("Failed to fetch categories", error: error)
        throw BudgetError.fetchFailed(underlying: error)
    }
}
```

**Progress**:
- ✅ Guest Module: 4 methods standardized
- ✅ Vendor Module: 4 methods standardized
- ✅ Budget Module: 29 methods standardized
- **Total**: 37 methods across 3 modules

**Consequences**:
The standardization achieved consistent error handling at 100% across all standardized modules including Guest, Vendor, and Budget with 37 methods total. Better debugging capabilities were gained through contextual logs that capture operation details at the point of failure. Domain-specific error types enable user-friendly messages that provide actionable information rather than generic error strings. All performance optimizations including caching, retry logic, and performance tracking were preserved during the standardization process.

However, the pattern requires systematic application to remaining modules in the codebase to achieve full consistency. Each module must be carefully reviewed to ensure the error handling wrapper doesn't interfere with existing business logic or error recovery strategies.

**Tags**: `error-handling`, `logging`, `debugging`, `reliability`

---

### ADR-009: Sentry Error Tracking Integration

**Status**: Adopted
**Date**: 2024-12
**Context**: Need for production error monitoring and performance tracking

**Decision**:
Integrate the Sentry SDK for comprehensive error tracking and performance monitoring across the application. Errors are captured at both the repository and store layers to provide visibility into data access failures and state management issues. User action breadcrumbs are added to track navigation and interactions leading up to errors. Performance transactions measure slow operations to detect regressions. All error reports include context-rich information such as operation names, parameters, and application state to aid in debugging and reproduction.

**Rationale**:
Production errors are invisible without proper monitoring infrastructure, making it impossible to proactively address issues before they impact users. Performance regressions are hard to detect without baseline measurements and trend analysis. User behavior context through breadcrumbs significantly aids debugging by showing the sequence of actions leading to an error. Proactive issue detection allows the development team to identify and fix problems before users report them, improving overall application reliability and user satisfaction.

**Implementation**:
```swift
// Error tracking
do {
    try await performOperation()
} catch {
    logger.error("Operation failed", error: error)
    SentryService.shared.captureError(error, context: [
        "operation": "createVendor",
        "vendorType": vendor.type
    ])
    throw error
}

// Performance monitoring
let result = await SentryService.shared.measureAsync(
    name: "load_budget_data",
    operation: "data.fetch"
) {
    try await repository.fetchBudgetData()
}

// Breadcrumbs for user actions
SentryService.shared.addBreadcrumb(
    message: "User navigated to vendor detail",
    category: "navigation",
    data: ["vendorId": vendor.id.uuidString]
)
```

**Consequences**:
The Sentry integration provides production error visibility that was previously unavailable, allowing the team to monitor application health in real-time. Performance regression detection capabilities enable identification of slow operations before they become critical issues. User behavior tracking through breadcrumbs significantly improves debugging efficiency by providing context for error reproduction. Proactive issue detection allows the team to fix problems before users encounter them or before they escalate into critical incidents.

However, the integration requires careful PII scrubbing to ensure user data privacy and compliance with data protection regulations. The team must also actively manage alert fatigue by properly configuring alert thresholds and notification rules to avoid overwhelming developers with non-critical alerts while ensuring critical issues are surfaced immediately.

**Tags**: `monitoring`, `error-tracking`, `performance`, `production`

---

## Coding Rules by Domain

### Swift/SwiftUI Rules

#### R-001: Async/Await Usage

**Title**: Async/Await Usage

**Content**:
All asynchronous operations in the codebase must use the modern async/await pattern exclusively. Completion handlers are forbidden as they lead to callback complexity and make error handling more difficult. For fire-and-forget operations where the result is not needed, use the Task API to launch asynchronous work. When multiple independent operations can run in parallel, use async let to bind results concurrently rather than awaiting them sequentially. All errors in async functions must be handled explicitly using do-catch blocks or try? for optional handling to prevent uncaught errors from crashing the application.

**Category**: Patterns

**Priority**: Critical (1)

**Examples**:
```swift
// ✅ GOOD: Parallel loading
async let summary = repository.fetchBudgetSummary()
async let categories = repository.fetchCategories()
async let expenses = repository.fetchExpenses()

let summaryResult = try await summary
let categoriesResult = try await categories
let expensesResult = try await expenses

// ❌ BAD: Sequential loading
let summary = try await repository.fetchBudgetSummary()
let categories = try await repository.fetchCategories()
let expenses = try await repository.fetchExpenses()
```

**Tags**: swift, concurrency, performance, async-await

**File Patterns**: *.swift, *Store*.swift, *Repository*.swift

---

#### R-002: Actor Isolation

**Title**: Actor Isolation

**Content**:
All UI-related classes including SwiftUI views and ObservableObject stores must be marked with @MainActor to ensure they execute on the main thread. For thread-safe caching and shared mutable state that needs concurrent access, use the actor type which provides automatic synchronization. Pure functions that don't need actor isolation should be marked as nonisolated to avoid unnecessary async context switching. Any types that cross actor boundaries must conform to the Sendable protocol to guarantee thread safety at compile time, which is enforced by Swift 6 strict concurrency checking.

**Category**: Patterns

**Priority**: Critical (1)

**Examples**:
```swift
// ✅ GOOD: MainActor for stores
@MainActor
class BudgetStoreV2: ObservableObject {
    @Published var loadingState: LoadingState<BudgetData> = .idle
}

// ✅ GOOD: Actor for caching
actor RepositoryCache {
    private var cache: [String: CacheEntry] = [:]

    func get<T>(_ key: String, maxAge: TimeInterval) -> T? {
        // Thread-safe access
    }
}

// ✅ GOOD: Nonisolated logger
@MainActor
class BudgetStoreV2: ObservableObject {
    nonisolated let logger = AppLogger.budget
}
```

**Tags**: swift, concurrency, thread-safety, actor, main-actor

**File Patterns**: *Store*.swift, *Repository*.swift, *Cache*.swift

---

#### R-003: Naming Conventions

**Title**: Naming Conventions

**Content**:
Files must follow specific naming patterns with Feature and Purpose clearly identified. SwiftUI views use the pattern FeaturePurposeView.swift such as BudgetOverviewView.swift. All stores must use the FeatureStoreV2.swift pattern with the V2 suffix being mandatory to distinguish from legacy implementations. Repository protocols follow FeatureRepositoryProtocol.swift naming. Extensions use the Type+Purpose.swift pattern to clearly show what type is being extended and why. Variables use camelCase with boolean variables requiring descriptive prefixes like is, has, or should to make their purpose immediately clear. Functions use camelCase with verb prefixes such as fetch, load, create, update, or delete to indicate the action being performed.

**Category**: Patterns

**Priority**: High (2)

**Examples**:
```swift
// ✅ GOOD
BudgetStoreV2.swift
GuestRepositoryProtocol.swift
LiveGuestRepository.swift
Color+Hex.swift
var isLoading: Bool
func fetchGuests() async throws

// ❌ BAD
BudgetStore.swift (missing V2)
GuestRepo.swift (not descriptive)
ColorExtensions.swift (not specific)
var loading: Bool (missing prefix)
func getGuests() async throws (use fetch not get)
```

**Tags**: swift, conventions, organization, naming

**File Patterns**: *.swift

---

#### R-004: MARK Comments

**Title**: MARK Comments

**Content**:
Use MARK comments with the dash separator (// MARK: -) for major sections in Swift files and MARK comments without the dash (// MARK:) for subsections within those major sections. MARK comments are required for all files exceeding 100 lines to aid in navigation and code organization. Standard sections that should be consistently used across the codebase include Properties for state and dependencies, Initialization for init methods, Public Interface for externally-callable methods, Private Helpers for internal implementation details, and Computed Properties for derived values. These sections create a predictable structure that makes it easier for developers to locate specific functionality within large classes.

**Category**: Patterns

**Priority**: Medium (3)

**Example**:
```swift
class BudgetStoreV2: ObservableObject {
    // MARK: - Properties

    // MARK: - Initialization

    // MARK: - Public Interface

    func loadBudgetData() async { }

    // MARK: - Private Helpers

    private func calculateTotals() { }

    // MARK: - Computed Properties

    var totalSpent: Decimal { }
}
```

**Tags**: swift, organization, readability, code-structure

**File Patterns**: *.swift

---

### Database Rules

#### R-005: RLS Policy Pattern

**Title**: RLS Policy Pattern

**Content**:
Row Level Security policies must follow a standardized pattern with one policy per table using the FOR ALL command to cover all operations (SELECT, INSERT, UPDATE, DELETE). Policy names follow the convention couples_manage_own_{resource} to clearly indicate multi-tenant ownership. The USING clause must check couple_id = get_user_couple_id() and the WITH CHECK clause must use the same condition to ensure consistency. Critically, the helper function get_user_couple_id() must wrap auth.uid() in a SELECT subquery like (SELECT auth.uid()) rather than calling auth.uid() directly. This optimization evaluates the authentication check once per query instead of once per row, resulting in 50-90% performance improvement for large datasets where the O(n) direct call becomes O(1) with the subquery wrapper.

**Category**: Security

**Priority**: Critical (1)

**Example**:
```sql
-- ✅ GOOD
CREATE POLICY "couples_manage_own_guests"
  ON guest_list
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- Helper function with optimized auth check
CREATE OR REPLACE FUNCTION get_user_couple_id()
RETURNS uuid AS $$
  SELECT couple_id
  FROM couple_profiles
  WHERE id = (SELECT auth.uid())  -- ✅ With SELECT wrapper
  LIMIT 1;
$$ LANGUAGE sql STABLE;

-- ❌ BAD: Multiple policies
CREATE POLICY "guests_select" ON guest_list FOR SELECT...
CREATE POLICY "guests_insert" ON guest_list FOR INSERT...
CREATE POLICY "guests_update" ON guest_list FOR UPDATE...
CREATE POLICY "guests_delete" ON guest_list FOR DELETE...

-- ❌ BAD: Direct auth.uid() (slow!)
USING (couple_id = auth.uid())  -- Evaluates per row!
```

**Tags**: database, security, rls, performance, postgres, supabase

**File Patterns**: supabase/migrations/*.sql

---

#### R-006: Database Function Security

**Title**: Database Function Security

**Content**:
All database functions must include the SET search_path = '' directive to prevent schema poisoning attacks where malicious users could create schemas that shadow legitimate functions. When functions require elevated privileges to access tables outside the caller's permissions, use SECURITY DEFINER but always document the security rationale in comments explaining why elevated privileges are needed. Never allow mutable search_path values as they create SQL injection vulnerabilities. The empty search_path forces fully-qualified table references like public.table_name, making the function's dependencies explicit and preventing attackers from redirecting operations to malicious schemas.

**Category**: Security

**Priority**: Critical (1)

**Example**:
```sql
-- ✅ GOOD
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''  -- Prevents schema poisoning
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- ❌ BAD: No search_path protection
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Tags**: database, security, sql-injection, postgres, functions

**File Patterns**: supabase/migrations/*.sql

---

#### R-007: Foreign Key Indexes

**Title**: Foreign Key Indexes

**Content**:
Create indexes on all foreign key columns to optimize JOIN operations and foreign key constraint checks. PostgreSQL does not automatically index foreign keys, so manual index creation is required. Index naming follows the pattern idx_{table}_{column} for consistency and easy identification. Unused indexes waste storage and slow down write operations, so perform quarterly audits using pg_stat_user_indexes to identify and remove indexes with zero or minimal usage. Monitor index effectiveness by checking idx_scan counts in pg_stat_user_indexes to ensure indexes are actually being utilized by query plans.

**Category**: Patterns

**Priority**: High (2)

**Example**:
```sql
-- ✅ GOOD: Index on foreign key
CREATE INDEX idx_guest_list_couple_id
ON guest_list(couple_id);

CREATE INDEX idx_expenses_budget_category_id
ON expenses(budget_category_id);

-- Quarterly audit for unused indexes
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as scans,
    idx_tup_read as tuples_read
FROM pg_stat_user_indexes
WHERE idx_scan = 0
    AND indexname NOT LIKE 'pg_%'
ORDER BY pg_relation_size(indexrelid) DESC;
```

**Tags**: database, performance, indexes, postgres, optimization

**File Patterns**: supabase/migrations/*.sql

---

### Security Rules

#### R-008: Password Handling

**Title**: Password Handling

**Content**:
Never store passwords in memory longer than necessary to minimize exposure if memory is dumped or inspected. Use SecureString or similar wrappers for sensitive data that require special handling. Clear sensitive data from memory immediately after use by overwriting the memory region with zeros. Never log passwords, API keys, tokens, or other credentials even in debug builds, as logs may be persisted, transmitted, or accessible to unauthorized parties. Use defer blocks in Swift to ensure cleanup happens even if errors occur.

**Category**: Security

**Priority**: Critical (1)

**Example**:
```swift
// ✅ GOOD: Minimal password retention
func signIn(email: String, password: String) async throws {
    defer {
        // Clear password from memory
        password.withCString { ptr in
            memset(UnsafeMutableRawPointer(mutating: ptr), 0, password.utf8.count)
        }
    }

    try await client.auth.signIn(email: email, password: password)
    logger.infoWithRedactedEmail("auth_login_success for", email: email)
}

// ❌ BAD: Password retained in closure
func signIn(email: String, password: String) async throws {
    Task {
        // Password lives in Task closure indefinitely
        try await client.auth.signIn(email: email, password: password)
    }
}
```

**Tags**: security, passwords, credentials, auth

**File Patterns**: *Auth*.swift, *Login*.swift, *SignIn*.swift

---

#### R-009: URL Validation

**Title**: URL Validation

**Content**:
Validate all external URLs before use to prevent Server-Side Request Forgery (SSRF) attacks and protocol-based exploits. Allow only https://, http://, or local file URLs based on context. Reject dangerous protocols including javascript:, data:, and file:// URLs when loading external resources as these can execute arbitrary code or leak local files. Log all rejected URLs with their schemes for security monitoring and incident response. URL validation must happen before any network request or resource loading to prevent attackers from exploiting protocol handlers or making requests to internal network resources.

**Category**: Security

**Priority**: Critical (1)

**Example**:
```swift
// ✅ GOOD: URL validation
func loadImage(from url: URL) async -> NSImage? {
    guard url.scheme == "https" || url.scheme == "http" || url.isFileURL else {
        logger.warning("Rejected URL with invalid scheme: \(url.scheme ?? "nil")")
        return nil
    }
    // Load image
}

// ❌ BAD: No validation
func loadImage(from url: URL) async -> NSImage? {
    // Accepts javascript:, data:, etc.
    return await fetchImage(url)
}
```

**Tags**: security, validation, ssrf, url-handling

**File Patterns**: *.swift

---

### Performance Rules

#### R-010: Cache Strategy

**Title**: Cache Strategy

**Content**:
Use RepositoryCache for frequently accessed data to reduce network load and improve response times. Always check the cache before making database queries using the tenant-scoped cache key pattern. Invalidate cache entries immediately after mutations (create, update, delete operations) to ensure data consistency across the application. Use appropriate TTL values based on data volatility with 60 seconds for dynamic data that changes frequently like guest lists and budget data, and 300 seconds for static or semi-static data like user profiles and configuration. Monitor cache hit rates through logging to identify optimization opportunities and validate that caching is providing the expected performance benefits.

**Category**: Patterns

**Priority**: High (2)

**Example**:
```swift
// ✅ GOOD: Complete caching pattern
func fetchGuests() async throws -> [Guest] {
    let cacheKey = "guests_\(tenantId.uuidString)"

    // Check cache
    if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
        logger.info("Cache hit: guests")
        return cached
    }

    // Fetch from database
    let guests = try await fetchFromDatabase()

    // Cache result
    await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
    return guests
}

// Invalidate on mutation
func createGuest(_ guest: Guest) async throws -> Guest {
    let created = try await createInDatabase(guest)

    // Invalidate related caches
    let tenantIdString = tenantId.uuidString
    await RepositoryCache.shared.remove("guests_\(tenantIdString)")
    await RepositoryCache.shared.remove("guest_stats_\(tenantIdString)")

    return created
}
```

**Tags**: performance, caching, networking, repository

**File Patterns**: *Repository*.swift, *Cache*.swift

---

#### R-011: List Performance

**Title**: List Performance

**Content**:
Always use the .id() modifier on ForEach items to provide explicit identity for SwiftUI's diffing algorithm, which prevents unnecessary view recreation. Limit initial data loads to 50-100 items to ensure fast rendering and good perceived performance. Implement pagination or infinite scrolling for large lists to avoid loading thousands of items at once which can cause UI freezes. Use LazyVStack and LazyHStack instead of VStack and HStack for large collections, as lazy stacks only create views when they become visible on screen, dramatically reducing memory usage and improving scroll performance.

**Category**: Patterns

**Priority**: High (2)

**Example**:
```swift
// ✅ GOOD: Proper list identity
ForEach(guestStore.filteredGuests) { guest in
    ModernGuestCard(guest: guest)
        .id(guest.id)  // Explicit identity
}

// ✅ GOOD: Lazy loading
ScrollView {
    LazyVStack {
        ForEach(guestStore.filteredGuests) { guest in
            ModernGuestCard(guest: guest)
        }
    }
}

// ❌ BAD: No ID, full recomputation
ForEach(guestStore.filteredGuests) { guest in
    ModernGuestCard(guest: guest)
}
```

**Tags**: performance, swiftui, rendering, lists

**File Patterns**: *View*.swift, *List*.swift

---

## Database Patterns

### Pattern: Multi-Tenant Table Structure

**Use Case**: All user data tables
**Implementation**:

```sql
CREATE TABLE guest_list (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    couple_id UUID NOT NULL,  -- ✅ Tenant ID
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    -- Business columns
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,

    -- Foreign keys
    CONSTRAINT fk_couple FOREIGN KEY (couple_id)
        REFERENCES couple_profiles(id) ON DELETE CASCADE
);

-- ✅ Enable RLS
ALTER TABLE guest_list ENABLE ROW LEVEL SECURITY;

-- ✅ Create policy
CREATE POLICY "couples_manage_own_guests"
  ON guest_list
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());

-- ✅ Create indexes
CREATE INDEX idx_guest_list_couple_id ON guest_list(couple_id);
CREATE INDEX idx_guest_list_created_at ON guest_list(created_at DESC);

-- ✅ Create trigger
CREATE TRIGGER update_guest_list_updated_at
    BEFORE UPDATE ON guest_list
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

**Tables Using This Pattern**: 50+ (all multi-tenant tables)

---

### Pattern: Updated_at Trigger

**Use Case**: Automatic timestamp management
**Implementation**:

```sql
-- ✅ Secure trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''  -- Security: Prevents schema poisoning
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Apply to table
CREATE TRIGGER update_{table}_updated_at
    BEFORE UPDATE ON {table_name}
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

**Applied To**: 42+ tables

---

## Security Patterns

### Pattern: RLS Helper Functions

**Use Case**: Reusable tenant scoping
**Implementation**:

```sql
-- Get current user's couple_id
CREATE OR REPLACE FUNCTION get_user_couple_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT couple_id
  FROM couple_profiles
  WHERE id = (SELECT auth.uid())  -- ✅ With SELECT wrapper
  LIMIT 1;
$$;

-- Check if user can access specific tenant
CREATE OR REPLACE FUNCTION can_user_access_tenant(tenant_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM couple_profiles
    WHERE id = (SELECT auth.uid())
      AND couple_id = tenant_id
  );
$$;
```

---

### Pattern: Admin Role-Based Access

**Use Case**: Admin operations without hardcoded UUIDs
**Implementation**:

```sql
-- Helper function
CREATE OR REPLACE FUNCTION auth.has_role(required_role text)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM users_roles ur
    JOIN roles r ON ur.role_id = r.id
    WHERE ur.user_id = (SELECT auth.uid())
      AND r.name = required_role
  );
$$;

-- Admin policy example
CREATE POLICY "admins_manage_everything"
  ON admin_audit_log
  FOR ALL
  USING (auth.has_role('admin') OR auth.has_role('super_admin'));
```

---

## Performance Patterns

### Pattern: Query Optimization with Indexes

**Use Case**: Fast foreign key lookups
**Implementation**:

```sql
-- ✅ GOOD: Composite index for common query
CREATE INDEX idx_expenses_couple_category
ON expenses(couple_id, budget_category_id);

-- Query benefits from composite index
SELECT * FROM expenses
WHERE couple_id = $1
  AND budget_category_id = $2;

-- ✅ GOOD: Partial index for common filter
CREATE INDEX idx_guests_attending
ON guest_list(couple_id)
WHERE rsvp_status = 'attending';

-- Query benefits from partial index
SELECT * FROM guest_list
WHERE couple_id = $1
  AND rsvp_status = 'attending';
```

**Guidelines**:
- Create indexes on foreign keys
- Use composite indexes for common multi-column queries
- Use partial indexes for frequently filtered columns
- Monitor index usage quarterly
- Remove unused indexes

---

### Pattern: Efficient Pagination

**Use Case**: Large result sets
**Implementation**:

```swift
struct PaginatedResult<T: Codable>: Codable {
    let items: [T]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool
}

func fetchGuestsPaginated(page: Int = 1, pageSize: Int = 50) async throws -> PaginatedResult<Guest> {
    let offset = (page - 1) * pageSize

    let guests: [Guest] = try await supabase.database
        .from("guest_list")
        .select()
        .eq("couple_id", value: tenantId)
        .order("created_at", ascending: false)
        .range(from: offset, to: offset + pageSize - 1)
        .execute()
        .value

    let totalCount: Int = try await supabase.database
        .from("guest_list")
        .select("*", head: true, count: .exact)
        .eq("couple_id", value: tenantId)
        .execute()
        .count ?? 0

    return PaginatedResult(
        items: guests,
        totalCount: totalCount,
        page: page,
        pageSize: pageSize,
        hasMore: totalCount > offset + pageSize
    )
}
```

---

## Testing Patterns

### Pattern: Mock Repository

**Use Case**: Unit testing stores
**Implementation**:

```swift
class MockGuestRepository: GuestRepositoryProtocol {
    var guests: [Guest] = []
    var shouldThrowError = false
    var throwError: Error = NSError(domain: "MockError", code: 1)

    func fetchGuests() async throws -> [Guest] {
        if shouldThrowError {
            throw throwError
        }
        return guests
    }

    func createGuest(_ guest: Guest) async throws -> Guest {
        if shouldThrowError {
            throw throwError
        }
        guests.append(guest)
        return guest
    }
}

// Usage in tests
@MainActor
final class GuestStoreV2Tests: XCTestCase {
    var mockRepository: MockGuestRepository!
    var store: GuestStoreV2!

    override func setUp() async throws {
        mockRepository = MockGuestRepository()
        store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }
    }

    func test_loadGuests_success() async throws {
        // Given
        mockRepository.guests = [.makeTest()]

        // When
        await store.loadGuests()

        // Then
        XCTAssertEqual(store.loadingState.data?.count, 1)
    }
}
```

---

### Pattern: Test Data Builders

**Use Case**: Consistent test data
**Implementation**:

```swift
extension Guest {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        firstName: String = "Test",
        lastName: String = "Guest",
        email: String = "test@example.com",
        rsvpStatus: RSVPStatus = .pending
    ) -> Guest {
        Guest(
            id: id,
            coupleId: coupleId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: nil,
            rsvpStatus: rsvpStatus,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// Usage
let guest = Guest.makeTest()
let attendingGuest = Guest.makeTest(rsvpStatus: .attending)
let specificGuest = Guest.makeTest(
    id: testId,
    firstName: "John",
    lastName: "Doe"
)
```

---

## Error Handling Patterns

### Pattern: Domain-Specific Errors

**Use Case**: User-friendly error messages
**Implementation**:

```swift
enum BudgetError: Error, LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case tenantContextMissing
    case invalidAllocation

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to load budget data: \(error.localizedDescription)"
        case .createFailed(let error):
            return "Failed to create item: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update item: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete item: \(error.localizedDescription)"
        case .tenantContextMissing:
            return "No wedding selected. Please sign in."
        case .invalidAllocation:
            return "Budget allocation exceeds 100% of total budget."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed, .createFailed, .updateFailed, .deleteFailed:
            return "Please check your internet connection and try again."
        case .tenantContextMissing:
            return "Please sign in to access your wedding planning data."
        case .invalidAllocation:
            return "Adjust your budget allocations to total 100% or less."
        }
    }
}
```

---

### Pattern: Error Logging with Context

**Use Case**: Debugging production issues
**Implementation**:

```swift
func createGuest(_ guest: Guest) async throws -> Guest {
    do {
        let client = try getClient()

        let created: Guest = try await RepositoryNetwork.withRetry {
            try await client
                .from("guest_list")
                .insert(guest)
                .select()
                .single()
                .execute()
                .value
        }

        logger.info("Created guest: \(created.fullName)")

        // Invalidate caches
        let tenantIdString = tenantId.uuidString
        await RepositoryCache.shared.remove("guests_\(tenantIdString)")

        return created
    } catch {
        logger.error("Failed to create guest", error: error, context: [
            "guestName": "\(guest.firstName) \(guest.lastName)",
            "tenantId": tenantId.uuidString
        ])

        SentryService.shared.captureError(error, context: [
            "operation": "createGuest",
            "guestFirstName": guest.firstName,
            "guestLastName": guest.lastName,
            "tenantId": tenantId.uuidString
        ])

        throw GuestError.createFailed(underlying: error)
    }
}
```

---

## Store Management Patterns

### Pattern: LoadingState Enum

**Use Case**: Consistent async operation tracking
**Implementation**:

```swift
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)

    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var hasError: Bool {
        if case .error = self { return true }
        return false
    }

    var data: T? {
        if case .loaded(let data) = self { return data }
        return nil
    }

    var error: Error? {
        if case .error(let error) = self { return error }
        return nil
    }
}

// Usage in views
switch store.loadingState {
case .idle:
    Text("Tap to load")
case .loading:
    ProgressView()
case .loaded(let guests):
    GuestList(guests: guests)
case .error(let error):
    ErrorView(error: error)
}
```

---

### Pattern: Optimistic Updates with Rollback

**Use Case**: Responsive UI with error recovery
**Implementation**:

```swift
func updateGuest(_ guest: Guest) async {
    // 1. Save original state
    guard case .loaded(var data) = loadingState,
          let index = data.guests.firstIndex(where: { $0.id == guest.id }) else {
        return
    }

    let original = data.guests[index]

    // 2. Optimistic update
    data.guests[index] = guest
    loadingState = .loaded(data)

    // 3. Attempt server update
    do {
        let updated = try await repository.updateGuest(guest)

        // 4. Update with server response
        if case .loaded(var data) = loadingState,
           let idx = data.guests.firstIndex(where: { $0.id == guest.id }) {
            data.guests[idx] = updated
            loadingState = .loaded(data)
        }

        logger.info("Updated guest: \(updated.fullName)")
    } catch {
        // 5. Rollback on error
        if case .loaded(var data) = loadingState,
           let idx = data.guests.firstIndex(where: { $0.id == guest.id }) {
            data.guests[idx] = original
            loadingState = .loaded(data)
        }

        logger.error("Failed to update guest, rolled back", error: error)
        SentryService.shared.captureError(error, context: [
            "operation": "updateGuest",
            "guestId": guest.id.uuidString
        ])

        self.error = GuestError.updateFailed(underlying: error)
    }
}
```

---

## Migration Best Practices

### Pattern: Safe Schema Changes

**Use Case**: Database migrations without downtime
**Implementation**:

```sql
-- ✅ GOOD: Safe migration pattern

-- Step 1: Add new column as nullable
ALTER TABLE guest_list
ADD COLUMN new_column TEXT NULL;

-- Step 2: Backfill data (if needed)
UPDATE guest_list
SET new_column = 'default_value'
WHERE new_column IS NULL;

-- Step 3: Add constraint (after deploy completes)
ALTER TABLE guest_list
ALTER COLUMN new_column SET NOT NULL;

-- ❌ BAD: Breaking change
ALTER TABLE guest_list
ADD COLUMN new_column TEXT NOT NULL;  -- Fails if data exists!
```

---

### Pattern: Migration Testing Checklist

**Use Case**: Ensuring migration safety
**Checklist**:

```markdown
## Pre-Migration
- [ ] Export current schema
- [ ] Export current RLS policies
- [ ] Test migration on copy of production data
- [ ] Verify no breaking changes for client apps
- [ ] Document rollback procedure

## Migration Execution
- [ ] Apply migration to database
- [ ] Verify schema changes applied
- [ ] Verify RLS policies updated
- [ ] Test CRUD operations manually
- [ ] Monitor database logs for errors

## Post-Migration
- [ ] Run automated test suite
- [ ] Verify data integrity
- [ ] Check performance (query times)
- [ ] Monitor error rates
- [ ] Update documentation
```

---

## Summary Statistics

### Codebase Metrics
- **Total Swift Files**: 470
- **Repository Files**: 19 (Live + Mock)
- **Store Files**: 9 (V2 pattern)
- **Database Tables**: 73 (50+ multi-tenant)
- **RLS Policies**: 50+ (1 per multi-tenant table)
- **Test Files**: 22 (4.7% coverage - needs improvement)

### Pattern Adoption
- ✅ Repository Pattern: 100% (all data access)
- ✅ StoreV2 Pattern: 100% (all stores)
- ✅ RLS Policies: 100% (all multi-tenant tables)
- ✅ Error Handling: 37 methods standardized (3 modules)
- ✅ UUID Best Practices: 100% (all repositories)
- ✅ Database Function Security: 100% (all functions)
- ⚠️ Test Coverage: 4.7% (target: 80%)

### Security Hardening
- ✅ RLS enabled on all multi-tenant tables
- ✅ Search path hardening (42+ functions)
- ✅ Auth.uid() optimization (32+ policies)
- ✅ Foreign key indexes (all relationships)
- ✅ URL validation (all external sources)
- ⚠️ Password memory clearing (needs review)

### Performance Optimizations
- ✅ Repository caching (60-300s TTL)
- ✅ Network retry (exponential backoff)
- ✅ RLS optimization (SELECT wrapper)
- ✅ Foreign key indexes (all FKs)
- ⚠️ List rendering optimization (needs .id() modifiers)
- ⚠️ Computed property memoization (needs review)

---

## Quick Reference

### Essential Commands

```bash
# Build project
xcodebuild -workspace "I Do Blueprint.xcworkspace" -scheme "I Do Blueprint" build

# Run tests
xcodebuild test -workspace "I Do Blueprint.xcworkspace" -scheme "I Do Blueprint"

# Apply migration
supabase migration up

# Check RLS policies
SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public';

# Check function security
SELECT routine_name, security_type FROM information_schema.routines WHERE routine_schema = 'public';

# Monitor cache hit rate
SELECT * FROM pg_stat_database WHERE datname = 'postgres';
```

### Code Review Checklist

```markdown
## General
- [ ] Follows naming conventions
- [ ] Uses appropriate MARK comments
- [ ] No hardcoded values (use constants)
- [ ] No force unwrapping (!)
- [ ] Proper error handling

## Architecture
- [ ] Uses repository pattern (not direct Supabase)
- [ ] Accesses stores via AppStores singleton
- [ ] Never creates new store instances
- [ ] Uses dependency injection
- [ ] Follows V2 store pattern

## Database
- [ ] Passes UUIDs directly to queries
- [ ] Uses (SELECT auth.uid()) in RLS
- [ ] Functions have SET search_path = ''
- [ ] Foreign keys have indexes
- [ ] Cache invalidation on mutations

## Security
- [ ] RLS policy for new tables
- [ ] No hardcoded credentials
- [ ] URL validation for external sources
- [ ] Sensitive data cleared from memory
- [ ] Error messages don't leak data

## Performance
- [ ] Uses RepositoryCache
- [ ] Uses NetworkRetry
- [ ] Parallel async operations with async let
- [ ] List items have .id() modifiers
- [ ] Appropriate cache TTL

## Testing
- [ ] Unit tests for new functionality
- [ ] Mock repository provided
- [ ] Test data builders used
- [ ] Error cases tested
- [ ] RLS isolation tested
```

---

**End of Document**

This knowledge base should be regularly updated as new patterns emerge and the codebase evolves. For questions or clarifications, refer to:
- `best_practices.md` - Detailed coding guidelines
- `docs/database/RLS_POLICIES.md` - Complete RLS policy documentation
- `ARCHITECTURE_ANALYSIS_2025-10-19.md` - Architecture analysis and issues
- Linear issues (JES-*) - Implementation examples and lessons learned
