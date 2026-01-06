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

    let onRetry: () -> Void
    let onTogglePaidStatus: (PaymentSchedule) -> Void
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?

    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedVendorIds: Set<Int64> = []
    @State private var hoveredCardId: Int64?

    private var isDarkMode: Bool { colorScheme == .dark }

    // MARK: - Computed Properties

    /// Group payments by vendor
    private var vendorPayments: [VendorPaymentGroup] {
        let grouped = Dictionary(grouping: paymentSchedules) { payment -> Int64 in
            payment.vendorId ?? -1
        }

        return grouped.compactMap { vendorId, payments -> VendorPaymentGroup? in
            guard vendorId != -1 else { return nil }

            let vendorName = getVendorName(vendorId) ?? payments.first?.vendor ?? "Unknown Vendor"
            let totalAmount = payments.reduce(0) { $0 + $1.paymentAmount }
            let paidAmount = payments.filter { $0.paid }.reduce(0) { $0 + $1.paymentAmount }
            let upcomingPayments = payments.filter { !$0.paid && $0.paymentDate > Date() }
            let overduePayments = payments.filter { !$0.paid && $0.paymentDate < Date() }

            return VendorPaymentGroup(
                vendorId: vendorId,
                vendorName: vendorName,
                payments: payments.sorted { $0.paymentDate < $1.paymentDate },
                totalAmount: totalAmount,
                paidAmount: paidAmount,
                upcomingCount: upcomingPayments.count,
                overdueCount: overduePayments.count
            )
        }
        .filter { group in
            // Apply search filter
            if searchQuery.isEmpty { return true }
            return group.vendorName.lowercased().contains(searchQuery.lowercased())
        }
        .sorted { $0.vendorName < $1.vendorName }
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

    /// Total paid amount
    private var totalPaid: Double {
        paymentSchedules.filter { $0.paid }.reduce(0) { $0 + $1.paymentAmount }
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
        } else if vendorPayments.isEmpty {
            emptyStateView
        } else {
            dashboardContent
        }
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // KPI Summary Cards
                kpiSummarySection

                // Vendor Payment Cards
                vendorCardsSection
            }
            .padding(.vertical, Spacing.lg)
        }
    }

    // MARK: - KPI Summary Section

    private var kpiSummarySection: some View {
        HStack(spacing: Spacing.md) {
            // Upcoming Payments
            KPISummaryCard(
                icon: "calendar.badge.clock",
                iconBackgroundColor: Color.fromHex("DBEAFE"),
                iconColor: Color.fromHex("3B82F6"),
                title: "Upcoming Payments",
                value: formatCurrency(totalUpcoming),
                valueColor: Color.fromHex("1D4ED8"),
                subtitle: "\(paymentSchedules.filter { !$0.paid && $0.paymentDate > Date() }.count) payments scheduled",
                isDarkMode: isDarkMode
            )

            // Overdue Payments
            KPISummaryCard(
                icon: "exclamationmark.triangle.fill",
                iconBackgroundColor: overdueCount > 0 ? Color.fromHex("FEE2E2") : Color.fromHex("D1FAE5"),
                iconColor: overdueCount > 0 ? Color.fromHex("DC2626") : Color.fromHex("10B981"),
                title: "Overdue Payments",
                value: formatCurrency(totalOverdue),
                valueColor: overdueCount > 0 ? Color.fromHex("DC2626") : Color.fromHex("047857"),
                subtitle: overdueCount > 0 ? "\(overdueCount) payments overdue" : "No overdue payments",
                isDarkMode: isDarkMode
            )

            // Total Schedules
            KPISummaryCard(
                icon: "doc.text.fill",
                iconBackgroundColor: Color.fromHex("E0E7FF"),
                iconColor: Color.fromHex("6366F1"),
                title: "Total Schedules",
                value: "\(totalSchedules)",
                valueColor: isDarkMode ? .white : SemanticColors.textPrimary,
                subtitle: "\(Int(overallProgress))% completed",
                isDarkMode: isDarkMode
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Vendor Cards Section

    private var vendorCardsSection: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(vendorPayments, id: \.vendorId) { group in
                VendorPaymentCard(
                    group: group,
                    isExpanded: expandedVendorIds.contains(group.vendorId),
                    isHovered: hoveredCardId == group.vendorId,
                    isDarkMode: isDarkMode,
                    windowSize: windowSize,
                    onToggleExpand: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if expandedVendorIds.contains(group.vendorId) {
                                expandedVendorIds.remove(group.vendorId)
                            } else {
                                expandedVendorIds.insert(group.vendorId)
                            }
                        }
                    },
                    onHover: { hovering in
                        hoveredCardId = hovering ? group.vendorId : nil
                    },
                    onTogglePaidStatus: onTogglePaidStatus,
                    onUpdate: onUpdate,
                    onDelete: onDelete
                )
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

// MARK: - Vendor Payment Group Model

private struct VendorPaymentGroup: Identifiable {
    let vendorId: Int64
    let vendorName: String
    let payments: [PaymentSchedule]
    let totalAmount: Double
    let paidAmount: Double
    let upcomingCount: Int
    let overdueCount: Int

    var id: Int64 { vendorId }

    var remainingAmount: Double { totalAmount - paidAmount }
    var progressPercentage: Double {
        guard totalAmount > 0 else { return 0 }
        return (paidAmount / totalAmount) * 100
    }
    var paymentCount: Int { payments.count }
    var paidCount: Int { payments.filter { $0.paid }.count }
}

// MARK: - KPI Summary Card

private struct KPISummaryCard: View {
    let icon: String
    let iconBackgroundColor: Color
    let iconColor: Color
    let title: String
    let value: String
    let valueColor: Color
    let subtitle: String
    let isDarkMode: Bool

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Icon and title row
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(iconColor)
                    )

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isDarkMode ? .white.opacity(0.6) : SemanticColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
            }

            // Value
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(valueColor)

            // Subtitle
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(isDarkMode ? .white.opacity(0.5) : SemanticColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(
            ZStack {
                // Base blur layer
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(.ultraThinMaterial)

                // Semi-transparent overlay
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(Color.white.opacity(isDarkMode ? 0.1 : 0.25))

                // Inner glow
                RoundedRectangle(cornerRadius: CornerRadius.xl)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(isDarkMode ? 0.05 : 0.15),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.8 : 0.6),
                            Color.white.opacity(isHovered ? 0.3 : 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Vendor Payment Card

private struct VendorPaymentCard: View {
    let group: VendorPaymentGroup
    let isExpanded: Bool
    let isHovered: Bool
    let isDarkMode: Bool
    let windowSize: WindowSize
    let onToggleExpand: () -> Void
    let onHover: (Bool) -> Void
    let onTogglePaidStatus: (PaymentSchedule) -> Void
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void

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
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .shadow(color: Color.black.opacity(0.03), radius: 32, x: 0, y: 12)
        .scaleEffect(isHovered && !isExpanded ? 1.005 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
        .onHover(perform: onHover)
    }

    // MARK: - Card Header

    private var cardHeader: some View {
        Button(action: onToggleExpand) {
            HStack(spacing: Spacing.md) {
                // Vendor icon
                vendorIcon

                // Vendor info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(group.vendorName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)

                    HStack(spacing: Spacing.sm) {
                        Text("\(group.paymentCount) payments")
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

    private var vendorIcon: some View {
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
                Text(String(group.vendorName.prefix(1)).uppercased())
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
                PaymentRowItem(
                    payment: payment,
                    isDarkMode: isDarkMode,
                    onTogglePaid: {
                        var updated = payment
                        updated.paid.toggle()
                        onTogglePaidStatus(updated)
                    }
                )

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
    let onTogglePaid: () -> Void

    @State private var isHovered = false

    private var status: PaymentDisplayStatus {
        if payment.paid {
            return .paid
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

            // Amount
            Text(formatCurrency(payment.paymentAmount))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isDarkMode ? .white : SemanticColors.textPrimary)
                .frame(width: 80, alignment: .trailing)

            // Status badge
            statusBadge

            // Toggle button
            Button(action: onTogglePaid) {
                Image(systemName: payment.paid ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(payment.paid ? Color.fromHex("10B981") : Color.gray.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(isHovered ? Color.white.opacity(isDarkMode ? 0.05 : 0.2) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
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
    case dueSoon
    case scheduled
    case overdue

    var displayName: String {
        switch self {
        case .paid: return "Paid"
        case .dueSoon: return "Due Soon"
        case .scheduled: return "Scheduled"
        case .overdue: return "Overdue"
        }
    }

    var color: Color {
        switch self {
        case .paid: return Color.fromHex("10B981")
        case .dueSoon: return Color.fromHex("F59E0B")
        case .scheduled: return Color.fromHex("6366F1")
        case .overdue: return Color.fromHex("DC2626")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .paid: return Color.fromHex("D1FAE5")
        case .dueSoon: return Color.fromHex("FEF3C7")
        case .scheduled: return Color.fromHex("E0E7FF")
        case .overdue: return Color.fromHex("FEE2E2")
        }
    }

    var textColor: Color {
        switch self {
        case .paid: return Color.fromHex("047857")
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
        onRetry: {},
        onTogglePaidStatus: { _ in },
        onUpdate: { _ in },
        onDelete: { _ in },
        getVendorName: { _ in "Sample Vendor" }
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
        onRetry: {},
        onTogglePaidStatus: { _ in },
        onUpdate: { _ in },
        onDelete: { _ in },
        getVendorName: { _ in "Sample Vendor" }
    )
    .frame(width: 1200, height: 800)
    .preferredColorScheme(.dark)
}
