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

    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var hasAppeared = false

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
        .frame(minWidth: 800, maxWidth: 1000, minHeight: 600, maxHeight: 800)
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
