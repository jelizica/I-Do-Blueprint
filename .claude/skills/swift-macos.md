# Swift/macOS Development Skill

## Swift Language Guidelines

### Concurrency
- **ALWAYS use `async/await`** (never completion handlers)
- **NEVER use `@MainActor`** on types that cross actor boundaries
- **ALWAYS conform to `Sendable`** for types shared across actors
- **USE `actor`** for thread-safe services and caches
- **USE `nonisolated`** for logger methods and pure functions

### Error Handling
```swift
// ✅ CORRECT - Async throws
func fetchData() async throws -> Data {
    let data = try await networkCall()
    return data
}

// ❌ WRONG - Completion handlers
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    // Don't use this pattern
}
```

### Optional Handling
```swift
// ✅ CORRECT - Guard for early return
guard let value = optionalValue else {
    logger.warning("Missing required value")
    return
}

// ✅ CORRECT - If let for scoped usage
if let value = optionalValue {
    process(value)
}

// ❌ AVOID - Force unwrapping without justification
let value = optionalValue! // Only with clear comment why it's safe
```

### Type Safety
```swift
// ✅ CORRECT - Explicit types for clarity
let id: UUID = UUID()
let name: String = "Guest"

// ✅ CORRECT - Type inference where obvious
let guests = repository.fetchGuests() // Type clear from context

// ❌ AVOID - Any or AnyObject
var data: Any // Use concrete types
```

## SwiftUI Best Practices

### View Organization
```swift
struct FeatureView: View {
    // MARK: - Properties
    @Environment(\.appStores) private var appStores
    @State private var selectedItem: Item?

    // MARK: - Computed Properties
    private var store: FeatureStore { appStores.feature }

    // MARK: - Body
    var body: some View {
        content
            .task { await loadData() }
            .alert("Error", isPresented: $showError) {
                errorAlert
            }
    }

    // MARK: - View Components
    @ViewBuilder
    private var content: some View {
        // View content
    }

    // MARK: - Actions
    private func loadData() async {
        await store.load()
    }
}
```

### State Management
```swift
// ✅ CORRECT - Environment for shared state
@Environment(\.budgetStore) private var store

// ✅ CORRECT - State for local UI state
@State private var searchText = ""
@State private var isExpanded = false

// ❌ WRONG - StateObject for singleton stores
@StateObject private var store = BudgetStore() // Memory leak!
```

### Accessibility
```swift
// ✅ ALWAYS add accessibility labels
Button("Delete") { }
    .accessibilityLabel("Delete guest")
    .accessibilityHint("Removes this guest from the list")

Image(systemName: "plus")
    .accessibilityLabel("Add new item")
```

## macOS Specifics

### File Access
```swift
// ✅ CORRECT - Security-scoped resource access
let openPanel = NSOpenPanel()
openPanel.canChooseFiles = true
openPanel.allowedContentTypes = [.csv, .xlsx]

if openPanel.runModal() == .OK, let url = openPanel.url {
    // URL is already security-scoped
    let data = try Data(contentsOf: url)
    // Process data
}

// ❌ WRONG - Direct file URLs without security scope
let url = URL(fileURLWithPath: "/path/to/file")
let data = try Data(contentsOf: url) // May fail with sandbox
```

### Menu Commands
```swift
// Define in App struct
.commands {
    CommandGroup(replacing: .newItem) {
        Button("New Guest") {
            // Action
        }
        .keyboardShortcut("n", modifiers: [.command])
    }
}
```

### Window Management
```swift
// Single window app pattern
WindowGroup {
    RootFlowView()
}
.windowStyle(.hiddenTitleBar)
.windowResizability(.contentSize)
.defaultSize(width: 1200, height: 800)
```

## Testing

### Test Structure
```swift
@MainActor
final class FeatureStoreTests: XCTestCase {
    var mockRepository: MockFeatureRepository!
    var store: FeatureStore!

    override func setUp() async throws {
        mockRepository = MockFeatureRepository()
        store = await withDependencies {
            $0.featureRepository = mockRepository
        } operation: {
            FeatureStore()
        }
    }

    func test_operation_success() async throws {
        // Given
        mockRepository.items = [.makeTest()]

        // When
        await store.loadItems()

        // Then
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.loadingState, .loaded([.makeTest()]))
    }
}
```

