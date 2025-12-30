# Frequently Asked Questions (FAQ)

## Table of Contents

- [Setup & Installation](#setup--installation)
- [Architecture & Patterns](#architecture--patterns)
- [MCP Tools](#mcp-tools)
- [Development Workflow](#development-workflow)
- [Common Errors](#common-errors)
- [Testing](#testing)
- [Database & Backend](#database--backend)
- [Performance & Optimization](#performance--optimization)

---

## Setup & Installation

### Q: What are the minimum requirements to build and run I Do Blueprint?

**A:** You need:
- **macOS 13.0+** (Ventura or later)
- **Xcode 14.0+** with Swift 5.9+
- **Xcode Command Line Tools**: `xcode-select --install`
- **GitHub CLI** (authenticated): `brew install gh && gh auth login`
- **Supabase CLI** (authenticated): `brew install supabase/tap/supabase && supabase login`

Optional but recommended for AI-assisted development:
- **Beads** (issue tracking): `uvx beads-mcp`
- **Basic Memory** (knowledge management): `uvx basic-memory mcp`

### Q: Do I need to configure Supabase credentials?

**A:** No! The app includes hardcoded Supabase configuration in `AppConfig.swift` and works out-of-the-box. The Supabase anon key is safe for client-side use because all data is protected by Row Level Security (RLS) policies.

If you want to test against a different Supabase instance, create `I Do Blueprint/Config.plist` with your custom values.

### Q: Why does the build fail with "Cannot find 'SupabaseClient' in scope"?

**A:** Swift Package Manager dependencies aren't resolved. Run:
```bash
xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -resolvePackageDependencies
```

### Q: How do I set up MCP servers for AI-assisted development?

**A:** See `docs/MCP_SETUP.md` for comprehensive setup instructions. Quick start:

1. **For Claude Code CLI**: MCP servers are configured in `~/.config/claude/settings.json`
2. **For Agent Deck**: MCP servers are configured in `~/.agent-deck/config.toml`

Available MCP servers: Supabase, Basic Memory, Beads, Code Guardian, ADR Analysis, Grep MCP, Swiftzilla. See `docs/mcp_tools_info.md` for details.

---

## Architecture & Patterns

### Q: What architecture pattern does I Do Blueprint use?

**A:** The app follows a strict **layered architecture**:

```
View Layer (SwiftUI)
    ↓
Store Layer (@MainActor ObservableObject)
    ↓
Repository Layer (async CRUD + caching)
    ↓
Domain Services Layer (business logic actors)
    ↓
Supabase Backend (PostgreSQL with RLS)
```

See `CLAUDE.md` for complete architecture documentation.

### Q: What is the Repository Pattern and why do we use it?

**A:** All data access goes through **repository protocols** for:
- **Testability**: Easy to mock for unit tests
- **Separation of concerns**: Views don't know about Supabase
- **Caching**: Repositories manage cache strategies
- **Network resilience**: Built-in retry logic with `NetworkRetry`
- **Consistency**: Standardized error handling and logging

Example:
```swift
protocol GuestRepositoryProtocol: Sendable {
    func fetchGuests() async throws -> [Guest]
    func createGuest(_ guest: Guest) async throws -> Guest
}
```

### Q: What is a Store and how is it different from a Repository?

**A:**
- **Store** (`@MainActor ObservableObject`): Manages UI state, publishes changes to views via `@Published` properties
- **Repository**: Handles data access, caching, and network operations

**Data flow**: View → Store → Repository → Domain Service → Supabase

### Q: What is the V2 naming convention?

**A:** Stores with the `V2` suffix (e.g., `BudgetStoreV2`) follow the new architecture pattern:
- Use dependency injection (`@Dependency`)
- Follow repository pattern
- Use actor-based caching (`RepositoryCache`)
- Use strategy-based cache invalidation
- Use `LoadingState<T>` enum
- Use `handleError` extension for consistent error handling

### Q: What is Store Composition and why does BudgetStoreV2 have sub-stores?

**A:** **BudgetStoreV2** is a composition root that owns 6 specialized sub-stores:
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

// ❌ WRONG - Do not create delegation methods
await budgetStore.addCategory(category)
```

### Q: How do I access stores in views?

**A:** **NEVER create new store instances in views**. Always use `AppStores` singleton:

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

// ❌ WRONG - Creates duplicate store instance (memory explosion!)
struct SettingsView: View {
    @StateObject private var store = SettingsStoreV2()
}
```

### Q: What are Domain Services and when should I use them?

**A:** **Domain Services** are actors that handle complex business logic:
- **When to use**: Multi-source data aggregation, complex calculations, orchestration
- **Examples**: `BudgetAggregationService`, `BudgetAllocationService`
- **Benefits**: Thread-safe, testable, keeps repositories focused on CRUD

```swift
actor BudgetAggregationService {
    func fetchBudgetOverview(scenarioId: String) async throws -> [BudgetOverviewItem] {
        // Fetch multiple sources in parallel
        async let items = repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
        async let expenses = repository.fetchExpenses()
        // Complex aggregation logic
    }
}
```

### Q: What is the Cache Invalidation Strategy Pattern?

**A:** Per-domain cache strategies for maintainable cache management:

```swift
actor GuestCacheStrategy: CacheInvalidationStrategy {
    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .guestCreated(let tenantId):
            await RepositoryCache.shared.remove("guests_\(tenantId.uuidString)")
            await RepositoryCache.shared.remove("guest_stats_\(tenantId.uuidString)")
        }
    }
}
```

Each repository uses a strategy to invalidate related caches on mutations.

---

## MCP Tools

### Q: What are MCP servers and why should I use them?

**A:** **Model Context Protocol (MCP)** servers provide specialized capabilities to AI coding assistants like Claude Code. They extend what AI can do by giving it access to:
- Project knowledge graphs (Basic Memory)
- Issue tracking (Beads)
- Database operations (Supabase MCP)
- Code search (Grep MCP)
- Documentation (Swiftzilla)
- Code quality validation (Code Guardian)

See `docs/mcp_tools_info.md` for comprehensive documentation.

### Q: When should I use Basic Memory vs Beads?

**A:**
- **Basic Memory**: Store **WHY and WHAT** - architectural decisions, patterns, pitfalls, research
  - Long-term knowledge that persists across sessions
  - Markdown files with semantic graph
  - MCP tools: `mcp__basic-memory__*`

- **Beads**: Track **HOW and WHEN** - tasks, bugs, dependencies, execution
  - Active work items with dependencies
  - Git-backed JSONL in `.beads/`
  - CLI commands: `bd *`

**The Golden Rule**: Basic Memory for knowledge, Beads for execution.

### Q: How do I use Basic Memory and Beads together?

**A:** They complement each other perfectly:

```bash
# Session start
bd ready  # Find available work (Beads)
mcp__basic-memory__recent_activity(timeframe: "7d")  # Restore context

# Research before implementing
mcp__basic-memory__search_notes("repository pattern")  # Learn patterns

# Track implementation
bd update beads-xxx --status=in_progress  # Claim work

# Document after completing
mcp__basic-memory__write_note(title: "New Pattern")  # Store knowledge
bd close beads-xxx  # Complete task
bd sync  # Push to git
```

See `docs/BASIC-MEMORY-AND-BEADS-GUIDE.md` for detailed workflow patterns.

### Q: Which MCP server should I use for different tasks?

**A:**
- **Architecture & Patterns**: Basic Memory
- **Active Tasks**: Beads
- **Database Queries**: Supabase MCP
- **Code Search**: Grep MCP
- **Swift Documentation**: Swiftzilla
- **Code Quality**: Code Guardian
- **Deployment Validation**: ADR Analysis

### Q: How do I check which MCP servers are available?

**A:**
```bash
# For Agent Deck
agent-deck mcp list

# For Claude Code
cat ~/.config/claude/settings.json | jq '.mcpServers'
```

---

## Development Workflow

### Q: What is the recommended workflow for starting a new session?

**A:**
```bash
# 1. Check active work (Beads)
bd ready  # What's ready to work?
bd list --status=in_progress  # What was I working on?

# 2. Restore context (Basic Memory - if using MCP)
mcp__basic-memory__recent_activity(timeframe: "7d", project: "i-do-blueprint")
mcp__basic-memory__build_context(url: "projects/i-do-blueprint")

# 3. Select task
bd show beads-xxx  # Review details
bd update beads-xxx --status=in_progress  # Claim it

# 4. Research (if needed)
mcp__basic-memory__search_notes("relevant topic")

# 5. Build and test
xcodebuild build -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'
```

### Q: What is the session end protocol?

**A:**
```bash
# 1. Complete work
bd close beads-xxx beads-yyy beads-zzz  # Close all completed issues

# 2. Document new knowledge (if significant)
mcp__basic-memory__write_note(...)

# 3. Check git status
git status

# 4. Stage and commit code changes
git add <files>
git commit -m "description"

# 5. Sync beads
bd sync

# 6. Push to remote
git push
```

**CRITICAL**: Work is not done until pushed to remote.

### Q: How do I create tasks for AI agents to work on?

**A:**
```bash
# Create task
bd create "Implement feature X" --type=feature --priority=1

# Create with dependencies
bd create "Add tests for X" --type=task --priority=1
bd dep add beads-test beads-feature  # Test depends on feature

# Check ready work
bd ready
```

Priority: 0-4 (0=critical, 2=medium, 4=backlog)
Types: `task`, `bug`, `feature`, `epic`, `chore`

### Q: How do I handle multi-session work?

**A:** Use Beads for persistence:
```bash
# End of session 1
bd update beads-xxx --status=in_progress --notes="Completed API, need to add tests"
bd sync

# Start of session 2
bd list --status=in_progress  # See what was in progress
bd show beads-xxx  # Read notes from last session
```

---

## Common Errors

### Q: I'm getting "UUID case mismatch" errors in database queries. Why?

**A:** **NEVER convert UUIDs to strings** for Supabase queries. Swift's `.uuidString` produces uppercase UUIDs, but Postgres stores lowercase.

```swift
// ✅ CORRECT - Pass UUID directly
.eq("couple_id", value: tenantId)

// ❌ WRONG - Causes case mismatch
.eq("couple_id", value: tenantId.uuidString)
```

Only convert for cache keys or logging: `"guests_\(tenantId.uuidString)"`

### Q: Why am I seeing memory explosion or duplicate data?

**A:** You're probably creating store instances in views instead of using `AppStores.shared` or `@Environment`.

```swift
// ❌ WRONG - Each view creates its own store instance
struct MyView: View {
    @StateObject private var store = BudgetStoreV2()
}

// ✅ CORRECT
struct MyView: View {
    @Environment(\.budgetStore) private var store
}
```

### Q: My dates are displaying in the wrong timezone. How do I fix this?

**A:** **Always use `DateFormatting` utility**, never `TimeZone.current`:

```swift
// Get user's configured timezone
let userTimezone = DateFormatting.userTimeZone(from: settingsStore.settings)

// Display dates
let displayDate = DateFormatting.formatDateMedium(date, timezone: userTimezone)

// Database dates (always UTC)
let dbDate = DateFormatting.formatForDatabase(date)
```

### Q: Network requests are failing intermittently. What should I do?

**A:** Use `NetworkRetry.withRetry()` for resilient network operations:

```swift
func fetchGuests() async throws -> [Guest] {
    return try await NetworkRetry.withRetry {
        try await supabase.database
            .from("guest_list")
            .select()
            .execute()
            .value
    }
}
```

### Q: I'm getting "security-scoped resource" errors when reading local files. Why?

**A:** Don't use `URLSession` for local files. Use `Data(contentsOf:)` or `FileManager`:

```swift
// ✅ CORRECT
let data = try Data(contentsOf: fileURL)

// ❌ WRONG - URLSession for local files causes security errors
let (data, _) = try await URLSession.shared.data(from: fileURL)
```

### Q: How do I handle errors consistently across stores?

**A:** Use the `handleError` extension:

```swift
func createGuest(_ guest: Guest) async {
    do {
        let created = try await repository.createGuest(guest)
    } catch {
        // Logs, captures to Sentry, shows user-facing error
        await handleError(error, operation: "createGuest", context: [
            "guestName": guest.fullName
        ]) { [weak self] in
            await self?.createGuest(guest)  // Retry closure
        }
    }
}
```

### Q: Caches aren't being invalidated after mutations. What's wrong?

**A:** Ensure your repository uses a cache strategy:

```swift
class LiveGuestRepository: GuestRepositoryProtocol {
    private let cacheStrategy = GuestCacheStrategy()

    func createGuest(_ guest: Guest) async throws -> Guest {
        let created = try await createInDatabase(guest)
        // Invalidate caches
        await cacheStrategy.invalidate(for: .guestCreated(tenantId: tenantId))
        return created
    }
}
```

---

## Testing

### Q: How do I run tests?

**A:**
```bash
# All tests
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'

# Specific test class
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -only-testing:"I Do BlueprintTests/BudgetStoreV2Tests"

# Specific test method
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -only-testing:"I Do BlueprintTests/BudgetStoreV2Tests/test_loadBudgetData_success"
```

### Q: How do I write unit tests for stores?

**A:** Use mock repositories and dependency injection:

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

### Q: Where are mock repositories defined?

**A:** In `I Do BlueprintTests/Helpers/MockRepositories.swift`

### Q: How do I create test data?

**A:** Use `.makeTest()` factory methods defined in `I Do BlueprintTests/Helpers/ModelBuilders.swift`:

```swift
let guest = Guest.makeTest(fullName: "John Doe", email: "john@example.com")
let budget = BudgetCategory.makeTest(name: "Venue", allocated: 5000)
```

---

## Database & Backend

### Q: How does multi-tenancy work?

**A:** All data is scoped by `couple_id` (tenant ID) with **Row Level Security (RLS)** policies:

```sql
CREATE POLICY "couples_manage_own_guests"
  ON guest_list
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());
```

Every repository query automatically filters by the authenticated user's `couple_id`.

### Q: How do I query Supabase from repositories?

**A:**
```swift
// Fetch with tenant filtering
let guests: [Guest] = try await supabase.database
    .from("guest_list")
    .select()
    .eq("couple_id", value: tenantId)  // ✅ Pass UUID directly
    .order("created_at", ascending: false)
    .execute()
    .value
```

### Q: How do I listen to real-time database changes?

**A:** Use `CollaborationRealtimeManager`:

```swift
// Connect
await CollaborationRealtimeManager.shared.connect(coupleId: coupleId)

// Listen
CollaborationRealtimeManager.shared.onCollaboratorChange { change in
    switch change.changeType {
    case .insert: // Handle new data
    case .update: // Handle update
    case .delete: // Handle deletion
    }
}

// Disconnect
await CollaborationRealtimeManager.shared.disconnect()
```

### Q: How do I import CSV/XLSX files?

**A:** Use `FileImportService`:

```swift
let importService = FileImportService()

// Parse
let preview = try await importService.parseCSV(from: fileURL)

// Infer mappings
let mappings = importService.inferMappings(
    headers: preview.headers,
    targetFields: Guest.importableFields
)

// Validate
let validation = importService.validateImport(preview: preview, mappings: mappings)

// Convert
let guests = importService.convertToGuests(
    preview: preview,
    mappings: mappings,
    coupleId: coupleId
)
```

---

## Performance & Optimization

### Q: How does caching work?

**A:** The app uses **actor-based caching** (`RepositoryCache`) with TTL:

```swift
// Check cache first
let cacheKey = "guests_\(tenantId.uuidString)"
if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
    return cached
}

// Fetch from network
let guests = try await fetchFromSupabase()

// Cache result
await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
```

### Q: How do I invalidate caches?

**A:** Use cache strategies per domain:

```swift
await cacheStrategy.invalidate(for: .guestCreated(tenantId: tenantId))
```

The strategy knows which cache keys to invalidate based on the operation.

### Q: How do I warm up caches on app launch?

**A:** Use `CacheWarmer`:

```swift
// In AppDelegate or app initialization
await CacheWarmer.shared.warmCriticalCaches(for: coupleId)
```

### Q: How do I handle loading states in views?

**A:** Use `LoadingState<T>` enum:

```swift
@Published var loadingState: LoadingState<[Guest]> = .idle

// In store
func load() async {
    loadingState = .loading
    do {
        let data = try await repository.fetch()
        loadingState = .loaded(data)
    } catch {
        loadingState = .error(error)
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

---

## Additional Resources

- **Architecture**: See `CLAUDE.md`
- **MCP Tools**: See `docs/mcp_tools_info.md`
- **Workflow**: See `docs/BASIC-MEMORY-AND-BEADS-GUIDE.md` and `docs/QUICK_START_GUIDE.md`
- **Glossary**: See `docs/GLOSSARY.md`
- **API Documentation**: See `docs/API_DOCUMENTATION.md`
- **Code Navigation**: See `_project_specs/session/code-landmarks.md`
- **Swift Patterns**: See `.claude/skills/swift-macos.md`

---

*Last Updated: 2025-12-29*
