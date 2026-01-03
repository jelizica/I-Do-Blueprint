---
title: Unified Header with Responsive Actions Pattern
type: note
permalink: architecture/patterns/unified-header-with-responsive-actions-pattern
tags:
- swiftui
- pattern
- responsive-design
- header
- compact-window
- ellipsis-menu
- navigation
---

# Unified Header with Responsive Actions Pattern

## Problem

Management views often have multiple header components stacked vertically:
1. A **module header** with title and navigation dropdown
2. A **page header** with subtitle and action buttons (Save, Export, etc.)
3. **Configuration controls** (pickers, filters, etc.)

In compact windows, this wastes vertical space and creates visual clutter.

## Solution

Consolidate all header elements into a **single unified header** that:
- Shows module title + page subtitle in a hierarchy
- Moves action buttons into an ellipsis menu (⋯)
- Places the ellipsis menu LEFT of the navigation dropdown
- Stacks form fields vertically in compact mode

## Visual Layout

### Regular Mode (≥700px)
```
┌─────────────────────────────────────────────────────────────┐
│ Module Title                              (⋯) [▼ Page Nav]  │
│ Page Subtitle                                               │
├─────────────────────────────────────────────────────────────┤
│ [Field 1 ▼]  [Field 2 ▼]  [Field 3 ▼]  [Add]               │
└─────────────────────────────────────────────────────────────┘
```

### Compact Mode (<700px)
```
┌─────────────────────────────────────┐
│ Module Title              (⋯) [▼]   │
│ Page Subtitle                       │
├─────────────────────────────────────┤
│ Field 1                             │
│ [Picker ▼]                          │
│                                     │
│ Field 2                             │
│ [Picker ▼] [Add]                    │
└─────────────────────────────────────┘
```

## Implementation

### Step 1: Define the Unified Header Component

```swift
struct UnifiedPageHeader<ActionsContent: View>: View {
    let windowSize: WindowSize
    let moduleTitle: String
    let pageSubtitle: String
    @Binding var currentPage: PageEnum  // Your navigation enum
    
    // Optional custom actions for ellipsis menu
    let actionsContent: ActionsContent?
    
    var body: some View {
        VStack(spacing: windowSize == .compact ? Spacing.md : Spacing.lg) {
            // Title row
            titleRow
            
            // Form fields (if any)
            if windowSize == .compact {
                compactFormFields
            } else {
                regularFormFields
            }
        }
        .padding(windowSize == .compact ? Spacing.md : Spacing.lg)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var titleRow: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            // Title hierarchy
            VStack(alignment: .leading, spacing: 4) {
                Text(moduleTitle)
                    .font(Typography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(pageSubtitle)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            // Actions: ellipsis + nav dropdown
            HStack(spacing: Spacing.sm) {
                ellipsisMenu
                navigationDropdown
            }
        }
    }
}
```

### Step 2: Implement the Ellipsis Menu

```swift
private var ellipsisMenu: some View {
    Menu {
        // Primary actions
        Button(action: { Task { await onSave() } }) {
            Label(saving ? "Saving..." : "Save", systemImage: "square.and.arrow.down.fill")
        }
        .disabled(saving)
        
        Divider()
        
        // Secondary actions in submenu
        Menu("Export") {
            Section(header: Text("Local Export")) {
                Button(action: onExportJSON) {
                    Label("Export as JSON", systemImage: "doc.text")
                }
                Button(action: onExportCSV) {
                    Label("Export as CSV", systemImage: "tablecells")
                }
            }
            
            Section(header: Text("Cloud Export")) {
                // Conditional based on auth state
                if isAuthenticated {
                    Button(action: { Task { await onCloudExport() } }) {
                        Label("Upload to Cloud", systemImage: "icloud.and.arrow.up")
                    }
                } else {
                    Button(action: { Task { await onSignIn() } }) {
                        Label("Sign in", systemImage: "person.crop.circle.badge.checkmark")
                    }
                }
            }
        }
    } label: {
        Image(systemName: "ellipsis.circle")
            .font(.title3)
            .foregroundColor(AppColors.textPrimary)
    }
    .buttonStyle(.plain)
}
```

### Step 3: Implement Responsive Form Fields

