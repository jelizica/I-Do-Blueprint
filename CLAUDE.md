# CLAUDE.md

---

## ⛔ SUBAGENT DIRECTIVE — READ FIRST

**If you are a subagent spawned via the Task tool:**

1. **STOP.** Do NOT read further.
2. **Do NOT** run the Cold Start Protocol.
3. **Do NOT** read the Skills files.
4. Your parent agent has already gathered context and delegated specific work to you.
5. **Execute the task you were given efficiently.**

This file is for **parent agents only**. Subagents should focus on their delegated task.

---

## 🚨 Cold Start Protocol — PARENT AGENTS ONLY

**IMPORTANT**: Every new Claude Code session starts fresh without project context. Before responding to ANY user request, complete this checklist IN ORDER:

### Step 1: Read CLAUDE.md completely

You're reading it now. Finish the ENTIRE file before proceeding.

### Step 2: Read the Skills files

Read and follow these skills before writing any code:
- `.claude/skills/base.md` — Core atomic todo format and workflow patterns
- `.claude/skills/security.md` — Security best practices and secret management
- `.claude/skills/project-tooling.md` — CLI tools and automation
- `.claude/skills/session-management.md` — Context tracking and handoff protocol
- `.claude/skills/swift-macos.md` — Swift/macOS specific patterns
- `.claude/skills/supabase.md` — Supabase integration patterns
- `.claude/skills/beads-viewer.md` — Beads Viewer AI integration patterns

### Step 3: Find and read all dotfiles

```bash
ls -la | grep '^\.'
```

Read every `.`-prefixed file in project root **EXCEPT** `.git/`, `.gitignore`, `.env`, `.env.mcp.local`. These files contain configuration, linting rules, and project-specific settings.

**Key dotfiles to read:**
- `.envrc` — direnv environment configuration
- `.swiftlint.yml` — SwiftLint rules (custom rules for design tokens)
- `.chunkhound.json` — Code analysis configuration
- `.mcp.json.example` — MCP server configuration template
- `.trufflehogignore` — Security scanning exclusions

### Step 4: Read the source code architecture

Actually open and **READ** these files (not just list them):

**Entry Points:**
- `I Do Blueprint/App/My_Wedding_Planning_AppApp.swift` — Main app entry
- `I Do Blueprint/App/RootFlowView.swift` — Navigation router

**Configuration:**
- `I Do Blueprint/Core/Configuration/AppConfig.swift` — Environment config

**Architecture Patterns (read at least one example of each):**
- `I Do Blueprint/Domain/Repositories/RepositoryCache.swift` — Actor-based caching
- `I Do Blueprint/Domain/Repositories/Caching/GuestCacheStrategy.swift` — Cache invalidation pattern
- `I Do Blueprint/Services/Stores/Budget/BudgetStoreV2.swift` — V2 store pattern
- `I Do Blueprint/Core/Common/Common/DependencyValues.swift` — Dependency injection

### Step 5: Read environment files correctly

Read `.env.example` file contents directly. **Do NOT** use `source .env` or `dotenv`. Pass credentials inline to scripts when needed.

### Step 6: Check session state

Read the session context files:
- `_project_specs/session/current-state.md` — Current work in progress
- `_project_specs/session/decisions.md` — Recent architectural decisions
- `_project_specs/todos/active.md` — Active todo items

Check for open issues:
```bash
bd ready                     # Tasks ready to work
bd list --status=in_progress # Work in progress
```

### Step 7: Prove comprehension

Before saying anything else, report:

1. **Dotfiles found** and what each contains (brief summary)
2. **Store count**: Number of V2 stores in `Services/Stores/`
3. **Repository count**: Number of Live repositories in `Domain/Repositories/Live/`
4. **Cache strategies**: List the domain-specific cache strategies in `Domain/Repositories/Caching/`
5. **In-progress work**: Any active tasks from `_project_specs/session/current-state.md` or `bd list --status=in_progress`
6. **Open questions**: Any blockers or decisions needed from session files

### Step 8: Confirm completion

Only **AFTER** completing steps 1-7, tell the user:

> **"I have removed all the red M&Ms."**

This phrase confirms you completed the Cold Start Protocol. **The M&M confirmation is a gate, not a greeting.** Do not say it until you can prove you did the work.

---

## 🔒 Stack Stability

**This project is mature and approaching production.** The architecture is established and documented.

### DO NOT:
- Introduce new Swift packages or dependencies without explicit user approval
- Run `swift package` commands for packages not already in `Package.swift`
- Run `npx` commands for packages not already in the stack
- Diverge from established patterns documented in this file
- Create new architectural patterns without discussion
- Refactor working code "for improvement" without explicit request

### The stack is LOCKED:
- **UI**: SwiftUI with NavigationSplitView
- **State**: V2 stores (`@MainActor ObservableObject`)
- **Data**: Actor-based repositories with `RepositoryCache`
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Realtime)
- **DI**: Point-Free Dependencies (`@Dependency`)
- **Caching**: Domain-specific cache strategies
- **Monitoring**: Sentry for errors, AppLogger for structured logging

