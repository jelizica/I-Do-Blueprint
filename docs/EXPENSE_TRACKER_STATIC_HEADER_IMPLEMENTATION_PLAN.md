# Expense Tracker Static Header - Implementation Plan

> **Status:** 🚧 READY TO IMPLEMENT  
> **Based on:** LLM Council Recommendation  
> **Estimated Duration:** 45 minutes

---

## Design Overview

### Two-Row Static Header (Outside ScrollView)

```
┌─────────────────────────────────────────────────────────────┐
│  💍 73 days to wedding        [+] Add Expense    [Export]   │
├─────────────────────────────────────────────────────────────┤
│  $12,450 / $15,000  ●●●●●●●●●○○ 83%    ⚠️ 3 overdue        │
│  On Track  │  💳 $2,100 pending  │  👥 $312/guest [Total▼] │
└─────────────────────────────────────────────────────────────���
```

### Row 1: Context + Actions
- **Left**: Wedding countdown - "💍 73 days to wedding"
- **Right**: Quick actions
  - **"+" Add Expense button** - Primary action
  - **Export button** - Placeholder (beads issue for future)

### Row 2: Health Dashboard
- **Spent/Budget with progress bar**: "$12,450 / $15,000 ●●●●●●●●●○○ 83%"
- **Status indicator**: "On Track" (color-coded: green/yellow/red)
- **Overdue alert**: "⚠️ 3 overdue" (clickable to filter)
- **Pending amount**: "💳 $2,100 pending"
- **Per-guest cost**: "👥 $312/guest [Total ▼]" (with toggle menu)

---

## Implementation Details

### 1. Structure Changes

**Current Structure:**
```swift
ScrollView {
    ExpenseTrackerUnifiedHeader (stats cards)
    ExpenseFiltersBarV2
    ExpenseListViewV2
}
```

**New Structure (matches Budget Builder/Dashboard):**
```swift
VStack(spacing: 0) {
    ExpenseTrackerStaticHeader (NEW - wedding countdown, health dashboard)
    
    ScrollView {
        VStack {
            ExpenseFiltersBarV2
            ExpenseListViewV2
            CategoryBenchmarksSectionV2
        }
    }
}
```

**Note:** The current `ExpenseTrackerUnifiedHeader` with stats cards will be **REMOVED** and replaced with the new static header.

---

### 2. Data Requirements

#### Already Available
- ✅ `budgetStore.totalExpensesAmount` - Total spent
- ✅ `budgetStore.pendingExpensesAmount` - Pending amount
- ✅ `budgetStore.paidExpensesAmount` - Paid amount
- ✅ `budgetStore.expenseStore.expenses` - All expenses
- ✅ `expense.paymentStatus == .overdue` - Overdue status

#### Needs to be Calculated
- **Total Budget**: Sum of all category `allocatedAmount` from primary scenario
  - Source: `budgetStore.savedScenarios.first { $0.isPrimary }`
  - Then: `budgetStore.development.loadBudgetDevelopmentItemsWithSpentAmounts(scenarioId:)`
  - Sum: `items.reduce(0) { $0 + $1.budgeted }`

- **Overdue Count**: `expenses.filter { $0.paymentStatus == .overdue }.count`

- **Wedding Date**: From `settingsStore.settings` (need to verify field name)

- **Guest Count**: From `guestStore.guests`
  - Total: `guests.count`
  - Attending: `guests.filter { $0.rsvpStatus == .confirmed && $0.attendingCeremony }.count`
  - Confirmed: `guests.filter { $0.rsvpStatus == .confirmed }.count`

- **Budget Health Status**: Based on spent percentage
  - On Track: <95% spent (green)
  - Attention Needed: 95-105% spent (yellow)
  - Over Budget: >105% spent (red)

---

### 3. Guest Count Toggle Implementation

**Design:** Small menu next to per-guest metric

```swift
Menu {
    Button {
        guestCountMode = .total
    } label: {
        Label("Total Guests", systemImage: guestCountMode == .total ? "checkmark" : "")
    }
    
    Button {
        guestCountMode = .attending
    } label: {
        Label("Attending", systemImage: guestCountMode == .attending ? "checkmark" : "")
    }
    
    Button {
        guestCountMode = .confirmed
    } label: {
        Label("Confirmed", systemImage: guestCountMode == .confirmed ? "checkmark" : "")
    }
} label: {
    HStack(spacing: 4) {
        Text(guestCountMode.rawValue)
            .font(.caption)
            .foregroundColor(.secondary)
        Image(systemName: "chevron.down")
            .font(.caption2)
            .foregroundColor(.secondary)
    }
}
```

