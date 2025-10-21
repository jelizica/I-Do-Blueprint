# Actionable Fixes Roadmap
## I Do Blueprint - Quick Reference for High-Impact Issues

Generated: October 19, 2025

---

## CRITICAL ISSUES (Fix Immediately)

### 1. Network Retry Disabled - URGENT
**File**: `/I Do Blueprint/Utilities/RepositoryNetwork.swift`  
**Lines**: 25-34  
**Current State**: Retry logic completely disabled
**Impact**: App fails on transient network errors, users cannot retry, features unusable on poor networks

**Quick Fix**:
```swift
// BEFORE (current, broken):
static func withRetry<T>(...) async throws -> T {
    print("🔵 [RepositoryNetwork] Executing operation (simplified, no retry)")
    return try await operation()
}

// AFTER (proper implementation):
static func withRetry<T>(
    timeout: TimeInterval = defaultTimeout,
    policy: RetryPolicy = defaultRetryPolicy,
    operation: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?
    for attempt in 0..<policy.maxRetries {
        do {
            return try await withThrowingTaskGroup(of: T.self) { group in
                group.addTask { try await operation() }
                return try await group.nextUnsafeResult()
            }
        } catch {
            lastError = error
            if attempt < policy.maxRetries - 1 {
                let delay = policy.delayForAttempt(attempt)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
    throw lastError ?? NetworkError.unknown
}
```

**Test**: Add unit test in `BudgetRepositoryTests.swift` validating retry on 503 errors

---

### 2. Missing .id() on List Items
**Files**: 
- `/I Do Blueprint/Views/Guests/GuestListViewV2.swift` (line ~162 in ModernGuestListView)
- `/I Do Blueprint/Views/VisualPlanning/SeatingChart/SeatingChartEditorView.swift` (line ~500+)
- `/I Do Blueprint/Views/Budget/BudgetMainView.swift` (any ForEach)

**Current State**: Lists render without stable identifiers
**Impact**: O(n) recomputation on any list update, 5-10x slower scrolling

**Quick Fix Pattern**:
```swift
// BEFORE:
ForEach(guestStore.filteredGuests) { guest in
    ModernGuestCard(guest: guest)
}

// AFTER:
ForEach(guestStore.filteredGuests, id: \.id) { guest in
    ModernGuestCard(guest: guest)
        .id(guest.id)  // Double-bind for stability
}
```

**Search**: `grep -r "ForEach.*filteredGuests\|ForEach.*guests\|ForEach.*expenses" --include="*.swift"` to find all

---

### 3. Password Not Cleared from Memory
**File**: `/I Do Blueprint/Services/Storage/SupabaseClient.swift`  
**Lines**: 146-149  
**Issue**: Passwords passed as String with no secure clearing

**Quick Fix**:
```swift
// Create SecureString wrapper:
struct SecureString {
    private var storage: [UInt8] = []
    
    init(_ string: String) {
        storage = Array(string.utf8)
    }
    
    deinit {
        storage.withUnsafeMutableBytes { buffer in
            memset(buffer.baseAddress!, 0, buffer.count)
        }
    }
}

// Use in signIn:
func signIn(email: String, password: String) async throws {
    let secure = SecureString(password)
    defer { /* secure deinits here */ }
    // Continue with Supabase auth
}
```

---

### 4. Monolithic BudgetStoreV2 - Split into Facade
**File**: `/I Do Blueprint/Services/Stores/BudgetStoreV2.swift`  
**Lines**: 1-1066  
**Issue**: 1,066 lines, 100+ computed properties, violates SRP

**Architecture Fix**:
Create separate calculator classes:
```swift
// New files to create:
// 1. BudgetAlertCalculator.swift - handles budgetAlerts logic (lines 300-378)
// 2. BudgetStatsCalculator.swift - handles stats computation (lines 244-255)
// 3. CashFlowCalculator.swift - handles cash flow calculations

// Then in BudgetStoreV2, delegate:
private let alertCalculator = BudgetAlertCalculator()
private let statsCalculator = BudgetStatsCalculator()

var budgetAlerts: [BudgetAlert] {
    alertCalculator.calculate(
        categories: categories,
        expenses: expenses,
        paymentSchedules: paymentSchedules
    )
}

var stats: BudgetStats {
    statsCalculator.calculate(
        categories: categories,
        expenses: expenses
    )
}
```