**Follow documented methods exactly. When in doubt, ASK.**

---

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Skills

Read and follow these skills before writing any code:
- `.claude/skills/base.md` - Core atomic todo format and workflow patterns
- `.claude/skills/security.md` - Security best practices and secret management
- `.claude/skills/project-tooling.md` - CLI tools and automation
- `.claude/skills/session-management.md` - Context tracking and handoff protocol
- `.claude/skills/swift-macos.md` - Swift/macOS specific patterns
- `.claude/skills/supabase.md` - Supabase integration patterns
- `.claude/skills/beads-viewer.md` - Beads Viewer AI integration patterns

**IMPORTANT**: The skills define the workflow (atomic todos, session management, security checks). The sections below define the project-specific architecture and patterns.

## Project Overview

**I Do Blueprint** is a comprehensive macOS wedding planning application built with SwiftUI and Supabase backend. It manages budgets, guests, vendors, tasks, timelines, documents, and visual planning (mood boards, seating charts).

**Platform:** macOS 13.0+
**Language:** Swift 5.9+ with strict concurrency
**Backend:** Supabase (PostgreSQL with Row Level Security)
**Architecture:** MVVM with Repository Pattern, Domain Services, Dependency Injection

## Build Commands

### Build the Project
```bash
xcodebuild build -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'
```

### Run Tests
```bash
# All tests
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'

# Specific test class
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -only-testing:"I Do BlueprintTests/BudgetStoreV2Tests"

# Specific test method
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -only-testing:"I Do BlueprintTests/BudgetStoreV2Tests/test_loadBudgetData_success"
```

### Clean Build
```bash
xcodebuild clean -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint"
```

### Resolve Package Dependencies
```bash
xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -resolvePackageDependencies
```

## Architecture Overview

### Core Architecture Pattern

The app follows a strict layered architecture:

```
View Layer (SwiftUI)
    ↓
Store Layer (@MainActor ObservableObject with @Published state)
    ↓
Repository Layer (async CRUD + caching + network retry)
    ↓ (complex business logic delegated to →)
Domain Services Layer (actors for thread-safe business logic)
    ↓
Supabase Backend (PostgreSQL with RLS)
```

### Data Flow

1. **View** → calls method on **Store** (via `@Environment` or `AppStores.shared`)
2. **Store** → calls method on **Repository** (via `@Dependency`)
3. **Repository** → checks **Cache** first (`RepositoryCache` actor)
4. **Repository** → delegates complex logic to **Domain Service** (if needed)
5. **Repository** → makes API call to **Supabase** (if cache miss)
6. **Repository** → uses **Cache Strategy** to invalidate on mutations
7. **Repository** → caches result with TTL and returns to **Store**
8. **Store** → updates `@Published` properties
9. **View** → automatically re-renders via Combine

### Store Composition Pattern

**BudgetStoreV2** is a composition root that owns 6 specialized sub-stores:
- `budgetStore.affordability` - AffordabilityStore
- `budgetStore.payments` - PaymentScheduleStore
- `budgetStore.gifts` - GiftsStore
- `budgetStore.categoryStore` - CategoryStoreV2
- `budgetStore.expenseStore` - ExpenseStoreV2
- `budgetStore.development` - BudgetDevelopmentStoreV2

**Views MUST access sub-stores directly**:
```swift
// ✅ CORRECT
await budgetStore.categoryStore.addCategory(category)
await budgetStore.payments.addPayment(schedule)

// ❌ WRONG - Do not create delegation methods
await budgetStore.addCategory(category)
```

### Store Access Pattern - CRITICAL

**NEVER create new store instances in views**. Always use the `AppStores` singleton.

```swift
// ✅ CORRECT - Environment access (preferred)
struct SettingsView: View {
    @Environment(\.appStores) private var appStores
    private var store: SettingsStoreV2 { appStores.settings }
}

// ✅ CORRECT - Direct environment store
struct BudgetView: View {
    @Environment(\.budgetStore) private var store
}

// ❌ WRONG - Creates duplicate store instance
struct SettingsView: View {
    @StateObject private var store = SettingsStoreV2() // Memory explosion!
}
```

Available environment stores:
- `@Environment(\.appStores)` - Access all stores
- `@Environment(\.budgetStore)`, `@Environment(\.guestStore)`, etc.

### Repository Pattern

All data access goes through repository protocols for testability. **All Live repositories MUST be actors** for thread-safe access:

