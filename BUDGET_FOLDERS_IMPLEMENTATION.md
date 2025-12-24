# Budget Folders Implementation Guide

## Overview

This document describes the implementation of hierarchical folder support for budget items in the I Do Blueprint application. The feature allows users to organize budget items into folders with up to 3 levels of nesting, with drag-and-drop support for easy reorganization.

## Implementation Status

### ✅ Completed Phases

#### Phase 1: Database Schema
**File**: `supabase/migrations/add_budget_folder_support.sql`

Added columns to `budget_development_items`:
- `parent_folder_id` (uuid) - Self-referencing foreign key
- `is_folder` (boolean) - Identifies folders vs items
- `display_order` (integer) - For sorting within parent
- `is_expanded` (boolean) - UI state persistence

Created database functions:
- `get_folder_descendants(folder_id)` - Returns all descendants with level
- `calculate_folder_total(folder_id)` - Returns aggregated totals

Added constraints:
- Folders cannot have budget amounts
- Proper indexing for performance

#### Phase 2: Domain Models
**File**: `I Do Blueprint/Domain/Models/Budget/Budget.swift`

Extended `BudgetItem` struct:
- Added folder-related fields
- Custom initializer with defaults
- Factory method: `createFolder()`

Created `BudgetFolder` helper struct:
- `calculateTotalWithoutTax(allItems:)` - Recursive calculation
- `calculateTotalTax(allItems:)` - Recursive calculation
- `calculateTotalWithTax(allItems:)` - Recursive calculation
- `getAllDescendantItems(allItems:)` - Returns non-folder descendants
- `getHierarchyLevel(allItems:)` - Returns depth level

Added `BudgetItem` extensions:
- `getHierarchyLevel(allItems:)` - Calculate item depth
- `canMoveTo(folderId:allItems:)` - Validates moves (prevents circular refs, enforces max depth 3)
- `getMaxDescendantDepth(allItems:)` - Helper for depth validation

#### Phase 3: Repository Layer
**Files**: 
- `I Do Blueprint/Domain/Repositories/Protocols/BudgetRepositoryProtocol.swift`
- `I Do Blueprint/Domain/Repositories/Live/LiveBudgetRepository.swift`
- `I Do BlueprintTests/Helpers/MockRepositories.swift`

Added 9 folder operations to protocol:
1. `createFolder(name:scenarioId:parentFolderId:displayOrder:)` - Create new folder
2. `moveItemToFolder(itemId:targetFolderId:displayOrder:)` - Move item/folder
3. `updateDisplayOrder(items:)` - Batch reorder for drag-and-drop
4. `toggleFolderExpansion(folderId:isExpanded:)` - Toggle UI state
5. `fetchBudgetItemsHierarchical(scenarioId:)` - Fetch with hierarchy
6. `calculateFolderTotals(folderId:)` - Get folder totals
7. `canMoveItem(itemId:toFolder:)` - Validate move operation
8. `deleteFolder(folderId:deleteContents:)` - Delete folder (cascade or move children)

Implemented in:
- `LiveBudgetRepository` - Production implementation with Supabase
- `MockBudgetRepository` - Test implementation

Features:
- Validation logic to prevent circular references
- Depth limit enforcement (max 3 levels)
- Optimistic updates with proper error handling
- Cache management
- Database function integration for efficient total calculations

#### Phase 4: Store Layer
**File**: `I Do Blueprint/Services/Stores/BudgetStoreV2.swift`

Added folder operations to `BudgetStoreV2`:
- `createFolder(name:scenarioId:parentFolderId:displayOrder:)` - Create folder
- `moveItemToFolder(itemId:targetFolderId:displayOrder:)` - Move item
- `updateDisplayOrder(items:)` - Batch reorder
- `toggleFolderExpansion(folderId:isExpanded:)` - Toggle expansion
- `fetchBudgetItemsHierarchical(scenarioId:)` - Fetch hierarchical
- `calculateFolderTotals(folderId:)` - Calculate totals (DB call)
- `canMoveItem(itemId:toFolder:)` - Validate move
- `deleteFolder(folderId:deleteContents:)` - Delete folder

Helper methods:
- `buildHierarchy(from:)` - Build tree structure from flat array
- `getChildren(of:from:)` - Get direct children
- `getAllDescendants(of:from:)` - Get all descendants recursively
- `calculateLocalFolderTotals(folderId:allItems:)` - Calculate without DB call