```swift
@ViewBuilder
private var compactFormFields: some View {
    VStack(spacing: Spacing.lg) {
        // Each field gets full width
        VStack(alignment: .leading, spacing: 6) {
            Text("Field Label")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: Spacing.sm) {
                Picker("", selection: $selectedValue) {
                    // Options
                }
                .pickerStyle(.menu)
                
                // Optional action button
                if showActionButton {
                    actionMenu
                }
            }
        }
        
        // Additional fields stacked vertically
        // ...
    }
}

@ViewBuilder
private var regularFormFields: some View {
    HStack(spacing: Spacing.lg) {
        // Fields arranged horizontally
        VStack(alignment: .leading, spacing: 4) {
            Text("Field Label")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Picker("", selection: $selectedValue) {
                    // Options
                }
                .pickerStyle(.menu)
            }
        }
        
        // More fields...
    }
}
```

### Step 4: Handle Navigation from Child Pages

When the unified header is in a child page that needs to navigate:

```swift
struct ChildPageView: View {
    // Support both embedded and standalone usage
    var externalCurrentPage: Binding<PageEnum>?
    @State private var internalCurrentPage: PageEnum = .thisPage
    
    private var currentPage: Binding<PageEnum> {
        externalCurrentPage ?? $internalCurrentPage
    }
    
    // Two initializers
    init(currentPage: Binding<PageEnum>) {
        self.externalCurrentPage = currentPage
    }
    
    init() {
        self.externalCurrentPage = nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            UnifiedPageHeader(
                windowSize: windowSize,
                currentPage: currentPage,  // Pass the computed binding
                // ...
            )
            // Page content
        }
    }
}
```

### Step 5: Skip Parent Header for Pages with Unified Headers

In the parent hub view:

```swift
struct ModuleHubView: View {
    @State private var currentPage: PageEnum = .hub
    
    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            
            if currentPage == .hub {
                // Hub content with standard header
            } else {
                VStack(spacing: 0) {
                    // Skip header for pages with unified headers
                    if !currentPage.hasUnifiedHeader {
                        StandardModuleHeader(
                            windowSize: windowSize,
                            currentPage: $currentPage
                        )
                    }
                    
                    // Render child page
                    if currentPage == .pageWithUnifiedHeader {
                        ChildPageView(currentPage: $currentPage)
                    } else {
                        currentPage.view
                    }
                }
            }
        }
    }
}
```

## Key Design Decisions

### 1. Ellipsis Position
Place ellipsis menu **LEFT** of navigation dropdown:
- Navigation is the most common action (rightmost = easiest to reach)
- Actions are secondary (left of nav)

### 2. Spacing Constants
Use design system spacing:
- Compact: `Spacing.md` (12px) between sections
- Regular: `Spacing.lg` (16px) between sections
- Form field labels: 4-6px gap to picker

### 3. Typography Hierarchy
- Module title: `Typography.displaySmall` (bold, primary color)
- Page subtitle: `Typography.bodyRegular` (regular weight, secondary color)
- Field labels: `.caption` (secondary color)

### 4. Action Button States
Show loading states in menu labels:
```swift
Label(saving ? "Saving..." : "Save", systemImage: "...")
```

## When to Use

✅ **Use this pattern when:**
- Page has multiple action buttons (Save, Export, Upload, etc.)
- Page has configuration controls (pickers, filters)
- Page is part of a module with navigation dropdown
- Vertical space is at a premium

❌ **Don't use when:**
- Page has only 1-2 simple actions (keep inline)
- Page doesn't need navigation dropdown
- Actions need to be highly visible (e.g., primary CTA)

## Real-World Example

See `BudgetDevelopmentUnifiedHeader.swift` for a complete implementation with:
- Module title ("Budget") + page subtitle ("Budget Development")
- Ellipsis menu with Save, Upload, Export actions
- Navigation dropdown for 12 budget pages
- Scenario picker and tax rate picker as form fields
- Full compact/regular responsive layouts

## Related Patterns

- [[Table-to-Card Responsive Switcher Pattern]] - For content below the header
- [[Expandable Card Editor Pattern]] - For editing items in compact mode
- [[Management View Header Alignment Pattern]] - Original header pattern this extends
