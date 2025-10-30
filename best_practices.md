# 📘 Project Best Practices

## 1. Project Purpose

**I Do Blueprint** is a comprehensive macOS wedding planning application built with SwiftUI. It helps couples manage all aspects of their wedding including budget tracking, guest management, vendor coordination, task planning, timeline management, document storage, and visual planning (mood boards, seating charts). The app uses Supabase as a backend for multi-tenant data storage and supports Google Drive integration for document management.

**Domain:** Wedding planning and event management  
**Platform:** macOS (SwiftUI)  
**Architecture:** MVVM with Repository Pattern, Dependency Injection  
**Backend:** Supabase (PostgreSQL with Row Level Security)

---

## 2. Project Structure

### Core Directory Layout

```
I Do Blueprint/
├── App/                          # Application entry point and root views
│   ├── ContentView.swift
│   ├── My_Wedding_Planning_AppApp.swift
│   └── RootFlowView.swift
├── Core/                         # Core infrastructure (auth, storage, utilities)
│   ├── Common/
│   │   ├── Analytics/           # ErrorTracker, performance monitoring
│   │   ├── Auth/                # Authentication helpers
│   │   ├── Common/              # AppStores, DependencyValues
│   │   └── Errors/              # Domain-specific error types
│   ├── Extensions/              # Swift type extensions
│   └── Utilities/               # Core utilities
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
│   │   └── Shared/
│   └── Repositories/            # Data access layer
│       ├── Protocols/           # Repository interfaces
│       ├── Live/                # Production implementations (Supabase)
│       ├── Mock/                # Test implementations
│       ���── RepositoryCache.swift # Generic caching infrastructure
├── Services/                     # Application services
│   ├── Stores/                  # State management (V2 pattern)
│   │   ├── Budget/              # BudgetStoreV2, AffordabilityStore, etc.
│   │   ├── GuestStoreV2.swift
│   │   ├── VendorStoreV2.swift
│   │   └── TaskStoreV2.swift
│   ├── API/                     # API clients
│   ├── Auth/                    # SessionManager, authentication
│   ├── Storage/                 # SupabaseClient, data persistence
│   ├── Analytics/               # SentryService, CacheWarmer, PerformanceOptimizationService
│   ├── Export/                  # Google Sheets export
│   ├── Integration/             # SecureAPIKeyManager, external integrations
│   └── Navigation/              # Navigation coordination
├── Utilities/                    # Shared utilities
│   ├── Logging/                 # AppLogger, structured logging
│   ├── Validation/              # Input validation
│   ├── NetworkRetry.swift       # Retry logic with exponential backoff
│   ├── HapticFeedback.swift     # Haptic feedback utilities
│   └── AccessibilityExtensions.swift
├── Views/                        # UI layer organized by feature
│   ├── Budget/
│   ├── Dashboard/
│   ├── Guests/
│   ├── Tasks/
│   ├── Vendors/
│   ├── Documents/
│   ├── Timeline/
│   ├── VisualPlanning/
│   ├── Settings/
│   └── Shared/                  # Reusable components
├── Resources/                    # Assets, localizations, Lottie files
│   ├── Assets.xcassets/
│   ├── Localizations/
│   └── Lottie/
└── Config.plist                  # API keys and configuration
```

### Key Architectural Principles

- **Feature-based organization**: Views, models, and logic grouped by feature domain
- **Separation of concerns**: Clear boundaries between UI (Views), State (Stores), Business Logic (Repositories), and Data (Models)
- **Repository pattern**: All data access goes through repository protocols for testability
- **Dependency injection**: Using Swift's `@Dependency` macro for loose coupling
- **V2 naming convention**: New architecture stores use `V2` suffix (e.g., `BudgetStoreV2`)
- **Actor-based caching**: Thread-safe caching with `RepositoryCache` actor
- **Multi-tenant security**: All data scoped by `couple_id` with Row Level Security (RLS)

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

### Naming Conventions

