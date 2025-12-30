# Repository Guidelines

## Project Structure & Module Organization

The macOS app lives inside `I Do Blueprint/` and follows a layered SwiftUI architecture. `App/` provides the entry point (`My_Wedding_Planning_AppApp.swift`, `RootFlowView.swift`) and bootstraps authentication plus dependency containers. Core infrastructure (analytics, auth helpers, dependency registration, security utilities, configuration) sits under `Core/`. Product design tokens, typography, and accessibility references live in `Design/`. Domain models, repository protocols/implementations, and business-focused domain services are grouped inside `Domain/`. Feature-oriented SwiftUI screens live in `Views/`, while shared operational logic (stores, API clients, realtime managers, import/export helpers) is in `Services/`. Shared helpers such as logging, validation, retries, haptics, and formatting utilities sit in `Utilities/`. Xcode schemes reference `I Do BlueprintTests/` for XCTest targets and `I Do BlueprintUITests/` for end-to-end UI flows. Assets, sample spreadsheets, and Lottie animations are stored in `Resources/`.

## Build, Test, and Development Commands

Use the same scheme for all automation (see README and CLAUDE.md):

```bash
# Resolve Swift Package dependencies
xcodebuild -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS' -resolvePackageDependencies

# Build release/debug artifacts
xcodebuild build -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'

# Run the full XCTest + XCUITest suite
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'
```

CI on GitHub Actions executes the same commands without extra secrets because Supabase and Sentry values are hardcoded in `Core/Configuration/AppConfig.swift`.

## Coding Style & Naming Conventions

- **Indentation**: 4-space soft tabs, matching existing files such as `App/My_Wedding_Planning_AppApp.swift`.
- **File naming**: `Views/{Feature}{Purpose}View.swift`, `Domain/Services/{Feature}Service.swift`, repositories under `Domain/Repositories/{Live|Mock|Protocols}/`, and stores suffixed with `StoreV2.swift` (see `Services/Stores/Budget/BudgetStoreV2.swift`).
- **Function/variable naming**: camelCase with descriptive prefixes (`loadGuests`, `isAuthenticated`, `tenantId`); boolean properties start with `is/has/should`.
- **Linting**: `.swiftlint.yml` limits linting to `I Do Blueprint/`, enforces line lengths (warning 160, error 200), and adds custom rules preventing hardcoded colors and fonts. Keep using the design tokens defined in `Design/DesignSystem.swift`; add new rules there if you need extra tokens.

## Testing Guidelines

- **Frameworks**: XCTest for unit/integration (`I Do BlueprintTests/` structure mirrors production layers) and XCUITest for UI flows (`I Do BlueprintUITests/`).
- **Test files**: follow `FeatureNameTests.swift` / `FeatureNameUITests.swift` plus helper builders (`I Do BlueprintTests/Helpers/`).
- **Running tests**: `xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'` (filter with `-only-testing` for targeted suites as shown in CLAUDE.md).
- **Coverage**: No enforced threshold, but stores and domain services are expected to mock repositories (see `Best_practices.md`), and UI flows should cover critical wedding-planning journeys (budget, guests, vendors).

## Commit & Pull Request Guidelines

- **Commit format**: Conventional prefixes dominate the history (`fix: Address CodeRabbit code review issues…`, `refactor: Decompose DashboardViewV4…`, `docs: Add comprehensive CLAUDE.md…`). Continue using `type: summary` for clarity.
- **PR process**: Open GitHub PRs backed by the same Xcode build/test commands; GitHub Actions already runs without extra secrets. Reference any CodeRabbit feedback threads where applicable, since CI is configured to comment on diffs.
- **Branch naming**: Not formally enforced—follow the conventional `<type>/<short-description>` pattern and keep branches scoped to a single feature or bugfix so reviewers can rely on targeted context.

---

# Repository Tour

_Last updated: 2025-12-29_

## 🎯 What This Repository Does

**I Do Blueprint** is a macOS SwiftUI application that helps couples plan weddings end-to-end by combining budgeting, guest/vendor management, timeline coordination, collaborative notes, and visual planning into a single Supabase-backed client.

**Key responsibilities:**
- Offer offline-friendly SwiftUI workflows for every planning domain (budget, guests, tasks, documents, vendors, visual planning).
- Synchronize data through Supabase repositories with caching, retry, and real-time collaboration.
- Enforce design system, accessibility, and security policies (Keychain secrets, multi-tenant RLS) inside the native macOS experience.

---

## 🏗️ Architecture Overview