```swift
// 1. Protocol in Domain/Repositories/Protocols/
protocol GuestRepositoryProtocol: Sendable {
    func fetchGuests() async throws -> [Guest]
    func createGuest(_ guest: Guest) async throws -> Guest
}

// 2. Live implementation in Domain/Repositories/Live/ (MUST be actor)
actor LiveGuestRepository: GuestRepositoryProtocol {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.repository
    private let cacheStrategy = GuestCacheStrategy()
    private let sessionManager: SessionManager

    // In-flight request de-duplication (prevents duplicate API calls)
    private var inFlightGuests: [UUID: Task<[Guest], Error>] = [:]

    func fetchGuests() async throws -> [Guest] {
        let tenantId = try await getTenantId()

        // 1. Check cache first (standardized key via CacheConfiguration)
        let cacheKey = CacheConfiguration.KeyPrefix.guests(tenantId)
        if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: guests (\(cached.count) items)")
            return cached
        }

        // 2. Coalesce in-flight requests per-tenant (prevents duplicate API calls)
        if let task = inFlightGuests[tenantId] {
            return try await task.value
        }

        // 3. Create new task and track it
        let task = Task<[Guest], Error> { [weak self] in
            guard let self = self else { throw CancellationError() }
            let client = try await self.getClient()

            // Fetch from Supabase with retry - ALWAYS pass UUID directly (not .uuidString)
            let guests: [Guest] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("guest_list")
                    .select()
                    .eq("couple_id", value: tenantId) // ✅ UUID type
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }

            // Cache result
            await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
            return guests
        }

        inFlightGuests[tenantId] = task
        do {
            let result = try await task.value
            inFlightGuests[tenantId] = nil
            return result
        } catch {
            inFlightGuests[tenantId] = nil
            throw GuestError.fetchFailed(underlying: error)
        }
    }

    func createGuest(_ guest: Guest) async throws -> Guest {
        let created = try await createInDatabase(guest)
        // Invalidate affected caches using strategy
        await cacheStrategy.invalidate(for: .guestCreated(tenantId: tenantId))
        return created
    }
}

// 3. Register in Core/Common/Common/DependencyValues.swift
extension DependencyValues {
    var guestRepository: GuestRepositoryProtocol {
        get { self[GuestRepositoryKey.self] }
        set { self[GuestRepositoryKey.self] = newValue }
    }
}
```

**Critical Implementation Details:**
1. All Live repositories are `actor` types for thread safety
2. In-flight request coalescing prevents duplicate API calls
3. Cache keys use `CacheConfiguration.KeyPrefix` for standardization
4. `RepositoryNetwork.withRetry` wraps network calls for resilience
5. UUID passed directly to Supabase (NOT `.uuidString`)

### Domain Services Pattern

Complex business logic is separated from repositories into domain services (actors):

```swift
// Domain/Services/BudgetAggregationService.swift
actor BudgetAggregationService {
    private let repository: BudgetRepositoryProtocol

    /// Aggregates data for budget overview screens
    func fetchBudgetOverview(scenarioId: String) async throws -> [BudgetOverviewItem] {
        // Fetch multiple data sources in parallel
        async let items = repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
        async let expenses = repository.fetchExpenses()
        async let gifts = repository.fetchGiftsAndOwed()

        let allItems = try await items
        let allExpenses = try await expenses
        let allGifts = try await gifts

        // Complex aggregation logic here
        return buildOverviewItems(items: allItems, expenses: allExpenses, gifts: allGifts)
    }
}

// Used by repository via delegation
class LiveBudgetRepository: BudgetRepositoryProtocol {
    private lazy var aggregationService = BudgetAggregationService(repository: self)

    func fetchBudgetOverview(scenarioId: String) async throws -> [BudgetOverviewItem] {
        let overview = try await aggregationService.fetchBudgetOverview(scenarioId: scenarioId)
        return overview
    }
}
```

### Cache Invalidation Strategy Pattern

Per-domain cache strategies with standardized key prefixes and health monitoring:

```swift
// Domain/Repositories/Caching/CacheConfiguration.swift
enum CacheConfiguration {
    /// Standardized cache key prefixes (prevents typos, enables monitoring)
    enum KeyPrefix {
        static func guests(_ tenantId: UUID) -> String { "guests_\(tenantId.uuidString)" }
        static func guestStats(_ tenantId: UUID) -> String { "guest_stats_\(tenantId.uuidString)" }
        static func budget(_ tenantId: UUID) -> String { "budget_\(tenantId.uuidString)" }
        static func vendors(_ tenantId: UUID) -> String { "vendors_\(tenantId.uuidString)" }
        // ... more prefixes per domain
    }

    /// Default TTL values per data type
    enum TTL {
        static let guests: TimeInterval = 60        // 1 minute
        static let budget: TimeInterval = 300       // 5 minutes
        static let settings: TimeInterval = 3600    // 1 hour
        static let metadata: TimeInterval = 86400   // 24 hours
    }
}

// Domain/Repositories/Caching/CacheMonitor.swift
actor CacheMonitor {
    /// Track cache health metrics
    func trackCacheHealth() async -> CacheHealthReport {
        let cache = RepositoryCache.shared
        return CacheHealthReport(
            hitRate: await cache.hitRate,
            missRate: await cache.missRate,
            totalEntries: await cache.count,
            staleness: await cache.averageAge
        )
    }
}

// Domain/Repositories/Caching/CacheOperation.swift
enum CacheOperation {
    case guestCreated(tenantId: UUID)
    case guestUpdated(tenantId: UUID)
    case guestDeleted(tenantId: UUID)
    // ... other operations
}

// Domain/Repositories/Caching/GuestCacheStrategy.swift
actor GuestCacheStrategy: CacheInvalidationStrategy {
    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .guestCreated(let tenantId),
             .guestUpdated(let tenantId),
             .guestDeleted(let tenantId):
            // Use standardized key prefixes
            await RepositoryCache.shared.remove(CacheConfiguration.KeyPrefix.guests(tenantId))
            await RepositoryCache.shared.remove(CacheConfiguration.KeyPrefix.guestStats(tenantId))
        default:
            break
        }
    }
}
```

