# Budget Navigation Fixes and Category Optimization

**Created:** 2026-01-01
**Status:** Ready for Implementation
**Priority:** P1 (User-Reported Issues)

---

## Issues to Address

### 1. Hub Return Navigation
**Problem:** Once you navigate away from the hub to a specific page (e.g., Expense Tracker), there's no clear way to get back to the hub.

**Current Behavior:**
- Dropdown shows "Budget: Expense Tracker"
- No "Dashboard" or "Hub" option visible in dropdown

**Solution:** Add "Dashboard" as the first item in the dropdown menu (outside any section).

### 2. Dashboard Naming Confusion
**Problem:** Two different "dashboards":
1. `BudgetDashboardHubView` - Navigation hub with group cards
2. `BudgetDashboardView` - Original data visualization page

**User Request:** 
- Keep the hub as the main landing page
- Rename the original dashboard to "Development Dashboard" or similar
- Remove "Dashboard" from being nested under "Overview" section

**Solution:** Restructure to:
```
Dashboard (hub - top level, always accessible)
Overview (section)
  ├─ Development Dashboard (renamed from "Budget Dashboard")
  ├─ Analytics Hub
  ├─ Account Cash Flow
  └─ Calculator
Expenses (section)
  ├─ Expense Tracker
  ├─ Expense Reports
  ├─ Expense Categories
  └─ Payment Schedule (moved from Payments)
Income (section - renamed from "Gifts & Owed")
  ├─ Money Tracker
  ├─ Money Received
  └─ Money Owed
```

### 3. Category Optimization
**Current Issues:**
- "Payments" section has only 1 page (feels incomplete)
- "Gifts & Owed" is awkward naming
- "Overview" is vague

**Optimizations:**
1. **Merge Payments into Expenses** - Payment Schedule is expense-related
2. **Rename "Gifts & Owed" to "Income"** - More intuitive
3. **Keep "Overview" but clarify** - These are planning/analysis tools

---

## Implementation Plan

### Step 1: Update BudgetPage Enum

**File:** `I Do Blueprint/Domain/Models/Budget/BudgetPage.swift`

**Changes:**
```swift
enum BudgetPage: String, CaseIterable, Identifiable {
    // Hub (special case - not in a group)
    case hub = "Dashboard"
    
    // Overview Group
    case developmentDashboard = "Development Dashboard"  // Renamed
    case analytics = "Analytics Hub"
    case cashFlow = "Account Cash Flow"
    case calculator = "Calculator"

    // Expenses Group (includes Payment Schedule)
    case expenseTracker = "Expense Tracker"
    case expenseReports = "Expense Reports"
    case expenseCategories = "Expense Categories"
    case paymentSchedule = "Payment Schedule"  // Moved from Payments

    // Income Group (renamed from Gifts & Owed)
    case moneyTracker = "Money Tracker"
    case moneyReceived = "Money Received"
    case moneyOwed = "Money Owed"

    var id: String { rawValue }

    var group: BudgetGroup? {
        switch self {
        case .hub:
            return nil  // Hub is not in a group
        case .developmentDashboard, .analytics, .cashFlow, .calculator:
            return .overview
        case .expenseTracker, .expenseReports, .expenseCategories, .paymentSchedule:
            return .expenses
        case .moneyTracker, .moneyReceived, .moneyOwed:
            return .income
        }
    }

    var icon: String {
        switch self {
        case .hub: return "square.grid.2x2.fill"
        case .developmentDashboard: return "chart.bar.fill"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .cashFlow: return "banknote.fill"
        case .calculator: return "function"
        case .expenseTracker: return "creditcard.fill"
        case .expenseReports: return "doc.text.fill"
        case .expenseCategories: return "folder.fill"
        case .paymentSchedule: return "calendar.badge.clock"
        case .moneyTracker: return "dollarsign.circle.fill"
        case .moneyReceived: return "arrow.down.circle.fill"
        case .moneyOwed: return "arrow.up.circle.fill"
        }
    }

    @ViewBuilder
    var view: some View {
        switch self {
        case .hub:
            EmptyView()  // Hub is handled separately
        case .developmentDashboard:
            BudgetDashboardView()  // Original dashboard
        case .analytics:
            BudgetAnalyticsView()
        case .cashFlow:
            BudgetCashFlowView()
        case .calculator:
            BudgetCalculatorView()
        case .expenseTracker:
            ExpenseTrackerView()
        case .expenseReports:
            ExpenseReportsView()
        case .expenseCategories:
            ExpenseCategoriesView()
        case .paymentSchedule:
            PaymentScheduleView()
        case .moneyTracker:
            MoneyTrackerView()
        case .moneyReceived:
            MoneyReceivedView()
        case .moneyOwed:
            MoneyOwedView()
        }
    }
}

enum BudgetGroup: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case expenses = "Expenses"
    case income = "Income"  // Renamed from giftsOwed

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .overview: return .blue
        case .expenses: return .red
        case .income: return .green
        }
    }

    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .expenses: return "creditcard.fill"
        case .income: return "dollarsign.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .overview: return "Planning and analysis tools"
        case .expenses: return "Track spending and payments"
        case .income: return "Monitor gifts and money owed"
        }
    }

    var pages: [BudgetPage] {
        BudgetPage.allCases.filter { $0.group == self }
    }

    var defaultPage: BudgetPage {
        switch self {
        case .overview: return .developmentDashboard
        case .expenses: return .expenseTracker
        case .income: return .moneyTracker
        }
    }
}
```