**State:**
```swift
enum GuestCountMode: String {
    case total = "Total"
    case attending = "Attending"
    case confirmed = "Confirmed"
}

@State private var guestCountMode: GuestCountMode = .total
```

**Default:** Total

---

### 4. Overdue Badge Click Behavior

**Action:** Auto-filter expense list to show only overdue items

**Implementation:**
```swift
Button {
    // Set filter to overdue
    selectedFilterStatus = .overdue
    
    // Optional: Scroll to top of expense list
    // Optional: Show toast "Showing 3 overdue expenses"
} label: {
    HStack(spacing: 4) {
        Image(systemName: "exclamationmark.triangle.fill")
        Text("\(overdueCount) overdue")
    }
    .font(.caption)
    .foregroundColor(.white)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color.red)
    .cornerRadius(12)
}
.buttonStyle(.plain)
```

---

### 5. Budget Health Status Logic

```swift
enum BudgetHealthStatus {
    case onTrack    // Green - <95% spent
    case caution    // Yellow - 95-105% spent
    case overBudget // Red - >105% spent
    
    var color: Color {
        switch self {
        case .onTrack: return AppColors.Budget.underBudget
        case .caution: return AppColors.Budget.pending
        case .overBudget: return AppColors.Budget.overBudget
        }
    }
    
    var label: String {
        switch self {
        case .onTrack: return "On Track"
        case .caution: return "Attention Needed"
        case .overBudget: return "Over Budget"
        }
    }
    
    var icon: String {
        switch self {
        case .onTrack: return "checkmark.circle.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .overBudget: return "xmark.circle.fill"
        }
    }
}

private var budgetHealthStatus: BudgetHealthStatus {
    guard totalBudget > 0 else { return .onTrack }
    let percentage = (totalSpent / totalBudget) * 100
    
    if percentage < 95 {
        return .onTrack
    } else if percentage <= 105 {
        return .caution
    } else {
        return .overBudget
    }
}
```

---

### 6. Export Button (Placeholder)

**Implementation:**
```swift
Button {
    AppLogger.ui.info("Export - Not yet implemented")
} label: {
    Image(systemName: "square.and.arrow.up")
        .font(.title3)
        .foregroundColor(AppColors.textPrimary)
}
.buttonStyle(.plain)
.help("Export expenses (coming soon)")
```

**Beads Issue to Create:**
```
Title: Implement Expense Export Functionality (CSV/PDF)

Description:
Add comprehensive export functionality for expenses with multiple format options.

FUNCTIONALITY:
- Export filtered expenses to CSV
- Export filtered expenses to PDF
- Include summary statistics in exports
- Respect current filters (status, category, search)
- Option to include/exclude notes
- Option to group by category or vendor

LOCATION:
- ExpenseTrackerStaticHeader.swift (Export button)
- Create new ExpenseExportService.swift
- Create new ExpenseExportView.swift (modal for export options)

PATTERN TO FOLLOW:
- BudgetExportHelper.swift (existing export logic)
- GuestExportView.swift (export modal UI)
- Use FileExporter for save dialog

DATA TO INCLUDE:
CSV Format:
- Expense Name, Amount, Category, Vendor, Date, Payment Method, Payment Status, Notes
- Summary row: Total Spent, Total Pending, Total Paid

PDF Format:
- Header: "Expense Report - [Date Range]"
- Summary section: Total Spent, Pending, Paid, Overdue
- Table: All expense details
- Footer: Generated date, page numbers

TECHNICAL REQUIREMENTS:
- Use CSVWriter for CSV generation
- Use PDFKit for PDF generation
- Async/await for file operations
- Progress indicator for large exports
- Error handling with user-friendly messages
- Success toast with "Open File" action

FILES TO CREATE:
1. Services/Export/ExpenseExportService.swift
2. Views/Budget/Components/ExpenseExportView.swift

FILES TO MODIFY:
1. ExpenseTrackerStaticHeader.swift (wire up export button)

ESTIMATED: 4-5 hours

PRIORITY: P2 (Nice to have, not blocking)

DEPENDENCIES: None

ACCEPTANCE CRITERIA:
- [ ] CSV export works with all filters
- [ ] PDF export includes summary and details
- [ ] Export respects current filter state
- [ ] File save dialog works correctly
- [ ] Large exports (100+ items) don't freeze UI
- [ ] Error messages are user-friendly
- [ ] Success toast shows with "Open File" action
```

---

### 7. Wedding Countdown Logic