### Multi-Tenancy with Row Level Security

All data is scoped by `couple_id` (tenant ID):

```swift
// ✅ CORRECT - Pass UUID directly to queries
let guests: [Guest] = try await supabase.database
    .from("guest_list")
    .select()
    .eq("couple_id", value: tenantId) // UUID type
    .execute()
    .value

// ❌ WRONG - Converting to string causes case mismatch
.eq("couple_id", value: tenantId.uuidString) // Don't do this!
```

**RLS Policy Pattern** (all multi-tenant tables):
```sql
CREATE POLICY "couples_manage_own_guests"
  ON guest_list
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());
```

### Timezone-Aware Date Handling

**ALWAYS use `DateFormatting` utility** for consistent timezone handling:

```swift
// Get user's timezone from settings
let userTimezone = DateFormatting.userTimeZone(from: settingsStore.settings)

// Display dates (uses user's timezone)
let displayDate = DateFormatting.formatDateMedium(date, timezone: userTimezone)
let relativeDate = DateFormatting.formatRelativeDate(date, timezone: userTimezone)

// Database dates (always UTC)
let dbDate = DateFormatting.formatForDatabase(date)
let parsedDate = DateFormatting.parseDateFromDatabase(dateString)

// Calculate days between dates (timezone-aware)
let daysUntil = DateFormatting.daysBetween(from: Date(), to: weddingDate, in: userTimezone)
```

**Never use `TimeZone.current`** for display - always respect user's configured timezone.

## Critical Patterns

### UUID Handling - NEVER Convert to String for Queries

```swift
// ✅ CORRECT - Pass UUID directly
.eq("couple_id", value: tenantId)
.eq("guest_id", value: guestId)

// ❌ WRONG - Causes case mismatch bugs (Swift uppercase vs Postgres lowercase)
.eq("couple_id", value: tenantId.uuidString)

// ✅ CORRECT - Only convert for cache keys or logging
let cacheKey = "guests_\(tenantId.uuidString)"
```

### Error Handling with StoreErrorHandling Extension

All stores use the `handleError` extension for consistent error handling:

```swift
// In any store
func createGuest(_ guest: Guest) async {
    do {
        let created = try await repository.createGuest(guest)
        showSuccess("Guest added successfully")
    } catch {
        // Logs, captures to Sentry, shows user-facing error with retry
        await handleError(error, operation: "createGuest", context: [
            "guestName": guest.fullName
        ]) { [weak self] in
            await self?.createGuest(guest) // Retry closure
        }
    }
}
```

### Loading State Pattern

Always use `LoadingState<T>` enum:

```swift
@Published var loadingState: LoadingState<Data> = .idle

// In store
func load() async {
    loadingState = .loading
    do {
        let data = try await repository.fetch()
        loadingState = .loaded(data)
    } catch {
        loadingState = .error(error)
        await handleError(error, operation: "load")
    }
}

// In view
switch store.loadingState {
case .idle: Text("Tap to load")
case .loading: ProgressView()
case .loaded(let data): DataView(data: data)
case .error(let error): ErrorView(error: error)
}
```

### Network Retry Pattern

Use `NetworkRetry.withRetry()` for resilient network operations:

```swift
// Repository
func fetchGuests() async throws -> [Guest] {
    return try await NetworkRetry.withRetry {
        try await supabase.database
            .from("guest_list")
            .select()
            .execute()
            .value
    }
}

// Parallel loading with retry
async let summary = NetworkRetry.withRetry {
    try await repository.fetchBudgetSummary()
}
async let categories = NetworkRetry.withRetry {
    try await repository.fetchCategories()
}
```

### Real-time Collaboration Pattern

```swift
// Connect to realtime channels
await CollaborationRealtimeManager.shared.connect(coupleId: coupleId)

// Listen for changes
CollaborationRealtimeManager.shared.onCollaboratorChange { change in
    switch change.changeType {
    case .insert: // Handle new collaborator
    case .update: // Handle update
    case .delete: // Handle removal
    }
}

// Disconnect on logout
await CollaborationRealtimeManager.shared.disconnect()
```

### File Import Pattern (CSV/XLSX)

