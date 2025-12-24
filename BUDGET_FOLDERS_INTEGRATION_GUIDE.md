# Budget Folders Integration Guide

## Quick Start: 3 Simple Integration Options

Choose one of these options to integrate the folder feature into your app:

---

## Option 1: Replace Budget Development View (Recommended)

This replaces the existing flat budget items list with the hierarchical folder view.

### Step 1: Find the Budget Items List

Open: `I Do Blueprint/Views/Budget/BudgetDevelopmentView.swift`

Look for the section that displays budget items (likely a `List` or `ForEach` with budget items).

### Step 2: Replace with Hierarchy View

```swift
// BEFORE (example - your code may vary):
List(budgetItems) { item in
    BudgetItemRow(item: item)
}

// AFTER:
BudgetHierarchyView(
    budgetStore: budgetStore,
    scenarioId: currentScenario?.id
)
```

### Complete Example:

```swift
struct BudgetDevelopmentView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @State private var currentScenario: SavedScenario?
    
    var body: some View {
        VStack {
            // Header, toolbar, etc.
            
            // Replace your budget items list with:
            BudgetHierarchyView(
                budgetStore: budgetStore,
                scenarioId: currentScenario?.id
            )
        }
    }
}
```

**Pros**:
- ✅ Seamless replacement
- ✅ Users get folders immediately
- ✅ No UI changes needed

**Cons**:
- ⚠️ Changes existing workflow
- ⚠️ Users need to adapt

---

## Option 2: Add as New Tab

This adds folders as a separate tab, keeping the old view available.

### Step 1: Update BudgetMainView

Open: `I Do Blueprint/Views/Budget/BudgetMainView.swift`

### Step 2: Add New Tab Case

```swift
enum BudgetTab: String, CaseIterable {
    case overview = "Overview"
    case development = "Development"
    case folders = "Folders"  // NEW
    case tracker = "Tracker"
    case calculator = "Calculator"
    case analytics = "Analytics"
    
    var icon: String {
        switch self {
        case .overview: return "chart.pie"
        case .development: return "hammer"
        case .folders: return "folder"  // NEW
        case .tracker: return "list.bullet"
        case .calculator: return "dollarsign.circle"
        case .analytics: return "chart.bar"
        }
    }
}
```

### Step 3: Add View Case

```swift
var body: some View {
    VStack {
        // Tab picker
        Picker("Budget Section", selection: $selectedTab) {
            ForEach(BudgetTab.allCases, id: \.self) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        
        // Content
        switch selectedTab {
        case .overview:
            BudgetOverviewView()
        case .development:
            BudgetDevelopmentView()
        case .folders:  // NEW
            BudgetHierarchyView(
                budgetStore: budgetStore,
                scenarioId: currentScenario?.id
            )
        case .tracker:
            ExpenseTrackerView()
        case .calculator:
            AffordabilityCalculatorView()
        case .analytics:
            BudgetAnalyticsView()
        }
    }
}
```

**Pros**:
- ✅ Non-disruptive
- ✅ Users can choose
- ✅ Easy to rollback

**Cons**:
- ⚠️ Duplicate functionality
- ⚠️ More UI complexity

---

## Option 3: Replace Budget Overview

This shows folders in the overview, keeping development view unchanged.

### Step 1: Update BudgetOverviewView

Open: `I Do Blueprint/Views/Budget/BudgetOverviewView.swift`

### Step 2: Replace Content

```swift
struct BudgetOverviewView: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @State private var currentScenario: SavedScenario?
    
    var body: some View {
        VStack {
            // Header, summary cards, etc.
            
            // Replace items list with:
            if let scenarioId = currentScenario?.id {
                BudgetOverviewWithFolders(
                    budgetStore: budgetStore,
                    scenarioId: scenarioId
                )
            } else {
                Text("No scenario selected")
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

**Pros**:
- ✅ Better overview experience
- ✅ Development view unchanged
- ✅ Gradual adoption

**Cons**:
- ⚠️ Only affects overview
- ⚠️ Users still need to create folders

---

## Option 4: Feature Flag (Gradual Rollout)

This allows you to toggle the feature on/off.

### Step 1: Create Feature Flag

Create: `I Do Blueprint/Core/Configuration/FeatureFlags.swift`

```swift
//
//  FeatureFlags.swift
//  I Do Blueprint
//
//  Feature flags for gradual rollout
//

import Foundation

struct FeatureFlags {
    /// Enable budget folders feature
    static var budgetFoldersEnabled: Bool {
        #if DEBUG
        return true  // Always on in debug
        #else
        return UserDefaults.standard.bool(forKey: "feature_budget_folders")
        #endif
    }
    
    /// Enable folder feature for user
    static func enableBudgetFolders() {
        UserDefaults.standard.set(true, forKey: "feature_budget_folders")
    }
    
