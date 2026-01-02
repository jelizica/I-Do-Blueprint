//
//  PaymentScheduleView.swift
//  I Do Blueprint
//
//  Main payment schedule view with filtering and plan grouping
//

import SwiftUI

struct PaymentScheduleView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    
    // Support both embedded and standalone usage (dual initializer pattern)
    var externalCurrentPage: Binding<BudgetPage>?
    @State private var internalCurrentPage: BudgetPage = .paymentSchedule
    
    private var currentPage: Binding<BudgetPage> {
        externalCurrentPage ?? $internalCurrentPage
    }
    
    @State private var paymentPlanSummaries: [PaymentPlanSummary] = []
    @State private var paymentPlanGroups: [PaymentPlanGroup] = []
    @State private var isLoadingPlans = false
    @State private var expandedPlanIds: Set<UUID> = []

    // Filter states
    @State private var selectedFilterOption: PaymentFilterOption = .all
    @State private var showPlanView: Bool = false
    @AppStorage("paymentPlanGroupingStrategy") private var groupingStrategy: PaymentPlanGroupingStrategy = .byExpense

    // Dialog states
    @State private var showingAddPayment = false
    
    // Error state
    @State private var loadError: String?
    @State private var showErrorAlert = false

    /// User's configured timezone - single source of truth for date operations
    private var userTimezone: TimeZone {
        DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
    }
    
    // MARK: - Initializers
    
    /// Embedded usage (from BudgetDashboardHubView)
    init(currentPage: Binding<BudgetPage>) {
        self.externalCurrentPage = currentPage
    }
    
    /// Standalone usage (for previews/testing)
    init() {
        self.externalCurrentPage = nil
    }

    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl
            let availableWidth = geometry.size.width - (horizontalPadding * 2)
            
            VStack(spacing: 0) {
                contentView(windowSize: windowSize, availableWidth: availableWidth, horizontalPadding: horizontalPadding)
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
    }

    // MARK: - Content Views
    
    private func contentView(windowSize: WindowSize, availableWidth: CGFloat, horizontalPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Unified header
            PaymentScheduleUnifiedHeader(
                windowSize: windowSize,
                currentPage: currentPage,
                onAddPayment: { showingAddPayment = true },
                onRefresh: { await budgetStore.refresh() }
            )
            
            headerView(windowSize: windowSize)
            Divider()
            paymentListView(windowSize: windowSize, availableWidth: availableWidth, horizontalPadding: horizontalPadding)
        }
    }

    private func headerView(windowSize: WindowSize) -> some View {
        VStack(spacing: 0) {
            PaymentSummaryHeaderViewV2(
                windowSize: windowSize,
                totalUpcoming: upcomingPaymentsTotal,
                totalOverdue: overduePaymentsTotal,
                scheduleCount: filteredPayments.count
            )

            PaymentFilterBarV2(
                windowSize: windowSize,
                showPlanView: $showPlanView,
                selectedFilterOption: $selectedFilterOption,
                groupingStrategy: $groupingStrategy,
                onViewModeChange: {
                    if showPlanView {
                        Task {
                            await loadPaymentPlanSummaries()
                        }
                    }
                },
                onGroupingChange: {
                    Task {
                        await loadPaymentPlanSummaries()
                    }
                }
            )
        }
    }

    @ViewBuilder
    private func paymentListView(windowSize: WindowSize, availableWidth: CGFloat, horizontalPadding: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                if showPlanView {
                    PaymentPlansListView(
                        isLoadingPlans: isLoadingPlans,
                        loadError: loadError,
                        groupingStrategy: groupingStrategy,
                        paymentPlanSummaries: paymentPlanSummaries,
                        paymentPlanGroups: paymentPlanGroups,
                        paymentSchedules: budgetStore.paymentSchedules,
                        expandedPlanIds: expandedPlanIds,
                        onRetry: {
                            Task {
                                await loadPaymentPlanSummaries()
                            }
                        },
                        onToggleExpansion: toggleExpansion,
                        onTogglePaidStatus: { schedule in
                            Task {
                                do {
                                    try await budgetStore.payments.updatePayment(schedule)
                                } catch {
                                    AppLogger.ui.error("Failed to update payment status", error: error)
                                }
                            }
                        },
                        onUpdate: { schedule in
                            Task {
                                do {
                                    try await budgetStore.payments.updatePayment(schedule)
                                } catch {
                                    AppLogger.ui.error("Failed to update payment", error: error)
                                }
                            }
                        },
                        onDelete: { schedule in
                            Task {
                                do {
                                    try await budgetStore.payments.deletePayment(id: schedule.id)
                                } catch {
                                    AppLogger.ui.error("Failed to delete payment", error: error)
                                }
                            }
                        },
                        getVendorName: getVendorNameById
                    )
                } else {
                    IndividualPaymentsListView(
                        windowSize: windowSize,
                        filteredPayments: filteredPayments,
                        expenses: budgetStore.expenseStore.expenses,
                        onUpdate: { updatedPayment in
                            Task {
                                do {
                                    try await budgetStore.payments.updatePayment(updatedPayment)
                                } catch {
                                    AppLogger.ui.error("Failed to update payment", error: error)
                                }
                            }
                        },
                        onDelete: { paymentToDelete in
                            Task {
                                do {
                                    try await budgetStore.payments.deletePayment(id: paymentToDelete.id)
                                } catch {
                                    AppLogger.ui.error("Failed to delete payment", error: error)
                                }
                            }
                        },
                        getVendorName: getVendorNameById,
                        userTimezone: userTimezone
                    )
                }
            }
            .frame(width: availableWidth)
            .padding(.horizontal, horizontalPadding)
        }
    }

    
    private var addPaymentSheet: some View {
        AddPaymentScheduleView(
            expenses: budgetStore.expenseStore.expenses.filter { $0.paymentStatus != .paid },
            existingPaymentSchedules: budgetStore.paymentSchedules,
            onSave: { newPaymentSchedule in
                Task {
                    do {
                        try await budgetStore.payments.addPayment(newPaymentSchedule)
                    } catch {
                        AppLogger.ui.error("Failed to add payment schedule", error: error)
                    }
                }
            },
            getVendorName: getVendorNameById
        )
        #if os(macOS)
        .frame(minWidth: 1000, maxWidth: 1200, minHeight: 600, maxHeight: 650)
        #endif
    }

    // MARK: - Computed Properties
    
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
    
    // MARK: - Private Helpers
    
    private func toggleExpansion(for planId: UUID) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedPlanIds.contains(planId) {
                expandedPlanIds.remove(planId)
            } else {
                expandedPlanIds.insert(planId)
            }
        }
    }
    
    /// Helper to resolve vendor name with consistent priority:
    /// 1. expense.vendorName (if available)
    /// 2. payment.vendor (if not empty)
    /// 3. AppStores vendor lookup (by vendorId)
    private func getVendorNameById(_ vendorId: Int64?) -> String? {
        // First try to get vendor name from the payment's expense
        if let payment = budgetStore.paymentSchedules.first(where: { $0.vendorId == vendorId }),
           let expense = budgetStore.expenseStore.expenses.first(where: { $0.id == payment.expenseId }),
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
                let summaries = try await budgetStore.payments.fetchPaymentPlanSummaries(
                    groupBy: groupingStrategy,
                    expenses: budgetStore.expenseStore.expenses
                )
                await MainActor.run {
                    paymentPlanSummaries = summaries
                    paymentPlanGroups = []
                }
            } else {
                // Use hierarchical groups for "By Expense" and "By Vendor"
                let groups = try await budgetStore.payments.fetchPaymentPlanGroups(
                    groupBy: groupingStrategy,
                    expenses: budgetStore.expenseStore.expenses
                )
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

#Preview {
    PaymentScheduleView()
}
