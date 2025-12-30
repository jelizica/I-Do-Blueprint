# Codebase Optimization Plan

## Overview
This document outlines optimization opportunities for the "I Do Blueprint" SwiftUI macOS app, based on analysis of large files (>300 lines), codebase patterns, and SwiftUI performance best practices. The plan prioritizes quick wins, medium refactors, and deep architectural changes to improve maintainability, performance, and scalability.

## Large File Analysis & Decomposition Points

### 1. LiveBudgetRepository.swift (3064 lines → 955 lines) ✅ COMPLETED
**Issues**: Massive repository with all budget operations. Complex aggregation logic mixed with data access, making the single implementation hard to read and maintain.

**Decomposition Points (without changing the public repository boundary)**:
- **Keep a single BudgetRepositoryProtocol / LiveBudgetRepository pair**: Do not introduce additional public repositories (e.g., ExpenseRepository, PaymentRepository). All existing call sites expect `budgetRepository` as the single entry point.
- **Extract internal data sources / helpers** inside the budget domain, each responsible for a cluster of methods:
  - ✅ **COMPLETED**: `BudgetCategoryDataSource` – category CRUD, dependency checks, batch delete (~290 lines extracted)
  - ✅ **COMPLETED**: `ExpenseDataSource` – expense CRUD, vendor-specific fetches, rollback support (~260 lines extracted)
  - ✅ **COMPLETED**: `PaymentScheduleDataSource` – payment schedules and payment plan summaries (~280 lines extracted)
  - ✅ **COMPLETED**: `GiftsAndOwedDataSource` – gifts, gifts_received, money_owed (~450 lines extracted)
  - ✅ **COMPLETED**: `AffordabilityDataSource` – affordability scenarios, contributions, gift links (~450 lines extracted)
  - ✅ **COMPLETED**: `BudgetDevelopmentDataSource` – budget development scenarios/items, allocations, folders, composite saves (~1,000 lines extracted)
- **Move Aggregation and complex rules to Domain Services**: Delegate cross-entity calculations (e.g., `fetchBudgetDevelopmentItemsWithSpentAmounts`) to existing services like `BudgetAggregationService` and `BudgetAllocationService`.
- **Extract Common Patterns**: Centralize common Supabase + caching + error-handling patterns in small internal helpers or base functions used by the internal data sources.
- **Target**: ✅ **ACHIEVED** - Reduced `LiveBudgetRepository.swift` to a thin façade (955 lines, 69% reduction from original 3064 lines)

**Progress**:
- ✅ **Phase 1 Complete**: Extracted `BudgetCategoryDataSource` (6 methods, ~290 lines)
  - Created: `/I Do Blueprint/Domain/Repositories/Live/Internal/BudgetCategoryDataSource.swift`
  - Methods: `fetchCategories`, `createCategory`, `updateCategory`, `deleteCategory`, `checkCategoryDependencies`, `batchDeleteCategories`
  - Features: Actor-based, caching, in-flight request coalescing, cache strategy integration

- ✅ **Phase 2 Complete**: Extracted `ExpenseDataSource` (5 methods + 2 helpers, ~260 lines)
  - Created: `/I Do Blueprint/Domain/Repositories/Live/Internal/ExpenseDataSource.swift`
  - Methods: `fetchExpenses`, `createExpense`, `updateExpense`, `deleteExpense`, `fetchExpensesByVendor`
  - Helpers: `fetchPreviousExpense`, `rollbackExpense` (for allocation recalculation failures)
  - Features: Actor-based, caching, in-flight request coalescing, vendor name joins, rollback support

- ✅ **Phase 3 Complete**: Extracted `PaymentScheduleDataSource` (5 methods, ~280 lines)
  - Created: `/I Do Blueprint/Domain/Repositories/Live/Internal/PaymentScheduleDataSource.swift`
  - Methods: `fetchPaymentSchedules`, `createPaymentSchedule`, `updatePaymentSchedule`, `deletePaymentSchedule`, `fetchPaymentSchedulesByVendor`
  - Features: Actor-based, caching, validation/normalization, payment type constraints, vendor-specific caching

- ✅ **Phase 4 Complete**: Extracted `GiftsAndOwedDataSource` (12 methods, ~450 lines)
  - Created: `/I Do Blueprint/Domain/Repositories/Live/Internal/GiftsAndOwedDataSource.swift`
  - Methods: 
    - Gifts and Owed: `fetchGiftsAndOwed`, `createGiftOrOwed`, `updateGiftOrOwed`, `deleteGiftOrOwed`
    - Gifts Received: `fetchGiftsReceived`, `createGiftReceived`, `updateGiftReceived`, `deleteGiftReceived`
    - Money Owed: `fetchMoneyOwed`, `createMoneyOwed`, `updateMoneyOwed`, `deleteMoneyOwed`
  - Features: Actor-based, tenant-scoped caching, scenario linking, Sentry integration, comprehensive logging
  - Delegation: All 12 methods in `LiveBudgetRepository` now delegate to this data source

- ✅ **Phase 5 Complete**: Extracted `AffordabilityDataSource` (8 methods, ~450 lines)
  - Created: `/I Do Blueprint/Domain/Repositories/Live/Internal/AffordabilityDataSource.swift`
  - Methods:
    - Affordability Scenarios: `fetchAffordabilityScenarios`, `saveAffordabilityScenario`, `deleteAffordabilityScenario`
    - Affordability Contributions: `fetchAffordabilityContributions`, `saveAffordabilityContribution`, `deleteAffordabilityContribution`
    - Gift Linking: `linkGiftsToScenario`, `unlinkGiftFromScenario`
  - Features: Actor-based, in-flight request coalescing, 5-min cache TTL, direct cache invalidation, Sentry integration
  - Delegation: All 8 methods in `LiveBudgetRepository` now delegate to this data source

- ✅ **Phase 6 Complete**: Extracted `BudgetDevelopmentDataSource` (17 methods, ~1,000 lines)
  - Created: `/I Do Blueprint/Domain/Repositories/Live/Internal/BudgetDevelopmentDataSource.swift`
  - Methods:
    - Budget Development Scenarios: `fetchBudgetDevelopmentScenarios`, `createBudgetDevelopmentScenario`, `updateBudgetDevelopmentScenario`, `fetchPrimaryBudgetScenario`
    - Budget Development Items: `fetchBudgetDevelopmentItems`, `fetchBudgetItemsHierarchical`, `createBudgetDevelopmentItem`, `updateBudgetDevelopmentItem`, `deleteBudgetDevelopmentItem`, `rollbackBudgetDevelopmentItem`, `invalidateCachesAfterUpdate`
    - Expense Allocations: `fetchExpenseAllocations`, `fetchExpenseAllocationsForScenario`, `createExpenseAllocation`, `fetchAllocationsForExpense`, `fetchAllocationsForExpenseAllScenarios`, `replaceAllocations`
    - Gift Linking: `linkGiftToBudgetItem`
    - Composite Saves: `saveBudgetScenarioWithItems`
    - Folder Operations: `createFolder`, `moveItemToFolder`, `updateDisplayOrder`, `toggleFolderExpansion`, `calculateFolderTotals`, `canMoveItem`, `deleteFolder`
  - Features: Actor-based, in-flight request coalescing, comprehensive caching (1-5 min TTL), rollback support, Sentry integration, batch operations
  - Delegation: All 17 methods in `LiveBudgetRepository` now delegate to this data source

- **Final Status**: ✅ **COMPLETED** - Extracted ~2,730 lines across 6 data sources
- **Result**: `LiveBudgetRepository.swift` reduced from 3,064 lines to 955 lines (69% reduction)
- **Build Status**: ✅ All changes compile successfully
- **Architecture**: LiveBudgetRepository is now a thin façade that delegates to specialized data sources while maintaining the single public repository interface

**Quick Win**: ✅ COMPLETED - Successfully decomposed massive repository into maintainable, focused data sources.

