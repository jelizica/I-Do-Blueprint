# 📘 Project Best Practices

## 1. Project Purpose

**I Do Blueprint** is a comprehensive macOS wedding planning application built with SwiftUI. It helps couples manage all aspects of their wedding including budget tracking, guest management, vendor coordination, task planning, timeline management, document storage, and visual planning (mood boards, seating charts). The app uses Supabase as a backend for multi-tenant data storage and supports Google Drive integration for document management.

**Domain:** Wedding planning and event management  
**Platform:** macOS (SwiftUI)  
**Architecture:** MVVM with Repository Pattern, Domain Services, Dependency Injection  
**Backend:** Supabase (PostgreSQL with Row Level Security)

---

## 2. Project Structure

### Core Directory Layout

```
I Do Blueprint/
├── App/                          # Application entry point and root views
│   ├── AppDelegate.swift
│   ├── My_Wedding_Planning_AppApp.swift
│   └── RootFlowView.swift
├── Core/                         # Core infrastructure (auth, storage, utilities)
│   ├── Common/
│   │   ├── Analytics/           # ErrorTracker, performance monitoring
│   │   ├── Auth/                # Authentication helpers
│   │   ├── Common/              # AppStores, DependencyValues
│   │   ├── Errors/              # Domain-specific error types (AppError, ErrorHandler)
│   │   ├── Security/            # Security utilities
│   │   └── Storage/             # Storage utilities
│   ├── Configuration/           # App configuration
│   ├── Extensions/              # Swift type extensions
│   └── Security/                # Security infrastructure
├── Design/                       # Design system and accessibility
│   ├── DesignSystem.swift       # Complete design system
│   ├── ColorPalette.swift       # WCAG-compliant color definitions
│   ├── Typography.swift         # Typography system
│   └── ACCESSIBILITY_*.md       # Accessibility documentation
├── Domain/                       # Business logic and data models
│   ├── Models/                  # Domain models organized by feature
│   │   ├── Budget/
│   │   ├── Guest/
│   │   ├── Task/
│   │   ├── Vendor/
│   │   ├── Collaboration/       # Collaborator, ActivityEvent, Presence
│   │   ├── Settings/
│   │   ├── Onboarding/
│   │   └── Shared/
│   ├── Repositories/            # Data access layer
│   │   ├── Protocols/           # Repository interfaces
│   │   ├── Live/                # Production implementations (Supabase)
│   │   ├── Mock/                # Test implementations
│   │   ├── Caching/             # Cache invalidation strategies
│   │   │   ├── CacheInvalidationStrategy.swift
│   │   │   ├── CacheOperation.swift
│   │   │   ├── GuestCacheStrategy.swift
│   │   │   ├── BudgetCacheStrategy.swift
│   │   │   ├── VendorCacheStrategy.swift
│   │   │   ├── TaskCacheStrategy.swift
│   │   │   ├── TimelineCacheStrategy.swift
│   │   │   └── DocumentCacheStrategy.swift
│   │   └── RepositoryCache.swift # Generic caching infrastructure
│   └── Services/                # Domain services (business logic)
│       ├── Protocols/           # Service interfaces
│       ├── BudgetAggregationService.swift
│       ├── BudgetAllocationService.swift
│       └── ExpensePaymentStatusService.swift
├── Services/                     # Application services
│   ├── Stores/                  # State management (V2 pattern)
│   │   ├── Budget/              # BudgetStoreV2, AffordabilityStore, etc.
│   │   ├── ActivityFeedStoreV2.swift
│   │   ├── BudgetStoreV2.swift
│   │   ├── CacheableStore.swift # Store-level caching protocol
│   │   ├── CollaborationStoreV2.swift
│   │   ├── DocumentStoreV2.swift
│   │   ├── GuestStoreV2.swift
│   │   ├── NotesStoreV2.swift
│   │   ├── OnboardingStoreV2.swift
│   │   ├── PresenceStoreV2.swift
│   │   ├── SettingsStoreV2.swift
│   │   ├── StoreErrorHandling.swift # Consistent error handling extension
│   │   ├── TaskStoreV2.swift
│   │   ├── TimelineStoreV2.swift
│   │   ├── VendorStoreV2.swift
│   │   └── VisualPlanningStoreV2.swift
│   ├── API/                     # API clients
│   ├── Auth/                    # SessionManager, authentication
│   ├── Avatar/                  # Avatar generation service
│   ├── Collaboration/           # InvitationService
│   ├── Email/                   # ResendEmailService for invitations
│   ├── Export/                  # Google Sheets export
│   ├── Import/                  # FileImportService (CSV/XLSX parsing)
│   ├── Integration/             # SecureAPIKeyManager, external integrations
│   ├── Loaders/                 # PostOnboardingLoader
│   ├── Navigation/              # Navigation coordination
│   ├── Realtime/                # CollaborationRealtimeManager
│   ├── Storage/                 # SupabaseClient, data persistence
│   ├── Analytics/               # SentryService, CacheWarmer, PerformanceOptimizationService
│   ├── UI/                      # UI services (AlertPresenter)
│   └── VisualPlanning/          # Visual planning services
├── Utilities/                    # Shared utilities
│   ├── Logging/                 # AppLogger, structured logging
│   ├── Validation/              # Input validation
│   ├── DateFormatting.swift     # Timezone-aware date formatting
│   ├── NetworkRetry.swift       # Retry logic with exponential backoff
│   ├── HapticFeedback.swift     # Haptic feedback utilities
│   └── AccessibilityExtensions.swift
├── Views/                        # UI layer organized by feature
│   ├── Auth/
│   ├── Budget/
│   ├── Collaboration/           # Invitation acceptance, collaborator management
│   ├── Dashboard/
│   ├── Documents/
│   ├── Guests/
│   ├── Notes/
│   ├── Onboarding/              # Multi-step onboarding flow
│   ├── Settings/
│   ├── Shared/                  # Reusable components, ErrorPresenter
│   ├── Tasks/
│   ├── Timeline/
│   ├── Vendors/
│   └── VisualPlanning/
├── Resources/                    # Assets, localizations, Lottie files
│   ├── Assets.xcassets/
│   ├── Lottie/
│   └── Sample files (CSV/XLSX)
└── Config.plist                  # API keys and configuration
```

