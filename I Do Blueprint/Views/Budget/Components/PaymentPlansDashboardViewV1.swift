//
//  PaymentPlansDashboardViewV1.swift
//  I Do Blueprint
//
//  Dashboard view for payment plans with KPI cards and vendor breakdown
//  Features: glassmorphism design, theme-aware styling, progress tracking
//
//  Version: V1
//  Integration: Replaces PaymentPlansListView in PaymentScheduleView (Plans tab)
//

import SwiftUI

// MARK: - Payment Plans Dashboard View V1

struct PaymentPlansDashboardViewV1: View {
    let windowSize: WindowSize
    let isLoadingPlans: Bool
    let loadError: String?
    let paymentSchedules: [PaymentSchedule]
    let expenses: [Expense]
    let searchQuery: String
    let groupingStrategy: PaymentPlanGroupingStrategy

    let onRetry: () -> Void
    let onTogglePaidStatus: (PaymentSchedule) -> Void
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?
    let onPaymentTap: (PaymentSchedule) -> Void

    // Selection mode support - selecting a plan selects all its payments
    @Binding var isSelectionMode: Bool
    @Binding var selectedPaymentIds: Set<Int64>
    let onBulkDelete: ([Int64]) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedGroupIds: Set<String> = []
    @State private var hoveredCardId: String?

    private var isDarkMode: Bool { colorScheme == .dark }

    // MARK: - Computed Properties

    /// Grouped payments based on selected strategy
    private var paymentGroups: [PaymentGroup] {
        switch groupingStrategy {
        case .byVendor:
            return groupByVendor()
        case .byExpense:
            return groupByExpense()
        case .byPlanId:
            // For byPlanId, treat each payment as its own group
            return groupByPlanId()
        }
    }

    /// Group payments by vendor
    private func groupByVendor() -> [PaymentGroup] {
        let grouped = Dictionary(grouping: paymentSchedules) { payment -> Int64 in
            payment.vendorId ?? -1
        }

        return grouped.compactMap { vendorId, payments -> PaymentGroup? in
            guard vendorId != -1 else { return nil }

            let vendorName = getVendorName(vendorId) ?? payments.first?.vendor ?? "Unknown Vendor"
            return createPaymentGroup(
                id: "vendor_\(vendorId)",
                name: vendorName,
                icon: vendorName.first.map { String($0).uppercased() } ?? "V",
                payments: payments
            )
        }
        .filter { group in
            if searchQuery.isEmpty { return true }
            return group.name.lowercased().contains(searchQuery.lowercased())
        }
        .sorted { $0.name < $1.name }
    }

    /// Group payments by expense
    private func groupByExpense() -> [PaymentGroup] {
        // Group by expenseId (UUID), filtering out payments without an expense
        let paymentsWithExpense = paymentSchedules.filter { $0.expenseId != nil }

        let grouped = Dictionary(grouping: paymentsWithExpense) { payment -> UUID in
            payment.expenseId!
        }

        return grouped.compactMap { expenseId, payments -> PaymentGroup? in
            let expense = expenses.first { $0.id == expenseId }
            let expenseName = expense?.expenseName ?? "Unknown Expense"
            let vendorName = payments.first.flatMap { getVendorName($0.vendorId) } ?? payments.first?.vendor ?? ""

            return createPaymentGroup(
                id: "expense_\(expenseId.uuidString)",
                name: expenseName,
                subtitle: vendorName.isEmpty ? nil : vendorName,
                icon: expenseName.first.map { String($0).uppercased() } ?? "E",
                payments: payments
            )
        }
        .filter { group in
            if searchQuery.isEmpty { return true }
            let nameMatch = group.name.lowercased().contains(searchQuery.lowercased())
            let subtitleMatch = group.subtitle?.lowercased().contains(searchQuery.lowercased()) ?? false
            return nameMatch || subtitleMatch
        }
        .sorted { $0.name < $1.name }
    }

