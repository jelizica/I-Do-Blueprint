# Folder Dashboard Implementation

## Overview
Implemented folder support in the budget dashboard with hierarchical display, expand/collapse functionality, and aggregated totals.

## Changes Made

### 1. Extended `BudgetOverviewItem` Model
**File:** `I Do Blueprint/Domain/Models/Budget/BudgetOverviewItem.swift`

Added folder-related properties:
- `isFolder: Bool` - Indicates if item is a folder
- `parentFolderId: String?` - Parent folder ID (nil for top-level items)
- `displayOrder: Int` - Sort order within parent
- `isExpanded: Bool` - Expansion state from database
- `isTopLevel` computed property - Returns true if `parentFolderId == nil`

### 2. Updated Aggregation Service
**File:** `I Do Blueprint/Domain/Services/BudgetAggregationService.swift`

Modified `fetchBudgetOverview()` to include folder fields when creating `BudgetOverviewItem` instances:
```swift
BudgetOverviewItem(
    // ... existing fields
    isFolder: item.isFolder,
    parentFolderId: item.parentFolderId,
    displayOrder: item.displayOrder,
    isExpanded: item.isExpanded
)
```

### 3. Added Folder Expansion State
**File:** `I Do Blueprint/Views/Budget/BudgetOverviewDashboardViewV2.swift`

Added state management:
```swift
@State private var expandedFolderIds: Set<String> = []
```

Passed to child component:
```swift
BudgetOverviewItemsSection(
    // ... existing params
    expandedFolderIds: $expandedFolderIds,
    // ...
)
```

### 4. Updated Budget Items Section
**File:** `I Do Blueprint/Views/Budget/Components/BudgetOverviewItemsSection.swift`

**Key Features:**
- **Hierarchical Filtering**: Shows only top-level items (no parent) initially
- **Folder Aggregation**: Calculates total budgeted, spent, and effective spent from all child items
- **Expand/Collapse**: Toggles visibility of child items with animation
- **Child Item Display**: Shows child items as full cards below folder when expanded
- **Indentation**: Child items are indented 20pt to show hierarchy

**Helper Methods:**
```swift
private var topLevelItems: [BudgetOverviewItem] {
    filteredBudgetItems
        .filter { $0.isTopLevel }
        .sorted { $0.displayOrder < $1.displayOrder }
}

private func getChildren(of folderId: String) -> [BudgetOverviewItem] {
    budgetItems
        .filter { $0.parentFolderId == folderId }
        .sorted { $0.displayOrder < $1.displayOrder }
}

private func getFolderTotals(folderId: String) -> (budgeted: Double, spent: Double, effectiveSpent: Double) {
    let children = getChildren(of: folderId)
    let budgeted = children.reduce(0.0) { $0 + $1.budgeted }
    let spent = children.reduce(0.0) { $0 + $1.spent }
    let effectiveSpent = children.reduce(0.0) { $0 + $1.effectiveSpent }
    return (budgeted, spent, effectiveSpent)
}
```

### 5. Created Folder Card Component
**File:** `I Do Blueprint/Views/Budget/Components/FolderBudgetCard.swift`

**Visual Distinctions:**
1. **Folder Icon** (📁) - Orange folder icon in header
2. **"FOLDER" Badge** - Orange gradient badge with white text
3. **Item Count Badge** - Shows number of child items
4. **Expand/Collapse Chevron** - Orange circle icon (right arrow when collapsed, down arrow when expanded)
5. **Orange Border** - Gradient orange border around card
6. **Orange Tint** - Subtle orange background overlay
7. **Circular Progress** - Shows aggregated percentage spent
8. **Aggregated Totals** - Displays sum of all child items:
   - BUDGETED: Total budgeted amount
   - SPENT: Total spent amount
   - REMAINING: Total remaining amount

**Interaction:**
- Entire card is clickable to expand/collapse
- Smooth animation on expand/collapse
- Accessible with VoiceOver support

**Color Coding:**
- Green: < 75% spent
- Yellow: 75-90% spent
- Orange: 90-100% spent
- Red: > 100% spent (over budget)

## User Experience

### Initial View
- Only top-level items are shown (folders and non-folder items without parents)
- Folders display aggregated totals from all child items
- Folders are visually distinct with icon, badge, and orange styling

### Expanding a Folder
1. Click anywhere on the folder card (or the chevron icon)
2. Folder expands with smooth animation
3. Child items appear as full cards below the folder
4. Child items are indented 20pt to show hierarchy
5. Chevron changes from right arrow to down arrow

### Collapsing a Folder
1. Click the expanded folder card again
2. Child items fade out with animation
3. Chevron changes back to right arrow

### Empty Folders
- Empty folders (0 items) are still displayed
- Show "0 items" badge
- Can still be expanded (shows no child items)

## Table View Support

Folders also work in table view mode:
- Folder rows have orange folder icon and "FOLDER" badge
- Clicking row expands/collapses children
- Child rows are indented
- Aggregated totals shown in columns

## Accessibility

All folder cards include:
- Semantic labels: "folder name folder"
- Value: Item count, percentage spent, amounts
- Hint: "Tap to expand/collapse folder"
- Button trait for interaction

## Technical Notes

### Performance
- Child items are only rendered when folder is expanded
- Uses `LazyVGrid` for efficient rendering
- Animations are lightweight (0.2s easeInOut)

### State Management
- Expansion state stored in `Set<String>` for O(1) lookup
- State persists during filtering/searching
- State resets on scenario change

### Data Flow
1. `BudgetStoreV2` loads items with folder data
2. `BudgetOverviewDashboardViewV2` manages expansion state
3. `BudgetOverviewItemsSection` filters and displays hierarchy
4. `FolderBudgetCard` renders folder with aggregated totals
5. `CircularProgressBudgetCard` renders child items

## Testing Checklist

- [x] Folders display at top level
- [x] Folder shows aggregated totals
- [x] Folder has distinct visual styling
- [x] Expand/collapse works on click
- [x] Child items show as full cards when expanded
- [x] Child items are indented
- [x] Empty folders display correctly
- [x] Table view supports folders
- [x] Animations are smooth
- [x] Accessibility labels work
- [x] Build succeeds without errors

## Future Enhancements

Potential improvements:
1. Persist expansion state across sessions (localStorage/UserDefaults)
2. "Expand All" / "Collapse All" buttons
3. Drag-and-drop to move items between folders
4. Nested folders (folders within folders)
5. Folder color customization
6. Folder sorting options
7. Bulk operations on folder contents

## Files Modified

1. `I Do Blueprint/Domain/Models/Budget/BudgetOverviewItem.swift` - Added folder fields
2. `I Do Blueprint/Domain/Services/BudgetAggregationService.swift` - Include folder data
3. `I Do Blueprint/Views/Budget/BudgetOverviewDashboardViewV2.swift` - Added expansion state
4. `I Do Blueprint/Views/Budget/Components/BudgetOverviewItemsSection.swift` - Hierarchical display
5. `I Do Blueprint/Views/Budget/Components/FolderBudgetCard.swift` - **NEW** Folder card component

## Build Status

✅ **BUILD SUCCEEDED** - No errors, only pre-existing warnings

---

**Implementation Date:** December 24, 2025  
**Status:** Complete and tested
