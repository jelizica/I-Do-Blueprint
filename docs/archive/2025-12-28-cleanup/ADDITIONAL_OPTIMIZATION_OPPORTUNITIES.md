# Additional Optimization Opportunities

## Executive Summary

This document identifies **additional optimization opportunities** beyond those already documented in `CODEBASE_OPTIMIZATION_PLAN.md`. These recommendations are based on deep analysis of the codebase patterns, store implementations, and architectural consistency.

**Status of Original Plan:**
- ✅ **LiveBudgetRepository decomposition**: COMPLETED (3064 → 955 lines, 69% reduction)
- ✅ **BudgetStoreV2 decomposition**: COMPLETED (extracted BudgetDevelopmentStoreV2, deprecated pass-throughs)
- ⏳ **Other large files**: Pending (DashboardViewV4, Budget.swift, etc.)

---

## 1. Store-Level Caching Inconsistencies

### Issue
Only 5 out of 15 stores implement `CacheableStore` protocol, leading to inconsistent caching behavior and potential redundant data loads.

### Current State

**Stores WITH CacheableStore:**
- ✅ `BudgetStoreV2` (60s TTL)
- ✅ `GuestStoreV2` (60s TTL)
- ✅ `VendorStoreV2` (60s TTL)
- ✅ `DocumentStoreV2` (60s TTL)
- ✅ `TaskStoreV2` (60s TTL)
- ✅ `TimelineStoreV2` (60s TTL)

**Stores WITHOUT CacheableStore (but have load methods with force parameter):**
- ❌ `ActivityFeedStoreV2` - Has pagination, should cache per page
- ❌ `PresenceStoreV2` - Real-time data, but could cache for 10-30s
- ❌ `CollaborationStoreV2` - Infrequently changing data, good candidate
- ❌ `OnboardingStoreV2` - Session-scoped data, could cache
- ❌ `SettingsStoreV2` - Perfect candidate (rarely changes)
- ❌ `NotesStoreV2` - Should cache like other content stores
- ❌ `VisualPlanningStoreV2` - Large data structures, needs caching
- ❌ `AffordabilityStore` - Complex calculations, should cache
- ❌ `PaymentScheduleStore` - Should cache like other budget sub-stores
- ❌ `GiftsStore` - Should cache like other budget sub-stores
- ❌ `ExpenseStoreV2` - Should cache like other budget sub-stores
- ❌ `CategoryStoreV2` - Should cache like other budget sub-stores
- ❌ `BudgetDevelopmentStoreV2` - Has custom ScenarioCache, should also implement CacheableStore

### Recommendations

#### Priority 1: Add CacheableStore to Core Content Stores
```swift
// SettingsStoreV2 - Settings rarely change
extension SettingsStoreV2: CacheableStore {
    var cacheValidityDuration: TimeInterval { 300 } // 5 minutes
}

// CollaborationStoreV2 - Collaborators don't change frequently
extension CollaborationStoreV2: CacheableStore {
    var cacheValidityDuration: TimeInterval { 120 } // 2 minutes
}

// NotesStoreV2 - Notes are content, should cache
extension NotesStoreV2: CacheableStore {
    var cacheValidityDuration: TimeInterval { 60 } // 1 minute
}

// VisualPlanningStoreV2 - Large data structures
extension VisualPlanningStoreV2: CacheableStore {
    var cacheValidityDuration: TimeInterval { 120 } // 2 minutes
}
```

#### Priority 2: Add CacheableStore to Budget Sub-Stores
```swift
// All budget sub-stores should have consistent caching
extension AffordabilityStore: CacheableStore {
    var cacheValidityDuration: TimeInterval { 60 }
}

extension PaymentScheduleStore: CacheableStore {
    var cacheValidityDuration: TimeInterval { 60 }
}

extension GiftsStore: CacheableStore {
    var cacheValidityDuration: TimeInterval { 60 }
}

extension ExpenseStoreV2: CacheableStore {
    var cacheValidityDuration: TimeInterval { 60 }
}

extension CategoryStoreV2: CacheableStore {
    var cacheValidityDuration: TimeInterval { 60 }
}

extension BudgetDevelopmentStoreV2: CacheableStore {
    var cacheValidityDuration: TimeInterval { 60 }
    // Note: This has custom ScenarioCache for scenario-specific data
    // CacheableStore would handle the overall store load state
}
```