Features:
- Error handling with `ErrorHandler`
- Logging with `AppLogger`
- Proper async/await patterns

#### Phase 5: UI Components
**Files**:
- `I Do Blueprint/Views/Budget/Components/BudgetFolderRow.swift`
- `I Do Blueprint/Views/Budget/Components/BudgetItemRowEnhanced.swift`
- `I Do Blueprint/Views/Budget/Components/BudgetHierarchyView.swift`

**BudgetFolderRow**:
- Displays folder with expand/collapse button
- Shows calculated totals
- Hover actions menu (rename, delete)
- Drag-and-drop support
- Accessibility labels and hints
- Visual indentation for hierarchy levels

**BudgetItemRowEnhanced**:
- Enhanced item row with drag handle
- Category badge display
- Hover actions menu
- Drag-and-drop support
- Visual indentation for hierarchy levels

**BudgetHierarchyView**:
- Main hierarchical view component
- Recursive rendering of folders and items
- Create/rename/delete folder dialogs
- Loading and error states
- Empty state handling
- Drag-and-drop integration

#### Phase 6: Drag-and-Drop
**File**: `I Do Blueprint/Views/Budget/Components/DragDropManager.swift`

**DragDropManager** class:
- Manages drag state (`draggedItem`, `dropTarget`, `dropPosition`)
- Validates drop operations
- Prevents circular references
- Enforces depth limits
- Provides visual feedback

**Drop validation**:
- Can't drop on itself
- Can only drop inside folders
- Checks for circular references
- Validates depth limits (max 3 levels)

**View extensions**:
- `budgetItemDraggable(item:dragManager:)` - Make view draggable
- `budgetItemDropTarget(targetItem:dragManager:allItems:onDrop:)` - Make view drop target

**Visual feedback**:
- `DropIndicatorView` - Shows drop position (above/below/inside)
- Hover highlighting for drop targets

#### Phase 7: Business Logic Integration
**File**: `I Do Blueprint/Views/Budget/Components/BudgetOverviewWithFolders.swift`

**BudgetOverviewWithFolders**:
- Shows folders at top level
- Expandable to show items
- Calculates and displays totals
- Supports nested hierarchy
- Loading/error/empty states

**FolderOverviewRow**:
- Compact folder display for overview
- Shows aggregated totals
- Expand/collapse functionality
- Hover effects

**ItemOverviewRow**:
- Item display within folders
- Category badges
- Proper indentation

## Architecture Decisions

### 1. Self-Referencing Foreign Key
Used `parent_folder_id` to create a tree structure in a single table. This approach:
- ✅ Simplifies queries (single table)
- ✅ Maintains referential integrity
- ✅ Supports unlimited depth (constrained by business logic)
- ❌ Requires recursive queries for deep hierarchies

### 2. Database Functions for Aggregation
Created PostgreSQL functions for folder totals:
- ✅ Efficient server-side calculation
- ✅ Consistent results across clients
- ✅ Reduces network traffic
- ❌ Requires database migration for changes

### 3. Client-Side Hierarchy Building
Built tree structure in Swift rather than database:
- ✅ Flexible rendering options
- ✅ Easy to add UI features (expand/collapse)
- ✅ Better performance for small datasets
- ❌ More memory usage for large datasets

### 4. Optimistic Updates with Rollback
Implemented optimistic UI updates:
- ✅ Immediate user feedback
- ✅ Better perceived performance
- ✅ Graceful error handling
- ❌ More complex state management

### 5. Depth Limit of 3 Levels
Enforced maximum depth:
- ✅ Prevents overly complex hierarchies
- ✅ Maintains UI usability
- ✅ Simplifies validation logic
- ❌ May be limiting for some use cases

## Usage Examples

### Creating a Folder

```swift
// In a view with access to budgetStore
Task {
    do {
        let folder = try await budgetStore.createFolder(
            name: "Venue & Catering",
            scenarioId: currentScenarioId,
            parentFolderId: nil, // Root level
            displayOrder: 0
        )
        print("Created folder: \(folder.itemName)")
    } catch {
        print("Error creating folder: \(error)")
    }
}
```

### Moving an Item to a Folder