### Key Architectural Principles

- **Feature-based organization**: Views, models, and logic grouped by feature domain
- **Separation of concerns**: Clear boundaries between UI (Views), State (Stores), Business Logic (Domain Services), Data Access (Repositories), and Data (Models)
- **Repository pattern**: All data access goes through repository protocols for testability
- **Domain Services layer**: Complex business logic separated from repositories (aggregation, allocation calculations)
- **Strategy-based cache invalidation**: Per-domain cache strategies for maintainable cache management
- **Dependency injection**: Using Swift's `@Dependency` macro for loose coupling
- **V2 naming convention**: New architecture stores use `V2` suffix (e.g., `BudgetStoreV2`)
- **Actor-based caching**: Thread-safe caching with `RepositoryCache` actor
- **Multi-tenant security**: All data scoped by `couple_id` with Row Level Security (RLS)
- **Real-time collaboration**: Supabase Realtime for presence and activity feeds
- **Timezone-aware date handling**: Centralized `DateFormatting` utility respecting user preferences

---

## 3. Test Strategy

### Framework
- **XCTest** for unit and integration tests
- **XCUITest** for UI tests

### Test Organization

```
I Do BlueprintTests/
├── Accessibility/               # Accessibility compliance tests
│   └── ColorAccessibilityTests.swift
├── Core/
│   ├── Errors/                 # Error handling tests
│   ├── AppStoresTests.swift
│   ├── SingletonTypeTests.swift
│   └── URLValidatorTests.swift
├── Domain/
│   ├── Models/                 # Model tests
│   └── Repositories/           # Repository tests
├── Services/
│   ├── Stores/                 # Store tests (e.g., BudgetStoreV2Tests.swift)
│   └── SecureAPIKeyManagerTests.swift
├── Utilities/
│   ├── InputValidationTests.swift
│   └── RepositoryNetworkTests.swift
├── Helpers/
│   ├── MockRepositories.swift  # Mock implementations for testing
│   ├── MockOnboardingRepository.swift
│   └── ModelBuilders.swift     # Test data builders
├── Integration/                # Integration tests
└── Performance/                # Performance benchmarks
    ├── AppStoresPerformanceTests.swift
    └── RepositoryCacheTests.swift

I Do BlueprintUITests/
├── BudgetFlowUITests.swift
├── DashboardFlowUITests.swift
├── GuestFlowUITests.swift
└── VendorFlowUITests.swift
```

### Testing Philosophy

1. **Mock repositories for unit tests**: All stores are tested with mock repositories
2. **Test data builders**: Use `.makeTest()` factory methods on models for consistent test data
3. **MainActor tests**: Store tests use `@MainActor` since stores are main-actor bound
4. **Dependency injection in tests**: Use `withDependencies` to inject mocks
5. **Accessibility testing**: Automated WCAG 2.1 contrast ratio testing for all colors
6. **UI flow tests**: Test complete user workflows (e.g., budget creation flow)
7. **Performance testing**: Test cache hit rates, query performance, memory usage
8. **Security testing**: Verify RLS policies, multi-tenant isolation
9. **Cache strategy testing**: Test cache invalidation per domain

### Test Naming Conventions

- Test files: `{FeatureName}Tests.swift` or `{FeatureName}UITests.swift`
- Test classes: `final class {FeatureName}Tests: XCTestCase`
- Test methods: `func test{Scenario}_{ExpectedOutcome}()`
- Mock classes: `Mock{Protocol}` (e.g., `MockGuestRepository`)

### Example Test Structure

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

---

## 4. Code Style

### Language-Specific Rules

#### Swift Conventions
- **Swift 5.9+** with modern concurrency (async/await)
- **Strict concurrency checking** enabled
- **Sendable conformance** for types crossing actor boundaries
- **MainActor** for UI-related classes (Views, Stores)
- **nonisolated** for logger methods and pure functions
- **Actor isolation** for thread-safe caching and shared state

#### Async/Await Usage
- Prefer `async/await` over completion handlers
- Use `Task` for fire-and-forget operations
- Use `async let` for parallel operations
- Always handle errors with `do-catch` or `try?`
- Use `NetworkRetry.withRetry()` for network operations

```swift
// ✅ Good: Parallel loading with retry
async let summary = NetworkRetry.withRetry {
    try await repository.fetchBudgetSummary()
}
async let categories = NetworkRetry.withRetry {
    try await repository.fetchCategories()
}
async let expenses = NetworkRetry.withRetry {
    try await repository.fetchExpenses()
}

let summaryResult = try await summary
let categoriesResult = try await categories
let expensesResult = try await expenses
```