    /// Group payments by payment_plan_id (payments sharing the same plan ID are grouped together)
    private func groupByPlanId() -> [PaymentGroup] {
        // Group by paymentPlanId (UUID), filtering out payments without a plan ID
        let paymentsWithPlanId = paymentSchedules.filter { $0.paymentPlanId != nil }

        let grouped = Dictionary(grouping: paymentsWithPlanId) { payment -> UUID in
            payment.paymentPlanId!
        }

        return grouped.compactMap { planId, payments -> PaymentGroup? in
            // Use the vendor name from the first payment as the group name
            let firstPayment = payments.first
            let vendorName = firstPayment.flatMap { getVendorName($0.vendorId) } ?? firstPayment?.vendor ?? "Unknown Plan"

            // Calculate date range for subtitle
            let sortedPayments = payments.sorted { $0.paymentDate < $1.paymentDate }
            let dateRangeSubtitle: String
            if let firstDate = sortedPayments.first?.paymentDate,
               let lastDate = sortedPayments.last?.paymentDate,
               sortedPayments.count > 1 {
                dateRangeSubtitle = "\(formatDate(firstDate)) - \(formatDate(lastDate))"
            } else if let singleDate = sortedPayments.first?.paymentDate {
                dateRangeSubtitle = formatDate(singleDate)
            } else {
                dateRangeSubtitle = ""
            }

            return createPaymentGroup(
                id: "plan_\(planId.uuidString)",
                name: vendorName,
                subtitle: dateRangeSubtitle.isEmpty ? nil : dateRangeSubtitle,
                icon: vendorName.first.map { String($0).uppercased() } ?? "P",
                payments: payments
            )
        }
        .filter { group in
            if searchQuery.isEmpty { return true }
            return group.name.lowercased().contains(searchQuery.lowercased())
        }
        .sorted { $0.name < $1.name }
    }