### 2. BudgetStoreV2.swift (approx. 3.9k lines across main file, extensions, and sub-stores) ✅ FULLY COMPLETED

> **Audience:** This section is written so that an AI (or a new engineer) can understand *why* the budget store is structured the way it is, *what* must not be broken, and *exactly how* to decompose or extend it without re‑introducing redundant routing or violating our architecture rules.

---

#### 2.0 Snapshot of the Current State (FINAL - December 28, 2025)

**✅ ALL OPTIMIZATION WORK COMPLETE**

Files involved (current verified line counts):

- `Services/Stores/BudgetStoreV2.swift` (**482 lines** - down from 721, 33% reduction)
  - Root budget store, `@MainActor`, `ObservableObject`, `CacheableStore`.
  - Composes sub-stores: `AffordabilityStore`, `PaymentScheduleStore`, `GiftsStore`, `ExpenseStoreV2`, `CategoryStoreV2`, `BudgetDevelopmentStoreV2`.
  - Owns `loadingState: LoadingState<BudgetData>`, `savedScenarios`, `primaryScenario`, `weddingEvents`, `taxRates`, etc.
  - Contains: load/refresh/reset logic, settings change handling, wedding event CRUD.
  - ✅ **COMPLETED**: All 48 deprecated pass-through methods **REMOVED** (not just deprecated).
  - ✅ **COMPLETED**: All call sites migrated to use sub-stores directly.

- `Services/Stores/BudgetStoreV2+Computed.swift` (**545 lines**)
  - Large group of computed properties for:
    - Root metrics (budget totals, stats, alerts).
    - Affordability metrics.
    - Gifts and payments metrics.
    - Convenience wrappers around sub-stores (e.g. `categories`, `expenses`, `paymentSchedules`).
  - ✅ **COMPLETED**: Low-value mirrors (`categories`, `expenses`) removed; key metrics now read from `loadingState`/sub-stores.
  - ⏳ **OPTIONAL**: Split into focused extension files (future enhancement for readability).

- ✅ **DELETED**: `Services/Stores/BudgetStoreV2+Development.swift` (~180 lines)
  - All functionality moved to `BudgetDevelopmentStoreV2`.
  - File removed after migrating all call sites.

- `Services/Stores/BudgetStoreV2+PaymentStatus.swift` (**188 lines**)
  - Uses `ExpensePaymentStatusService` to reconcile expense payment status from payment schedules.
  - Updates repository and in-memory `loadingState`.
  - ✅ **KEPT**: Already follows best practices (orchestration only, logic in domain service).

- `Services/Stores/Budget/AffordabilityStore.swift` (**522 lines**)
- `Services/Stores/Budget/CategoryStoreV2.swift` (**372 lines**)
- `Services/Stores/Budget/ExpenseStoreV2.swift` (**264 lines**)
- `Services/Stores/Budget/GiftsStore.swift` (**274 lines**)
- `Services/Stores/Budget/PaymentScheduleStore.swift` (**703 lines**)
- ✅ **CREATED**: `Services/Stores/Budget/BudgetDevelopmentStoreV2.swift` (**479 lines**)
  - Extracted all scenario and folder operations from root store.
  - Includes `ScenarioCache` actor for store-level caching.
  - Manages budget development items, scenarios, allocations, and folder hierarchy.

**Remaining optional enhancement:**
- `+Computed` could be split into domain-specific extensions for improved organization (not required).

**Non-negotiables:**
- Keep **one** `BudgetStoreV2` as the root budget entry in `AppStores` and `Environment`. Do **not** create alternative budget root stores.
- Keep our **repository boundary** intact (`BudgetRepositoryProtocol` + `LiveBudgetRepository`). Stores must not talk to Supabase directly.
- Maintain existing **load/refresh semantics**, error handling (`ErrorHandler`, `AppLogger`, `SentryService`), and caching patterns (`CacheableStore`, `RepositoryCache`).

---

### 2.1 Role of BudgetStoreV2 in the Architecture

`BudgetStoreV2` is the **composition root** for the budget domain in the UI layer.

Responsibilities:

1. **Composition & Wiring**
   - Owns instances of feature-specific budget stores:
     - `affordability: AffordabilityStore`
     - `payments: PaymentScheduleStore`
     - `gifts: GiftsStore`
     - `expenseStore: ExpenseStoreV2`
     - `categoryStore: CategoryStoreV2`
     - `development: BudgetDevelopmentStoreV2`
   - Forwards `objectWillChange` from sub-stores to itself so SwiftUI updates correctly when nested state changes.

2. **Root Loading & Caching**
   - `loadBudgetData(force:)`:
     - Uses `@Dependency(\.budgetRepository)` to fetch:
       - `BudgetSummary`
       - Categories
       - Expenses
     - Updates `loadingState` (`LoadingState<BudgetData>`) and `lastLoadTime`.
     - Populates sub-stores (e.g. `categoryStore.updateCategories(categoriesResult)`).
     - Calls `payments.loadPaymentSchedules()`, `gifts.loadGiftsData()`, and `updateAllExpensePaymentStatuses()`.
     - Records performance metrics via `PerformanceMonitor`.
   - Implements `CacheableStore` and uses `isCacheValid()` to avoid redundant loads.

3. **Cross-Feature Orchestration**
   - Coordinates operations that inherently span multiple concerns, for example:
     - `loadBudgetData(force:)` (summary + categories + expenses + payments + gifts + payment status reconciliation).
     - `batchDeleteCategories(ids:)` (category deletion + full budget reload).

4. **Secondary Domains**
   - Owns `weddingEvents` and provides CRUD via the repository.

Non-responsibilities (should live elsewhere):

- Fine-grained CRUD for **single features** (categories only, expenses only, gifts only, affordability only) → these belong in their sub-stores.
- UI-specific derivations and string formatting → should go into view models or thin helper types.

**Key design rule for AI:** When adding new behavior:
- Ask: "Does this touch **multiple feature domains** (e.g. categories + expenses + payments) or global orchestration?"
  - **Yes** → put into `BudgetStoreV2` (or a new, clearly named extension file).
  - **No, it's scoped to a single feature** → put into the appropriate sub-store under `Services/Stores/Budget`.

---

### 2.2 Pass-Through APIs: ✅ ALL REMOVED

Historically, `BudgetStoreV2` exposed many methods like:

```swift
func addPayment(_ payment: PaymentSchedule) async {
    await payments.addPayment(payment)
}
```

These were useful before we had first-class sub-stores, but now they:
- Add **noise** and **binary size**.
- Encourage API drift (root vs sub-store might diverge behavior).
- Make the call graph harder to analyze (indirection for no gain).

**✅ COMPLETED (December 28, 2025):** All 48 pass-through methods have been **removed** from `BudgetStoreV2.swift`. Views now access sub-stores directly:

```swift
@Environment(\.budgetStore) private var budgetStore

// In views - use sub-stores directly:
await budgetStore.payments.addPayment(payment)
await budgetStore.affordability.loadScenarios()
await budgetStore.categoryStore.addCategory(category)
await budgetStore.development.loadBudgetDevelopmentItems(scenarioId: id)
```

---

### 2.3 Budget Development & Folders → BudgetDevelopmentStoreV2 ✅ COMPLETED

**✅ COMPLETED:** `BudgetDevelopmentStoreV2` has been created and all functionality migrated.

**Location:** `Services/Stores/Budget/BudgetDevelopmentStoreV2.swift` (479 lines)

**Responsibilities:**

1. **Scenario Item Operations**
   - `loadBudgetDevelopmentItems(scenarioId:)`
   - `saveBudgetDevelopmentItem(_:)`
   - `deleteBudgetDevelopmentItem(id:)`
   - `loadBudgetDevelopmentItemsWithSpentAmounts(scenarioId:)`
   - `saveScenarioWithItems(_:, items:)`
   - `updateBudgetDevelopmentScenario(_:)`

2. **Scenario Item Caching**
   - Owns the `ScenarioCache` actor.
   - Provides `invalidateScenarioCache(scenarioId:)`.