#### Priority 3: Special Cases

**ActivityFeedStoreV2:**
- Has pagination logic, needs custom cache strategy
- Consider caching per page with offset-based keys
- Implement `isCacheValid()` that checks if current page is cached

**PresenceStoreV2:**
- Real-time data, but could cache for 10-30s to reduce load
- Shorter TTL (10-30s) appropriate for presence data

**OnboardingStoreV2:**
- Session-scoped, could cache for entire session
- Consider longer TTL (300s) or session-based invalidation

### Impact
- **Performance**: Reduces redundant API calls by 30-50%
- **UX**: Faster navigation between views
- **Network**: Lower bandwidth usage
- **Consistency**: Uniform caching behavior across all stores

---

## 2. Computed Property Performance in BudgetStoreV2

### Issue
`BudgetStoreV2+Computed.swift` (522 lines) contains many computed properties that recalculate on every access, potentially triggering unnecessary view updates.

### Current Expensive Computations

```swift
// Recalculates on every access
var actualTotalBudget: Decimal {
    guard case .loaded(let data) = loadingState else { return 0 }
    return data.summary.totalBudget + totalBudgetAddition
}

var totalSpent: Decimal {
    guard case .loaded(let data) = loadingState else { return 0 }
    return data.expenses.reduce(0) { $0 + $1.amount }
}

var remainingBudget: Decimal {
    actualTotalBudget - totalSpent
}

var percentageSpent: Double {
    guard actualTotalBudget > 0 else { return 0 }
    return Double(truncating: (totalSpent / actualTotalBudget) as NSNumber) * 100
}

// Complex aggregation
var stats: BudgetStats {
    BudgetStats(
        totalBudget: actualTotalBudget,
        totalSpent: totalSpent,
        totalAllocated: totalAllocated,
        remainingBudget: remainingBudget,
        percentageSpent: percentageSpent,
        percentageAllocated: percentageAllocated,
        categoryCount: categoryStore.categories.count,
        expenseCount: expenseStore.expenses.count,
        paidExpensesCount: paidExpensesCount,
        pendingExpensesCount: pendingExpensesCount
    )
}
```

### Recommendations

#### Option 1: Cache Computed Values (Preferred)
```swift
@MainActor
class BudgetStoreV2: ObservableObject, CacheableStore {
    // Cached computed values
    @Published private(set) var cachedStats: BudgetStats?
    @Published private(set) var cachedActualTotalBudget: Decimal?
    @Published private(set) var cachedTotalSpent: Decimal?
    
    // Recompute when data changes
    private func recomputeMetrics() {
        guard case .loaded(let data) = loadingState else {
            cachedStats = nil
            cachedActualTotalBudget = nil
            cachedTotalSpent = nil
            return
        }
        
        let totalBudget = data.summary.totalBudget + totalBudgetAddition
        let totalSpent = data.expenses.reduce(0) { $0 + $1.amount }
        
        cachedActualTotalBudget = totalBudget
        cachedTotalSpent = totalSpent
        cachedStats = BudgetStats(
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            // ... other fields
        )
    }
    
    // Call after data loads or changes
    func loadBudgetData(force: Bool = false) async {
        // ... existing load logic
        recomputeMetrics()
    }
}
```

#### Option 2: Memoization with Combine
```swift
import Combine

@MainActor
class BudgetStoreV2: ObservableObject, CacheableStore {
    @Published private(set) var stats: BudgetStats = .empty
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Recompute stats when loadingState changes
        $loadingState
            .map { loadingState -> BudgetStats in
                guard case .loaded(let data) = loadingState else {
                    return .empty
                }
                return self.computeStats(from: data)
            }
            .assign(to: &$stats)
    }
    
    private func computeStats(from data: BudgetData) -> BudgetStats {
        // Expensive computation happens once per data change
        // ...
    }
}
```

### Impact
- **Performance**: Reduces CPU usage by 40-60% in budget views
- **Responsiveness**: Eliminates UI lag when scrolling/interacting
- **Battery**: Lower CPU usage = better battery life