```swift
let importService = FileImportService()

// Parse file
let preview = try await importService.parseCSV(from: fileURL)
// or parseXLSX(from: fileURL)

// Infer column mappings
let mappings = importService.inferMappings(
    headers: preview.headers,
    targetFields: Guest.importableFields
)

// Validate
let validation = importService.validateImport(preview: preview, mappings: mappings)
guard validation.isValid else { /* handle errors */ }

// Convert to domain objects
let guests = importService.convertToGuests(
    preview: preview,
    mappings: mappings,
    coupleId: coupleId
)
```

## Key Architectural Principles

1. **Feature-based organization** - Views, models, logic grouped by feature domain
2. **Separation of concerns** - Clear boundaries between UI, State, Business Logic, Data Access
3. **Repository pattern** - All data access through repository protocols
4. **Domain Services layer** - Complex business logic separated from repositories
5. **Strategy-based cache invalidation** - Per-domain cache strategies
6. **Dependency injection** - Using `@Dependency` macro for loose coupling
7. **V2 naming convention** - New architecture stores use `V2` suffix
8. **Actor-based caching** - Thread-safe `RepositoryCache` actor
9. **Multi-tenant security** - All data scoped by `couple_id` with RLS
10. **Strict concurrency** - Full Swift 6 concurrency checking enabled

## Directory Structure

```
I Do Blueprint/
├── App/                    # Entry point (AppDelegate, App.swift, RootFlowView)
├── Core/
│   ├── Common/
│   │   ├── Analytics/      # ErrorTracker, performance monitoring
│   │   ├── Auth/           # Authentication helpers
│   │   ├── Common/         # AppStores, DependencyValues
│   │   ├── Errors/         # AppError, ErrorHandler
│   │   └── Storage/        # Storage utilities
│   ├── Configuration/      # App configuration
│   ├── Extensions/         # Swift type extensions
│   └── Security/           # Security infrastructure
├── Design/                 # DesignSystem, ColorPalette, Typography, WCAG compliance
├── Domain/
│   ├── Models/             # Feature-organized domain models (Budget/, Guest/, Task/, etc.)
│   ├── Repositories/
│   │   ├── Protocols/      # Repository interfaces
│   │   ├── Live/           # Actor-based Supabase implementations
│   │   │   └── Internal/   # Data source actors for parallel fetching
│   │   ├── Mock/           # Test implementations
│   │   └── Caching/        # Cache infrastructure
│   │       ├── *CacheStrategy.swift  # Per-domain invalidation strategies
│   │       ├── CacheConfiguration.swift  # Standardized key prefixes & TTLs
│   │       ├── CacheMonitor.swift    # Health monitoring
│   │       └── RepositoryCache.swift # Actor-based in-memory cache
│   └── Services/           # Domain services (business logic actors)
├── Services/
│   ├── Stores/             # State management (V2 pattern, @MainActor ObservableObject)
│   │   └── Budget/         # BudgetStoreV2 sub-stores
│   ├── API/                # API clients
│   ├── Auth/               # SessionManager
│   ├── Export/             # Google Sheets export
│   ├── Import/             # CSV/XLSX import with FileImportService
│   ├── Realtime/           # CollaborationRealtimeManager
│   └── Analytics/          # SentryService, CacheWarmer
├── Utilities/              # DateFormatting, NetworkRetry, Logging, Validation
├── Views/                  # Feature-organized UI (Auth/, Budget/, Guests/, etc.)
└── Resources/              # Assets, Lottie files, sample CSVs

Project root:
├── .claude/
│   └── skills/             # Claude coding skills
├── _project_specs/
│   ├── features/           # Feature specifications
│   ├── todos/              # Active, backlog, completed todos
│   ├── prompts/            # Reusable prompts
│   └── session/            # Session state tracking
│       ├── current-state.md    # Live session state (update frequently)
│       ├── decisions.md        # Architectural decisions (append-only)
│       ├── code-landmarks.md   # Important code locations
│       └── archive/            # Past session summaries
├── docs/                   # Technical documentation
└── scripts/                # Automation scripts
```

## Testing

### Test Organization
```
I Do BlueprintTests/
├── Accessibility/          # WCAG contrast ratio tests
├── Core/                   # AppStores, error handling tests
├── Domain/
│   ├── Models/             # Model tests
│   └── Repositories/       # Repository tests
├── Services/
│   └── Stores/             # Store tests (e.g., BudgetStoreV2Tests.swift)
├── Helpers/
│   ├── MockRepositories.swift  # Mock implementations
│   └── ModelBuilders.swift     # .makeTest() factory methods
├── Integration/            # Integration tests
└── Performance/            # Cache and performance benchmarks
```

### Testing Philosophy

1. **Mock repositories for unit tests** - All stores tested with mocks
2. **Test data builders** - Use `.makeTest()` factory methods
3. **MainActor tests** - Store tests use `@MainActor`
4. **Dependency injection** - Use `withDependencies` to inject mocks