3. **Folder Operations**
   - CRUD and movement:
     - `createFolder(name:scenarioId:parentFolderId:displayOrder:)`
     - `moveItemToFolder(itemId:targetFolderId:displayOrder:)`
     - `updateDisplayOrder(items:)`
     - `toggleFolderExpansion(folderId:isExpanded:)`
     - `deleteFolder(folderId:deleteContents:)`
   - Queries and hierarchy work:
     - `fetchBudgetItemsHierarchical(scenarioId:)`
     - `calculateFolderTotals(folderId:)` (backed by repository RPC).
     - Local helpers: `getChildren(of:from:)`, `getAllDescendants(...)`, `calculateLocalFolderTotals(...)`, `getHierarchyLevel(...)`.

**Wiring from BudgetStoreV2:**

```swift
public var development: BudgetDevelopmentStoreV2
```

**Migration Status:** ✅ All call sites migrated. `BudgetStoreV2+Development.swift` deleted.

---

### 2.4 Computed Properties: Structure, Not Sprawl

`BudgetStoreV2+Computed.swift` (545 lines) contains computed properties organized by domain:
- Root budget metrics: `actualTotalBudget`, `remainingBudget`, `percentageSpent`, `stats`, `budgetAlerts`, etc.
- Payments/gifts/affordability metrics drawn from sub-stores.

**✅ COMPLETED:**
- Low-value mirrors (`categories`, `expenses`) removed
- All metrics now read from `loadingState` and composed stores

**Optional Future Enhancement:**
Split into domain-specific extensions for improved organization:
- `BudgetStoreV2+MetricsBudget.swift`
- `BudgetStoreV2+MetricsPayments.swift`
- `BudgetStoreV2+MetricsGifts.swift`
- `BudgetStoreV2+MetricsAffordability.swift`

---

### 2.5 Payment Status Logic – Already Aligned with Best Practices

`BudgetStoreV2+PaymentStatus.swift` (188 lines) is already structured correctly:

- Uses `ExpensePaymentStatusService` (a domain service) for the *rules*.
- `BudgetStoreV2` performs **orchestration only**:
  - Reads the current expenses from `loadingState`.
  - Reads `payments.paymentSchedules` from `PaymentScheduleStore`.
  - Calls the service to determine status updates.
  - Persists updates via `repository.updateExpense`.
  - Updates `loadingState` in memory.

We keep this pattern as-is, and use it as the **gold standard** for new cross-cutting calculations.

---

### 2.6 Implementation Checklist ✅ ALL COMPLETE

**Final Status (December 28, 2025):** All required work is complete.

1. **Pass-through Cleanup** ✅ **FULLY COMPLETED**
   - [x] Enumerate all affordability, payments, and category methods on `BudgetStoreV2` that simply call a sub-store.
   - [x] Mark each with `@available(*, deprecated, message: ...)` pointing to the correct sub-store method.
   - [x] Use greb/AI search to rewrite all call sites to the sub-store directly.
   - [x] **DONE (Dec 28, 2025)**: All 48 deprecated methods **REMOVED** from `BudgetStoreV2.swift` (721 → 482 lines, 33% reduction).
   - [x] Fixed additional usages: `refreshBudgetData()` → `refresh()`, `loadCashFlowData()` → `refresh()` across all Budget views.

2. **Introduce BudgetDevelopmentStoreV2** ✅ **COMPLETED**
   - [x] Create `Services/Stores/Budget/BudgetDevelopmentStoreV2.swift` with `@MainActor class BudgetDevelopmentStoreV2: ObservableObject`.
   - [x] Move `ScenarioCache` and associated functions from `BudgetStoreV2+Development.swift` into this class.
   - [x] Move folder CRUD and helper methods from `BudgetStoreV2.swift` into this class.
   - [x] Add `public var development: BudgetDevelopmentStoreV2` to `BudgetStoreV2` and instantiate it in `init()`.
   - [x] Migrate call sites to use `budgetStore.development.*`.
   - [x] Remove `BudgetStoreV2+Development.swift` file entirely.

3. **Computed Properties Refactor** ✅ **COMPLETED**
   - [x] Identify and remove low-value mirrors for `categories` and `expenses` after migrating their usages across all views.
   - [x] Update core metrics to read from `loadingState` and composed stores.
   - [x] Migrated 15+ view files to use new API.
   - [x] Fixed all compilation errors and verified build succeeds.
   - [ ] Split `BudgetStoreV2+Computed.swift` into domain-specific extensions (optional future enhancement).

4. **File Size / Structure Targets** ✅ **ACHIEVED & EXCEEDED**

   **Final Verified Line Counts (December 28, 2025):**
   
   | File | Lines | Target | Status |
   |------|-------|--------|--------|
   | `BudgetStoreV2.swift` | **482** | <600 | ✅ **EXCEEDED** |
   | `BudgetStoreV2+Computed.swift` | 545 | <600 | ✅ Met |
   | `BudgetStoreV2+PaymentStatus.swift` | 188 | <200 | ✅ Met |
   | `AffordabilityStore.swift` | 522 | <600 | ✅ Met |
   | `CategoryStoreV2.swift` | 372 | <400 | ✅ Met |
   | `ExpenseStoreV2.swift` | 264 | <300 | ✅ Met |
   | `GiftsStore.swift` | 274 | <300 | ✅ Met |
   | `PaymentScheduleStore.swift` | 703 | <750 | ✅ Met |
   | `BudgetDevelopmentStoreV2.swift` | 479 | <500 | ✅ Met |
   | **Total Store Layer** | **3,829** | - | ✅ Well-organized |

**Summary of Achievements (Final)**:
- ✅ Extracted `BudgetDevelopmentStoreV2` with all scenario/folder operations
- ✅ Removed `BudgetStoreV2+Development.swift` (functionality moved to new store)
- ✅ **REMOVED all 48 deprecated pass-through methods** (not just deprecated - fully deleted)
- ✅ Removed mirror properties (`categories`, `expenses`) from computed properties
- ✅ Updated all computed metrics to read from `loadingState` and composed stores
- ✅ Migrated 15+ view files to use new API
- ✅ Fixed all compilation errors - **BUILD SUCCEEDED**
- ✅ Followed MVVM + Repository + Domain Services architecture
- ✅ All stores remain under recommended size limits
- ✅ **BudgetStoreV2.swift reduced by 33%** (721 → 482 lines)

**🎉 No remaining work for Section 2. The Budget Store V2 optimization is complete.**

---

### 3. DashboardViewV4.swift (~1400 lines → 217 lines) ✅ COMPLETED
**Status:** ✅ COMPLETED - December 28, 2025

**Results:**
- **Starting Line Count**: ~1,400 lines
- **Final Line Count**: **217 lines** (84.5% reduction)
- **Target**: <300 lines ✅ **EXCEEDED**

**Files Created (16 total):**
1. `DashboardViewModel.swift` (280 lines)
2. `Budget/BudgetOverviewCardV4.swift` (145 lines)
3. `Budget/PaymentDueRow.swift` (70 lines)
4. `Budget/BudgetProgressRow.swift` (65 lines)
5. `Tasks/TaskProgressCardV4.swift` (50 lines)
6. `Tasks/DashboardTaskRow.swift` (70 lines)
7. `Guests/GuestResponsesCardV4.swift` (80 lines)
8. `Guests/StatColumn.swift` (25 lines)
9. `Guests/DashboardGuestRow.swift` (95 lines)
10. `Vendors/VendorStatusCardV4.swift` (50 lines)
11. `Vendors/VendorRow.swift` (120 lines)
12. `Hero/WeddingCountdownCard.swift` (75 lines)
13. `Hero/DashboardMetricCard.swift` (55 lines)
14. `QuickActions/QuickActionsCardV4.swift` (50 lines)
15. `QuickActions/DashboardV4QuickActionButton.swift` (35 lines)
16. `DashboardSkeletonViews.swift` (135 lines)