### System Context
```
[Couple on macOS] → [I Do Blueprint SwiftUI client]
                          ↓
                   [Supabase (PostgreSQL, Auth, Storage)]
                          ↓
                [Realtime channels, Row Level Security]
                          ↓
          [Sentry telemetry] & [Optional Google/Resend APIs]
```

### Key Components
- **App bootstrap (`App/My_Wedding_Planning_AppApp.swift`, `RootFlowView.swift`)** – wires AppDelegate, AuthContext, AppStores, SupabaseManager, and coordinates onboarding/tenant flows.
- **State stores (`Services/Stores/*.swift`)** – `@MainActor` ObservableObjects handling feature logic, caching, and error presentation via `StoreErrorHandling`.
- **Repositories & Cache (`Domain/Repositories/*`)** – protocol-driven Supabase data access with retry (`Utilities/NetworkRetry.swift`) and actor-based cache (`Domain/Repositories/RepositoryCache.swift`).
- **Domain services (`Domain/Services/*.swift`)** – actors like `BudgetAllocationService` and `BudgetAggregationService` encapsulate business rules that exceed CRUD complexity.
- **Design system + Utilities (`Design/`, `Utilities/`)** – enforce AppColors, Typography, Spacing, accessibility extensions, and cross-feature helpers (logging, validation, haptics).
- **External service layers (`Services/API`, `Services/Realtime`, `Services/Export`, `Services/Import`)** – wrap Google, Supabase Realtime, Resend email, and file import/export flows.

### Data Flow
1. `RootFlowView` determines whether to show authentication, tenant selection, onboarding, or the main `NavigationSplitView`.
2. SwiftUI views request operations via environment-provided stores (e.g., `BudgetStoreV2`, `GuestStoreV2`).
3. Stores resolve repository protocols through the Point-Free `@Dependency` container defined under `Core/Common/Common/`.
4. Repositories fetch from `RepositoryCache`, optionally invoke domain services for aggregation/allocation work, then call Supabase via strongly typed UUID filters.
5. Mutations invalidate caches via domain-specific strategies and bubble success/error states back to stores → views update reactively.

---

## 📁 Project Structure [Partial Directory Tree]

```
I Do Blueprint/
├── App/                         # Entry point, RootFlowView, AppDelegate
├── Core/
│   ├── Common/                  # Analytics, Auth, AppStores, Error handling
│   ├── Configuration/           # AppConfig, ConfigValidator, feature flags
│   ├── Extensions/              # Swift and UI extensions
│   └── Security/                # Keychain + credential helpers
├── Design/                      # DesignSystem, ColorPalette, accessibility docs
├── Domain/
│   ├── Models/                  # Budget, Guest, Task, Vendor, etc.
│   ├── Repositories/            # Protocols, Live, Mock, Caching strategies
│   └── Services/                # Business logic actors
├── Services/
│   ├── Stores/                  # Feature stores (BudgetStoreV2, GuestStoreV2…)
│   ├── API/, Auth/, Realtime/   # External integration layers
│   └── Import/, Export/         # File pipelines and data movers
├── Utilities/                   # Logging, validation, date formatting, retries
├── Views/                       # Feature-based SwiftUI screens
├── Resources/                   # Assets, Lottie animations, sample spreadsheets
├── I Do BlueprintTests/         # XCTest targets mirroring production layers
└── I Do BlueprintUITests/       # XCUITest flows (budget, guest, vendor journeys)
```

### Key Files to Know

| File | Purpose | When You'd Touch It |
|------|---------|---------------------|
| `App/My_Wedding_Planning_AppApp.swift` | Declares the `@main` app, injects AuthContext/AppStores, runs config preflight | Boot logic, new startup flows, telemetry hooks |
| `App/RootFlowView.swift` | Central auth/tenant/onboarding router plus MainAppView shell | Adjust onboarding, tenant switching, or post-onboarding loader |
| `Core/Configuration/AppConfig.swift` | Hardcoded Supabase/Sentry defaults with Config.plist override support | Changing backend endpoints or enabling custom environments |
| `Core/Common/Common/DependencyValues.swift` | Registers repository/service dependencies via Point-Free `@Dependency` | Adding new repositories or swapping implementations in tests |
| `Domain/Repositories/RepositoryCache.swift` | Actor-based cache shared across repositories | Tweaking TTL, invalidation primitives, or cache metrics |
| `Domain/Services/BudgetAllocationService.swift` | Actor implementing proportional budget allocation recalculations | Changing allocation math or adding new triggers |
| `Services/Stores/Budget/BudgetStoreV2.swift` | Budget composition root owning sub-stores and loading logic | Extending budget UX, wiring new budget subdomains |
| `Services/API/DocumentsAPI.swift` | Typed API client for document endpoints | Adding new document endpoints or request parameters |
| `Views/Dashboard/` | SwiftUI components powering the main dashboard tabs | Updating dashboard layout, metrics, or cards |
| `Utilities/NetworkRetry.swift` | Standardized retry/backoff helper for Supabase requests | Adjusting resilience strategy or instrumentation |
| `I Do BlueprintTests/Helpers/MockRepositories.swift` | Shared mocks for repository protocols | Creating new mocks or extending test fixtures |
| `Resources/SampleGuestList.xlsx` | Sample import file for QA and demos | Updating example schemas to match domain changes |

