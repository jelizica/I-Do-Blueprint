---
title: Domain Services Layer - Business Logic Separation
type: note
permalink: architecture/services/domain-services-layer-business-logic-separation
tags:
- architecture
- domain-services
- business-logic
- actor
- performance
---

# Domain Services Layer - Business Logic Separation

## Overview

Domain services in I Do Blueprint are actor-based classes that handle complex business logic, separating it from repositories. Services are used when operations require:
- Aggregation of multiple data sources
- Complex calculations or transformations
- Multi-step workflows with business rules
- Permission checks and role management

## All Domain Services

Located in `Domain/Services/`:

1. **BudgetAggregationService** - Budget overview aggregation and calculations
2. **BudgetAllocationService** - Expense allocation logic
3. **BudgetDevelopmentService** - Budget scenario development
4. **ExpensePaymentStatusService** - Payment status calculations
5. **CollaborationPermissionService** - Permission checks and role management
6. **CollaborationInvitationService** - Invitation workflow management

## Domain Service Pattern

All services follow this pattern:

```swift
/// Actor-based service for thread-safe business logic
actor {Feature}Service: {Feature}ServiceProtocol {
    private let repository: {Feature}RepositoryProtocol
    private nonisolated let logger = AppLogger.repository
    
    init(repository: {Feature}RepositoryProtocol) {
        self.repository = repository
    }
    
    /// Complex business logic method
    func performComplexOperation() async throws -> Result {
        let startTime = Date()
        
        // 1. Fetch multiple data sources in parallel
        async let data1 = repository.fetch1()
        async let data2 = repository.fetch2()
        
        let result1 = try await data1
        let result2 = try await data2
        
        // 2. Perform complex calculations
        let aggregated = complexCalculation(result1, result2)
        
        // 3. Record performance metrics
        let duration = Date().timeIntervalSince(startTime)
        await PerformanceMonitor.shared.recordOperation("operation", duration: duration)
        
        return aggregated
    }
}
```

## Key Characteristics

### 1. Actor-Based for Thread Safety
All services are `actor` types for safe concurrent access:
```swift
actor BudgetAggregationService { }
```

### 2. Nonisolated Loggers
Loggers use `nonisolated` for synchronous access:
```swift
private nonisolated let logger = AppLogger.repository
```

### 3. Repository Delegation
Services receive repositories via dependency injection:
```swift
init(repository: BudgetRepositoryProtocol) {
    self.repository = repository
}
```

### 4. Performance Monitoring
All operations tracked for performance:
```swift
let startTime = Date()
// ... operation ...
let duration = Date().timeIntervalSince(startTime)
await PerformanceMonitor.shared.recordOperation("name", duration: duration)
```

## Service Details

### BudgetAggregationService

**Purpose:** Aggregates budget data from multiple sources for overview screens

**Key Method:**
```swift
func fetchBudgetOverview(scenarioId: String) async throws -> [BudgetOverviewItem]
```

**Implementation Highlights:**
- Parallel data fetching using `async let`
- N+1 query prevention with bulk fetch
- Expense allocation mapping
- Gift contribution calculation
- Effective spend calculation (spent - gifts)

**Data Sources:**
1. Budget development items
2. Expenses
3. Gifts and money owed
4. Expense allocations (bulk fetched per scenario)

**Algorithm:**
1. Fetch all data sources in parallel
2. Build lookup dictionaries for O(1) access
3. Bulk fetch all allocations for scenario (avoid N+1)
4. Group allocations by budget item
5. Calculate totals and effective spend
6. Build BudgetOverviewItem array

### CollaborationPermissionService

**Purpose:** Handles permission checks and role management for multi-user collaboration

**Key Methods:**
```swift
func hasPermission(_ permission: String, coupleId: UUID) async throws -> Bool
func getCurrentUserRole(coupleId: UUID, userId: UUID) async throws -> RoleName?
func canLeaveCollaboration(coupleId: UUID, userId: UUID) async throws -> Bool
```

**Implementation Highlights:**
- RPC function calls to Supabase for permission checks
- Role-based access control (RBAC)
- Owner protection (prevent last owner from leaving)
- Active status filtering
- Performance monitoring for all operations