**Key Achievements:**
- ✅ MVVM pattern with `DashboardViewModel`
- ✅ All inline components extracted to `Views/Dashboard/Components/`
- ✅ Skeleton views consolidated
- ✅ Removed `swiftlint:disable file_length` comment
- ✅ Build succeeded with no errors

See `DASHBOARD_V4_DECOMPOSITION_TRACKER.md` for full details.

---

### 4. FileImportService.swift (901 lines → 180 lines) ✅ COMPLETED
**Status:** Phase 2 Complete - **#1 hotspot** resolved (complexity score: 90.0 → ~20.0)

**Issues Resolved**: Decomposed very large service handling multiple import formats. Reduced cyclomatic complexity from 75 to ~15 per service, eliminated deep nesting (level 6 → 2-3), separated concerns.

**Swift Best Practices Applied**: Protocol-oriented programming, composition over inheritance, focused components with single responsibilities, value semantics.

**Final Architecture**:
```
FileImportService (Thin Façade - 180 lines) ✅
├── CSVImportService (CSV parsing - 95 lines) ✅
├── XLSXImportService (XLSX parsing - 185 lines) ✅
├── ImportValidationService (Validation logic - 105 lines) ✅
├── ColumnMappingService (Mapping inference - 175 lines) ✅
├── GuestConversionService (Guest conversion - 165 lines) ✅
└── VendorConversionService (Vendor conversion - 105 lines) ✅
```

**Implementation Summary**:

#### Phase 1: Extract Pure Functions ✅ COMPLETED
1. **Extracted helper functions** to separate files:
   - ✅ `DateParsingHelpers.swift` (85 lines) - `parseDate`, `parseNumeric`, `parseBoolean`, `parseInteger`
   - ✅ `StringValidationHelpers.swift` (20 lines) - `isValidEmail`, `isValidPhone`
   - ✅ `RSVPStatusParsingHelpers.swift` (68 lines) - `parseRSVPStatus`, `parseInvitedBy`, `parsePreferredContactMethod`

#### Phase 2: Create Protocol-Based Services ✅ COMPLETED
2. **Created focused services** following protocol-oriented design:
   - ✅ `CSVImportService` (95 lines) - CSV file parsing with quote/comma handling
   - ✅ `XLSXImportService` (185 lines) - XLSX parsing with CoreXLSX, shared strings, inline strings
   - ✅ `ImportValidationService` (105 lines) - Row/column validation, email/phone format checks
   - ✅ `ColumnMappingService` (175 lines) - Header inference with 50+ field patterns
   - ✅ `GuestConversionService` (165 lines) - CSV → Guest object conversion
   - ✅ `VendorConversionService` (105 lines) - CSV → Vendor object conversion

#### Phase 3: Compose in Façade ✅ COMPLETED
3. **Updated FileImportService** to thin façade pattern:
   - ✅ Composes 6 focused services via dependency injection
   - ✅ Delegates all operations to specialized services
   - ✅ Maintains backward compatibility - **zero breaking changes**
   - ✅ All 4 views continue to work without modification

**Results**:
- **Line Count**: 901 → 180 lines (80% reduction in main file)
- **Total Extracted**: ~1,030 lines across 9 focused files
- **Complexity**: 90.0 → ~20.0 per service (78% reduction)
- **Testability**: Each service independently testable
- **Maintainability**: Changes isolated to single-responsibility services
- **Build Status**: ✅ **BUILD SUCCEEDED** - no compilation errors
- **Breaking Changes**: **ZERO** - all existing code works unchanged

**Benefits**:
- **Testability**: Each service can be unit tested in isolation
- **Maintainability**: Changes to CSV parsing don't affect XLSX parsing
- **Reusability**: Services can be reused independently
- **Performance**: Smaller components, easier to optimize
- **Swift Best Practices**: Protocol-oriented, composition over inheritance

**Migration Path**:
1. **No breaking changes** - public interface preserved
2. **Gradual migration** - extract one service at a time
3. **Backward compatibility** - all existing code continues to work
4. **Testing** - comprehensive tests for each new service

**Target**: FileImportService reduced to thin façade (~150 lines), each focused service <200 lines.

---

### 5. AdvancedExportTemplateService.swift (816 lines → ~150 lines) ⏳ HIGH PRIORITY - IN PROGRESS
**Status:** Phase 1 Starting - **#2 hotspot** (complexity score: 85.0, nesting depth: 5)

**Issues**: Very large export service with high complexity (72), deep nesting (level 5), many branches (score 48). Mixed responsibilities: template management, export generation, PDF/image/SVG creation, and persistence all in one file.

**Swift Best Practices Applied** (from Swiftzilla research):
- **Protocol-Oriented Design** (API Design Guidelines) - Define protocols for each export format
- **Single Responsibility Principle** (Xcode build efficiency docs) - Separate concerns
- **Actor Isolation** (SE-0338, SE-0461) - Proper MainActor usage for UI code
- **Composition over Inheritance** (Cocoa Design Patterns) - Façade pattern
- **ImageRenderer Best Practices** (SwiftUI docs) - Extract to dedicated renderers

**Proposed Architecture**:
```
AdvancedExportTemplateService (Façade - ~150 lines)
├── ExportTemplateManager (Template CRUD - ~100 lines)
├── BrandingSettingsManager (Branding persistence - ~80 lines)
├── PDFExportGenerator (PDF generation - ~200 lines)
├── ImageExportGenerator (PNG/JPEG generation - ~100 lines)
├── SVGExportGenerator (SVG generation - ~50 lines)
└── Models/
    ├── ExportTemplate.swift (~80 lines)
    ├── ExportModels.swift (~100 lines) - Categories, Formats, Features
    ├── BrandingSettings.swift (~60 lines)
    └── ExportContent.swift (~40 lines)
```

**Detailed Implementation Plan**:

#### Phase 1: Extract Data Models (Low Risk) ✅ COMPLETED
1. **Extracted template models** to `Services/Export/Models/ExportTemplate.swift` (195 lines):
   - ✅ `ExportTemplate` struct
   - ✅ `ExportCategory` enum
   - ✅ `ExportFormat` enum
   - ✅ `TemplateFeature` enum
   - ✅ `TemplateLayout` struct
   - ✅ `CodableEdgeInsets` struct

2. **Extracted branding models** to `Services/Export/Models/BrandingSettings.swift` (38 lines):
   - ✅ `BrandingSettings` struct
   - ✅ `ContactInfo` struct

3. **Extracted content/error models** to `Services/Export/Models/ExportModels.swift` (48 lines):
   - ✅ `ExportContent` struct
   - ✅ `ExportCustomizations` struct
   - ✅ `ExportError` enum

4. **Updated AdvancedExportTemplateService.swift**:
   - ✅ Removed ~280 lines of model definitions
   - ✅ Added import comments for extracted models
   - ✅ **BUILD SUCCEEDED** - no compilation errors

**Phase 1 Results**:
- **Models Extracted**: 281 lines across 3 files
- **Main File Reduced**: 816 → ~536 lines (34% reduction so far)
- **Build Status**: ✅ All changes compile successfully

#### Phase 2: Extract Format-Specific Generators ✅ COMPLETED
4. **Created `PDFExportGenerator.swift`** (265 lines):
   - ✅ Extracted `generatePDFExport()` and all PDF page generation methods
   - ✅ Actor-based for thread safety
   - ✅ Protocol: `PDFExportProtocol`
   - ✅ Methods: `generatePDF`, `generateCoverPage`, `generateTableOfContents`, `generateMoodBoardPages`, `generateColorPalettePages`, `generateSeatingChartPages`, `generateStyleGuidePages`

5. **Created `ImageExportGenerator.swift`** (118 lines):
   - ✅ Extracted `generateImageExport()` and image content generation
   - ✅ Protocol: `ImageExportProtocol`
   - ✅ Supports PNG and JPEG formats with configurable quality
   - ✅ Uses SwiftUI ImageRenderer for high-resolution exports

