//
//  DashboardViewModel.swift
//  I Do Blueprint
//
//  View model for DashboardViewV4
//  Handles computed properties, metrics, and data loading logic
//

import SwiftUI
import Combine
import Sentry

@MainActor
final class DashboardViewModel: ObservableObject {
    private let logger = AppLogger.ui
    
    // MARK: - Published State
    
    @Published var isLoading = false
    @Published var hasLoaded = false
    
    // MARK: - Dependencies (Stores)
    
    private let budgetStore: BudgetStoreV2
    private let vendorStore: VendorStoreV2
    private let guestStore: GuestStoreV2
    private let taskStore: TaskStoreV2
    private let settingsStore: SettingsStoreV2
    
    // MARK: - Cached Computed Values
    
    private var cachedWeddingDate: Date?
    private var cachedDaysUntilWedding: Int?
    private var lastDateCalculation: Date?
    
    // MARK: - Initialization
    
    init(
        budgetStore: BudgetStoreV2,
        vendorStore: VendorStoreV2,
        guestStore: GuestStoreV2,
        taskStore: TaskStoreV2,
        settingsStore: SettingsStoreV2
    ) {
        self.budgetStore = budgetStore
        self.vendorStore = vendorStore
        self.guestStore = guestStore
        self.taskStore = taskStore
        self.settingsStore = settingsStore
    }
    
    // MARK: - Computed Properties - Timezone & Date
    
    /// User's configured timezone for display
    var userTimezone: TimeZone {
        DateFormatting.userTimeZone(from: settingsStore.settings)
    }

    /// User's theme settings for dashboard customization
    var themeSettings: ThemeSettings {
        settingsStore.settings.theme
    }
    
    /// Wedding date parsed from settings (cached for performance)
    var weddingDate: Date? {
        guard hasLoaded else { return nil }
        
        // Cache wedding date calculation (only recalculate if settings changed)
        let dateString = settingsStore.settings.global.weddingDate
        guard !dateString.isEmpty else { return nil }
        
        if cachedWeddingDate == nil {
            cachedWeddingDate = DateFormatting.parseDateFromDatabase(dateString)
        }
        
        return cachedWeddingDate
    }
    
    /// Days until wedding (cached, recalculated daily)
    var daysUntilWedding: Int {
        guard let weddingDate = weddingDate else { return 0 }
        
        // Recalculate if we haven't calculated today or if cached value is nil
        let now = Date()
        if let lastCalc = lastDateCalculation,
           Calendar.current.isDate(lastCalc, inSameDayAs: now),
           let cached = cachedDaysUntilWedding {
            return cached
        }
        
        // Calculate days in user's timezone (not device timezone)
        let days = DateFormatting.daysBetween(from: now, to: weddingDate, in: userTimezone)
        cachedDaysUntilWedding = days
        lastDateCalculation = now
        
        return days
    }
    
    // MARK: - Computed Properties - Partner Names
    
    /// Partner 1 display name (nickname if available, otherwise full name)
    var partner1DisplayName: String {
        guard hasLoaded else { return "" }
        
        let nickname = settingsStore.settings.global.partner1Nickname
        let fullName = settingsStore.settings.global.partner1FullName
        
        if !nickname.isEmpty {
            return nickname
        } else if !fullName.isEmpty {
            return fullName
        } else {
            return "Partner 1"
        }
    }
    
    /// Partner 2 display name (nickname if available, otherwise full name)
    var partner2DisplayName: String {
        guard hasLoaded else { return "" }
        
        let nickname = settingsStore.settings.global.partner2Nickname
        let fullName = settingsStore.settings.global.partner2FullName
        
        if !nickname.isEmpty {
            return nickname
        } else if !fullName.isEmpty {
            return fullName
        } else {
            return "Partner 2"
        }
    }
    
    // MARK: - Computed Properties - Guest Metrics
    
    var totalGuests: Int {
        guestStore.guests.count
    }
    
    var rsvpYesCount: Int {
        guestStore.guests.filter {
            $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed
        }.count
    }
    
    var rsvpNoCount: Int {
        guestStore.guests.filter { $0.rsvpStatus == .declined }.count
    }
    
    var rsvpPendingCount: Int {
        guestStore.guests.filter {
            $0.rsvpStatus == .pending || $0.rsvpStatus == .invited
        }.count
    }
    
