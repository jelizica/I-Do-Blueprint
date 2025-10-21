//
//  BudgetStoreV2+Computed.swift
//  I Do Blueprint
//
//  Computed properties for BudgetStoreV2
//

import Foundation

// MARK: - Computed Properties

extension BudgetStoreV2 {
    
    // MARK: - Backward Compatibility Properties
    
    /// Budget summary from loading state
    var budgetSummary: BudgetSummary? {
        loadingState.data?.summary
    }
    
    /// Categories from loading state
    var categories: [BudgetCategory] {
        loadingState.data?.categories ?? []
    }
    
    /// Expenses from loading state
    var expenses: [Expense] {
        loadingState.data?.expenses ?? []
    }
    
    /// Loading state indicator
    var isLoading: Bool {
        loadingState.isLoading
    }
    
    /// Error from loading state
    var error: BudgetError? {
        if case .error(let err) = loadingState {
            return err as? BudgetError ?? .fetchFailed(underlying: err)
        }
        return nil
    }
    
    // MARK: - Delegated Properties (from Composed Stores)
    
    /// Payment schedules (delegated to PaymentScheduleStore)
    var paymentSchedules: [PaymentSchedule] {
        payments.paymentSchedules
    }
    
    /// Gifts and owed (delegated to GiftsStore)
    var giftsAndOwed: [GiftOrOwed] {
        gifts.giftsAndOwed
    }
    
    /// Gifts received (delegated to GiftsStore)
    var giftsReceived: [GiftReceived] {
        gifts.giftsReceived
    }
    
    /// Money owed (delegated to GiftsStore)
    var moneyOwed: [MoneyOwed] {
        gifts.moneyOwed
    }
    
    /// Affordability scenarios (delegated to AffordabilityStore)
    var affordabilityScenarios: [AffordabilityScenario] {
        affordability.scenarios
    }
    
    /// Affordability contributions (delegated to AffordabilityStore)
    var affordabilityContributions: [ContributionItem] {
        affordability.contributions
    }
    
    /// Selected scenario ID (delegated to AffordabilityStore)
    var selectedScenarioId: UUID? {
        get { affordability.selectedScenarioId }
        set { affordability.selectedScenarioId = newValue }
    }
    
    /// Available gifts (delegated to AffordabilityStore)
    var availableGifts: [GiftOrOwed] {
        affordability.availableGifts
    }
    
    /// Editing gift (delegated to AffordabilityStore)
    var editingGift: GiftOrOwed? {
        get { affordability.editingGift }
        set { affordability.editingGift = newValue }
    }
    
    /// Edited wedding date (delegated to AffordabilityStore)
    var editedWeddingDate: Date? {
        get { affordability.editedWeddingDate }
        set { affordability.editedWeddingDate = newValue }
    }
    
    /// Edited calculation start date (delegated to AffordabilityStore)
    var editedCalculationStartDate: Date? {
        get { affordability.editedCalculationStartDate }
        set { affordability.editedCalculationStartDate = newValue }
    }
    
    /// Edited partner 1 monthly (delegated to AffordabilityStore)
    var editedPartner1Monthly: Double {
        get { affordability.editedPartner1Monthly }
        set { affordability.editedPartner1Monthly = newValue }
    }
    
    /// Edited partner 2 monthly (delegated to AffordabilityStore)
    var editedPartner2Monthly: Double {
        get { affordability.editedPartner2Monthly }
        set { affordability.editedPartner2Monthly = newValue }
    }
    
    /// Show add scenario sheet (delegated to AffordabilityStore)
    var showAddScenarioSheet: Bool {
        get { affordability.showAddScenarioSheet }
        set { affordability.showAddScenarioSheet = newValue }
    }
    
    /// Show add contribution sheet (delegated to AffordabilityStore)
    var showAddContributionSheet: Bool {
        get { affordability.showAddContributionSheet }
        set { affordability.showAddContributionSheet = newValue }
    }
    
