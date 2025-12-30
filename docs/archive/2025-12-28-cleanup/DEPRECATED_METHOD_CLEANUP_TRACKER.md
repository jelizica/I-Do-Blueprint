# Deprecated Method Cleanup Tracker

**Date Started:** December 28, 2025  
**Objective:** Remove all pass-through/deferring methods from BudgetStoreV2.swift  
**Expected Result:** Reduce BudgetStoreV2.swift from ~721 lines to ~350 lines

---

## Overview

BudgetStoreV2.swift contains ~50 deprecated pass-through methods that simply forward calls to sub-stores. These add no value and should be removed after migrating all call sites.

---

## Phase 1: Migrate Call Sites

### 1.1 BudgetCalculatorView.swift Migration

**File:** `I Do Blueprint/Views/Budget/BudgetCalculatorView.swift`

**Methods to migrate:**

| Old API | New API | Status |
|---------|---------|--------|
| `budgetStore.selectScenario(scenario)` | `budgetStore.affordability.selectScenario(scenario)` | ⏳ TODO |
| `budgetStore.loadContributions()` | `budgetStore.affordability.loadContributions()` | ⏳ TODO |
| `budgetStore.deleteScenario(scenario)` | `budgetStore.affordability.deleteScenario(scenario)` | ⏳ TODO |
| `budgetStore.markFieldChanged()` | `budgetStore.affordability.markFieldChanged()` | ⏳ TODO |
| `budgetStore.saveChanges()` | `budgetStore.affordability.saveChanges()` | ⏳ TODO |
| `budgetStore.loadAvailableGifts()` | `budgetStore.affordability.loadAvailableGifts()` | ⏳ TODO |
| `budgetStore.startEditingGift(contributionId:)` | `budgetStore.affordability.startEditingGift(contributionId:)` | ⏳ TODO |
| `budgetStore.deleteContribution(contribution)` | `budgetStore.affordability.deleteContribution(contribution)` | ⏳ TODO |
| `budgetStore.loadScenarios()` | `budgetStore.affordability.loadScenarios()` | ⏳ TODO |
| `budgetStore.setWeddingDate(dateString)` | `budgetStore.affordability.setWeddingDate(dateString)` | ⏳ TODO |
| `budgetStore.createScenario(name:)` | `budgetStore.affordability.createScenario(name:)` | ⏳ TODO |
| `budgetStore.addContribution(...)` | `budgetStore.affordability.addContribution(...)` | ⏳ TODO |
| `budgetStore.linkGifts(giftIds:)` | `budgetStore.affordability.linkGifts(giftIds:)` | ⏳ TODO |
| `budgetStore.updateGift(gift)` | `budgetStore.affordability.updateGift(gift)` | ⏳ TODO |

---

### 1.2 BudgetCategoriesSettingsView.swift Migration

**File:** `I Do Blueprint/Views/Settings/Sections/BudgetCategoriesSettingsView.swift`

**Methods to migrate:**

| Old API | New API | Status |
|---------|---------|--------|
| `budgetStore.canDeleteCategory(category)` | `budgetStore.categoryStore.canDeleteCategory(category)` | ⏳ TODO |
| `budgetStore.loadCategoryDependencies()` | `budgetStore.categoryStore.loadCategoryDependencies()` | ⏳ TODO |
| `budgetStore.getDependencyWarning(for:)` | `budgetStore.categoryStore.getDependencyWarning(for:)` | ⏳ TODO |

---

## Phase 2: Remove Deprecated Methods from BudgetStoreV2.swift

### 2.1 Payment Methods (No usages - safe to remove)

| Method | Lines | Status |
|--------|-------|--------|
| `addPayment(_:)` | ~3 | ⏳ TODO |
| `deletePayment(_:)` | ~3 | ⏳ TODO |
| `updatePayment(_:)` | ~3 | ⏳ TODO |
| `addPaymentSchedule(_:)` | ~3 | ⏳ TODO |
| `updatePaymentSchedule(_:)` | ~3 | ⏳ TODO |
| `deletePaymentSchedule(id:)` | ~3 | ⏳ TODO |
| `loadPaymentSchedules()` | ~3 | ⏳ TODO |

**Subtotal:** ~21 lines to remove

---

### 2.2 Affordability Methods (After migration)

| Method | Lines | Status |
|--------|-------|--------|
| `loadAffordabilityScenarios()` | ~3 | ⏳ TODO |
| `loadAffordabilityContributions(scenarioId:)` | ~3 | ⏳ TODO |
| `saveAffordabilityScenario(_:)` | ~3 | ⏳ TODO |
| `deleteAffordabilityScenario(id:)` | ~3 | ⏳ TODO |
| `saveAffordabilityContribution(_:)` | ~3 | ⏳ TODO |
| `deleteAffordabilityContribution(id:scenarioId:)` | ~3 | ⏳ TODO |
| `linkGiftsToScenario(giftIds:scenarioId:)` | ~3 | ⏳ TODO |
| `unlinkGiftFromScenario(giftId:scenarioId:)` | ~3 | ⏳ TODO |
| `setWeddingDate(_:)` | ~3 | ⏳ TODO |
| `selectScenario(_:)` | ~3 | ⏳ TODO |
| `resetEditingState()` | ~3 | ⏳ TODO |
| `saveChanges()` | ~3 | ⏳ TODO |
| `createScenario(name:)` | ~3 | ⏳ TODO |
| `deleteScenario(_:)` | ~3 | ⏳ TODO |
| `addContribution(name:amount:type:date:)` | ~3 | ⏳ TODO |
| `deleteContribution(_:)` | ~3 | ⏳ TODO |
| `loadAvailableGifts()` | ~3 | ⏳ TODO |
| `linkGifts(giftIds:)` | ~3 | ⏳ TODO |
| `updateGift(_:)` | ~3 | ⏳ TODO |
| `startEditingGift(contributionId:)` | ~3 | ⏳ TODO |
| `markFieldChanged()` | ~3 | ⏳ TODO |
| `loadScenarios()` | ~3 | ⏳ TODO |
| `loadContributions()` | ~3 | ⏳ TODO |