---

## 🔧 Technology Stack

### Core Technologies
- **Language:** Swift 5.9+ with strict concurrency checking (async/await, actors).
- **Framework:** SwiftUI for UI, Combine for state observation, NavigationSplitView for macOS sidebars.
- **Backend:** Supabase (PostgreSQL + Auth + Storage + Realtime) – Row Level Security ensures tenant isolation.
- **Configuration:** Point-Free Dependencies library for injection, Swift Package Manager for dependency resolution.

### Key Libraries
- **Supabase Swift Client** – Database, Auth, Storage APIs used by `Domain/Repositories/Live`.
- **SentrySDK / SentrySwiftUI** – Error and performance monitoring, initialized in `AppDelegate` and `SentryService`.
- **CoreXLSX + CSV parsers** – `Services/Import/` processes guest/vendor spreadsheets.
- **Resend API** – `Services/Email/` sends collaboration invitations.
- **GoogleAuthManager/Drive/Sheets services** – `Services/Integration/` handles optional document sync and exports.
- **Lottie** – Animations stored under `Resources/Lottie/` for onboarding polish.

### Development Tools
- **SwiftLint (`.swiftlint.yml`)** – Ensures semantic colors/typography, identifier length, line limits.
- **SwiftFormat** (referenced in `ARCHITECTURE_IMPROVEMENT_PLAN*.md`) – Optional formatting pass aligning with design tokens.
- **GitHub Actions** – Runs `xcodebuild build/test` for every PR, no secrets required thanks to hardcoded AppConfig.

---

## 🌐 External Dependencies

### Required Services
- **Supabase** – Primary persistence/auth backend; all repositories rely on Supabase client calls guarded by RLS policies.
- **Sentry** – Error tracking and performance monitoring, enabled when `ConfigValidator` detects a valid DSN.
- **macOS Keychain** – Secure storage for session data, tenant selection, and user-provided API keys.

### Optional Integrations
- **Google OAuth, Drive, Sheets** – Configured through Settings → API Keys and used by `Services/Export` and `Services/Import` to sync documents.
- **Resend** – Email delivery for collaboration invitations.
- **Unsplash & Pinterest APIs** – Enhance visual planning mood boards when users provide API keys.
- **Multiavatar (`Resources/multiavatar.min.js`)** – Generates placeholder avatars when no user upload is available.

---

### Environment Variables / Config Keys

Values are supplied via `Config.plist` (gitignored) and override `AppConfig.swift` defaults:

```bash
# Required
SUPABASE_URL=             # Overrides default Supabase endpoint
SUPABASE_ANON_KEY=        # Client-safe key, never use service_role
SENTRY_DSN=               # Enables runtime error reporting

# Optional
GOOGLE_CLIENT_ID=         # Enables Google OAuth + Drive/Sheets
RESEND_API_KEY=           # Invitation emails via Resend
UNSPLASH_ACCESS_KEY=      # Mood board integrations
PINTEREST_ACCESS_TOKEN=   # Visual inspiration boards
```

---

## 🔄 Common Workflows

### Onboarding and Tenant Initialization
1. `RootFlowView` checks `SupabaseManager.isAuthenticated` and `SessionManager.getTenantId()`.
2. If onboarding is unfinished, `OnboardingStoreV2` drives the guided flow and persists progress.
3. Once complete, `PostOnboardingLoader` sequentially loads settings, guests, vendors, tasks, and budgets before revealing `MainAppView`.
**Code path:** `App/RootFlowView.swift` → `Services/Stores/OnboardingStoreV2.swift` → `Services/Stores/PostOnboardingLoader.swift` → downstream stores.