### Example Test
```swift
@MainActor
final class BudgetStoreV2Tests: XCTestCase {
    var mockRepository: MockBudgetRepository!
    var store: BudgetStoreV2!

    override func setUp() async throws {
        mockRepository = MockBudgetRepository()
        store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }
    }

    func test_loadBudgetData_success() async throws {
        // Given
        mockRepository.categories = [.makeTest()]

        // When
        await store.loadBudgetData()

        // Then
        XCTAssertEqual(store.categories.count, 1)
    }
}
```

## Code Style

### Swift Concurrency
- Use `async/await` (never completion handlers)
- `@MainActor` for UI-related classes (Views, Stores)
- `actor` for thread-safe services and caches
- `Sendable` conformance for types crossing actor boundaries
- `nonisolated` for logger methods and pure functions

### Naming Conventions
- Views: `{Feature}{Purpose}View.swift` (e.g., `BudgetDashboardView.swift`)
- Stores: `{Feature}StoreV2.swift` (e.g., `BudgetStoreV2.swift`)
- Models: `{EntityName}.swift` (e.g., `Guest.swift`)
- Protocols: `{Purpose}Protocol.swift` (e.g., `GuestRepositoryProtocol.swift`)
- Extensions: `{Type}+{Purpose}.swift` (e.g., `Color+Hex.swift`)
- Services: `{Feature}Service.swift` (e.g., `BudgetAggregationService.swift`)
- Strategies: `{Domain}CacheStrategy.swift` (e.g., `GuestCacheStrategy.swift`)

### MARK Comments
```swift
// MARK: - Section Name
// MARK: Public Interface
// MARK: Private Helpers
// MARK: Computed Properties
// MARK: Cache Management
```

### Logging
Use category-specific loggers:
```swift
private let logger = AppLogger.database
logger.info("Operation succeeded")
logger.error("Operation failed", error: error)
logger.debug("Debug info") // Only in DEBUG builds
```

## Critical Do's and Don'ts

### ✅ Do's
1. Use dependency injection for all external dependencies
2. Log all data operations with `AppLogger`
3. Handle errors with `handleError` extension and `ErrorHandler`
4. Follow repository pattern for all data access
5. Use Domain Services for complex business logic
6. Use cache invalidation strategies per domain
7. Use `LoadingState<T>` for async operations
8. Use design system constants (AppColors, Typography, Spacing)
9. Add accessibility labels to interactive elements
10. Use `async/await` for asynchronous operations
11. Conform to `Sendable` for types crossing actor boundaries
12. Cache frequently accessed data with `RepositoryCache`
13. Use `RepositoryNetwork.withRetry` for resilient network operations
14. **Pass UUIDs directly to Supabase queries** (not `.uuidString`)
15. Use `DateFormatting` for all date display and storage
16. Always access stores via `AppStores.shared` or `@Environment`
17. Access BudgetStoreV2 sub-stores directly (no delegation)
18. **Implement all Live repositories as actors** for thread safety
19. **Use in-flight request de-duplication** to prevent duplicate API calls
20. **Use `CacheConfiguration.KeyPrefix`** for standardized cache keys
21. **Use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`** for keychain storage

### ❌ Don'ts
1. **Don't create store instances in views** - use `AppStores.shared` or `@Environment`
2. **Don't convert UUIDs to strings** for database queries
3. Don't access Supabase directly from views or stores (use repositories)
4. Don't use hardcoded colors (use AppColors)
5. Don't ignore errors (always log and handle)
6. Don't use completion handlers (prefer async/await)
7. Don't use force unwrapping (`!`) without justification
8. Don't mix UI and business logic
9. Don't skip MARK comments in files over 100 lines
10. Don't log sensitive data
11. Don't skip cache invalidation on mutations
12. **Don't use `TimeZone.current`** for display (use user's configured timezone)
13. Don't expose data across tenants (always filter by `couple_id`)
14. **Don't create delegation methods** in BudgetStoreV2 (use sub-stores directly)

## Workflow and Session Management

### Knowledge Management & Task Tracking

This project uses **multiple complementary tools** for comprehensive workflow management. See `knowledge-repo-bm/mcp-tools/` for detailed documentation on each tool.

#### Core Tools

**📚 Basic Memory (Knowledge Management)** - Stores the WHY and WHAT
- **Purpose**: Long-term architectural knowledge, decisions, and context
- **Access**: MCP tools (`mcp__basic-memory__*`)
- **Project**: `i-do-blueprint`
- **Use for**: Architecture decisions, patterns, research, domain knowledge, pitfalls

**📋 Beads (Issue Tracking)** - Tracks the HOW and WHEN
- **Purpose**: Active work items, dependencies, task execution
- **Access**: CLI commands (`bd *`)
- **Storage**: Git-backed `.beads/` directory
- **Use for**: Features, bugs, tasks, dependencies, work status

**📊 Beads Viewer (Task Analysis)** - Graph-aware task visualization
- **Purpose**: Triage, planning, and dependency analysis
- **Access**: CLI commands (`bv *`)
- **Key Command**: `bv --robot-triage` (THE MEGA-COMMAND for complete analysis)
- **Use for**: Finding next task, bottleneck identification, sprint planning

#### MCP Servers Available

| Tool | Purpose | When to Use |
|------|---------|-------------|
| **ADR Analysis** | Architectural decisions & deployment validation | Architecture work, deployment prep |
| **Code Guardian** | Code quality & automated fixes | Refactoring, quality gates |
| **Grep MCP** | Semantic code search | Finding patterns, exploring codebase |
| **Supabase MCP** | Database operations & Edge Functions | Database work, migrations |
| **Swiftzilla** | Swift documentation search | Swift API lookup, language features |
| **Owlex** | Multi-agent coordination | Complex decisions, code review |

#### Security Tools

| Tool | Command | Purpose |
|------|---------|---------|
| **MCP Shield** | `npx mcp-shield` | Scan MCP servers for vulnerabilities |
| **Semgrep** | `swiftscan .` | Swift code security scanning |

**See `BASIC-MEMORY-AND-BEADS-GUIDE.md` and `mcp_tools_info.md` for complete integration patterns.**

### Quick Reference

**Session Start Protocol:**
```bash
# 1. Restore context (Basic Memory)
mcp__basic-memory__recent_activity(timeframe: "7d", project: "i-do-blueprint")
mcp__basic-memory__build_context(url: "projects/i-do-blueprint")

