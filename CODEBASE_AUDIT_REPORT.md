# I Do Blueprint - Codebase Audit Report

**Date**: 2025-12-30
**Scope**: Architecture patterns, conventions, critical patterns, and tech stack
**Swift Files Analyzed**: 2,377
**Project Type**: macOS SwiftUI + Supabase backend wedding planning application

---

## 1. ACTUAL ARCHITECTURE PATTERNS

### 1.1 Store Patterns (V2 Naming Convention)

**Pattern**: @MainActor ObservableObject with lazy initialization and composition

**Actual Implementation**:
- All stores use `@MainActor` decorator on class definition
- Stores conform to `ObservableObject` and `CacheableStore` protocol
- Stores use `@Published` for reactive state
- Stores use `@Dependency(\.repositoryName)` for dependency injection
- Task tracking for cancellation: `private var loadTask: Task<Void, Never>?`

**Files**:
- `/I Do Blueprint/Services/Stores/BudgetStoreV2.swift` - Composition root with 6 sub-stores
- `/I Do Blueprint/Services/Stores/GuestStoreV2.swift`
- `/I Do Blueprint/Services/Stores/VendorStoreV2.swift`
- `/I Do Blueprint/Services/Stores/TaskStoreV2.swift`
- `/I Do Blueprint/Services/Stores/NotesStoreV2.swift`
- (13 total V2 stores)

**BudgetStoreV2 Sub-Store Composition**:
```swift
@MainActor
class BudgetStoreV2: ObservableObject, CacheableStore {
    public var affordability: AffordabilityStore
    public var payments: PaymentScheduleStore
    public var gifts: GiftsStore
    public var expenseStore: ExpenseStoreV2
    public var categoryStore: CategoryStoreV2
    public var development: BudgetDevelopmentStoreV2
}
```

**Critical Pattern**: Views access sub-stores DIRECTLY, NOT through delegation methods:
```swift
// ✅ CORRECT
await budgetStore.categoryStore.addCategory(category)

// ❌ WRONG (not implemented)
await budgetStore.addCategory(category)
```

**Loading State Pattern**:
```swift
@Published var loadingState: LoadingState<T> = .idle
```
Enum with cases: `.idle`, `.loading`, `.loaded(T)`, `.error(Error)`

**Cache Management**:
```swift
var lastLoadTime: Date?
let cacheValidityDuration: TimeInterval = 300 // 5 minutes

func isCacheValid() -> Bool {
    guard case .loaded = loadingState,
          let last = lastLoadTime else { return false }
    return Date().timeIntervalSince(last) < cacheValidityDuration
}
```

---

### 1.2 Repository Pattern (Protocol/Live/Mock Structure)

**Directory Structure**:
```
Domain/Repositories/
├── Protocols/          # 14 protocol files
│   ├── GuestRepositoryProtocol.swift
│   ├── BudgetRepositoryProtocol.swift
│   ├── VendorRepositoryProtocol.swift
│   ├── DocumentRepositoryProtocol.swift
│   ├── TaskRepositoryProtocol.swift
│   ├── TimelineRepositoryProtocol.swift
│   ├── VisualPlanningRepositoryProtocol.swift
│   ├── SettingsRepositoryProtocol.swift
│   ├── NotesRepositoryProtocol.swift
│   ├── OnboardingRepositoryProtocol.swift
│   ├── CollaborationRepositoryProtocol.swift
│   ├── ActivityFeedRepositoryProtocol.swift
│   ├── PresenceRepositoryProtocol.swift
│   └── RepositoryProtocols.swift (CoupleRepositoryProtocol, etc.)
├── Live/              # 12 live implementations (all as actors)
│   ├── LiveGuestRepository.swift
│   ├── LiveBudgetRepository.swift
│   ├── LiveVendorRepository.swift
│   ├── Internal/      # Data source actors
│   │   ├── GiftsAndOwedDataSource.swift
│   │   ├── ExpenseDataSource.swift
│   │   ├── BudgetDevelopmentDataSource.swift
│   │   ├── AffordabilityDataSource.swift
│   │   ├── PaymentScheduleDataSource.swift
│   │   └── BudgetCategoryDataSource.swift
│   └── ...
├── Mock/              # 10 mock implementations
│   ├── MockGuestRepository.swift
│   ├── MockBudgetRepository.swift
│   └── ...
├── Caching/           # Cache strategy per domain
│   ├── GuestCacheStrategy.swift
│   ├── BudgetCacheStrategy.swift
│   ├── TaskCacheStrategy.swift
│   ├── DocumentCacheStrategy.swift
│   ├── TimelineCacheStrategy.swift
│   ├── VendorCacheStrategy.swift
│   ├── CacheConfiguration.swift    # NEW: Standardized key prefixes
│   ├── CacheMonitor.swift          # NEW: Health monitoring
│   └── RepositoryCache.swift       # Actor-based cache
└── RepositoryCache.swift

```

