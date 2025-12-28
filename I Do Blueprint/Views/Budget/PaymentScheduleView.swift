import SwiftUI

struct PaymentScheduleView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @State private var paymentPlanSummaries: [PaymentPlanSummary] = []
    @State private var paymentPlanGroups: [PaymentPlanGroup] = []
    @State private var isLoadingPlans = false
    @State private var expandedPlanIds: Set<UUID> = []

    // Filter states
    @State private var selectedFilterOption: PaymentFilterOption = .all
    @State private var showPlanView: Bool = false
    @AppStorage("paymentPlanGroupingStrategy") private var groupingStrategy: PaymentPlanGroupingStrategy = .byExpense
    @State private var showGroupingInfo = false

    // Dialog states
    @State private var showingAddPayment = false
    
    // Error state
    @State private var loadError: String?
    @State private var showErrorAlert = false

    /// User's configured timezone - single source of truth for date operations
    private var userTimezone: TimeZone {
        DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
    }

    var filteredPayments: [PaymentSchedule] {
        // Use user's timezone for date comparisons
        var calendar = Calendar.current
        calendar.timeZone = userTimezone
        
        let filtered = budgetStore.paymentSchedules.filter { payment in
            switch selectedFilterOption {
            case .all:
                return true
            case .upcoming:
                return payment.paymentDate > Date() && !payment.paid
            case .overdue:
                return payment.paymentDate < Date() && !payment.paid
            case .thisWeek:
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
                let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
                return payment.paymentDate >= startOfWeek && payment.paymentDate <= endOfWeek
            case .thisMonth:
                let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
                let endOfMonth = calendar.dateInterval(of: .month, for: Date())?.end ?? Date()
                return payment.paymentDate >= startOfMonth && payment.paymentDate <= endOfMonth
            case .paid:
                return payment.paid
            }
        }
        return filtered.sorted { $0.paymentDate < $1.paymentDate }
    }

    var upcomingPaymentsTotal: Double {
        filteredPayments.filter { !$0.paid && $0.paymentDate > Date() }.reduce(0) { $0 + $1.paymentAmount }
    }

    var overduePaymentsTotal: Double {
        filteredPayments.filter { !$0.paid && $0.paymentDate < Date() }.reduce(0) { $0 + $1.paymentAmount }
    }

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Payment Schedule")
                .toolbar {
                    toolbarContent
                }
                .sheet(isPresented: $showingAddPayment) {
                    addPaymentSheet
                }
                .alert("Error Loading Payment Plans", isPresented: $showErrorAlert) {
                    Button("OK") {
                        loadError = nil
                    }
                } message: {
                    if let loadError {
                        Text(loadError)
                    }
                }
        }
        .task {
            await budgetStore.loadBudgetData(force: true)
        }
    }

    private var contentView: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            paymentListView
        }
    }

    private var headerView: some View {
        VStack(spacing: 0) {
            PaymentSummaryHeaderView(
                totalUpcoming: upcomingPaymentsTotal,
                totalOverdue: overduePaymentsTotal,
                scheduleCount: filteredPayments.count)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))

            filterView
        }
    }

    private var filterView: some View {
        VStack(spacing: 12) {
            // View mode toggle
            HStack(spacing: 12) {
                Text("View")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Picker("View Mode", selection: $showPlanView) {
                    Text("Individual").tag(false)
                    Text("Plans").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .onChange(of: showPlanView) { newValue in
                    if newValue {
                        Task {
                            await loadPaymentPlanSummaries()
                        }
                    }
                }
            }
            
            // Filter/Group By picker (shown for both views)
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Text(showPlanView ? "Group By" : "Filter")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    if showPlanView {
                        Button(action: { showGroupingInfo = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showGroupingInfo) {
                            GroupingInfoView()
                                .frame(width: 320)
                                .padding()
                        }
                    }
                }
                
                if showPlanView {
                    Picker("Group By", selection: $groupingStrategy) {
                        ForEach(PaymentPlanGroupingStrategy.allCases, id: \.self) { strategy in
                            Label(strategy.displayName, systemImage: strategy.icon).tag(strategy)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .onChange(of: groupingStrategy) { _ in
                        Task {
                            await loadPaymentPlanSummaries()
                        }
                    }
                } else {
                    Picker("Filter", selection: $selectedFilterOption) {
                        ForEach(PaymentFilterOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder
    private var paymentListView: some View {
        if showPlanView {
            // Show payment plan summaries
            planSummariesView
        } else {
            // Show individual payments
            individualPaymentsView
        }
    }
    
    @ViewBuilder
    private var planSummariesView: some View {
        if isLoadingPlans {
            VStack {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Text("Loading payment plans...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
                Spacer()
            }
        } else if let loadError {
            // Show inline error view
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text("Failed to Load Payment Plans")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(loadError)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: {
                    Task {
                        await loadPaymentPlanSummaries()
                    }
                }) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
        } else if groupingStrategy == .byPlanId {
            // Show flat list for "By Plan ID"
            if paymentPlanSummaries.isEmpty {
                ContentUnavailableView(
                    "No Payment Plans",
                    systemImage: "calendar.badge.clock",
                    description: Text("Payment plans will appear here when you have multiple payments for the same expense."))
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(paymentPlanSummaries) { plan in
                            ExpandablePaymentPlanCardView(
                                plan: plan,
                                paymentSchedules: budgetStore.paymentSchedules,
                                isExpanded: expandedPlanIds.contains(plan.id),
                                onToggle: {
                                    toggleExpansion(for: plan.id)
                                },
                                onTogglePaidStatus: { schedule in
                                    Task {
                                        await budgetStore.updatePaymentSchedule(schedule)
                                    }
                                },
                                onUpdate: { schedule in
                                    Task {
                                        await budgetStore.updatePaymentSchedule(schedule)
                                    }
                                },
                                onDelete: { schedule in
                                    Task {
                                        await budgetStore.deletePaymentSchedule(id: schedule.id)
                                    }
                                },
                                getVendorName: getVendorNameById
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        } else {
            // Show hierarchical groups for "By Expense" and "By Vendor"
            if paymentPlanGroups.isEmpty {
                ContentUnavailableView(
                    "No Payment Plans",
                    systemImage: "calendar.badge.clock",
                    description: Text("Payment plans will appear here when you have multiple payments."))
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(paymentPlanGroups) { group in
                            HierarchicalPaymentGroupView(
                                group: group,
                                paymentSchedules: budgetStore.paymentSchedules,
                                onTogglePaidStatus: { schedule in
                                    Task {
                                        await budgetStore.updatePaymentSchedule(schedule)
                                    }
                                },
                                onUpdate: { schedule in
                                    Task {
                                        await budgetStore.updatePaymentSchedule(schedule)
                                    }
                                },
                                onDelete: { schedule in
                                    Task {
                                        await budgetStore.deletePaymentSchedule(id: schedule.id)
                                    }
                                },
                                getVendorName: getVendorNameById
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }
    
    private func toggleExpansion(for planId: UUID) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedPlanIds.contains(planId) {
                expandedPlanIds.remove(planId)
            } else {
                expandedPlanIds.insert(planId)
            }
        }
    }
    
    @ViewBuilder
    private var individualPaymentsView: some View {
        if filteredPayments.isEmpty {
            ContentUnavailableView(
                "No Payment Schedules",
                systemImage: "calendar.circle",
                description: Text("Add payment schedules to track upcoming payments and deadlines"))
        } else {
            List {
                ForEach(groupedPayments, id: \.key) { group in
                    Section(group.key) {
                        ForEach(group.value, id: \.id) { payment in
                            PaymentScheduleRowView(
                                payment: payment,
                                expense: getExpenseForPayment(payment),
                                onUpdate: { updatedPayment in
                                    Task {
                                        await budgetStore.updatePaymentSchedule(updatedPayment)
                                    }
                                },
                                onDelete: { paymentToDelete in
                                    Task {
                                        await budgetStore.deletePaymentSchedule(id: paymentToDelete.id)
                                    }
                                },
                                getVendorName: { vendorId in
                                    // First try to get vendor name from the payment's expense
                                    if let expense = getExpenseForPayment(payment) {
                                        return expense.vendorName
                                    }
                                    // Fall back to payment's vendor field
                                    return payment.vendor.isEmpty ? nil : payment.vendor
                                }
                            )
                            .id(payment.id)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: {
                showingAddPayment = true
            }) {
                Label("Add Payment", systemImage: "plus")
            }
        }

        ToolbarItem(placement: .secondaryAction) {
            Button(action: {
                Task {
                    await budgetStore.refreshBudgetData()
                }
            }) {
                Image(systemName: "arrow.clockwise")
            }
        }
    }

    private var addPaymentSheet: some View {
        AddPaymentScheduleView(
            expenses: budgetStore.expenses.filter { $0.paymentStatus != .paid },
            existingPaymentSchedules: budgetStore.paymentSchedules,
            onSave: { newPaymentSchedule in
                Task {
                    await budgetStore.addPaymentSchedule(newPaymentSchedule)
                }
            },
            getVendorName: getVendorNameById
        )
        #if os(macOS)
        .frame(minWidth: 1000, maxWidth: 1200, minHeight: 600, maxHeight: 650)
        #endif
    }

    private var groupedPayments: [(key: String, value: [PaymentSchedule])] {
        // Use user's timezone for month grouping
        let grouped = Dictionary(grouping: filteredPayments) { payment in
            DateFormatting.formatDate(payment.paymentDate, format: "MMMM yyyy", timezone: userTimezone)
        }
        return grouped.sorted { first, second in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.timeZone = userTimezone

            guard let firstDate = formatter.date(from: first.key),
                  let secondDate = formatter.date(from: second.key) else {
                return first.key < second.key
            }

            return firstDate < secondDate
        }
    }

    private func getExpenseForPayment(_ payment: PaymentSchedule) -> Expense? {
        budgetStore.expenses.first { $0.id == payment.expenseId }
    }
    
    /// Helper to resolve vendor name with consistent priority:
    /// 1. expense.vendorName (if available)
    /// 2. payment.vendor (if not empty)
    /// 3. AppStores vendor lookup (by vendorId)
    private func getVendorNameById(_ vendorId: Int64?) -> String? {
        // First try to get vendor name from the payment's expense
        if let payment = budgetStore.paymentSchedules.first(where: { $0.vendorId == vendorId }),
           let expense = budgetStore.expenses.first(where: { $0.id == payment.expenseId }),
           let vendorName = expense.vendorName, !vendorName.isEmpty {
            return vendorName
        }
        // Fall back to payment's vendor field
        if let payment = budgetStore.paymentSchedules.first(where: { $0.vendorId == vendorId }),
           !payment.vendor.isEmpty {
            return payment.vendor
        }
        // Finally fall back to AppStores lookup
        guard let vendorId = vendorId else { return nil }
        let vendors = AppStores.shared.vendor.vendors
        return vendors.first(where: { $0.id == vendorId })?.vendorName
    }
    
    private func loadPaymentPlanSummaries() async {
        // Ensure we're on the main thread for state updates
        await MainActor.run {
            isLoadingPlans = true
            loadError = nil
        }
        
        do {
            if groupingStrategy == .byPlanId {
                // Use flat summaries for "By Plan ID"
                let summaries = try await budgetStore.fetchPaymentPlanSummaries(groupBy: groupingStrategy)
                await MainActor.run {
                    paymentPlanSummaries = summaries
                    paymentPlanGroups = []
                }
            } else {
                // Use hierarchical groups for "By Expense" and "By Vendor"
                let groups = try await budgetStore.fetchPaymentPlanGroups(groupBy: groupingStrategy)
                await MainActor.run {
                    paymentPlanGroups = groups
                    paymentPlanSummaries = []
                }
            }
        } catch {
            // Handle error with user-friendly message
            let errorMessage: String
            if let budgetError = error as? BudgetError {
                errorMessage = budgetError.localizedDescription
            } else {
                errorMessage = "Unable to load payment plans. Please check your connection and try again."
            }
            
            // Log the error with full details
            AppLogger.database.error("Error loading payment plan summaries: \(error)")
            
            // Update state on main thread
            await MainActor.run {
                // Clear existing data to avoid showing stale information
                paymentPlanSummaries = []
                paymentPlanGroups = []
                
                // Set user-friendly error message
                loadError = errorMessage
                showErrorAlert = true
            }
        }
        
        // Always reset loading state
        await MainActor.run {
            isLoadingPlans = false
        }
    }
}

// MARK: - Grouping Info View

struct GroupingInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Plan Grouping")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Choose how to group your payment schedules:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            ForEach(PaymentPlanGroupingStrategy.allCases, id: \.self) { strategy in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: strategy.icon)
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text(strategy.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(strategy.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                
                if strategy != PaymentPlanGroupingStrategy.allCases.last {
                    Divider()
                }
            }
            
            Spacer()
            
            Text("Your preference is saved automatically.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()
        }
    }
}

// MARK: - Supporting Views

struct PaymentSummaryHeaderView: View {
    let totalUpcoming: Double
    let totalOverdue: Double
    let scheduleCount: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                PaymentOverviewCard(
                    title: "Upcoming Payments",
                    value: NumberFormatter.currency.string(from: NSNumber(value: totalUpcoming)) ?? "$0",
                    subtitle: "Due soon",
                    icon: "calendar",
                    color: AppColors.Budget.pending)

                PaymentOverviewCard(
                    title: "Overdue Payments",
                    value: NumberFormatter.currency.string(from: NSNumber(value: totalOverdue)) ?? "$0",
                    subtitle: "Past due",
                    icon: "exclamationmark.triangle.fill",
                    color: AppColors.Budget.overBudget)

                PaymentOverviewCard(
                    title: "Total Schedules",
                    value: "\(scheduleCount)",
                    subtitle: "Active schedules",
                    icon: "list.number",
                    color: AppColors.Budget.allocated)
            }
        }
    }
}

struct PaymentScheduleRowView: View {
    let payment: PaymentSchedule
    let expense: Expense?
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?

    @State private var showingEditModal = false

    var body: some View {
        Button(action: {
            showingEditModal = true
        }) {
            HStack(spacing: 16) {
                // Payment status indicator
                Circle()
                    .fill(payment.paid ? AppColors.Budget.income : AppColors.Budget.pending)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(expense?.expenseName ?? "Unknown Expense")
                            .font(.headline)
                            .fontWeight(.medium)

                        Spacer()

                        Text(NumberFormatter.currency.string(from: NSNumber(value: payment.paymentAmount)) ?? "$0")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(payment.paid ? AppColors.Budget.income : .primary)
                    }

                    Text(payment.notes ?? "No description")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Due: \(formatDateInUserTimezone(payment.paymentDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(payment.paid ? "Paid" : "Pending")
                            .font(.caption)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xxs)
                            .background(payment.paid ? AppColors.Budget.income.opacity(0.2) : AppColors.Budget.pending.opacity(0.2))
                            .foregroundColor(payment.paid ? AppColors.Budget.income : AppColors.Budget.pending)
                            .clipShape(Capsule())
                    }
                }

                // Quick action buttons
                HStack(spacing: 8) {
                    Button(action: {
                        var updatedPayment = payment
                        updatedPayment.paid.toggle()
                        updatedPayment.updatedAt = Date()
                        onUpdate(updatedPayment)
                    }) {
                        Image(systemName: payment.paid ? "checkmark.square.fill" : "square")
                            .foregroundColor(payment.paid ? AppColors.Budget.income : .secondary)
                            .font(.title2)
                    }
                    .buttonStyle(.plain)

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEditModal) {
            PaymentEditModal(
                payment: payment,
                expense: expense,
                getVendorName: getVendorName,
                onUpdate: onUpdate,
                onDelete: {
                    onDelete(payment)
                })
        }
    }
}

struct PaymentOverviewCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Filter Options

enum PaymentFilterOption: String, CaseIterable {
    case all = "all"
    case upcoming = "upcoming"
    case overdue = "overdue"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case paid = "paid"

    var displayName: String {
        switch self {
        case .all: "All"
        case .upcoming: "Upcoming"
        case .overdue: "Overdue"
        case .thisWeek: "This Week"
        case .thisMonth: "This Month"
        case .paid: "Paid"
        }
    }
}

// MARK: - Helper Functions

private func formatDateInUserTimezone(_ date: Date) -> String {
    // Use user's timezone for date formatting
    let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
    return DateFormatting.formatDateMedium(date, timezone: userTimezone)
}

extension PaymentScheduleView {
    /// Helper to format dates using the view's cached timezone
    private func formatDate(_ date: Date) -> String {
        DateFormatting.formatDateMedium(date, timezone: userTimezone)
    }
}

#Preview {
    PaymentScheduleView()
}