#### Files
- **Views**: `{Feature}{Purpose}View.swift` (e.g., `BudgetDashboardView.swift`)
- **Stores**: `{Feature}StoreV2.swift` (e.g., `BudgetStoreV2.swift`)
- **Models**: `{EntityName}.swift` (e.g., `Guest.swift`, `Expense.swift`)
- **Protocols**: `{Purpose}Protocol.swift` (e.g., `GuestRepositoryProtocol.swift`)
- **Extensions**: `{Type}+{Purpose}.swift` (e.g., `Color+Hex.swift`)

#### Classes/Structs
- **Views**: `{Feature}{Purpose}View` (e.g., `DashboardProgressCard`)
- **Stores**: `{Feature}StoreV2` (e.g., `BudgetStoreV2`)
- **Models**: PascalCase nouns (e.g., `Guest`, `BudgetCategory`)
- **Protocols**: `{Purpose}Protocol` (e.g., `GuestRepositoryProtocol`)

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

#### Error Propagation
- Throw errors from repositories
- Catch and handle in stores
- Update loading state on errors
- Log errors with `AppLogger`
- Capture errors with `SentryService`

```swift
do {
    let created = try await repository.createCategory(category)
    logger.info("Added category: \(created.categoryName)")
} catch {
    loadingState = .error(BudgetError.createFailed(underlying: error))
    logger.error("Error adding category", error: error)
    SentryService.shared.captureError(error, context: [
        "operation": "createCategory",
        "categoryName": category.categoryName
    ])
}
```

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

// 2. Implement live version
class LiveGuestRepository: GuestRepositoryProtocol {
    private let supabase: SupabaseClient
    private let logger = AppLogger.database
    
    func fetchGuests() async throws -> [Guest] {
        // Check cache first
        let cacheKey = "guests_\(tenantId.uuidString)"
        if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: guests")
            return cached
        }
        
        // Fetch from Supabase
        let guests: [Guest] = try await supabase.database
            .from("guest_list")
            .select()
            .eq("couple_id", value: tenantId) // ✅ Pass UUID directly
            .order("created_at", ascending: false)
            .execute()
            .value
        
        // Cache the results
        await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
        return guests
    }
}

// 3. Implement mock version
class MockGuestRepository: GuestRepositoryProtocol {
    var guests: [Guest] = []
    var shouldThrowError = false
    
    func fetchGuests() async throws -> [Guest] {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 1)
        }
        return guests
    }
}

// 4. Register with dependency system
private enum GuestRepositoryKey: DependencyKey {
    static let liveValue: any GuestRepositoryProtocol = LiveRepositories.guest
    static let testValue: any GuestRepositoryProtocol = MockGuestRepository()
}

extension DependencyValues {
    var guestRepository: any GuestRepositoryProtocol {
        get { self[GuestRepositoryKey.self] }
        set { self[GuestRepositoryKey.self] = newValue }
    }
}

// 5. Use in stores
@MainActor
class GuestStoreV2: ObservableObject {
    @Dependency(\.guestRepository) var repository
    
    func loadGuests() async {
        do {
            let guests = try await repository.fetchGuests()
            // Update state
        } catch {
            // Handle error
        }
    }
}
```

### Caching Pattern

Use `RepositoryCache` actor for thread-safe caching:

```swift
// In repository
func fetchGuests() async throws -> [Guest] {
    let cacheKey = "guests_\(tenantId.uuidString)"
    
    // Check cache first (60 second TTL)
    if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
        logger.info("Cache hit: guests (\(cached.count) items)")
        return cached
    }
    
    // Fetch from database
    let guests = try await fetchFromDatabase()
    
    // Cache the results
    await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
    return guests
}

// Invalidate cache on mutations
func createGuest(_ guest: Guest) async throws -> Guest {
    let created = try await createInDatabase(guest)
    
    // Invalidate tenant-scoped cache
    await RepositoryCache.shared.remove("guests_\(tenantId.uuidString)")
    await RepositoryCache.shared.remove("guest_stats_\(tenantId.uuidString)")
    
    return created
}
```

### Network Retry Pattern

Use `NetworkRetry` for resilient network operations:

```swift
// Simple retry
let guests = try await NetworkRetry.withRetry {
    try await repository.fetchGuests()
}