### Budget Aggregation & Allocation
1. `BudgetStoreV2` (or sub-stores within `Services/Stores/Budget/`) issues repository calls when users edit budget items.
2. `Domain/Repositories/Live/LiveBudgetRepository` fetches cached data, updates Supabase, then hands off to `BudgetAggregationService` / `BudgetAllocationService` actors.
3. Cache strategies invalidate scenario-specific keys so UI reflects proportional allocation changes immediately.
**Code path:** `Views/Budget/*` → `BudgetStoreV2` → `BudgetRepositoryProtocol` → `Domain/Services/Budget*Service.swift`.

### Document Import & Export
1. User selects CSV/XLSX samples (see `Resources/SampleGuestList.xlsx`).
2. `Services/Import/FileImportService` parses headers, infers mappings, validates entries, and emits domain models.
3. Repositories persist guests/vendors and invalidate caches; optional exports route through Google Sheets via `Services/Export/`.
**Code path:** `Views/Documents/` → `DocumentStoreV2` → `FileImportService` / `DocumentsAPI`.

---

## 📈 Performance & Scale

- **Caching:** `Domain/Repositories/RepositoryCache` (actor) stores frequently requested lists with TTL and domain-specific invalidation policies (`Domain/Repositories/Caching/*`).
- **Retry Logic:** `Utilities/NetworkRetry.swift` wraps Supabase calls with exponential backoff and parallel async loading (see README/CLAUDE examples).
- **Post-Onboarding Prefetch:** `PostOnboardingLoader` warms caches for all major stores, reducing first-render latency after account setup.
- **Monitoring:** `Services/Analytics/SentryService` records breadcrumbs and captures store/repository errors; logs go through `Utilities/Logging/AppLogger` categories.

---

## 🚨 Things to Be Careful About

### 🔒 Security Considerations
- **Multi-Tenant Enforcement:** Every repository query must filter by `couple_id` using UUID values directly (never strings) to align with Supabase/PostgreSQL RLS policies documented in `docs/DOMAIN_SERVICES_ARCHITECTURE.md` and CLAUDE.md.
- **Keychain Storage:** API keys, Google OAuth tokens, and session secrets live in the per-user Keychain (see README). Never persist them to disk or logs.
- **Configuration Validation:** `ConfigValidator` and `AppConfig` guard against missing Supabase/Sentry data; configuration errors surface via `ConfigurationErrorView` early in app startup.
- **Custom Colors & Fonts:** SwiftLint rules (`no_literal_rgb_colors`, `no_custom_font`) enforce the design system; violating them risks accessibility regressions documented inside `Design/ACCESSIBILITY_*.md`.
- **Error Reporting:** Use `SentryService` + `ErrorHandler` instead of ad-hoc logging so sensitive context gets redacted and triaged consistently.

*Update to last commit: 4e172d599f32cfd5c47d9fc7c15d8b3a13c483c1*

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

<!-- bv-agent-instructions-v1 -->

---

## Beads Workflow Integration

This project uses [beads_viewer](https://github.com/Dicklesworthstone/beads_viewer) for issue tracking. Issues are stored in `.beads/` and tracked in git.

### Essential Commands

```bash
# View issues (launches TUI - avoid in automated sessions)
bv

# CLI commands for agents (use these instead)
bd ready              # Show issues ready to work (no blockers)
bd list --status=open # All open issues
bd show <id>          # Full issue details with dependencies
bd create --title="..." --type=task --priority=2
bd update <id> --status=in_progress
bd close <id> --reason="Completed"
bd close <id1> <id2>  # Close multiple issues at once
bd sync               # Commit and push changes
```

### Workflow Pattern

1. **Start**: Run `bd ready` to find actionable work
2. **Claim**: Use `bd update <id> --status=in_progress`
3. **Work**: Implement the task
4. **Complete**: Use `bd close <id>`
5. **Sync**: Always run `bd sync` at session end

### Key Concepts

- **Dependencies**: Issues can block other issues. `bd ready` shows only unblocked work.
- **Priority**: P0=critical, P1=high, P2=medium, P3=low, P4=backlog (use numbers, not words)
- **Types**: task, bug, feature, epic, question, docs
- **Blocking**: `bd dep add <issue> <depends-on>` to add dependencies

### Session Protocol

**Before ending any session, run this checklist:**

```bash
git status              # Check what changed
git add <files>         # Stage code changes
bd sync                 # Commit beads changes
git commit -m "..."     # Commit code
bd sync                 # Commit any new beads changes
git push                # Push to remote
```

### Best Practices

- Check `bd ready` at session start to find available work
- Update status as you work (in_progress → closed)
- Create new issues with `bd create` when you discover tasks
- Use descriptive titles and set appropriate priority/type
- Always `bd sync` before ending session

<!-- end-bv-agent-instructions -->