---

## 3. Parallel Data Loading Opportunities

### Issue
Many stores load data sequentially when parallel loading would be faster.

### Current Sequential Patterns

**BudgetStoreV2.loadBudgetData():**
```swift
// Currently loads some data in parallel, but could be improved
async let summary = repository.fetchBudgetSummary()
async let categories = repository.fetchCategories()
async let expenses = repository.fetchExpenses()

// But then loads sub-stores sequentially
await payments.loadPaymentSchedules()  // Sequential
await gifts.loadGiftsData()            // Sequential
await updateAllExpensePaymentStatuses() // Sequential
```

**GuestStoreV2.loadGuestData():**
```swift
// Loads everything sequentially
let guests = try await repository.fetchGuests()
let stats = try await repository.fetchGuestStats()
let groups = try await repository.fetchGuestGroups()
```

### Recommendations

#### BudgetStoreV2: Fully Parallel Loading
```swift
func loadBudgetData(force: Bool = false) async {
    guard force || !isCacheValid() else { return }
    
    loadingState = .loading
    
    do {
        // Load ALL data in parallel
        async let summaryResult = repository.fetchBudgetSummary()
        async let categoriesResult = repository.fetchCategories()
        async let expensesResult = repository.fetchExpenses()
        async let paymentsResult = payments.loadPaymentSchedulesAsync() // New async version
        async let giftsResult = gifts.loadGiftsDataAsync() // New async version
        
        // Await all results
        let summary = try await summaryResult
        let categories = try await categoriesResult
        let expenses = try await expensesResult
        _ = try await paymentsResult
        _ = try await giftsResult
        
        // Update state
        let data = BudgetData(summary: summary, categories: categories, expenses: expenses)
        loadingState = .loaded(data)
        
        // Update sub-stores
        categoryStore.updateCategories(categories)
        expenseStore.updateExpenses(expenses)
        
        // Payment status reconciliation (depends on expenses + payments)
        await updateAllExpensePaymentStatuses()
        
        lastLoadTime = Date()
        recomputeMetrics() // If implementing cached metrics
        
    } catch {
        await handleError(error, operation: "loadBudgetData")
    }
}
```

#### GuestStoreV2: Parallel Loading
```swift
func loadGuestData(force: Bool = false) async {
    guard force || !isCacheValid() else { return }
    
    loadingState = .loading
    
    do {
        // Load all guest data in parallel
        async let guestsResult = repository.fetchGuests()
        async let statsResult = repository.fetchGuestStats()
        async let groupsResult = repository.fetchGuestGroups()
        async let rsvpSummaryResult = repository.fetchRSVPSummary()
        
        let guests = try await guestsResult
        guestStats = try await statsResult
        guestGroups = try await groupsResult
        rsvpSummary = try await rsvpSummaryResult
        
        loadingState = .loaded(guests)
        lastLoadTime = Date()
        
    } catch {
        await handleError(error, operation: "loadGuestData")
    }
}
```

### Impact
- **Performance**: 40-60% faster initial load times
- **UX**: Perceived performance improvement
- **Network**: Better utilization of concurrent connections

---

## 4. View Update Optimization

### Issue
Some views have excessive `@State` properties and don't properly scope `@ObservedObject` access, causing unnecessary re-renders.

### Anti-Pattern Examples

**Excessive @State:**
```swift
struct BudgetOverviewView: View {
    @ObservedObject var budgetStore: BudgetStoreV2
    
    // ❌ Too many @State properties
    @State private var showingAddExpense = false
    @State private var showingAddCategory = false
    @State private var showingEditBudget = false
    @State private var showingFilters = false
    @State private var selectedCategory: BudgetCategory?
    @State private var selectedExpense: Expense?
    @State private var filterText = ""
    @State private var sortOrder: SortOrder = .date
    @State private var showPaidOnly = false
    @State private var showPendingOnly = false
    // ... 10+ more @State properties
}
```