// Retry with custom configuration
let config = RetryConfiguration(
    maxAttempts: 5,
    baseDelay: 1.0,
    maxDelay: 10.0,
    jitterFactor: 0.3
)

let data = try await NetworkRetry.withRetry(config: config) {
    try await repository.fetchLargeDataset()
}

// Retry with timeout
let result = try await NetworkRetry.withRetryAndTimeout(
    timeoutSeconds: 30
) {
    try await repository.fetchData()
}
```

### Loading State Pattern

Use `LoadingState<T>` enum for async operations:

```swift
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var data: T? {
        if case .loaded(let data) = self { return data }
        return nil
    }
}

// Usage in stores
@Published var loadingState: LoadingState<BudgetData> = .idle

func loadData() async {
    loadingState = .loading
    do {
        let data = try await repository.fetchData()
        loadingState = .loaded(data)
    } catch {
        loadingState = .error(error)
        SentryService.shared.captureError(error)
    }
}
```

### Optimistic Updates with Rollback

```swift
func updateCategory(_ category: BudgetCategory) async {
    // 1. Optimistic update
    guard case .loaded(var budgetData) = loadingState,
          let index = budgetData.categories.firstIndex(where: { $0.id == category.id }) else {
        return
    }
    
    let original = budgetData.categories[index]
    budgetData.categories[index] = category
    loadingState = .loaded(budgetData)
    
    // 2. Attempt server update
    do {
        let updated = try await repository.updateCategory(category)
        // Update with server response
    } catch {
        // 3. Rollback on error
        if case .loaded(var data) = loadingState,
           let idx = data.categories.firstIndex(where: { $0.id == category.id }) {
            data.categories[idx] = original
            loadingState = .loaded(data)
        }
        logger.error("Error updating category, rolled back", error: error)
        SentryService.shared.captureError(error, context: ["operation": "updateCategory"])
    }
}
```

### Sentry Integration Pattern

Use `SentryService` for error tracking and performance monitoring:

```swift
// Error tracking
do {
    try await performOperation()
} catch {
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

// Breadcrumbs for debugging
SentryService.shared.addBreadcrumb(
    message: "User navigated to vendor detail",
    category: "navigation",
    data: ["vendorId": vendor.id.uuidString]
)

// Track user actions
SentryService.shared.trackAction(
    "create_expense",
    category: "budget",
    metadata: ["amount": expense.amount]
)
```

### Store Composition

Break large stores into smaller, focused stores:

```swift
@MainActor
class BudgetStoreV2: ObservableObject {
    // Composed stores
    let affordability: AffordabilityStore
    let payments: PaymentScheduleStore
    let gifts: GiftsStore
    
    init() {
        self.payments = PaymentScheduleStore()
        self.gifts = GiftsStore()
        self.affordability = AffordabilityStore(
            paymentSchedulesProvider: { [weak payments] in
                payments?.paymentSchedules ?? []
            }
        )
    }
    
    // Delegate properties
    var paymentSchedules: [PaymentSchedule] {
        payments.paymentSchedules
    }
}
```

### Store Access Patterns

**CRITICAL**: Never create new store instances in views. Always use the `AppStores` singleton to prevent memory explosion and state synchronization issues.

#### ✅ Correct Patterns

**Option 1: Environment Access (Preferred)**
```swift
struct SettingsView: View {
    @Environment(\.appStores) private var appStores
    
    private var store: SettingsStoreV2 {
        appStores.settings
    }
    
    var body: some View {
        // Use store
    }
}
```

**Option 2: Direct Environment Store Access**
```swift
struct BudgetView: View {
    @Environment(\.budgetStore) private var store
    
    var body: some View {
        // Use store
    }
}
```

**Option 3: Pass Store as Parameter**
```swift
struct BudgetDetailView: View {
    @ObservedObject var budgetStore: BudgetStoreV2
    
    var body: some View {
        // Use budgetStore
    }
}

// Parent view passes singleton store
BudgetDetailView(budgetStore: appStores.budget)
```

**Option 4: Direct Singleton Access (Last Resort)**
```swift
struct QuickAccessView: View {
    private var store: SettingsStoreV2 {
        AppStores.shared.settings
    }
    
    var body: some View {
        // Use store
    }
}
```

#### ❌ Anti-Patterns to Avoid

**NEVER create new store instances:**
```swift
// ❌ BAD: Creates duplicate store instance
struct SettingsView: View {
    @StateObject private var store = SettingsStoreV2()
    // This wastes memory and creates state sync issues!
}

// ❌ BAD: Creates new instance on each access
struct BudgetView: View {
    var body: some View {
        let store = BudgetStoreV2() // Don't do this!
    }
}
```

#### Memory Impact

Each store instance loads full datasets:
- **BudgetStoreV2**: ~500KB-2MB (categories, expenses, scenarios)
- **GuestStoreV2**: ~200KB-1MB (guest list, RSVP data)
- **VendorStoreV2**: ~300KB-1MB (vendor list, contracts)

Creating duplicate instances can waste **1-5MB per view** that creates stores.

#### When to Use Each Pattern

1. **Environment Access**: Use for root views and views that need multiple stores
2. **Direct Environment Store**: Use for views that only need one specific store
3. **Pass as Parameter**: Use for child views that receive store from parent
4. **Direct Singleton**: Use sparingly, only when environment is not available

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

### Design System Usage

Always use design system constants:

```swift
// ✅ Good
Text("Hello")
    .font(Typography.heading)
    .foregroundColor(AppColors.textPrimary)
    .padding(Spacing.lg)

// ❌ Bad
Text("Hello")
    .font(.system(size: 18, weight: .semibold))
    .foregroundColor(.black)
    .padding(16)
```

### Accessibility Modifiers

Use semantic accessibility modifiers:

```swift
Button("Save") {
    save()
}
.accessibleActionButton(
    label: "Save budget category",
    hint: "Saves the current category and returns to the list"
)

Text(guest.fullName)
    .accessibleListItem(
        label: guest.fullName,
        hint: "Tap to view guest details",
        value: guest.rsvpStatus.rawValue,
        isSelected: selectedGuest?.id == guest.id
    )
```

### UUID Handling Best Practices

#### Core Principles

1. **Pass UUIDs directly to Supabase** - Never convert to string for queries
2. **Minimize string conversions** - Only convert when absolutely necessary
3. **Understand case sensitivity** - Swift returns uppercase, PostgreSQL stores lowercase
4. **Cache string representations** - Reuse converted strings when needed multiple times

#### Database Queries

```swift
// ✅ GOOD: Pass UUID directly to Supabase
let guests: [Guest] = try await supabase.database
    .from("guest_list")
    .select()
    .eq("couple_id", value: tenantId) // UUID type
    .execute()
    .value

// ❌ BAD: Converting to string (unnecessary and causes case issues)
let guests: [Guest] = try await supabase.database
    .from("guest_list")
    .select()
    .eq("couple_id", value: tenantId.uuidString) // Don't do this!
    .execute()
    .value
```

**Why this matters:**
- Supabase Swift client supports UUID types natively
- PostgreSQL UUID type is case-insensitive for comparisons
- Converting to string adds unnecessary overhead
- String conversion can cause case mismatch bugs in dictionary operations

#### Cache Keys

```swift
// ✅ GOOD: Convert once for cache operations
let tenantIdString = tenantId.uuidString
let cacheKey = "guests_\(tenantIdString)"

if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
    return cached
}