#### Type Safety
- Use strong typing (avoid `Any` when possible)
- Prefer enums over string constants
- Use `UUID` for identifiers (never convert to string for queries)
- Use `Codable` for serialization
- Use `LocalizedError` for user-facing errors
- Implement `AppError` protocol for comprehensive error handling

### Naming Conventions

#### Files
- **Views**: `{Feature}{Purpose}View.swift` (e.g., `BudgetDashboardView.swift`)
- **Stores**: `{Feature}StoreV2.swift` (e.g., `BudgetStoreV2.swift`)
- **Models**: `{EntityName}.swift` (e.g., `Guest.swift`, `Expense.swift`)
- **Protocols**: `{Purpose}Protocol.swift` (e.g., `GuestRepositoryProtocol.swift`)
- **Extensions**: `{Type}+{Purpose}.swift` (e.g., `Color+Hex.swift`)
- **Services**: `{Feature}Service.swift` (e.g., `BudgetAggregationService.swift`)
- **Strategies**: `{Domain}CacheStrategy.swift` (e.g., `GuestCacheStrategy.swift`)

#### Classes/Structs
- **Views**: `{Feature}{Purpose}View` (e.g., `DashboardProgressCard`)
- **Stores**: `{Feature}StoreV2` (e.g., `BudgetStoreV2`)
- **Models**: PascalCase nouns (e.g., `Guest`, `BudgetCategory`)
- **Protocols**: `{Purpose}Protocol` (e.g., `GuestRepositoryProtocol`)
- **Services**: `{Feature}Service` (e.g., `BudgetAggregationService`)

#### Variables/Properties
- **camelCase** for all variables and properties
- **Descriptive names**: `totalSpent` not `ts`
- **Boolean prefixes**: `is`, `has`, `should` (e.g., `isLoading`, `hasError`)
- **Published properties**: Use `@Published` for observable state

#### Functions
- **camelCase** with verb prefixes
- **CRUD operations**: `fetch`, `create`, `update`, `delete`
- **Async operations**: Suffix with `async` if ambiguous
- **Loading operations**: `load{Resource}` (e.g., `loadBudgetData()`)

### Documentation

#### Header Comments
```swift
//
//  FileName.swift
//  I Do Blueprint
//
//  Brief description of file purpose
//
```

#### DocStrings for Public APIs
```swift
/// Fetches all guests for the current couple
///
/// Returns guests sorted by creation date (newest first).
/// Results are automatically scoped to the current couple's tenant ID.
///
/// - Returns: Array of guest records
/// - Throws: Repository errors if fetch fails or tenant context is missing
func fetchGuests() async throws -> [Guest]
```

#### MARK Comments
```swift
// MARK: - Section Name
// MARK: Public Interface
// MARK: Private Helpers
// MARK: Computed Properties
// MARK: Sentry Integration
// MARK: Cache Management
```

### Error Handling

#### AppError Protocol
```swift
public protocol AppError: LocalizedError {
    var errorCode: String { get }
    var userMessage: String { get }
    var technicalDetails: String { get }
    var recoveryOptions: [ErrorRecoveryOption] { get }
    var severity: ErrorSeverity { get }
    var shouldReport: Bool { get }
}
```

#### Custom Error Types
```swift
enum BudgetError: Error, LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case tenantContextMissing
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch budget data: \(error.localizedDescription)"
        case .tenantContextMissing:
            return "No couple selected. Please sign in."
        // ...
        }
    }
}
```

#### Centralized Error Handling
```swift
// Use ErrorHandler for centralized error management
ErrorHandler.shared.handle(error, context: ErrorContext(
    operation: "loadBudgetData",
    feature: "budget"
))

// Use StoreErrorHandling extension for consistent store error handling
await handleError(error, operation: "createGuest", context: ["guestName": guest.fullName])
```

#### Error Propagation
- Throw errors from repositories
- Catch and handle in stores using `handleError` extension
- Update loading state on errors
- Log errors with `AppLogger`
- Capture errors with `SentryService`
- Present user-facing errors with `AlertPresenter`

---

## 5. Common Patterns

### Repository Pattern

All data access goes through repository protocols:

```swift
// 1. Define protocol
protocol GuestRepositoryProtocol: Sendable {
    func fetchGuests() async throws -> [Guest]
    func createGuest(_ guest: Guest) async throws -> Guest
    func updateGuest(_ guest: Guest) async throws -> Guest
    func deleteGuest(id: UUID) async throws
}

// 2. Implement live version with cache strategy
class LiveGuestRepository: GuestRepositoryProtocol {
    private let supabase: SupabaseClient
    private let logger = AppLogger.database
    private let cacheStrategy = GuestCacheStrategy()
    
    func fetchGuests() async throws -> [Guest] {
        let cacheKey = "guests_\(tenantId.uuidString)"
        if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }
        
        let guests: [Guest] = try await supabase.database
            .from("guest_list")
            .select()
            .eq("couple_id", value: tenantId) // ✅ Pass UUID directly
            .order("created_at", ascending: false)
            .execute()
            .value
        
        await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
        return guests
    }
    
    func createGuest(_ guest: Guest) async throws -> Guest {
        let created = try await createInDatabase(guest)
        // Use cache strategy for invalidation
        await cacheStrategy.invalidate(for: .guestCreated(tenantId: tenantId))
        return created
    }
}
```

### Domain Services Pattern

Separate complex business logic from repositories:

```swift
// Domain services are actors for thread safety
actor BudgetAggregationService {
    private let repository: BudgetRepositoryProtocol
    
    init(repository: BudgetRepositoryProtocol) {
        self.repository = repository
    }
    
    /// Aggregates data needed by budget overview screens
    func fetchBudgetOverview(scenarioId: String) async throws -> [BudgetOverviewItem] {
        let items = try await repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
        let expenses = try await repository.fetchExpenses()
        let gifts = try await repository.fetchGiftsAndOwed()
        
        // Complex aggregation logic here
        return buildOverviewItems(items: items, expenses: expenses, gifts: gifts)
    }
}

// Usage in repository (delegation pattern)
class LiveBudgetRepository: BudgetRepositoryProtocol {
    private lazy var aggregationService = BudgetAggregationService(repository: self)
    
    func fetchBudgetOverview(scenarioId: String) async throws -> [BudgetOverviewItem] {
        let cacheKey = "budget_overview_\(scenarioId)"
        if let cached: [BudgetOverviewItem] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }
        
        let overview = try await aggregationService.fetchBudgetOverview(scenarioId: scenarioId)
        await RepositoryCache.shared.set(cacheKey, value: overview, ttl: 60)
        return overview
    }
}
```

### Cache Invalidation Strategy Pattern

Use per-domain strategies for maintainable cache management:

```swift
// Define operations that trigger cache invalidation
enum CacheOperation {
    case guestCreated(tenantId: UUID)
    case guestUpdated(tenantId: UUID)
    case guestDeleted(tenantId: UUID)
    case guestBulkImport(tenantId: UUID)
    // ... other operations
}

// Implement strategy per domain
actor GuestCacheStrategy: CacheInvalidationStrategy {
    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .guestCreated(let tenantId),
             .guestUpdated(let tenantId),
             .guestDeleted(let tenantId),
             .guestBulkImport(let tenantId):
            let idString = tenantId.uuidString
            await RepositoryCache.shared.remove("guests_\(idString)")
            await RepositoryCache.shared.remove("guest_stats_\(idString)")
            await RepositoryCache.shared.remove("guest_count_\(idString)")
            await RepositoryCache.shared.remove("guest_groups_\(idString)")
            await RepositoryCache.shared.remove("guest_rsvp_summary_\(idString)")
        default:
            break
        }
    }
}
```

### CacheableStore Protocol

Store-level caching with TTL:

```swift
protocol CacheableStore: AnyObject {
    var lastLoadTime: Date? { get set }
    var cacheValidityDuration: TimeInterval { get }
    func isCacheValid() -> Bool
    func invalidateCache()
}

extension CacheableStore {
    func isCacheValid() -> Bool {
        guard let last = lastLoadTime else { return false }
        return Date().timeIntervalSince(last) < cacheValidityDuration
    }
    
    func invalidateCache() {
        lastLoadTime = nil
    }
}

// Usage in store
@MainActor
class GuestStoreV2: ObservableObject, CacheableStore {
    var lastLoadTime: Date?
    var cacheValidityDuration: TimeInterval { 60 } // 60 seconds
    
    func loadGuests(force: Bool = false) async {
        guard force || !isCacheValid() else { return }
        // Load data...
        lastLoadTime = Date()
    }
}
```

### Timezone-Aware Date Formatting

Always use `DateFormatting` for consistent timezone handling:

```swift
// Get user's timezone from settings
let userTimezone = DateFormatting.userTimeZone(from: settingsStore.settings)

// Format for display (uses user's timezone)
let displayDate = DateFormatting.formatDateMedium(date, timezone: userTimezone)
let relativeDate = DateFormatting.formatRelativeDate(date, timezone: userTimezone)

// Format for database (always UTC)
let dbDate = DateFormatting.formatForDatabase(date)
let dbTimestamp = DateFormatting.formatDateTimeForDatabase(date)

// Parse from database (assumes UTC)
let parsedDate = DateFormatting.parseDateFromDatabase(dateString)

// Calculate days between dates (timezone-aware)
let daysUntil = DateFormatting.daysBetween(from: Date(), to: weddingDate, in: userTimezone)
```

### Real-time Collaboration Pattern

Use `CollaborationRealtimeManager` for real-time features:

```swift
// Connect to realtime channels
await CollaborationRealtimeManager.shared.connect(coupleId: coupleId)

// Listen for collaborator changes
CollaborationRealtimeManager.shared.onCollaboratorChange { change in
    switch change.changeType {
    case .insert:
        // Handle new collaborator
    case .update:
        // Handle collaborator update
    case .delete:
        // Handle collaborator removal
    }
}

// Listen for activity events
CollaborationRealtimeManager.shared.onActivityChange { activity in
    // Update activity feed
}

// Disconnect when done
await CollaborationRealtimeManager.shared.disconnect()
```

### File Import Pattern

Use `FileImportService` for CSV/XLSX imports:

```swift
let importService = FileImportService()

// Parse file
let preview = try await importService.parseCSV(from: fileURL)
// or
let preview = try await importService.parseXLSX(from: fileURL)

// Infer column mappings
let mappings = importService.inferMappings(
    headers: preview.headers,
    targetFields: Guest.importableFields
)

// Validate import
let validation = importService.validateImport(preview: preview, mappings: mappings)
if !validation.isValid {
    // Handle errors
}

// Convert to domain objects
let guests = importService.convertToGuests(
    preview: preview,
    mappings: mappings,
    coupleId: coupleId
)
```

### Store Error Handling Extension

Consistent error handling across all stores:

```swift
extension ObservableObject where Self: AnyObject {
    @MainActor
    func handleError(
        _ error: Error,
        operation: String,
        context: [String: Any]? = nil,
        retry: (() async -> Void)? = nil
    ) async {
        // Log technical error
        AppLogger.database.error("Error in \(operation)", error: error)
        
        // Capture to Sentry
        SentryService.shared.captureError(error, context: context ?? [:])
        
        // Show user-facing error with retry option
        await AlertPresenter.shared.showUserFacingError(
            UserFacingError.from(error),
            retryAction: retry
        )
    }
}

// Usage in store
func createGuest(_ guest: Guest) async {
    do {
        let created = try await repository.createGuest(guest)
        showSuccess("Guest added successfully")
    } catch {
        await handleError(error, operation: "createGuest", context: [
            "guestName": guest.fullName
        ]) { [weak self] in
            await self?.createGuest(guest) // Retry
        }
    }
}
```

### Post-Onboarding Loading Pattern

Sequence data loading with progress updates:

```swift
@MainActor
final class PostOnboardingLoader: ObservableObject {
    @Published private(set) var progress: Double = 0.0
    @Published private(set) var currentMessage: String = "Preparing..."
    @Published private(set) var isFinished: Bool = false
    
    func start(appStores: AppStores, settingsStore: SettingsStoreV2) async {
        let steps: [(String, () async -> Void)] = [
            ("Loading settings...", { await settingsStore.loadSettings(force: true) }),
            ("Loading guests...", { await appStores.guest.loadGuestData() }),
            ("Loading vendors...", { await appStores.vendor.loadVendors() }),
            ("Loading tasks...", { await appStores.task.loadTasks() }),
            ("Loading budget...", { await appStores.budget.loadBudgetData() })
        ]
        
        for (index, (message, action)) in steps.enumerated() {
            currentMessage = message
            await action()
            progress = Double(index + 1) / Double(steps.count)
        }
        
        isFinished = true
    }
}
```

### Store Access Patterns

**CRITICAL**: Never create new store instances in views. Always use the `AppStores` singleton.

#### ✅ Correct Patterns

```swift
// Option 1: Environment Access (Preferred)
struct SettingsView: View {
    @Environment(\.appStores) private var appStores
    
    private var store: SettingsStoreV2 {
        appStores.settings
    }
}

// Option 2: Direct Environment Store Access
struct BudgetView: View {
    @Environment(\.budgetStore) private var store
}

// Option 3: Pass Store as Parameter
struct BudgetDetailView: View {
    @ObservedObject var budgetStore: BudgetStoreV2
}

// Option 4: Direct Singleton Access (Last Resort)
struct QuickAccessView: View {
    private var store: SettingsStoreV2 {
        AppStores.shared.settings
    }
}
```

#### ❌ Anti-Patterns to Avoid

```swift
// ❌ BAD: Creates duplicate store instance
struct SettingsView: View {
    @StateObject private var store = SettingsStoreV2()
}

// ❌ BAD: Creates new instance on each access
struct BudgetView: View {
    var body: some View {
        let store = BudgetStoreV2() // Don't do this!
    }
}
```

#### Available Environment Stores

```swift
@Environment(\.appStores) private var appStores
@Environment(\.budgetStore) private var budgetStore
@Environment(\.guestStore) private var guestStore
@Environment(\.vendorStore) private var vendorStore
@Environment(\.documentStore) private var documentStore
@Environment(\.taskStore) private var taskStore
@Environment(\.timelineStore) private var timelineStore
@Environment(\.notesStore) private var notesStore
@Environment(\.visualPlanningStore) private var visualPlanningStore
```

### UUID Handling Best Practices

#### Core Principles

1. **Pass UUIDs directly to Supabase** - Never convert to string for queries
2. **Minimize string conversions** - Only convert when absolutely necessary
3. **Understand case sensitivity** - Swift returns uppercase, PostgreSQL stores lowercase
4. **Cache string representations** - Reuse converted strings when needed multiple times

```swift
// ✅ GOOD: Pass UUID directly to Supabase
let guests: [Guest] = try await supabase.database
    .from("guest_list")
    .select()
    .eq("couple_id", value: tenantId) // UUID type
    .execute()
    .value

// ❌ BAD: Converting to string
.eq("couple_id", value: tenantId.uuidString) // Don't do this!

// ✅ GOOD: Convert once for cache operations
let tenantIdString = tenantId.uuidString
await cache.remove("guests_\(tenantIdString)")
await cache.remove("stats_\(tenantIdString)")

// ✅ GOOD: Normalize for dictionary keys when mixing sources
let itemId = allocation.budgetItemId.uuidString.lowercased()
allocationsByItem[itemId, default: []].append(allocation)
```

---

## 6. Do's and Don'ts

### ✅ Do's

1. **Use dependency injection** for all external dependencies
2. **Log all data operations** with `AppLogger` (category-specific loggers)
3. **Handle errors gracefully** with `handleError` extension and `ErrorHandler`
4. **Use MARK comments** to organize code sections
5. **Follow the repository pattern** for all data access
6. **Use Domain Services** for complex business logic
7. **Use cache invalidation strategies** per domain
8. **Use LoadingState enum** for async operations
9. **Implement optimistic updates** with rollback for better UX
10. **Use design system constants** (AppColors, Typography, Spacing)
11. **Add accessibility labels** to all interactive elements
12. **Test with mock repositories** for unit tests
13. **Use async/await** for asynchronous operations
14. **Document public APIs** with DocStrings
15. **Use strong typing** and avoid `Any` when possible
16. **Conform to Sendable** for types crossing actor boundaries
17. **Use @MainActor** for UI-related classes
18. **Cache frequently accessed data** with `RepositoryCache`
19. **Use NetworkRetry** for resilient network operations
20. **Track errors with Sentry** for production monitoring
21. **Pass UUIDs directly** to Supabase queries (not strings)
22. **Use DateFormatting** for all date display and storage
23. **Use security-scoped resources** for file access
24. **Validate all external URLs** before use
25. **Test RLS policies** for multi-tenant isolation
26. **Use CacheableStore** for store-level caching