    /// Helper to create a PaymentGroup with computed stats
    private func createPaymentGroup(
        id: String,
        name: String,
        subtitle: String? = nil,
        icon: String,
        payments: [PaymentSchedule]
    ) -> PaymentGroup {
        let totalAmount = payments.reduce(0) { $0 + $1.paymentAmount }
        // Use actual amountPaid for accurate tracking (includes partial payments)
        let paidAmount = payments.reduce(0) { $0 + $1.amountPaid }
        let upcomingPayments = payments.filter { !$0.paid && $0.paymentDate > Date() }
        let overduePayments = payments.filter { !$0.paid && $0.paymentDate < Date() }

        return PaymentGroup(
            id: id,
            name: name,
            subtitle: subtitle,
            icon: icon,
            payments: payments.sorted { $0.paymentDate < $1.paymentDate },
            totalAmount: totalAmount,
            paidAmount: paidAmount,
            upcomingCount: upcomingPayments.count,
            overdueCount: overduePayments.count
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Total upcoming payments amount
    private var totalUpcoming: Double {
        paymentSchedules
            .filter { !$0.paid && $0.paymentDate > Date() }
            .reduce(0) { $0 + $1.paymentAmount }
    }

    /// Total overdue payments amount
    private var totalOverdue: Double {
        paymentSchedules
            .filter { !$0.paid && $0.paymentDate < Date() }
            .reduce(0) { $0 + $1.paymentAmount }
    }

    /// Number of overdue payments
    private var overdueCount: Int {
        paymentSchedules.filter { !$0.paid && $0.paymentDate < Date() }.count
    }

    /// Total number of payment schedules
    private var totalSchedules: Int {
        paymentSchedules.count
    }

    /// Total paid amount (uses actual amountPaid for partial payment accuracy)
    private var totalPaid: Double {
        paymentSchedules.reduce(0) { $0 + $1.amountPaid }
    }

    /// Overall completion percentage
    private var overallProgress: Double {
        let total = paymentSchedules.reduce(0) { $0 + $1.paymentAmount }
        guard total > 0 else { return 0 }
        return (totalPaid / total) * 100
    }

    // MARK: - Body

    var body: some View {
        if isLoadingPlans {
            loadingView
        } else if let loadError {
            errorView(message: loadError)
        } else if paymentGroups.isEmpty {
            emptyStateView
        } else {
            dashboardContent
        }
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Payment Cards (grouped based on parent's groupingStrategy)
                groupedCardsSection
            }
            .padding(.vertical, Spacing.lg)
        }
    }

    // MARK: - Grouped Cards Section

    private var groupedCardsSection: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(paymentGroups, id: \.id) { group in
                HStack(spacing: Spacing.sm) {
                    // Plan-level selection checkbox
                    if isSelectionMode {
                        let groupPaymentIds = Set(group.payments.map { $0.id })
                        let allSelected = groupPaymentIds.isSubset(of: selectedPaymentIds)

                        Button(action: {
                            if allSelected {
                                selectedPaymentIds.subtract(groupPaymentIds)
                            } else {
                                selectedPaymentIds.formUnion(groupPaymentIds)
                            }
                        }) {
                            Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(allSelected ? SemanticColors.primaryAction : SemanticColors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }

                    PaymentGroupCard(
                        group: group,
                        isExpanded: expandedGroupIds.contains(group.id),
                        isHovered: hoveredCardId == group.id,
                        isDarkMode: isDarkMode,
                        windowSize: windowSize,
                        isSelectionMode: isSelectionMode,
                        selectedPaymentIds: $selectedPaymentIds,
                        onToggleExpand: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if expandedGroupIds.contains(group.id) {
                                    expandedGroupIds.remove(group.id)
                                } else {
                                    expandedGroupIds.insert(group.id)
                                }
                            }
                        },
                        onHover: { hovering in
                            hoveredCardId = hovering ? group.id : nil
                        },
                        onTogglePaidStatus: onTogglePaidStatus,
                        onUpdate: onUpdate,
                        onDelete: onDelete,
                        onPaymentTap: onPaymentTap
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Loading State

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading payment plans...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isDarkMode ? .white.opacity(0.7) : SemanticColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error State

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Failed to Load Payment Plans")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(isDarkMode ? .white.opacity(0.7) : SemanticColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)

            Button(action: onRetry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundColor(isDarkMode ? .white.opacity(0.3) : SemanticColors.textTertiary)

            Text("No Payment Plans")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)

            Text(searchQuery.isEmpty
                 ? "Payment plans will appear here when you have multiple payments for vendors."
                 : "No payment plans match your search.")
                .font(.system(size: 14))
                .foregroundColor(isDarkMode ? .white.opacity(0.6) : SemanticColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxl)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Payment Group Model

private struct PaymentGroup: Identifiable {
    let id: String
    let name: String
    let subtitle: String?
    let icon: String
    let payments: [PaymentSchedule]
    let totalAmount: Double
    let paidAmount: Double
    let upcomingCount: Int
    let overdueCount: Int

    var remainingAmount: Double { totalAmount - paidAmount }
    var progressPercentage: Double {
        guard totalAmount > 0 else { return 0 }
        return (paidAmount / totalAmount) * 100
    }
    var paymentCount: Int { payments.count }
    var paidCount: Int { payments.filter { $0.paid }.count }
}

// MARK: - Payment Group Card

private struct PaymentGroupCard: View {
    let group: PaymentGroup
    let isExpanded: Bool
    let isHovered: Bool
    let isDarkMode: Bool
    let windowSize: WindowSize
    var isSelectionMode: Bool = false
    @Binding var selectedPaymentIds: Set<Int64>
    let onToggleExpand: () -> Void
    let onHover: (Bool) -> Void
    let onTogglePaidStatus: (PaymentSchedule) -> Void
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let onPaymentTap: (PaymentSchedule) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            cardHeader

            // Expanded content
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(isDarkMode ? 0.1 : 0.3))

                paymentsList
            }
        }
        .background(
            ZStack {
                // Base blur layer
                RoundedRectangle(cornerRadius: CornerRadius.xxl)
                    .fill(.ultraThinMaterial)

                // Semi-transparent overlay
                RoundedRectangle(cornerRadius: CornerRadius.xxl)
                    .fill(Color.white.opacity(isDarkMode ? 0.08 : 0.25))

                // Inner glow
                RoundedRectangle(cornerRadius: CornerRadius.xxl)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(isDarkMode ? 0.03 : 0.12),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 300
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xxl)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.7 : 0.5),
                            Color.white.opacity(isHovered ? 0.25 : 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        // Static shadows - no geometric changes on hover to prevent layout flickering
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.03), radius: 32, x: 0, y: 12)
        // Hover feedback via border opacity only (lines 439-440) - no layout impact
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
        .onHover(perform: onHover)
    }

    // MARK: - Card Header