let guests = try await fetchFromDatabase()
await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)

// Invalidate with same string
await RepositoryCache.shared.remove(cacheKey)

// ❌ BAD: Converting multiple times
await RepositoryCache.shared.remove("guests_\(tenantId.uuidString)")
await RepositoryCache.shared.remove("guest_stats_\(tenantId.uuidString)")
await RepositoryCache.shared.remove("guest_count_\(tenantId.uuidString)")
```

**Performance impact:**
- Each `.uuidString` call creates a new string allocation
- Reusing the string reduces memory pressure
- Especially important in hot paths (cache invalidation, logging)

#### Case Sensitivity and Dictionary Operations

**Important:** Swift's `UUID.uuidString` returns **UPPERCASE**, but PostgreSQL stores UUIDs as **lowercase**.

```swift
// ⚠️ CASE MISMATCH SCENARIO
// Swift UUID: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
// PostgreSQL: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

// ✅ GOOD: Normalize at dictionary creation (Swift UUID → lowercase)
var allocationsByItem: [String: [Allocation]] = [:]
for allocation in allocations {
    let itemId = allocation.budgetItemId.uuidString.lowercased()
    allocationsByItem[itemId, default: []].append(allocation)
}

// ✅ GOOD: Lookup with database string (already lowercase)
let itemAllocations = allocationsByItem[item.id] ?? []

