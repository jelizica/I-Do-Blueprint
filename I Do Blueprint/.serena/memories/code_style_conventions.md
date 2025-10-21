# I Do Blueprint - Code Style & Conventions

## Swift Version & Language Features
- **Swift 5.9+** with modern concurrency
- **Strict concurrency checking** enabled
- **Sendable conformance** for types crossing actor boundaries
- **MainActor** for UI-related classes (Views, Stores)
- **async/await** preferred over completion handlers

## Naming Conventions

### Files
- **Views**: `{Feature}{Purpose}View.swift` → `BudgetDashboardView.swift`
- **Stores**: `{Feature}StoreV2.swift` → `BudgetStoreV2.swift`
- **Models**: `{EntityName}.swift` → `Guest.swift`, `Expense.swift`
- **Protocols**: `{Purpose}Protocol.swift` → `GuestRepositoryProtocol.swift`
- **Extensions**: `{Type}+{Purpose}.swift` → `Color+Hex.swift`

### Classes & Structs
- **Views**: `{Feature}{Purpose}View` → `DashboardProgressCard`
- **Stores**: `{Feature}StoreV2` (V2 suffix mandatory)
- **Models**: PascalCase nouns → `Guest`, `BudgetCategory`
- **Protocols**: `{Purpose}Protocol` → `GuestRepositoryProtocol`

### Variables & Properties
- **camelCase** for all variables
- **Descriptive names**: `totalSpent` not `ts`
- **Boolean prefixes**: `is`, `has`, `should` → `isLoading`, `hasError`
- **@Published** for observable state in stores

### Functions
- **camelCase** with verb prefixes
- **CRUD**: `fetch`, `create`, `update`, `delete`
- **Loading**: `load{Resource}()` → `loadBudgetData()`
- **Async suffix** if ambiguous → `fetchDataAsync()`

## Documentation

### File Headers
```swift
//
//  FileName.swift
//  I Do Blueprint
//
//  Brief description of file purpose
//
```

### DocStrings for Public APIs
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

### MARK Comments
```swift
// MARK: - Section Name
// MARK: Public Interface
// MARK: Private Helpers
// MARK: Computed Properties
```

## Async/Await Best Practices

### Parallel Operations
```swift
// ✅ Good: Parallel loading
async let summary = repository.fetchBudgetSummary()
async let categories = repository.fetchCategories()
async let expenses = repository.fetchExpenses()

let summaryResult = try await summary
let categoriesResult = try await categories
let expensesResult = try await expenses
```

### Task Usage
```swift
// Fire-and-forget operations
Task {
    await performBackgroundTask()
}

// Task with MainActor
Task { @MainActor in
    updateUI()
}
```

## Type Safety

- **Strong typing** - avoid `Any` when possible
- **Enums over strings** for constants
- **UUID** for identifiers
- **Codable** for serialization
- **Sendable** for concurrency safety

## Error Handling

### Custom Error Types
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
        }
    }
}
```

### Error Propagation Pattern
```swift
do {
    let created = try await repository.createCategory(category)
    logger.info("Added category: \(created.categoryName)")
} catch {
    loadingState = .error(BudgetError.createFailed(underlying: error))
    logger.error("Error adding category", error: error)
}
```

## Design System Usage

### Always Use Constants
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

## Accessibility

### Semantic Modifiers
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

### Color Contrast
- All colors must meet **WCAG AA standards** (4.5:1 contrast ratio)
- Use semantic color names from `AppColors`
- Test with VoiceOver

## Logging

### Category-Specific Loggers
```swift
private let logger = AppLogger.database  // Or .auth, .api, .ui, etc.

logger.info("Operation succeeded")
logger.error("Operation failed", error: error)
logger.debug("Debug info")  // Only in DEBUG builds
```

### Log Levels
- **info**: Important events (user actions, state changes)
- **error**: Failures requiring attention
- **warning**: Potential issues
- **debug**: Development debugging (stripped in Release)

## Code Organization

### File Size Limits
- **Views**: Keep under 300 lines (break into components)
- **Stores**: Focus on single domain
- **Use MARK**: Required for files over 100 lines

### Section Organization
```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - Public Interface
// MARK: - Private Helpers
// MARK: - Computed Properties
```

## Common Abbreviations
- **cfg**: config
- **impl**: implementation
- **repo**: repository
- **auth**: authentication
- **nav**: navigation
- **mgr**: manager