6. **Created `SVGExportGenerator.swift`** (68 lines):
   - ✅ Extracted `generateSVGExport()` and SVG content generation
   - ✅ Protocol: `SVGExportProtocol`
   - ✅ Simplified SVG generation (ready for enhancement)

7. **Updated AdvancedExportTemplateService.swift**:
   - ✅ Removed ~350 lines of generator code
   - ✅ Delegates to format-specific generators via switch statement
   - ✅ Simplified `generateBatchExport` to reuse `generateExport`
   - ✅ **BUILD SUCCEEDED** - no compilation errors

**Phase 2 Results**:
- **Generators Extracted**: 451 lines across 3 files
- **Main File Reduced**: ~536 → ~185 lines (77% reduction total)
- **Build Status**: ✅ All changes compile successfully
- **Architecture**: Clean separation of concerns by export format

#### Phase 3: Extract Management Services ✅ COMPLETED
7. **Created `ExportTemplateManager.swift`** (195 lines):
   - ✅ Template loading (built-in and custom templates)
   - ✅ Template persistence (save/delete custom templates)
   - ✅ Custom template creation with UUID generation
   - ✅ Template preview generation delegation
   - ✅ Protocol: `ExportTemplateManagerProtocol`

8. **Created `BrandingSettingsManager.swift`** (48 lines):
   - ✅ Branding settings persistence via UserDefaults
   - ✅ Load/save/reset operations
   - ✅ Protocol: `BrandingSettingsManagerProtocol`

**Phase 3 Results**:
- **Managers Extracted**: 243 lines across 2 files
- **Main File Reduced**: ~185 → 205 lines (final size)
- **Build Status**: ✅ All changes compile successfully

#### Phase 4: Compose in Façade ✅ COMPLETED
9. **Updated `AdvancedExportTemplateService.swift`** to thin façade (205 lines):
   - ✅ Composed `ExportTemplateManager` and `BrandingSettingsManager` via dependency injection
   - ✅ Delegates template operations to `templateManager`
   - ✅ Delegates branding operations to `brandingManager`
   - ✅ Delegates export generation to format-specific generators
   - ✅ Maintains backward compatibility - **zero breaking changes**
   - ✅ Keeps `shared` singleton for existing code
   - ✅ **BUILD SUCCEEDED** - no compilation errors

**Phase 4 Results**:
- **Final Main File**: 205 lines (was 816 lines)
- **Total Reduction**: 75% reduction (611 lines removed)
- **Files Created**: 8 focused files (3 models, 3 generators, 2 managers)
- **Total Extracted**: 975 lines across 8 specialized files
- **Build Status**: ✅ All changes compile successfully
- **Breaking Changes**: **ZERO** - all existing code works unchanged

**🎉 AdvancedExportTemplateService Decomposition COMPLETE!**

**Final Architecture**:
```
AdvancedExportTemplateService (Façade - 205 lines) ✅
├── Managers/
│   ├── ExportTemplateManager (195 lines) ✅
│   └── BrandingSettingsManager (48 lines) ✅
├── Generators/
│   ├── PDFExportGenerator (265 lines) ✅
│   ├── ImageExportGenerator (118 lines) ✅
│   └── SVGExportGenerator (68 lines) ✅
└── Models/
    ├── ExportTemplate.swift (195 lines) ✅
    ├── BrandingSettings.swift (38 lines) ✅
    └── ExportModels.swift (48 lines) ✅
```

**Summary of Achievements**:
- ✅ Extracted all data models to dedicated files
- ✅ Extracted format-specific generators (PDF, Image, SVG)
- ✅ Extracted management services (templates, branding)
- ✅ Reduced main file by 75% (816 → 205 lines)
- ✅ Protocol-oriented design for all services
- ✅ Actor-based generators for thread safety
- ✅ Dependency injection for testability
- ✅ Zero breaking changes - backward compatible
- ✅ **BUILD SUCCEEDED** - production ready

**Target Achieved**: ✅ Main file reduced to ~200 lines (target was ~150 lines, achieved 205 lines - within acceptable range)

**Benefits**:
- **Testability**: Each generator can be unit tested in isolation
- **Maintainability**: PDF changes don't affect image export
- **Reusability**: Generators can be used independently
- **Performance**: Smaller files, faster compilation
- **Swift Best Practices**: Protocol-oriented, composition over inheritance

**Migration Path**:
1. **No breaking changes** - public interface preserved
2. **Gradual migration** - extract one component at a time
3. **Backward compatibility** - all existing code continues to work
4. **Testing** - comprehensive tests for each new component

**Target**: AdvancedExportTemplateService reduced to thin façade (~150 lines), each focused component <200 lines.

---

### 6. ColorExtractionService.swift (750 lines → 191 lines) ✅ COMPLETED
**Status:** ✅ COMPLETED - **#3 hotspot** resolved (complexity score: 83.3 → ~20.0)

**Issues**: Large visual planning service with very high complexity (63), deep nesting (level 6). Mixed responsibilities: image processing, multiple extraction algorithms, k-means clustering, accessibility analysis, and quality scoring all in one file.

**Current Usage** (from greb-mcp analysis):
- Used in `MoodBoardGeneratorView` (main orchestrator)
- Used in `AddImagesStepView` (image upload step)
- Used in `ColorsAndStyleStepView` (color extraction step)
- Used in `ColorPaletteCreatorView` (palette creation)
- All views use `@StateObject` or `@ObservedObject` pattern
- **Zero breaking changes required** - maintain public interface

**Swift Best Practices Applied** (from Swiftzilla research):
- **Core Image Performance** (Apple docs) - Optimize CIContext usage, minimize filter creation
- **Accelerate Framework** (vImage) - Use planar buffers for parallel processing
- **Memory Management** (Xcode docs) - Release large image buffers promptly, avoid retain cycles
- **Actor Isolation** (SE-0338) - Thread-safe algorithm implementations
- **Protocol-Oriented Design** - Define protocols for each algorithm type

**Proposed Architecture**:
```
ColorExtractionService (Façade - ~150 lines)
├── Processors/
│   ├── ImageProcessingService (~120 lines)
│   │   - NSImage → CIImage conversion
│   │   - Pixel sampling and scaling
│   │   - Histogram data extraction
│   │   - Memory-efficient buffer management
│   └── ColorSpaceConverter (~60 lines)
│       - RGB ��� HSL conversions
│       - Color space transformations
│       - Gamma correction utilities
├── Algorithms/
│   ├── VibrantColorAlgorithm (~100 lines)
│   │   - Histogram-based vibrant color extraction
│   │   - Saturation weighting
│   │   - Protocol: ColorExtractionAlgorithmProtocol
│   ├── QuantizationAlgorithm (~80 lines)
│   │   - CIColorPosterize-based quantization
│   │   - Unique color extraction
│   │   - Protocol: ColorExtractionAlgorithmProtocol
│   ├── ClusteringAlgorithm (~150 lines)
│   │   - K-means clustering implementation
│   │   - SIMD-optimized distance calculations
│   │   - Centroid convergence detection
│   │   - Protocol: ColorExtractionAlgorithmProtocol
│   └── DominantColorAlgorithm (~100 lines)
│       - Vision framework integration (future)
│       - Dominant color detection
│       - Protocol: ColorExtractionAlgorithmProtocol
├── Analysis/
│   ├── ColorQualityAnalyzer (~100 lines)
│   │   - Quality score calculation
│   │   - Color diversity metrics
│   │   - Population distribution analysis
│   └── AccessibilityAnalyzer (~120 lines)
│       - WCAG contrast ratio calculations
│       - Relative luminance computation
│       - Accessibility recommendations
└── Models/
    ├── ColorExtractionModels.swift (~100 lines)
    │   - ExtractedColor, ColorExtractionResult
    │   - ColorExtractionOptions, ExtractionMetadata
    └── ColorAlgorithmModels.swift (~60 lines)
        - ColorCluster, ContrastPair
        - AccessibilityInfo, ColorExtractionError
```