// ❌ BAD: Normalizing at lookup (redundant if key already normalized)
let itemAllocations = allocationsByItem[item.id.lowercased()] ?? []

// ❌ BAD: Not normalizing when mixing Swift UUIDs with DB strings
var dict: [String: Data] = [:]
dict[swiftUUID.uuidString] = data // Uppercase key
let value = dict[dbString] // Lowercase lookup - FAILS!
```

**When to use `.lowercased()`:**
- ✅ Creating dictionary keys from Swift UUIDs that will be looked up with DB strings
- ✅ Comparing Swift UUID strings with PostgreSQL UUID strings
- ❌ Database queries (PostgreSQL handles case-insensitivity)
- ❌ Dictionary lookups when keys are already normalized
- ❌ Cache keys (consistency is more important than case)

#### Logging and Debugging

```swift
// ✅ GOOD: Convert once for logging context
let guestIdString = guest.id.uuidString
logger.info("Processing guest: \(guestIdString)")
SentryService.shared.addBreadcrumb(
    message: "Guest updated",
    data: ["guestId": guestIdString]
)

// ❌ BAD: Converting multiple times
logger.info("Processing guest: \(guest.id.uuidString)")
logger.debug("Guest details: \(guest.id.uuidString)")
SentryService.shared.addBreadcrumb(
    message: "Guest updated",
    data: ["guestId": guest.id.uuidString]
)
```

#### Test Data Generation

```swift
// ✅ GOOD: Use UUID directly in models
let testGuest = Guest(
    id: UUID(), // Generate UUID directly
    coupleId: testCoupleId,
    fullName: "Test Guest"
)

// ✅ GOOD: Factory methods for test data
extension Guest {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        fullName: String = "Test Guest"
    ) -> Guest {
        Guest(id: id, coupleId: coupleId, fullName: fullName)
    }
}