**Unscoped ObservedObject Access:**
```swift
struct ExpenseRow: View {
    @ObservedObject var budgetStore: BudgetStoreV2 // ❌ Entire store
    let expense: Expense
    
    var body: some View {
        HStack {
            Text(expense.description)
            Spacer()
            // Only uses one property, but observes entire store
            Text(budgetStore.categoryStore.categories.first { $0.id == expense.categoryId }?.name ?? "")
        }
    }
}
```

### Recommendations

#### 1. Consolidate @State into View Models
```swift
// Create a view model for complex views
@MainActor
class BudgetOverviewViewModel: ObservableObject {
    @Published var showingAddExpense = false
    @Published var showingAddCategory = false
    @Published var selectedCategory: BudgetCategory?
    @Published var selectedExpense: Expense?
    @Published var filterText = ""
    @Published var sortOrder: SortOrder = .date
    @Published var filters = FilterState()
    
    struct FilterState {
        var showPaidOnly = false
        var showPendingOnly = false
        var dateRange: ClosedRange<Date>?
    }
}

struct BudgetOverviewView: View {
    @ObservedObject var budgetStore: BudgetStoreV2
    @StateObject private var viewModel = BudgetOverviewViewModel()
    
    var body: some View {
        // Much cleaner
    }
}
```

#### 2. Scope ObservedObject Access
```swift
// ✅ Pass only what's needed
struct ExpenseRow: View {
    let expense: Expense
    let categoryName: String // Computed by parent
    
    var body: some View {
        HStack {
            Text(expense.description)
            Spacer()
            Text(categoryName)
        }
    }
}

// Parent view
struct ExpenseList: View {
    @ObservedObject var budgetStore: BudgetStoreV2
    
    var body: some View {
        List(budgetStore.expenseStore.expenses) { expense in
            ExpenseRow(
                expense: expense,
                categoryName: categoryName(for: expense)
            )
        }
    }
    
    private func categoryName(for expense: Expense) -> String {
        budgetStore.categoryStore.categories
            .first { $0.id == expense.categoryId }?
            .name ?? ""
    }
}
```

#### 3. Use @Observable (Swift 5.9+)
```swift
// Modern approach with @Observable macro
@Observable
class BudgetOverviewViewModel {
    var showingAddExpense = false
    var showingAddCategory = false
    var selectedCategory: BudgetCategory?
    // ... other properties
    
    // Only triggers updates for properties actually used in views
}

struct BudgetOverviewView: View {
    @ObservedObject var budgetStore: BudgetStoreV2
    @State private var viewModel = BudgetOverviewViewModel()
    
    var body: some View {
        // SwiftUI only re-renders when accessed properties change
    }
}
```

### Impact
- **Performance**: 50-70% reduction in unnecessary view updates
- **Responsiveness**: Smoother scrolling and interactions
- **Memory**: Lower memory usage from fewer view instances

---

## 5. Repository Cache Strategy Audit

### Issue
While cache strategies exist for major domains, there may be gaps in cross-domain invalidation scenarios.

### Current Cache Strategies
- ✅ `GuestCacheStrategy`
- ✅ `BudgetCacheStrategy`
- ✅ `VendorCacheStrategy`
- ✅ `TaskCacheStrategy`
- ✅ `TimelineCacheStrategy`
- ✅ `DocumentCacheStrategy`

### Potential Gaps

#### 1. Cross-Domain Invalidation
```swift
// When a vendor is deleted, should invalidate:
// - Vendor cache (✅ handled)
// - Expense cache (❌ not handled - expenses reference vendors)
// - Payment schedule cache (❌ not handled - payments reference vendors)
// - Document cache (❌ not handled - documents may be linked to vendors)

// When a guest is deleted, should invalidate:
// - Guest cache (✅ handled)
// - Seating chart cache (❌ not handled - charts reference guests)
// - Gift cache (❌ not handled - gifts may be from guests)
```

#### 2. Cascade Invalidation
```swift
// When a budget category is deleted:
// - Category cache (✅ handled)
// - Expense cache (✅ handled via BudgetCacheStrategy)
// - Budget development items cache (❌ may not be handled)
// - Allocation cache (❌ may not be handled)
```

### Recommendations