**Protocol Implementation Pattern**:
```swift
// Protocol (Sendable)
protocol GuestRepositoryProtocol: Sendable {
    func fetchGuests() async throws -> [Guest]
    func fetchGuestStats() async throws -> GuestStats
    func createGuest(_ guest: Guest) async throws -> Guest
    func updateGuest(_ guest: Guest) async throws -> Guest
    func deleteGuest(id: UUID) async throws
}

// Live implementation (actor)
actor LiveGuestRepository: GuestRepositoryProtocol {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.repository
    private let cacheStrategy = GuestCacheStrategy()
    private let sessionManager: SessionManager

    // In-flight request de-duplication
    private var inFlightGuests: [UUID: Task<[Guest], Error>] = [:]

    func fetchGuests() async throws -> [Guest] {
        let tenantId = try await getTenantId()
        let cacheKey = "guests_\(tenantId.uuidString)"

        // ✅ Check cache first
        if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: guests (\(cached.count) items)")
            return cached
        }

        // Coalesce in-flight requests per-tenant
        if let task = inFlightGuests[tenantId] {
            return try await task.value
        }

        let task = Task<[Guest], Error> { [weak self] in
            guard let self = self else { throw CancellationError() }
            let client = try await self.getClient()
            let guests: [Guest] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("guest_list")
                    .select()
                    .eq("couple_id", value: tenantId)  // ✅ UUID type, not string
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }
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
}
```

**Critical Implementation Details**:
1. All Live repositories are `actor` types for thread safety
2. In-flight request coalescing to prevent duplicate API calls
3. Cache strategy injection per repository
4. UUID passed directly to Supabase (NOT `.uuidString`)
5. RepositoryNetwork.withRetry for resilience
6. Tenant context via TenantContextProvider

---

### 1.3 Dependency Injection (DependencyValues)

**File**: `/I Do Blueprint/Core/Common/Common/DependencyValues.swift`

**Pattern**:
```swift
private enum LiveRepositories {
    static let budget: any BudgetRepositoryProtocol = LiveBudgetRepository()
    static let guest: any GuestRepositoryProtocol = LiveGuestRepository()
    static let vendor: any VendorRepositoryProtocol = LiveVendorRepository()
    // ... 11 more repositories
}

// Each repository has a DependencyKey
private enum BudgetRepositoryKey: DependencyKey {
    static let liveValue: any BudgetRepositoryProtocol = LiveRepositories.budget
    static let testValue: any BudgetRepositoryProtocol = MockBudgetRepository()
    static let previewValue: any BudgetRepositoryProtocol = MockBudgetRepository()
}

// Extension for easy access
extension DependencyValues {
    var budgetRepository: any BudgetRepositoryProtocol {
        get { self[BudgetRepositoryKey.self] }
        set { self[BudgetRepositoryKey.self] = newValue }
    }
}
```

**Usage in Stores**:
```swift
@Dependency(\.budgetRepository) var repository

// Used in methods:
let data = try await repository.fetchBudgetData()
```

**Usage in Tests**:
```swift
await withDependencies {
    let mockRepo = MockBudgetRepository()
    mockRepo.categories = [.makeTest()]
    $0.budgetRepository = mockRepo
} operation: {
    let store = BudgetStoreV2()
    await store.loadBudgetData()
}
```

**Registered Dependencies** (14 total):
- budgetRepository
- guestRepository
- vendorRepository
- documentRepository
- taskRepository
- timelineRepository
- visualPlanningRepository
- settingsRepository
- notesRepository
- onboardingRepository
- budgetAllocationService
- alertPresenter

---

### 1.4 Concurrency Patterns

**@MainActor Pattern** (All stores):
```swift
@MainActor
class BudgetStoreV2: ObservableObject {
    // UI state only on main thread
    @Published var loadingState: LoadingState<BudgetData> = .idle

    func loadData() async {
        loadingState = .loading  // Safe: runs on MainActor

        do {
            let data = try await repository.fetchData()  // Repository is actor
            loadingState = .loaded(data)
        } catch {
            loadingState = .error(error)
        }
    }
}
```

**Actor-Based Repositories**:
All Live repositories are `actor` types for thread-safe access from Store threads:
```swift
actor LiveGuestRepository: GuestRepositoryProtocol {
    func fetchGuests() async throws -> [Guest] {
        // Automatically isolated to repository's actor
    }
}
```

**Other Actors** (11 found):
- `TenantContextProvider` - Manages current couple/tenant ID
- `UserContextProvider` - Manages authenticated user
- `OfflineCache` - Thread-safe offline storage
- `ErrorTracker` - Thread-safe error tracking
- `RepositoryCache` - Thread-safe caching
- `GiftsAndOwedDataSource` - Parallel data fetching
- `ExpenseDataSource` - Parallel data fetching
- `BudgetDevelopmentDataSource` - Parallel data fetching
- `AffordabilityDataSource` - Parallel data fetching
- `PaymentScheduleDataSource` - Parallel data fetching
- `BudgetCategoryDataSource` - Parallel data fetching

**Sendable Conformance**:
- 72 instances of `Sendable` conformance in codebase
- All protocol types conform: `protocol XRepositoryProtocol: Sendable`
- Models that cross actor boundaries must conform
- Exception: `Guest` contains `NSImage` (non-Sendable), blocking pagination

**nonisolated Helpers**:
```swift
// Logger methods marked nonisolated for Sendable compliance
nonisolated func debug(_ message: String) {
    Task { @MainActor in
        logger.debug(message)
    }
}
```

---

## 2. CONVENTIONS OBSERVED IN CODE

### 2.1 File Naming

**Consistent Patterns**:

| Category | Pattern | Examples |
|----------|---------|----------|
| Views | `{Feature}{Purpose}View.swift` | `BudgetDashboardView.swift`, `GuestListView.swift`, `VendorDetailViewV3.swift` |
| Stores | `{Feature}StoreV2.swift` | `BudgetStoreV2.swift`, `GuestStoreV2.swift` |
| Sub-Stores | `{Feature}Store.swift` | `AffordabilityStore.swift`, `PaymentScheduleStore.swift` |
| Models | `{EntityName}.swift` | `Guest.swift`, `BudgetCategory.swift` |
| Protocols | `{Purpose}Protocol.swift` | `GuestRepositoryProtocol.swift`, `CacheInvalidationStrategy.swift` |
| Implementations | `Live{Entity}Repository.swift` | `LiveGuestRepository.swift` |
| Mocks | `Mock{Entity}Repository.swift` | `MockGuestRepository.swift` |
| Strategies | `{Domain}CacheStrategy.swift` | `GuestCacheStrategy.swift`, `BudgetCacheStrategy.swift` |
| Extensions | `{Type}+{Purpose}.swift` | `Color+Hex.swift`, `Notification+Extensions.swift` |
| Services | `{Feature}Service.swift` | `FileImportService.swift`, `BudgetAggregationService.swift` |

**Version Numbering**:
- V1 = Legacy (deprecated)
- V2 = Current architecture (stores, repositories)
- V3 = UI refinement (views only, e.g., VendorDetailViewV3)

---

### 2.2 Directory Structure (Actual)

```
I Do Blueprint/
├── App/                          # Entry point
│   ├── AppDelegate.swift
│   ├── App.swift                 # @main
│   └── RootFlowView.swift
│
├── Core/
│   ├── Common/
│   │   ├── Analytics/            # ErrorTracker, PerformanceMonitor
│   │   ├── Auth/                 # SessionManager, TenantContext, UserContext
│   │   ├── Common/               # AppStores, DependencyValues
│   │   ├── Errors/               # AppError, ErrorHandler, UserFacingError
│   │   └── Storage/              # OfflineCache, KeychainService
│   ├── Configuration/            # AppConfig.swift
│   ├── Extensions/               # Color+Hex, Notification+Extensions, etc.
│   └── Security/                 # ConfigValidator, URLValidator
│
├── Design/
│   ├── DesignSystem.swift
│   ├── ColorPalette.swift        # AppColors with semantic naming
│   ├── Typography.swift
│   ├── Spacing.swift
│   ├── Shadows.swift
│   ├── Gradients.swift
│   ├── Animations.swift
│   ├── Components.swift
│   └── Accessibility/            # Color audit files (WCAG compliance)
│
├── Domain/
│   ├── Models/
│   │   ├── Budget/               # 15+ budget-related models
│   │   ├── Guest/                # 8+ guest-related models
│   │   ├── Vendor/               # 6+ vendor models
│   │   ├── Document/
│   │   ├── Task/
│   │   ├── Timeline/
│   │   ├── VisualPlanning/
│   │   ├── Collaboration/
│   │   ├── Dashboard/
│   │   ├── Note(s)/
│   │   ├── Onboarding/
│   │   ├── Settings/
│   │   └── Shared/               # Common types (errors, enums)
│   │
│   ├── Repositories/
│   │   ├── Protocols/            # 14 protocol files
│   │   ├── Live/                 # 12 actor implementations + Internal/ data sources
│   │   ├── Mock/                 # 10 test implementations
│   │   └── Caching/              # 6 cache strategies + RepositoryCache, CacheConfiguration, CacheMonitor
│   │
│   └── Services/                 # 1 domain service (BudgetAllocationService)
│
├── Services/
│   ├── Stores/                   # 13 stores + sub-stores (Budget/ subdirectory)
│   │   ├── BudgetStoreV2.swift
│   │   ├── Budget/               # 6 sub-stores
│   │   ├── GuestStoreV2.swift
│   │   ├── VendorStoreV2.swift
│   │   ├── TaskStoreV2.swift
│   │   ├── NotesStoreV2.swift
│   │   ├── VisualPlanningStoreV2.swift
│   │   ├── SettingsStoreV2.swift
│   │   ├── Settings/             # Sub-stores
│   │   ├── TimelineStoreV2.swift
│   │   ├── DocumentStoreV2.swift
│   │   ├── OnboardingStoreV2.swift
│   │   ├── CollaborationStoreV2.swift
│   │   ├── PresenceStoreV2.swift
│   │   ├── ActivityFeedStoreV2.swift
│   │   ├── StoreErrorHandling.swift
│   │   └── CacheableStore.swift
│   │
│   ├── API/                      # Supabase API clients
│   │   ├── DocumentsAPI.swift
│   │   ├── TimelineAPI.swift
│   │   ├── Documents/            # Module
│   │   └── Timeline/             # Module
│   │
│   ├── Auth/                     # SessionManager, auth helpers
│   ├── Export/                   # Google Sheets export
│   ├── Import/                   # CSV/XLSX import
│   ├── UI/                       # Alert presenter, toast service
│   ├── VisualPlanning/           # MoodBoard, seating, search
│   ├── Analytics/                # Sentry integration
│   ├── Avatar/                   # Avatar caching
│   ├── Collaboration/            # Realtime collaboration
│   ├── Email/                    # Email service
│   ├── Realtime/                 # Supabase realtime
│   ├── Navigation/               # Navigation state
│   ├── Loaders/                  # Data loaders
│   ├── Storage/                  # File storage
│   └── Integration/              # Third-party integrations
│
├── Utilities/
│   ├── Logging/                  # AppLogger (12 categories), LoggingConfiguration
│   ├── NetworkRetry.swift        # Exponential backoff retry
│   ├── RepositoryNetwork.swift   # Network + offline cache + timeout
│   ├── DateFormatting.swift      # Timezone-aware date handling
│   ├── PaymentScheduleCalculator.swift
│   ├── CategoryIcons.swift
│   ├── DebouncedState.swift
│   ├── HapticFeedback.swift
│   ├── AccessibilityExtensions.swift
│   ├── AnimationPresets.swift
│   ├── RectangularTableLayoutManager.swift
│   └── Validation/               # InputValidation.swift
│
├── Views/                        # Feature-organized UI
│   ├── Auth/                     # Authentication flows
│   ├── Authentication/           # Alternative auth
│   ├── Budget/                   # Budget UI
│   ├── Guests/                   # Guest management
│   ├── Vendors/                  # Vendor management
│   ├── Tasks/                    # Task management
│   ├── Timeline/                 # Timeline visualization
│   ├── Documents/                # Document management
│   ├── Notes/                    # Notes feature
│   ├── Settings/                 # Settings UI
│   ├── Dashboard/                # Dashboard view
│   ├── Collaboration/            # Collaboration UI
│   ├── Onboarding/               # Onboarding flows
│   ├── VisualPlanning/           # Mood boards, seating, search
│   └── Shared/                   # Reusable components
│
└── Resources/
    ├── Assets.xcassets
    ├── Lottie/
    └── Sample CSVs

```

