# 🔧 Component Extraction Quick Reference Guide

## Purpose

This guide provides quick, actionable steps for extracting components from large view files, based on proven patterns from Phase 3 refactoring.

---

## 🎯 When to Extract Components

### File Size Triggers
- ✅ File exceeds 300 lines
- ✅ File exceeds 500 lines (high priority)
- ✅ File exceeds 700 lines (urgent)

### Code Quality Triggers
- ✅ Multiple responsibilities in single file
- ✅ Difficult to navigate (excessive scrolling)
- ✅ Hard to test specific functionality
- ✅ Frequent merge conflicts
- ✅ Mixed UI and business logic

---

## 📋 Extraction Process (30-60 minutes)

### Step 1: Analyze (5 minutes)

**Questions to ask:**
1. What are the main sections of this view?
2. Which components are reusable?
3. What business logic can be separated?
4. Are there repeated patterns?

**Create a list:**
```
Example for MoneyOwedView:
- Summary cards (reusable)
- Filter controls (reusable)
- Charts (reusable)
- Row components (reusable)
- Types/enums (shared)
- Computed properties (logic)
```

---

### Step 2: Choose Pattern (2 minutes)

| If your file has... | Use this pattern | Example |
|---------------------|------------------|---------|
| Many UI components | Component Extraction by Type | MoneyOwedView |
| Complex business logic | Extension-Based Separation | BudgetDevelopmentView |
| Multiple features | Feature-Based Organization | ExportViews |
| Nested components | Hierarchical Structure | MoodBoardListView |

---

### Step 3: Create Structure (3 minutes)

**Create component directory:**
```bash
mkdir -p "Views/{Feature}/Components/{SubFeature}"
```

**Example:**
```bash
mkdir -p "Views/Budget/Components/MoneyOwed"
```

---

### Step 4: Extract Components (20-40 minutes)

#### For UI Components:

**1. Create component file:**
```swift
//
//  {Feature}{ComponentType}.swift
//  I Do Blueprint
//
//  {Brief description}
//

import SwiftUI

// MARK: - {Component Name}

struct {ComponentName}: View {
    // Properties
    let data: DataType
    
    var body: some View {
        // Component UI
    }
}
```

**2. Move component code from main file**

**3. Update main file to use component:**
```swift
// Before
VStack {
    // 50 lines of summary UI
}

// After
SummarySection(data: summaryData)
```

#### For Business Logic (Extensions):

**1. Create extension file:**
```swift
//
//  {ViewName}+{Purpose}.swift
//  I Do Blueprint
//
//  {Purpose} for {view name}
//

import Foundation

// MARK: - {Purpose}

extension {ViewName} {
    func methodName() {
        // Logic here
    }
}
```

**2. Move logic from main file**

**3. Update access control if needed:**
```swift
// Change from:
@State private var searchText = ""

// To:
@State var searchText = ""
```

---

### Step 5: Refactor Main File (5 minutes)

**Main file should only contain:**
1. State declarations
2. Body with high-level composition
3. Simple computed properties (if any)

**Example structure:**
```swift
struct MyView: View {
    // MARK: - State
    @EnvironmentObject var store: MyStore
    @State var searchText = ""
    @State var selectedItem: Item?
    
    // MARK: - Body
    var body: some View {
        VStack {
            HeaderComponent(...)
            ContentComponent(...)
            FooterComponent(...)
        }
    }
}
```

---

### Step 6: Verify (5 minutes)

**Checklist:**
- [ ] Project builds successfully
- [ ] No compilation errors
- [ ] No new warnings
- [ ] Functionality works as before
- [ ] All components accessible
- [ ] File sizes under 300 lines

**Build command:**
```bash
xcodebuild -project "I Do Blueprint.xcodeproj" \
  -scheme "I Do Blueprint" \
  -configuration Debug build
```

---

### Step 7: Document (5 minutes)

**Update file headers:**
```swift
//
//  MyView.swift
//  I Do Blueprint
//
//  Main view for {feature}
//  Components are in Components/{SubFeature}/ directory
//
```

**Add MARK comments:**
```swift
// MARK: - State
// MARK: - Body
// MARK: - Sections
// MARK: - Actions
```

---

## 🎨 Pattern Templates