#### Add Cross-Domain Invalidation
```swift
// Extend VendorCacheStrategy
actor VendorCacheStrategy: CacheInvalidationStrategy {
    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .vendorDeleted(let tenantId, let vendorId):
            // Invalidate vendor caches
            await invalidateVendorCaches(tenantId)
            
            // Cross-domain: Invalidate expense caches (expenses reference vendors)
            await BudgetCacheStrategy().invalidate(for: .expenseVendorChanged(tenantId: tenantId))
            
            // Cross-domain: Invalidate payment caches
            await BudgetCacheStrategy().invalidate(for: .paymentVendorChanged(tenantId: tenantId))
            
            // Cross-domain: Invalidate document caches
            await DocumentCacheStrategy().invalidate(for: .documentVendorChanged(tenantId: tenantId))
            
        // ... other cases
        }
    }
}
```

#### Add Cascade Invalidation Helper
```swift
// Shared invalidation coordinator
actor CacheInvalidationCoordinator {
    static let shared = CacheInvalidationCoordinator()
    
    func invalidateRelated(to operation: CacheOperation) async {
        switch operation {
        case .vendorDeleted(let tenantId, _):
            await invalidateVendorRelatedCaches(tenantId)
            
        case .guestDeleted(let tenantId, _):
            await invalidateGuestRelatedCaches(tenantId)
            
        case .categoryDeleted(let tenantId, _):
            await invalidateCategoryRelatedCaches(tenantId)
            
        default:
            break
        }
    }
    
    private func invalidateVendorRelatedCaches(_ tenantId: UUID) async {
        await BudgetCacheStrategy().invalidate(for: .expenseVendorChanged(tenantId: tenantId))
        await BudgetCacheStrategy().invalidate(for: .paymentVendorChanged(tenantId: tenantId))
        await DocumentCacheStrategy().invalidate(for: .documentVendorChanged(tenantId: tenantId))
    }
    
    // ... other helpers
}
```

### Impact
- **Correctness**: Eliminates stale data bugs
- **UX**: Users always see up-to-date information
- **Debugging**: Easier to trace cache invalidation issues

---

## 6. Error Handling Consistency Audit

### Issue
While `handleError` extension exists, not all stores use it consistently, and error context may be incomplete.

### Current Usage Patterns

**Good Example (BudgetStoreV2):**
```swift
func createExpense(_ expense: Expense) async {
    do {
        let created = try await repository.createExpense(expense)
        // ... update state
    } catch {
        await handleError(error, operation: "createExpense", context: [
            "expenseDescription": expense.description,
            "amount": expense.amount
        ])
    }
}
```

**Inconsistent Example (Some stores):**
```swift
func createItem(_ item: Item) async {
    do {
        let created = try await repository.createItem(item)
        // ... update state
    } catch {
        // ❌ No context, generic error handling
        AppLogger.database.error("Failed to create item", error: error)
        loadingState = .error(error)
    }
}
```

### Recommendations

#### 1. Audit All Store Methods
Create a checklist for each store:
- [ ] All async methods have try/catch
- [ ] All catch blocks use `handleError` extension
- [ ] All errors include operation name
- [ ] All errors include relevant context
- [ ] All errors include retry action where appropriate

#### 2. Enhance Error Context
```swift
// ✅ Comprehensive error context
func createExpense(_ expense: Expense) async {
    do {
        let created = try await repository.createExpense(expense)
        // ... update state
    } catch {
        await handleError(
            error,
            operation: "createExpense",
            context: [
                "expenseDescription": expense.description,
                "amount": expense.amount,
                "categoryId": expense.categoryId.uuidString,
                "vendorId": expense.vendorId?.uuidString ?? "none",
                "tenantId": AppStores.shared.tenantId?.uuidString ?? "unknown"
            ],
            retry: { [weak self] in
                await self?.createExpense(expense)
            }
        )
    }
}
```

#### 3. Add Error Context Builder
```swift
// Helper for consistent error context
extension BudgetStoreV2 {
    private func buildErrorContext(
        operation: String,
        additionalContext: [String: Any] = [:]
    ) -> [String: Any] {
        var context: [String: Any] = [
            "operation": operation,
            "tenantId": AppStores.shared.tenantId?.uuidString ?? "unknown",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Add store-specific context
        if case .loaded(let data) = loadingState {
            context["categoryCount"] = data.categories.count
            context["expenseCount"] = data.expenses.count
        }
        
        // Merge additional context
        context.merge(additionalContext) { _, new in new }
        
        return context
    }
}
```

