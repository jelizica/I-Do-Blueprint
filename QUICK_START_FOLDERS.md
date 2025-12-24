# Budget Folders - Quick Start Guide

## ✅ Status: READY TO TEST

Everything is implemented and integrated. Just open Xcode and test!

---

## 🚀 Quick Test (5 minutes)

### 1. Open & Build
```bash
open "/Users/jessicaclark/Development/nextjs-projects/I Do Blueprint/I Do Blueprint.xcodeproj"
```
Press `Cmd + B` to build

### 2. Run Tests
Press `Cmd + U` to run all tests
✅ All tests should pass

### 3. Run App
Press `Cmd + R` to launch app

### 4. Test Folders
1. Navigate to **Budget → Development**
2. Look for **List/Folders toggle** at top
3. Switch to **Folders** view
4. Click **New Folder** button
5. Create a folder named "Venue"
6. Click **Add Item** to create a budget item
7. **Drag** the item onto the folder
8. ✅ Item moves into folder
9. ✅ Folder shows total amount

---

## 🎯 What You Get

### User Features
- ✅ **Organize** budget items into folders
- ✅ **Drag & drop** to reorganize
- ✅ **Auto-calculate** folder totals
- ✅ **Nest folders** up to 3 levels
- ✅ **Expand/collapse** folders
- ✅ **Switch views** between list and folders

### Technical Features
- ✅ **Database migration** applied
- ✅ **Full CRUD** operations
- ✅ **Validation** (no circular refs, depth limits)
- ✅ **Caching** for performance
- ✅ **Error handling** throughout
- ✅ **Unit tests** (15+ tests)
- ✅ **Feature flag** for control

---

## 📁 Key Files

### New Components
```
Views/Budget/Components/
├── BudgetFolderRow.swift          # Folder display
├── BudgetItemRowEnhanced.swift    # Item with drag support
├── BudgetHierarchyView.swift      # Main folder view
├── DragDropManager.swift          # Drag-and-drop logic
├── BudgetOverviewWithFolders.swift # Overview with folders
└── BudgetItemsTableEnhanced.swift # Switchable table
```

### Modified Files
```
Domain/Models/Budget/Budget.swift           # Added folder fields
Domain/Repositories/.../BudgetRepository... # Added folder methods
Services/Stores/BudgetStoreV2.swift         # Added folder operations
Views/Budget/BudgetDevelopmentView.swift    # Uses enhanced table
```

---

## 🔧 Configuration

### Feature Flag
**Location**: `I Do Blueprint/Core/Configuration/FeatureFlags.swift`

**Current Setting**: Enabled in DEBUG mode

**To Disable**:
```swift
static var budgetFoldersEnabled: Bool {
    #if DEBUG
    return false  // Change to false
    #else
    return UserDefaults.standard.bool(forKey: "feature_budget_folders")
    #endif
}
```

---

## 🧪 Testing Checklist

- [ ] App builds without errors
- [ ] Unit tests pass (Cmd + U)
- [ ] App launches successfully
- [ ] Can navigate to Budget Development
- [ ] See List/Folders toggle
- [ ] Can create a folder
- [ ] Can add items to folder
- [ ] Can drag items between folders
- [ ] Folder totals calculate correctly
- [ ] Can expand/collapse folders
- [ ] Can delete folders
- [ ] Can nest folders (up to 3 levels)

---

## 🎨 UI Overview

```
Budget Development View
├── [List | Folders] ← Toggle
├── [New Folder] [Add Item] ← Actions
└── Content Area
    ├── 📁 Venue & Catering ($15,000)
    │   ├── 📄 Venue Rental ($5,000)
    │   ├── 📄 Catering ($8,000)
    │   └── 📄 Bar Service ($2,000)
    ├── 📁 Photography ($3,500)
    │   └── 📄 Photographer ($3,500)
    └── 📄 Standalone Item ($1,000)
```

---

## 💡 Tips

### Creating Folders
- Use descriptive names (e.g., "Venue & Catering")
- Group related items together
- Don't nest too deep (max 3 levels)

### Organizing Items
- Drag items onto folders to move them
- Drag items to root to remove from folder
- Use display order to sort within folders

### Calculating Totals
- Folders auto-calculate from contents
- Includes nested folder contents
- Updates in real-time

---

## 🐛 Common Issues

**Q: Toggle doesn't appear**
A: Feature flag is disabled. Check `FeatureFlags.swift`

**Q: Can't create folders**
A: Make sure you're in "Folders" view mode

**Q: Drag-and-drop doesn't work**
A: Ensure you're dragging onto a folder (not an item)

**Q: Folder shows $0.00**
A: Folders themselves have no amount. Add items to see totals.

---

## 📊 Database

### Migration Applied ✅
- Table: `budget_development_items`
- Columns: `parent_folder_id`, `is_folder`, `display_order`, `is_expanded`
- Functions: `get_folder_descendants()`, `calculate_folder_total()`

### Verify in Supabase
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'budget_development_items' 
AND column_name LIKE '%folder%' OR column_name LIKE '%display%';
```

---

## 🎉 You're Ready!

**Everything is set up and ready to test.**

1. Open Xcode
2. Build & Run
3. Navigate to Budget Development
4. Start creating folders!

**Estimated Testing Time**: 15-30 minutes

---

## 📚 Full Documentation

For detailed information, see:
- `BUDGET_FOLDERS_COMPLETE.md` - Complete implementation details
- `BUDGET_FOLDERS_IMPLEMENTATION.md` - Technical architecture
- `BUDGET_FOLDERS_INTEGRATION_GUIDE.md` - Integration options
- `BUDGET_FOLDERS_PREFLIGHT_CHECKLIST.md` - Testing checklist

---

**Happy Testing! 🚀**