    /// Show link gifts sheet (delegated to AffordabilityStore)
    var showLinkGiftsSheet: Bool {
        get { affordability.showLinkGiftsSheet }
        set { affordability.showLinkGiftsSheet = newValue }
    }
    
    /// Show edit gift sheet (delegated to AffordabilityStore)
    var showEditGiftSheet: Bool {
        get { affordability.showEditGiftSheet }
        set { affordability.showEditGiftSheet = newValue }
    }
    
    // MARK: - Budget Calculations
    
    /// Total amount spent across all expenses
    var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Total amount allocated across all categories
    var totalAllocated: Double {
        categories.reduce(0) { $0 + $1.allocatedAmount }
    }
    
    /// Actual total budget (from summary or allocated)
    var actualTotalBudget: Double {
        if let summary = budgetSummary, summary.totalBudget > 0 {
            return summary.totalBudget
        }
        return totalAllocated
    }
    
    /// Remaining budget
    var remainingBudget: Double {
        actualTotalBudget - totalSpent
    }
    
    /// Percentage of budget spent
    var percentageSpent: Double {
        guard actualTotalBudget > 0 else { return 0 }
        return (totalSpent / actualTotalBudget) * 100
    }
    
    /// Percentage of budget allocated
    var percentageAllocated: Double {
        guard actualTotalBudget > 0 else { return 0 }
        return (totalAllocated / actualTotalBudget) * 100
    }
    
    /// Whether budget is exceeded
    var isOverBudget: Bool {
        totalSpent > actualTotalBudget
    }
    
    /// Budget utilization percentage
    var budgetUtilization: Double {
        guard actualTotalBudget > 0 else { return 0 }
        return (totalSpent / actualTotalBudget) * 100
    }
    
    // MARK: - Gift and Payment Calculations
    
    /// Total pending gifts and owed amounts
    var totalPending: Double {
        giftsAndOwed.reduce(0) { $0 + $1.amount }
    }
    
    /// Total received gifts
    var totalReceived: Double {
        giftsReceived.reduce(0) { $0 + $1.amount }
    }
    
    /// Total confirmed gifts
    var totalConfirmed: Double {
        giftsAndOwed.filter { $0.status == .confirmed }.reduce(0) { $0 + $1.amount }
    }
    
    /// Total budget addition from gifts
    var totalBudgetAddition: Double {
        totalReceived + totalPending + totalConfirmed
    }
    
    /// Total pending payments
    var pendingPayments: Double {
        paymentSchedules.filter { $0.paymentStatus == .pending }.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Cash Flow Calculations
    
    /// Total inflows (gifts and contributions)
    var totalInflows: Double {
        totalBudgetAddition
    }
    
    /// Total outflows (expenses)
    var totalOutflows: Double {
        totalSpent
    }
    
    /// Net cash flow
    var netCashFlow: Double {
        totalInflows - totalOutflows
    }
    
    // MARK: - Expense Calculations
    
    /// Total expenses amount
    var totalExpensesAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Paid expenses amount
    var paidExpensesAmount: Double {
        expenses.filter { $0.paymentStatus == .paid }.reduce(0) { $0 + $1.amount }
    }
    
    /// Pending expenses amount
    var pendingExpensesAmount: Double {
        expenses.filter { $0.paymentStatus == .pending }.reduce(0) { $0 + $1.amount }
    }
    
    /// Average monthly spend
    var averageMonthlySpend: Double {
        // Simplified calculation - divide total by 12 months
        totalSpent / 12.0
    }
    
    // MARK: - Category Calculations
    
    /// Parent categories (no parent category ID)
    var parentCategories: [BudgetCategory] {
        categories.filter { $0.parentCategoryId == nil }
    }
    
    // MARK: - Stats and Metrics
    
    /// Budget statistics
    var stats: BudgetStats {
        BudgetStats(
            totalCategories: categories.count,
            categoriesOverBudget: categories.filter { $0.spentAmount > $0.allocatedAmount }.count,
            categoriesOnTrack: categories.filter { $0.spentAmount <= $0.allocatedAmount }.count,
            totalExpenses: expenses.count,
            expensesPending: expenses.filter { $0.paymentStatus == .pending }.count,
            expensesOverdue: expenses.filter { $0.isOverdue }.count,
            averageSpendingPerCategory: categories.isEmpty ? 0 : totalSpent / Double(categories.count),
            projectedOverage: max(0, totalSpent - actualTotalBudget),
            monthlyBurnRate: 0
        )
    }
    
    /// Days to wedding
    var daysToWedding: Int {
        guard let weddingDate = budgetSummary?.weddingDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: weddingDate)
        return max(0, components.day ?? 0)
    }
    
