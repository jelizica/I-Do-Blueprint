# I Do Blueprint - Testing Practices

## Test Organization

### Directory Structure
```
I Do BlueprintTests/
├── Accessibility/               # WCAG compliance tests
│   └── ColorAccessibilityTests.swift
├── Core/                        # Core infrastructure tests
├── Domain/
│   └── Repositories/           # Repository tests (if needed)
├── Services/
│   └── Stores/                 # Store tests (primary test focus)
│       ├── BudgetStoreV2Tests.swift
│       ├── GuestStoreV2Tests.swift
│       └── VendorStoreV2Tests.swift
├── Helpers/
│   ├── MockRepositories.swift  # All mock implementations
│   └── ModelBuilders.swift     # Test data factories
├── Integration/                # Integration tests
├── Performance/                # Performance benchmarks
└── Utilities/                  # Utility tests

I Do BlueprintUITests/
├── BudgetFlowUITests.swift     # Budget feature UI flows
├── DashboardFlowUITests.swift  # Dashboard UI flows
├── GuestFlowUITests.swift      # Guest feature UI flows
└── VendorFlowUITests.swift     # Vendor feature UI flows
```

## Testing Philosophy

### Unit Test Principles
1. **Mock repositories** - All stores tested with mock implementations
2. **Test data builders** - Use `.makeTest()` factory methods
3. **MainActor tests** - Store tests use `@MainActor` annotation
4. **Dependency injection** - Use `withDependencies` for mocks
5. **Isolated tests** - Each test is independent
6. **Fast execution** - Unit tests run in <5 seconds

### Test Coverage Goals
- **Stores**: 80%+ coverage (critical business logic)
- **Repositories**: 60%+ coverage (data access layer)
- **Models**: 70%+ coverage (business rules)
- **Views**: UI tests for critical flows

## Unit Test Pattern (Stores)

### Test Structure
```swift
@MainActor
final class GuestStoreV2Tests: XCTestCase {
    var mockRepository: MockGuestRepository!
    var store: GuestStoreV2!
    
    // Setup before each test
    override func setUp() async throws {
        mockRepository = MockGuestRepository()
        store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }
    }
    
    // Cleanup after each test
    override func tearDown() async throws {
        mockRepository = nil
        store = nil
    }
    
    // MARK: - Success Cases
    
    func test_loadGuests_success() async throws {
        // Given: Arrange test data
        mockRepository.guests = [.makeTest(name: "John Doe")]
        
        // When: Execute action
        await store.loadGuests()
        
        // Then: Assert results
        XCTAssertEqual(store.guests.count, 1)
        XCTAssertEqual(store.guests.first?.fullName, "John Doe")
        XCTAssertFalse(store.loadingState.isLoading)
    }
    
    // MARK: - Error Cases
    
    func test_loadGuests_error() async throws {
        // Given
        mockRepository.shouldThrowError = true
        
        // When
        await store.loadGuests()
        
        // Then
        XCTAssertTrue(store.guests.isEmpty)
        if case .error = store.loadingState {
            // Expected error state
        } else {
            XCTFail("Expected error state")
        }
    }
    
    // MARK: - Edge Cases
    
    func test_loadGuests_emptyList() async throws {
        // Given
        mockRepository.guests = []
        
        // When
        await store.loadGuests()
        
        // Then
        XCTAssertTrue(store.guests.isEmpty)
        if case .loaded = store.loadingState {
            // Expected loaded state with empty data
        } else {
            XCTFail("Expected loaded state")
        }
    }
}
```

## Mock Repository Pattern

### Mock Implementation
```swift
class MockGuestRepository: GuestRepositoryProtocol {
    // Test data
    var guests: [Guest] = []
    var shouldThrowError = false
    var errorToThrow: Error = GuestError.fetchFailed(underlying: TestError.mockError)
    
    // Track method calls
    var fetchGuestsCallCount = 0
    var createGuestCallCount = 0
    
    func fetchGuests() async throws -> [Guest] {
        fetchGuestsCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return guests
    }
    
    func createGuest(_ guest: Guest) async throws -> Guest {
        createGuestCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        guests.append(guest)
        return guest
    }
    
    // Reset for next test
    func reset() {
        guests = []
        shouldThrowError = false
        fetchGuestsCallCount = 0
        createGuestCallCount = 0
    }
}
```

## Test Data Builders