### Step 2: Update BudgetDashboardHubView Dropdown

**File:** `I Do Blueprint/Views/Budget/BudgetDashboardHubView.swift`

**Changes to `budgetPageDropdown`:**
```swift
private var budgetPageDropdown: some View {
    Menu {
        // Dashboard (always first, outside sections)
        Button {
            currentPage = .hub
        } label: {
            Label("Dashboard", systemImage: "square.grid.2x2.fill")
            if currentPage == .hub {
                Image(systemName: "checkmark")
            }
        }
        .keyboardShortcut("1", modifiers: [.command])

        Divider()

        // Overview Group
        Section("Overview") {
            ForEach(BudgetGroup.overview.pages) { page in
                Button {
                    currentPage = page
                } label: {
                    Label(page.rawValue, systemImage: page.icon)
                    if currentPage == page {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }

        // Expenses Group
        Section("Expenses") {
            ForEach(BudgetGroup.expenses.pages) { page in
                Button {
                    currentPage = page
                } label: {
                    Label(page.rawValue, systemImage: page.icon)
                    if currentPage == page {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }

        // Income Group (renamed)
        Section("Income") {
            ForEach(BudgetGroup.income.pages) { page in
                Button {
                    currentPage = page
                } label: {
                    Label(page.rawValue, systemImage: page.icon)
                    if currentPage == page {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    } label: {
        HStack(spacing: Spacing.xs) {
            Text("Budget: \(currentPage.rawValue)")
                .font(.headline)
            Image(systemName: "chevron.down")
                .font(.caption)
        }
    }
    .menuStyle(.borderlessButton)
}
```

**Changes to `body`:**
```swift
var body: some View {
    GeometryReader { geometry in
        let windowSize = geometry.size.width.windowSize
        let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.huge
        let availableWidth = geometry.size.width - (horizontalPadding * 2)

        ZStack {
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            // Content based on current page
            if currentPage == .hub {
                // Dashboard hub content
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        budgetDashboardSummary(windowSize: windowSize)
                            .frame(width: availableWidth)

                        // 3 Group Cards (not 4)
                        groupCardsGrid(windowSize: windowSize)
                            .frame(width: availableWidth)

                        if windowSize != .compact {
                            quickAccessSection
                                .frame(width: availableWidth)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, Spacing.lg)
                }
            } else {
                // Show the selected page's view
                currentPage.view
            }
        }
    }
    .toolbar {
        ToolbarItem(placement: .principal) {
            budgetPageDropdown
        }
    }
    .task {
        await budgetStore.loadBudgetData()
    }
}
```

### Step 3: Update Group Cards Grid

**Changes to `groupCardsGrid`:**
```swift
@ViewBuilder
private func groupCardsGrid(windowSize: WindowSize) -> some View {
    let columns: [GridItem] = {
        if windowSize == .compact {
            return [GridItem(.flexible())]
        } else {
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
    }()

    LazyVGrid(columns: columns, spacing: Spacing.lg) {
        // Now only 3 groups
        ForEach(BudgetGroup.allCases) { group in
            BudgetGroupCard(group: group) {
                currentPage = group.defaultPage
            }
        }
    }
}
```

### Step 4: Update Quick Access Section

**Changes to `quickAccessSection`:**
```swift
private var quickAccessSection: some View {
    VStack(alignment: .leading, spacing: Spacing.md) {
        Text("Quick Access")
            .font(.headline)
            .padding(.horizontal, Spacing.sm)

        VStack(spacing: Spacing.xs) {
            QuickAccessRow(page: .developmentDashboard) {
                currentPage = .developmentDashboard
            }
            QuickAccessRow(page: .expenseTracker) {
                currentPage = .expenseTracker
            }
            QuickAccessRow(page: .paymentSchedule) {
                currentPage = .paymentSchedule
            }
            QuickAccessRow(page: .analytics) {
                currentPage = .analytics
            }
        }
        .padding(Spacing.sm)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}
```

### Step 5: Update Dashboard Summary