---

### 2.3 Error Handling Patterns

**Unified Error Handling Extension**:
```swift
// StoreErrorHandling.swift
extension ObservableObject where Self: AnyObject {
    @MainActor
    func handleError(
        _ error: Error,
        operation: String,
        context: [String: Any]? = nil,
        retry: (() async -> Void)? = nil
    ) async {
        let userError = UserFacingError.from(error)

        // Log technical error
        AppLogger.database.error("Error in \(operation)", error: error)

        // Capture to Sentry with context
        var sentryContext = context ?? [:]
        sentryContext["operation"] = operation
        sentryContext["timestamp"] = Date().ISO8601Format()
        sentryContext["errorType"] = String(describing: type(of: error))

        SentryService.shared.captureError(error, context: sentryContext)

        // Add breadcrumb
        SentryService.shared.addBreadcrumb(
            message: "Error in \(operation): \(error.localizedDescription)",
            category: "error",
            level: .error,
            data: sentryContext
        )

        // Show user-facing error with retry
        await AlertPresenter.shared.showUserFacingError(userError, retryAction: retry)
    }
}
```

**Usage in Stores**:
```swift
func createGuest(_ guest: Guest) async {
    do {
        let created = try await repository.createGuest(guest)
        showSuccess("Guest added successfully")
    } catch {
        await handleError(error, operation: "createGuest", context: [
            "guestName": guest.fullName
        ]) { [weak self] in
            await self?.createGuest(guest) // Retry closure
        }
    }
}
```

**Error Types**:
- Repository errors: `GuestError`, `BudgetError`, `VendorError`
- Network errors: `NetworkError` (timeout, connectionFailed)
- Domain errors: Custom per-domain errors
- User-facing: `UserFacingError` (localized message for UI)

---

### 2.4 Logging Patterns

**Categories** (12 total):
```swift
enum LogCategory: String {
    case api = "API"
    case repository = "Repository"
    case ui = "UI"
    case export = "Export"
    case auth = "Auth"
    case storage = "Storage"
    case analytics = "Analytics"
    case network = "Network"
    case database = "Database"
    case cache = "Cache"
    case general = "General"
}
```

**Static Loggers**:
```swift
let logger = AppLogger.repository      // In repositories
let logger = AppLogger.database        // In stores
let logger = AppLogger.cache           // In cache code
let logger = AppLogger.api             // In API clients
```

**Privacy Controls**:
```swift
// Public logging (unredacted)
logger.info("Fetched \(guests.count) guests")

// Private logging (redacted in console)
logger.logPrivate(apiKey)

// Convenience helpers
logger.infoWithRedactedEmail("User: \(email)")
logger.repositorySuccess("fetchGuests", affectedRows: 42)
logger.repositoryFailure("createGuest", error: error)
```

**Sentry Integration**:
```swift
// In error handling
SentryService.shared.captureError(error, context: context)
SentryService.shared.addBreadcrumb(message: "...", category: "...", level: .error)
```

---

### 2.5 Testing Patterns

**Test Organization**:
```
I Do BlueprintTests/
├── Accessibility/              # WCAG contrast ratio tests
├── Core/                       # AppStores, error handling
├── Domain/
│   ├── Models/                 # Model tests
│   └── Repositories/           # Repository tests
├── Services/
│   └── Stores/                 # Store tests
├── Helpers/
│   ├── MockRepositories.swift  # All mocks in one file
│   └── ModelBuilders.swift     # .makeTest() factory methods
├── Integration/
├── Performance/                # Cache, performance benchmarks
└── ...Tests.swift files
```