### Model Extensions for Testing
```swift
extension Guest {
    static func makeTest(
        id: UUID = UUID(),
        name: String = "Test Guest",
        email: String = "test@example.com",
        rsvpStatus: RSVPStatus = .pending,
        coupleId: UUID = UUID()
    ) -> Guest {
        Guest(
            id: id,
            fullName: name,
            email: email,
            rsvpStatus: rsvpStatus,
            coupleId: coupleId,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

extension BudgetCategory {
    static func makeTest(
        id: UUID = UUID(),
        name: String = "Test Category",
        budgetedAmount: Decimal = 1000,
        spent: Decimal = 500
    ) -> BudgetCategory {
        BudgetCategory(
            id: id,
            categoryName: name,
            budgetedAmount: budgetedAmount,
            actualSpent: spent,
            coupleId: UUID(),
            createdAt: Date()
        )
    }
}
```

## UI Testing Pattern

### UI Test Structure
```swift
final class GuestFlowUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    func test_createGuestFlow() throws {
        // Navigate to guests
        app.buttons["Guests"].tap()
        
        // Tap add button
        app.buttons["Add Guest"].tap()
        
        // Fill form
        let nameField = app.textFields["Full Name"]
        nameField.tap()
        nameField.typeText("Jane Smith")
        
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("jane@example.com")
        
        // Save
        app.buttons["Save"].tap()
        
        // Verify guest appears in list
        XCTAssertTrue(app.staticTexts["Jane Smith"].exists)
    }
}
```

## Test Naming Conventions

### Test Files
- **Unit tests**: `{FeatureName}Tests.swift`
- **UI tests**: `{FeatureName}UITests.swift`
- **Integration**: `{Feature}IntegrationTests.swift`

### Test Classes
```swift
final class GuestStoreV2Tests: XCTestCase { }
```

### Test Methods
```swift
func test_{scenario}_{expectedOutcome}()
func test_loadGuests_success()
func test_createGuest_error()
func test_updateGuest_optimisticUpdate()
```

## Accessibility Testing

### Color Contrast Tests
```swift
final class ColorAccessibilityTests: XCTestCase {
    func test_allColors_meetWCAG_AA_standards() {
        let colors: [(name: String, foreground: Color, background: Color)] = [
            ("Primary text on background", AppColors.textPrimary, AppColors.background),
            ("Secondary text on background", AppColors.textSecondary, AppColors.background),
            ("Button text on primary", AppColors.buttonText, AppColors.primary)
        ]
        
        for colorPair in colors {
            let ratio = calculateContrastRatio(
                foreground: colorPair.foreground,
                background: colorPair.background
            )
            
            XCTAssertGreaterThanOrEqual(
                ratio,
                4.5,
                "\(colorPair.name) fails WCAG AA (ratio: \(ratio))"
            )
        }
    }
}
```

## Performance Testing

### Performance Tests
```swift
func test_loadGuests_performance() {
    // Measure performance
    measure {
        let expectation = expectation(description: "Load guests")
        
        Task {
            await store.loadGuests()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
```

## Test Execution

### Run All Tests
```bash
# Command line
xcodebuild test -project "I Do Blueprint.xcodeproj" -scheme "I Do Blueprint" -destination 'platform=macOS'

# Xcode
⌘U
```

### Run Specific Test
```bash
# Single test class
xcodebuild test -only-testing:I\ Do\ BlueprintTests/GuestStoreV2Tests

# Single test method
xcodebuild test -only-testing:I\ Do\ BlueprintTests/GuestStoreV2Tests/test_loadGuests_success
```

### Continuous Testing
- Enable "Test on Save" in Xcode for rapid feedback
- Use `⌃⌥⌘G` to run last test again

## Best Practices

### ✅ Do's
1. Test one thing per test
2. Use descriptive test names
3. Use Given-When-Then structure
4. Mock external dependencies
5. Test error cases
6. Test edge cases (empty, nil, boundary values)
7. Use test data builders
8. Keep tests fast (<100ms per test)
9. Make tests independent
10. Clean up in tearDown

### ❌ Don'ts
1. Don't test private methods directly
2. Don't use real network calls
3. Don't depend on test execution order
4. Don't share state between tests
5. Don't skip tests (fix or remove)
6. Don't test framework code
7. Don't use sleep() for timing
8. Don't hardcode test data
9. Don't test implementation details
10. Don't write flaky tests

## Test Coverage

### View Coverage
```bash
# Generate coverage report in Xcode
# Product → Test (⌘U) with code coverage enabled
# View: Editor → Show Code Coverage
```

### Coverage Goals
- **Critical paths**: 90%+ (auth, payment, data persistence)
- **Business logic**: 80%+ (stores, repositories)
- **UI components**: 60%+ (via UI tests)
- **Utilities**: 70%+
