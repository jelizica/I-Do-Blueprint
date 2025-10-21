# 📘 Project Best Practices

## 1. Project Purpose

**I Do Blueprint** is a comprehensive macOS wedding planning application built with SwiftUI. It helps couples manage all aspects of their wedding including budget tracking, guest management, vendor coordination, task planning, timeline management, document storage, and visual planning (mood boards, seating charts). The app uses Supabase as a backend for multi-tenant data storage and supports Google Drive integration for document management.

**Domain:** Wedding planning and event management  
**Platform:** macOS (SwiftUI)  
**Architecture:** MVVM with Repository Pattern, Dependency Injection

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
│   ├── Extensions/
│   └── Utilities/
├── Design/                       # Design system and accessibility
│   ├── DesignSystem.swift       # Complete design system
│   ├── ColorPalette.swift
│   ├── Typography.swift
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
│       ├── Live/                # Production implementations
│       └── Mock/                # Test implementations
├── Services/                     # Application services
│   ├── Stores/                  # State management (V2 pattern)
│   ├── API/                     # API clients
│   ├─��� Auth/                    # Authentication
│   ├── Storage/                 # Data persistence
│   └── Analytics/               # Analytics and performance
├── Utilities/                    # Shared utilities
│   └── Logging/                 # Structured logging
├── Views/                        # UI layer organized by feature
│   ├── Budget/
│   ├── Dashboard/
│   ├── Guests/
│   ├── Tasks/
│   ├── Vendors/
│   └── Shared/                  # Reusable components
└── Resources/                    # Assets, localizations, Lottie files
```

### Key Architectural Principles

- **Feature-based organization**: Views, models, and logic grouped by feature domain
- **Separation of concerns**: Clear boundaries between UI (Views), State (Stores), Business Logic (Repositories), and Data (Models)
- **Repository pattern**: All data access goes through repository protocols for testability
- **Dependency injection**: Using Swift's `@Dependency` macro for loose coupling
- **V2 naming convention**: New architecture stores use `V2` suffix (e.g., `BudgetStoreV2`)

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
├── Domain/
│   └── Repositories/           # Repository tests
├── Services/
│   └── Stores/                 # Store tests (e.g., BudgetStoreV2Tests.swift)
├── Helpers/
│   ├── MockRepositories.swift  # Mock implementations for testing
│   └── ModelBuilders.swift     # Test data builders
├── Integration/                # Integration tests
└── Performance/                # Performance benchmarks

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

#### Async/Await Usage
- Prefer `async/await` over completion handlers
- Use `Task` for fire-and-forget operations
- Use `async let` for parallel operations
- Always handle errors with `do-catch` or `try?`

```swift
// ✅ Good: Parallel loading
async let summary = repository.fetchBudgetSummary()
async let categories = repository.fetchCategories()
async let expenses = repository.fetchExpenses()

let summaryResult = try await summary
let categoriesResult = try await categories
let expensesResult = try await expenses
```

#### Type Safety
- Use strong typing (avoid `Any` when possible)
- Prefer enums over string constants
- Use `UUID` for identifiers
- Use `Codable` for serialization

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
```

### Error Handling

#### Custom Error Types
```swift
enum BudgetError: Error, LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch budget data: \(error.localizedDescription)"
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

```swift
do {
    let created = try await repository.createCategory(category)
    logger.info("Added category: \(created.categoryName)")
} catch {
    loadingState = .error(BudgetError.createFailed(underlying: error))
    logger.error("Error adding category", error: error)
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
    // Implementation using Supabase
}

// 3. Implement mock version
class MockGuestRepository: GuestRepositoryProtocol {
    var guests: [Guest] = []
    var shouldThrowError = false
    // Mock implementation
}

// 4. Register with dependency system
extension DependencyValues {
    var guestRepository: GuestRepositoryProtocol {
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
    }
}
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

---

## 7. Tools & Dependencies

### Core Dependencies

- **SwiftUI** - UI framework
- **Combine** - Reactive programming (for @Published)
- **Supabase** - Backend as a service (database, auth, storage)
- **Dependencies** - Dependency injection framework
- **OSLog** - Structured logging

### Key Libraries

- **SupabaseClient** - Supabase Swift client
- **GoogleAuthManager** - Google OAuth integration
- **GoogleDriveManager** - Google Drive integration
- **GoogleSheetsManager** - Google Sheets export

### Development Tools

- **Xcode** - Primary IDE
- **Swift Package Manager** - Dependency management
- **XCTest** - Testing framework
- **Instruments** - Performance profiling

### Project Setup

1. **Clone repository**
2. **Open `I Do Blueprint.xcodeproj`**
3. **Configure Supabase credentials** in `Config.plist`
4. **Configure Google OAuth** credentials
5. **Build and run** (⌘R)

### Environment Configuration

- **Config.plist** - Contains API keys and configuration
- **Supabase URL and Anon Key** required
- **Google OAuth Client ID** required for Google integration
- **Multi-tenant setup** - Each couple has a unique tenant ID

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
3. **Repository** → makes API call to **Supabase**
4. **Repository** → returns data to **Store**
5. **Store** → updates `@Published` properties
6. **View** → automatically re-renders

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

#### Accessibility
- All colors must meet WCAG AA standards (4.5:1 contrast ratio)
- Use semantic color names from `AppColors`
- Add accessibility labels to all interactive elements
- Test with VoiceOver

#### Multi-Tenancy
- All data is scoped by `couple_id` (tenant ID)
- Repositories automatically filter by current couple
- Never expose data across tenants

#### Performance
- Use `async let` for parallel operations
- Implement caching in repositories when appropriate
- Use `RepositoryCache` for frequently accessed data
- Monitor with `PerformanceOptimizationService`

#### Error Handling
- Create domain-specific error types (e.g., `BudgetError`, `GuestError`)
- Always log errors with context
- Update loading state on errors
- Show user-friendly error messages

#### Testing
- Write tests for all stores using mock repositories
- Use `.makeTest()` factory methods for test data
- Test error cases and edge cases
- Run accessibility tests before committing

#### Code Organization
- Keep views under 300 lines (break into components)
- Keep stores focused on single domain
- Use MARK comments for organization
- Group related functionality together

#### Common Pitfalls
1. **Forgetting @MainActor** on stores → runtime crashes
2. **Not handling loading states** → poor UX
3. **Skipping error handling** → silent failures
4. **Using hardcoded colors** → accessibility issues
5. **Not testing with mocks** → brittle tests
6. **Mixing concerns** → hard to maintain

#### When Adding New Features
1. Create domain model in `Domain/Models/{Feature}/`
2. Create repository protocol in `Domain/Repositories/Protocols/`
3. Implement live repository in `Domain/Repositories/Live/`
4. Implement mock repository in `I Do BlueprintTests/Helpers/MockRepositories.swift`
5. Create store in `Services/Stores/{Feature}StoreV2.swift`
6. Create views in `Views/{Feature}/`
7. Add tests in `I Do BlueprintTests/Services/Stores/`
8. Update this document with new patterns

---

**Last Updated:** January 2025  
**Architecture Version:** V2 (Repository Pattern)  
**Swift Version:** 5.9+  
**Platform:** macOS 13.0+