```swift
Task {
    do {
        try await budgetStore.moveItemToFolder(
            itemId: itemToMove.id,
            targetFolderId: targetFolder.id,
            displayOrder: 0
        )
        print("Item moved successfully")
    } catch {
        print("Error moving item: \(error)")
    }
}
```

### Calculating Folder Totals

```swift
// Using database function (async)
Task {
    do {
        let totals = try await budgetStore.calculateFolderTotals(folderId: folder.id)
        print("Total: \(totals.withTax)")
    } catch {
        print("Error calculating totals: \(error)")
    }
}

// Using local calculation (sync)
let totals = budgetStore.calculateLocalFolderTotals(
    folderId: folder.id,
    allItems: budgetItems
)
print("Total: \(totals.withTax)")
```

### Validating a Move

```swift
Task {
    let canMove = await budgetStore.canMoveItem(
        itemId: draggedItem.id,
        toFolder: targetFolder.id
    )
    
    if canMove {
        // Perform the move
    } else {
        // Show error message
    }
}
```

### Deleting a Folder

```swift
Task {
    do {
        // Option 1: Move children to parent
        try await budgetStore.deleteFolder(
            folderId: folder.id,
            deleteContents: false
        )
        
        // Option 2: Delete all contents
        try await budgetStore.deleteFolder(
            folderId: folder.id,
            deleteContents: true
        )
    } catch {
        print("Error deleting folder: \(error)")
    }
}
```

## Integration with Existing Views

### Budget Development View

Replace the flat item list with `BudgetHierarchyView`:

```swift
// Before
BudgetItemsList(items: budgetItems)

// After
BudgetHierarchyView(
    budgetStore: budgetStore,
    scenarioId: currentScenario.id
)
```

### Budget Overview View

Replace the flat overview with `BudgetOverviewWithFolders`:

```swift
// Before
BudgetOverviewView(items: budgetItems)

// After
BudgetOverviewWithFolders(
    budgetStore: budgetStore,
    scenarioId: currentScenario.id
)
```

## Testing

### Unit Tests

Test the folder operations in `BudgetStoreV2Tests`:

```swift
@MainActor
final class BudgetFolderTests: XCTestCase {
    var mockRepository: MockBudgetRepository!
    var store: BudgetStoreV2!
    
    override func setUp() async throws {
        mockRepository = MockBudgetRepository()
        store = await withDependencies {
            $0.budgetRepository = mockRepository
        } operation: {
            BudgetStoreV2()
        }
    }
    
    func test_createFolder_success() async throws {
        // Given
        let folderName = "Test Folder"
        
        // When
        let folder = try await store.createFolder(
            name: folderName,
            scenarioId: "test-scenario",
            parentFolderId: nil,
            displayOrder: 0
        )
        
        // Then
        XCTAssertEqual(folder.itemName, folderName)
        XCTAssertTrue(folder.isFolder)
        XCTAssertEqual(mockRepository.budgetItems.count, 1)
    }
    
    func test_moveItem_preventsCircularReference() async throws {
        // Given
        let parentFolder = try await store.createFolder(
            name: "Parent",
            scenarioId: "test",
            parentFolderId: nil,
            displayOrder: 0
        )
        
        let childFolder = try await store.createFolder(
            name: "Child",
            scenarioId: "test",
            parentFolderId: parentFolder.id,
            displayOrder: 0
        )
        
        // When/Then - Should fail
        do {
            try await store.moveItemToFolder(
                itemId: parentFolder.id,
                targetFolderId: childFolder.id,
                displayOrder: 0
            )
            XCTFail("Should have thrown error")
        } catch {
            // Expected
        }
    }
    
    func test_calculateFolderTotals() async throws {
        // Given
        let folder = try await store.createFolder(
            name: "Test Folder",
            scenarioId: "test",
            parentFolderId: nil,
            displayOrder: 0
        )
        
        let item1 = BudgetItem(
            itemName: "Item 1",
            vendorEstimateWithoutTax: 100,
            taxRate: 0.10,
            vendorEstimateWithTax: 110,
            coupleId: "test",
            parentFolderId: folder.id
        )
        mockRepository.budgetItems.append(item1)
        
        // When
        let totals = try await store.calculateFolderTotals(folderId: folder.id)
        
        // Then
        XCTAssertEqual(totals.withoutTax, 100)
        XCTAssertEqual(totals.tax, 10)
        XCTAssertEqual(totals.withTax, 110)
    }
}
```