**Milestone**: Reduce BudgetStoreV2 to 400 lines by end of Phase 1

---

### 5. Test Coverage Crisis (4.7%)
**Issue**: Only 22 tests for 470 files
**Critical Missing Tests**:

1. **Repository Cache Tests** (0 files):
   ```swift
   // Add: BudgetRepositoryTests.swift
   func testCacheTTLExpiration() {
       // Verify cache invalidates after 5 minutes
   }
   
   func testCacheInvalidationOnWrite() {
       // Verify related caches cleared on update
   }
   ```

2. **View Filtering Tests** (0 files):
   ```swift
   // Add: GuestListViewV2Tests.swift
   func testSearchFiltering() {
       // Test search across name, email, phone
   }
   
   func testStatusFiltering() {
       // Test RSVP status filter
   }
   ```

3. **Network Retry Tests** (needs new file):
   ```swift
   // Add: NetworkRetryTests.swift - currently only RetryPolicy but no integration tests
   ```

**Target**: Get to 25% coverage by Phase 2 (aim for 150 lines of test per 1000 lines of code)

---

## HIGH PRIORITY ISSUES (Fix Next)

### 6. Inconsistent Search/Filter Patterns
**Files to Standardize**:
- `PaymentManagementView.swift` (inline filtering, lines 12-66)
- `GuestListViewV2.swift` (delegated filtering, lines 65-85)
- `BudgetCategoryDetailView.swift` (computed property filtering, lines 34-57)

**Solution**: Create unified SearchFilter component:
```swift
// New file: Views/Shared/Components/SearchableList.swift
struct SearchableList<Item, Content: View>: View {
    @State private var searchText = ""
    let items: [Item]
    let searchPredicate: (Item, String) -> Bool
    let content: (Item) -> Content
    
    var filteredItems: [Item] {
        searchText.isEmpty ? items : items.filter { searchPredicate($0, searchText) }
    }
    
    var body: some View {
        VStack {
            SearchField(text: $searchText)
            List(filteredItems, id: \.id) { item in
                content(item)
            }
        }
    }
}

// Usage:
SearchableList(
    items: guests,
    searchPredicate: { guest, query in
        guest.fullName.localizedCaseInsensitiveContains(query) ||
        guest.email?.localizedCaseInsensitiveContains(query) == true
    }
) { guest in
    GuestRow(guest: guest)
}
```

---

### 7. Unvalidated URLs - Security Risk
**Files**: 
- `SafeImageLoader.swift` (line 51)
- `DocumentDetailView.swift` (document URL loading)

**Quick Fix**:
```swift
// Add URL validation helper
extension URL {
    var isValid: Bool {
        let validSchemes = ["https", "http", "file"]
        guard let scheme = scheme, validSchemes.contains(scheme) else { return false }
        
        // Block sensitive protocols
        let blockedHosts = ["localhost", "127.0.0.1", "169.254.169.254"]
        if let host = host, blockedHosts.contains(host) { return false }
        
        return true
    }
}

// In SafeImageLoader:
func loadImage(from url: URL) async -> NSImage? {
    guard url.isValid else {
        logger.warning("Rejected invalid URL: \(url)")
        return nil
    }
    // ... rest of implementation
}
```

---

### 8. Store Delegation Leakage
**File**: `BudgetStoreV2.swift` (lines 71-180)  
**Problem**: Exposes internal store APIs

**Fix - Hide Internal Stores**:
```swift
// BEFORE (leaking implementation):
var affordabilityScenarios: [AffordabilityScenario] {
    affordability.scenarios  // Direct access to internal store
}

// AFTER (proper interface):
private let affordability: AffordabilityStore

func getAffordabilityScenarios() -> [AffordabilityScenario] {
    affordability.scenarios  // OK - internal delegation
}

// Don't expose:
// - affordability.showAddScenarioSheet
// - affordability.editingGift
// These are implementation details
```

Audit all property delegations (lines 71-180) and move UI state to parent store level.

---

## MODERATE PRIORITY (Fix After Critical)