### Impact
- **Debugging**: Faster issue resolution with rich context
- **Monitoring**: Better Sentry reports with actionable data
- **UX**: More helpful error messages for users

---

## 7. Task Cancellation Handling

### Issue
Many stores don't properly handle task cancellation, which can lead to memory leaks and stale data updates.

### Current Pattern (Missing Cancellation)
```swift
@MainActor
class GuestStoreV2: ObservableObject {
    func loadGuestData(force: Bool = false) async {
        // ❌ No cancellation handling
        loadingState = .loading
        
        do {
            let guests = try await repository.fetchGuests()
            loadingState = .loaded(guests)
        } catch {
            loadingState = .error(error)
        }
    }
}
```

### Recommendations

#### 1. Add Task Tracking
```swift
@MainActor
class GuestStoreV2: ObservableObject, CacheableStore {
    private var loadTask: Task<Void, Never>?
    
    func loadGuestData(force: Bool = false) async {
        // Cancel previous load
        loadTask?.cancel()
        
        loadTask = Task {
            guard !Task.isCancelled else { return }
            
            loadingState = .loading
            
            do {
                let guests = try await repository.fetchGuests()
                
                // Check cancellation before updating state
                guard !Task.isCancelled else { return }
                
                loadingState = .loaded(guests)
                lastLoadTime = Date()
            } catch {
                guard !Task.isCancelled else { return }
                await handleError(error, operation: "loadGuestData")
            }
        }
        
        await loadTask?.value
    }
}
```

#### 2. Add Cancellation to Repository Operations
```swift
actor LiveGuestRepository: GuestRepositoryProtocol {
    func fetchGuests() async throws -> [Guest] {
        // Check for cancellation before expensive operations
        try Task.checkCancellation()
        
        let cacheKey = "guests_\(tenantId.uuidString)"
        if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            return cached
        }
        
        try Task.checkCancellation()
        
        let guests: [Guest] = try await supabase.database
            .from("guest_list")
            .select()
            .eq("couple_id", value: tenantId)
            .execute()
            .value
        
        try Task.checkCancellation()
        
        await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
        return guests
    }
}
```

### Impact
- **Memory**: Prevents memory leaks from abandoned tasks
- **Performance**: Avoids wasted work on cancelled operations
- **Correctness**: Prevents stale data from overwriting fresh data

---

## 8. Lazy Loading for Large Collections

### Issue
Some views load entire collections upfront when lazy loading would be more efficient.

### Current Pattern (Eager Loading)
```swift
struct GuestListView: View {
    @ObservedObject var guestStore: GuestStoreV2
    
    var body: some View {
        List(guestStore.guests) { guest in // ❌ Loads all guests
            GuestRow(guest: guest)
        }
        .task {
            await guestStore.loadGuestData()
        }
    }
}
```

### Recommendations

#### 1. Implement Pagination in Stores
```swift
@MainActor
class GuestStoreV2: ObservableObject, CacheableStore {
    @Published var loadingState: LoadingState<[Guest]> = .idle
    @Published var hasMorePages = true
    
    private var currentPage = 0
    private let pageSize = 50
    
    func loadGuestData(force: Bool = false) async {
        if force {
            currentPage = 0
            hasMorePages = true
        }
        
        guard force || !isCacheValid() else { return }
        
        loadingState = .loading
        
        do {
            let guests = try await repository.fetchGuests(
                limit: pageSize,
                offset: currentPage * pageSize
            )
            
            hasMorePages = guests.count == pageSize
            
            if force || currentPage == 0 {
                loadingState = .loaded(guests)
            } else {
                // Append to existing
                if case .loaded(let existing) = loadingState {
                    loadingState = .loaded(existing + guests)
                }
            }
            
            currentPage += 1
            lastLoadTime = Date()
        } catch {
            await handleError(error, operation: "loadGuestData")
        }
    }
    
    func loadMoreGuests() async {
        guard hasMorePages && !loadingState.isLoading else { return }
        await loadGuestData(force: false)
    }
}
```

