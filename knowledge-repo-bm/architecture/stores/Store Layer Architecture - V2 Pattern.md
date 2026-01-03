---
title: Store Layer Architecture - V2 Pattern
type: note
permalink: architecture/stores/store-layer-architecture-v2-pattern
tags:
- architecture
- stores
- v2-pattern
- composition
- dependency-injection
---

# Store Layer Architecture - V2 Pattern

## Overview

All stores in I Do Blueprint follow the "V2" naming convention, representing the new architecture using repository pattern and dependency injection. Stores are `@MainActor` classes that inherit from `ObservableObject`.

## Core Store Pattern

```swift
@MainActor
class {Feature}StoreV2: ObservableObject, CacheableStore {
    @Published var loadingState: LoadingState<DataType> = .idle
    @Published var showSuccessToast = false
    @Published var successMessage = ""
    
    @Dependency(\.{feature}Repository) var repository
    
    // Cache management
    var lastLoadTime: Date?
    let cacheValidityDuration: TimeInterval = 600
}
```

## All V2 Stores in the Application

### Main Domain Stores
1. **BudgetStoreV2** - Budget management with composition pattern (6 sub-stores)
2. **GuestStoreV2** - Guest list and RSVP management
3. **VendorStoreV2** - Vendor directory and contracts
4. **TaskStoreV2** - Wedding task and checklist management
5. **DocumentStoreV2** - Document storage with composition pattern (3 sub-stores)
6. **CollaborationStoreV2** - Multi-user collaboration and permissions
7. **NotesStoreV2** - Notes and reminders
8. **OnboardingStoreV2** - User onboarding flow
9. **VisualPlanningStoreV2** - Mood boards, color palettes, seating charts
10. **TimelineStoreV2** - Timeline and milestone management

### Budget Sub-Stores (Composition Pattern)
BudgetStoreV2 uses composition with 6 specialized sub-stores:
- **AffordabilityStore** - Budget scenarios and affordability calculations
- **PaymentScheduleStore** - Payment plans and schedules
- **GiftsStore** - Gift tracking and money owed
- **CategoryStoreV2** - Budget category management
- **ExpenseStoreV2** - Expense tracking and allocation
- **BudgetDevelopmentStoreV2** - Budget scenario development

### Document Sub-Stores (Composition Pattern)
DocumentStoreV2 uses composition with 3 specialized sub-stores:
- **DocumentUploadStore** - File upload operations
- **DocumentFilterStore** - Search and filtering
- **DocumentBatchStore** - Batch operations

## Key Architectural Principles

### 1. Store Composition Pattern
BudgetStoreV2 demonstrates the composition root pattern:
```swift
@MainActor
class BudgetStoreV2: ObservableObject, CacheableStore {
    // Sub-stores are public for direct access
    public var affordability: AffordabilityStore
    public var payments: PaymentScheduleStore
    public var gifts: GiftsStore
    public var categoryStore: CategoryStoreV2
    public var expenseStore: ExpenseStoreV2
    public var development: BudgetDevelopmentStoreV2
}
```

**CRITICAL:** Views MUST access sub-stores directly:
```swift
// ✅ CORRECT
await budgetStore.categoryStore.addCategory(category)
await budgetStore.payments.addPayment(schedule)

// ❌ WRONG - Do not create delegation methods
await budgetStore.addCategory(category)
```

### 2. Dependency Injection
All stores use the `@Dependency` macro for repository access:
```swift
@Dependency(\.guestRepository) var repository
```

### 3. LoadingState Pattern
Stores use `LoadingState<T>` enum for async operations:
```swift
@Published var loadingState: LoadingState<[Guest]> = .idle

// States: .idle, .loading, .loaded(T), .error(Error)
```

### 4. CacheableStore Protocol
Stores implementing `CacheableStore` manage their own cache:
```swift
var lastLoadTime: Date?
let cacheValidityDuration: TimeInterval = 600
```

### 5. Error Handling Standardization
**Status:** Nearly complete (Issue: I Do Blueprint-aip - CLOSED)

All stores use the `handleError` extension for consistent error handling:
```swift
do {
    let data = try await repository.fetch()
    loadingState = .loaded(data)
} catch {
    await handleError(error, operation: "fetch", context: [...]) { [weak self] in
        await self?.fetch() // Retry closure
    }
}
```

**Completed:** All stores except OnboardingStoreV2 (which was just standardized)

## Store Access Pattern - CRITICAL

**NEVER create store instances in views**. Always use `AppStores` singleton:

```swift
// ✅ CORRECT - Environment access (preferred)
struct SettingsView: View {
    @Environment(\.appStores) private var appStores
    private var store: SettingsStoreV2 { appStores.settings }
}

// ✅ CORRECT - Direct environment store
struct BudgetView: View {
    @Environment(\.budgetStore) private var store
}

// ❌ WRONG - Creates duplicate instances, memory explosion
struct SettingsView: View {
    @StateObject private var store = SettingsStoreV2()
}
```

Available environment stores:
- `@Environment(\.appStores)` - Access all stores
- `@Environment(\.budgetStore)`, `@Environment(\.guestStore)`, etc.

## Notable Features

### Guest List Versioning
GuestStoreV2 uses a version token for explicit re-renders:
```swift
@Published private(set) var guestListVersion: Int = 0
```

### Task Filtering
TaskStoreV2 includes built-in filtering:
```swift
@Published var filterStatus: TaskStatus?
@Published var filterPriority: WeddingTaskPriority?
@Published var searchQuery = ""
@Published var sortOption: TaskSortOption = .dueDate
```

### Collaboration Roles
CollaborationStoreV2 tracks current user permissions:
```swift
@Published private(set) var currentUserRole: RoleName?
@Published private(set) var currentUserCollaborator: Collaborator?
```

## References
- Related Issue: I Do Blueprint-aip (Error handling standardization)
- Related Issue: I Do Blueprint-0wo (MockBudgetRepository reduction)
- File: Core/Common/Common/AppStores.swift (Store registry)
- File: Core/Common/Common/DependencyValues.swift (Dependency registration)