### Template 1: Component Extraction by Type

**Use when:** File has many distinct UI components

**Structure:**
```
Views/{Feature}/
├── MainView.swift                    (~200 lines)
└── Components/{SubFeature}/
    ├── {Feature}Types.swift          (~50 lines)
    ├── {Feature}Summary.swift        (~120 lines)
    ├── {Feature}Filters.swift        (~80 lines)
    ├── {Feature}Charts.swift         (~100 lines)
    └── {Feature}Row.swift            (~150 lines)
```

**Main file pattern:**
```swift
struct MainView: View {
    @State var searchText = ""
    @State var filterOption: FilterOption = .all
    
    var body: some View {
        VStack {
            SummarySection(data: summaryData)
            FiltersSection(filter: $filterOption)
            ChartsSection(data: chartData)
            
            ForEach(filteredItems) { item in
                RowComponent(item: item)
            }
        }
    }
}
```

---

### Template 2: Extension-Based Separation

**Use when:** File has complex business logic

**Structure:**
```
Views/{Feature}/
├── MainView.swift                    (~150 lines)
└── Components/{SubFeature}/
    ├── {Feature}Types.swift          (~50 lines)
    ├── {Feature}Computed.swift       (~100 lines)
    ├── {Feature}Actions.swift        (~150 lines)
    └── {Feature}Helpers.swift        (~80 lines)
```

**Extension pattern:**
```swift
// MainView+Computed.swift
extension MainView {
    var filteredItems: [Item] {
        // Filtering logic
    }
    
    var totalAmount: Double {
        // Calculation logic
    }
}

// MainView+Actions.swift
extension MainView {
    func loadData() async {
        // Loading logic
    }
    
    func saveData() async {
        // Saving logic
    }
}
```

---

### Template 3: Feature-Based Organization

**Use when:** File handles multiple distinct features

**Structure:**
```
Views/{Feature}/
├── MainView.swift                    (~30 lines)
└── Components/
    ├── Feature1Components.swift      (~200 lines)
    ├── Feature2Components.swift      (~150 lines)
    ├── Feature3Components.swift      (~180 lines)
    └── SupportingViews.swift         (~50 lines)
```

**Main file pattern:**
```swift
// MainView.swift becomes documentation/re-export
//
//  MainView.swift
//  I Do Blueprint
//
//  Central import point for {feature} views
//
// Components are organized in the Components/ subdirectory:
//
// - Feature1Components.swift
//   - Feature1View
//   - Feature1DetailView
//
// - Feature2Components.swift
//   - Feature2View
//   - Feature2DetailView
//
```

---

### Template 4: Hierarchical Structure

**Use when:** Components have clear hierarchy

**Structure:**
```
Views/{Feature}/
├── MainView.swift                    (~200 lines)
└── Components/{SubFeature}/
    ├── Types.swift                   (~40 lines) - Base types
    ├── Helpers.swift                 (~50 lines) - Helper functions
    ├── CardView.swift                (~150 lines) - Uses types
    ├── RowView.swift                 (~110 lines) - Uses types
    └── Components.swift              (~180 lines) - Uses all above
```

**Dependency order:**
1. Types (no dependencies)
2. Helpers (uses types)
3. Basic components (uses types + helpers)
4. Complex components (uses everything)
5. Main view (uses complex components)

---

## 🔍 Common Issues & Solutions

### Issue 1: "Cannot find type in scope"

**Cause:** Missing import or wrong file location

**Solution:**
```swift
// Add to component file
import SwiftUI
import Foundation // if using Foundation types
```

---

### Issue 2: "Property is inaccessible due to 'private' protection level"

**Cause:** Extension can't access private state

**Solution:**
```swift
// Change from:
@State private var searchText = ""

// To:
@State var searchText = ""
```

---

### Issue 3: "Cannot find '{ComponentName}' in scope"

**Cause:** Component file not added to Xcode project

**Solution:**
1. Right-click on Components folder in Xcode
2. Add Files to "I Do Blueprint"
3. Select your component file
4. Ensure "Add to targets" is checked

---

### Issue 4: Duplicate function names

**Cause:** Same function exists in multiple files

