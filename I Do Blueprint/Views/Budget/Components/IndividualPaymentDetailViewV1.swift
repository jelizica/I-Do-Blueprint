//
//  IndividualPaymentDetailViewV1.swift
//  I Do Blueprint
//
//  Individual payment detail modal with paid/unpaid state handling
//  Follows V1 glassmorphism design patterns
//

import SwiftUI

struct IndividualPaymentDetailViewV1: View {
    let payment: PaymentSchedule
    @ObservedObject var vendorStore: VendorStoreV2
    @ObservedObject var budgetStore: BudgetStoreV2
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    @EnvironmentObject private var coordinator: AppCoordinator

    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingPlanModal = false
    @State private var showingRecordPaymentModal = false
    @State private var paymentPlanSummary: PaymentPlanSummary?
    @State private var isLoadingPlan = false
    @State private var hasAppeared = false

    // MARK: - Proportional Modal Sizing Pattern

    private let minWidth: CGFloat = 800
    private let maxWidth: CGFloat = 1000
    private let minHeight: CGFloat = 600
    private let maxHeight: CGFloat = 800
    private let widthProportion: CGFloat = 0.65
    private let heightProportion: CGFloat = 0.80

    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        let targetWidth = parentSize.width * widthProportion
        let targetHeight = parentSize.height * heightProportion
        // Clamp to min/max bounds, then ensure we never exceed parent window
        let boundedWidth = min(maxWidth, max(minWidth, targetWidth))
        let boundedHeight = min(maxHeight, max(minHeight, targetHeight))
        let finalWidth = min(boundedWidth, parentSize.width - 40) // 20px padding each side
        let finalHeight = min(boundedHeight, parentSize.height - 40)
        return CGSize(width: max(300, finalWidth), height: max(300, finalHeight))
    }

    // MARK: - Computed Properties

    private var userTimezone: TimeZone {
        DateFormatting.userTimeZone(from: settingsStore.settings)
    }

    private var vendor: Vendor? {
        guard let vendorId = payment.vendorId else { return nil }
        return vendorStore.vendors.first { $0.id == vendorId }
    }

    private var vendorName: String {
        vendor?.vendorName ?? payment.vendor
    }

    private var paymentTitle: String {
        if let order = payment.paymentOrder, let total = payment.totalPaymentCount {
            let typeLabel = payment.isDeposit ? "Deposit" : "Payment"
            return "\(typeLabel) \(order) of \(total)"
        }
        return payment.isDeposit ? "Deposit" : "Payment"
    }

    private var relatedExpense: Expense? {
        guard case .loaded(let data) = budgetStore.loadingState else { return nil }
        return data.expenses.first { $0.id == payment.expenseId }
    }

    /// Whether this payment is part of a payment plan
    private var isPartOfPlan: Bool {
        payment.paymentPlanId != nil
    }

    /// All payments in the same plan as this payment
    private var planPayments: [PaymentSchedule] {
        guard let planId = payment.paymentPlanId else { return [] }
        return budgetStore.payments.paymentSchedules
            .filter { $0.paymentPlanId == planId }
            .sorted { $0.paymentDate < $1.paymentDate }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Hero Card with amount and actions
                    heroCard

                    // Vendor Details and Payment History
                    HStack(alignment: .top, spacing: Spacing.lg) {
                        IndividualPaymentVendorCardV1(
                            vendor: vendor,
                            vendorName: vendorName,
                            expense: relatedExpense
                        )

                        IndividualPaymentHistoryCardV1(
                            payment: payment,
                            timezone: userTimezone
                        )
                    }

                    // Notes Section
                    if let notes = payment.notes, !notes.isEmpty {
                        IndividualPaymentNotesCardV1(notes: notes)
                    }
                }
                .padding(Spacing.xl)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle(paymentTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .frame(width: dynamicSize.width, height: dynamicSize.height)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                hasAppeared = true
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            PaymentEditModal(
                payment: payment,
                expense: relatedExpense,
                getVendorName: { _ in vendorName },
                onUpdate: { updated in
                    Task { await budgetStore.payments.updatePayment(updated) }
                },
                onDelete: {
                    Task {
                        await budgetStore.payments.deletePayment(id: payment.id)
                        dismiss()
                    }
                }
            )
            .environmentObject(settingsStore)
        }
        .sheet(isPresented: $showingPlanModal) {
            if let summary = paymentPlanSummary {
                PaymentPlanDetailModal(
                    plan: summary,
                    paymentSchedules: budgetStore.payments.paymentSchedules,
                    onUpdate: { updatedPayment in
                        Task {
                            await budgetStore.payments.updatePayment(updatedPayment)
                        }
                    },
                    onDelete: { paymentToDelete in
                        Task {
                            await budgetStore.payments.deletePayment(id: paymentToDelete.id)
                        }
                    },
                    getVendorName: { vendorId in
                        guard let id = vendorId else { return nil }
                        return vendorStore.vendors.first(where: { $0.id == id })?.vendorName
                    }
                )
            }
        }
        .sheet(isPresented: $showingRecordPaymentModal) {
            RecordPaymentModal(
                payment: payment,
                onRecordPayment: { amount in
                    await budgetStore.payments.recordPartialPayment(
                        payment: payment,
                        amountPaid: amount
                    )
                }
            )
            .environmentObject(settingsStore)
            .environmentObject(coordinator)
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(spacing: Spacing.xl) {
            // Header row: Status + Amount + Actions
            HStack(alignment: .top, spacing: Spacing.xxl) {
                // Left: Status and Amount
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    IndividualPaymentStatusBadgeV1(
                        isPaid: payment.paid,
                        date: payment.paymentDate,
                        timezone: userTimezone
                    )

                    IndividualPaymentAmountV1(
                        amount: payment.paymentAmount,
                        isPaid: payment.paid,
                        date: payment.paymentDate,
                        timezone: userTimezone
                    )
                }

                Spacer()

                // Right: Action Buttons
                IndividualPaymentActionsV1(
                    payment: payment,
                    onMarkPaid: handleMarkPaid,
                    onRecordPayment: { showingRecordPaymentModal = true },
                    onViewReceipt: handleViewReceipt,
                    onEdit: { showingEditSheet = true },
                    onPlan: handlePlan
                )
            }

            NativeDividerStyle(opacity: 0.3)

            // Stats Grid
            IndividualPaymentStatsGridV1(
                originalAmount: payment.paymentAmount,
                remainingBalance: payment.paid ? 0 : payment.paymentAmount
            )
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xxl)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xxl)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }

    // MARK: - Actions

    private func handleMarkPaid() {
        Task {
            var updated = payment
            updated.paid = true
            await budgetStore.payments.updatePayment(updated)
        }
    }

    private func handleViewReceipt() {
        // TODO: Implement receipt viewing
    }

    private func handlePlan() {
        guard let planId = payment.paymentPlanId,
              let expenseId = payment.expenseId else { return }

        isLoadingPlan = true

        Task {
            // Load the payment plan summary
            if let summary = await budgetStore.payments.loadPaymentPlanSummary(expenseId: expenseId) {
                await MainActor.run {
                    self.paymentPlanSummary = summary
                    self.isLoadingPlan = false
                    self.showingPlanModal = true
                }
            } else {
                // Try to construct a basic summary from the payments we have
                let payments = planPayments
                if !payments.isEmpty {
                    let summary = constructPlanSummary(from: payments, planId: planId)
                    await MainActor.run {
                        self.paymentPlanSummary = summary
                        self.isLoadingPlan = false
                        self.showingPlanModal = true
                    }
                } else {
                    await MainActor.run {
                        self.isLoadingPlan = false
                    }
                }
            }
        }
    }

    private func constructPlanSummary(from payments: [PaymentSchedule], planId: UUID) -> PaymentPlanSummary {
        let total = payments.reduce(0) { $0 + $1.paymentAmount }
        let paid = payments.filter { $0.paid }.reduce(0) { $0 + $1.paymentAmount }
        let paidCount = payments.filter { $0.paid }.count
        let unpaidCount = payments.count - paidCount
        let sortedPayments = payments.sorted { $0.paymentDate < $1.paymentDate }
        let depositPayments = payments.filter { $0.isDeposit }
        let overduePayments = sortedPayments.filter { !$0.paid && $0.paymentDate < Date() }
        let allPaid = payments.allSatisfy { $0.paid }
        let anyPaid = payments.contains { $0.paid }

        // Determine plan status
        let planStatus: PaymentPlanSummary.PlanStatus
        if allPaid {
            planStatus = .completed
        } else if !overduePayments.isEmpty {
            planStatus = .overdue
        } else if anyPaid {
            planStatus = .inProgress
        } else {
            planStatus = .pending
        }

        return PaymentPlanSummary(
            paymentPlanId: planId,
            expenseId: payment.expenseId ?? UUID(),
            coupleId: payment.coupleId,
            vendor: vendorName,
            vendorId: payment.vendorId ?? 0,
            vendorType: payment.vendorType,
            paymentType: payment.paymentType ?? "plan",
            paymentPlanType: payment.paymentPlanType ?? "custom",
            planTypeDisplay: payment.paymentPlanType ?? "Payment Plan",
            totalPayments: payments.count,
            firstPaymentDate: sortedPayments.first?.paymentDate ?? Date(),
            lastPaymentDate: sortedPayments.last?.paymentDate ?? Date(),
            depositDate: depositPayments.first?.paymentDate,
            totalAmount: total,
            amountPaid: paid,
            amountRemaining: total - paid,
            depositAmount: depositPayments.first?.paymentAmount ?? 0,
            percentPaid: total > 0 ? (paid / total * 100) : 0,
            actualPaymentCount: Int64(payments.count),
            paymentsCompleted: Int64(paidCount),
            paymentsRemaining: Int64(unpaidCount),
            depositCount: Int64(depositPayments.count),
            allPaid: allPaid,
            anyPaid: anyPaid,
            hasDeposit: !depositPayments.isEmpty,
            hasRetainer: payments.contains { $0.isRetainer },
            planStatus: planStatus,
            nextPaymentDate: sortedPayments.first { !$0.paid }?.paymentDate,
            nextPaymentAmount: sortedPayments.first { !$0.paid }?.paymentAmount,
            daysUntilNextPayment: nil,
            overdueCount: Int64(overduePayments.count),
            overdueAmount: overduePayments.reduce(0) { $0 + $1.paymentAmount },
            combinedNotes: nil,
            planCreatedAt: payments.first?.createdAt ?? Date(),
            planUpdatedAt: payments.compactMap { $0.updatedAt }.max()
        )
    }
}
