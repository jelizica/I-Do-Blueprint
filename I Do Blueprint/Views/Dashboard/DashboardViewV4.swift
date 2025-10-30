//
//  DashboardViewV4.swift
//  I Do Blueprint
//
//  Modern dashboard with Supabase data integration
//  Displays real-time wedding planning metrics and countdown
//

import SwiftUI

struct DashboardViewV4: View {
    private let logger = AppLogger.ui
    @Environment(\.appStores) private var appStores
    
    // Convenience accessors
    private var budgetStore: BudgetStoreV2 { appStores.budget }
    private var vendorStore: VendorStoreV2 { appStores.vendor }
    private var guestStore: GuestStoreV2 { appStores.guest }
    private var taskStore: TaskStoreV2 { appStores.task }
    private var settingsStore: SettingsStoreV2 { appStores.settings }
    
    @State private var isLoading = false
    @State private var hasLoaded = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.fromHex("F8F9FA"),
                        Color.fromHex("E9ECEF")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading dashboard...")
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textSecondary)
                } else if hasLoaded {
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Hero Section - Wedding Countdown
                            WeddingCountdownCard(
                                weddingDate: weddingDate,
                                daysUntil: daysUntilWedding,
                                partner1Name: partner1DisplayName,
                                partner2Name: partner2DisplayName
                            )
                            .padding(.horizontal, Spacing.xxl)
                            
                            // Key Metrics Row
                            HStack(spacing: Spacing.lg) {
                                // RSVPs
                                DashboardMetricCard(
                                    icon: "person.2.fill",
                                    iconColor: AppColors.Guest.confirmed,
                                    title: "RSVPs",
                                    value: "\(rsvpYesCount)/\(totalGuests)",
                                    subtitle: "\(rsvpPendingCount) pending"
                                )
                                
                                // Vendors Booked
                                DashboardMetricCard(
                                    icon: "briefcase.fill",
                                    iconColor: AppColors.Vendor.booked,
                                    title: "Vendors Booked",
                                    value: "\(vendorsBookedCount)/\(totalVendors)",
                                    subtitle: "\(vendorsPendingCount) pending"
                                )
                                
                                // Budget Used
                                DashboardMetricCard(
                                    icon: "dollarsign.circle.fill",
                                    iconColor: budgetColor,
                                    title: "Budget Used",
                                    value: "\(Int(budgetPercentage))%",
                                    subtitle: "$\(formatCurrency(budgetRemaining)) left"
                                )
                            }
                            .padding(.horizontal, Spacing.xxl)
                            
                            // Main Content Grid
                            HStack(alignment: .top, spacing: Spacing.lg) {
                                // Left Column
                                VStack(spacing: Spacing.lg) {
                                    BudgetOverviewCardV4(store: budgetStore, vendorStore: vendorStore)
                                    TaskProgressCardV4(store: taskStore)
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Right Column
                                VStack(spacing: Spacing.lg) {
                                    GuestResponsesCardV4(store: guestStore)
                                    VendorStatusCardV4(store: vendorStore)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, Spacing.xxl)
                            
                            // Quick Actions
                            QuickActionsCardV4()
                                .padding(.horizontal, Spacing.xxl)
                        }
                        .padding(.vertical, Spacing.xxl)
                    }
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: Spacing.md) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        
                        Button {
                            Task { await loadDashboardData() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .buttonStyle(.plain)
                        .accessibleActionButton(
                            label: "Refresh dashboard",
                            hint: "Reload all dashboard data"
                        )
                    }
                }
            }
        }
        .task {
            if !hasLoaded {
                await loadDashboardData()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var weddingDate: Date? {
        guard hasLoaded else { return nil }
        
        let dateString = settingsStore.settings.global.weddingDate
        guard !dateString.isEmpty else { return nil }
        
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: dateString) {
            return date
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: dateString)
    }
    
    private var daysUntilWedding: Int {
        guard let weddingDate = weddingDate else { return 0 }
        
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let wedding = calendar.startOfDay(for: weddingDate)
        return calendar.dateComponents([.day], from: now, to: wedding).day ?? 0
    }
    
    // Partner Names - Use nicknames if available, otherwise full names
    private var partner1DisplayName: String {
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
    
    private var partner2DisplayName: String {
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
    
    // Guest Metrics
    private var totalGuests: Int {
        guestStore.guests.count
    }
    
    private var rsvpYesCount: Int {
        guestStore.guests.filter { 
            $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed 
        }.count
    }
    
    private var rsvpNoCount: Int {
        guestStore.guests.filter { $0.rsvpStatus == .declined }.count
    }
    
    private var rsvpPendingCount: Int {
        guestStore.guests.filter { 
            $0.rsvpStatus == .pending || $0.rsvpStatus == .invited 
        }.count
    }
    
    // Vendor Metrics
    private var totalVendors: Int {
        vendorStore.vendors.count
    }
    
    private var vendorsBookedCount: Int {
        vendorStore.vendors.filter { $0.isBooked == true }.count
    }
    
    private var vendorsPendingCount: Int {
        vendorStore.vendors.filter { $0.isBooked != true }.count
    }
    
    // Budget Metrics - Based on Primary Development Scenario
    private var budgetPercentage: Double {
        guard let primaryScenario = budgetStore.primaryScenario else {
            return 0
        }
        
        let totalPaid = budgetStore.payments.totalPaid
        guard primaryScenario.totalWithTax > 0 else { return 0 }
        return (totalPaid / primaryScenario.totalWithTax) * 100
    }
    
    private var budgetRemaining: Double {
        guard let primaryScenario = budgetStore.primaryScenario else {
            return 0
        }
        
        let totalPaid = budgetStore.payments.totalPaid
        return primaryScenario.totalWithTax - totalPaid
    }
    
    private var totalBudget: Double {
        guard let primaryScenario = budgetStore.primaryScenario else {
            return 0
        }
        return primaryScenario.totalWithTax
    }
    
    private var totalPaid: Double {
        return budgetStore.payments.totalPaid
    }
    
    private var totalExpenses: Double {
        guard case .loaded(let budgetData) = budgetStore.loadingState else {
            return 0
        }
        return budgetData.expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var categories: [BudgetCategory] {
        guard case .loaded(let budgetData) = budgetStore.loadingState else {
            return []
        }
        return budgetData.categories
    }
    
    private var budgetColor: Color {
        if budgetPercentage >= 100 {
            return AppColors.error
        } else if budgetPercentage >= 90 {
            return AppColors.warning
        } else {
            return AppColors.success
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
    
    // MARK: - Data Loading
    
    private func loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }
        
        logger.info("Loading dashboard data...")
        
        // Load data from all stores in parallel
        async let budgetLoad = budgetStore.loadBudgetData()
        async let vendorsLoad = vendorStore.loadVendors()
        async let guestsLoad = guestStore.loadGuestData()
        async let tasksLoad = taskStore.loadTasks()
        async let settingsLoad = settingsStore.loadSettings()
        
        // Wait for all to complete
        _ = await (budgetLoad, vendorsLoad, guestsLoad, tasksLoad, settingsLoad)
        
        logger.info("Dashboard data loaded successfully")
        hasLoaded = true
    }
}

// MARK: - Wedding Countdown Card

private struct WeddingCountdownCard: View {
    let weddingDate: Date?
    let daysUntil: Int
    let partner1Name: String
    let partner2Name: String
    
    private var weddingTitle: String {
        if !partner1Name.isEmpty && !partner2Name.isEmpty {
            return "\(partner1Name) & \(partner2Name)'s Wedding"
        } else if !partner1Name.isEmpty {
            return "\(partner1Name)'s Wedding"
        } else if !partner2Name.isEmpty {
            return "\(partner2Name)'s Wedding"
        } else {
            return "Our Wedding"
        }
    }
    
    var body: some View {
        ZStack {
            // Muted gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.97),
                    Color(red: 0.98, green: 0.98, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: Spacing.xxl * 2) {
                // Left side - Wedding info
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(weddingTitle)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.22))
                    
                    if let weddingDate = weddingDate {
                        Text(formatWeddingDate(weddingDate))
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.45, green: 0.48, blue: 0.53))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Right side - Emphasized day count
                VStack(spacing: Spacing.xs) {
                    Text("\(daysUntil)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(Color(red: 0.93, green: 0.28, blue: 0.60))
                    
                    Text("Days Until")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.45, green: 0.48, blue: 0.53))
                        .textCase(.uppercase)
                        .tracking(1.2)
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                )
            }
            .padding(.horizontal, Spacing.xxl * 1.5)
        }
        .frame(height: 180)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private func formatWeddingDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Dashboard Metric Card

private struct DashboardMetricCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 48, height: 48)
                    .background(iconColor.opacity(0.1))
                    .cornerRadius(CornerRadius.md)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                Text(value)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .cornerRadius(CornerRadius.md)
        .shadow(color: AppColors.shadowLight, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Budget Overview Card V4

private struct BudgetOverviewCardV4: View {
    @ObservedObject var store: BudgetStoreV2
    @ObservedObject var vendorStore: VendorStoreV2
    
    private var totalBudget: Double {
        guard let primaryScenario = store.primaryScenario else {
            return 0
        }
        return primaryScenario.totalWithTax
    }
    
    private var totalPaid: Double {
        return store.payments.totalPaid
    }
    
    private var totalExpenses: Double {
        guard case .loaded(let budgetData) = store.loadingState else {
            return 0
        }
        return budgetData.expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var remainingBudget: Double {
        return totalBudget - totalPaid
    }
    
    private var paymentsThisMonth: [PaymentSchedule] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        return store.payments.paymentSchedules.filter { payment in
            payment.paymentDate >= startOfMonth && payment.paymentDate <= endOfMonth
        }.sorted { $0.paymentDate < $1.paymentDate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Budget Overview")
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)
                
                if let scenario = store.primaryScenario {
                    Text("$\(formatAmount(totalPaid)) of $\(formatAmount(scenario.totalWithTax)) paid")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    Text("No primary scenario")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.sm)
            
            Divider()
            
            // Payment vs Expense Breakdown
            VStack(spacing: Spacing.md) {
                // Payments Progress
                BudgetProgressRow(
                    label: "Payments",
                    amount: totalPaid,
                    total: totalBudget,
                    color: Color(red: 0.23, green: 0.51, blue: 0.96)
                )
                
                // Expenses Progress
                BudgetProgressRow(
                    label: "Expenses",
                    amount: totalExpenses,
                    total: totalBudget,
                    color: Color(red: 0.92, green: 0.70, blue: 0.03)
                )
                
                // Remaining Budget (moved here)
                HStack {
                    Text("Remaining Budget")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("$\(formatAmount(remainingBudget))")
                        .font(Typography.caption.weight(.semibold))
                        .foregroundColor(AppColors.success)
                }
                .padding(.top, Spacing.xs)
                
                // Payments Due This Month
                if !paymentsThisMonth.isEmpty {
                    Divider()
                        .padding(.vertical, Spacing.sm)
                    
                    Text("Payments Due This Month")
                        .font(Typography.caption.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    ForEach(paymentsThisMonth.prefix(5)) { payment in
                        PaymentDueRow(payment: payment, vendorStore: vendorStore)
                    }
                }
            }
            
            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 430)
        .background(.white)
        .shadow(color: AppColors.shadowLight, radius: 2, x: 0, y: 1)
        .cornerRadius(CornerRadius.md)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

private struct PaymentDueRow: View {
    let payment: PaymentSchedule
    @ObservedObject var vendorStore: VendorStoreV2
    
    private var vendorName: String {
        guard let vendorId = payment.vendorId else {
            return payment.notes ?? "Payment"
        }
        
        // Look up vendor name from vendor store
        if let vendor = vendorStore.vendors.first(where: { $0.id == vendorId }) {
            return vendor.vendorName
        }
        
        return payment.notes ?? "Payment"
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(formatDate(payment.paymentDate))
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(vendorName)
                    .font(Typography.caption2)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("$\(formatAmount(payment.paymentAmount))")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(payment.paid ? "Paid" : "Unpaid")
                    .font(Typography.caption2)
                    .foregroundColor(payment.paid ? AppColors.success : AppColors.warning)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

private struct BudgetProgressRow: View {
    let label: String
    let amount: Double
    let total: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("$\(formatAmount(amount))")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(red: 0.93, green: 0.93, blue: 0.93))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var progressPercentage: CGFloat {
        guard total > 0 else { return 0 }
        return min(CGFloat(amount / total), 1.0)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

private struct BudgetCategoryRow: View {
    let category: BudgetCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 12, height: 12)
                
                Text(category.categoryName)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("$\(formatAmount(category.spentAmount))")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(red: 0.93, green: 0.93, blue: 0.93))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(categoryColor)
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var progressPercentage: CGFloat {
        guard category.allocatedAmount > 0 else { return 0 }
        return min(CGFloat(category.spentAmount / category.allocatedAmount), 1.0)
    }
    
    private var categoryColor: Color {
        // Assign colors based on category name
        switch category.categoryName.lowercased() {
        case let name where name.contains("venue"):
            return Color(red: 0.93, green: 0.28, blue: 0.60)
        case let name where name.contains("catering"):
            return Color(red: 0.23, green: 0.51, blue: 0.96)
        case let name where name.contains("photo"):
            return Color(red: 0.13, green: 0.77, blue: 0.37)
        case let name where name.contains("flower"):
            return Color(red: 0.92, green: 0.70, blue: 0.03)
        case let name where name.contains("music"):
            return Color(red: 0.66, green: 0.33, blue: 0.97)
        default:
            return AppColors.textSecondary
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Task Progress Card V4

private struct TaskProgressCardV4: View {
    @ObservedObject var store: TaskStoreV2
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Task Manager")
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(remainingTasks) tasks remaining")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.bottom, Spacing.sm)
            
            Divider()
            
            // Recent Tasks
            VStack(spacing: Spacing.md) {
                ForEach(store.tasks.prefix(5)) { task in
                    DashboardTaskRow(task: task)
                }
            }
            
            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 347)
        .background(.white)
        .shadow(color: AppColors.shadowLight, radius: 2, x: 0, y: 1)
        .cornerRadius(CornerRadius.md)
    }
    
    private var remainingTasks: Int {
        store.tasks.filter { $0.status != .completed }.count
    }
}

private struct DashboardTaskRow: View {
    let task: WeddingTask
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.status == .completed ? AppColors.success : AppColors.textSecondary)
            
            Text(task.taskName)
                .font(Typography.caption)
                .foregroundColor(task.status == .completed ? AppColors.textSecondary : AppColors.textPrimary)
                .strikethrough(task.status == .completed)
            
            Spacer()
            
            if let dueDate = task.dueDate {
                Text(dueDateText(dueDate))
                    .font(Typography.caption)
                    .foregroundColor(dueDateColor(dueDate))
            }
        }
    }
    
    private func dueDateText(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Due today"
        } else if calendar.isDateInTomorrow(date) {
            return "Due tomorrow"
        } else {
            let days = calendar.dateComponents([.day], from: now, to: date).day ?? 0
            if days > 0 {
                return "Due in \(days) days"
            } else {
                return "Overdue"
            }
        }
    }
    
    private func dueDateColor(_ date: Date) -> Color {
        let calendar = Calendar.current
        let now = Date()
        let days = calendar.dateComponents([.day], from: now, to: date).day ?? 0
        
        if days < 0 {
            return AppColors.error
        } else if days <= 1 {
            return AppColors.warning
        } else {
            return AppColors.textSecondary
        }
    }
}

// MARK: - Guest Responses Card V4

private struct GuestResponsesCardV4: View {
    @ObservedObject var store: GuestStoreV2
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Guest Responses")
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(respondedCount) of \(totalGuests) guests responded")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)
            
            Divider()
            
            // Stats
            HStack(spacing: Spacing.xl) {
                StatColumn(value: attendingCount, label: "Attending", color: AppColors.success)
                StatColumn(value: declinedCount, label: "Declined", color: AppColors.error)
                StatColumn(value: pendingCount, label: "Pending", color: AppColors.textSecondary)
            }
            .padding(.vertical, Spacing.md)
            
            Divider()
            
            // Recent Responses
            VStack(spacing: Spacing.md) {
                ForEach(store.guests.prefix(8)) { guest in
                    DashboardV4GuestRow(guest: guest)
                }
            }
            
            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 407)
        .background(.white)
        .shadow(color: AppColors.shadowLight, radius: 2, x: 0, y: 1)
        .cornerRadius(CornerRadius.md)
    }
    
    private var totalGuests: Int {
        store.guests.count
    }
    
    private var attendingCount: Int {
        store.guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count
    }
    
    private var declinedCount: Int {
        store.guests.filter { $0.rsvpStatus == .declined }.count
    }
    
    private var pendingCount: Int {
        store.guests.filter { $0.rsvpStatus == .pending || $0.rsvpStatus == .invited }.count
    }
    
    private var respondedCount: Int {
        attendingCount + declinedCount
    }
}