    // MARK: - Budget Alerts
    
    /// Budget alerts for overspending and upcoming payments
    var budgetAlerts: [BudgetAlert] {
        var alerts: [BudgetAlert] = []
        
        // Check for overspending in categories
        for category in categories {
            let spent = expenses
                .filter { $0.budgetCategoryId == category.id }
                .reduce(0.0) { $0 + $1.amount }
            
            let percentSpent = category.allocatedAmount > 0 ? (spent / category.allocatedAmount) : 0
            
            if spent > category.allocatedAmount {
                alerts.append(BudgetAlert(
                    severity: .critical,
                    title: "\(category.categoryName) Over Budget",
                    message: "Spent \(String(format: "$%.2f", spent)) of \(String(format: "$%.2f", category.allocatedAmount)) budget",
                    timestamp: Date()
                ))
            } else if percentSpent >= 0.9 {
                alerts.append(BudgetAlert(
                    severity: .warning,
                    title: "\(category.categoryName) Near Budget Limit",
                    message: "Used \(Int(percentSpent * 100))% of budget",
                    timestamp: Date()
                ))
            }
        }
        
        // Check for upcoming payments
        let upcomingPayments = paymentSchedules.filter { schedule in
            let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: schedule.dueDate).day ?? 0
            return daysUntilDue >= 0 && daysUntilDue <= 7 && schedule.paymentStatus == .pending
        }
        
        if !upcomingPayments.isEmpty {
            let totalDue = upcomingPayments.reduce(0.0) { $0 + $1.amount }
            alerts.append(BudgetAlert(
                severity: .info,
                title: "Upcoming Payments",
                message: "\(upcomingPayments.count) payment(s) due in the next week (\(String(format: "$%.2f", totalDue)))",
                timestamp: Date()
            ))
        }
        
        // Check overall budget status
        if let summary = budgetSummary {
            let percentUsed = summary.totalBudget > 0 ? (summary.totalSpent / summary.totalBudget) : 0
            
            if summary.totalSpent > summary.totalBudget {
                alerts.append(BudgetAlert(
                    severity: .critical,
                    title: "Overall Budget Exceeded",
                    message: "Spent \(String(format: "$%.2f", summary.totalSpent)) of \(String(format: "$%.2f", summary.totalBudget)) total budget",
                    timestamp: Date()
                ))
            } else if percentUsed >= 0.85 {
                alerts.append(BudgetAlert(
                    severity: .warning,
                    title: "Budget Alert",
                    message: "Used \(Int(percentUsed * 100))% of total budget",
                    timestamp: Date()
                ))
            }
        }
        
