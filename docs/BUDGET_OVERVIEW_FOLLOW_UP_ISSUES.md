# Budget Overview Dashboard - Follow-Up Issues

> **Created:** January 2026  
> **Related Epic:** `I Do Blueprint-0f4` - Budget Compact Views Optimization  
> **Parent Task:** `I Do Blueprint-dra` - Budget Overview Compact Window Optimization

---

## Overview

Three comprehensive Beads issues have been created for follow-up enhancements to the Budget Overview Dashboard. These issues are self-contained and can be worked on independently without requiring context from the initial implementation.

---

## Created Issues

### 1. Advanced Filter System
**Issue ID:** `I Do Blueprint-6vk`  
**Priority:** P2 (Medium)  
**Type:** Feature  
**Labels:** `budget`, `filters`, `responsive-design`, `ui`

#### Summary
Implement a comprehensive filter system for the Budget Overview Dashboard, similar to the Guest Management filter implementation. The backend filter logic already exists, but there's no UI to manage filters.

#### Key Requirements
- Filter menu accessible in both compact and regular modes
- Active filter chips displayed below search field
- Individual filter add/remove capability
- Clear All Filters button
- Filter state persistence during session
- Filters work with search (AND logic)

#### Filter Options
- Over Budget (spent > budgeted)
- Under Budget (spent < budgeted)
- On Track (within 10% of budget)
- No Expenses (no linked expenses)
- By Category/Subcategory
- By Amount Range
- Has Gifts
- Is Folder

#### Reference Implementation
- Location: `Views/Guests/GuestManagementViewV4.swift`
- Pattern: Filter menu with checkboxes, active filter chips, clear all button

#### Files to Create/Modify
- **Modify:** `BudgetOverviewUnifiedHeader.swift` (add filter menu)
- **Modify:** `BudgetOverviewDashboardViewV2.swift` (expand filter logic)
- **Create:** `BudgetFilterChip.swift` (reusable filter chip component)

---

### 2. Export Summary Feature
**Issue ID:** `I Do Blueprint-qi0`  
**Priority:** P3 (Low)  
**Type:** Feature  
**Labels:** `budget`, `export`, `pdf`, `csv`, `feature`

#### Summary
Implement export functionality for the Budget Overview Dashboard, allowing users to export budget summary data in multiple formats (PDF, CSV, JSON). Currently, the "Export Summary" button only logs to console.

#### Export Formats

**PDF Export (Primary)**
- Summary cards section (totals)
- Budget items table with all columns
- Scenario name and export date in header
- Professional formatting with app branding

**CSV Export**
- All budget items as rows
- Compatible with Excel/Google Sheets
- Summary row at top with totals

**JSON Export (Developer/Backup)**
- Complete data structure
- Scenario metadata
- All budget items with full details
- Formatted for readability

#### Export Options Dialog
- Format selection (PDF/CSV/JSON)
- Include filters toggle (export filtered view or all items)
- Destination picker (local file system)
- Progress indicator for large exports

#### Implementation Approach
- Use existing **TPPDF library** for PDF generation
- Use **NSOpenPanel** for save location picker
- Reference existing export services:
  - `Services/Export/VendorExportService.swift`
  - `Services/Export/GuestExportService.swift`

#### Files to Create/Modify
- **Create:** `Services/Export/BudgetOverviewExportService.swift`
- **Create:** `Views/Budget/Components/ExportOptionsSheet.swift`
- **Modify:** `BudgetOverviewUnifiedHeader.swift` (replace placeholder)
- **Modify:** `BudgetOverviewDashboardViewV2.swift` (add export sheet state)

---

### 3. Compact Table View with Expandable Details
**Issue ID:** `I Do Blueprint-hws`  
**Priority:** P2 (Medium)  
**Type:** Feature  
**Labels:** `budget`, `compact-window`, `table-view`, `ui`, `responsive-design`

#### Summary
Implement a simplified, non-editable table view for compact mode with expandable row details. The current full table doesn't fit well in narrow windows (under 700px), making columns cramped and difficult to read.

#### Current Problem
- Same table view shown in all window sizes
- 5 columns (Item, Category, Budgeted, Spent, Remaining) don't fit in compact mode
- Horizontal scrolling or cramped layout

#### Proposed Solution
**Compact Table View Design:**
- Simplified rows with essential info only
- Chevron icon indicates expandable state
- Tap row to expand/collapse details
- Non-editable (view-only in compact mode)
- Smooth expand/collapse animation

**Row Layout (Collapsed):**
```
[>] Item Name                    $1,000
    Category                      $850
```

**Row Layout (Expanded):**
```
[v] Item Name                    $1,000
    Category                      $850
    ─────────────────────────────────────
    Category: Reception
    Subcategory: Catering
    Budgeted: $1,000.00
    Spent: $850.00
    Remaining: $150.00
    Expenses: 3 | Gifts: 1
```