private struct StatColumn: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DashboardV4GuestRow: View {
    let guest: Guest
    @State private var avatarImage: NSImage?
    @State private var isLoadingAvatar = false
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Avatar
            Group {
                if let image = avatarImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                } else {
                    // Fallback to initials
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .overlay {
                            Text(guest.initials)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(statusColor)
                        }
                }
            }
            .task {
                await loadAvatar()
            }
            .accessibilityLabel("Avatar for \(guest.fullName)")
            
            Text(guest.fullName)
                .font(Typography.caption)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Text(statusText)
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(statusColor)
        }
    }
    
    private var statusText: String {
        switch guest.rsvpStatus {
        case .attending, .confirmed:
            return "Attending"
        case .declined:
            return "Declined"
        default:
            return "Pending"
        }
    }
    
    private var statusColor: Color {
        switch guest.rsvpStatus {
        case .attending, .confirmed:
            return AppColors.success
        case .declined:
            return AppColors.error
        default:
            return AppColors.textSecondary
        }
    }
    
    // MARK: - Avatar Loading
    
    private func loadAvatar() async {
        do {
            let image = try await guest.fetchAvatar(
                size: CGSize(width: 48, height: 48) // 2x for retina
            )
            await MainActor.run {
                avatarImage = image
            }
        } catch {
            // Silently fail, keep showing initials
            // Error already logged by MultiAvatarService
        }
    }
}

