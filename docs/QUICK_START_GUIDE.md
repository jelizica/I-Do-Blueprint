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

### 2. Read the Documentation
Start here (in order):
1. `CLAUDE.md` - Project architecture and patterns
2. `.claude/skills/base.md` - Atomic todo format and workflow
3. `.claude/skills/swift-macos.md` - Swift/macOS specific patterns
4. `_project_specs/overview.md` - Project goals and vision
5. `_project_specs/session/code-landmarks.md` - Navigate the codebase

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

#### Adding a New Feature
1. **Read** `.claude/skills/base.md` for atomic todo format
2. **Create** feature spec in `_project_specs/features/`
3. **Break down** into atomic todos with validation and test cases
4. **Add** to `_project_specs/todos/active.md`
5. **Implement** following the architecture in `CLAUDE.md`
6. **Track** session state in `_project_specs/session/current-state.md`
7. **Log** decisions in `_project_specs/session/decisions.md`
8. **Test** and validate
9. **Move** completed todo to `_project_specs/todos/completed.md`

#### Session Management
- Update `current-state.md` after every todo completion
- Update after ~20 tool calls during active work
- Log architectural decisions to `decisions.md` (append-only)
- Archive old sessions to `_project_specs/session/archive/`

### 5. Key Commands

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

- Architecture questions: See `CLAUDE.md`
- Workflow questions: See `.claude/skills/base.md` and `.claude/skills/session-management.md`
- Code navigation: See `_project_specs/session/code-landmarks.md`
- Recent decisions: See `_project_specs/session/decisions.md`
- Active work: See `_project_specs/todos/active.md`

## For Claude Code

When starting a new session:
1. Read `_project_specs/session/current-state.md` first
2. Check `_project_specs/todos/active.md` for current work
3. Review recent `decisions.md` entries if needed
4. Continue from "Next Steps" in current-state.md