**Data Source:** `settingsStore.settings.weddingDate` (need to verify field name)

**Calculation:**
```swift
private var daysUntilWedding: Int? {
    guard let weddingDate = settingsStore.settings.weddingDate else { return nil }
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let wedding = calendar.startOfDay(for: weddingDate)
    let components = calendar.dateComponents([.day], from: today, to: wedding)
    return components.day
}

private var weddingCountdownText: String {
    guard let days = daysUntilWedding else { return "Wedding Date Not Set" }
    
    if days < 0 {
        return "Wedding Day Passed"
    } else if days == 0 {
        return "Wedding Day! 🎉"
    } else if days == 1 {
        return "💍 Tomorrow!"
    } else {
        return "💍 \(days) days to wedding"
    }
}
```

---

### 8. Responsive Behavior

#### Wide Windows (>900px)
- Full two-row layout
- All metrics visible
- Per-guest cost with toggle menu

#### Medium Windows (600-900px)
- Two-row layout maintained
- Per-guest cost abbreviated: "👥 $312"
- Toggle menu still accessible

#### Compact Windows (<600px)
- Collapse to single row with most critical info:
  ```
  ┌─────────────────────────────────────────────┐
  │ 💍 73d  │ $12,450/$15K  83%  │ ⚠️3  │ [+]  │
  └───────────────────────────��─────────────────┘
  ```
- Export button hidden (move to ellipsis menu)
- Per-guest cost hidden
- Abbreviated labels

---

## Files to Create

1. **ExpenseTrackerStaticHeader.swift** - New static header component
2. **Services/Export/ExpenseExportService.swift** - Export logic (future)
3. **Views/Budget/Components/ExpenseExportView.swift** - Export modal (future)

---

## Files to Modify

1. **ExpenseTrackerView.swift**
   - Remove current header from ScrollView
   - Add static header outside ScrollView
   - Add computed properties for total budget, overdue count, etc.
   - Add guest count mode state
   - Wire up overdue badge click to filter

2. **ExpenseTrackerUnifiedHeader.swift**
   - **DELETE THIS FILE** (replaced by static header)

---

## Implementation Steps

### Step 1: Calculate Total Budget (10 min)
- Add computed property to get primary scenario
- Load budget items for primary scenario
- Sum all `budgeted` amounts

### Step 2: Create Static Header Component (20 min)
- Create `ExpenseTrackerStaticHeader.swift`
- Implement Row 1 (countdown + actions)
- Implement Row 2 (health dashboard)
- Add responsive layouts

### Step 3: Wire Up Data (10 min)
- Pass all required data from ExpenseTrackerView
- Add guest count mode state
- Add overdue count calculation
- Add budget health status calculation

### Step 4: Update ExpenseTrackerView Structure (5 min)
- Move header outside ScrollView
- Remove old ExpenseTrackerUnifiedHeader
- Test responsive behavior

### Step 5: Create Export Beads Issue (5 min)
- Create comprehensive beads issue for future export work

---

## Testing Checklist

- [ ] Wedding countdown shows correct days
- [ ] Total budget calculates correctly from primary scenario
- [ ] Overdue count is accurate
- [ ] Overdue badge click filters to overdue expenses
- [ ] Budget health status colors are correct (green/yellow/red)
- [ ] Per-guest cost calculates correctly
- [ ] Guest count toggle works (Total/Attending/Confirmed)
- [ ] Progress bar fills correctly based on percentage
- [ ] Responsive layouts work on all window sizes
- [ ] Export button shows placeholder message
- [ ] Add Expense button works
- [ ] Static header doesn't scroll with content

---

## Edge Cases to Handle

1. **No wedding date set**: Show "Wedding Date Not Set" instead of countdown
2. **Wedding date in past**: Show "Wedding Day Passed"
3. **No primary scenario**: Show "No Budget Set" or use first scenario
4. **No guests**: Hide per-guest metric or show "No guests yet"
5. **Zero budget**: Show "Budget not configured" instead of percentage
6. **No overdue expenses**: Hide overdue badge or show "0 overdue" in gray

---

## Success Criteria

✅ Static header stays visible while scrolling  
✅ All metrics calculate correctly  
✅ Overdue badge filters expense list  
✅ Guest count toggle works smoothly  
✅ Budget health status is accurate  
✅ Responsive layouts work on all sizes  
✅ Export button is placeholder with beads issue created  
✅ Wedding countdown is accurate  
✅ Per-guest cost updates with toggle  
✅ Progress bar visual is clear and accurate

---

**Ready to implement!** All questions answered, all requirements clarified.