    private var cardHeader: some View {
        Button(action: onToggleExpand) {
            HStack(spacing: Spacing.md) {
                // Group icon
                groupIcon

                // Group info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(group.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)

                    HStack(spacing: Spacing.sm) {
                        // Show subtitle if available (e.g., vendor name for expense grouping)
                        if let subtitle = group.subtitle {
                            Text(subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(isDarkMode ? .white.opacity(0.6) : SemanticColors.textSecondary)

                            Text("•")
                                .font(.system(size: 13))
                                .foregroundColor(isDarkMode ? .white.opacity(0.4) : SemanticColors.textTertiary)
                        }

                        Text("\(group.paymentCount) payment\(group.paymentCount == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundColor(isDarkMode ? .white.opacity(0.6) : SemanticColors.textSecondary)

                        if group.overdueCount > 0 {
                            Text("\(group.overdueCount) overdue")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color.fromHex("DC2626"))
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(
                                    Capsule()
                                        .fill(Color.fromHex("FEE2E2"))
                                )
                        }
                    }
                }

                Spacer()

                // Progress and amount
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text(formatCurrency(group.totalAmount))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)

                    // Progress bar
                    progressBar
                }

                // Expand indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isDarkMode ? .white.opacity(0.5) : SemanticColors.textSecondary)
                    .padding(.leading, Spacing.sm)
            }
            .padding(Spacing.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var groupIcon: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.fromHex("6366F1").opacity(0.2),
                        Color.fromHex("6366F1").opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 48, height: 48)
            .overlay(
                Text(group.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.fromHex("6366F1"))
            )
    }

    private var progressBar: some View {
        VStack(alignment: .trailing, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                Text("\(group.paidCount)/\(group.paymentCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isDarkMode ? .white.opacity(0.5) : SemanticColors.textSecondary)

                Text("\(Int(group.progressPercentage))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(progressColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))

                    // Progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor)
                        .frame(width: max(geometry.size.width * (group.progressPercentage / 100), 0))
                }
            }
            .frame(width: 100, height: 6)
        }
    }

    private var progressColor: Color {
        if group.progressPercentage >= 100 {
            return Color.fromHex("10B981")
        } else if group.progressPercentage >= 50 {
            return Color.fromHex("3B82F6")
        } else {
            return Color.fromHex("F59E0B")
        }
    }

    // MARK: - Payments List

    private var paymentsList: some View {
        VStack(spacing: 0) {
            ForEach(group.payments, id: \.id) { payment in
                HStack(spacing: Spacing.sm) {
                    // Individual payment selection checkbox
                    if isSelectionMode {
                        Button(action: {
                            if selectedPaymentIds.contains(payment.id) {
                                selectedPaymentIds.remove(payment.id)
                            } else {
                                selectedPaymentIds.insert(payment.id)
                            }
                        }) {
                            Image(systemName: selectedPaymentIds.contains(payment.id) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(selectedPaymentIds.contains(payment.id) ? SemanticColors.primaryAction : SemanticColors.textTertiary)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, Spacing.lg)
                    }

                    PaymentRowItem(
                        payment: payment,
                        isDarkMode: isDarkMode,
                        isSelectionMode: isSelectionMode,
                        onTogglePaid: {
                            var updated = payment
                            updated.paid.toggle()
                            onTogglePaidStatus(updated)
                        },
                        onTap: {
                            if isSelectionMode {
                                if selectedPaymentIds.contains(payment.id) {
                                    selectedPaymentIds.remove(payment.id)
                                } else {
                                    selectedPaymentIds.insert(payment.id)
                                }
                            } else {
                                onPaymentTap(payment)
                            }
                        }
                    )
                }

                if payment.id != group.payments.last?.id {
                    Divider()
                        .background(Color.white.opacity(isDarkMode ? 0.05 : 0.15))
                        .padding(.horizontal, Spacing.lg)
                }
            }
        }
        .padding(.vertical, Spacing.sm)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Payment Row Item

private struct PaymentRowItem: View {
    let payment: PaymentSchedule
    let isDarkMode: Bool
    var isSelectionMode: Bool = false
    let onTogglePaid: () -> Void
    let onTap: () -> Void

    // REMOVED: @State private var isHovered - causes scroll rebounding/interruption
    // When scrolling, onHover fires as mouse passes over items, triggering @State updates
    // which cause view rebuilds and interrupt scroll momentum.
    // Instead, use static styling - hover feedback is handled by the parent PaymentGroupCard.

    private var status: PaymentDisplayStatus {
        if payment.paid {
            return .paid
        } else if payment.isPartiallyPaid {
            return .partial
        } else if payment.paymentDate < Date() {
            return .overdue
        } else {
            let sevenDaysFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            if payment.paymentDate <= sevenDaysFromNow {
                return .dueSoon
            }
            return .scheduled
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Status indicator
                Circle()
                    .fill(status.color)
                    .frame(width: 10, height: 10)

                // Date
                Text(formatDate(payment.paymentDate))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isDarkMode ? .white.opacity(0.8) : SemanticColors.textPrimary)
                    .frame(width: 100, alignment: .leading)

                // Notes/Description
                Text(payment.notes ?? "Payment")
                    .font(.system(size: 14))
                    .foregroundColor(isDarkMode ? .white.opacity(0.6) : SemanticColors.textSecondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Amount - show paid amount for partial payments
                VStack(alignment: .trailing, spacing: 2) {
                    if payment.isPartiallyPaid {
                        Text("\(formatCurrency(payment.amountPaid)) paid")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.fromHex("F59E0B"))
                        Text("of \(formatCurrency(payment.paymentAmount))")
                            .font(.system(size: 11))
                            .foregroundColor(isDarkMode ? .white.opacity(0.5) : SemanticColors.textTertiary)
                    } else {
                        Text(formatCurrency(payment.paymentAmount))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)
                    }
                }
                .frame(width: 100, alignment: .trailing)

                // Status badge
                statusBadge

                // Toggle button
                Button(action: onTogglePaid) {
                    Image(systemName: payment.paid ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(payment.paid ? Color.fromHex("10B981") : Color.gray.opacity(0.4))
                }
                .buttonStyle(.plain)

                // Detail indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(isDarkMode ? .white.opacity(0.3) : SemanticColors.textTertiary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Static background - no hover state to avoid scroll interruption
        // The parent PaymentGroupCard already provides hover feedback at the group level
        .background(Color.clear)
    }

    private var statusBadge: some View {
        Text(status.displayName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(status.textColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(
                Capsule()
                    .fill(status.backgroundColor)
            )
            .frame(width: 80)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Payment Display Status

private enum PaymentDisplayStatus {
    case paid
    case partial
    case dueSoon
    case scheduled
    case overdue

    var displayName: String {
        switch self {
        case .paid: return "Paid"
        case .partial: return "Partial"
        case .dueSoon: return "Due Soon"
        case .scheduled: return "Scheduled"
        case .overdue: return "Overdue"
        }
    }

    var color: Color {
        switch self {
        case .paid: return Color.fromHex("10B981")
        case .partial: return Color.fromHex("F59E0B")
        case .dueSoon: return Color.fromHex("F59E0B")
        case .scheduled: return Color.fromHex("6366F1")
        case .overdue: return Color.fromHex("DC2626")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .paid: return Color.fromHex("D1FAE5")
        case .partial: return Color.fromHex("FEF3C7")
        case .dueSoon: return Color.fromHex("FEF3C7")
        case .scheduled: return Color.fromHex("E0E7FF")
        case .overdue: return Color.fromHex("FEE2E2")
        }
    }

    var textColor: Color {
        switch self {
        case .paid: return Color.fromHex("047857")
        case .partial: return Color.fromHex("B45309")
        case .dueSoon: return Color.fromHex("B45309")
        case .scheduled: return Color.fromHex("4338CA")
        case .overdue: return Color.fromHex("DC2626")
        }
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    PaymentPlansDashboardViewV1(
        windowSize: .regular,
        isLoadingPlans: false,
        loadError: nil,
        paymentSchedules: [],
        expenses: [],
        searchQuery: "",
        groupingStrategy: .byVendor,
        onRetry: {},
        onTogglePaidStatus: { _ in },
        onUpdate: { _ in },
        onDelete: { _ in },
        getVendorName: { _ in "Sample Vendor" },
        onPaymentTap: { _ in },
        isSelectionMode: .constant(false),
        selectedPaymentIds: .constant([]),
        onBulkDelete: { _ in }
    )
    .frame(width: 1200, height: 800)
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    PaymentPlansDashboardViewV1(
        windowSize: .regular,
        isLoadingPlans: false,
        loadError: nil,
        paymentSchedules: [],
        expenses: [],
        searchQuery: "",
        groupingStrategy: .byExpense,
        onRetry: {},
        onTogglePaidStatus: { _ in },
        onUpdate: { _ in },
        onDelete: { _ in },
        getVendorName: { _ in "Sample Vendor" },
        onPaymentTap: { _ in },
        isSelectionMode: .constant(false),
        selectedPaymentIds: .constant([]),
        onBulkDelete: { _ in }
    )
    .frame(width: 1200, height: 800)
    .preferredColorScheme(.dark)
}