**Solution:**
```swift
// Option 1: Use Swift's built-in formatters
Text(date, style: .date)

// Option 2: Make function more specific
func formatDateForDisplay(_ date: Date) -> String

// Option 3: Remove duplicate, use shared utility
```

---

### Issue 5: Component needs too many parameters

**Cause:** Component is too tightly coupled

**Solution:**
```swift
// Before (too many parameters)
MyComponent(
    param1: value1,
    param2: value2,
    param3: value3,
    param4: value4,
    param5: value5
)

// After (use data model)
struct MyComponentData {
    let param1: Type1
    let param2: Type2
    let param3: Type3
    let param4: Type4
    let param5: Type5
}

MyComponent(data: componentData)
```

---

## 📊 Success Criteria

### File Size
- ✅ Main file: <300 lines
- ✅ Component files: <250 lines each
- ✅ Extension files: <200 lines each

### Code Quality
- ✅ Clear separation of concerns
- ✅ Single responsibility per file
- ✅ Reusable components
- ✅ Easy to navigate

### Build Status
- ✅ No compilation errors
- ✅ No new warnings
- ✅ All tests passing
- ✅ Functionality preserved

---

## 🎯 Quick Checklist

Before starting:
- [ ] File exceeds 300 lines
- [ ] Identified component groups
- [ ] Chosen extraction pattern
- [ ] Created component directory

During extraction:
- [ ] Created component files
- [ ] Moved code to components
- [ ] Updated main file
- [ ] Fixed access control
- [ ] Added MARK comments

After extraction:
- [ ] Project builds successfully
- [ ] No errors or warnings
- [ ] Functionality works
- [ ] Files under 300 lines
- [ ] Documentation updated

---

## 📚 Examples

### Example 1: Simple Component Extraction

**Before (500 lines):**
```swift
struct MyView: View {
    var body: some View {
        VStack {
            // Header (50 lines)
            HStack {
                Text("Title")
                // ... more UI
            }
            
            // Content (400 lines)
            ScrollView {
                // ... lots of UI
            }
        }
    }
}
```

**After (150 lines main + 2 components):**
```swift
// MyView.swift (150 lines)
struct MyView: View {
    var body: some View {
        VStack {
            HeaderComponent(title: "Title")
            ContentComponent(data: contentData)
        }
    }
}

// HeaderComponent.swift (50 lines)
struct HeaderComponent: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
            // ... header UI
        }
    }
}

// ContentComponent.swift (400 lines)
struct ContentComponent: View {
    let data: ContentData
    var body: some View {
        ScrollView {
            // ... content UI
        }
    }
}
```

---

### Example 2: Extension-Based Extraction

**Before (600 lines):**
```swift
struct MyView: View {
    @State private var items: [Item] = []
    
    var body: some View {
        // UI (200 lines)
    }
    
    // Computed properties (100 lines)
    private var filteredItems: [Item] { ... }
    private var totalAmount: Double { ... }
    
    // Actions (300 lines)
    private func loadData() async { ... }
    private func saveData() async { ... }
}
```

**After (200 lines main + 2 extensions):**
```swift
// MyView.swift (200 lines)
struct MyView: View {
    @State var items: [Item] = []
    
    var body: some View {
        // UI only
    }
}

// MyView+Computed.swift (100 lines)
extension MyView {
    var filteredItems: [Item] { ... }
    var totalAmount: Double { ... }
}

// MyView+Actions.swift (300 lines)
extension MyView {
    func loadData() async { ... }
    func saveData() async { ... }
}
```

---

## 🚀 Pro Tips

1. **Start with types** - Extract enums and data structures first
2. **Extract bottom-up** - Start with leaf components, work up to containers
3. **Test frequently** - Build after each extraction
4. **Keep it simple** - Don't over-engineer, follow proven patterns
5. **Document as you go** - Add comments and MARK sections
6. **Reuse existing patterns** - Look at Phase 3 examples
7. **Ask for help** - Reference this guide and Phase 3 summary

---

## 📖 Additional Resources

- `PHASE_3_REFACTORING_SUMMARY.md` - Detailed patterns and examples
- `best_practices.md` - Project conventions
- `COMPONENTS_README.md` - Component library guide
- Phase 3 refactored files - Real-world examples

---

**Version:** 1.0  
**Last Updated:** January 2025  
**Status:** Complete
