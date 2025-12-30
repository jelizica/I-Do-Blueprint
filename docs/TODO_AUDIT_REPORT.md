# TODO/FIXME Audit Report

**Date:** 2025-12-29  
**Total Count:** 44 occurrences  
**Status:** In Progress

## Summary

The codebase contains 44 TODO comments, primarily in two categories:
1. **Preview Code Placeholders** (42 occurrences) - Harmless print statements in SwiftUI previews
2. **Incomplete Implementations** (2 occurrences) - Actual missing functionality

## Category Breakdown

### 1. Preview Code TODOs (Low Priority - Can be cleaned up)

These are placeholder actions in SwiftUI `#Preview` blocks. They don't affect production code but should be cleaned up for code hygiene.

**Pattern:** `// TODO: Implement action - print("...")`

**Files:**
- `Views/Budget/AddExpenseView.swift` - Line ~320
- `Views/Budget/PaymentRecordView.swift` - Preview
- `Views/Budget/AddBudgetCategoryView.swift` - Preview
- `Views/Budget/AddGiftOrOwedModal.swift` - Preview
- `Views/VisualPlanning/SeatingChart/Components/GuestImportView.swift` - Preview
- `Views/Shared/Components/Cards/SummaryCard.swift` - Preview
- `Views/Shared/Components/Common/SearchBar.swift` - Preview
- `Views/Shared/Components/Cards/InfoCard.swift` - Preview
- `Views/Shared/Components/Cards/ActionCard.swift` - Preview
- `Views/Shared/Components/Loading/LoadingStateView.swift` - Preview
- `Views/Shared/Components/Loading/ErrorStateView.swift` - Preview (2 occurrences)
- `Views/VisualPlanning/MoodBoard/GeneratorSteps/PreviewStepView.swift` - Preview (2 occurrences)
- `Views/VisualPlanning/Search/Components/ColorPaletteSearchResultCard.swift` - Preview
- `Views/VisualPlanning/Search/Components/SeatingChartSearchResultCard.swift` - Preview
- `Views/VisualPlanning/Search/Components/MoodBoardSearchResultCard.swift` - Preview
- `Views/Auth/CredentialsErrorView.swift` - Preview
- `Views/Vendors/AddVendorView.swift` - Preview

**Recommendation:** Remove these TODOs and replace with empty closures or simple print statements without the TODO comment.

### 2. Incomplete Implementations (High Priority - Needs Implementation)

#### A. Add Subcategory Feature
**File:** `Views/Settings/Sections/BudgetCategoriesSettingsView.swift`  
**Line:** ~382  
**Code:**
```swift
Button("Add Subcategory") {
    // TODO: Add subcategory with this as parent
}
```

**Context:** In the folder row menu, there's a button to add a subcategory but it's not implemented.

**Impact:** Medium - Feature is exposed in UI but doesn't work

**Recommendation:** Implement the action to open `SettingsAddCategoryView` with the parent category pre-selected.

**Proposed Fix:**
```swift
Button("Add Subcategory") {
    // Create a new category with this as parent
    editingCategory = BudgetCategory(
        id: UUID(),
        coupleId: category.coupleId,
        categoryName: "",
        parentCategoryId: category.id,  // Set parent
        allocatedAmount: 0,
        spentAmount: 0,
        typicalPercentage: nil,
        priorityLevel: 1,
        isEssential: false,
        notes: nil,
        forecastedAmount: 0,
        confidenceLevel: 0.8,
        lockedAllocation: false,
        description: nil,
        createdAt: Date(),
        updatedAt: nil
    )
}
```

Or better yet, create a dedicated sheet state for adding subcategories.

#### B. False Positives (Not actual TODOs)
The search also picked up method names containing "toDomain" which are not TODO comments. These can be ignored.

## Action Plan

### Phase 1: Fix Critical TODOs (Priority 1)
- [ ] Implement "Add Subcategory" functionality in `BudgetCategoriesSettingsView.swift`

### Phase 2: Clean Up Preview TODOs (Priority 2)
- [ ] Remove all "TODO: Implement action" comments from preview code
- [ ] Replace with simple empty closures or remove comments entirely

### Phase 3: Establish TODO Policy (Priority 3)
- [ ] Document TODO hygiene policy in `best_practices.md`
- [ ] Add SwiftLint rule to flag TODOs older than 30 days
- [ ] Require GitHub issues for any TODO that will take more than a day to implement

## Recommendations

1. **Immediate:** Fix the "Add Subcategory" button implementation
2. **Short-term:** Clean up all preview TODOs in a single commit
3. **Long-term:** Establish and enforce TODO hygiene policy

## Notes

- Most TODOs are harmless preview code placeholders
- Only 1 real incomplete implementation found
- Code quality is generally good with minimal technical debt from TODOs