**Detailed Implementation Plan**:

#### Phase 1: Extract Data Models (Low Risk) ⏳ READY
1. **Create `ColorExtractionModels.swift`** (~100 lines):
   - Move `ExtractedColor` struct
   - Move `ColorExtractionResult` struct
   - Move `ColorExtractionOptions` struct
   - Move `ExtractionMetadata` struct
   - Move `ColorExtractionAlgorithm` enum

2. **Create `ColorAlgorithmModels.swift`** (~60 lines):
   - Move `ColorCluster` struct
   - Move `ContrastPair` struct
   - Move `AccessibilityInfo` struct
   - Move `ColorExtractionError` enum
   - Move SIMD3 extension

**Phase 1 Target**: Extract ~160 lines of models, reduce main file to ~590 lines

#### Phase 2: Extract Image Processing (Medium Risk) ⏳ READY
3. **Create `ImageProcessingService.swift`** (~120 lines):
   - Extract `convertToCIImage(_:)` method
   - Extract `extractHistogramData(from:)` method
   - Extract `samplePixels(from:sampleCount:)` method
   - Add protocol: `ImageProcessingProtocol`
   - Actor-based for thread safety
   - Optimize CIContext reuse (shared instance)

4. **Create `ColorSpaceConverter.swift`** (~60 lines):
   - Extract color space conversion utilities
   - Extract gamma correction functions
   - Pure functions (no state)

**Phase 2 Target**: Extract ~180 lines, reduce main file to ~410 lines

#### Phase 3: Extract Algorithm Implementations (High Risk) ⏳ READY
5. **Create protocol `ColorExtractionAlgorithmProtocol`**:
```swift
protocol ColorExtractionAlgorithmProtocol {
    func extractColors(
        from ciImage: CIImage,
        options: ColorExtractionOptions,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> ([ExtractedColor], ExtractionMetadata)
}
```

6. **Create `VibrantColorAlgorithm.swift`** (~100 lines):
   - Extract `extractVibrantColors(from:options:)` method
   - Extract `analyzeHistogramForVibrantColors(_:maxColors:)` method
   - Extract `calculateVibrancy(_:)` method
   - Actor-based implementation

7. **Create `QuantizationAlgorithm.swift`** (~80 lines):
   - Extract `extractQuantizedColors(from:options:)` method
   - Extract `extractUniqueColors(from:maxColors:)` method
   - Actor-based implementation

8. **Create `ClusteringAlgorithm.swift`** (~150 lines):
   - Extract `extractClusteredColors(from:options:)` method
   - Extract `performKMeansClustering(on:k:)` method
   - SIMD-optimized distance calculations
   - Actor-based implementation

9. **Create `DominantColorAlgorithm.swift`** (~100 lines):
   - Extract `extractDominantColors(from:options:)` method
   - Extract `analyzeDominantColors(ciImage:maxColors:)` method
   - Actor-based implementation

**Phase 3 Target**: Extract ~430 lines, reduce main file to ~260 lines (algorithms removed)

#### Phase 4: Extract Analysis Services (Low Risk) ⏳ READY
10. **Create `ColorQualityAnalyzer.swift`** (~100 lines):
    - Extract `calculateQualityScore(for:metadata:)` method
    - Extract `calculateColorDiversity(_:)` method
    - Extract `calculateColorDistance(_:_:)` method
    - Extract `calculatePopulationDistribution(_:)` method
    - Pure functions (no state)

11. **Create `AccessibilityAnalyzer.swift`** (~120 lines):
    - Extract `generateAccessibilityInfo(for:)` method
    - Extract `calculateContrastRatio(_:_:)` method
    - Extract `calculateRelativeLuminance(_:)` method
    - Extract `generateAccessibilityRecommendations(for:)` method
    - Pure functions (no state)

**Phase 4 Target**: Extract ~220 lines, reduce main file to ~150 lines (final size)

#### Phase 5: Compose in Façade (Final Integration) ⏳ READY
12. **Update `ColorExtractionService.swift`** to thin façade (~150 lines):
    - Compose all services via dependency injection
    - Maintain `@MainActor` for UI updates (`@Published` properties)
    - Delegate image processing to `ImageProcessingService`
    - Delegate algorithm execution to algorithm implementations
    - Delegate quality analysis to `ColorQualityAnalyzer`
    - Delegate accessibility to `AccessibilityAnalyzer`
    - Keep public interface unchanged - **zero breaking changes**
    - Maintain progress reporting through composed services

**Phase 5 Target**: Final façade ~150 lines, all existing views work unchanged

**Performance Optimizations** (from Apple docs):
- **CIContext Reuse**: Share single CIContext instance across all operations
- **Planar Buffers**: Use Accelerate framework for parallel channel processing
- **Memory Management**: Release large buffers immediately after use
- **SIMD Operations**: Leverage SIMD for distance calculations in k-means
- **Async/Await**: Proper actor isolation for thread-safe algorithm execution

**Testing Strategy**:
1. **Unit Tests**: Test each algorithm independently with known inputs
2. **Performance Tests**: Benchmark before/after decomposition
3. **Integration Tests**: Verify façade delegates correctly
4. **UI Tests**: Ensure all 4 views continue to work

**Migration Path**:
1. **No breaking changes** - public interface preserved
2. **Gradual extraction** - one component at a time
3. **Backward compatibility** - all existing views work unchanged
4. **Performance validation** - benchmark each phase

**Benefits**:
- **Testability**: Each algorithm independently testable
- **Maintainability**: Algorithm changes isolated
- **Reusability**: Algorithms can be used independently
- **Performance**: Optimized CIContext and buffer management
- **Extensibility**: Easy to add new algorithms via protocol

**Phase 1: Extract Data Models** ✅ COMPLETED
1. **Created `ColorExtractionModels.swift`** (92 lines):
   - ✅ Extracted `ExtractedColor`, `ColorExtractionResult`, `ColorExtractionOptions`, `ExtractionMetadata`, `ColorExtractionAlgorithm`

2. **Created `ColorAlgorithmModels.swift`** (63 lines):
   - ✅ Extracted `ColorCluster`, `ContrastPair`, `AccessibilityInfo`, `ColorExtractionError`, SIMD3 extension

**Phase 1 Results**: 155 lines extracted across 2 model files

**Phase 2: Extract Image Processing** ✅ COMPLETED
3. **Created `ImageProcessingService.swift`** (101 lines):
   - ✅ Actor-based image processing service
   - ✅ Protocol: `ImageProcessingProtocol`
   - ✅ Methods: `convertToCIImage`, `extractHistogramData`, `samplePixels`
   - ✅ Shared CIContext for optimal performance

4. **Created `ColorSpaceConverter.swift`** (64 lines):
   - ✅ Pure functions for color space conversions
   - ✅ Methods: `calculateVibrancy`, `calculateColorDistance`, `calculateRelativeLuminance`, `calculateContrastRatio`

**Phase 2 Results**: 165 lines extracted across 2 processor files

**Phase 3: Extract Algorithm Implementations** ✅ COMPLETED
5. **Created `ColorExtractionAlgorithmProtocol.swift`** (24 lines):
   - ✅ Protocol defining algorithm interface with progress callbacks

6. **Created `VibrantColorAlgorithm.swift`** (100 lines):
   - ✅ Actor-based vibrant color extraction
   - ✅ Histogram analysis with saturation weighting

7. **Created `QuantizationAlgorithm.swift`** (88 lines):
   - ✅ Actor-based quantization using CIColorPosterize
   - ✅ Unique color extraction

8. **Created `ClusteringAlgorithm.swift`** (140 lines):
   - ✅ Actor-based k-means clustering
   - ✅ SIMD-optimized distance calculations
   - ✅ Centroid convergence detection

9. **Created `DominantColorAlgorithm.swift`** (62 lines):
   - ✅ Actor-based dominant color detection
   - ✅ Delegates to clustering algorithm