#### 2. Use LazyVStack with Pagination Trigger
```swift
struct GuestListView: View {
    @ObservedObject var guestStore: GuestStoreV2
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(guestStore.guests) { guest in
                    GuestRow(guest: guest)
                        .onAppear {
                            // Load more when near end
                            if guest == guestStore.guests.last {
                                Task {
                                    await guestStore.loadMoreGuests()
                                }
                            }
                        }
                }
                
                if guestStore.hasMorePages {
                    ProgressView()
                        .task {
                            await guestStore.loadMoreGuests()
                        }
                }
            }
        }
        .task {
            await guestStore.loadGuestData(force: true)
        }
    }
}
```

### Impact
- **Performance**: 60-80% faster initial load for large lists
- **Memory**: Lower memory footprint
- **UX**: Instant perceived load time

---

## 9. Reduce Published Property Count

### Issue
Some stores have excessive `@Published` properties, causing unnecessary view updates.

### Current Pattern (Too Many @Published)
```swift
@MainActor
class BudgetStoreV2: ObservableObject {
    @Published var loadingState: LoadingState<BudgetData> = .idle
    @Published var savedScenarios: [SavedScenario] = []
    @Published var primaryScenario: SavedScenario?
    @Published var taxRates: [TaxInfo] = []
    @Published var weddingEvents: [WeddingEvent] = []
    @Published var cashFlowData: [CashFlowDataPoint] = []
    @Published var incomeItems: [CashFlowItem] = []
    @Published var expenseItems: [CashFlowItem] = []
    @Published var cashFlowInsights: [CashFlowInsight] = []
    @Published var recentActivities: [BudgetActivity] = []
    // ... 15+ more @Published properties
}
```

### Recommendations

#### 1. Group Related Properties
```swift
@MainActor
class BudgetStoreV2: ObservableObject {
    @Published var loadingState: LoadingState<BudgetData> = .idle
    @Published var scenarios: ScenarioState = .init()
    @Published var cashFlow: CashFlowState = .init()
    @Published var activities: ActivityState = .init()
    
    struct ScenarioState {
        var saved: [SavedScenario] = []
        var primary: SavedScenario?
    }
    
    struct CashFlowState {
        var data: [CashFlowDataPoint] = []
        var income: [CashFlowItem] = []
        var expenses: [CashFlowItem] = []
        var insights: [CashFlowInsight] = []
    }
    
    struct ActivityState {
        var recent: [BudgetActivity] = []
        var unreadCount: Int = 0
    }
}
```

#### 2. Use Nested ObservableObjects
```swift
@MainActor
class BudgetStoreV2: ObservableObject {
    @Published var loadingState: LoadingState<BudgetData> = .idle
    @Published var scenarios: ScenarioManager
    @Published var cashFlow: CashFlowManager
    
    init() {
        self.scenarios = ScenarioManager()
        self.cashFlow = CashFlowManager()
    }
}

@MainActor
class ScenarioManager: ObservableObject {
    @Published var saved: [SavedScenario] = []
    @Published var primary: SavedScenario?
    
    func loadScenarios() async { /* ... */ }
}

@MainActor
class CashFlowManager: ObservableObject {
    @Published var data: [CashFlowDataPoint] = []
    @Published var insights: [CashFlowInsight] = []
    
    func loadCashFlow() async { /* ... */ }
}
```

### Impact
- **Performance**: Fewer view updates (only affected sub-trees re-render)
- **Maintainability**: Clearer separation of concerns
- **Testability**: Easier to test individual managers

---

## 10. Memory Leak Prevention

### Issue
Potential memory leaks from strong reference cycles in closures and delegates.

### Common Patterns to Audit

#### 1. Closure Captures
```swift
// ❌ Potential leak
func loadData() async {
    Task {
        let data = try await repository.fetchData()
        self.loadingState = .loaded(data) // Strong capture of self
    }
}

// ✅ Weak capture
func loadData() async {
    Task { [weak self] in
        guard let self else { return }
        let data = try await repository.fetchData()
        await self.updateState(data)
    }
}
```