### ❌ Don'ts

1. **Don't access Supabase directly** from views or stores (use repositories)
2. **Don't use hardcoded colors** (use AppColors)
3. **Don't use hardcoded spacing** (use Spacing constants)
4. **Don't ignore errors** (always log and handle with `handleError`)
5. **Don't use completion handlers** (prefer async/await)
6. **Don't create singletons** without careful consideration
7. **Don't skip accessibility** labels and hints
8. **Don't use force unwrapping** (`!`) without clear justification
9. **Don't mix UI and business logic** (keep views thin)
10. **Don't create massive view files** (break into components)
11. **Don't skip MARK comments** in files over 100 lines
12. **Don't use magic numbers** (create named constants)
13. **Don't log sensitive data** (use AppLogger's redaction methods)
14. **Don't create new stores** without following V2 pattern
15. **Don't bypass the loading state pattern** for async operations
16. **Don't convert UUIDs to strings** for database queries
17. **Don't use URLSession** for local file access
18. **Don't skip cache invalidation** on mutations
19. **Don't use `auth.uid()`** directly in RLS policies (use `(SELECT auth.uid())`)
20. **Don't create indexes** without verifying usage
21. **Don't skip Sentry integration** for production code
22. **Don't use mutable search_path** in database functions
23. **Don't expose data across tenants** (always filter by `couple_id`)
24. **Don't use TimeZone.current** for display (use user's configured timezone)
25. **Don't store dates in local timezone** in database (always UTC)
26. **Don't scatter cache invalidation** (use cache strategies)

---

## 7. Tools & Dependencies

### Core Dependencies

- **SwiftUI** - UI framework
- **Combine** - Reactive programming (for @Published)
- **Supabase** - Backend as a service (database, auth, storage, realtime)
- **Dependencies** - Dependency injection framework (Point-Free)
- **OSLog** - Structured logging
- **Sentry** - Error tracking and performance monitoring
- **CoreXLSX** - Excel file parsing for imports

### Key Libraries

- **SupabaseClient** - Supabase Swift client
- **Realtime** - Supabase Realtime for collaboration
- **SentrySDK** - Sentry error tracking
- **SentrySwiftUI** - Sentry SwiftUI integration
- **GoogleAuthManager** - Google OAuth integration
- **GoogleDriveManager** - Google Drive integration
- **GoogleSheetsManager** - Google Sheets export
- **Resend** - Email service for invitations

### Development Tools

- **Xcode** - Primary IDE
- **Swift Package Manager** - Dependency management
- **XCTest** - Testing framework
- **Instruments** - Performance profiling
- **Sentry Dashboard** - Error monitoring and analytics
- **SwiftLint** - Code linting

### Project Setup

1. **Clone repository**
2. **Open `I Do Blueprint.xcodeproj`**
3. **Configure Supabase credentials** in `Config.plist`
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
4. **Configure Sentry DSN** in `Config.plist`
   - `SENTRY_DSN`
5. **Configure Google OAuth** credentials
   - `GOOGLE_CLIENT_ID`
6. **Build and run** (⌘R)

### Environment Configuration

- **Config.plist** - Contains API keys and configuration
- **Supabase URL and Anon Key** required
- **Sentry DSN** required for error tracking
- **Google OAuth Client ID** required for Google integration
- **Resend API Key** optional (embedded key available for shared service)
- **Multi-tenant setup** - Each couple has a unique tenant ID (`couple_id`)

---

## 8. Workflow Management with Basic Memory & Beads

This project uses **two complementary tools** for optimal AI-assisted development workflows:

### Tools Overview

| Tool | Basic Memory | Beads |
|------|-------------|-------|
| **Purpose** | Knowledge management | Issue tracking |
| **Focus** | WHY & WHAT | HOW & WHEN |
| **Time Horizon** | Long-term (months/years) | Short-term (days/weeks) |
| **Storage** | Markdown files (semantic graph) | JSONL files (dependency graph) |
| **Access** | MCP tools | CLI commands |
| **Integration** | Claude Code, Claude Desktop | Git-native |

### When to Use Each Tool

**Use Basic Memory For:**
- Architectural decisions and ADRs
- Technical documentation and patterns
- Research and investigation results
- Domain knowledge and business rules
- Common pitfalls and solutions
- Code standards and conventions

**Use Beads For:**
- Feature development tracking
- Bug fixes and technical tasks
- Work prioritization (P0-P4)
- Dependency management
- Session continuity
- Active work status

### Essential Workflows

#### 1. Research → Plan → Execute → Document

```bash
# RESEARCH (Basic Memory)
mcp__basic-memory__search_notes("repository pattern", project: "i-do-blueprint")
mcp__basic-memory__read_note("Cache Strategy", project: "i-do-blueprint")

# PLAN (Beads)
bd create "Implement guest import feature" -t feature -p 1
bd create "Add CSV validation" -t task -p 1
bd dep add beads-xxx beads-yyy

# EXECUTE (Beads)
bd ready
bd update beads-xxx --status=in_progress
# [Write code, run tests]
bd close beads-xxx

# DOCUMENT (Basic Memory)
mcp__basic-memory__write_note(
  title: "CSV Import Pattern",
  folder: "architecture/data-import",
  project: "i-do-blueprint"
)
```

