# Domain Services Architecture

This document describes the Domain Services layer introduced in JES-210 to separate business logic from data access.

## Goals
- Keep repositories focused on CRUD, caching, tenant scoping, and network concerns
- Centralize complex business rules in services for reuse and isolated testing
- Improve maintainability and readability of budget-related code paths

## Layout
```
Domain/
├── Models/
├── Repositories/
│   ├── Live/
│   ├── Mock/
│   └── Protocols/
└── Services/
    ├── BudgetAllocationService.swift
    ├── BudgetAggregationService.swift
    └── Protocols/
        ├── BudgetAllocationServiceProtocol.swift
        └── BudgetAggregationServiceProtocol.swift
```

## Responsibilities
- BudgetAggregationService
  - Aggregates data needed by budget overview screens
  - Builds BudgetOverviewItem (spent, effectiveSpent, ExpenseLink, GiftLink)
  - Fetches base data via repository APIs only; no direct DB access
- BudgetAllocationService
  - Performs proportional allocation recalculation when
    - a budget item total changes (per-scenario)
    - an expense amount changes (single scenario or across scenarios)
  - Uses delete+reinsert semantics through repository helpers to avoid validation conflicts

## Key Repository APIs used by Services
- fetchBudgetDevelopmentItems(scenarioId:)
- fetchExpenseAllocations(scenarioId:budgetItemId:)
- fetchAllocationsForExpense(expenseId:scenarioId:)
- fetchAllocationsForExpenseAllScenarios(expenseId:)
- replaceAllocations(expenseId:scenarioId:with:)
- fetchGiftsAndOwed()
- fetchExpenses()

## Threading and Safety
- Services are declared as Swift actors; they are safe to call from concurrent contexts
- Repositories already encapsulate network calls with retry and caching; services do not add network plumbing

## Usage Examples

### Delegating from Repository (production)
```swift
// LiveBudgetRepository.swift (excerpt)
private lazy var allocationService = BudgetAllocationService(repository: self)
private lazy var aggregationService = BudgetAggregationService(repository: self)

func fetchBudgetDevelopmentItemsWithSpentAmounts(scenarioId: String) async throws -> [BudgetOverviewItem] {
  let cacheKey = "budget_overview_items_\(scenarioId)"
  if let cached: [BudgetOverviewItem] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
    return cached
  }
  let overview = try await aggregationService.fetchBudgetOverview(scenarioId: scenarioId)
  await RepositoryCache.shared.set(cacheKey, value: overview)
  return overview
}

func updateBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem {
  let result = try await /* update in DB */
  if let scenarioId = item.scenarioId {
    try await allocationService.recalculateAllocations(budgetItemId: item.id, scenarioId: scenarioId)
  }
  return result
}

func updateExpense(_ expense: Expense) async throws -> Expense {
  let result = try await /* update in DB */
  try await allocationService.recalculateExpenseAllocationsForAllScenarios(expenseId: expense.id, newAmount: expense.amount)
  return result
}
```

### Unit testing a service
```swift
// Example test sketch
let mock = MockBudgetRepository()
// seed mock.expenseAllocations, mock.budgetDevelopmentItems, mock.expenses, etc.
let service = BudgetAllocationService(repository: mock)
try await service.recalculateAllocations(budgetItemId: "item-1", scenarioId: "scenario-1")
// assert calls or inspect mock state
```

## Migration Notes
- New services should follow the same pattern: define a protocol, implement as an actor, depend only on repository protocols
- If a service needs data not available via repository protocol, add the minimal helper(s) to the protocol and Mock/Live implementations

## Diagram
```
[UI] ──> Stores ──> Repositories (CRUD, cache, network)
                     │
                     └──> Domain Services (business rules)
                               │
                               └──> Repositories (helper reads/writes)
```