**Test Builders (Factory Pattern)**:
```swift
extension Guest {
    static func makeTest(
        id: UUID = UUID(),
        firstName: String = "John",
        lastName: String = "Doe",
        rsvpStatus: RSVPStatus = .pending,
        // 20+ parameters with defaults
    ) -> Guest {
        Guest(
            id: id,
            createdAt: Date(),
            firstName: firstName,
            // ...
        )
    }
}

extension BudgetCategory {
    static func makeTest(
        id: UUID = UUID(),
        categoryName: String = "Test Category",
        allocatedAmount: Double = 1000.0,
        // ...
    ) -> BudgetCategory {
        BudgetCategory(
            id: id,
            categoryName: categoryName,
            // ...
        )
    }
}
```

**Store Tests Pattern**:
```swift
@MainActor
final class BudgetStoreV2Tests: XCTestCase {
    var mockRepository: MockBudgetRepository!
    var store: BudgetStoreV2!

    override func setUp() async throws {
        try await super.setUp()
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

**Lazy Loading Tests**:
```swift
func testLazyLoading_BudgetStoreCreatedOnAccess() {
    var initialLoaded = stores.loadedStores()
    XCTAssertFalse(initialLoaded.contains("Budget"))

    _ = stores.budget  // Trigger lazy creation

    let loaded = stores.loadedStores()
    XCTAssertTrue(loaded.contains("Budget"))
}
```

---

## 3. CRITICAL DO'S AND DON'TS (FROM CODE ANALYSIS)

### 3.1 Critical DO'S

#### 1. **Always use @MainActor on Stores**
```swift
// ✅ CORRECT
@MainActor
class GuestStoreV2: ObservableObject {
    func loadGuests() async { }
}

// ❌ WRONG - Runtime crash with published updates
class GuestStoreV2: ObservableObject {
    @Published var guests: [Guest] = []
}
```
**Why**: SwiftUI state updates must occur on main thread. Missing @MainActor causes crashes.

#### 2. **Pass UUIDs Directly to Supabase (NOT .uuidString)**
```swift
// ✅ CORRECT - UUID type
.eq("couple_id", value: tenantId)

// ❌ WRONG - Case mismatch (Swift uppercase vs Postgres lowercase)
.eq("couple_id", value: tenantId.uuidString)
```
**Why**: UUID type conversion is handled by Supabase SDK. String conversion causes case mismatches.
**Found in**: LiveGuestRepository, LiveBudgetRepository, etc.

#### 3. **Use RepositoryCache for All Data Access**
```swift
// ✅ CORRECT - Check cache first
let cacheKey = "guests_\(tenantId.uuidString)"
if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
    return cached
}

// Fetch from Supabase
let guests = try await fetchFromSupabase()

// Cache result
await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
```
**Why**: Prevents API thrashing and improves performance.
**Pattern**: Check → Fetch → Cache

#### 4. **Invalidate Caches on Mutations**
```swift
// ✅ CORRECT - Use cache strategy
func createGuest(_ guest: Guest) async throws -> Guest {
    let created = try await createInDatabase(guest)
    await cacheStrategy.invalidate(for: .guestCreated(tenantId: tenantId))
    return created
}
```
**Why**: Prevents stale data after mutations.
**Implementation**: Per-domain cache strategies in `Domain/Repositories/Caching/`

#### 5. **Use LoadingState<T> Enum for All Async Operations**
```swift
// ✅ CORRECT
@Published var loadingState: LoadingState<[Guest]> = .idle

switch loadingState {
case .idle: Text("Tap to load")
case .loading: ProgressView()
case .loaded(let guests): GuestList(guests: guests)
case .error(let error): ErrorView(error: error)
}
```
**Why**: Unified pattern for handling async states. Prevents stale data and loading states.

#### 6. **Use RepositoryNetwork.withRetry for Resilience**
```swift
// ✅ CORRECT
let guests: [Guest] = try await RepositoryNetwork.withRetry {
    try await client
        .from("guest_list")
        .select()
        .execute()
        .value
}
```
**Why**: Built-in retry logic with exponential backoff, timeouts, offline cache fallback.

#### 7. **Store Singletons in LiveRepositories, Not in Stores**
```swift
// ✅ CORRECT - In DependencyValues
private enum LiveRepositories {
    static let budget: any BudgetRepositoryProtocol = LiveBudgetRepository()
    static let guest: any GuestRepositoryProtocol = LiveGuestRepository()
}

// ❌ WRONG - Creates duplicate in every store
@MainActor
class BudgetStoreV2 {
    private let repository = LiveBudgetRepository()
}
```
**Why**: Prevents memory explosion from duplicate instances.

#### 8. **Coalesce In-Flight Requests in Repositories**
```swift
// ✅ CORRECT - Deduplicate concurrent requests
private var inFlightGuests: [UUID: Task<[Guest], Error>] = [:]

if let task = inFlightGuests[tenantId] {
    return try await task.value
}

let task = Task<[Guest], Error> { ... }
inFlightGuests[tenantId] = task
```
**Why**: Prevents duplicate API calls if same request is made concurrently.

#### 9. **Use Actor-Based Repositories for Thread Safety**
```swift
// ✅ CORRECT - All Live repositories are actors
actor LiveGuestRepository: GuestRepositoryProtocol {
    func fetchGuests() async throws -> [Guest] { }
}
```
**Why**: Automatic thread-safe isolation. Repositories can be accessed from any thread.

#### 10. **Access Sub-Stores Directly (No Delegation)**
```swift
// ✅ CORRECT
await budgetStore.categoryStore.addCategory(category)
await budgetStore.payments.addPayment(schedule)

