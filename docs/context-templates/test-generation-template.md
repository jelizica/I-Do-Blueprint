# Test Generation Context Template (Qodo Gen)

**Last Updated**: [Auto-update timestamp]

---

## Test Generation Goal
[What component/feature needs testing]

**Target**: [Class/Function/Feature name]
**Test Type**: [Unit / Integration / UI]
**Coverage Goal**: [Percentage or specific scenarios]

---

## Project Architecture Context

### Pattern in Use
- **Architecture**: Repository Pattern with Domain Services
- **State Management**: V2 Stores with `@MainActor` and `ObservableObject`
- **Testing Framework**: XCTest with mock repositories

### Key Conventions
- Test files: `{FeatureName}Tests.swift`
- Test classes: `final class {FeatureName}Tests: XCTestCase`
- Test methods: `func test{Scenario}_{ExpectedOutcome}()`
- Mock classes: `Mock{Protocol}` (e.g., `MockGuestRepository`)
- Use `@MainActor` for store tests
- Use `withDependencies` to inject mocks

---

## Target Component Details

### File Path
```
[Full path to file being tested]
```

### Component Type
- [ ] Store (V2 pattern)
- [ ] Repository (Protocol implementation)
- [ ] Domain Service (Actor-based)
- [ ] View (SwiftUI)
- [ ] Model (Codable struct)
- [ ] Utility (Pure function)

### Dependencies
```swift
// List all dependencies that need mocking
@Dependency(\.guestRepository) var guestRepository
@Dependency(\.budgetRepository) var budgetRepository
// etc.
```

### Key Methods to Test
1. `methodName()` - [What it does]
2. `methodName()` - [What it does]
3. `methodName()` - [What it does]

---

## Test Scenarios Required

### Happy Path
- [ ] Scenario 1: [Description]
- [ ] Scenario 2: [Description]
- [ ] Scenario 3: [Description]

### Error Cases
- [ ] Network failure
- [ ] Invalid data
- [ ] Missing tenant context
- [ ] Cache miss/hit scenarios

### Edge Cases
- [ ] Empty results
- [ ] Large datasets
- [ ] Concurrent operations
- [ ] State transitions

---

## Mock Setup Requirements

### Mock Repositories Needed
```swift
// Example structure
class MockGuestRepository: GuestRepositoryProtocol {
    var guests: [Guest] = []
    var shouldThrowError = false
    var errorToThrow: Error?
    
    func fetchGuests() async throws -> [Guest] {
        if shouldThrowError {
            throw errorToThrow ?? GuestError.fetchFailed
        }
        return guests
    }
}
```

### Test Data Builders
```swift
// Use .makeTest() factory methods
let testGuest = Guest.makeTest(
    fullName: "Test Guest",
    email: "test@example.com"
)
```

---

## Recent Similar Tests (For Consistency)

### Pattern 1: Store Testing
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

### Pattern 2: Repository Testing
```swift
final class LiveGuestRepositoryTests: XCTestCase {
    var repository: LiveGuestRepository!
    var mockSupabase: MockSupabaseClient!
    
    override func setUp() {
        mockSupabase = MockSupabaseClient()
        repository = LiveGuestRepository(supabase: mockSupabase)
    }
    
    func test_fetchGuests_success() async throws {
        // Given
        let expectedGuests = [Guest.makeTest()]
        mockSupabase.mockResponse = expectedGuests
        
        // When
        let guests = try await repository.fetchGuests()
        
        // Then
        XCTAssertEqual(guests.count, 1)
        XCTAssertEqual(guests.first?.fullName, "Test Guest")
    }
}
```

### Pattern 3: Domain Service Testing
```swift
final class BudgetAggregationServiceTests: XCTestCase {
    var service: BudgetAggregationService!
    var mockRepository: MockBudgetRepository!
    
    override func setUp() async throws {
        mockRepository = MockBudgetRepository()
        service = BudgetAggregationService(repository: mockRepository)
    }
    
    func test_fetchBudgetOverview_aggregatesCorrectly() async throws {
        // Given
        mockRepository.items = [.makeTest()]
        mockRepository.expenses = [.makeTest()]
        
        // When
        let overview = try await service.fetchBudgetOverview(scenarioId: "test")
        
        // Then
        XCTAssertFalse(overview.isEmpty)
    }
}
```