### UI Tests

Test the drag-and-drop functionality:

```swift
final class BudgetFolderUITests: XCTestCase {
    func test_dragItemToFolder() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to budget development
        app.buttons["Budget"].tap()
        app.buttons["Development"].tap()
        
        // Create a folder
        app.buttons["New Folder"].tap()
        app.textFields["Folder Name"].typeText("Test Folder")
        app.buttons["Create"].tap()
        
        // Drag an item to the folder
        let item = app.staticTexts["Wedding Venue"]
        let folder = app.staticTexts["Test Folder"]
        
        item.press(forDuration: 0.5, thenDragTo: folder)
        
        // Verify item is now in folder
        folder.tap() // Expand folder
        XCTAssertTrue(app.staticTexts["Wedding Venue"].exists)
    }
}
```

## Performance Considerations

### Database Queries

1. **Folder Totals**: Use the database function for accurate, server-side calculation
2. **Hierarchy Fetching**: Single query fetches all items, hierarchy built client-side
3. **Caching**: Repository caches results for 60 seconds

### UI Rendering

1. **LazyVStack**: Only renders visible items
2. **Local Calculations**: Use `calculateLocalFolderTotals` for UI updates
3. **Optimistic Updates**: Immediate UI feedback, async persistence

### Memory Usage

1. **Flat Array**: All items stored in single array
2. **Hierarchy Building**: Temporary dictionaries for tree construction
3. **Expanded State**: Set of folder IDs (minimal memory)

## Security Considerations

1. **Multi-Tenant Isolation**: All queries filtered by `couple_id`
2. **RLS Policies**: Database enforces row-level security
3. **Validation**: Client and server-side validation for moves
4. **Depth Limits**: Prevents malicious deep nesting

## Future Enhancements

### Potential Improvements

1. **Folder Templates**: Pre-defined folder structures
2. **Bulk Operations**: Move multiple items at once
3. **Folder Colors**: Visual categorization
4. **Folder Icons**: Custom icons for folders
5. **Search**: Search within folders
6. **Filters**: Filter by folder
7. **Sorting**: Custom sort orders within folders
8. **Permissions**: Folder-level access control
9. **Archiving**: Archive entire folders
10. **Export**: Export folder structure

### Known Limitations

1. **Maximum Depth**: Limited to 3 levels
2. **No Folder Sharing**: Folders are scenario-specific
3. **No Folder Metadata**: No description, tags, etc.
4. **No Folder History**: No audit trail for folder changes

## Troubleshooting

### Common Issues

**Issue**: Items not appearing in folder after move
- **Solution**: Check cache invalidation, refresh the view

**Issue**: Circular reference error
- **Solution**: Validate move before attempting, use `canMoveItem`

**Issue**: Depth limit exceeded
- **Solution**: Flatten hierarchy or reorganize structure

**Issue**: Totals not updating
- **Solution**: Ensure cache is invalidated after item changes

## Migration Guide

### Applying the Database Migration

```bash
# Using Supabase CLI
supabase db push

# Or manually apply the SQL file
psql -h your-db-host -U your-user -d your-db -f supabase/migrations/add_budget_folder_support.sql
```

### Updating Existing Data

Existing budget items will have `parent_folder_id = NULL` and `is_folder = false` by default, so they will appear at the root level. No data migration is required.

### Rollback Plan

If needed, the migration can be rolled back:

```sql
-- Remove columns
ALTER TABLE budget_development_items 
DROP COLUMN parent_folder_id,
DROP COLUMN is_folder,
DROP COLUMN display_order,
DROP COLUMN is_expanded;

-- Drop functions
DROP FUNCTION IF EXISTS get_folder_descendants(uuid);
DROP FUNCTION IF EXISTS calculate_folder_total(uuid);

-- Drop indexes
DROP INDEX IF EXISTS idx_budget_items_parent_folder;
DROP INDEX IF EXISTS idx_budget_items_display_order;
```

## Conclusion

The budget folders feature is now fully implemented with:
- ✅ Database schema with proper constraints
- ✅ Domain models with validation logic
- ✅ Repository layer with full CRUD operations
- ✅ Store layer with business logic
- ✅ UI components with drag-and-drop
- ✅ Integration with existing views
- ✅ Comprehensive error handling
- ✅ Performance optimizations
- ✅ Security measures

The feature is ready for testing and deployment.