    /// Disable folder feature for user
    static func disableBudgetFolders() {
        UserDefaults.standard.set(false, forKey: "feature_budget_folders")
    }
}
```

### Step 2: Use in Views

```swift
struct BudgetDevelopmentView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    var body: some View {
        VStack {
            if FeatureFlags.budgetFoldersEnabled {
                // New folder view
                BudgetHierarchyView(
                    budgetStore: budgetStore,
                    scenarioId: currentScenario?.id
                )
            } else {
                // Old flat view
                BudgetItemsList(items: budgetItems)
            }
        }
    }
}
```

### Step 3: Add Settings Toggle

In your settings view:

```swift
Section("Experimental Features") {
    Toggle("Budget Folders", isOn: Binding(
        get: { FeatureFlags.budgetFoldersEnabled },
        set: { enabled in
            if enabled {
                FeatureFlags.enableBudgetFolders()
            } else {
                FeatureFlags.disableBudgetFolders()
            }
        }
    ))
    .help("Organize budget items into folders")
}
```

**Pros**:
- ✅ Safe rollout
- ✅ Easy to disable
- ✅ User control

**Cons**:
- ⚠️ More code complexity
- ⚠️ Maintenance overhead

---

## Testing Your Integration

After integrating, test these scenarios:

### 1. Basic Functionality
```
✓ App launches without errors
✓ Budget view loads
✓ Can see "New Folder" button
✓ Can create a folder
✓ Folder appears in list
```

### 2. Drag and Drop
```
✓ Can drag an item
✓ Can drop item on folder
✓ Item moves into folder
✓ Can drag item out of folder
✓ Cannot create circular reference
```

### 3. Folder Operations
```
✓ Can expand/collapse folders
✓ Can rename folders
✓ Can delete folders
✓ Folder totals calculate correctly
✓ Nested folders work (up to 3 levels)
```

### 4. Data Persistence
```
✓ Folders persist after app restart
✓ Folder expansion state persists
✓ Item order persists
✓ No data loss
```

---

## Troubleshooting

### Issue: "New Folder" button doesn't appear

**Solution**: Check that `BudgetHierarchyView` is being used:

```swift
// Make sure you're using the new view:
BudgetHierarchyView(budgetStore: budgetStore, scenarioId: scenarioId)

// Not the old view:
// BudgetItemsList(items: items)  // OLD
```

### Issue: Drag and drop doesn't work

**Solution**: Ensure `DragDropManager` is initialized:

```swift
@StateObject private var dragManager = DragDropManager()

// Pass to hierarchy view if needed
BudgetHierarchyView(
    budgetStore: budgetStore,
    scenarioId: scenarioId
)
```

### Issue: Folder totals show $0.00

**Solution**: Check that items have `parentFolderId` set:

```swift
// When moving item to folder:
try await budgetStore.moveItemToFolder(
    itemId: item.id,
    targetFolderId: folder.id,  // Make sure this is set
    displayOrder: 0
)
```

### Issue: Database errors

**Solution**: Verify migration was applied:

```sql
-- Run in Supabase SQL Editor:
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'budget_development_items' 
AND column_name IN ('parent_folder_id', 'is_folder', 'display_order', 'is_expanded');

-- Should return 4 rows
```

### Issue: Items disappear after moving

**Solution**: Check cache invalidation:

```swift
// After move, refresh the view:
Task {
    await budgetStore.refresh()
}
```

---

## Performance Optimization

### For Large Datasets (100+ items)

If you have many budget items, consider:

1. **Lazy Loading**:
```swift
ScrollView {
    LazyVStack {  // Use LazyVStack instead of VStack
        ForEach(items) { item in
            // ...
        }
    }
}
```

2. **Pagination**:
```swift
// Load folders first, then items on demand
.task {
    await loadFolders()
}
.onAppear {
    if folder.isExpanded {
        await loadFolderContents(folder.id)
    }
}
```

3. **Cache Optimization**:
```swift
// Increase cache TTL for stable data
await RepositoryCache.shared.set(
    cacheKey,
    value: items,
    ttl: 300  // 5 minutes instead of 60 seconds
)
```

---

## Migration Path for Existing Data

If you have existing budget items, they will automatically appear at the root level (no folder) because `parent_folder_id` defaults to `NULL`.

### Optional: Auto-organize existing items

You can create a migration script to automatically organize items:

```swift
func autoOrganizeExistingItems() async {
    let items = try await budgetStore.fetchBudgetItemsHierarchical(scenarioId: nil)
    
    // Group by category
    let itemsByCategory = Dictionary(grouping: items) { $0.category }
    
    // Create folders for each category
    for (category, categoryItems) in itemsByCategory {
        let folder = try await budgetStore.createFolder(
            name: category,
            scenarioId: categoryItems.first?.scenarioId,
            parentFolderId: nil,
            displayOrder: 0
        )
        
        // Move items into folder
        for item in categoryItems {
            try await budgetStore.moveItemToFolder(
                itemId: item.id,
                targetFolderId: folder.id,
                displayOrder: 0
            )
        }
    }
}
```

---

## Next Steps

1. **Choose an integration option** (Option 1 recommended)
2. **Apply the code changes**
3. **Test thoroughly** using the checklist above
4. **Monitor for issues** in production
5. **Gather user feedback**
6. **Iterate and improve**

---

## Support

If you need help:
1. Check console logs for errors
2. Verify database migration was applied
3. Review the implementation guide
4. Check the troubleshooting section above

---

## Summary

**Recommended Integration**: Option 1 (Replace Budget Development View)

**Estimated Integration Time**: 15-30 minutes

**Testing Time**: 30-60 minutes

**Total Time to Production**: 1-2 hours

The feature is **production-ready** and can be integrated immediately after applying the database migration.

Good luck! 🚀