// ❌ WRONG - Unnecessary delegation
await budgetStore.addCategory(category)  // Not implemented, don't add
```
**Why**: BudgetStoreV2 is composition root. Sub-stores are publicly accessible.

#### 11. **Use AppStores.shared for All Store Access**
```swift
// ✅ CORRECT - In views
@Environment(\.appStores) private var appStores
private var store: BudgetStoreV2 { appStores.budget }

// ✅ CORRECT - Direct environment access
@Environment(\.budgetStore) private var store

// ❌ WRONG - Creates duplicate instance
@StateObject private var store = BudgetStoreV2()
```
**Why**: Prevents memory explosion, ensures single instance per app lifecycle.

#### 12. **Use @Dependency for Repository Injection**
```swift
// ✅ CORRECT
@Dependency(\.budgetRepository) var repository

// In tests:
await withDependencies {
    $0.budgetRepository = mockRepository
} operation: {
    // Store with mock injected
}
```
**Why**: Testable, swappable dependencies.

#### 13. **Log with Proper Categories**
```swift
// ✅ CORRECT
let logger = AppLogger.repository
logger.info("Fetched \(guests.count) guests")
logger.error("Operation failed", error: error)

// ✅ CORRECT - Privacy redaction
logger.logPrivate(apiKey)  // Redacted in console
logger.infoWithRedactedEmail("User logged in: \(email)")
```
**Why**: Organized logging by subsystem, privacy compliance.

#### 14. **Use Sendable for Types Crossing Actor Boundaries**
```swift
// ✅ CORRECT
protocol GuestRepositoryProtocol: Sendable {
    func fetchGuests() async throws -> [Guest]
}

struct Guest: Codable, Sendable { }
```
**Why**: Compile-time thread-safety verification.

#### 15. **Implement Cache Validity Checks**
```swift
// ✅ CORRECT
var lastLoadTime: Date?
let cacheValidityDuration: TimeInterval = 300

func isCacheValid() -> Bool {
    guard case .loaded = loadingState,
          let last = lastLoadTime else { return false }
    return Date().timeIntervalSince(last) < cacheValidityDuration
}

// In load method:
if !force && isCacheValid() {
    return  // Use cached data
}
```
**Why**: Prevents unnecessary API calls while keeping data fresh.

---

### 3.2 Critical DON'Ts

#### 1. **Don't Create Store Instances in Views**
```swift
// ❌ WRONG - Memory explosion, duplicate instances
@StateObject private var store = BudgetStoreV2()

// ✅ CORRECT
@Environment(\.appStores) private var appStores
private var store: BudgetStoreV2 { appStores.budget }
```
**Finding**: Multiple git commits removing duplicate store creation
**Impact**: Each instance loads full dataset from Supabase

#### 2. **Don't Convert UUIDs to Strings for Database Queries**
```swift
// ❌ WRONG
.eq("couple_id", value: tenantId.uuidString)

// ✅ CORRECT
.eq("couple_id", value: tenantId)
```
**Finding**: Bug history shows case-mismatch issues
**Impact**: Silent data filtering failures

#### 3. **Don't Mix UI and Business Logic**
```swift
// ❌ WRONG
struct GuestListView: View {
    let supabase = SupabaseClient(...)  // API directly in view
    @State var guests: [Guest] = []

    var body: some View {
        List {
            ForEach(guests) { guest in
                Text(guest.fullName)
                    .onAppear {
                        Task {
                            guests = try await supabase...  // Direct API call
                        }
                    }
            }
        }
    }
}

// ✅ CORRECT
struct GuestListView: View {
    @Environment(\.budgetStore) private var store

    var body: some View {
        List {
            ForEach(store.guests) { guest in
                Text(guest.fullName)
            }
        }
        .task {
            await store.loadGuestData()
        }
    }
}
```
**Why**: Separation of concerns, testability, reusability

#### 4. **Don't Skip Error Handling**
```swift
// ❌ WRONG
try await repository.fetchGuests()  // Ignores error

// ✅ CORRECT
do {
    let guests = try await repository.fetchGuests()
    loadingState = .loaded(guests)
} catch {
    await handleError(error, operation: "fetchGuests")
    loadingState = .error(error)
}
```
**Why**: Enables Sentry tracking, user-facing feedback, retries

#### 5. **Don't Ignore Task Cancellation**
```swift
// ❌ WRONG
let task = Task {
    try await repository.fetchGuests()
}
// Task keeps running even if discarded

// ✅ CORRECT
private var loadTask: Task<Void, Never>?

func load() {
    loadTask?.cancel()
    loadTask = Task { @MainActor in
        try Task.checkCancellation()
        let data = try await repository.fetch()
    }
}
```
**Why**: Prevents duplicate requests, memory leaks

#### 6. **Don't Use Force Unwrapping Without Justification**
```swift
// ❌ WRONG
let guest = guests.first!  // Crashes if empty

// ✅ CORRECT
guard let guest = guests.first else {
    // Handle empty case
    return
}
```
**Why**: Runtime crashes from force unwrap

#### 7. **Don't Use TimeZone.current for Display**
```swift
// ❌ WRONG
let formatted = DateFormatter()
formatted.timeZone = TimeZone.current  // User's device timezone

// ✅ CORRECT
let userTimezone = DateFormatting.userTimeZone(from: settingsStore.settings)
let formatted = DateFormatting.formatDateMedium(date, timezone: userTimezone)
```
**Why**: Respects user's configured timezone (may differ from device)

#### 8. **Don't Create Delegation Methods in BudgetStoreV2**
```swift
// ❌ WRONG - Don't add
func addCategory(_ category: BudgetCategory) async throws -> BudgetCategory {
    try await categoryStore.addCategory(category)
}

