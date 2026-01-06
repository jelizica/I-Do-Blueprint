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
        // TODO: Implement payment planning
    }
}