#### 2. Problem → Investigate → Fix → Learn

```bash
# PROBLEM (Beads)
bd create "UUID case mismatch bug" -t bug -p 0

# INVESTIGATE (Basic Memory)
mcp__basic-memory__search_notes("UUID handling", project: "i-do-blueprint")

# FIX (Beads)
bd update beads-xxx --status=in_progress
# [Apply fix, test, commit]
bd close beads-xxx

# LEARN (Basic Memory)
mcp__basic-memory__write_note(
  title: "Common Pitfall - UUID String Conversion",
  folder: "troubleshooting",
  project: "i-do-blueprint"
)
```

#### 3. Session Start Protocol

```bash
# 1. Restore context (Basic Memory)
mcp__basic-memory__recent_activity(timeframe: "7d", project: "i-do-blueprint")
mcp__basic-memory__build_context(url: "projects/i-do-blueprint")

# 2. Check active work (Beads)
bd ready                     # What's ready to work?
bd list --status=in_progress # What was I working on?
bd blocked                   # What's blocked?

# 3. Select next task (Beads)
bd show beads-xxx
bd update beads-xxx --status=in_progress

# 4. Load relevant knowledge (Basic Memory)
mcp__basic-memory__search_notes("relevant topic", project: "i-do-blueprint")
```

#### 4. Session End Protocol

```bash
# 1. Complete work items (Beads)
bd close beads-xxx beads-yyy beads-zzz
bd update beads-aaa --status=blocked

# 2. Document new knowledge (Basic Memory)
mcp__basic-memory__write_note(
  title: "Pattern Name",
  content: "...",
  folder: "architecture/patterns",
  project: "i-do-blueprint"
)

# 3. Sync to git (Beads)
bd sync
```

### Basic Memory Command Reference

```bash
# Reading
mcp__basic-memory__read_note(identifier: "Note Title", project: "i-do-blueprint")
mcp__basic-memory__search_notes(query: "search terms", project: "i-do-blueprint")
mcp__basic-memory__build_context(url: "architecture/*", project: "i-do-blueprint")

# Writing
mcp__basic-memory__write_note(
  title: "Note Title",
  content: "...",
  folder: "architecture/patterns",
  tags: ["tag1", "tag2"],
  project: "i-do-blueprint"
)

mcp__basic-memory__edit_note(
  identifier: "Note Title",
  operation: "append",
  content: "\n## New Section",
  project: "i-do-blueprint"
)
```

### Beads Command Reference

```bash
# Creating & Managing
bd create "Task title" -p 0              # Priority 0 (critical)
bd create "Feature title" -t feature -p 1
bd create "Bug title" -t bug -p 0
bd update beads-xxx --status=in_progress
bd close beads-xxx

# Querying
bd ready                                 # Tasks ready to work
bd list --status=open                    # All open tasks
bd blocked                               # All blocked tasks
bd show beads-xxx                        # Full task details

# Dependencies
bd dep add beads-child beads-parent     # child depends on parent

# Sync
bd sync                                  # Commit and push changes
```

### Best Practices

1. **Separation of Concerns**
   - Basic Memory = Knowledge that outlives individual tasks
   - Beads = Current sprint/week work items

2. **Cross-Referencing**
   - Reference Beads tasks in Basic Memory notes
   - Link Basic Memory docs in Beads task notes

3. **Documentation Timing**
   - Document AFTER completing work, not before
   - Capture patterns and decisions, not implementation details

4. **Task Granularity**
   - Beads tasks: Completable in < 1 day
   - Basic Memory notes: 1000-3000 words, comprehensive

5. **Priority Alignment**
   - P0 (Critical) → Document immediately
   - P1 (High) → Document if novel pattern
   - P2+ → Document only if architecturally significant

### Knowledge Repository Structure

The `knowledge-repo-bm/` directory (Basic Memory project: `i-do-blueprint`) contains:

```
knowledge-repo-bm/
├── architecture/         # Architecture patterns, decisions
│   ├── caching/
│   ├── models/
│   ├── repositories/
│   ├── services/
│   └── stores/
├── database/            # Database schema, migrations
├── security/            # Security patterns, RLS
├── testing/             # Testing infrastructure
├── project-management/  # Beads integration notes
├── projects/            # Project-wide context
│   └── i-do-blueprint/
└── quick-reference/     # Quick lookup guides
```

### Decision Tree

```
Is this information needed in 6 months?
├─ YES → Basic Memory
│  └─ Architecture decisions, patterns, pitfalls
│
└─ NO → Beads
   └─ "Fix bug X", "Add feature Y", "Refactor Z"

Will this help understand future code?
├─ YES → Basic Memory
│  └─ Why we chose X, How pattern Y works
│
└─ NO → Beads
   └─ Task status, blocking relationships

Is this actionable work?
├─ YES → Beads
│  └─ Create task, track progress, mark complete
│
└─ NO → Basic Memory
   └─ Document context, record decision
```

### For More Information

See **`BASIC-MEMORY-AND-BEADS-GUIDE.md`** for:
- Complete workflow patterns
- Real-world examples
- Integration setup
- Detailed command reference
- Advanced use cases

---

## 9. Other Notes

### For LLMs Generating Code