---

## Must Follow Patterns

### Error Handling
```swift
func test_operation_failure() async throws {
    // Given
    mockRepository.shouldThrowError = true
    mockRepository.errorToThrow = GuestError.fetchFailed
    
    // When/Then
    do {
        _ = try await store.loadGuests()
        XCTFail("Expected error to be thrown")
    } catch {
        XCTAssertTrue(error is GuestError)
    }
}
```

### Loading State Testing
```swift
func test_loadingState_transitions() async throws {
    // Given
    XCTAssertEqual(store.loadingState, .idle)
    
    // When
    let loadTask = Task {
        await store.loadData()
    }
    
    // Then - Check loading state
    try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
    XCTAssertEqual(store.loadingState, .loading)
    
    await loadTask.value
    
    // Then - Check loaded state
    if case .loaded = store.loadingState {
        XCTAssertTrue(true)
    } else {
        XCTFail("Expected loaded state")
    }
}
```

### Cache Testing
```swift
func test_cache_hit() async throws {
    // Given - First load populates cache
    await store.loadData()
    let firstLoadTime = store.lastLoadTime
    
    // When - Second load should use cache
    await store.loadData()
    
    // Then
    XCTAssertEqual(store.lastLoadTime, firstLoadTime)
    XCTAssertEqual(mockRepository.fetchCallCount, 1) // Only called once
}
```

---

## Must Avoid Anti-Patterns

### ❌ Don't Do This
```swift
// Don't use force unwrapping
let guest = store.guests.first!

// Don't skip error testing
func test_happyPath() { /* only tests success */ }

// Don't use real network calls
let response = try await URLSession.shared.data(from: url)

// Don't test implementation details
XCTAssertEqual(store.privateInternalCounter, 5)
```

### ✅ Do This Instead
```swift
// Use optional binding
guard let guest = store.guests.first else {
    XCTFail("Expected guest")
    return
}

// Test both success and failure
func test_operation_success() { }
func test_operation_failure() { }

// Use mocks
mockRepository.mockResponse = expectedData

// Test public interface
XCTAssertEqual(store.guests.count, 5)
```

---

## Test File Structure

```swift
//
//  [FeatureName]Tests.swift
//  I Do BlueprintTests
//
//  Tests for [FeatureName]
//

import XCTest
@testable import I_Do_Blueprint

@MainActor // If testing stores
final class [FeatureName]Tests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: [SystemUnderTest]!
    var mockDependency: Mock[Dependency]!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        // Setup code
    }
    
    override func tearDown() async throws {
        sut = nil
        mockDependency = nil
        try await super.tearDown()
    }
    
    // MARK: - Happy Path Tests
    
    func test_operation_success() async throws {
        // Given
        
        // When
        
        // Then
    }
    
    // MARK: - Error Case Tests
    
    func test_operation_failure() async throws {
        // Given
        
        // When/Then
    }
    
    // MARK: - Edge Case Tests
    
    func test_operation_edgeCase() async throws {
        // Given
        
        // When
        
        // Then
    }
}
```

---

## Generation Checklist

Before generating tests, ensure:

- [ ] Reviewed target component code
- [ ] Identified all dependencies
- [ ] Listed all methods to test
- [ ] Defined test scenarios (happy/error/edge)
- [ ] Checked for similar existing tests
- [ ] Prepared mock data structures
- [ ] Understood expected behavior

After generating tests, verify:

- [ ] All methods have tests
- [ ] Error cases are covered
- [ ] Edge cases are handled
- [ ] Mocks are properly configured
- [ ] Tests follow naming conventions
- [ ] Tests use `@MainActor` if needed
- [ ] Tests compile without errors
- [ ] Tests pass when run

---

## Notes

[Any additional context or special considerations for this test generation]

---

**Template Version**: 1.0
**Last Used**: [Date]