#### State Management
- Add `expandedItemIds: Set<String>` to track expanded rows
- Persist expanded state during session
- Collapse all when switching scenarios

#### Technical Details
- Use `LazyVStack` for performance with large lists
- Divider between rows
- Maintain folder expand/collapse functionality
- Support keyboard navigation (arrow keys)

#### Files to Create/Modify
- **Modify:** `BudgetOverviewItemsSection.swift` (add compactTableView)
- **Create:** `CompactBudgetItemRow.swift` (new component)

#### Design Specifications
- Padding: `Spacing.md`
- Item names: `Typography.bodyRegular`
- Secondary text: `Typography.caption`
- Spent amounts: `AppColors.Budget` colors (red/green)
- Animation: `.easeInOut(duration: 0.2)`

---

## Implementation Priority

### Recommended Order

1. **Issue I Do Blueprint-hws** (P2) - Compact Table View
   - **Why first:** Completes the compact mode experience
   - **Impact:** High - improves usability in narrow windows
   - **Complexity:** Medium
   - **Estimated time:** 2-3 hours

2. **Issue I Do Blueprint-6vk** (P2) - Advanced Filter System
   - **Why second:** Enhances data discovery and usability
   - **Impact:** High - users can narrow down large budget lists
   - **Complexity:** Medium
   - **Estimated time:** 3-4 hours

3. **Issue I Do Blueprint-qi0** (P3) - Export Summary
   - **Why last:** Nice-to-have feature, not critical for core functionality
   - **Impact:** Medium - useful for sharing/backup
   - **Complexity:** Medium-High (PDF generation)
   - **Estimated time:** 4-5 hours

---

## Dependencies

### Issue Dependencies
- **None** - All three issues are independent and can be worked on in any order
- Each issue is self-contained with complete context

### Technical Dependencies
- All issues require the completed Budget Overview compact implementation
- Export feature requires TPPDF library (already in project)
- Filter system can reference Guest Management implementation

---

## Testing Considerations

### Common Testing Scenarios
All three features should be tested with:
- Empty budget items list (edge case)
- 1-10 items (typical use)
- 100+ items (performance test)
- Items with very long names
- Items with special characters
- Compact mode (640-699px)
- Regular mode (700-1000px)
- Large mode (1000px+)

### Accessibility Testing
- VoiceOver navigation
- Keyboard shortcuts
- Color contrast ratios
- Focus indicators
- Screen reader announcements

---

## Design System Compliance

All implementations must follow:
- **Colors:** `AppColors` constants
- **Typography:** `Typography` constants
- **Spacing:** `Spacing` constants
- **Corner Radius:** `CornerRadius` constants
- **Animations:** `.easeInOut(duration: 0.2)` standard
- **Accessibility:** Proper labels and hints

---

## Success Metrics

### Filter System (I Do Blueprint-6vk)
- Users can apply multiple filters simultaneously
- Filter state persists during session
- No performance degradation with filters active
- Filter UI is discoverable and intuitive

### Export Feature (I Do Blueprint-qi0)
- Users can export in all three formats
- Exports complete in < 5 seconds for typical datasets
- Generated files open correctly in target applications
- Export respects active filters

### Compact Table View (I Do Blueprint-hws)
- No horizontal scrolling in compact mode
- Expand/collapse animations are smooth
- All information accessible in expanded state
- Performance remains good with 100+ items

---

## Related Documentation

- **Implementation Summary:** `docs/BUDGET_OVERVIEW_DASHBOARD_COMPACT_IMPLEMENTATION_SUMMARY.md`
- **Implementation Plan:** `_project_specs/plans/budget-overview-dashboard-compact-view-plan.md`
- **Guest Management Reference:** `docs/GUEST_MANAGEMENT_COMPACT_WINDOW_PLAN.md`
- **Design System:** `Design/DesignSystem.swift`

---

## Notes for Future Implementers

### Filter System Tips
- Study the Guest Management filter implementation first
- Reuse filter chip component if possible
- Consider filter presets (e.g., "Over Budget Items")
- Add filter count badge to header button

### Export Feature Tips
- Test PDF generation with various data sizes
- Handle file system permissions gracefully
- Consider adding export to cloud (Google Drive) in future
- Log export events for analytics

### Compact Table View Tips
- Use `@State` for expanded IDs, not `@Published`
- Animate expand/collapse with `.animation()` modifier
- Consider adding "Expand All" / "Collapse All" buttons
- Test with folders (nested items)

---

**Issues Created:** January 2026  
**Status:** Ready for Implementation  
**Total Estimated Time:** 9-12 hours