// ❌ BAD: Unnecessary string conversion in tests
let testGuest = Guest(
    id: UUID(uuidString: UUID().uuidString)!, // Pointless conversion
    coupleId: testCoupleId,
    fullName: "Test Guest"
)
```

#### Common Patterns

**Pattern 1: Repository with Caching**
```swift
func fetchGuests() async throws -> [Guest] {
    // Convert once for cache key
    let cacheKey = "guests_\(tenantId.uuidString)"
    
    if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
        return cached
    }
    
    // Pass UUID directly to query
    let guests: [Guest] = try await supabase.database
        .from("guest_list")
        .select()
        .eq("couple_id", value: tenantId) // ✅ UUID type
        .execute()
        .value
    
    await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
    return guests
}
```

**Pattern 2: Cache Invalidation**
```swift
func createGuest(_ guest: Guest) async throws -> Guest {
    let created = try await createInDatabase(guest)
    
    // Convert once, reuse for multiple invalidations
    let tenantIdString = tenantId.uuidString
    await RepositoryCache.shared.remove("guests_\(tenantIdString)")
    await RepositoryCache.shared.remove("guest_stats_\(tenantIdString)")
    await RepositoryCache.shared.remove("guest_count_\(tenantIdString)")
    
    return created
}
```

**Pattern 3: Dictionary Operations with Mixed Sources**
```swift
// Scenario: Matching Swift UUIDs with PostgreSQL UUID strings
func fetchBudgetOverview() async throws -> [BudgetItem] {
    let items = try await fetchBudgetItems() // Returns items with id: String (lowercase from DB)
    let allocations = try await fetchAllocations() // Returns allocations with budgetItemId: UUID (Swift)
    
    // Create dictionary with normalized keys (Swift UUID → lowercase)
    var allocationsByItem: [String: [Allocation]] = [:]
    for allocation in allocations {
        let itemId = allocation.budgetItemId.uuidString.lowercased() // ✅ Normalize here
        allocationsByItem[itemId, default: []].append(allocation)
    }
    
    // Lookup with database strings (already lowercase)
    return items.map { item in
        let itemAllocations = allocationsByItem[item.id] ?? [] // ✅ No normalization needed
        return BudgetItem(item: item, allocations: itemAllocations)
    }
}
```

#### Performance Checklist

- [ ] Pass UUIDs directly to Supabase queries (not `.uuidString`)
- [ ] Convert UUID to string once per operation, reuse the string
- [ ] Use `.lowercased()` only when mixing Swift UUIDs with DB strings in dictionaries
- [ ] Avoid repeated `.uuidString` calls in loops
- [ ] Cache string representations for frequently accessed UUIDs
- [ ] Profile hot paths to identify unnecessary conversions

#### Common Mistakes

1. **Converting for database queries** ❌
   ```swift
   .eq("id", value: id.uuidString) // Don't do this
   ```

2. **Repeated conversions in cache operations** ❌
   ```swift
   await cache.remove("key_\(id.uuidString)")
   await cache.remove("key2_\(id.uuidString)")
   await cache.remove("key3_\(id.uuidString)")
   ```

3. **Not normalizing dictionary keys** ❌
   ```swift
   dict[swiftUUID.uuidString] = value // Uppercase
   let result = dict[dbString] // Lowercase - won't match!
   ```

4. **Over-normalizing** ❌
   ```swift
   dict[dbString.lowercased()] = value // Already lowercase!
   ```

#### Migration Guide

If you find code with unnecessary UUID conversions:

**Before:**
```swift
let guests: [Guest] = try await supabase.database
    .from("guest_list")
    .select()
    .eq("couple_id", value: tenantId.uuidString.lowercased())
    .execute()
    .value
```

**After:**
```swift
let guests: [Guest] = try await supabase.database
    .from("guest_list")
    .select()
    .eq("couple_id", value: tenantId) // ✅ Pass UUID directly
    .execute()
    .value
```

**Before:**
```swift
await cache.remove("guests_\(id.uuidString)")
await cache.remove("stats_\(id.uuidString)")
await cache.remove("count_\(id.uuidString)")
```

**After:**
```swift
let idString = id.uuidString
await cache.remove("guests_\(idString)")
await cache.remove("stats_\(idString)")
await cache.remove("count_\(idString)")
```

---

### Multi-Tenant Security Pattern

Always scope queries by `couple_id`:

```swift
// ✅ Good: Pass UUID directly
let guests: [Guest] = try await supabase.database
    .from("guest_list")
    .select()
    .eq("couple_id", value: tenantId) // UUID type
    .execute()
    .value

// ❌ Bad: Converting to string causes case mismatch
let guests: [Guest] = try await supabase.database
    .from("guest_list")
    .select()
    .eq("couple_id", value: tenantId.uuidString) // Returns uppercase!
    .execute()
    .value