**Subtotal:** ~69 lines to remove

---

### 2.3 Category Methods (After migration)

| Method | Lines | Status |
|--------|-------|--------|
| `loadCategoryDependencies()` | ~6 | ⏳ TODO |
| `canDeleteCategory(_:)` | ~3 | ⏳ TODO |
| `getDependencyWarning(for:)` | ~3 | ⏳ TODO |

**Subtotal:** ~12 lines to remove

---

### 2.4 Folder/Development Methods (No usages - safe to remove)

| Method | Lines | Status |
|--------|-------|--------|
| `createFolder(name:scenarioId:parentFolderId:displayOrder:)` | ~4 | ⏳ TODO |
| `moveItemToFolder(itemId:targetFolderId:displayOrder:)` | ~3 | ⏳ TODO |
| `updateDisplayOrder(items:)` | ~3 | ⏳ TODO |
| `toggleFolderExpansion(folderId:isExpanded:)` | ~3 | ⏳ TODO |
| `fetchBudgetItemsHierarchical(scenarioId:)` | ~3 | ⏳ TODO |
| `calculateFolderTotals(folderId:)` | ~3 | ⏳ TODO |
| `canMoveItem(itemId:toFolder:)` | ~3 | ⏳ TODO |
| `deleteFolder(folderId:deleteContents:)` | ~3 | ⏳ TODO |
| `getChildren(of:from:)` | ~3 | ⏳ TODO |
| `getAllDescendants(of:from:)` | ~3 | ⏳ TODO |
| `calculateLocalFolderTotals(folderId:allItems:)` | ~3 | ⏳ TODO |
| `getHierarchyLevel(itemId:allItems:)` | ~3 | ⏳ TODO |

**Subtotal:** ~37 lines to remove

---

### 2.5 Refresh Methods (No usages - safe to remove)

| Method | Lines | Status |
|--------|-------|--------|
| `refreshData()` | ~3 | ⏳ TODO |
| `refreshBudgetData()` | ~3 | ⏳ TODO |
| `loadCashFlowData()` | ~3 | ⏳ TODO |

**Subtotal:** ~9 lines to remove

---

## Summary

| Category | Lines to Remove | Status |
|----------|-----------------|--------|
| Payment Methods | ~21 | ⏳ TODO |
| Affordability Methods | ~69 | ⏳ TODO |
| Category Methods | ~12 | ⏳ TODO |
| Folder/Development Methods | ~37 | ⏳ TODO |
| Refresh Methods | ~9 | ⏳ TODO |
| **TOTAL** | **~148 lines** | ⏳ TODO |

**Expected Result:**
- Before: 721 lines
- After: ~573 lines (or less with cleanup)
- Reduction: ~20%

---

## Progress Log

### December 28, 2025

- [x] **Phase 1.1**: Migrate BudgetCalculatorView.swift (14 methods) ✅ COMPLETE
- [x] **Phase 1.2**: Migrate BudgetCategoriesSettingsView.swift (3 methods) ✅ COMPLETE
- [x] **Build Verification**: Build succeeded after Phase 1 ✅
- [x] **Phase 2.1**: Remove Payment Methods (7 methods) ✅ COMPLETE
- [x] **Phase 2.2**: Remove Affordability Methods (23 methods) ✅ COMPLETE
- [x] **Phase 2.3**: Remove Category Methods (3 methods) ✅ COMPLETE
- [x] **Phase 2.4**: Remove Folder/Development Methods (12 methods) ✅ COMPLETE
- [x] **Phase 2.5**: Remove Refresh Methods (3 methods) ✅ COMPLETE
- [x] **Additional**: Fixed remaining usages of `refreshBudgetData()` and `loadCashFlowData()` in Views ✅
- [x] **Final Verify**: Build succeeds ✅ **BUILD SUCCEEDED**
- [ ] **Final Verify**: All tests pass (pending)

## Final Results

| Metric | Before | After | Reduction |
|--------|--------|-------|-----------|
| BudgetStoreV2.swift lines | 721 | **482** | **33%** |
| Deprecated methods | 48 | **0** | **100%** |
| Pass-through methods | 48 | **0** | **100%** |

**Total lines removed:** 239 lines
**Build status:** ✅ **BUILD SUCCEEDED**

---

## Notes

- All deprecated methods are marked with `@available(*, deprecated, message: "Use ...")`
- Migration messages already point to the correct sub-store methods
- No breaking changes expected since we're just updating call sites to use the direct API
