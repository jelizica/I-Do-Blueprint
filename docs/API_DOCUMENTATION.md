# API Documentation

Comprehensive reference for I Do Blueprint's internal APIs, including repository interfaces, store APIs, domain services, and utilities.

## Table of Contents

- [Repository Layer](#repository-layer)
  - [Budget Repository](#budget-repository)
  - [Guest Repository](#guest-repository)
  - [Vendor Repository](#vendor-repository)
  - [Task Repository](#task-repository)
  - [Timeline Repository](#timeline-repository)
  - [Document Repository](#document-repository)
  - [Visual Planning Repository](#visual-planning-repository)
  - [Settings Repository](#settings-repository)
  - [Collaboration Repository](#collaboration-repository)
  - [Notes Repository](#notes-repository)
  - [Onboarding Repository](#onboarding-repository)
  - [Presence Repository](#presence-repository)
  - [Activity Feed Repository](#activity-feed-repository)
- [Store Layer (State Management)](#store-layer-state-management)
- [Domain Services](#domain-services)
- [Utilities & Helpers](#utilities--helpers)
- [Database Schema](#database-schema)
- [Error Handling](#error-handling)

---

## Repository Layer

All repositories follow a consistent pattern:
- **Protocol-based**: Defined as `Sendable` protocols in `Domain/Repositories/Protocols/`
- **Live implementation**: In `Domain/Repositories/Live/` with Supabase integration
- **Mock implementation**: In `I Do BlueprintTests/Helpers/MockRepositories.swift`
- **Thread-safe**: All methods are `async` and can be called from any actor context
- **Multi-tenant**: Automatically filter by `couple_id` via Row Level Security
- **Cached**: Use `RepositoryCache` actor with TTL-based expiration
- **Resilient**: Wrap network calls in `NetworkRetry.withRetry()`

### Common Repository Patterns

```swift
// Dependency injection
@Dependency(\.guestRepository) private var repository

// Fetch with caching
let cacheKey = "guests_\(tenantId.uuidString)"
if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
    return cached
}
let guests = try await NetworkRetry.withRetry {
    try await supabase.database.from("guest_list").select().execute().value
}
await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)

// Mutations invalidate cache
await cacheStrategy.invalidate(for: .guestCreated(tenantId: tenantId))
```

---

## Budget Repository

**Protocol**: `BudgetRepositoryProtocol`
**Location**: `I Do Blueprint/Domain/Repositories/Protocols/BudgetRepositoryProtocol.swift`
**Live Implementation**: `LiveBudgetRepository`

Handles all budget-related data operations including categories, expenses, payment schedules, gifts, affordability scenarios, and budget development planning.

### Budget Summary Operations

```swift
/// Fetches the budget summary for the current couple
func fetchBudgetSummary() async throws -> BudgetSummary?
```

Returns budget totals, category breakdowns, and spending metadata.

### Category Operations

```swift
/// Fetches all budget categories
func fetchCategories() async throws -> [BudgetCategory]

/// Creates a new budget category
func createCategory(_ category: BudgetCategory) async throws -> BudgetCategory

/// Updates an existing budget category
func updateCategory(_ category: BudgetCategory) async throws -> BudgetCategory

/// Deletes a budget category
func deleteCategory(id: UUID) async throws

/// Checks dependencies before deletion
func checkCategoryDependencies(id: UUID) async throws -> CategoryDependencies

/// Batch deletes multiple categories
func batchDeleteCategories(ids: [UUID]) async throws -> BatchDeleteResult
```

**Models:**
- `BudgetCategory`: Category with allocated amount
- `CategoryDependencies`: Expense and payment counts
- `BatchDeleteResult`: Success/failure counts

### Expense Operations

```swift
/// Fetches all expenses
func fetchExpenses() async throws -> [Expense]

/// Creates a new expense
func createExpense(_ expense: Expense) async throws -> Expense

/// Updates an existing expense
func updateExpense(_ expense: Expense) async throws -> Expense

/// Deletes an expense
func deleteExpense(id: UUID) async throws

/// Fetches expenses for a specific vendor
func fetchExpensesByVendor(vendorId: Int64) async throws -> [Expense]
```

**Models:**
- `Expense`: Actual or planned cost with category link

### Payment Schedule Operations

```swift
/// Fetches all payment schedules
func fetchPaymentSchedules() async throws -> [PaymentSchedule]

/// Creates a new payment schedule
func createPaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule

/// Updates an existing payment schedule
func updatePaymentSchedule(_ schedule: PaymentSchedule) async throws -> PaymentSchedule

/// Deletes a payment schedule
func deletePaymentSchedule(id: Int64) async throws

/// Fetches payment schedules for a specific vendor
func fetchPaymentSchedulesByVendor(vendorId: Int64) async throws -> [PaymentSchedule]
```

**Models:**
- `PaymentSchedule`: Payment plan with due dates
- `PaymentPlanSummary`: Aggregated payment plan data

### Gifts and Money Owed Operations

```swift
/// Fetches all gifts and money owed
func fetchGiftsAndOwed() async throws -> [GiftOrOwed]

/// Creates a new gift or money owed item
func createGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed

/// Updates an existing gift or money owed item
func updateGiftOrOwed(_ gift: GiftOrOwed) async throws -> GiftOrOwed

/// Deletes a gift or money owed item
func deleteGiftOrOwed(id: UUID) async throws
```

**Separate Operations:**

```swift
/// Gift Received operations
func fetchGiftsReceived() async throws -> [GiftReceived]
func createGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived
func updateGiftReceived(_ gift: GiftReceived) async throws -> GiftReceived
func deleteGiftReceived(id: UUID) async throws

/// Money Owed operations
func fetchMoneyOwed() async throws -> [MoneyOwed]
func createMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed
func updateMoneyOwed(_ money: MoneyOwed) async throws -> MoneyOwed
func deleteMoneyOwed(id: UUID) async throws
```

### Budget Development Operations

```swift
/// Fetches all budget development scenarios
func fetchBudgetDevelopmentScenarios() async throws -> [SavedScenario]

/// Fetches budget development items for a specific scenario
func fetchBudgetDevelopmentItems(scenarioId: String?) async throws -> [BudgetItem]

/// Fetches budget development items with spent amounts
func fetchBudgetDevelopmentItemsWithSpentAmounts(scenarioId: String) async throws -> [BudgetOverviewItem]

/// Creates a new budget development scenario
func createBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario

/// Updates an existing budget development scenario
func updateBudgetDevelopmentScenario(_ scenario: SavedScenario) async throws -> SavedScenario

/// CRUD for budget items
func createBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem
func updateBudgetDevelopmentItem(_ item: BudgetItem) async throws -> BudgetItem
func deleteBudgetDevelopmentItem(id: String) async throws
```

**Hierarchical Folder Operations:**

```swift
/// Creates a new budget folder
func createFolder(name: String, scenarioId: String, parentFolderId: String?, displayOrder: Int) async throws -> BudgetItem

/// Moves an item or folder to a different parent (prevents circular moves)
func moveItemToFolder(itemId: String, targetFolderId: String?, displayOrder: Int) async throws

/// Updates display order for multiple items (drag-and-drop)
func updateDisplayOrder(items: [(itemId: String, displayOrder: Int)]) async throws

/// Toggles folder expansion state (validates isFolder)
func toggleFolderExpansion(folderId: String, isExpanded: Bool) async throws

/// Fetches budget items with hierarchical structure (flat array, hierarchy in properties)
func fetchBudgetItemsHierarchical(scenarioId: String) async throws -> [BudgetItem]

/// Calculates folder totals using database function
func calculateFolderTotals(folderId: String) async throws -> FolderTotals

/// Validates if an item can be moved to a target folder
func canMoveItem(itemId: String, toFolder targetFolderId: String?) async throws -> Bool

/// Deletes a folder and optionally moves contents to parent
func deleteFolder(folderId: String, deleteContents: Bool) async throws
```

### Affordability Calculator Operations

```swift
/// Fetches all affordability scenarios
func fetchAffordabilityScenarios() async throws -> [AffordabilityScenario]

/// Saves an affordability scenario (create or update)
func saveAffordabilityScenario(_ scenario: AffordabilityScenario) async throws -> AffordabilityScenario

/// Deletes an affordability scenario
func deleteAffordabilityScenario(id: UUID) async throws

/// Fetches contributions for a specific scenario
func fetchAffordabilityContributions(scenarioId: UUID) async throws -> [ContributionItem]

/// Saves a contribution item (create or update)
func saveAffordabilityContribution(_ contribution: ContributionItem) async throws -> ContributionItem

/// Deletes a contribution from a scenario
func deleteAffordabilityContribution(id: UUID, scenarioId: UUID) async throws

/// Links existing gifts to an affordability scenario
func linkGiftsToScenario(giftIds: [UUID], scenarioId: UUID) async throws

/// Unlinks a gift from an affordability scenario
func unlinkGiftFromScenario(giftId: UUID, scenarioId: UUID) async throws
```

### Expense Allocation Operations

```swift
/// Fetches expense allocations for a specific scenario and budget item
func fetchExpenseAllocations(scenarioId: String, budgetItemId: String) async throws -> [ExpenseAllocation]

/// Fetches all expense allocations for a specific scenario (bulk fetch)
func fetchExpenseAllocationsForScenario(scenarioId: String) async throws -> [ExpenseAllocation]

/// Creates a new expense allocation
func createExpenseAllocation(_ allocation: ExpenseAllocation) async throws -> ExpenseAllocation

/// Fetches all allocations for a given expense within a scenario
func fetchAllocationsForExpense(expenseId: UUID, scenarioId: String) async throws -> [ExpenseAllocation]

/// Fetches all allocations for a given expense across all scenarios
func fetchAllocationsForExpenseAllScenarios(expenseId: UUID) async throws -> [ExpenseAllocation]

/// Atomically replaces all allocations for an expense within a scenario
func replaceAllocations(expenseId: UUID, scenarioId: String, with newAllocations: [ExpenseAllocation]) async throws
```

### Tax Rate & Wedding Event Operations

```swift
/// Tax Rate operations
func fetchTaxRates() async throws -> [TaxInfo]
func createTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo
func updateTaxRate(_ taxInfo: TaxInfo) async throws -> TaxInfo
func deleteTaxRate(id: Int64) async throws

/// Wedding Event operations
func fetchWeddingEvents() async throws -> [WeddingEvent]
func createWeddingEvent(_ event: WeddingEvent) async throws -> WeddingEvent
func updateWeddingEvent(_ event: WeddingEvent) async throws -> WeddingEvent
func deleteWeddingEvent(id: String) async throws
```

### Composite Save Operations

```swift
/// Saves a budget development scenario and its items atomically via RPC
func saveBudgetScenarioWithItems(_ scenario: SavedScenario, items: [BudgetItem]) async throws -> (scenarioId: String, insertedItems: Int)

/// Links a gift to a budget development item
func linkGiftToBudgetItem(giftId: UUID, budgetItemId: String) async throws

/// Fetches the primary budget development scenario
func fetchPrimaryBudgetScenario() async throws -> BudgetDevelopmentScenario?
```

---

## Guest Repository

**Protocol**: `GuestRepositoryProtocol`
**Location**: `I Do Blueprint/Domain/Repositories/Protocols/GuestRepositoryProtocol.swift`
**Live Implementation**: `LiveGuestRepository`

Handles guest list management including RSVP tracking, guest statistics, and batch imports.

### Fetch Operations

```swift
/// Fetches all guests for the current couple (sorted by creation date)
func fetchGuests() async throws -> [Guest]

/// Fetches guest statistics
/// - Total count, attending, pending, declined, RSVP response rate
func fetchGuestStats() async throws -> GuestStats
```

**Models:**
- `Guest`: Guest record with RSVP status, meal preferences, contact info
- `GuestStats`: Aggregate statistics

### Create, Update, Delete Operations

```swift
/// Creates a new guest record
func createGuest(_ guest: Guest) async throws -> Guest

/// Updates an existing guest record
func updateGuest(_ guest: Guest) async throws -> Guest

/// Deletes a guest record
func deleteGuest(id: UUID) async throws
```

### Search Operations

```swift
/// Searches guests by query string
/// Searches: full name, email, phone (case-insensitive)
func searchGuests(query: String) async throws -> [Guest]
```

### Batch Import Operations

```swift
/// Imports multiple guests in a single batch operation
/// - Uses single database transaction
/// - Optimized for large CSV imports
func importGuests(_ guests: [Guest]) async throws -> [Guest]
```

---

## Vendor Repository

**Protocol**: `VendorRepositoryProtocol`
**Location**: `I Do Blueprint/Domain/Repositories/Protocols/VendorRepositoryProtocol.swift`
**Live Implementation**: `LiveVendorRepository`

Handles vendor management including reviews, payments, contracts, and bulk imports.

### Fetch Operations

```swift
/// Fetches all vendors for the current couple
func fetchVendors() async throws -> [Vendor]

/// Fetches vendor statistics
/// - Total count, booked count, average rating, total cost
func fetchVendorStats() async throws -> VendorStats
```

### CRUD Operations

```swift
/// Creates a new vendor record
func createVendor(_ vendor: Vendor) async throws -> Vendor

/// Updates an existing vendor record
func updateVendor(_ vendor: Vendor) async throws -> Vendor

/// Deletes a vendor record
func deleteVendor(id: Int64) async throws
```

### Extended Vendor Data Operations

```swift
/// Fetches reviews for a specific vendor
func fetchVendorReviews(vendorId: Int64) async throws -> [VendorReview]

/// Fetches review statistics for a specific vendor
func fetchVendorReviewStats(vendorId: Int64) async throws -> VendorReviewStats?

/// Fetches payment summary for a specific vendor
func fetchVendorPaymentSummary(vendorId: Int64) async throws -> VendorPaymentSummary?

/// Fetches contract summary for a specific vendor
func fetchVendorContractSummary(vendorId: Int64) async throws -> VendorContract?

/// Fetches complete vendor details (all data combined)
func fetchVendorDetails(id: Int64) async throws -> VendorDetails
```

**Models:**
- `Vendor`: Basic vendor record
- `VendorReview`: Review with rating and comments
- `VendorReviewStats`: Aggregate review data
- `VendorPaymentSummary`: Total, paid, remaining amounts
- `VendorContract`: Contract status and terms
- `VendorDetails`: Complete vendor information

### Vendor Types

```swift
/// Fetches all vendor types (system-wide reference data)
func fetchVendorTypes() async throws -> [VendorType]
```

### Bulk Import Operations

```swift
/// Imports multiple vendors from CSV data
/// - Single transaction
/// - Duplicate detection by name/email
/// - Cache invalidation after import
func importVendors(_ vendors: [VendorImportData]) async throws -> [Vendor]
```

---

## Task Repository

**Protocol**: `TaskRepositoryProtocol`
**Location**: `I Do Blueprint/Domain/Repositories/Protocols/TaskRepositoryProtocol.swift`

Handles wedding planning task management with checklist features.

### Operations

```swift
func fetchTasks() async throws -> [WeddingTask]
func createTask(_ task: WeddingTask) async throws -> WeddingTask
func updateTask(_ task: WeddingTask) async throws -> WeddingTask
func deleteTask(id: UUID) async throws
func toggleTaskCompletion(id: UUID) async throws
```

---

## Timeline Repository

**Protocol**: `TimelineRepositoryProtocol`
**Location**: `I Do Blueprint/Domain/Repositories/Protocols/TimelineRepositoryProtocol.swift`

Handles wedding day timeline and schedule management.

### Operations

```swift
func fetchTimelineEvents() async throws -> [TimelineEvent]
func createTimelineEvent(_ event: TimelineEvent) async throws -> TimelineEvent
func updateTimelineEvent(_ event: TimelineEvent) async throws -> TimelineEvent
func deleteTimelineEvent(id: UUID) async throws
func reorderTimelineEvents(eventIds: [UUID]) async throws
```

---

## Document Repository

**Protocol**: `DocumentRepositoryProtocol`
**Location**: `I Do Blueprint/Domain/Repositories/Protocols/DocumentRepositoryProtocol.swift`

Handles document storage and organization.

### Operations

```swift
func fetchDocuments() async throws -> [Document]
func uploadDocument(_ document: Document, data: Data) async throws -> Document
func downloadDocument(id: UUID) async throws -> Data
func deleteDocument(id: UUID) async throws
func organizeIntoFolder(documentId: UUID, folderId: UUID?) async throws
```

---

## Visual Planning Repository

**Protocol**: `VisualPlanningRepositoryProtocol`
**Location**: `I Do Blueprint/Domain/Repositories/Protocols/VisualPlanningRepositoryProtocol.swift`

Handles mood boards, seating charts, and floor plans.

### Operations

```swift
func fetchMoodBoards() async throws -> [MoodBoard]
func fetchSeatingCharts() async throws -> [SeatingChart]
func createMoodBoard(_ board: MoodBoard) async throws -> MoodBoard
func updateSeatingChart(_ chart: SeatingChart) async throws -> SeatingChart
```

---

## Settings Repository

**Protocol**: `SettingsRepositoryProtocol`
**Location**: `I Do Blueprint/Domain/Repositories/Protocols/SettingsRepositoryProtocol.swift`

Handles user preferences and application settings.

### Operations

```swift
func fetchSettings() async throws -> AppSettings
func updateSettings(_ settings: AppSettings) async throws -> AppSettings
func resetSettings() async throws -> AppSettings
```

---

## Collaboration Repository

**Protocol**: `CollaborationRepositoryProtocol`
**Location**: `I Do Blueprint/Domain/Repositories/Protocols/CollaborationRepositoryProtocol.swift`

Handles real-time collaboration features.

### Operations

```swift
func fetchCollaborators() async throws -> [Collaborator]
func inviteCollaborator(email: String, role: CollaboratorRole) async throws
func updateCollaboratorRole(id: UUID, role: CollaboratorRole) async throws
func removeCollaborator(id: UUID) async throws
```

---

## Notes Repository

**Protocol**: `NotesRepositoryProtocol`
**Location**: `I Do Blueprint/Domain/Repositories/Protocols/NotesRepositoryProtocol.swift`

Handles note-taking and annotations.

### Operations

```swift
func fetchNotes() async throws -> [Note]
func createNote(_ note: Note) async throws -> Note
func updateNote(_ note: Note) async throws -> Note
func deleteNote(id: UUID) async throws
```

---

## Onboarding Repository

**Protocol**: `OnboardingRepositoryProtocol`
**Location**: `I Do Blueprint/Domain/Repositories/Protocols/OnboardingRepositoryProtocol.swift`

Handles new user onboarding flow.

### Operations

```swift
func fetchOnboardingStatus() async throws -> OnboardingStatus
func completeOnboardingStep(step: OnboardingStep) async throws
func skipOnboarding() async throws
```

---

## Presence Repository

**Protocol**: `PresenceRepositoryProtocol`
**Location**: `I Do Blueprint/Domain/Repositories/Protocols/PresenceRepositoryProtocol.swift`

Handles user presence and activity status.

### Operations

```swift
func updatePresence(status: PresenceStatus) async throws
func fetchActiveUsers() async throws -> [UserPresence]
```

---

## Activity Feed Repository

**Protocol**: `ActivityFeedRepositoryProtocol`
**Location**: `I Do Blueprint/Domain/Repositories/Protocols/ActivityFeedRepositoryProtocol.swift`

Handles activity feed and notifications.

### Operations

```swift
func fetchActivityFeed(limit: Int) async throws -> [ActivityItem]
func markAsRead(activityId: UUID) async throws
func clearActivityFeed() async throws
```

---

## Store Layer (State Management)

Stores are `@MainActor` `ObservableObject` classes that manage UI state and coordinate between views and repositories.

### BudgetStoreV2 (Composition Root)

**Location**: `I Do Blueprint/Services/Stores/BudgetStoreV2.swift`

Composition root that owns 6 specialized sub-stores:

```swift
@MainActor
final class BudgetStoreV2: ObservableObject {
    // Sub-stores (access directly from views)
    let affordability: AffordabilityStore
    let payments: PaymentScheduleStore
    let gifts: GiftsStore
    let categoryStore: CategoryStoreV2
    let expenseStore: ExpenseStoreV2
    let development: BudgetDevelopmentStoreV2

    // Published state
    @Published var loadingState: LoadingState<BudgetSummary> = .idle
    @Published var budgetSummary: BudgetSummary?

    // Lifecycle
    func loadBudgetData() async
    func refreshData() async
}
```

**Sub-Store Access Pattern:**

```swift
// ✅ CORRECT - Access sub-stores directly
await budgetStore.categoryStore.addCategory(category)
await budgetStore.payments.addPayment(schedule)
await budgetStore.development.createScenario(scenario)

// ❌ WRONG - Do not create delegation methods in BudgetStoreV2
await budgetStore.addCategory(category)
```

### Common Store Patterns

All V2 stores follow these patterns:

#### LoadingState Pattern

```swift
@Published var loadingState: LoadingState<Data> = .idle

func load() async {
    loadingState = .loading
    do {
        let data = try await repository.fetch()
        loadingState = .loaded(data)
    } catch {
        loadingState = .error(error)
        await handleError(error, operation: "load")
    }
}
```

#### Error Handling Pattern

```swift
func createItem(_ item: Item) async {
    do {
        let created = try await repository.createItem(item)
        items.append(created)
    } catch {
        await handleError(error, operation: "createItem", context: [
            "itemName": item.name
        ]) { [weak self] in
            await self?.createItem(item) // Retry closure
        }
    }
}
```

#### Cache Warming Pattern

```swift
protocol CacheableStore: ObservableObject {
    func warmCache() async
}

extension BudgetStoreV2: CacheableStore {
    func warmCache() async {
        // Pre-load critical data
        async let _ = repository.fetchCategories()
        async let _ = repository.fetchExpenses()
    }
}
```

---

## Domain Services

Domain Services are actors that handle complex business logic. They keep repositories focused on CRUD and caching.

### BudgetAggregationService

**Location**: `I Do Blueprint/Domain/Services/BudgetAggregationService.swift`

```swift
actor BudgetAggregationService {
    /// Aggregates data for budget overview screens
    func fetchBudgetOverview(scenarioId: String) async throws -> [BudgetOverviewItem] {
        // Fetch multiple sources in parallel
        async let items = repository.fetchBudgetDevelopmentItems(scenarioId: scenarioId)
        async let expenses = repository.fetchExpenses()
        async let gifts = repository.fetchGiftsAndOwed()

        // Complex aggregation logic
        return buildOverviewItems(items: try await items, expenses: try await expenses, gifts: try await gifts)
    }
}
```

### BudgetAllocationService

**Location**: `I Do Blueprint/Domain/Services/BudgetAllocationService.swift`

```swift
actor BudgetAllocationService {
    /// Recalculates proportional allocations for budget items
    func recalculateAllocations(for scenarioId: String) async throws -> [BudgetItem] {
        // Complex allocation logic
    }
}
```

---

## Utilities & Helpers

### DateFormatting

**Location**: `I Do Blueprint/Utilities/DateFormatting.swift`

Timezone-aware date handling utility.

```swift
struct DateFormatting {
    /// Get user's configured timezone from settings
    static func userTimeZone(from settings: AppSettings) -> TimeZone

    /// Display dates (uses user's timezone)
    static func formatDateMedium(_ date: Date, timezone: TimeZone) -> String
    static func formatRelativeDate(_ date: Date, timezone: TimeZone) -> String

    /// Database dates (always UTC)
    static func formatForDatabase(_ date: Date) -> String
    static func parseDateFromDatabase(_ dateString: String) -> Date?

    /// Calculate days between dates (timezone-aware)
    static func daysBetween(from: Date, to: Date, in timezone: TimeZone) -> Int
}
```

**Critical**: Always use `DateFormatting` for display and database operations. Never use `TimeZone.current`.

### NetworkRetry

**Location**: `I Do Blueprint/Utilities/NetworkRetry.swift`

Network resilience utility with exponential backoff.

```swift
struct NetworkRetry {
    /// Wraps network operations with retry logic
    static func withRetry<T>(
        maxAttempts: Int = 3,
        operation: () async throws -> T
    ) async throws -> T {
        // Exponential backoff retry logic
    }
}
```

**Usage:**

```swift
let guests = try await NetworkRetry.withRetry {
    try await supabase.database.from("guest_list").select().execute().value
}
```

### RepositoryCache

**Location**: `I Do Blueprint/Utilities/RepositoryCache.swift`

Thread-safe actor-based caching.

```swift
actor RepositoryCache {
    static let shared = RepositoryCache()

    /// Get cached value if not expired
    func get<T>(_ key: String, maxAge: TimeInterval) -> T?

    /// Set cached value with TTL
    func set<T>(_ key: String, value: T, ttl: TimeInterval)

    /// Remove cached value
    func remove(_ key: String)

    /// Clear all caches
    func clearAll()
}
```

### AppLogger

**Location**: `I Do Blueprint/Utilities/AppLogger.swift`

Category-specific logging.

```swift
struct AppLogger {
    static let database = Logger(subsystem: "com.idoblueprin.app", category: "database")
    static let network = Logger(subsystem: "com.idoblueprin.app", category: "network")
    static let ui = Logger(subsystem: "com.idoblueprin.app", category: "ui")
    static let cache = Logger(subsystem: "com.idoblueprin.app", category: "cache")
}

// Usage
private let logger = AppLogger.database
logger.info("Fetching guests")
logger.error("Failed to fetch guests", error: error)
```

### ValidationHelpers

**Location**: `I Do Blueprint/Utilities/ValidationHelpers.swift`

Input validation utilities.

```swift
struct ValidationHelpers {
    static func isValidEmail(_ email: String) -> Bool
    static func isValidPhoneNumber(_ phone: String) -> Bool
    static func sanitizeInput(_ input: String) -> String
}
```

---

## Database Schema

High-level overview of Supabase tables (all include `couple_id` for multi-tenancy).

### Budget Tables

- `budget_summary`: Overall budget totals and metadata
- `budget_categories`: Spending categories with allocated amounts
- `expenses`: Actual or planned costs
- `payment_schedules`: Payment plans with due dates
- `gifts_and_owed`: Gifts received and money owed
- `gifts_received`: Gift tracking
- `money_owed`: Money owed tracking
- `budget_development_scenarios`: Budget planning scenarios
- `budget_development_items`: Budget line items
- `affordability_scenarios`: Affordability calculator scenarios
- `affordability_contributions`: Contribution items
- `expense_allocations`: Expense-to-budget-item allocations
- `tax_rates`: Tax information
- `wedding_events`: Wedding event details

### Guest Tables

- `guest_list`: Guest records with RSVP status
- `guest_groups`: Guest groupings
- `guest_meal_preferences`: Dietary restrictions and preferences

### Vendor Tables

- `vendors`: Vendor records
- `vendor_types`: Reference data for vendor categories
- `vendor_reviews`: Vendor reviews and ratings
- `vendor_contracts`: Contract information
- `vendor_payments`: Payment tracking

### Other Tables

- `wedding_tasks`: Task checklist
- `timeline_events`: Wedding day schedule
- `documents`: Document storage metadata
- `mood_boards`: Visual planning boards
- `seating_charts`: Seating arrangements
- `notes`: User notes
- `settings`: User preferences
- `collaborators`: Collaboration and sharing
- `activity_feed`: Activity notifications
- `user_presence`: Real-time presence

### Row Level Security (RLS)

All multi-tenant tables have RLS policies:

```sql
CREATE POLICY "couples_manage_own_data"
  ON table_name
  FOR ALL
  USING (couple_id = get_user_couple_id())
  WITH CHECK (couple_id = get_user_couple_id());
```

This ensures users can only access their own couple's data.

---

## Error Handling

### AppError

**Location**: `I Do Blueprint/Core/Errors/AppError.swift`

Centralized error types:

```swift
enum AppError: Error {
    case network(NetworkError)
    case database(DatabaseError)
    case validation(ValidationError)
    case authentication(AuthError)
    case notFound(String)
    case unauthorized
    case unknown(Error)
}
```

### ErrorHandler

**Location**: `I Do Blueprint/Core/Errors/ErrorHandler.swift`

Centralized error handling with Sentry integration.

```swift
struct ErrorHandler {
    static func handle(_ error: Error, context: [String: Any] = [:])
    static func captureException(_ error: Error, context: [String: Any] = [:])
}
```

### StoreErrorHandling Extension

**Location**: `I Do Blueprint/Services/Stores/StoreErrorHandling.swift`

Consistent error handling for all stores.

```swift
extension ObservableObject {
    func handleError(
        _ error: Error,
        operation: String,
        context: [String: Any] = [:],
        retry: (() async -> Void)? = nil
    ) async {
        // Logs error, captures to Sentry, shows user-facing message
    }
}
```

**Usage:**

```swift
catch {
    await handleError(error, operation: "createGuest", context: [
        "guestName": guest.fullName
    ]) { [weak self] in
        await self?.createGuest(guest) // Optional retry
    }
}
```

---

## API Conventions

### Naming Conventions

- **Fetch operations**: `fetch*()` - e.g., `fetchGuests()`
- **Create operations**: `create*()` - e.g., `createGuest()`
- **Update operations**: `update*()` - e.g., `updateGuest()`
- **Delete operations**: `delete*()` - e.g., `deleteGuest()`
- **Search operations**: `search*()` - e.g., `searchGuests()`
- **Batch operations**: `import*()`, `batch*()` - e.g., `importGuests()`, `batchDeleteCategories()`

### UUID Handling

**CRITICAL**: Pass UUIDs directly to Supabase queries, never convert to string.

```swift
// ✅ CORRECT
.eq("couple_id", value: tenantId) // UUID type

// ❌ WRONG - Causes case mismatch (Swift uppercase vs Postgres lowercase)
.eq("couple_id", value: tenantId.uuidString)
```

Only convert UUIDs to strings for:
- Cache keys: `"guests_\(tenantId.uuidString)"`
- Logging: `logger.info("Loading guests for \(tenantId.uuidString)")`

### Async/Await

All repository methods are `async throws`:
- Use `await` for asynchronous calls
- Use `try await` for throwing async calls
- Never use completion handlers

### Thread Safety

- Repositories: `Sendable` protocol, can be called from any actor
- Stores: `@MainActor`, always run on main thread
- Domain Services: `actor`, thread-safe by default
- Cache: `actor RepositoryCache`, thread-safe

---

## Testing

### Mocking Repositories

```swift
@MainActor
final class StoreTests: XCTestCase {
    var mockRepository: MockGuestRepository!
    var store: GuestStoreV2!

    override func setUp() async throws {
        mockRepository = MockGuestRepository()
        store = await withDependencies {
            $0.guestRepository = mockRepository
        } operation: {
            GuestStoreV2()
        }
    }

    func test_loadGuests_success() async throws {
        // Given
        mockRepository.guests = [.makeTest()]

        // When
        await store.loadGuests()

        // Then
        XCTAssertEqual(store.guests.count, 1)
    }
}
```

### Test Data Builders

```swift
extension Guest {
    static func makeTest(
        fullName: String = "John Doe",
        email: String = "john@example.com",
        rsvpStatus: RSVPStatus = .pending
    ) -> Guest {
        Guest(
            id: UUID(),
            fullName: fullName,
            email: email,
            rsvpStatus: rsvpStatus,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
```

---

## See Also

- **Architecture**: See `CLAUDE.md` for complete architecture documentation
- **FAQ**: See `docs/FAQ.md` for common questions and troubleshooting
- **Glossary**: See `docs/GLOSSARY.md` for term definitions
- **MCP Tools**: See `docs/mcp_tools_info.md` for MCP server documentation
- **Workflow**: See `docs/BASIC-MEMORY-AND-BEADS-GUIDE.md` for development workflow
- **Quick Start**: See `docs/QUICK_START_GUIDE.md` for getting started

---

*Last Updated: 2025-12-29*