        // Sort by severity (critical first) and timestamp
        return alerts.sorted { alert1, alert2 in
            if alert1.severity != alert2.severity {
                switch (alert1.severity, alert2.severity) {
                case (.critical, _): return true
                case (_, .critical): return false
                case (.warning, .info): return true
                case (.info, .warning): return false
                default: return alert1.timestamp > alert2.timestamp
                }
            }
            return alert1.timestamp > alert2.timestamp
        }
    }
    
    // MARK: - Affordability Calculator Computed Properties
    
    /// Scenarios (alias for affordabilityScenarios)
    var scenarios: [AffordabilityScenario] {
        affordabilityScenarios
    }
    
    /// Contributions (alias for affordabilityContributions)
    var contributions: [ContributionItem] {
        affordabilityContributions
    }
    
    /// Selected scenario
    var selectedScenario: AffordabilityScenario? {
        guard let id = selectedScenarioId else { return nil }
        return affordabilityScenarios.first { $0.id == id }
    }
    
    /// Whether there are unsaved changes
    var hasUnsavedChanges: Bool {
        guard let scenario = selectedScenario else { return false }
        
        // Check if any values have changed from the selected scenario
        let startDateChanged = editedCalculationStartDate != scenario.calculationStartDate
        let partner1Changed = editedPartner1Monthly != scenario.partner1Monthly
        let partner2Changed = editedPartner2Monthly != scenario.partner2Monthly
        
        return startDateChanged || partner1Changed || partner2Changed
    }
    
    /// Total contributions
    var totalContributions: Double {
        affordabilityContributions.reduce(0) { $0 + $1.amount }
    }
    
    /// Total gifts
    var totalGifts: Double {
        affordabilityContributions
            .filter { $0.contributionType == .gift }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Total external contributions
    var totalExternal: Double {
        affordabilityContributions
            .filter { $0.contributionType == .external }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Money already saved from calculation start date to today
    var totalSaved: Double {
        guard let startDate = editedCalculationStartDate ?? selectedScenario?.calculationStartDate else {
            return 0
        }
        
        // Calculate months from start date until today
        let monthsElapsed = Calendar.current.dateComponents([.month], from: startDate, to: Date()).month ?? 0
        guard monthsElapsed > 0 else { return 0 }
        
        let monthlyTotal = editedPartner1Monthly + editedPartner2Monthly
        return monthlyTotal * Double(monthsElapsed)
    }
    
    /// Money that will be saved from today until wedding date
    var projectedSavings: Double {
        guard let weddingDate = editedWeddingDate else {
            return 0
        }
        
        // Calculate months from today until wedding
        let monthsRemaining = Calendar.current.dateComponents([.month], from: Date(), to: weddingDate).month ?? 0
        guard monthsRemaining > 0 else { return 0 }
        
        let monthlyTotal = editedPartner1Monthly + editedPartner2Monthly
        return monthlyTotal * Double(monthsRemaining)
    }
    
    /// Already paid amount
    var alreadyPaid: Double {
        paymentSchedules
            .filter { $0.paid }
            .reduce(0) { $0 + $1.amount }
    }
    
    /// Total affordable budget
    var totalAffordableBudget: Double {
        totalContributions + totalSaved + projectedSavings + alreadyPaid
    }
    
    /// Months left until wedding
    var monthsLeft: Int {
        guard let weddingDate = editedWeddingDate else {
            return 0
        }
        
        // Months from today to wedding date
        return max(0, Calendar.current.dateComponents([.month], from: Date(), to: weddingDate).month ?? 0)
    }
    
    /// Progress percentage toward wedding date
    var progressPercentage: Double {
        guard let startDate = editedCalculationStartDate ?? selectedScenario?.calculationStartDate,
              let weddingDate = editedWeddingDate else {
            return 0
        }
        
        // Calculate total months from start to wedding
        let totalMonths = Calendar.current.dateComponents([.month], from: startDate, to: weddingDate).month ?? 0
        guard totalMonths > 0 else { return 0 }
        
        // Calculate months elapsed from start to today
        let monthsElapsed = Calendar.current.dateComponents([.month], from: startDate, to: Date()).month ?? 0
        
        return min(100, max(0, (Double(monthsElapsed) / Double(totalMonths)) * 100))
    }
}
