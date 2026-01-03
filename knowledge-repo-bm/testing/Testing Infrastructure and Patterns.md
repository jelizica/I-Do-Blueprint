---
title: Testing Infrastructure and Patterns
type: note
permalink: testing/testing-infrastructure-and-patterns
tags:
- testing
- unit-tests
- mocks
- xctest
- tdd
---

# Testing Infrastructure and Patterns

## Overview

I Do Blueprint uses XCTest framework with a comprehensive testing infrastructure including unit tests, performance tests, accessibility tests, and integration tests.

## Test Organization

```
I Do BlueprintTests/
├── Core/                   # Core infrastructure tests
│   ├── AppStoresTests.swift
│   ├── SingletonTypeTests.swift
│   ├── URLValidatorTests.swift
│   └── Errors/            # Error handling tests
├── Services/
│   └── Stores/            # Store unit tests
│       └── BudgetStoreV2Tests.swift
├── Domain/
│   ├── Models/            # Model tests
│   └── Repositories/      # Repository tests (if any)
├── Utilities/             # Utility tests
│   ├── InputValidationTests.swift
│   └── RepositoryNetworkTests.swift
├── Performance/           # Performance benchmarks
│   ├── AppStoresPerformanceTests.swift
│   └── RepositoryCacheTests.swift
├── Accessibility/         # WCAG compliance tests
│   └── ColorAccessibilityTests.swift
├── Helpers/               # Test utilities
│   ├── ModelBuilders.swift
│   ├── MockRepositories.swift (re-export file)
│   └── MockRepositories/  # Individual mock implementations
│       ├── MockGuestRepository.swift
│       ├── MockBudgetRepository.swift
│       ├── MockTaskRepository.swift
│       ├── MockTimelineRepository.swift
│       ├── MockSettingsRepository.swift
│       ├── MockNotesRepository.swift
│       ├── MockDocumentRepository.swift
│       ├── MockVendorRepository.swift
│       ├── MockVisualPlanningRepository.swift
│       ├── MockCollaborationRepository.swift
│       ├── MockPresenceRepository.swift
│       └── MockActivityFeedRepository.swift
└── Integration/           # Integration tests (if any)
```

## Testing Philosophy

1. **Mock repositories for unit tests** - All stores tested with mocks
2. **Test data builders** - Use `.makeTest()` factory methods
3. **MainActor tests** - Store tests use `@MainActor`
4. **Dependency injection** - Use `withDependencies` to inject mocks
5. **Separation of concerns** - Test one component at a time
6. **Accessibility-first** - WCAG compliance tests

## Mock Repository Pattern

### Organization

Mock repositories were recently refactored from a single monolithic file to separate files per repository for:
- Better organization
- Faster compilation
- Easier maintenance
- Clear separation of concerns

### Mock Repository Structure

```swift
class MockGuestRepository: GuestRepositoryProtocol {
    // MARK: - Mock Data
    var guests: [Guest] = []
    var guestStats: GuestStats?
    
    // MARK: - Error Simulation
    var shouldThrowError = false
    var errorToThrow: Error = AppError.networkError
    
    // MARK: - Call Tracking
    var fetchGuestsCalled = false
    var createGuestCalled = false
    
    // MARK: - Protocol Implementation
    func fetchGuests() async throws -> [Guest] {
        fetchGuestsCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return guests
    }
    
    func createGuest(_ guest: Guest) async throws -> Guest {
        createGuestCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        var created = guest
        created.id = UUID()
        guests.append(created)
        return created
    }
}
```

### All Mock Repositories

- MockGuestRepository
- MockBudgetRepository (largest - related to Issue I Do Blueprint-0wo)
- MockTaskRepository
- MockTimelineRepository
- MockSettingsRepository
- MockNotesRepository
- MockDocumentRepository
- MockVendorRepository
- MockVisualPlanningRepository
- MockCollaborationRepository
- MockPresenceRepository
- MockActivityFeedRepository

## Store Testing Pattern

All store tests follow this pattern:

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
    
    override func tearDown() async throws {
        mockRepository = nil
        store = nil
    }
    
    func test_loadBudgetData_success() async throws {
        // Given
        mockRepository.categories = [.makeTest()]
        mockRepository.expenses = [.makeTest()]
        
        // When
        await store.loadBudgetData()
        
        // Then
        XCTAssertEqual(store.categories.count, 1)
        XCTAssertTrue(mockRepository.fetchCategoriesCalled)
    }
    
    func test_loadBudgetData_error() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = BudgetError.networkError
        
        // When
        await store.loadBudgetData()
        
        // Then
        if case .error(let error) = store.loadingState {
            XCTAssertNotNil(error)
        } else {
            XCTFail("Expected error state")
        }
    }
}
```

## Test Data Builders

**File:** `I Do BlueprintTests/Helpers/ModelBuilders.swift`

Factory methods for creating test data:

```swift
extension Guest {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        fullName: String = "Test Guest",
        email: String? = "test@example.com",
        rsvpStatus: RSVPStatus = .pending,
        phoneNumber: String? = nil,
        hasPlus: Bool = false
    ) -> Guest {
        Guest(
            id: id,
            coupleId: coupleId,
            fullName: fullName,
            email: email,
            rsvpStatus: rsvpStatus,
            phoneNumber: phoneNumber,
            hasPlus: hasPlus
        )
    }
}

