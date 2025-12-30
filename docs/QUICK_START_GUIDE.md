# Quick Start Guide

## For New Contributors

### 1. Verify Your Environment
```bash
# Check all required tools are installed and authenticated
./scripts/verify-tooling.sh
```

Required tools:
- Xcode Command Line Tools
- Swift 5.9+
- GitHub CLI (authenticated)
- Supabase CLI (authenticated)
- Beads (`bd`) - Issue tracking
- Basic Memory - Knowledge management (optional, for AI agents)

### 2. Read the Documentation
Start here (in order):
1. `CLAUDE.md` - Project architecture and patterns
2. `mcp_tools_info.md` - MCP servers and development tools
3. `BASIC-MEMORY-AND-BEADS-GUIDE.md` - Knowledge management & issue tracking workflow
4. `.claude/skills/base.md` - Atomic todo format and workflow
5. `.claude/skills/swift-macos.md` - Swift/macOS specific patterns
6. `_project_specs/overview.md` - Project goals and vision
7. `_project_specs/session/code-landmarks.md` - Navigate the codebase

### 3. Build the Project
```bash
# Resolve dependencies
xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -resolvePackageDependencies

# Build
xcodebuild build -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'

# Run tests
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'
```

### 4. Understand the Workflow

#### MCP-Enhanced Development Workflow

This project uses **Beads** for task tracking and **Basic Memory** for knowledge management. See [BASIC-MEMORY-AND-BEADS-GUIDE.md](../BASIC-MEMORY-AND-BEADS-GUIDE.md) for comprehensive patterns.

**Quick Start with Beads & Basic Memory:**

```bash
# 1. Start session - Check active work
bd ready                    # Find tasks ready to work (no blockers)
bd list --status=in_progress # Check what you were working on

# 2. Research context (if using Basic Memory MCP)
# In Claude Code/Desktop:
mcp__basic-memory__recent_activity(timeframe: "7d", project: "i-do-blueprint")
mcp__basic-memory__search_notes("relevant topic")

# 3. Create new task
bd create "Implement feature X" --type=feature --priority=1

# 4. Start work
bd update beads-xxx --status=in_progress

# 5. During work - search architecture knowledge
mcp__basic-memory__search_notes("repository pattern")
mcp__basic-memory__read_note("Cache Strategy")

# 6. Complete work
bd close beads-xxx

# 7. Document new patterns (if significant)
mcp__basic-memory__write_note(
  title: "Pattern Name",
  folder: "architecture/patterns",
  project: "i-do-blueprint"
)

# 8. Sync to git
bd sync
```

#### Adding a New Feature

**With Beads + Basic Memory (Recommended):**

1. **Research** - Search Basic Memory for relevant patterns
   ```javascript
   mcp__basic-memory__search_notes("similar feature")
   mcp__basic-memory__read_note("Architecture Doc")
   ```

2. **Plan** - Create Beads tasks with dependencies
   ```bash
   bd create "Implement feature X" -t feature -p 1
   bd create "Add tests for X" -t task -p 1
   bd dep add beads-test beads-impl  # Test depends on impl
   ```

3. **Execute** - Work on ready tasks
   ```bash
   bd ready
   bd update beads-xxx --status=in_progress
   # [Implement feature]
   bd close beads-xxx
   ```

4. **Document** - Store new knowledge
   ```javascript
   mcp__basic-memory__write_note({
     title: "Feature X Pattern",
     folder: "architecture",
     project: "i-do-blueprint"
   })
   ```

5. **Sync** - Commit task tracking
   ```bash
   bd sync
   ```

#### Session Management with MCP Tools

**Session Start:**
```bash
# Check what's ready
bd ready

# Restore context (Basic Memory)
mcp__basic-memory__recent_activity(timeframe: "7d")
mcp__basic-memory__build_context(url: "projects/i-do-blueprint")
```

**During Session:**
- Use `bd show beads-xxx` to view task details
- Use `mcp__basic-memory__search_notes()` for research
- Track progress in Beads
- Reference architecture docs in Basic Memory

**Session End:**
```bash
# Close completed tasks
bd close beads-xxx beads-yyy

# Document new learnings
mcp__basic-memory__write_note(...)

# Sync to git
bd sync
```

### 5. Key Commands

#### Development Commands
```bash
# Verify tooling
./scripts/verify-tooling.sh

# Security checks (run before commit)
./scripts/security-check.sh

# Build
xcodebuild build -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'

# Run specific test
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -only-testing:"I Do BlueprintTests/BudgetStoreV2Tests"

# Clean build
xcodebuild clean -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint"
```

#### MCP & Workflow Commands

**Beads (Task Tracking):**
```bash
# Finding work
bd ready                           # Tasks with no blockers
bd list --status=open              # All open tasks
bd list --status=in_progress       # Active work
bd blocked                         # Show blocked tasks

# Creating tasks
bd create "Title" -t task -p 1     # Create task (priority 0-4)
bd create "Title" -t bug -p 0      # Create critical bug
bd create "Title" -t feature -p 1  # Create feature

# Managing tasks
bd update beads-xxx --status=in_progress
bd close beads-xxx
bd close beads-xxx beads-yyy beads-zzz  # Bulk close

# Dependencies
bd dep add beads-child beads-parent     # child depends on parent

# Project health
bd stats                           # Statistics
bd sync                            # Sync to git
```

**Basic Memory (via MCP in Claude Code/Desktop):**
```javascript
// Search knowledge base
mcp__basic-memory__search_notes({
  query: "repository pattern",
  project: "i-do-blueprint"
})

// Read documentation
mcp__basic-memory__read_note({
  identifier: "Cache Strategy",
  project: "i-do-blueprint"
})

// Create documentation
mcp__basic-memory__write_note({
  title: "New Pattern",
  content: "# Pattern\n...",
  folder: "architecture/patterns",
  project: "i-do-blueprint"
})

// Build context
mcp__basic-memory__build_context({
  url: "architecture/repositories",
  project: "i-do-blueprint"
})
```