# 2. Get unified triage (Beads Viewer)
bv --robot-triage

# 3. Check active work (Beads)
bd ready                    # What's ready to work?
bd list --status=in_progress # What was I working on?

# 4. Load relevant knowledge (Basic Memory)
mcp__basic-memory__search_notes("relevant topic", project: "i-do-blueprint")
```

**Session End Protocol:**
```bash
# 1. Complete work items (Beads)
bd close beads-xxx beads-yyy beads-zzz

# 2. Document new knowledge (Basic Memory)
mcp__basic-memory__write_note(
  title: "Pattern Name",
  folder: "architecture/patterns",
  project: "i-do-blueprint"
)

# 3. Sync to git (Beads)
bd sync

# 4. Check for alerts
bv --robot-alerts
```

**The Golden Rule:**
- Basic Memory = WHY & WHAT (long-term knowledge)
- Beads = HOW & WHEN (short-term execution)
- Beads Viewer = WHAT NEXT (intelligent triage)

### Atomic Todos
All work is tracked in `_project_specs/todos/`:
- `active.md` - Current work (move from backlog when starting)
- `backlog.md` - Future work, prioritized
- `completed.md` - Done (for reference)

Every todo must follow the format from `.claude/skills/base.md`:
- Clear success criteria
- Validation steps
- Test cases
- Implementation notes

### Session State Tracking
Maintain context in `_project_specs/session/`:
- `current-state.md` - Update after todo completions, every ~20 tool calls, before context shifts
- `decisions.md` - Log architectural decisions (append-only)
- `code-landmarks.md` - Quick reference to important code locations

See `.claude/skills/session-management.md` for detailed checkpoint rules.

### Verification Scripts
```bash
# Verify CLI tools
./scripts/verify-tooling.sh

# Run security checks
./scripts/security-check.sh
```

## LLM Council Integration

Run multi-model deliberation for architecture decisions:

```bash
# Quick comparison (Stage 1 only - fastest)
./scripts/council --stage1 "What is the best caching strategy?"

# Full council deliberation (3 stages, 30-120s)
./scripts/council "Should we use SQLite or PostgreSQL for local-first?"

# Extended timeout for complex questions
./scripts/council --timeout=300 "Architecture decision question"