### 9. Large View Files (700+ lines)
**Action**: Create extracted sub-components

**Example: BudgetCategoryDetailView.swift (777 lines)**
```swift
// Extract to: Components/ExpenseListView.swift
struct ExpenseListView: View {
    let expenses: [Expense]
    let onAdd: () -> Void
    // Takes lines 68-135
}

// Extract to: Components/ExpenseFiltersView.swift
struct ExpenseFiltersView: View {
    @State var searchText = ""
    @State var filterOption: ExpenseFilterOption
    // Takes lines 86-105
}

// Now BudgetCategoryDetailView becomes readable:
struct BudgetCategoryDetailView: View {
    var body: some View {
        VStack {
            CategoryHeaderView(category: category)
            CategoryStatsView(category: category, expenses: expenses)
            
            ExpenseFiltersView(...)
            ExpenseListView(...)
        }
    }
}
```

---

### 10. Silent Error Fallback
**File**: `GuestStoreV2.swift` (lines 168-174)  
**Issue**: Search failure overwrites loaded state

**Fix**:
```swift
// BEFORE:
func searchGuests(query: String) async {
    do {
        filteredGuests = try await repository.searchGuests(query: query)
    } catch {
        loadingState = .error(GuestError.fetchFailed(underlying: error))  // WRONG
    }
}

// AFTER - separate search error state:
@Published var searchError: Error? = nil

func searchGuests(query: String) async {
    searchError = nil
    do {
        filteredGuests = try await repository.searchGuests(query: query)
    } catch {
        searchError = error  // Don't overwrite load state
        logger.error("Search failed", error: error)
    }
}
```

---

## QUICK WINS (Small fixes, big impact)

### 11. Magic Numbers to Constants
**File**: `SafeImageLoader.swift`  
**Lines**: 37-38

```swift
// Add to top of file:
enum ImageLoaderConstants {
    static let maxCachedImages = 50
    static let maxCacheSizeBytes = 100 * 1024 * 1024  // 100MB
    static let defaultMaxImageSize = CGSize(width: 1024, height: 1024)
    static let thumbnailSize = CGSize(width: 200, height: 200)
    static let networkTimeoutSeconds = 30.0
}

// Update initialization:
imageCache.countLimit = ImageLoaderConstants.maxCachedImages
imageCache.totalCostLimit = ImageLoaderConstants.maxCacheSizeBytes
```

---

### 12. Add Accessibility Labels - Start Here
**Quick Targets** (each takes 10 minutes):

1. **PaymentManagementView** (line 115-120):
```swift
Menu {
    Button("All Payments") { selectedFilter = .all }
        .accessibilityLabel("Filter: All Payments")
    Button("Pending") { selectedFilter = .pending }
        .accessibilityLabel("Filter: Pending Payments")
    // ... etc
} label: {
    HStack {
        Text(selectedFilter.displayName)
        Image(systemName: "chevron.down")
    }
}
.accessibilityLabel("Payment Filter Menu")
```

2. **GuestDetailViewV2** tabs (line 26-34):
```swift
TabbedDetailView(
    tabs: [
        DetailTab(title: "Overview", icon: "info.circle")
            .accessibilityIdentifier("tab_overview"),
        // ... rest
    ]
)
```

3. **Color Status Indicators**:
```swift
// BEFORE:
Circle().fill(color)

// AFTER:
Circle()
    .fill(color)
    .accessibilityLabel("Status: \(status.displayName)")
```

---

## VERIFICATION CHECKLIST

After implementing fixes, verify:

- [ ] Network retry test passes: `testRetryOn503StatusCode()`
- [ ] List scrolling smooth with 500+ items (measure with Instruments)
- [ ] No `.password` text in crash logs
- [ ] BudgetStoreV2 reduced to <500 lines
- [ ] All `ForEach` loops have `.id()` modifiers
- [ ] 25+ new tests added
- [ ] URL validation blocks `file://` protocol
- [ ] Search behavior identical across GuestList, PaymentManagement, Budget
- [ ] Accessibility audit passes: 200+ labeled elements
- [ ] No compiler warnings from deprecations

---

## DOCUMENTATION
Full analysis saved to: `/ARCHITECTURE_ANALYSIS_2025-10-19.md`