// ✅ CORRECT - Use directly
await budgetStore.categoryStore.addCategory(category)
```
**Why**: BudgetStoreV2 is composition root, sub-stores are public

#### 9. **Don't Skip Cache Invalidation on Mutations**
```swift
// ❌ WRONG
func createGuest(_ guest: Guest) async throws -> Guest {
    return try await createInDatabase(guest)
    // No cache invalidation - stale data!
}

// ✅ CORRECT
func createGuest(_ guest: Guest) async throws -> Guest {
    let created = try await createInDatabase(guest)
    await cacheStrategy.invalidate(for: .guestCreated(tenantId: tenantId))
    return created
}
```
**Why**: Prevents stale data after mutations

#### 10. **Don't Use Completion Handlers**
```swift
// ❌ WRONG
func fetchGuests(completion: @escaping ([Guest]) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, _ in
        completion(guests)
    }.resume()
}

// ✅ CORRECT
func fetchGuests() async throws -> [Guest] {
    try await client.from("guest_list").select().execute().value
}
```
**Why**: async/await is cleaner, no pyramid of doom, better error handling

#### 11. **Don't Log Sensitive Data Unredacted**
```swift
// ❌ WRONG
logger.info("User API key: \(apiKey)")
logger.info("Session token: \(token)")

// ✅ CORRECT
logger.logPrivate(apiKey)  // Redacted in console
logger.infoWithRedactedEmail("User logged in: \(email)")
```
**Why**: Privacy, security, compliance

#### 12. **Don't Expose Data Across Tenants**
```swift
// ❌ WRONG
let guests = try await supabase.from("guest_list").select().execute().value
// Returns ALL guests, not filtered!

// ✅ CORRECT
let tenantId = try await getTenantId()
let guests: [Guest] = try await client
    .from("guest_list")
    .select()
    .eq("couple_id", value: tenantId)  // Always filter by tenant
    .execute()
    .value
```
**Why**: Multi-tenant security, RLS enforcement

#### 13. **Don't Skip Sendable Conformance**
```swift
// ❌ WRONG
protocol GuestRepository {  // Not Sendable
    func fetchGuests() async throws -> [Guest]
}

// ✅ CORRECT
protocol GuestRepositoryProtocol: Sendable {
    func fetchGuests() async throws -> [Guest]
}
```
**Why**: Compile-time enforcement of thread-safety

#### 14. **Don't Forget @MainActor in Tests**
```swift
// ❌ WRONG
final class BudgetStoreV2Tests: XCTestCase {
    var store: BudgetStoreV2!  // Not @MainActor - thread issues
}

// ✅ CORRECT
@MainActor
final class BudgetStoreV2Tests: XCTestCase {
    var store: BudgetStoreV2!
}
```
**Why**: Store is @MainActor, tests must be too

#### 15. **Don't Create New Mock Data in Tests Without builders**
```swift
// ❌ WRONG
let guest = Guest(
    id: UUID(),
    firstName: "John",
    // 50 more properties...
)

// ✅ CORRECT
let guest = Guest.makeTest(firstName: "John")
```
**Why**: Builder pattern provides sensible defaults, maintainability

---

## 4. TECH STACK (ACTUAL USAGE)

### 4.1 Swift Version & Concurrency
- **Swift Version**: Swift 5.9+
- **Concurrency**: Full Swift 6 concurrency checking enabled
- **Features Used**:
  - `async/await` (100% adoption)
  - `actor` for thread-safe types (11 actors)
  - `@MainActor` on all UI classes
  - `Sendable` conformance (72 instances)
  - `nonisolated` for pure functions
  - `@Dependency` macro from swift-dependencies

### 4.2 Framework Stack
- **UI**: SwiftUI
- **Platform**: macOS 13.0+
- **Backend**: Supabase (PostgreSQL with Row Level Security)
- **Networking**: Supabase Swift SDK (async/await based)
- **Dependency Injection**: swift-dependencies package
- **Logging**: OSLog (Darwin system framework)
- **Error Tracking**: Sentry
- **Testing**: XCTest

### 4.3 Supabase Integration Patterns

**Client Setup**:
```swift
private let supabase: SupabaseClient?