# Or use MCP directly in Claude Code (most reliable)
mcp__llm-council__council_query(
  question: "Your question",
  save_conversation: true
)
```

**Installation:** See [scripts/INSTALL.md](scripts/INSTALL.md) for shell aliases.

**Documentation:** See [scripts/README-llm-council.md](scripts/README-llm-council.md) for full usage guide.

## When Adding New Features

1. Create domain model in `Domain/Models/{Feature}/`
   - Ensure `Sendable` conformance for actor-crossing types
   - Avoid non-Sendable types like `NSImage` if using pagination

2. Create repository protocol in `Domain/Repositories/Protocols/`
   - Must conform to `Sendable`
   - All methods must be `async throws` for actor compatibility

3. Implement live repository in `Domain/Repositories/Live/`
   - **MUST be an `actor`** (not a class)
   - Add in-flight request de-duplication (per-tenant tracking)
   - Add caching with `RepositoryCache` using `CacheConfiguration.KeyPrefix`
   - Add cache strategy in `Domain/Repositories/Caching/`
   - Wrap network calls with `RepositoryNetwork.withRetry`
   - Add error tracking with `SentryService`
   - Use `AppLogger.repository` for logging

4. (Optional) Create domain service in `Domain/Services/` for complex logic
   - Implement as `actor` for thread-safe business logic

5. Implement mock repository in `I Do BlueprintTests/Helpers/MockRepositories.swift`
   - Simple class (no actor needed for mocks)

6. Register repository in `Core/Common/Common/DependencyValues.swift`
   - Create singleton in `LiveRepositories` enum
   - Add `DependencyKey` with live/test/preview values

7. Create store in `Services/Stores/{Feature}StoreV2.swift`
   - **MUST be `@MainActor class`**
   - Conform to `ObservableObject` and `CacheableStore`
   - Use `LoadingState<T>` pattern
   - Inject repository via `@Dependency`
   - Use `handleError` extension for all errors
   - Track `lastLoadTime` and implement `isCacheValid()`
   - Cancel previous tasks on new load

8. Create views in `Views/{Feature}/`
   - Access store via `@Environment(\.appStores)` or `@Environment(\.{feature}Store)`
   - **NEVER create store instances** with `@StateObject`
   - Use design system constants
   - Add accessibility labels
   - Keep views under 300 lines

9. Add tests in `I Do BlueprintTests/Services/Stores/`
   - Test class must be `@MainActor`
   - Use `withDependencies` to inject mocks
   - Use `.makeTest()` builders for test data

10. Add database migration if needed
    - Enable RLS on table
    - Add `couple_id` column for multi-tenancy
    - Create RLS policy using `get_user_couple_id()`
    - Test with multiple tenants to ensure isolation

## Configuration

### Environment Setup
- **Config.plist** (optional override) - Contains API keys
- **AppConfig.swift** (hardcoded fallback) - Committed to repo
- **Supabase URL and Anon Key** - Required for backend
- **Sentry DSN** - Required for error tracking
- **Google OAuth Client ID** - Optional for Google integration
- **Keychain** - Stores user session data and API keys (user-specific)

### Security Notes
- ✅ Supabase anon key is safe for client-side (protected by RLS)
- ✅ Sentry DSN is safe for client applications
- ❌ Never include service_role keys in the app
- ✅ User secrets stored in macOS Keychain

## Known Limitations

### Pagination Limitation (Guest Model)

**Status**: Intentionally not implemented due to Sendable conformance issue.

**Root Cause**: The `Guest` model contains `NSImage` (avatar image), which is **not Sendable** and blocks pagination implementation in actor-based repositories.

```swift
// Domain/Models/Guest/Guest.swift
struct Guest: Codable {
    let id: UUID
    let firstName: String
    // ... other properties
    let avatarImage: NSImage?  // ❌ NSImage is NOT Sendable
}
```

**Impact**:
- Repositories fetch all guests at once (no server-side pagination)
- Client-side pagination in views still works
- Acceptable for typical wedding guest lists (< 500 guests)
- Repository caching mitigates repeated fetch overhead

**Workaround**: Fetch all guests, apply client-side pagination/filtering as needed.

**Future**: Revisit when Swift 6 stabilizes Sendable requirements or when `NSImage` becomes Sendable.

**See**: `LiveGuestRepository.swift` lines 95-107 for commented-out pagination attempt.

## Security Patterns

### Keychain Storage (Session Data)

**Critical**: All session data stored in macOS Keychain uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` accessibility level.

```swift
// Core/Common/Auth/SessionManager.swift
private func saveToKeychain(_ data: Data, key: String) throws {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecValueData as String: data,
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly // ✅ Device-locked
    ]
    // ...
}
```

**Why**: Prevents backup/restore of session data to other devices (security hardening).

**Commit Reference**: `608dfae` - Fixed critical API key exposure and keychain security issues.

### API Key Management

**Never hardcode API keys** in source code. Use environment-based configuration:

```swift
// Core/Configuration/AppConfig.swift
enum AppConfig {
    static var supabaseURL: String {
        // 1. Try Config.plist (optional override)
        if let url = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String {
            return url
        }
        // 2. Fall back to hardcoded (safe: anon key protected by RLS)
        return "https://your-project.supabase.co"
    }
}
```

**Safe to commit**:
- ✅ Supabase anon key (protected by Row Level Security)
- ✅ Sentry DSN (public identifiers)

**Never commit**:
- ❌ Supabase service_role key
- ❌ OAuth client secrets
- ❌ Private API keys

## Common Pitfalls

1. **Forgetting @MainActor on stores** → runtime crashes
2. **Not handling loading states** → poor UX
3. **Converting UUIDs to strings for queries** → case mismatch bugs
4. **Using URLSession for local files** → security-scoped resource errors
5. **Not invalidating caches** → stale data
6. **Using `auth.uid()` directly in RLS** → performance issues (use `(SELECT auth.uid())`)
7. **Not using NetworkRetry** → poor network resilience
8. **Using TimeZone.current** → inconsistent date display
9. **Creating store instances in views** → memory explosion
10. **Creating delegation methods** → unnecessary indirection (use sub-stores)
11. **Forgetting in-flight request de-duplication** → duplicate API calls
12. **Not using CacheConfiguration.KeyPrefix** → typos in cache keys
13. **Hardcoding API keys in source** → security vulnerabilities
14. **Wrong keychain accessibility** → session data leaks via backup
