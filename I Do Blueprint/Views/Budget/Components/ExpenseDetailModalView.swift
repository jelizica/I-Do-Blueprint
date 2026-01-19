//
//  ExpenseDetailModalView.swift
//  I Do Blueprint
//
//  Expense detail modal showing comprehensive expense information
//  with payment schedules, vendor info, and documentation
//

import Combine
import SwiftUI

// MARK: - Main View

struct ExpenseDetailModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @EnvironmentObject private var coordinator: AppCoordinator

    // Observe bill calculator store for reactive updates when guest count changes
    @ObservedObject private var billCalculatorStore = AppStores.shared.billCalculator

    let expense: Expense

    // State for showing edit modal
    @State private var showEditExpense = false
    @State private var showLinkBillsModal = false
    @State private var linkedPayments: [PaymentSchedule] = []
    @State private var category: BudgetCategory?
    @State private var vendor: Vendor?
    @State private var isLoadingPayments = true

    // State for linked bills
    @State private var linkedBills: [BillCalculator] = []
    @State private var linkedBillLinks: [ExpenseBillCalculatorLink] = []
    @State private var isLoadingLinkedBills = true

    // State for unlink confirmation
    @State private var billToUnlink: BillCalculator?
    @State private var showUnlinkConfirmation = false
    @State private var isUnlinking = false

    private let logger = AppLogger.ui

    // MARK: - Size Constants (Modal Sizing)

    private let minWidth: CGFloat = 500
    private let maxWidth: CGFloat = 700
    private let minHeight: CGFloat = 500
    private let maxHeight: CGFloat = 750
    private let windowChromeBuffer: CGFloat = 40

    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        let targetWidth = min(maxWidth, max(minWidth, parentSize.width * 0.65))
        let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.85 - windowChromeBuffer))
        return CGSize(width: targetWidth, height: targetHeight)
    }

    // MARK: - Computed Properties

    /// Total paid from linked payments
    private var paidAmount: Double {
        linkedPayments.filter { $0.paid }.reduce(0) { $0 + $1.paymentAmount }
    }

    /// Remaining amount to be paid
    private var remainingAmount: Double {
        expense.amount - paidAmount
    }

    /// Payment progress percentage (0-100)
    private var paymentProgressPercent: Double {
        guard expense.amount > 0 else { return 0 }
        return min(100, (paidAmount / expense.amount) * 100)
    }

    /// Days until expense due date
    private var daysUntilDue: Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: expense.expenseDate)
        return calendar.dateComponents([.day], from: today, to: due).day
    }

    // MARK: - Body

    var body: some View {
        Group {
            if showLinkBillsModal {
                // Show Link Bills modal (navigation-style flow)
                LinkBillsToExpenseModal(
                    expense: expense,
                    category: category,
                    onDismiss: {
                        showLinkBillsModal = false
                    },
                    onLinkComplete: {
                        showLinkBillsModal = false
                        // Reload data to show updated links
                        loadData()
                    }
                )
                .environmentObject(budgetStore)
                .environmentObject(settingsStore)
                .environmentObject(coordinator)
            } else {
                // Show expense detail content
                expenseDetailContent
            }
        }
        .onAppear {
            loadData()
        }
        .onReceive(billCalculatorStore.objectWillChange) { _ in
            // Refresh linked bills when bill calculator store publishes changes (e.g., guest count changed)
            // Use DispatchQueue to ensure we get the updated values after the change is applied
            DispatchQueue.main.async {
                guard !linkedBillLinks.isEmpty else { return }
                let billIds = Set(linkedBillLinks.map { $0.billCalculatorId })
                linkedBills = billCalculatorStore.calculators.filter { billIds.contains($0.id) }
            }
        }
        .sheet(isPresented: $showEditExpense) {
            ExpenseTrackerEditView(expense: expense)
                .environmentObject(budgetStore)
                .environmentObject(settingsStore)
                .environmentObject(coordinator)
        }
        .alert(
            "Unlink Bill",
            isPresented: $showUnlinkConfirmation,
            presenting: billToUnlink
        ) { bill in
            Button("Cancel", role: .cancel) {
                billToUnlink = nil
            }
            Button("Unlink", role: .destructive) {
                Task {
                    await unlinkBill(bill)
                }
            }
        } message: { bill in
            Text("Are you sure you want to unlink \"\(bill.name.isEmpty ? "Untitled Bill" : bill.name)\" from this expense? The bill calculator will not be deleted.")
        }
    }

    // MARK: - Expense Detail Content

    private var expenseDetailContent: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            // Content (scrollable)
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Two-column layout
                    HStack(alignment: .top, spacing: Spacing.lg) {
                        // Left column (40%)
                        leftColumn
                            .frame(maxWidth: .infinity)

                        // Right column (60%)
                        rightColumn
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.lg)

                    // Payment Schedule section (full width)
                    if !linkedPayments.isEmpty {
                        paymentScheduleSection
                            .padding(.horizontal, Spacing.lg)
                    }

                    // Linked Bills section (full width)
                    linkedBillsSection
                        .padding(.horizontal, Spacing.lg)

                    Spacer(minLength: Spacing.lg)
                }
            }

            // Footer
            footerSection
        }
        .frame(width: dynamicSize.width, height: dynamicSize.height)
        .background(SemanticColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Badges
                HStack(spacing: Spacing.sm) {
                    // Category badge
                    categoryBadge

                    // Payment status badge
                    paymentStatusBadge
                }

                // Expense name
                Text(expense.expenseName)
                    .font(Typography.title3)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(2)
            }

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SemanticColors.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(SemanticColors.backgroundTertiary.opacity(0.5))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.lg)
        .background(SemanticColors.backgroundPrimary)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Category Badge

    @ViewBuilder
    private var categoryBadge: some View {
        let categoryName = category?.categoryName ?? "Expense"
        let categoryColor = category.map { Color.fromHex($0.color) } ?? SemanticColors.primaryAction

        HStack(spacing: Spacing.xs) {
            Image(systemName: categoryIcon(for: categoryName))
                .font(.system(size: 10))
            Text(categoryName.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
        }
        .foregroundColor(categoryColor)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(categoryColor.opacity(Opacity.light))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
    }

    // MARK: - Payment Status Badge

    @ViewBuilder
    private var paymentStatusBadge: some View {
        let status = expense.paymentStatus
        let (statusColor, statusIcon) = statusColorAndIcon(for: status)

        HStack(spacing: Spacing.xs) {
            Image(systemName: statusIcon)
                .font(.system(size: 10))
            Text(status.displayName.uppercased())
                .font(.system(size: 11, weight: .medium))
                .tracking(0.5)
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(statusColor.opacity(Opacity.light))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
    }

    // MARK: - Left Column

    private var leftColumn: some View {
        VStack(spacing: Spacing.md) {
            // Amount card with gradient
            amountCard

            // Payment progress donut
            paymentProgressCard

            // Approval status (if approved)
            if expense.approvalStatus == "approved" {
                approvalStatusCard
            }
        }
    }

    // MARK: - Amount Card

    private var amountCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("TOTAL AMOUNT")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(.white.opacity(0.9))

            Text(formatCurrency(expense.amount))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: Spacing.xs) {
                Image(systemName: "calendar")
                    .font(.system(size: 11))
                Text("Due \(formatDate(expense.expenseDate))")
                    .font(.system(size: 12))
            }
            .foregroundColor(.white.opacity(0.9))

            // Due in days
            if let days = daysUntilDue {
                Divider()
                    .background(Color.white.opacity(0.2))
                    .padding(.top, Spacing.sm)

                HStack {
                    Text("Due in")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                    Text(days >= 0 ? "\(days) days" : "\(abs(days)) days ago")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    SemanticColors.primaryAction,
                    SemanticColors.primaryActionHover
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    // MARK: - Payment Progress Card

    private var paymentProgressCard: some View {
        VStack(spacing: Spacing.md) {
            // Donut chart
            ZStack {
                // Background circle
                Circle()
                    .stroke(SemanticColors.borderLight, lineWidth: 8)
                    .frame(width: 100, height: 100)

                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(paymentProgressPercent / 100))
                    .stroke(
                        SemanticColors.statusSuccess,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                // Center text
                VStack(spacing: 2) {
                    Text("\(Int(paymentProgressPercent))%")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(SemanticColors.textPrimary)
                    Text("PAID")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(0.5)
                        .foregroundColor(SemanticColors.textTertiary)
                }
            }

            // Payment summary
            VStack(spacing: Spacing.sm) {
                HStack {
                    Text("Paid")
                        .font(.system(size: 13))
                        .foregroundColor(SemanticColors.textSecondary)
                    Spacer()
                    Text(formatCurrency(paidAmount))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SemanticColors.statusSuccess)
                }

                HStack {
                    Text("Remaining")
                        .font(.system(size: 13))
                        .foregroundColor(SemanticColors.textSecondary)
                    Spacer()
                    Text(formatCurrency(remainingAmount))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SemanticColors.textPrimary)
                }
            }
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
    }

    // MARK: - Approval Status Card

    private var approvalStatusCard: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(SemanticColors.statusSuccess)
                    .frame(width: 28, height: 28)

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("APPROVED")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(SemanticColors.statusSuccess)

                if let approver = expense.approvedBy, let date = expense.approvedAt {
                    Text("by \(approver) on \(formatShortDate(date))")
                        .font(.system(size: 11))
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(SemanticColors.statusSuccessLight.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.statusSuccess.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Right Column

    private var rightColumn: some View {
        VStack(spacing: Spacing.md) {
            // Vendor section
            if vendor != nil || expense.vendorName != nil {
                vendorCard
            }

            // Payment method section
            if expense.paymentMethod != nil {
                paymentMethodCard
            }

            // Documentation section
            if expense.receiptUrl != nil || expense.invoiceDocumentUrl != nil {
                documentationCard
            }

            // Notes section
            if let notes = expense.notes, !notes.isEmpty {
                notesCard(notes: notes)
            }
        }
    }

    // MARK: - Vendor Card

    private var vendorCard: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Vendor icon
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [
                                SoftLavender.shade500,
                                SoftLavender.shade600
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: "building.2")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("VENDOR")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(SemanticColors.textTertiary)

                Text(vendor?.vendorName ?? expense.vendorName ?? "Unknown Vendor")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SemanticColors.textPrimary)

                if let city = vendor?.city {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(city)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(SemanticColors.textSecondary)
                }

                if let phone = vendor?.phoneNumber {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 10))
                        Text(phone)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(SemanticColors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
    }

    // MARK: - Payment Method Card

    private var paymentMethodCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("PAYMENT METHOD")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(SemanticColors.textTertiary)

            HStack(spacing: Spacing.sm) {
                // Payment method icon
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.info,
                                    AppColors.info.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: paymentMethodIcon(expense.paymentMethod ?? ""))
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(paymentMethodDisplayName(expense.paymentMethod ?? ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.textPrimary)

                    Text("•••• ****")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SemanticColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
    }

    // MARK: - Documentation Card

    private var documentationCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("DOCUMENTATION")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(SemanticColors.textTertiary)

            VStack(spacing: Spacing.sm) {
                // Receipt link
                if expense.receiptUrl != nil {
                    documentRow(
                        icon: "receipt",
                        iconColor: SemanticColors.statusSuccess,
                        iconBackground: SemanticColors.statusSuccessLight,
                        title: "Receipt",
                        subtitle: "Uploaded \(formatShortDate(expense.createdAt))"
                    )
                }

                // Invoice link
                if let invoiceNumber = expense.invoiceNumber {
                    documentRow(
                        icon: "doc.text.fill",
                        iconColor: AppColors.info,
                        iconBackground: AppColors.infoLight,
                        title: "Invoice #\(invoiceNumber)",
                        subtitle: "PDF Document"
                    )
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SemanticColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
    }

    // MARK: - Document Row

    private func documentRow(
        icon: String,
        iconColor: Color,
        iconBackground: Color,
        title: String,
        subtitle: String
    ) -> some View {
        Button {
            // TODO: Open document
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(iconBackground)
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(SemanticColors.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(SemanticColors.textSecondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.textTertiary)
            }
            .padding(Spacing.sm)
            .background(SemanticColors.backgroundPrimary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notes Card

    private func notesCard(notes: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("NOTES")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.5)
                    .foregroundColor(SemanticColors.textTertiary)

                Spacer()

                Button("Edit") {
                    showEditExpense = true
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(SemanticColors.primaryAction)
                .buttonStyle(.plain)
            }

            Text(notes)
                .font(.system(size: 13))
                .foregroundColor(SemanticColors.textSecondary)
                .lineSpacing(4)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SemanticColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
    }

    // MARK: - Payment Schedule Section

    private var paymentScheduleSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: Spacing.sm) {
                    Text("PAYMENT SCHEDULE")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text("\(linkedPayments.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 2)
                        .background(SemanticColors.primaryAction)
                        .clipShape(Circle())
                }

                Spacer()

                Button {
                    // TODO: Edit schedule
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                        Text("Edit Schedule")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(SemanticColors.primaryAction)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)

            Divider()

            // Payment cards
            VStack(spacing: Spacing.sm) {
                ForEach(Array(linkedPayments.enumerated()), id: \.element.id) { index, payment in
                    paymentCard(payment: payment, index: index + 1, total: linkedPayments.count)
                }
            }
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)

            Divider()

            // Progress footer
            paymentProgressFooter
        }
        .background(SemanticColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
    }

    // MARK: - Payment Card

    private func paymentCard(payment: PaymentSchedule, index: Int, total: Int) -> some View {
        let isPaid = payment.paid
        let isOverdue = !isPaid && payment.paymentDate < Date()

        return HStack(alignment: .top, spacing: Spacing.md) {
            // Status icon
            ZStack {
                Circle()
                    .fill(isPaid ? SemanticColors.statusSuccess : (isOverdue ? SemanticColors.statusWarning : SemanticColors.statusPendingLight))
                    .frame(width: 40, height: 40)

                if isPaid {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "clock")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isOverdue ? SemanticColors.statusWarning : SemanticColors.statusPending)
                }
            }
            .overlay {
                if !isPaid && isOverdue {
                    Circle()
                        .stroke(SemanticColors.statusWarning, lineWidth: 2)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Amount and type
                HStack {
                    HStack(spacing: Spacing.sm) {
                        Text(formatCurrency(payment.paymentAmount))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SemanticColors.textPrimary)

                        // Payment type badge
                        if let type = payment.paymentType {
                            Text(type.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(0.3)
                                .foregroundColor(paymentTypeBadgeColor(type))
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 2)
                                .background(paymentTypeBadgeColor(type).opacity(Opacity.light))
                                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                        }
                    }

                    Spacer()

                    Text(isPaid ? "Paid" : (isOverdue ? "Overdue" : "Pending"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isPaid ? SemanticColors.statusSuccess : (isOverdue ? SemanticColors.statusWarning : SemanticColors.statusPending))
                }

                // Date and order
                HStack(spacing: Spacing.md) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(formatShortDate(payment.paymentDate))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(SemanticColors.textSecondary)

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "number")
                            .font(.system(size: 10))
                        Text("\(index) of \(total)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(SemanticColors.textSecondary)
                }

                // Notes or warning
                if !isPaid {
                    if isOverdue {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text("Overdue")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(SemanticColors.statusWarning)
                        .padding(.top, Spacing.xs)
                    } else if let days = daysUntilPayment(payment.paymentDate), days <= 14 {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text("Due in \(days) days")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(SemanticColors.statusPending)
                        .padding(.top, Spacing.xs)
                    }
                } else if let notes = payment.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.textTertiary)
                        .padding(.top, Spacing.xs)
                }
            }
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(
                    !isPaid && isOverdue ? SemanticColors.statusWarning.opacity(0.4) : SemanticColors.borderLight,
                    lineWidth: !isPaid && isOverdue ? 2 : 1
                )
        )
    }

    // MARK: - Payment Progress Footer

    private var paymentProgressFooter: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Payment Progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)

                Spacer()

                Text("\(formatCurrency(paidAmount)) / \(formatCurrency(expense.amount))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(SemanticColors.textPrimary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SemanticColors.borderLight)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [SemanticColors.statusSuccess, SemanticColors.statusSuccess.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(paymentProgressPercent / 100), height: 8)
                }
            }
            .frame(height: 8)

            // Summary
            HStack {
                let paidCount = linkedPayments.filter { $0.paid }.count
                Text("\(paidCount) of \(linkedPayments.count) payments completed")
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textTertiary)

                Spacer()

                Text("\(formatCurrency(remainingAmount)) remaining")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(SemanticColors.textPrimary)
            }
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundTertiary)
    }

    // MARK: - Linked Bills Section

    private var linkedBillsSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: Spacing.sm) {
                    Text("LINKED BILLS")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(SemanticColors.textPrimary)

                    if !linkedBills.isEmpty {
                        Text("\(linkedBills.count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(AppColors.info)
                            .clipShape(Circle())
                    }
                }

                Spacer()

                Button {
                    showLinkBillsModal = true
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: linkedBills.isEmpty ? "plus" : "pencil")
                            .font(.system(size: 10))
                        Text(linkedBills.isEmpty ? "Link Bill" : "Manage")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(AppColors.info)
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)

            Divider()

            // Content
            if isLoadingLinkedBills {
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading linked bills...")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.textSecondary)
                    Spacer()
                }
                .padding(Spacing.lg)
                .background(SemanticColors.backgroundSecondary)
            } else if linkedBills.isEmpty {
                // Empty state
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(SemanticColors.textTertiary)

                    Text("No bills linked")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColors.textSecondary)

                    Text("Link a bill calculator to track detailed cost breakdowns")
                        .font(.system(size: 12))
                        .foregroundColor(SemanticColors.textTertiary)
                        .multilineTextAlignment(.center)

                    Button {
                        showLinkBillsModal = true
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Link Bill")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(AppColors.info)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, Spacing.xs)
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(SemanticColors.backgroundSecondary)
            } else {
                // Linked bills list
                VStack(spacing: Spacing.sm) {
                    ForEach(linkedBills) { bill in
                        linkedBillCard(bill)
                    }

                    // Total summary
                    linkedBillsSummary
                }
                .padding(Spacing.md)
                .background(SemanticColors.backgroundSecondary)
            }
        }
        .background(SemanticColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
    }

    // MARK: - Linked Bill Card

    private func linkedBillCard(_ bill: BillCalculator) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Bill icon
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .fill(AppColors.info.opacity(Opacity.light))
                    .frame(width: 40, height: 40)

                Image(systemName: "function")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.info)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Bill name and amount
                HStack {
                    Text(bill.name.isEmpty ? "Untitled Bill" : bill.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SemanticColors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Text(formatCurrency(bill.grandTotal))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(SemanticColors.textPrimary)

                    // Unlink button
                    Button {
                        billToUnlink = bill
                        showUnlinkConfirmation = true
                    } label: {
                        Image(systemName: "link.badge.minus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SemanticColors.statusError)
                            .frame(width: 28, height: 28)
                            .background(SemanticColors.statusErrorLight.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Unlink this bill from the expense")
                    .disabled(isUnlinking)
                    .opacity(isUnlinking ? 0.5 : 1)
                }

                // Vendor and event info
                HStack(spacing: Spacing.sm) {
                    if let vendorName = bill.vendorName {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "building.2")
                                .font(.system(size: 10))
                            Text(vendorName)
                                .font(.system(size: 11))
                                .lineLimit(1)
                        }
                        .foregroundColor(SemanticColors.textSecondary)
                    }

                    if let eventName = bill.eventName {
                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(eventName)
                                .font(.system(size: 11))
                                .lineLimit(1)
                        }
                        .foregroundColor(SemanticColors.textSecondary)
                    }
                }

                // Item counts
                HStack(spacing: Spacing.md) {
                    let perPersonCount = bill.items.filter { $0.type == .perPerson }.count
                    let serviceFeeCount = bill.items.filter { $0.type == .serviceFee }.count
                    let flatFeeCount = bill.items.filter { $0.type == .flatFee }.count

                    if perPersonCount > 0 {
                        itemCountTag(count: perPersonCount, label: "per-person", color: SoftLavender.shade500)
                    }

                    if serviceFeeCount > 0 {
                        itemCountTag(count: serviceFeeCount, label: serviceFeeCount == 1 ? "service fee" : "service fees", color: AppColors.info)
                    }

                    if flatFeeCount > 0 {
                        itemCountTag(count: flatFeeCount, label: flatFeeCount == 1 ? "flat fee" : "flat fees", color: SageGreen.shade500)
                    }

                    Spacer()

                    // Guest count badge
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text("\(bill.guestCount)")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(SoftLavender.shade700)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 2)
                    .background(SoftLavender.shade100)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
                }
            }
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                billToUnlink = bill
                showUnlinkConfirmation = true
            } label: {
                Label("Unlink Bill", systemImage: "link.badge.minus")
            }
        }
    }

    private func itemCountTag(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: Spacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(count) \(label)")
                .font(.system(size: 11))
        }
        .foregroundColor(SemanticColors.textTertiary)
    }

    // MARK: - Linked Bills Summary

    private var linkedBillsSummary: some View {
        let totalBillsAmount = linkedBills.reduce(0) { $0 + $1.grandTotal }
        let difference = totalBillsAmount - expense.amount
        let coveragePercent = expense.amount > 0 ? min(100, (totalBillsAmount / expense.amount) * 100) : 0

        return VStack(spacing: Spacing.sm) {
            Divider()
                .padding(.vertical, Spacing.xs)

            HStack {
                Text("Total from Bills")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)

                Spacer()

                Text(formatCurrency(totalBillsAmount))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(SemanticColors.textPrimary)
            }

            // Coverage bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SemanticColors.borderLight)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: coveragePercent >= 100
                                    ? [SemanticColors.statusSuccess, SemanticColors.statusSuccess.opacity(0.8)]
                                    : [AppColors.info, AppColors.info.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(coveragePercent / 100), height: 8)
                }
            }
            .frame(height: 8)

            // Difference display
            HStack {
                Text(String(format: "%.1f%% of expense covered", coveragePercent))
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textTertiary)

                Spacer()

                if abs(difference) > 0.01 {
                    Text(difference > 0 ? "+\(formatCurrency(difference))" : formatCurrency(difference))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(difference > 0 ? SemanticColors.statusWarning : AppColors.info)
                } else {
                    Text("Exact match")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(SemanticColors.statusSuccess)
                }
            }
        }
        .padding(.top, Spacing.xs)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack(spacing: Spacing.md) {
            // View Receipt button
            Button {
                // TODO: Open receipt
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "eye")
                        .font(.system(size: 14))
                    Text("View Receipt")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(SemanticColors.backgroundPrimary)
                .foregroundColor(SemanticColors.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(SemanticColors.borderPrimary, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            .disabled(expense.receiptUrl == nil)
            .opacity(expense.receiptUrl == nil ? 0.5 : 1)

            // Link Bill button
            Button {
                showLinkBillsModal = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "link")
                        .font(.system(size: 14))
                    Text("Link Bill")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(SemanticColors.backgroundPrimary)
                .foregroundColor(AppColors.info)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(AppColors.info, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)

            // Edit Expense button
            Button {
                showEditExpense = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                    Text("Edit Expense")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(
                    LinearGradient(
                        colors: [SemanticColors.primaryAction, SemanticColors.primaryActionHover],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    // MARK: - Data Loading

    private func loadData() {
        // Load category
        category = budgetStore.categoryStore.categories.first { $0.id == expense.budgetCategoryId }

        // Load vendor
        if let vendorId = expense.vendorId {
            vendor = AppStores.shared.vendor.vendors.first { $0.id == vendorId }
        }

        // Load linked payments
        Task {
            isLoadingPayments = true
            linkedPayments = budgetStore.payments.paymentSchedules
                .filter { $0.expenseId == expense.id }
                .sorted { $0.paymentDate < $1.paymentDate }
            isLoadingPayments = false
        }

        // Load linked bill calculators
        Task {
            isLoadingLinkedBills = true
            do {
                let links = try await budgetStore.repository.fetchBillCalculatorLinksForExpense(expenseId: expense.id)

                // Store the links for unlinking functionality
                linkedBillLinks = links

                // Early exit if no links exist
                guard !links.isEmpty else {
                    linkedBills = []
                    isLoadingLinkedBills = false
                    return
                }

                let billIds = Set(links.map { $0.billCalculatorId })

                // Ensure bill calculator store is loaded before filtering
                let billStore = AppStores.shared.billCalculator

                // Wait for bill store to finish loading if it's currently loading
                // or trigger a load if it hasn't started
                if billStore.loadingState.isIdle || billStore.loadingState.hasError {
                    await billStore.loadCalculators()
                } else if billStore.loadingState.isLoading {
                    // Wait for the in-progress load to complete by polling with timeout
                    var waitCount = 0
                    while billStore.loadingState.isLoading && waitCount < 100 { // Max 5 seconds
                        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                        waitCount += 1
                    }
                }

                // Get bill calculators from the store
                linkedBills = billStore.calculators.filter { billIds.contains($0.id) }
            } catch {
                logger.error("Failed to load linked bills for expense \(expense.id)", error: error)
                linkedBills = []
                linkedBillLinks = []
            }
            isLoadingLinkedBills = false
        }
    }

    // MARK: - Unlink Bill

    /// Unlinks a bill calculator from this expense
    private func unlinkBill(_ bill: BillCalculator) async {
        // Find the link ID for this bill
        guard let link = linkedBillLinks.first(where: { $0.billCalculatorId == bill.id }) else {
            logger.error("No link found for bill \(bill.id) when trying to unlink")
            return
        }

        isUnlinking = true
        defer { isUnlinking = false }

        do {
            try await budgetStore.repository.unlinkBillCalculatorFromExpense(linkId: link.id)
            logger.info("Successfully unlinked bill \(bill.name) from expense \(expense.id)")

            // Update local state
            linkedBills.removeAll { $0.id == bill.id }
            linkedBillLinks.removeAll { $0.billCalculatorId == bill.id }

            // Clear the selected bill
            billToUnlink = nil
        } catch {
            logger.error("Failed to unlink bill \(bill.id) from expense \(expense.id)", error: error)
            // The alert will have already dismissed, so we just log the error
        }
    }

    // MARK: - Helper Functions

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = settingsStore.settings.global.currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func daysUntilPayment(_ date: Date) -> Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: due).day
    }

    private func categoryIcon(for category: String) -> String {
        let lowercased = category.lowercased()
        if lowercased.contains("venue") { return "building.columns" }
        if lowercased.contains("catering") || lowercased.contains("food") { return "fork.knife" }
        if lowercased.contains("photo") { return "camera" }
        if lowercased.contains("flower") || lowercased.contains("floral") { return "leaf" }
        if lowercased.contains("music") || lowercased.contains("band") { return "music.note" }
        if lowercased.contains("dress") || lowercased.contains("attire") { return "tshirt" }
        if lowercased.contains("cake") { return "birthday.cake" }
        if lowercased.contains("video") { return "video" }
        return "tag"
    }

    private func statusColorAndIcon(for status: PaymentStatus) -> (Color, String) {
        switch status {
        case .pending:
            return (SemanticColors.statusPending, "clock")
        case .partial:
            return (Color.fromHex("EAB308"), "clock")
        case .paid:
            return (SemanticColors.statusSuccess, "checkmark.circle.fill")
        case .overdue:
            return (SemanticColors.statusWarning, "exclamationmark.triangle.fill")
        case .cancelled:
            return (SemanticColors.textTertiary, "xmark.circle")
        case .refunded:
            return (SoftLavender.shade600, "arrow.uturn.left")
        }
    }

    private func paymentMethodIcon(_ method: String) -> String {
        switch method.lowercased() {
        case "credit_card": return "creditcard"
        case "debit_card": return "creditcard"
        case "bank_transfer": return "building.columns"
        case "check": return "doc.text"
        case "cash": return "dollarsign"
        case "venmo", "zelle": return "arrow.left.arrow.right"
        default: return "creditcard"
        }
    }

    private func paymentMethodDisplayName(_ method: String) -> String {
        switch method.lowercased() {
        case "credit_card": return "Credit Card"
        case "debit_card": return "Debit Card"
        case "bank_transfer": return "Bank Transfer"
        case "check": return "Check"
        case "cash": return "Cash"
        case "venmo": return "Venmo"
        case "zelle": return "Zelle"
        default: return method.capitalized.replacingOccurrences(of: "_", with: " ")
        }
    }

    private func paymentTypeBadgeColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "deposit": return AppColors.info
        case "installment": return SoftLavender.shade600
        case "final": return Terracotta.shade500
        case "retainer": return SageGreen.shade600
        default: return SemanticColors.textSecondary
        }
    }
}

// MARK: - Preview

#Preview("Expense Detail Modal") {
    let mockExpense = Expense(
        id: UUID(),
        coupleId: UUID(),
        budgetCategoryId: UUID(),
        vendorId: nil,
        vendorName: "Elegant Events Center",
        expenseName: "Grand Ballroom Venue Deposit",
        amount: 4500.00,
        expenseDate: Date().addingTimeInterval(86400 * 38),
        paymentMethod: "credit_card",
        paymentStatus: .partial,
        receiptUrl: "https://example.com/receipt.pdf",
        invoiceNumber: "INV-2024-0042",
        notes: "Deposit secures the Grand Ballroom for the wedding ceremony and reception. Includes 6-hour venue rental, basic setup/cleanup, tables and chairs for 150 guests, and access to bridal suite.",
        approvalStatus: "approved",
        approvedBy: "Sarah Chen",
        approvedAt: Date().addingTimeInterval(-86400 * 7),
        invoiceDocumentUrl: "https://example.com/invoice.pdf",
        isTestData: true,
        createdAt: Date()
    )

    return ExpenseDetailModalView(expense: mockExpense)
        .environmentObject(BudgetStoreV2())
        .environmentObject(SettingsStoreV2())
        .environmentObject(AppCoordinator.shared)
}