```

---

## 6. Do's and Don'ts

### ✅ Do's

1. **Use dependency injection** for all external dependencies
2. **Log all data operations** with `AppLogger` (category-specific loggers)
3. **Handle errors gracefully** with proper error types and user feedback
4. **Use MARK comments** to organize code sections
5. **Follow the repository pattern** for all data access
6. **Use LoadingState enum** for async operations
7. **Implement optimistic updates** with rollback for better UX
8. **Use design system constants** (AppColors, Typography, Spacing)
9. **Add accessibility labels** to all interactive elements
10. **Test with mock repositories** for unit tests
11. **Use async/await** for asynchronous operations
12. **Document public APIs** with DocStrings
13. **Use strong typing** and avoid `Any` when possible
14. **Conform to Sendable** for types crossing actor boundaries
15. **Use @MainActor** for UI-related classes
16. **Cache frequently accessed data** with `RepositoryCache`
17. **Use NetworkRetry** for resilient network operations
18. **Track errors with Sentry** for production monitoring
19. **Pass UUIDs directly** to Supabase queries (not strings)
20. **Invalidate caches** on data mutations
21. **Use security-scoped resources** for file access
22. **Validate all external URLs** before use
23. **Clear sensitive data** from memory after use
24. **Test RLS policies** for multi-tenant isolation

### ❌ Don'ts

1. **Don't access Supabase directly** from views or stores (use repositories)
2. **Don't use hardcoded colors** (use AppColors)
3. **Don't use hardcoded spacing** (use Spacing constants)
4. **Don't ignore errors** (always log and handle)
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
24. **Don't skip security-scoped resource handling** for file operations

---

## 7. Tools & Dependencies

### Core Dependencies

- **SwiftUI** - UI framework
- **Combine** - Reactive programming (for @Published)
- **Supabase** - Backend as a service (database, auth, storage)
- **Dependencies** - Dependency injection framework (Point-Free)
- **OSLog** - Structured logging
- **Sentry** - Error tracking and performance monitoring

### Key Libraries

- **SupabaseClient** - Supabase Swift client
- **SentrySDK** - Sentry error tracking
- **SentrySwiftUI** - Sentry SwiftUI integration
- **GoogleAuthManager** - Google OAuth integration
- **GoogleDriveManager** - Google Drive integration
- **GoogleSheetsManager** - Google Sheets export

### Development Tools

- **Xcode** - Primary IDE
- **Swift Package Manager** - Dependency management
- **XCTest** - Testing framework
- **Instruments** - Performance profiling
- **Sentry Dashboard** - Error monitoring and analytics

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
- **Multi-tenant setup** - Each couple has a unique tenant ID (`couple_id`)

---

## 8. Other Notes

### For LLMs Generating Code

#### State Management
- All stores should be `@MainActor` and `ObservableObject`
- Use `@Published` for observable state
- Use `@Dependency` for injecting repositories
- Follow the V2 store pattern (see `BudgetStoreV2.swift`)

#### Data Flow
1. **View** → calls method on **Store**
2. **Store** → calls method on **Repository**
3. **Repository** → checks **Cache** first
4. **Repository** → makes API call to **Supabase** (if cache miss)
5. **Repository** → caches result and returns data to **Store**
6. **Store** → updates `@Published` properties
7. **View** → automatically re-renders

#### Loading States
Always use the `LoadingState<T>` pattern:
```swift
@Published var loadingState: LoadingState<Data> = .idle