func fetchGuests() async throws -> [Guest] {
    let client = try getClient()
    let tenantId = try await getTenantId()

    let guests: [Guest] = try await RepositoryNetwork.withRetry {
        try await client
            .from("guest_list")
            .select()
            .eq("couple_id", value: tenantId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    return guests
}
```

**RLS Policy Pattern** (Multi-tenant):
```sql
CREATE POLICY "couples_manage_own_guests"
  ON guest_list
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());
```

**Realtime Features**:
- Found: `CollaborationRealtimeManager`, `PresenceStoreV2`
- Pattern: Channel subscriptions with change callbacks

### 4.4 Cache Architecture

**Three-Layer Cache**:
1. **In-Memory Cache** (`RepositoryCache` actor)
   - TTL-based expiration (default 60s)
   - Hit/miss tracking
   - Automatic cleanup

2. **Offline Cache** (`OfflineCache` actor)
   - Codable persistence
   - Fallback on network failure
   - TTL support

3. **In-Flight Request Deduplication**
   - Per-repository de-duplication
   - Prevents duplicate API calls

**Cache Strategies**:
- Per-domain: `GuestCacheStrategy`, `BudgetCacheStrategy`, etc.
- Standardized keys: `CacheConfiguration.KeyPrefix`
- Health monitoring: `CacheMonitor` actor

### 4.5 Error Tracking

**Sentry Integration**:
```swift
SentryService.shared.captureError(error, context: context)
SentryService.shared.addBreadcrumb(message: "...", category: "error")
```

**Error Types**:
- `AppError` (domain base)
- `GuestError`, `BudgetError`, `VendorError` (domain-specific)
- `NetworkError` (timeout, connection failed)
- `UserFacingError` (localized for UI)

### 4.6 Performance Monitoring

**Found**:
- `PerformanceMonitor` actor
- `AnalyticsService` tracking
- Cache hit/miss metrics
- Request duration tracking
- Sentry performance monitoring

---

## 5. CODE METRICS

| Metric | Value |
|--------|-------|
| Total Swift Files | 2,377 |
| Repositories | 12 live + 10 mock + 14 protocols |
| Stores (V2) | 13 main + ~6 sub-stores |
| Cache Strategies | 6 domain-specific |
| Actors | 11 (repositories + services) |
| @MainActor Classes | 13 stores |
| Test Files | 20+ |
| Models | 80+ |
| Views | 150+ |

---

## 6. CRITICAL FINDINGS

### 6.1 Recent Security Fixes
- **Commit 608dfae**: Hardcoded API keys removed, replaced with environment variables
- **Fix**: SessionManager keychain changed to `ThisDeviceOnly` accessibility
- **Impact**: Prevents backup/restore of session data to other devices

### 6.2 Deferred Pagination Issue
- **File**: `LiveGuestRepository.swift` (lines 95-107)
- **Issue**: Guest pagination blocked by `Sendable` conformance
- **Root Cause**: Guest model contains `NSImage` (non-Sendable)
- **Workaround**: Fetch all guests, client-side pagination if needed
- **Performance Impact**: Minimal for typical wedding guests (< 500)
- **Future**: Revisit when Swift 6 stabilizes Sendable requirements

### 6.3 UUID Handling Pitfall
- **Found**: Multiple instances of UUID string conversion in git history
- **Pattern**: Causes silent case mismatch bugs (Swift uppercase vs Postgres lowercase)
- **Solution**: Always pass UUID directly to Supabase queries
- **Note**: Cache keys CAN use `.uuidString` (no database queries)

### 6.4 Missing Pagination
- **Status**: Intentionally not implemented (Sendable blocking issue)
- **Current**: Fetches all records, reasonable for datasets < 1000

### 6.5 Error Handling Standardization
- **Found**: 5+ commits standardizing error handling across stores
- **Pattern**: All stores now use `.handleError()` extension + Sentry
- **Coverage**: Standardization now complete across all stores

---

## 7. RECOMMENDATIONS FOR CLAUDE GUIDANCE

### For New Feature Development:
1. Create models in `Domain/Models/{Feature}/`
2. Create repository protocol in `Domain/Repositories/Protocols/`
3. Implement live repository as `actor` with caching
4. Create mock for testing
5. Register in `DependencyValues.swift`
6. Create `V2` store with `@MainActor`, `CacheableStore`
7. Create cache strategy for domain
8. Create views in `Views/{Feature}/`
9. Add tests in `I Do BlueprintTests/`

### For Store Implementation:
1. Always `@MainActor class`, `ObservableObject`, `CacheableStore`
2. Use `LoadingState<T>` enum
3. Inject repository via `@Dependency`
4. Track load time for cache validity
5. Use `.handleError()` extension for errors
6. Implement `isCacheValid()` method
7. Cancel previous tasks in load methods

### For Repository Implementation:
1. Declare as `actor`
2. Implement protocol exactly
3. Add caching layer (check → fetch → cache)
4. Use `RepositoryNetwork.withRetry` for resilience
5. Coalesce in-flight requests
6. Create domain-specific `CacheStrategy`
7. Inject `SessionManager` for tenant scoping
8. Always filter by `couple_id` in multi-tenant tables

### For Error Handling:
1. Use domain-specific error types
2. Always log with appropriate category
3. Capture to Sentry with context
4. Show user-facing error via `AlertPresenter`
5. Provide retry closure for user action

---

## Summary

**I Do Blueprint** is a well-architected macOS application with:
- Clear separation of concerns (View/Store/Repository/Model layers)
- Strict concurrency compliance (100% async/await, actor-based isolation)
- Comprehensive caching strategy (3-layer: in-memory, offline, in-flight deduplication)
- Dependency injection for testability
- Unified error handling and logging
- Multi-tenant security with RLS enforcement
- Performance monitoring and analytics integration

**Key Architectural Strengths**:
1. Repository pattern prevents direct API access from views
2. V2 naming convention clearly marks modern architecture
3. Actor-based repositories ensure thread safety
4. Cache strategies consolidate invalidation logic
5. Dependency injection enables complete testability
6. LoadingState pattern handles all async scenarios
7. Error handling standardization ensures consistency

**Known Limitations**:
1. Pagination deferred due to Sendable/NSImage conflict
2. Guest model contains non-Sendable NSImage type
3. Some views still exist in legacy patterns (being migrated)

This audit provides the actual patterns Claude should follow when working with this codebase, not aspirational patterns in documentation.