**Phase 3 Results**: 414 lines extracted across 5 algorithm files

**Phase 4: Extract Analysis Services** ✅ COMPLETED
10. **Created `ColorQualityAnalyzer.swift`** (71 lines):
    - ✅ Pure functions for quality scoring
    - ✅ Methods: `calculateQualityScore`, `calculateColorDiversity`, `calculatePopulationDistribution`

11. **Created `ColorAccessibilityAnalyzer.swift`** (59 lines):
    - ✅ Pure functions for WCAG accessibility analysis
    - ✅ Methods: `generateAccessibilityInfo`, `generateAccessibilityRecommendations`
    - ✅ Renamed to avoid conflict with existing `AccessibilityAnalyzer`

**Phase 4 Results**: 130 lines extracted across 2 analysis files

**Phase 5: Compose in Façade** ✅ COMPLETED
12. **Updated `ColorExtractionService.swift`** to thin façade (191 lines):
    - ✅ Removed all old implementation code (559 lines removed)
    - ✅ Composed all services via dependency injection
    - ✅ Delegates to `ImageProcessingService` for image processing
    - ✅ Delegates to algorithm implementations for extraction
    - ✅ Delegates to `ColorQualityAnalyzer` for quality scoring
    - ✅ Delegates to `ColorAccessibilityAnalyzer` for accessibility
    - ✅ Maintains `@MainActor` for UI updates
    - ✅ Keeps public interface unchanged - **zero breaking changes**
    - ✅ All 4 views continue to work without modification
    - ✅ **BUILD SUCCEEDED** - no compilation errors

**Final Results**:
- **Main File**: 750 → 191 lines (74.5% reduction)
- **Files Created**: 11 focused files
- **Total Extracted**: 864 lines across specialized files
- **Build Status**: ✅ **BUILD SUCCEEDED** - production ready
- **Breaking Changes**: **ZERO** - all existing code works unchanged
- **Views Tested**: 4 views (MoodBoardGeneratorView, AddImagesStepView, ColorsAndStyleStepView, ColorPaletteCreatorView)

**Final Architecture**:
```
ColorExtractionService (Façade - 191 lines) ✅
├── Models/ (155 lines)
│   ├── ColorExtractionModels.swift (92 lines) ✅
│   └── ColorAlgorithmModels.swift (63 lines) ✅
├── Processors/ (165 lines)
│   ├── ImageProcessingService.swift (101 lines) ✅
│   └── ColorSpaceConverter.swift (64 lines) ✅
├── Algorithms/ (414 lines)
│   ├── ColorExtractionAlgorithmProtocol.swift (24 lines) ✅
│   ├── VibrantColorAlgorithm.swift (100 lines) ✅
│   ├─�� QuantizationAlgorithm.swift (88 lines) ✅
│   ├── ClusteringAlgorithm.swift (140 lines) ✅
│   └── DominantColorAlgorithm.swift (62 lines) ✅
└── Analysis/ (130 lines)
    ├── ColorQualityAnalyzer.swift (71 lines) ✅
    └── ColorAccessibilityAnalyzer.swift (59 lines) ✅
```

**Performance Optimizations Applied**:
- ✅ Shared CIContext instance (Apple best practice)
- ✅ SIMD-optimized k-means clustering
- ✅ Actor isolation for thread safety
- ✅ Memory-efficient pixel sampling
- ✅ Progress callbacks for UI responsiveness

**Benefits Achieved**:
- ✅ **Testability**: Each algorithm independently testable
- ✅ **Maintainability**: Algorithm changes isolated
- ✅ **Reusability**: Algorithms can be used independently
- ✅ **Performance**: Optimized CIContext and buffer management
- ✅ **Extensibility**: Easy to add new algorithms via protocol
- ✅ **Swift Best Practices**: Protocol-oriented, composition over inheritance

**Target Achieved**: ✅ Main file reduced to 191 lines (target was ~150 lines, achieved 191 lines - within acceptable range, 74.5% reduction)

**🎉 ColorExtractionService Decomposition COMPLETE!**

---

### 7. GuestListViewV3.swift (978 lines) ⏳ HIGH PRIORITY
**Status:** Not started - **#4 hotspot** (complexity score: 81.9, nesting depth: 9)

**Issues**: Very large view with very deep nesting (level 9!), high complexity (65). Multiple versions exist causing confusion. Should be deprecated in favor of GuestManagementViewV4.

**Decomposition Points**:
- **Deprecate**: Mark as deprecated, migrate all usages to GuestManagementViewV4
- **If keeping**: Extract panels, filtering logic, and sub-views to components
- **Target**: Delete after confirming no runtime usage

---

### 8. DocumentStoreV2.swift (877 lines) ⏳ MEDIUM PRIORITY
**Status:** Not started - **#5 hotspot** (complexity score: 79.5, nesting depth: 11)

**Issues**: Very large store with extremely deep nesting (level 11!), high complexity (61). Handles document management, Google Drive integration, and file operations.

**Decomposition Points**:
- **Google Drive Logic**: Extract to `GoogleDriveService.swift` (if not already)
- **File Operations**: Separate local file handling
- **Folder Management**: Extract folder CRUD to sub-store
- **Target**: <500 lines for main store

---

### 9. PaymentScheduleView.swift (811 lines) ⏳ MEDIUM PRIORITY
**Status:** Not started - **#6 hotspot** (complexity score: 78.3, nesting depth: 5)

**Issues**: Very large view with high complexity (60). Complex payment scheduling UI with inline components.

**Decomposition Points**:
- **Extract Components**: Move payment row, calendar, and form components to separate files
- **View Model**: Create `PaymentScheduleViewModel` for business logic
- **Target**: <300 lines

---

### 10. AnalyticsService.swift (813 lines) ⏳ LOW PRIORITY
**Status:** Not started - **#7 hotspot** (complexity score: 78.1)

**Issues**: Large analytics service with high complexity (56). Handles multiple analytics providers and event tracking.

**Decomposition Points**:
- **Provider Abstraction**: Create protocol for analytics providers
- **Event Builders**: Extract event construction to helpers
- **Target**: <500 lines

---

### 11. TimelineAPI.swift (676 lines) ⏳ LOW PRIORITY
**Status:** Not started - **#8 hotspot** (complexity score: 75.7, nesting depth: 5)

**Issues**: Large API service with high complexity (59). Handles timeline data fetching and mutations.

**Decomposition Points**:
- **Split by Operation**: Separate read and write operations
- **Caching**: Extract caching logic to shared helper
- **Target**: <400 lines

---

### 12. VendorManagementViewV3.swift (861 lines) ⏳ MEDIUM PRIORITY
**Status:** Not started - **#9 hotspot** (complexity score: 74.9)

**Issues**: Very large view with high complexity (57). Similar issues to guest management views.

**Decomposition Points**:
- **Extract Panels**: Split list and detail panels
- **Components**: Move vendor cards, filters to components
- **View Model**: Create `VendorManagementViewModel`
- **Target**: <300 lines

---

### 13. GuestManagementViewV4.swift (955 lines) ⏳ MEDIUM PRIORITY
**Status:** Not started - **#10 hotspot** (complexity score: 74.9)

**Issues**: Very large view with high complexity (57). This is the canonical guest management view but needs decomposition.

**Decomposition Points**:
- **Extract Panels**: Split into `GuestListPanel` and `GuestDetailPanel`
- **Tab Content**: Move tab views to `Views/Guests/Components/`
- **Filtering**: Extract to `GuestListViewModel`
- **Target**: <300 lines

---

### 15. Budget.swift (1386 lines) ⏳ MEDIUM PRIORITY
**Issues**: Large model file with many structs. Repetitive coding patterns, custom decoding logic.

**Decomposition Points**:
- **Split Models**: Create separate files: `BudgetSummary.swift`, `BudgetCategory.swift`, `Expense.swift`, etc.
- **Extract Common Logic**: Move date decoding helpers to shared utility.
- **Enums & Types**: Group related enums in separate files.
- **Target**: <200 lines per model file.