// In view
switch store.loadingState {
case .idle:
    Text("Tap to load")
case .loading:
    ProgressView()
case .loaded(let data):
    DataView(data: data)
case .error(let error):
    ErrorView(error: error)
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

#### Error Tracking
Always capture errors with Sentry in production code:
```swift
do {
    try await performOperation()
} catch {
    logger.error("Operation failed", error: error)
    SentryService.shared.captureError(error, context: [
        "operation": "operationName",
        "additionalContext": "value"
    ])
    throw error
}
```

#### Caching
Use `RepositoryCache` for frequently accessed data:
```swift
// Check cache first
let cacheKey = "resource_\(tenantId.uuidString)"
if let cached: [Resource] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
    return cached
}

// Fetch and cache
let data = try await fetchFromDatabase()
await RepositoryCache.shared.set(cacheKey, value: data, ttl: 60)

// Invalidate on mutations
await RepositoryCache.shared.remove(cacheKey)
```

#### Network Resilience
Use `NetworkRetry` for all network operations:
```swift
let data = try await NetworkRetry.withRetry {
    try await repository.fetchData()
}
```

#### Accessibility
- All colors must meet WCAG AA standards (4.5:1 contrast ratio)
- Use semantic color names from `AppColors`
- Add accessibility labels to all interactive elements
- Test with VoiceOver

#### Multi-Tenancy
- All data is scoped by `couple_id` (tenant ID)
- Repositories automatically filter by current couple
- Never expose data across tenants
- Always pass UUID directly to queries (not `.uuidString`)
- RLS policies enforce security at database level

#### Security
- Use `(SELECT auth.uid())` in RLS policies (not `auth.uid()`)
- Set `search_path = ''` in database functions
- Validate all external URLs before use
- Use security-scoped resources for file access
- Clear sensitive data from memory
- Enable leaked password protection
- Support multiple MFA options

#### Performance
- Use `async let` for parallel operations
- Implement caching in repositories when appropriate
- Use `RepositoryCache` for frequently accessed data
- Monitor with `PerformanceOptimizationService`
- Track cache hit rates and query performance
- Optimize RLS policies for performance
- Add indexes on foreign keys
- Remove unused indexes

#### Error Handling
- Create domain-specific error types (e.g., `BudgetError`, `GuestError`)
- Always log errors with context
- Update loading state on errors
- Show user-friendly error messages
- Capture errors with Sentry for production monitoring

#### Testing
- Write tests for all stores using mock repositories
- Use `.makeTest()` factory methods for test data
- Test error cases and edge cases
- Run accessibility tests before committing
- Test cache behavior (hits, misses, invalidation)
- Test RLS policies for multi-tenant isolation
- Test network retry logic

#### Code Organization
- Keep views under 300 lines (break into components)
- Keep stores focused on single domain
- Use MARK comments for organization
- Group related functionality together
- Extract reusable components to `Views/Shared/`

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

#### When Adding New Features
1. Create domain model in `Domain/Models/{Feature}/`
2. Create repository protocol in `Domain/Repositories/Protocols/`
3. Implement live repository in `Domain/Repositories/Live/`
   - Add caching with `RepositoryCache`
   - Add retry logic with `NetworkRetry`
   - Add error tracking with `SentryService`
4. Implement mock repository in `I Do BlueprintTests/Helpers/MockRepositories.swift`
5. Register repository in `Core/Common/Common/DependencyValues.swift`
6. Create store in `Services/Stores/{Feature}StoreV2.swift`
   - Use `LoadingState<T>` pattern
   - Add error handling
   - Add Sentry tracking
7. Create views in `Views/{Feature}/`
   - Use design system constants
   - Add accessibility labels
   - Keep views under 300 lines
8. Add tests in `I Do BlueprintTests/Services/Stores/`
   - Test with mock repositories
   - Test error cases
   - Test cache behavior
9. Add database migration if needed
   - Enable RLS on new tables
   - Add `couple_id` column for multi-tenancy
   - Create RLS policy: `FOR ALL USING (couple_id = get_user_couple_id())`
   - Add indexes on foreign keys
10. Update this document with new patterns

#### Database Best Practices
- **RLS Policies**: Use `(SELECT auth.uid())` not `auth.uid()`
- **Functions**: Set `search_path = ''` for security
- **Indexes**: Add on foreign keys, remove unused ones
- **Multi-tenancy**: Always filter by `couple_id`
- **UUID Queries**: Pass UUID directly, not `.uuidString`
- **Migrations**: Test thoroughly before deploying
- **Performance**: Monitor query execution time
- **Security**: Test RLS policies for tenant isolation

#### File Operations
- Use `Data(contentsOf:)` for local files (not URLSession)
- Handle security-scoped resources with `startAccessingSecurityScopedResource()`
- Always call `stopAccessingSecurityScopedResource()` in defer block
- Log file operations for debugging
- Handle file access errors gracefully

#### Monitoring & Analytics
- Track errors with Sentry
- Monitor cache hit rates
- Track query performance
- Monitor memory usage
- Track user actions with breadcrumbs
- Use performance transactions for slow operations
- Set up alerts for critical errors

---

**Last Updated:** January 2025  
**Architecture Version:** V2 (Repository Pattern with Caching & Monitoring)  
**Swift Version:** 5.9+  
**Platform:** macOS 13.0+  
**Backend:** Supabase (PostgreSQL with RLS)  
**Monitoring:** Sentry