**Changes to `budgetDashboardSummary`:**
```swift
@ViewBuilder
private func budgetDashboardSummary(windowSize: WindowSize) -> some View {
    VStack(spacing: Spacing.lg) {
        // Header
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Budget Hub")  // Changed from "Budget Dashboard"
                    .font(Typography.displaySmall)

                if windowSize != .compact {
                    Text("Your wedding budget at a glance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: {
                Task {
                    await budgetStore.refresh()
                }
            }) {
                if windowSize == .compact {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20))
                } else {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
            .frame(width: windowSize == .compact ? 44 : nil, height: 44)
            .buttonStyle(.bordered)
            .help(windowSize == .compact ? "Refresh" : "")
        }

        // Stats Grid (unchanged)
        StatsGridView(
            stats: [
                StatItem(
                    icon: "dollarsign.circle.fill",
                    label: "Total Budget",
                    value: NumberFormatter.currencyShort.string(from: NSNumber(value: budgetStore.actualTotalBudget)) ?? "$0",
                    color: AppColors.Budget.allocated
                ),
                StatItem(
                    icon: "creditcard.fill",
                    label: "Total Spent",
                    value: NumberFormatter.currencyShort.string(from: NSNumber(value: budgetStore.totalSpent)) ?? "$0",
                    color: budgetStore.isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.underBudget
                ),
                StatItem(
                    icon: "banknote.fill",
                    label: "Remaining",
                    value: NumberFormatter.currencyShort.string(from: NSNumber(value: budgetStore.remainingBudget)) ?? "$0",
                    color: budgetStore.isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.pending
                )
            ],
            columns: windowSize == .compact ? 2 : 3
        )

        // Progress bar (unchanged)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Budget Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(budgetStore.percentageSpent))% spent")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressBar(
                value: min(budgetStore.percentageSpent / 100, 1.0),
                color: budgetStore.isOverBudget ? AppColors.Budget.overBudget : AppColors.Budget.allocated,
                height: 8
            )
        }
    }
    .padding(Spacing.lg)
    .background(Color(NSColor.controlBackgroundColor))
    .cornerRadius(12)
}
```

---

## Summary of Changes

### Navigation Improvements
1. ✅ **Hub Return**: "Dashboard" always visible at top of dropdown
2. ✅ **Clear Hierarchy**: Hub → Sections → Pages
3. ✅ **Keyboard Shortcut**: ⌘1 returns to hub

### Category Optimization
1. ✅ **3 Groups Instead of 4**: Overview, Expenses, Income
2. ✅ **Payment Schedule Moved**: Now under Expenses (makes more sense)
3. ✅ **Better Naming**: "Income" instead of "Gifts & Owed"
4. ✅ **Clearer Purpose**: Each group has a distinct function

### Dashboard Clarity
1. ✅ **Hub vs Dashboard**: Hub is navigation, Development Dashboard is data
2. ✅ **Renamed**: "Budget Dashboard" → "Development Dashboard"
3. ✅ **Not Nested**: Dashboard is top-level in dropdown

### Page Count
- **Before**: 13 pages (5 Overview + 3 Expenses + 1 Payments + 3 Gifts & Owed + 1 Hub)
- **After**: 13 pages (1 Hub + 4 Overview + 4 Expenses + 3 Income)

---

## Testing Checklist

### Navigation Flow
- [ ] Click Budget in sidebar → lands on hub
- [ ] Select "Development Dashboard" from dropdown → shows data dashboard
- [ ] Select "Dashboard" from dropdown → returns to hub
- [ ] ⌘1 keyboard shortcut → returns to hub
- [ ] Group cards navigate to correct default pages

### Dropdown Menu
- [ ] "Dashboard" appears first (outside sections)
- [ ] Overview section has 4 pages
- [ ] Expenses section has 4 pages (includes Payment Schedule)
- [ ] Income section has 3 pages
- [ ] Current page shows checkmark
- [ ] All pages accessible

### Group Cards
- [ ] 3 cards displayed (Overview, Expenses, Income)
- [ ] Cards show correct icons and colors
- [ ] Cards show correct page counts (4, 4, 3)
- [ ] Clicking cards navigates to default pages

### Quick Access
- [ ] Shows Development Dashboard (not "Budget Dashboard")
- [ ] Shows Expense Tracker
- [ ] Shows Payment Schedule
- [ ] Shows Analytics
- [ ] All links work correctly

---

## Files to Modify

1. `I Do Blueprint/Domain/Models/Budget/BudgetPage.swift` - Update enum
2. `I Do Blueprint/Views/Budget/BudgetDashboardHubView.swift` - Update dropdown and UI
3. `I Do Blueprint/Views/Budget/BudgetDashboardView.swift` - Verify still works (no changes needed)

---

## Implementation Time Estimate

- **Step 1-2**: 30 minutes (enum and dropdown updates)
- **Step 3-5**: 30 minutes (UI updates)
- **Testing**: 30 minutes
- **Total**: ~1.5 hours

---

## Next Steps

1. ✅ Review and approve this plan
2. Create Beads issue for implementation
3. Implement changes
4. Test thoroughly
5. Update Basic Memory with new navigation structure
6. Update implementation plan document

---

**Status:** Ready for Implementation
**Approval:** Awaiting User Confirmation