**Quick Win**: Extract `DateDecodingHelpers` to `Utilities/DateDecoding.swift`.

---

### 16. LiveCollaborationRepository.swift (1139 lines) ⏳ LOW PRIORITY
**Issues**: Complex multi-query operations, email sending mixed with data access.

**Decomposition Points**:
- **Split Operations**: Extract invitation handling to `InvitationService`.
- **Move Complex Queries**: Delegate `fetchUserCollaborations` to `CollaborationAggregationService`.
- **Separate Concerns**: Email sending to dedicated service.
- **Target**: <800 lines; focus on core CRUD.

**Quick Win**: Extract `fetchCoupleName` and email logic to services.

---

### 17. BudgetItemsTableView.swift (952 lines) ⏳ LOW PRIORITY
**Issues**: Large table view with complex data handling.

**Decomposition Points**:
- **Extract Table Logic**: Create `BudgetItemsTableViewModel`.
- **Row Components**: Separate row views.
- **Target**: <400 lines.

---

## Hotspot Priority Summary

Based on Code Guardian analysis (December 28, 2025), the top 10 files requiring attention:

| Rank | File | Lines | Complexity | Priority |
|------|------|-------|------------|----------|
| 1 | FileImportService.swift | 901 | 90.0 | 🔴 HIGH |
| 2 | AdvancedExportTemplateService.swift | 816 | 85.0 | 🔴 HIGH |
| 3 | ColorExtractionService.swift | 750 | 83.3 | 🟡 MEDIUM |
| 4 | GuestListViewV3.swift | 978 | 81.9 | 🔴 HIGH (deprecate) |
| 5 | DocumentStoreV2.swift | 877 | 79.5 | 🟡 MEDIUM |
| 6 | PaymentScheduleView.swift | 811 | 78.3 | 🟡 MEDIUM |
| 7 | AnalyticsService.swift | 813 | 78.1 | 🟢 LOW |
| 8 | TimelineAPI.swift | 676 | 75.7 | 🟢 LOW |
| 9 | VendorManagementViewV3.swift | 861 | 74.9 | 🟡 MEDIUM |
| 10 | GuestManagementViewV4.swift | 955 | 74.9 | 🟡 MEDIUM |

---

## Outdated Version Analysis & Cleanup Plan

### Versioned Files Identified
Analysis of files with version suffixes (V1, V2, V3, V4, etc.) revealed multiple outdated versions that can be safely removed after verification.

### Safe to Remove (No Runtime Usage Found)
These files are only referenced in their own previews or not at all in navigation/code:

- **DashboardViewV2.swift** → Replaced by DashboardViewV4 (used in AppCoordinator)
- **DashboardViewV3.swift** → Replaced by DashboardViewV4
- **GuestListViewV3.swift** → Only has preview; GuestManagementViewV4 used in navigation
- **GuestDetailViewV2.swift** → Replaced by GuestDetailViewV4 (used in AppCoordinator)
- **VendorListViewV2.swift** → Only has preview; VendorManagementViewV3 used in navigation
- **NavigationBarV2.swift** → Only has preview; no runtime usage

**Action**: Add deprecation comments with TODOs, then delete after confirming no hidden dependencies.

### Keep But Deprecate (Still Available via Toggles/Options)
- **SeatingChartEditorView.swift** (old version) → V2 version available via toggle in SeatingChartView
  - **Action**: Mark as deprecated with availability check or TODO; consider removing toggle after user migration period.

### Current Canonical Versions (Keep)
- **DashboardViewV4** (navigation)
- **GuestManagementViewV4** (navigation)
- **GuestDetailViewV4** (navigation)
- **VendorManagementViewV3** (navigation)
- **TimelineViewV2** (navigation)
- **BudgetOverviewDashboardViewV2** (used in BudgetMainView)
- **EditGuestSheetV2** (used in multiple views)
- **EditVendorSheetV2** (used in multiple views)
- **QuickActionButtonV2** (used in QuickActionsBar)

### Deprecation Strategy (From Swift Documentation)
- Use availability checks for platform-specific deprecations.
- Add `@available(*, deprecated, message: "Use V4 instead")` to old versions.
- For user-facing toggles (like seating chart), provide migration path with warnings.
- Test thoroughly before deletion to ensure no hidden imports or reflections.

## Lower Priority Work (From MCP Tools)

### Greb Analysis (Code Search)
- **Anti-Patterns Found**: No direct store creation in views, but some views have excessive @State properties.
- **Duplication**: Some repetitive error handling patterns across repositories.
- **Recommendations**:
  - Standardize error handling with shared `ErrorHandler` extension (already partially done).
  - Reduce @State in views by using store properties.
  - Implement consistent caching strategies.

### Swiftzilla Analysis (Swift Documentation)
- **SwiftUI Performance**:
  - Use `LazyVStack`/`LazyHStack` for large lists (apply to guest/vendor lists).
  - Minimize view body computations; move expensive work to stores.
  - Use `@Observable` macro for better state management (future migration).
- **Concurrency**:
  - Ensure `@MainActor` on all stores/views.
  - Use `Sendable` for actor-crossing types.
  - Validate `async let` for parallel operations.
- **Best Practices**:
  - Keep views <300 lines.
  - Use design system constants.
  - Implement proper accessibility.
  - Migrate from deprecated NavigationView to NavigationStack/NavigationSplitView.

## Implementation Priorities

### Phase 1: Quick Wins (1-2 Days) - ✅ BUDGET COMPLETE, DASHBOARD NEXT
1. ✅ ~~Extract card components from `DashboardViewV4.swift` into `Views/Dashboard/Components/`.~~ (Budget done, Dashboard next)
2. Standardize on the latest Guest List view (e.g., `GuestListViewV4`): point navigation/previews to it, mark V3 as deprecated, and move tab content views from the canonical version into `Views/Guests/Components/`.
3. Split `Budget.swift` into separate model files (e.g., `BudgetSummary.swift`, `BudgetCategory.swift`, `Expense.swift`, `PaymentSchedule.swift`, etc.).
4. Apply `LazyVStack`/`LazyHStack` to scrollable lists in large views (Guest list, vendors, budget tables) to improve SwiftUI performance.

### Phase 2: Medium Refactors (3-5 Days) - ✅ BUDGET COMPLETE
1. ✅ ~~Decompose `LiveBudgetRepository.swift` via internal data-source helpers~~ **DONE** (69% reduction)
2. ✅ ~~Extract payment grouping/summary logic from `BudgetStoreV2.swift`~~ **DONE** (PaymentScheduleStore)
3. Create lightweight view models for complex views (Dashboard, Guest List, Budget items table) so that Views are mostly bindings, not logic.
4. Implement shared date decoding helpers (where not already present) and ensure all budget-related models use them consistently.

### Phase 3: Deep Refactors (1-2 Sprints)
1. Migrate to `@Observable` stores where appropriate to reduce unnecessary SwiftUI updates and better align with modern data flow, while preserving the existing Repository and Service layers.
2. Expand domain services for complex cross-entity logic (beyond `BudgetAggregationService` and `BudgetAllocationService`) instead of adding more repositories.
3. Add comprehensive performance monitoring and profiling for key flows (dashboard load, guest list interactions, budget editing) and iterate using Instruments.
4. Refactor large services (e.g., `FileImportService`) into format-specific helpers (`CSVImport`, `XLSXImport`) with a thin façade, keeping public APIs stable.

## Success Criteria
- All views <300 lines.
- All stores <500 lines.
- Improved compile times.
- Better testability through separation of concerns.
- Enhanced performance (measured via Instruments).

## Risks & Mitigations
- **Breaking Changes**: Test thoroughly; use feature flags for gradual rollout.
- **Performance Impact**: Profile with Instruments before/after.
- **Team Coordination**: Document changes; pair on complex refactors.

This plan aligns with the V2 architecture and repository rules for maintainable, performant code.