### Test Data Builders
```swift
extension Guest {
    static func makeTest(
        id: UUID = UUID(),
        firstName: String = "Test",
        lastName: String = "Guest",
        email: String? = "test@example.com"
    ) -> Guest {
        Guest(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            // ... other properties with defaults
        )
    }
}
```

## Code Organization

### File Structure
```
Feature/
├── Models/
│   ├── FeatureModel.swift
│   └── FeatureEnums.swift
├── Views/
│   ├── FeatureView.swift
│   └── Components/
│       ├── FeatureCard.swift
│       └── FeatureRow.swift
├── Stores/
│   └── FeatureStore.swift
└── Repositories/
    ├── FeatureRepositoryProtocol.swift
    └── LiveFeatureRepository.swift
```

### MARK Comments (Required for files > 100 lines)
```swift
// MARK: - Type Definition
// MARK: - Properties
// MARK: - Initialization
// MARK: - Public Interface
// MARK: - Private Helpers
// MARK: - Computed Properties
// MARK: - Protocol Conformance
```

## Common Patterns

### Repository Pattern
```swift
// Protocol
protocol FeatureRepositoryProtocol: Sendable {
    func fetch() async throws -> [Item]
    func create(_ item: Item) async throws -> Item
}

// Live Implementation
final class LiveFeatureRepository: FeatureRepositoryProtocol {
    private let supabase: SupabaseClient
    private let cache = RepositoryCache.shared

    func fetch() async throws -> [Item] {
        let cacheKey = "items_\(tenantId.uuidString)"
        if let cached: [Item] = await cache.get(cacheKey, maxAge: 60) {
            return cached
        }

        let items = try await NetworkRetry.withRetry {
            try await supabase.database
                .from("items")
                .select()
                .eq("couple_id", value: tenantId) // ✅ UUID directly
                .execute()
                .value
        }

        await cache.set(cacheKey, value: items, ttl: 60)
        return items
    }
}
```

### Store Pattern
```swift
@MainActor
final class FeatureStore: ObservableObject {
    @Published var items: [Item] = []
    @Published var loadingState: LoadingState<[Item]> = .idle

    @Dependency(\.featureRepository) private var repository
    private let logger = AppLogger.store

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

## Performance

### Lazy Loading
```swift
// ✅ Use lazy for expensive computed properties
private lazy var formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
```

### Background Work
```swift
// ✅ Heavy computation off main thread
Task.detached {
    let result = await performHeavyWork()
    await MainActor.run {
        self.updateUI(result)
    }
}
```

## Security

### Keychain Access
```swift
// ✅ Use KeychainAccess wrapper
try KeychainAccess.shared.set(token, for: "auth_token")
let token = try KeychainAccess.shared.get("auth_token")
```

### Sensitive Data
```swift
// ✅ Never log sensitive data
logger.info("User logged in", metadata: [
    "userId": userId.uuidString // ✅ ID is fine
    // ❌ Never log: password, token, email
])
```

## Build & Deploy

### Build Commands
```bash
# Clean build
xcodebuild clean -project "Project.xcodeproj" -scheme "Scheme"

# Build
xcodebuild build -project "Project.xcodeproj" -scheme "Scheme" -destination 'platform=macOS'

# Test
xcodebuild test -project "Project.xcodeproj" -scheme "Scheme" -destination 'platform=macOS'

# Specific test
xcodebuild test -project "Project.xcodeproj" -scheme "Scheme" -destination 'platform=macOS' -only-testing:"TestTarget/TestClass/testMethod"
```

### Code Signing
- Use automatic signing for development
- Manual signing for distribution
- Never commit provisioning profiles or certificates

## Anti-Patterns to Avoid

1. **Force unwrapping without justification**
   ```swift
   let value = dict["key"]! // ❌ Can crash
   ```

2. **Retain cycles in closures**
   ```swift
   // ❌ Strong reference cycle
   task.onComplete { result in
       self.process(result)
   }

   // ✅ Weak self
   task.onComplete { [weak self] result in
       self?.process(result)
   }
   ```

3. **Blocking the main thread**
   ```swift
   // ❌ Synchronous network call on main thread
   let data = try Data(contentsOf: url)

   // ✅ Async
   let data = try await URLSession.shared.data(from: url).0
   ```

4. **Ignoring errors**
   ```swift
   // ❌ Silent failure
   try? performOperation()

   // ✅ Handle or log
   do {
       try await performOperation()
   } catch {
       logger.error("Operation failed", error: error)
   }
   ```
