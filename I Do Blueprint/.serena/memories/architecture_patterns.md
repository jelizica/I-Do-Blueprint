# I Do Blueprint - Architecture Patterns

## Repository Pattern (Mandatory)

All data access MUST go through repository protocols for testability and separation of concerns.

### Pattern Structure
```swift
// 1. Define protocol (Sendable for concurrency)
protocol GuestRepositoryProtocol: Sendable {
    func fetchGuests() async throws -> [Guest]
    func createGuest(_ guest: Guest) async throws -> Guest
    func updateGuest(_ guest: Guest) async throws -> Guest
    func deleteGuest(id: UUID) async throws
}

// 2. Implement live version (Supabase)
class LiveGuestRepository: GuestRepositoryProtocol {
    @Dependency(\.supabase) var supabase
    private let logger = AppLogger.database
    
    func fetchGuests() async throws -> [Guest] {
        // Supabase implementation
    }
}

// 3. Implement mock version (testing)
class MockGuestRepository: GuestRepositoryProtocol {
    var guests: [Guest] = []
    var shouldThrowError = false
    
    func fetchGuests() async throws -> [Guest] {
        if shouldThrowError { throw TestError.mockError }
        return guests
    }
}

// 4. Register with dependency system
extension DependencyValues {
    var guestRepository: GuestRepositoryProtocol {
        get { self[GuestRepositoryKey.self] }
        set { self[GuestRepositoryKey.self] = newValue }
    }
}
```

### Repository Guidelines
- All CRUD operations go through repositories
- Repositories handle Supabase interactions
- Multi-tenancy filtering happens in repositories
- Errors are domain-specific (e.g., `GuestError`)

## Loading State Pattern (Mandatory)

Use `LoadingState<T>` enum for all async operations to provide proper UI feedback.

### Pattern Definition
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
```

### Usage in Stores
```swift
@Published var loadingState: LoadingState<BudgetData> = .idle

func loadData() async {
    loadingState = .loading
    do {
        let data = try await repository.fetchData()
        loadingState = .loaded(data)
        logger.info("Data loaded successfully")
    } catch {
        loadingState = .error(error)
        logger.error("Failed to load data", error: error)
    }
}
```

### UI Rendering
```swift
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

## Optimistic Updates with Rollback

Provide instant UI feedback while handling server failures gracefully.

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
        // Confirm with server response
    } catch {
        // 3. Rollback on error
        if case .loaded(var data) = loadingState,
           let idx = data.categories.firstIndex(where: { $0.id == category.id }) {
            data.categories[idx] = original
            loadingState = .loaded(data)
        }
        logger.error("Error updating category, rolled back", error: error)
    }
}
```

## Store Composition Pattern

Break large stores into smaller, focused stores for maintainability.

```swift
@MainActor
class BudgetStoreV2: ObservableObject {
    // Composed stores (single responsibility)
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
    
    // Delegate properties for convenience
    var paymentSchedules: [PaymentSchedule] {
        payments.paymentSchedules
    }
}
```

## Data Flow Architecture

**Unidirectional data flow** (MVVM + Repository):

1. **View** → Calls method on **Store**
2. **Store** → Calls method on **Repository** (via @Dependency)
3. **Repository** → Makes API call to **Supabase**
4. **Repository** → Returns data to **Store**
5. **Store** → Updates `@Published` properties
6. **View** → Automatically re-renders (SwiftUI observation)

### Example Flow
```
User taps "Save Guest" button
    ↓
GuestDetailView.save()
    ↓
GuestStoreV2.createGuest()
    ↓
GuestRepositoryProtocol.createGuest()
    ↓
LiveGuestRepository → Supabase API
    ↓
Repository returns Guest
    ↓
Store updates @Published var guests
    ↓
View automatically refreshes
```

## Dependency Injection Pattern

Use `@Dependency` for all external dependencies.

```swift
@MainActor
class GuestStoreV2: ObservableObject {
    @Dependency(\.guestRepository) var repository
    @Dependency(\.alertPresenter) var alertPresenter
    
    private let logger = AppLogger.guests
    
    func loadGuests() async {
        do {
            let guests = try await repository.fetchGuests()
            // Update state
        } catch {
            logger.error("Failed to load guests", error: error)
            alertPresenter.showError(error)
        }
    }
}
```

## Multi-Tenancy Pattern

All data is automatically scoped by `couple_id` (tenant ID).

### Repository Implementation
```swift
func fetchGuests() async throws -> [Guest] {
    guard let tenantId = authContext.currentCoupleId else {
        throw GuestError.missingTenantContext
    }
    
    return try await supabase
        .from("guests")
        .select()
        .eq("couple_id", value: tenantId)
        .execute()
        .value
}
```

### Security Principles
- **Never expose data across tenants**
- **Always filter by couple_id in repositories**
- **Validate tenant context before operations**

## Test Pattern (with Mocks)

```swift
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
        XCTAssertEqual(store.guests.count, 1)
        XCTAssertFalse(store.loadingState.isLoading)
    }
}
```

## Performance Patterns

### Parallel Loading
```swift
async let summary = repository.fetchBudgetSummary()
async let categories = repository.fetchCategories()
async let expenses = repository.fetchExpenses()

let results = try await (summary, categories, expenses)
```

### Caching
```swift
private var cache = RepositoryCache<UUID, Guest>()

func fetchGuest(id: UUID) async throws -> Guest {
    if let cached = cache.get(id) {
        return cached
    }
    
    let guest = try await supabase.fetchGuest(id)
    cache.set(guest, for: id)
    return guest
}
```