extension Vendor {
    static func makeTest(
        id: Int64 = 1,
        vendorName: String = "Test Vendor",
        category: String = "Catering",
        isBooked: Bool = false,
        estimatedCost: Double? = 5000.0
    ) -> Vendor {
        Vendor(
            id: id,
            vendorName: vendorName,
            category: category,
            isBooked: isBooked,
            estimatedCost: estimatedCost
        )
    }
}
```

## Dependency Injection in Tests

Using `withDependencies` to inject mocks:

```swift
store = await withDependencies {
    $0.guestRepository = mockRepository
    $0.taskRepository = mockTaskRepo
    $0.vendorRepository = mockVendorRepo
} operation: {
    GuestStoreV2()
}
```

## Performance Testing

**File:** `I Do BlueprintTests/Performance/RepositoryCacheTests.swift`

Tests cache performance and hit rates:

```swift
func testCachePerformance() throws {
    measure {
        // Test cache operations
        for _ in 0..<1000 {
            let _ = cache.get("key")
        }
    }
}
```

**File:** `I Do BlueprintTests/Performance/AppStoresPerformanceTests.swift`

Tests store initialization and loading performance.

## Accessibility Testing

**File:** `I Do BlueprintTests/Accessibility/ColorAccessibilityTests.swift`

Validates WCAG color contrast ratios:

```swift
func testColorContrast() {
    let textColor = AppColors.text
    let backgroundColor = AppColors.background
    
    let ratio = ColorAccessibility.contrastRatio(
        foreground: textColor,
        background: backgroundColor
    )
    
    XCTAssertGreaterThanOrEqual(ratio, 4.5, "WCAG AA requires 4.5:1")
}
```

## Test Naming Conventions

### Test Methods
```
test_{methodName}_{scenario}
```

Examples:
- `test_loadGuests_success`
- `test_loadGuests_error`
- `test_createGuest_duplicateGuest`
- `test_deleteGuest_notFound`

### Test Files
```
{ClassName}Tests.swift
```

Examples:
- `BudgetStoreV2Tests.swift`
- `GuestRepositoryTests.swift`
- `InputValidationTests.swift`

## Common Test Patterns

### Testing Async Operations

```swift
func test_asyncOperation() async throws {
    let result = await store.performOperation()
    XCTAssertNotNil(result)
}
```

### Testing Error Handling

```swift
func test_errorHandling() async {
    mockRepository.shouldThrowError = true
    mockRepository.errorToThrow = AppError.networkError
    
    await store.operation()
    
    XCTAssertTrue(store.hasError)
}
```

### Testing Loading States

```swift
func test_loadingState() async {
    // Initially idle
    XCTAssertEqual(store.loadingState, .idle)
    
    // Becomes loading
    let loadTask = Task {
        await store.load()
    }
    
    try? await Task.sleep(nanoseconds: 100_000) // 0.1ms
    XCTAssertEqual(store.loadingState, .loading)
    
    await loadTask.value
    
    // Eventually loaded
    if case .loaded = store.loadingState {
        XCTAssertTrue(true)
    } else {
        XCTFail("Expected loaded state")
    }
}
```

### Testing Call Tracking

```swift
func test_repositoryCalled() async {
    await store.fetchData()
    
    XCTAssertTrue(mockRepository.fetchDataCalled)
    XCTAssertEqual(mockRepository.fetchDataCallCount, 1)
}
```

## Test Coverage Goals

- **Stores:** 80%+ coverage
- **Repositories:** 70%+ coverage
- **Domain Services:** 80%+ coverage
- **Utilities:** 90%+ coverage
- **Models:** 60%+ (mainly validation logic)

## Running Tests

### All Tests
```bash
xcodebuild test -project "I Do Blueprint.xcodeproj" \
    -scheme "I Do Blueprint" \
    -destination 'platform=macOS'
```

### Specific Test Class
```bash
xcodebuild test -project "I Do Blueprint.xcodeproj" \
    -scheme "I Do Blueprint" \
    -destination 'platform=macOS' \
    -only-testing:"I Do BlueprintTests/BudgetStoreV2Tests"
```

### Specific Test Method
```bash
xcodebuild test -project "I Do Blueprint.xcodeproj" \
    -scheme "I Do Blueprint" \
    -destination 'platform=macOS' \
    -only-testing:"I Do BlueprintTests/BudgetStoreV2Tests/test_loadBudgetData_success"
```

## Test Best Practices

### ✅ Do's
1. **Use meaningful test names** - Describe what is being tested
2. **Follow Given-When-Then** - Structure tests clearly
3. **Test one thing per test** - Single responsibility
4. **Use test builders** - `.makeTest()` factories
5. **Clean up in tearDown** - Prevent test interference
6. **Test error cases** - Not just happy paths
7. **Use @MainActor** - For store and UI tests
8. **Track mock calls** - Verify interactions

### ❌ Don'ts
1. **Don't test implementation details** - Test behavior
2. **Don't share state between tests** - Use setUp/tearDown
3. **Don't use real repositories** - Always use mocks for unit tests
4. **Don't skip async/await** - Properly handle concurrency
5. **Don't ignore warnings** - Fix test warnings immediately
6. **Don't test private methods directly** - Test through public API

## Current Test Issues

**Issue:** I Do Blueprint-0wo (MockBudgetRepository reduction)
- MockBudgetRepository is very large
- Needs refactoring and optimization
- In progress

## Future Improvements

1. **Integration tests** - Test repository + Supabase locally
2. **UI tests** - SwiftUI view testing
3. **Snapshot tests** - Visual regression testing
4. **Code coverage reporting** - Automated coverage tracking
5. **Continuous integration** - Automated test runs

## References
- Related Issue: I Do Blueprint-0wo (MockBudgetRepository reduction)
- Related Issue: I Do Blueprint-s2q (API layer integration tests)
- Related Issue: I Do Blueprint-bji (Domain service unit tests)
- File: `I Do BlueprintTests/Helpers/ModelBuilders.swift` - Test factories
- File: `I Do BlueprintTests/Helpers/MockRepositories/` - Mock implementations