# Glossary

A comprehensive reference of technical terms, architecture concepts, and domain-specific terminology used in the I Do Blueprint project.

## Table of Contents

- [Architecture & Design Patterns](#architecture--design-patterns)
- [Swift & Concurrency](#swift--concurrency)
- [Data & State Management](#data--state-management)
- [Backend & Database](#backend--database)
- [MCP (Model Context Protocol)](#mcp-model-context-protocol)
- [Development Tools](#development-tools)
- [Wedding Planning Domain](#wedding-planning-domain)
- [Testing & Quality](#testing--quality)

---

## Architecture & Design Patterns

### Actor
A Swift concurrency primitive that provides thread-safe access to mutable state. Actors automatically serialize access to their properties and methods, preventing data races.

```swift
actor RepositoryCache {
    private var cache: [String: CachedItem] = [:]

    func get<T>(_ key: String) -> T? {
        // Thread-safe access automatically enforced
    }
}
```

### Cache Strategy
A pattern for managing cache invalidation based on domain operations. Each domain (Guests, Budget, etc.) has its own cache strategy that knows which cache keys to invalidate for different operations.

**Example**: `GuestCacheStrategy` invalidates guest-related caches when guests are created, updated, or deleted.

### Dependency Injection
A design pattern where dependencies are provided to a class rather than created internally. This project uses the `@Dependency` property wrapper for loose coupling and testability.

```swift
@Dependency(\.guestRepository) private var repository
```

### Domain Service
An actor that encapsulates complex business logic that doesn't belong in repositories. Domain Services handle multi-source aggregation, complex calculations, and orchestration.

**Example**: `BudgetAggregationService` combines data from multiple repositories to build budget overview screens.

### MVVM (Model-View-ViewModel)
The architectural pattern used by this app:
- **Model**: Domain models (Guest, Budget, etc.)
- **View**: SwiftUI views
- **ViewModel**: Stores (BudgetStoreV2, GuestStoreV2, etc.)

### Repository Pattern
A design pattern that abstracts data access behind protocol interfaces. Repositories handle CRUD operations, caching, network retry, and error handling.

**Benefits**:
- Testability (easy to mock)
- Separation of concerns
- Consistent error handling
- Centralized caching logic

### Store
A `@MainActor` `ObservableObject` that manages UI state and coordinates between views and repositories. Stores publish state changes via `@Published` properties, triggering view updates.

**Naming**: Stores following the new architecture use the `V2` suffix (e.g., `BudgetStoreV2`).

### Store Composition
A pattern where a parent store owns specialized sub-stores for different concerns. **BudgetStoreV2** uses this pattern with 6 sub-stores:
- `affordability` - AffordabilityStore
- `payments` - PaymentScheduleStore
- `gifts` - GiftsStore
- `categoryStore` - CategoryStoreV2
- `expenseStore` - ExpenseStoreV2
- `development` - BudgetDevelopmentStoreV2

**Critical Rule**: Views must access sub-stores directly, not through delegation methods.

### V2 Naming Convention
Stores and repositories suffixed with `V2` follow the new architecture patterns:
- Use dependency injection
- Follow repository pattern
- Use actor-based caching
- Use strategy-based cache invalidation
- Use `LoadingState<T>` enum
- Use `handleError` extension

---

## Swift & Concurrency

### @MainActor
A global actor that ensures code runs on the main thread. Required for all UI-related classes like Views and Stores.

```swift
@MainActor
final class BudgetStoreV2: ObservableObject {
    // All properties and methods run on main thread
}
```

### @Published
A property wrapper that publishes value changes to SwiftUI views via Combine. When a `@Published` property changes, any view observing it automatically re-renders.

```swift
@Published var guests: [Guest] = []
```

### @Sendable
A protocol that marks types as safe to transfer across concurrency boundaries (between actors or tasks). Required for types used in async/await contexts.

```swift
protocol GuestRepositoryProtocol: Sendable {
    func fetchGuests() async throws -> [Guest]
}
```

### async/await
Swift's modern concurrency syntax for asynchronous operations. Replaces completion handlers with cleaner, sequential-looking code.

```swift
func loadGuests() async {
    let guests = try await repository.fetchGuests()
}
```

### Concurrency Checking
Swift 6 feature that enforces thread-safety at compile time. This project uses **strict concurrency checking** to prevent data races.

### nonisolated
A keyword that marks methods as safe to call from any actor context. Used for pure functions and loggers.

```swift
actor Service {
    nonisolated func log(_ message: String) {
        // Can be called without await
    }
}
```

### Sendable
See **@Sendable** above.

---

## Data & State Management

### AppStores
A singleton that owns all application stores (`BudgetStoreV2`, `GuestStoreV2`, etc.). Provides centralized access to stores via environment values.

**Critical**: Always use `AppStores.shared` or `@Environment` to access stores. Never create store instances in views.

```swift
@Environment(\.appStores) private var appStores
private var budgetStore: BudgetStoreV2 { appStores.budget }
```

### Cache Key
A unique string identifier for cached data. Convention: `"{domain}_{tenantId.uuidString}"` (e.g., `"guests_123e4567-e89b-12d3-a456-426614174000"`).

### Cache TTL (Time To Live)
The duration (in seconds) that cached data remains valid before being considered stale.

**Example**: `ttl: 60` means cache expires after 60 seconds.

### CachedItem
A wrapper around cached data that includes timestamp and TTL for expiration checking.

### LoadingState<T>
An enum representing the state of an asynchronous operation:
- `.idle` - Not started
- `.loading` - In progress
- `.loaded(T)` - Successfully completed with data
- `.error(Error)` - Failed with error

```swift
@Published var loadingState: LoadingState<[Guest]> = .idle
```

### RepositoryCache
A thread-safe actor that manages in-memory caching across all repositories. Supports TTL-based expiration and key-based invalidation.

```swift
await RepositoryCache.shared.set("guests_\(id)", value: guests, ttl: 60)
if let cached: [Guest] = await RepositoryCache.shared.get("guests_\(id)", maxAge: 60) {
    return cached
}
```

---

## Backend & Database

### Anon Key
The Supabase anonymous key used for client-side authentication. Safe to include in client applications because all data access is protected by Row Level Security (RLS) policies.

### Couple ID
The tenant identifier (UUID) that scopes all data to a specific couple. Every multi-tenant table has a `couple_id` column with RLS policies.

### Edge Function
Serverless TypeScript/JavaScript functions deployed to Supabase Edge Runtime (Deno). Used for backend logic, webhooks, and scheduled tasks.

### Multi-Tenancy
An architecture where a single application serves multiple customers (couples), with data isolation enforced by Row Level Security.

**Pattern**: All queries filter by `couple_id` automatically via RLS policies.

### PostgreSQL
The open-source relational database system used by Supabase. Supports advanced features like JSON columns, full-text search, and Row Level Security.

### RLS (Row Level Security)
A PostgreSQL feature that enforces data access policies at the database level. Ensures users can only access their own couple's data.

```sql
CREATE POLICY "couples_manage_own_guests"
  ON guest_list
  FOR ALL
  USING (couple_id = get_user_couple_id());
```

### Service Role Key
A Supabase admin key that bypasses Row Level Security. **NEVER** include in client applications - only use server-side.

### Supabase
An open-source Firebase alternative providing PostgreSQL database, authentication, real-time subscriptions, storage, and Edge Functions.

### Tenant ID
See **Couple ID** above.

### UUID
A 128-bit universally unique identifier. PostgreSQL stores UUIDs in lowercase format.

**Critical**: Pass UUIDs directly to Supabase queries, never convert to string (causes case mismatch).

```swift
// ✅ CORRECT
.eq("couple_id", value: tenantId)

// ❌ WRONG
.eq("couple_id", value: tenantId.uuidString)
```

---

## MCP (Model Context Protocol)

### ADR (Architectural Decision Record)
A document capturing an important architectural decision, its context, and consequences. The ADR Analysis MCP server helps create, track, and validate ADRs.

### Agent Deck
A terminal-based session manager for AI coding agents built with Go and Bubble Tea. Manages multiple Claude sessions with MCP server attachment.

**Config**: `~/.agent-deck/config.toml`

### Basic Memory
An MCP server providing knowledge management through semantic graphs and Markdown files. Used for storing **WHY and WHAT** - architectural decisions, patterns, and domain knowledge.

**Commands**:
- `mcp__basic-memory__search_notes(query)`
- `mcp__basic-memory__write_note(title, content, folder)`
- `mcp__basic-memory__read_note(identifier)`

### Beads
A git-backed graph issue tracker optimized for AI agents. Used for tracking **HOW and WHEN** - tasks, bugs, dependencies, and execution.

**Storage**: JSONL files in `.beads/` directory
**CLI**: `bd` command

**Commands**:
- `bd ready` - Show ready tasks
- `bd create` - Create issue
- `bd update` - Update issue
- `bd close` - Complete issue
- `bd sync` - Sync with git

### Code Guardian
An MCP server providing code quality validation, automated fixes, and persistent memory. Tracks task completion, deployment readiness, and project health.

### Grep MCP
An MCP server for semantic code search across large codebases using natural language queries.

### MCP (Model Context Protocol)
A protocol that allows AI assistants to access specialized capabilities through server plugins. Each MCP server provides tools, resources, and prompts.

### MCP Server
A process that implements the Model Context Protocol, providing specialized capabilities to AI coding assistants like Claude Code.

**Available Servers**:
- Basic Memory
- Beads
- Supabase MCP
- Code Guardian
- ADR Analysis
- Grep MCP
- Swiftzilla

### Supabase MCP
An MCP server providing database operations, migrations, Edge Function deployment, and project management for Supabase.

### Swiftzilla
An MCP server for searching Swift documentation, API references, and Swift Evolution proposals.

---

## Development Tools

### Claude Code
Anthropic's official CLI tool for AI-assisted development. Integrates with MCP servers for enhanced capabilities.

### GitHub CLI (`gh`)
Command-line tool for GitHub operations (PRs, issues, releases). Required for deployment workflows.

**Install**: `brew install gh`

### Supabase CLI
Command-line tool for local Supabase development, migrations, and project management.

**Install**: `brew install supabase/tap/supabase`

### Xcode
Apple's integrated development environment (IDE) for macOS and iOS development.

### Xcode Command Line Tools
Essential build tools including compilers and make. Required even if not using Xcode IDE.

**Install**: `xcode-select --install`

---

## Wedding Planning Domain

### Budget Category
A spending category in the wedding budget (e.g., "Venue", "Catering", "Photography"). Has allocated amount and tracks expenses.

### Budget Development Item
Line items in budget planning (income sources, expenses, gifts). Used in budget scenario planning.

### Budget Scenario
A "what-if" budget plan for comparing different spending strategies.

### Ceremony
The wedding ceremony event details including location, date, and time.

### Couple
Two people planning a wedding together. The primary tenant entity in the multi-tenant architecture.

### Expense
An actual or planned cost within a budget category.

### Guest
A person invited to the wedding. Tracks RSVP status, meal preferences, plus-ones, and contact information.

### Guest Group
Multiple guests traveling or sitting together (e.g., a family).

### Mood Board
A visual planning tool with images, colors, and inspiration for wedding aesthetic.

### Payment Schedule
Planned or actual payments to vendors over time.

### Reception
The wedding reception event details including location, date, and timeline.

### Seating Chart
Visual arrangement of guests at reception tables.

### Task
A to-do item in the wedding planning checklist.

### Timeline
The wedding day schedule with timing for ceremony, photos, reception events, etc.

### Vendor
A service provider (photographer, caterer, florist, etc.) with contact info, contracts, and payments.

### Visual Planning
Feature category including mood boards, seating charts, and floor plans.

---

## Testing & Quality

### Mock Repository
A test implementation of a repository protocol that returns predefined data instead of making network calls.

**Location**: `I Do BlueprintTests/Helpers/MockRepositories.swift`

### Model Builder
Factory methods (`.makeTest()`) for creating test data with sensible defaults.

**Location**: `I Do BlueprintTests/Helpers/ModelBuilders.swift`

```swift
let guest = Guest.makeTest(fullName: "John Doe")
```

### Sentry
Error tracking and performance monitoring service. Automatically captures crashes and errors.

### Unit Test
Tests that verify individual components (stores, repositories, domain services) in isolation using mocks.

### WCAG (Web Content Accessibility Guidelines)
Standards for making content accessible to people with disabilities. This app follows WCAG 2.1 Level AA for contrast ratios.

### XCTest
Apple's testing framework for Swift and Objective-C.

---

## Common Acronyms

- **ADR**: Architectural Decision Record
- **API**: Application Programming Interface
- **CLI**: Command-Line Interface
- **CRUD**: Create, Read, Update, Delete
- **CSV**: Comma-Separated Values
- **DSN**: Data Source Name (Sentry)
- **IDE**: Integrated Development Environment
- **JSON**: JavaScript Object Notation
- **JSONL**: JSON Lines (newline-delimited JSON)
- **JWT**: JSON Web Token
- **MCP**: Model Context Protocol
- **MVVM**: Model-View-ViewModel
- **RLS**: Row Level Security
- **RSVP**: Répondez s'il vous plaît (please respond)
- **SDK**: Software Development Kit
- **SQL**: Structured Query Language
- **TTL**: Time To Live
- **UI**: User Interface
- **URL**: Uniform Resource Locator
- **UUID**: Universally Unique Identifier
- **WCAG**: Web Content Accessibility Guidelines
- **XLSX**: Excel Spreadsheet Format

---

## See Also

- **FAQ**: See `docs/FAQ.md` for common questions and troubleshooting
- **API Documentation**: See `docs/API_DOCUMENTATION.md` for technical API reference
- **Architecture**: See `CLAUDE.md` for complete architecture documentation
- **MCP Tools**: See `docs/mcp_tools_info.md` for MCP server documentation
- **Workflow**: See `docs/BASIC-MEMORY-AND-BEADS-GUIDE.md` for integrated workflow patterns

---

*Last Updated: 2025-12-29*