    // MARK: - Computed Properties - Vendor Metrics
    
    var totalVendors: Int {
        vendorStore.vendors.count
    }
    
    var vendorsBookedCount: Int {
        vendorStore.vendors.filter { $0.isBooked == true }.count
    }
    
    var vendorsPendingCount: Int {
        vendorStore.vendors.filter { $0.isBooked != true }.count
    }
    
    // MARK: - Computed Properties - Budget Metrics
    
    /// Budget percentage based on primary development scenario
    var budgetPercentage: Double {
        guard let primaryScenario = budgetStore.primaryScenario else {
            return 0
        }
        
        let totalPaid = budgetStore.payments.totalPaid
        guard primaryScenario.totalWithTax > 0 else { return 0 }
        return (totalPaid / primaryScenario.totalWithTax) * 100
    }
    
    /// Remaining budget amount
    var budgetRemaining: Double {
        guard let primaryScenario = budgetStore.primaryScenario else {
            return 0
        }
        
        let totalPaid = budgetStore.payments.totalPaid
        return primaryScenario.totalWithTax - totalPaid
    }
    
    /// Total budget from primary scenario
    var totalBudget: Double {
        guard let primaryScenario = budgetStore.primaryScenario else {
            return 0
        }
        return primaryScenario.totalWithTax
    }
    
    /// Total paid amount
    var totalPaid: Double {
        return budgetStore.payments.totalPaid
    }
    
    /// Total expenses amount
    var totalExpenses: Double {
        guard case .loaded(let budgetData) = budgetStore.loadingState else {
            return 0
        }
        return budgetData.expenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Budget categories
    var categories: [BudgetCategory] {
        guard case .loaded(let budgetData) = budgetStore.loadingState else {
            return []
        }
        return budgetData.categories
    }
    
    /// Budget status color based on percentage used
    var budgetColor: Color {
        if budgetPercentage >= 100 {
            return SemanticColors.error
        } else if budgetPercentage >= 90 {
            return SemanticColors.warning
        } else {
            return SemanticColors.success
        }
    }
    
    // MARK: - Helper Methods
    
    /// Format currency amount for display
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
    
    /// Invalidate cached date calculations (call when settings change)
    func invalidateDateCache() {
        cachedWeddingDate = nil
        cachedDaysUntilWedding = nil
        lastDateCalculation = nil
    }
    
    // MARK: - Data Loading
    
    /// Load all dashboard data in parallel
    func loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }
        
        logger.info("Loading dashboard data...")
        
        // Start Sentry transaction bound to scope so network spans can attach
        let transaction = SentryService.shared.startTransaction(name: "dashboard.load", operation: "ui.load")
        let spanBudget = transaction?.startChild(operation: "store.budget.load", description: "BudgetStoreV2.loadBudgetData")
        let spanVendors = transaction?.startChild(operation: "store.vendor.load", description: "VendorStoreV2.loadVendors")
        let spanGuests = transaction?.startChild(operation: "store.guest.load", description: "GuestStoreV2.loadGuestData")
        let spanTasks = transaction?.startChild(operation: "store.task.load", description: "TaskStoreV2.loadTasks")
        let spanSettings = transaction?.startChild(operation: "store.settings.load", description: "SettingsStoreV2.loadSettings")
        
        // Load data from all stores in parallel
        async let budgetLoad = budgetStore.loadBudgetData()
        async let vendorsLoad = vendorStore.loadVendors()
        async let guestsLoad = guestStore.loadGuestData()
        async let tasksLoad = taskStore.loadTasks()
        // Fire-and-forget settings load so it doesn't block dashboard readiness
        Task { @MainActor in
            await settingsStore.loadSettings()
            spanSettings?.finish()
        }
        
        // Wait for core data to complete
        _ = await (budgetLoad, vendorsLoad, guestsLoad, tasksLoad)
        
        // Finish spans and transaction
        spanBudget?.finish()
        spanVendors?.finish()
        spanGuests?.finish()
        spanTasks?.finish()
        // spanSettings finished in its own Task above
        SentryService.shared.finishTransaction(name: "dashboard.load", status: .ok)
        
        logger.info("Dashboard data loaded successfully")
        hasLoaded = true
        
        // Invalidate date cache to ensure fresh calculations
        invalidateDateCache()
    }
}
