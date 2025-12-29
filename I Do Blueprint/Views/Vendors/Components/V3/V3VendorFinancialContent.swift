//
//  V3VendorFinancialContent.swift
//  I Do Blueprint
//
//  Financial tab content for V3 vendor detail view
//

import SwiftUI

struct V3VendorFinancialContent: View {
    let vendor: Vendor
    let expenses: [Expense]
    let payments: [PaymentSchedule]
    let isLoading: Bool

    // MARK: - Computed Properties

    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var paidAmount: Double {
        payments.filter { $0.paid }.reduce(0) { $0 + $1.paymentAmount }
    }

    private var pendingAmount: Double {
        totalExpenses - paidAmount
    }

    private var paymentProgress: Double {
        guard totalExpenses > 0 else { return 0 }
        return min((paidAmount / totalExpenses) * 100, 100)
    }

    private var hasAnyFinancialInfo: Bool {
        vendor.quotedAmount != nil || !expenses.isEmpty || !payments.isEmpty
    }

    var body: some View {
        VStack(spacing: Spacing.xxxl) {
            if isLoading {
                loadingState
            } else if hasAnyFinancialInfo {
                financialContent
            } else {
                emptyState
            }
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading financial data...")
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)

            Text("No Financial Information")
                .font(Typography.heading)
                .foregroundColor(AppColors.textSecondary)

            Text("Add quoted amount, expenses, or payment schedules to track financial details for this vendor.")
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxxl)
    }

    // MARK: - Financial Content

    private var financialContent: some View {
        VStack(spacing: Spacing.xxxl) {
            // Quoted Amount Section
            if let quotedAmount = vendor.quotedAmount {
                quotedAmountSection(amount: quotedAmount)
            }

            // Expenses Section
            if !expenses.isEmpty {
                expensesSection
            }

            // Payment Schedule Section
            if !payments.isEmpty {
                paymentScheduleSection
            }
        }
    }

    // MARK: - Quoted Amount Section

    private func quotedAmountSection(amount: Double) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            V3SectionHeader(
                title: "Quoted Amount",
                icon: "banknote.fill",
                color: AppColors.Vendor.booked
            )

            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Total Quote")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text(amount.formatted(.currency(code: "USD")))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.primary)
                }

                Spacer()

                if let category = vendor.categoryDisplayName {
                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        Text("Category")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)

                        Text(category)
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .padding(Spacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Expenses Section

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            V3SectionHeader(
                title: "Expenses",
                icon: "receipt.fill",
                color: AppColors.Vendor.booked
            )

            // Summary Cards
            HStack(spacing: Spacing.md) {
                V3ExpenseSummaryCard(
                    title: "Total",
                    amount: totalExpenses,
                    icon: "sum",
                    color: AppColors.primary
                )

                V3ExpenseSummaryCard(
                    title: "Paid",
                    amount: paidAmount,
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                V3ExpenseSummaryCard(
                    title: "Pending",
                    amount: pendingAmount,
                    icon: "clock.fill",
                    color: .orange
                )
            }

            // Expense List
            VStack(spacing: Spacing.sm) {
                ForEach(expenses.sorted(by: { $0.expenseDate > $1.expenseDate })) { expense in
                    V3ExpenseRow(expense: expense)
                }
            }
        }
    }

    // MARK: - Payment Schedule Section

    private var paymentScheduleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            V3SectionHeader(
                title: "Payment Schedule",
                icon: "calendar.badge.clock",
                color: AppColors.Vendor.pending
            )

            // Progress Card
            V3PaymentProgressCard(
                totalAmount: totalExpenses,
                paidAmount: paidAmount,
                remainingAmount: pendingAmount,
                progressPercentage: paymentProgress
            )

            // Payment Groups
            let overduePayments = payments.filter { !$0.paid && $0.paymentDate < Date() }
            let upcomingPayments = payments.filter { !$0.paid && $0.paymentDate >= Date() }
            let paidPayments = payments.filter { $0.paid }

            // Overdue Payments
            if !overduePayments.isEmpty {
                paymentGroup(title: "Overdue", payments: overduePayments, isOverdue: true)
            }

            // Upcoming Payments
            if !upcomingPayments.isEmpty {
                paymentGroup(title: "Upcoming", payments: upcomingPayments, isOverdue: false)
            }

            // Paid Payments (collapsible)
            if !paidPayments.isEmpty {
                paidPaymentsGroup(payments: paidPayments)
            }
        }
    }

    private func paymentGroup(title: String, payments: [PaymentSchedule], isOverdue: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(Typography.subheading)
                .foregroundColor(isOverdue ? .red : AppColors.textSecondary)

            ForEach(payments.sorted(by: { $0.paymentDate < $1.paymentDate })) { payment in
                V3PaymentRow(payment: payment, isOverdue: isOverdue)
            }
        }
    }

    private func paidPaymentsGroup(payments: [PaymentSchedule]) -> some View {
        DisclosureGroup {
            VStack(spacing: Spacing.sm) {
                ForEach(payments.sorted(by: { $0.paymentDate > $1.paymentDate })) { payment in
                    V3PaymentRow(payment: payment, isOverdue: false)
                }
            }
        } label: {
            HStack {
                Text("Paid (\(payments.count))")
                    .font(Typography.subheading)
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                Text(payments.reduce(0) { $0 + $1.paymentAmount }.formatted(.currency(code: "USD")))
                    .font(Typography.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(Spacing.sm)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Expense Summary Card

private struct V3ExpenseSummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(amount.formatted(.currency(code: "USD")))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Expense Row

private struct V3ExpenseRow: View {
    let expense: Expense

    private var statusColor: Color {
        switch expense.paymentStatus {
        case .paid: return .green
        case .pending: return .orange
        case .overdue: return .red
        case .partial: return .yellow
        case .cancelled: return .gray
        case .refunded: return .purple
        }
    }

    private var statusIcon: String {
        switch expense.paymentStatus {
        case .paid: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .partial: return "circle.lefthalf.filled"
        case .cancelled: return "xmark.circle.fill"
        case .refunded: return "arrow.uturn.backward.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status Indicator
            Image(systemName: statusIcon)
                .font(.title3)
                .foregroundColor(statusColor)
                .frame(width: 24)

            // Expense Info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(expense.expenseName)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textPrimary)

                HStack(spacing: Spacing.xs) {
                    Text(expense.expenseDate.formatted(date: .abbreviated, time: .omitted))
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    if let invoiceNumber = expense.invoiceNumber, !invoiceNumber.isEmpty {
                        Text("•")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)

                        Text("Invoice: \(invoiceNumber)")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }

            Spacer()

            // Amount and Status
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(expense.amount.formatted(.currency(code: "USD")))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text(expense.paymentStatus.displayName)
                    .font(Typography.caption)
                    .foregroundColor(statusColor)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Payment Progress Card

private struct V3PaymentProgressCard: View {
    let totalAmount: Double
    let paidAmount: Double
    let remainingAmount: Double
    let progressPercentage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Progress Bar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Payment Progress")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    Text("\(Int(progressPercentage))%")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.border.opacity(0.3))
                            .frame(height: 8)

                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primary.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (progressPercentage / 100), height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Amount Summary
            HStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Paid")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text(paidAmount.formatted(.currency(code: "USD")))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.green)
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Remaining")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text(remainingAmount.formatted(.currency(code: "USD")))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.orange)
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Total")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Text(totalAmount.formatted(.currency(code: "USD")))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Payment Row

private struct V3PaymentRow: View {
    let payment: PaymentSchedule
    let isOverdue: Bool

    private var statusColor: Color {
        if payment.paid {
            return .green
        } else if isOverdue {
            return .red
        } else {
            return .orange
        }
    }

    private var statusIcon: String {
        if payment.paid {
            return "checkmark.circle.fill"
        } else if isOverdue {
            return "exclamationmark.triangle.fill"
        } else {
            return "clock.fill"
        }
    }

    private var statusText: String {
        if payment.paid {
            return "Paid"
        } else if isOverdue {
            return "Overdue"
        } else {
            return "Pending"
        }
    }

    private var daysUntilDue: Int? {
        guard !payment.paid else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: payment.paymentDate).day
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status Indicator
            Image(systemName: statusIcon)
                .font(.title3)
                .foregroundColor(statusColor)
                .frame(width: 24)

            // Payment Info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Text(payment.paymentDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textPrimary)

                    if payment.isDeposit {
                        Text("• Deposit")
                            .font(Typography.caption)
                            .foregroundColor(.blue)
                    } else if payment.isRetainer {
                        Text("• Retainer")
                            .font(Typography.caption)
                            .foregroundColor(.purple)
                    }
                }

                HStack(spacing: Spacing.xs) {
                    Text(statusText)
                        .font(Typography.caption)
                        .foregroundColor(statusColor)

                    if let days = daysUntilDue {
                        Text("•")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)

                        if days == 0 {
                            Text("Due today")
                                .font(Typography.caption)
                                .foregroundColor(.red)
                        } else if days > 0 {
                            Text("Due in \(days) day\(days == 1 ? "" : "s")")
                                .font(Typography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }

            Spacer()

            // Amount
            Text(payment.paymentAmount.formatted(.currency(code: "USD")))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isOverdue ? Color.red.opacity(0.3) : AppColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview("Financial Content - With Data") {
    ScrollView {
        V3VendorFinancialContent(
            vendor: .makeTest(quotedAmount: 5000),
            expenses: [
                Expense(
                    id: UUID(),
                    coupleId: UUID(),
                    budgetCategoryId: UUID(),
                    vendorId: 1,
                    vendorName: "Test Vendor",
                    expenseName: "Wedding Cake",
                    amount: 496.57,
                    expenseDate: Date(),
                    paymentMethod: "debit_card",
                    paymentStatus: .partial,
                    receiptUrl: nil,
                    invoiceNumber: nil,
                    notes: nil,
                    approvalStatus: "approved",
                    approvedBy: nil,
                    approvedAt: nil,
                    invoiceDocumentUrl: nil,
                    isTestData: false,
                    createdAt: Date(),
                    updatedAt: nil
                )
            ],
            payments: [
                PaymentSchedule(
                    id: 1,
                    coupleId: UUID(),
                    vendor: "Test",
                    paymentDate: Date().addingTimeInterval(-86400 * 5),
                    paymentAmount: 75,
                    notes: nil,
                    vendorType: nil,
                    paid: true,
                    paymentType: nil,
                    customAmount: nil,
                    billingFrequency: nil,
                    autoRenew: false,
                    startDate: nil,
                    reminderEnabled: false,
                    reminderDaysBefore: nil,
                    priorityLevel: nil,
                    expenseId: nil,
                    vendorId: 1,
                    isDeposit: false,
                    isRetainer: false,
                    paymentOrder: nil,
                    totalPaymentCount: nil,
                    paymentPlanType: nil,
                    createdAt: Date(),
                    updatedAt: nil
                )
            ],
            isLoading: false
        )
        .padding()
    }
    .background(AppColors.background)
}

#Preview("Financial Content - Empty") {
    V3VendorFinancialContent(
        vendor: .makeTest(quotedAmount: nil),
        expenses: [],
        payments: [],
        isLoading: false
    )
    .padding()
    .background(AppColors.background)
}