**MCP Servers (for specialized tasks):**
- **Supabase**: `mcp__supabase__*` - Database operations, migrations
- **Code Guardian**: `mcp__code-guardian__*` - Code validation, quality checks
- **ADR Analysis**: `mcp__adr-analysis__*` - Architecture decision records
- **Grep MCP**: `mcp__greb-mcp__*` - Semantic code search
- **Swiftzilla**: `mcp__swiftzilla__*` - Swift documentation search

See [mcp_tools_info.md](../mcp_tools_info.md) for complete MCP server documentation.

### 6. Architecture Quick Reference

**Data Flow:**
```
View → Store (@MainActor) → Repository → Domain Service → Supabase
```

**Key Patterns:**
- Repository Pattern: All data access through protocols
- Store Composition: BudgetStoreV2 owns 6 specialized sub-stores
- Cache Strategies: Per-domain cache invalidation
- Multi-tenancy: All data scoped by `couple_id` with RLS
- Strict Concurrency: Full Swift 6 concurrency checking

**Critical Rules:**
- ✅ Pass UUIDs directly to queries (not `.uuidString`)
- ✅ Use `AppStores.shared` or `@Environment` for stores
- ✅ Access BudgetStoreV2 sub-stores directly (no delegation)
- ✅ Use `DateFormatting` for all date display
- ✅ Wrap Supabase calls in `NetworkRetry.withRetry`
- ❌ Never create store instances in views
- ❌ Never convert UUIDs to strings for queries
- ❌ Never use `TimeZone.current` for display

### 7. Common Tasks

#### Adding a New Repository
```swift
// 1. Protocol in Domain/Repositories/Protocols/
protocol FeatureRepositoryProtocol: Sendable {
    func fetch() async throws -> [Item]
}

// 2. Live implementation in Domain/Repositories/Live/
class LiveFeatureRepository: FeatureRepositoryProtocol {
    private let supabase: SupabaseClient
    private let cache = RepositoryCache.shared
    private let cacheStrategy = FeatureCacheStrategy()
    // ... implementation
}

// 3. Mock in I Do BlueprintTests/Helpers/MockRepositories.swift
class MockFeatureRepository: FeatureRepositoryProtocol { }

// 4. Register in Core/Common/Common/DependencyValues.swift
extension DependencyValues {
    var featureRepository: FeatureRepositoryProtocol {
        get { self[FeatureRepositoryKey.self] }
        set { self[FeatureRepositoryKey.self] = newValue }
    }
}
```

#### Adding a New Store
```swift
@MainActor
final class FeatureStore: ObservableObject {
    @Published var items: [Item] = []
    @Published var loadingState: LoadingState<[Item]> = .idle

    @Dependency(\.featureRepository) private var repository

    func loadItems() async {
        loadingState = .loading
        do {
            let items = try await repository.fetch()
            self.items = items
            loadingState = .loaded(items)
        } catch {
            loadingState = .error(error)
            await handleError(error, operation: "loadItems")
        }
    }
}
```

### 8. Getting Help

- **Architecture**: See `CLAUDE.md`
- **MCP Tools**: See `mcp_tools_info.md`
- **Workflow**: See `BASIC-MEMORY-AND-BEADS-GUIDE.md`
- **Task Tracking**: Run `bd ready` or `bd stats`
- **Knowledge Base**: Search Basic Memory with `mcp__basic-memory__search_notes()`
- **Code Navigation**: See `_project_specs/session/code-landmarks.md`
- **Swift Patterns**: See `.claude/skills/swift-macos.md`

## For Claude Code / AI Agents

### Session Start Protocol

```bash
# 1. Check active work (Beads)
bd ready                    # What's ready to work?
bd list --status=in_progress # What was I working on?

# 2. Restore context (Basic Memory)
mcp__basic-memory__recent_activity(timeframe: "7d", project: "i-do-blueprint")
mcp__basic-memory__build_context(url: "projects/i-do-blueprint")

# 3. Select next task
bd show beads-xxx          # Review task details
bd update beads-xxx --status=in_progress
```

### During Work

```javascript
// Research patterns before implementing
mcp__basic-memory__search_notes("repository pattern")
mcp__basic-memory__read_note("Cache Strategy")

// Use specialized MCPs as needed
mcp__supabase__list_tables()
mcp__code-guardian__guard_validate(code, filename)
mcp__swiftzilla__search("URLSession async")
```

### Session End Protocol

```bash
# 1. Complete work (Beads)
bd close beads-xxx beads-yyy

# 2. Document learnings (Basic Memory)
mcp__basic-memory__write_note({
  title: "New Pattern",
  folder: "architecture",
  project: "i-do-blueprint"
})

# 3. Sync to git
bd sync
```

### MCP Tool Selection Guide

**When to use each MCP:**

- **Basic Memory**: Architecture docs, patterns, decisions, troubleshooting guides
- **Beads**: Active tasks, bugs, features, dependency tracking
- **Supabase MCP**: Database queries, migrations, Edge Functions
- **Code Guardian**: Code validation, quality checks, automated fixes
- **ADR Analysis**: Architecture decision records, deployment validation
- **Grep MCP**: Large-scale code search, finding patterns
- **Swiftzilla**: Swift API docs, language features, Evolution proposals

See [BASIC-MEMORY-AND-BEADS-GUIDE.md](../BASIC-MEMORY-AND-BEADS-GUIDE.md) for detailed workflow patterns and integration examples.