**Permission Check Pattern:**
```swift
struct PermissionParams: Encodable {
    let p_couple_id: UUID
    let p_permission: String
}

let result: [[String: Bool]] = try await RepositoryNetwork.withRetry {
    try await supabase
        .rpc("user_has_permission", params: params)
        .execute()
        .value
}
```

### BudgetAllocationService

**Purpose:** Handles complex expense allocation logic across budget items

**Key Features:**
- Proportional allocation calculations
- Scenario-aware allocations
- Validation rules
- Allocation constraints

### BudgetDevelopmentService

**Purpose:** Manages budget scenario development and "what-if" analysis

**Key Features:**
- Scenario creation and cloning
- Budget item management within scenarios
- Folder support for grouping items
- Event-based categorization

### ExpensePaymentStatusService

**Purpose:** Calculates payment status and progress for expenses

**Key Features:**
- Payment progress calculation
- Status determination (unpaid, partial, paid, overpaid)
- Due date tracking
- Multi-payment aggregation

### CollaborationInvitationService

**Purpose:** Manages invitation workflow for collaborators

**Key Features:**
- Invitation creation and sending
- Token generation
- Acceptance workflow
- Email/link-based invitations

## Integration with Repositories

Services are used by repositories via lazy initialization:

```swift
class LiveBudgetRepository: BudgetRepositoryProtocol {
    private lazy var aggregationService = BudgetAggregationService(repository: self)
    
    func fetchBudgetOverview(scenarioId: String) async throws -> [BudgetOverviewItem] {
        // Delegate to service
        return try await aggregationService.fetchBudgetOverview(scenarioId: scenarioId)
    }
}
```

## Performance Optimization Patterns

### 1. Parallel Data Fetching
```swift
async let items = repository.fetchItems()
async let expenses = repository.fetchExpenses()
async let gifts = repository.fetchGifts()

let allItems = try await items
let allExpenses = try await expenses
let allGifts = try await gifts
```

### 2. N+1 Query Prevention
```swift
// ✅ Bulk fetch all allocations for scenario
let allAllocations = try await repository.fetchExpenseAllocationsForScenario(scenarioId)
let allocationsByItem = Dictionary(grouping: allAllocations, by: { $0.budgetItemId })

// ❌ Would create N+1 queries
for item in items {
    let allocations = try await repository.fetchAllocations(itemId: item.id)
}
```

### 3. Dictionary Lookups for O(1) Access
```swift
let expenseById: [String: String] = Dictionary(
    uniqueKeysWithValues: expenses.map { ($0.id.uuidString.lowercased(), $0.expenseName) }
)
```

### 4. Capacity Reservation
```swift
var overview: [BudgetOverviewItem] = []
overview.reserveCapacity(items.count) // Prevent reallocation
```

## When to Use Domain Services

**Use Domain Services when:**
- Logic involves multiple data sources
- Complex calculations or transformations needed
- Business rules span multiple entities
- Permission or role checks required
- Performance monitoring needed

**Don't use Domain Services when:**
- Simple CRUD operations (use repositories directly)
- Single data source operations
- UI-specific logic (belongs in stores)

## Testing Domain Services

Services are easily testable with mock repositories:

```swift
func testBudgetOverview() async throws {
    let mockRepo = MockBudgetRepository()
    let service = BudgetAggregationService(repository: mockRepo)
    
    mockRepo.items = [.makeTest()]
    mockRepo.expenses = [.makeTest()]
    mockRepo.gifts = [.makeTest()]
    
    let overview = try await service.fetchBudgetOverview(scenarioId: "test")
    
    XCTAssertEqual(overview.count, 1)
}
```

## References
- Related Issue: I Do Blueprint-0t9 (Large service files decomposition)
- File: `Utilities/PerformanceMonitor.swift` - Performance tracking
- File: `Utilities/NetworkRetry.swift` - Network retry wrapper (RepositoryNetwork)
- File: `Core/Common/Extensions/Logger+Categories.swift` - AppLogger categories