#### State Management
- All stores should be `@MainActor` and `ObservableObject`
- Use `@Published` for observable state
- Use `@Dependency` for injecting repositories
- Follow the V2 store pattern (see `BudgetStoreV2.swift`)
- Implement `CacheableStore` for store-level caching
- Use `handleError` extension for consistent error handling

#### Data Flow
```
[UI] ──> Stores ──> Repositories (CRUD, cache, network)
                     │
                     └──> Domain Services (business rules)
                               │
                               └──> Repositories (helper reads/writes)
```

1. **View** → calls method on **Store**
2. **Store** → calls method on **Repository**
3. **Repository** → checks **Cache** first
4. **Repository** → delegates to **Domain Service** for complex logic (if needed)
5. **Repository** → makes API call to **Supabase** (if cache miss)
6. **Repository** → uses **Cache Strategy** to invalidate on mutations
7. **Repository** → caches result and returns data to **Store**
8. **Store** → updates `@Published` properties
9. **View** → automatically re-renders

#### Loading States
Always use the `LoadingState<T>` pattern:
```swift
@Published var loadingState: LoadingState<Data> = .idle

switch store.loadingState {
case .idle: Text("Tap to load")
case .loading: ProgressView()
case .loaded(let data): DataView(data: data)
case .error(let error): ErrorView(error: error)
}
```

#### Logging
Use category-specific loggers:
```swift
private let logger = AppLogger.database
logger.info("Operation succeeded")
logger.error("Operation failed", error: error)
logger.debug("Debug info") // Only in DEBUG builds
```

#### Timezone Handling
Always use `DateFormatting` utilities:
```swift
// Display: Use user's timezone
let userTimezone = DateFormatting.userTimeZone(from: settings)
let formatted = DateFormatting.formatDateMedium(date, timezone: userTimezone)

// Database: Always UTC
let dbString = DateFormatting.formatForDatabase(date)
let parsed = DateFormatting.parseDateFromDatabase(dbString)
```

#### Cache Invalidation
Use domain-specific cache strategies:
```swift
// In repository mutation
func createGuest(_ guest: Guest) async throws -> Guest {
    let created = try await createInDatabase(guest)
    await cacheStrategy.invalidate(for: .guestCreated(tenantId: tenantId))
    return created
}
```

#### Multi-Tenancy
- All data is scoped by `couple_id` (tenant ID)
- Repositories automatically filter by current couple
- Never expose data across tenants
- Always pass UUID directly to queries (not `.uuidString`)
- RLS policies enforce security at database level

#### RLS Policy Pattern
All multi-tenant tables use a single `FOR ALL` policy:
```sql
CREATE POLICY "couples_manage_own_{resource}"
  ON {table_name}
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());
```

#### Real-time Collaboration
- Use `CollaborationRealtimeManager` for presence and activity
- Connect on app launch, disconnect on logout
- Handle reconnection with exponential backoff
- Use Supabase Realtime channels per couple

#### When Adding New Features
1. Create domain model in `Domain/Models/{Feature}/`
2. Create repository protocol in `Domain/Repositories/Protocols/`
3. Implement live repository in `Domain/Repositories/Live/`
   - Add caching with `RepositoryCache`
   - Add cache strategy in `Domain/Repositories/Caching/`
   - Add retry logic with `NetworkRetry`
   - Add error tracking with `SentryService`
4. (Optional) Create domain service in `Domain/Services/` for complex logic
5. Implement mock repository in `I Do BlueprintTests/Helpers/MockRepositories.swift`
6. Register repository in `Core/Common/Common/DependencyValues.swift`
7. Create store in `Services/Stores/{Feature}StoreV2.swift`
   - Use `LoadingState<T>` pattern
   - Implement `CacheableStore` if needed
   - Use `handleError` extension
   - Add Sentry tracking
8. Create views in `Views/{Feature}/`
   - Use design system constants
   - Add accessibility labels
   - Keep views under 300 lines
9. Add tests in `I Do BlueprintTests/Services/Stores/`
   - Test with mock repositories
   - Test error cases
   - Test cache behavior
10. Add database migration if needed
    - Enable RLS on new tables
    - Add `couple_id` column for multi-tenancy
    - Create RLS policy: `FOR ALL USING (couple_id = get_user_couple_id())`
    - Add indexes on foreign keys
11. Update this document with new patterns

#### Common Pitfalls
1. **Forgetting @MainActor** on stores → runtime crashes
2. **Not handling loading states** → poor UX
3. **Skipping error handling** → silent failures
4. **Using hardcoded colors** → accessibility issues
5. **Not testing with mocks** → brittle tests
6. **Mixing concerns** → hard to maintain
7. **Converting UUIDs to strings** → case mismatch bugs
8. **Using URLSession for local files** → security-scoped resource errors
9. **Not invalidating caches** → stale data
10. **Skipping Sentry integration** → production issues go unnoticed
11. **Using `auth.uid()` directly** → RLS performance issues
12. **Not using NetworkRetry** → poor network resilience
13. **Using TimeZone.current** → inconsistent date display
14. **Scattering cache invalidation** → missed invalidations
15. **Creating store instances in views** → memory explosion

---

**Last Updated:** December 2025  
**Architecture Version:** V2 (Repository Pattern with Domain Services, Cache Strategies & Monitoring)  
**Swift Version:** 5.9+  
**Platform:** macOS 13.0+  
**Backend:** Supabase (PostgreSQL with RLS)  
**Monitoring:** Sentry