// MARK: - Vendor Status Card V4

private struct VendorStatusCardV4: View {
    @ObservedObject var store: VendorStoreV2
    @State private var selectedVendor: Vendor?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Our Vendors")
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("\(bookedCount) vendors booked")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.bottom, Spacing.sm)
            
            Divider()
            
            // Vendor List
            VStack(spacing: Spacing.md) {
                ForEach(store.vendors.prefix(7)) { vendor in
                    VendorRow(vendor: vendor)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedVendor = vendor
                        }
                }
            }
            
            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 467)
        .background(.white)
        .shadow(color: AppColors.shadowLight, radius: 2, x: 0, y: 1)
        .cornerRadius(CornerRadius.md)
        .sheet(item: $selectedVendor) { vendor in
            VendorDetailModal(vendor: vendor, vendorStore: store)
        }
    }
    
    private var bookedCount: Int {
        store.vendors.filter { $0.isBooked == true }.count
    }
}

private struct VendorRow: View {
    let vendor: Vendor
    @State private var loadedImage: NSImage?
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(vendorColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Group {
                        if let image = loadedImage {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: vendorIcon)
                                .foregroundColor(vendorColor)
                        }
                    }
                )
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(vendor.vendorName)
                    .font(Typography.caption.weight(.semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(vendor.vendorType ?? "Vendor")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Text(vendor.isBooked == true ? "✓ Booked" : "Pending")
                .font(Typography.caption)
                .foregroundColor(vendor.isBooked == true ? AppColors.success : AppColors.warning)
        }
        .task(id: vendor.imageUrl) {
            await loadVendorImage()
        }
    }
    
    /// Load vendor image asynchronously from URL
    private func loadVendorImage() async {
        guard let imageUrl = vendor.imageUrl,
              let url = URL(string: imageUrl) else {
            loadedImage = nil
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let nsImage = NSImage(data: data) {
                await MainActor.run {
                    loadedImage = nsImage
                }
            }
        } catch {
            await MainActor.run {
                loadedImage = nil
            }
        }
    }
    
    private var vendorIcon: String {
        guard let vendorType = vendor.vendorType?.lowercased() else {
            return "briefcase.fill"
        }
        
        if vendorType.contains("photo") {
            return "camera.fill"
        } else if vendorType.contains("cater") {
            return "fork.knife"
        } else if vendorType.contains("flower") {
            return "leaf.fill"
        } else if vendorType.contains("music") {
            return "music.note"
        } else {
            return "briefcase.fill"
        }
    }
    
    private var vendorColor: Color {
        guard let vendorType = vendor.vendorType?.lowercased() else {
            return Color(red: 0.95, green: 0.96, blue: 0.96)
        }
        
        if vendorType.contains("photo") {
            return Color(red: 0.99, green: 0.91, blue: 0.95)
        } else if vendorType.contains("cater") {
            return Color(red: 0.86, green: 0.92, blue: 1)
        } else if vendorType.contains("flower") {
            return Color(red: 1, green: 0.98, blue: 0.76)
        } else if vendorType.contains("music") {
            return Color(red: 0.95, green: 0.91, blue: 1)
        } else {
            return Color(red: 0.95, green: 0.96, blue: 0.96)
        }
    }
}