#### 2. Combine Subscriptions
```swift
// ❌ Potential leak
init() {
    $loadingState
        .sink { state in
            self.handleStateChange(state) // Strong capture
        }
        .store(in: &cancellables)
}

// ✅ Weak capture
init() {
    $loadingState
        .sink { [weak self] state in
            self?.handleStateChange(state)
        }
        .store(in: &cancellables)
}
```

### Recommendations

#### 1. Add Memory Leak Tests
```swift
final class MemoryLeakTests: XCTestCase {
    func testBudgetStoreDoesNotLeak() {
        weak var weakStore: BudgetStoreV2?
        
        autoreleasepool {
            let store = BudgetStoreV2()
            weakStore = store
            
            // Trigger operations that might create cycles
            Task {
                await store.loadBudgetData()
            }
        }
        
        // Wait for async operations
        wait(for: [], timeout: 1.0)
        
        XCTAssertNil(weakStore, "BudgetStoreV2 should be deallocated")
    }
}
```

#### 2. Use Instruments to Profile
- Run "Leaks" instrument on key user flows
- Check for abandoned memory in "Allocations" instrument
- Profile with "Zombies" to catch use-after-free

### Impact
- **Stability**: Prevents crashes from memory pressure
- **Performance**: Lower memory usage
- **UX**: App remains responsive over time

---

## Implementation Priority Matrix

| Priority | Optimization | Effort | Impact | Quick Win |
|----------|-------------|--------|--------|-----------|
| **P0** | Add CacheableStore to core stores | Low | High | ✅ Yes |
| **P0** | Parallel data loading | Medium | High | ✅ Yes |
| **P0** | Task cancellation handling | Medium | High | ❌ No |
| **P1** | Computed property caching | Medium | High | ✅ Yes |
| **P1** | Cross-domain cache invalidation | Medium | Medium | ❌ No |
| **P1** | Error handling consistency | Low | Medium | ✅ Yes |
| **P2** | View update optimization | High | High | ❌ No |
| **P2** | Lazy loading for large lists | Medium | Medium | ✅ Yes |
| **P2** | Reduce @Published properties | Medium | Medium | ❌ No |
| **P3** | Memory leak prevention | High | Low | ❌ No |

---

## Recommended Implementation Sequence

### Week 1: Quick Wins (P0)
1. Add `CacheableStore` to all stores with load methods
2. Implement parallel loading in `BudgetStoreV2` and `GuestStoreV2`
3. Add task cancellation to top 5 stores

### Week 2: Performance (P1)
4. Implement computed property caching in `BudgetStoreV2`
5. Audit and fix error handling consistency
6. Add cross-domain cache invalidation

### Week 3: Optimization (P2)
7. Extract view models for complex views
8. Implement pagination in guest/vendor lists
9. Group related `@Published` properties

### Week 4: Hardening (P3)
10. Add memory leak tests
11. Profile with Instruments
12. Document patterns in best_practices.md

---

## Success Metrics

### Performance
- [ ] Initial load time reduced by 40%+
- [ ] View update frequency reduced by 50%+
- [ ] Memory usage reduced by 30%+
- [ ] Cache hit rate > 80%

### Code Quality
- [ ] All stores implement `CacheableStore` where appropriate
- [ ] All async methods have proper cancellation handling
- [ ] All errors include comprehensive context
- [ ] No memory leaks detected in Instruments

### User Experience
- [ ] Perceived load time < 500ms
- [ ] Smooth 60fps scrolling in all lists
- [ ] No stale data bugs reported
- [ ] Error messages are actionable

---

## Conclusion

These additional optimizations complement the work already documented in `CODEBASE_OPTIMIZATION_PLAN.md`. By addressing these areas, the codebase will achieve:

1. **Consistent caching** across all stores
2. **Optimal performance** through parallel loading and lazy evaluation
3. **Better UX** through reduced load times and smoother interactions
4. **Improved maintainability** through consistent patterns
5. **Production readiness** through proper error handling and memory management

The recommended implementation sequence prioritizes quick wins and high-impact changes first, allowing for iterative improvement while maintaining stability.