// MARK: - Quick Actions Card V4

private struct QuickActionsCardV4: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Quick Actions")
                .font(Typography.subheading)
                .foregroundColor(AppColors.textPrimary)
                .padding(.bottom, Spacing.sm)
            
            Divider()
            
            HStack(spacing: Spacing.lg) {
                DashboardV4QuickActionButton(
                    icon: "envelope.fill",
                    title: "Send Invites",
                    color: Color(red: 0.93, green: 0.28, blue: 0.60)
                )
                
                DashboardV4QuickActionButton(
                    icon: "calendar.badge.plus",
                    title: "Add Event",
                    color: Color(red: 0.23, green: 0.51, blue: 0.96)
                )
                
                DashboardV4QuickActionButton(
                    icon: "dollarsign.circle.fill",
                    title: "Update Budget",
                    color: Color(red: 0.13, green: 0.77, blue: 0.37)
                )
                
                DashboardV4QuickActionButton(
                    icon: "person.badge.plus",
                    title: "Find Vendors",
                    color: Color(red: 0.66, green: 0.33, blue: 0.97)
                )
            }
        }
        .padding(Spacing.lg)
        .background(.white)
        .shadow(color: AppColors.shadowLight, radius: 2, x: 0, y: 1)
        .cornerRadius(CornerRadius.md)
    }
}

private struct DashboardV4QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(title)
                .font(Typography.caption.weight(.semibold))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(color.opacity(0.1))
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    DashboardViewV4()
        .environmentObject(AppStores.shared)
        .frame(width: 1400, height: 900)
}
