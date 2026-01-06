//
//  VendorDetailFinancialTabV2.swift
//  I Do Blueprint
//
//  Enhanced financial tab with payment schedule pie chart, expenses list, and payment details
//

import SwiftUI

struct VendorDetailFinancialTabV2: View {
    let vendor: Vendor
    let expenses: [Expense]
    let payments: [PaymentSchedule]
    let isLoading: Bool

    var body: some View {
        VStack(spacing: Spacing.xl) {
            if isLoading {
                loadingView
            } else if hasAnyFinancialInfo {
                financialContent
            } else {
                VendorEmptyStateView(
                    icon: "dollarsign.circle",
                    title: "No Financial Information",
                    message: "Add quoted amount, expenses, or payment schedules to track financial details for this vendor."
                )
            }
        }
    }

    // MARK: - Components

    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading financial data...")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var financialContent: some View {
        VStack(spacing: Spacing.xl) {
            // Top row: Quoted Amount card and Payment Schedule pie chart
            HStack(alignment: .top, spacing: Spacing.lg) {
                // Quoted Amount Card
                quotedAmountCard

                // Payment Schedule Overview with Pie Chart
                if !payments.isEmpty {
                    paymentScheduleOverview
                }
            }

            // Expenses Section
            if !expenses.isEmpty {
                expensesSection
            }

            // Payment Schedule Details
            if !payments.isEmpty {
                paymentScheduleDetails
            }
        }
    }

    // MARK: - Quoted Amount Card

    private var quotedAmountCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Quoted Amount",
                icon: "banknote.fill",
                color: SemanticColors.primaryAction
            )

            VStack(spacing: Spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Total Quote")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)

                        Text((vendor.quotedAmount ?? 0).formatted(.currency(code: "USD")))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(SemanticColors.textPrimary)
                    }

                    Spacer()

                    ZStack {
                        Circle()
                            .fill(SemanticColors.primaryAction.opacity(Opacity.subtle))
                            .frame(width: 56, height: 56)

                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(SemanticColors.primaryAction)
                    }
                }

                // Summary stats
                HStack(spacing: Spacing.lg) {
                    FinancialStatV2(
                        label: "Total Paid",
                        value: totalPaid,
                        color: SemanticColors.success
                    )

                    FinancialStatV2(
                        label: "Remaining",
                        value: remainingAmount,
                        color: SemanticColors.warning
                    )
                }
            }
            .padding(Spacing.lg)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(CornerRadius.lg)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Payment Schedule Overview with Pie Chart

    private var paymentScheduleOverview: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Payment Schedule",
                icon: "chart.pie.fill",
                color: SemanticColors.success
            )

            HStack(spacing: Spacing.xl) {
                // Pie Chart
                PaymentPieChart(
                    paidAmount: totalPaid,
                    pendingAmount: totalPending
                )
                .frame(width: 120, height: 120)

                // Legend
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    PaymentLegendItem(
                        color: SemanticColors.success,
                        label: "Paid",
                        amount: totalPaid,
                        percentage: paidPercentage
                    )

                    PaymentLegendItem(
                        color: SemanticColors.warning,
                        label: "Pending",
                        amount: totalPending,
                        percentage: pendingPercentage
                    )

                    Divider()
                        .padding(.vertical, Spacing.xs)

                    HStack {
                        Text("Total")
                            .font(Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(SemanticColors.textPrimary)

                        Spacer()

                        Text(totalPayments.formatted(.currency(code: "USD")))
                            .font(Typography.bodyRegular)
                            .fontWeight(.bold)
                            .foregroundColor(SemanticColors.textPrimary)
                    }
                }
            }
            .padding(Spacing.lg)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(CornerRadius.lg)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Expenses Section

    private var expensesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                SectionHeaderV2(
                    title: "Expenses (\(expenses.count))",
                    icon: "list.bullet.circle.fill",
                    color: SemanticColors.warning
                )

                Spacer()

                Text("Total: \(totalExpenses.formatted(.currency(code: "USD")))")
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            VStack(spacing: Spacing.sm) {
                ForEach(expenses) { expense in
                    ExpenseRowV2(expense: expense)
                }
            }
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Payment Schedule Details

    private var paymentScheduleDetails: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                SectionHeaderV2(
                    title: "Payment Details (\(payments.count))",
                    icon: "calendar.circle.fill",
                    color: SemanticColors.success
                )

                Spacer()

                HStack(spacing: Spacing.md) {
                    PaymentCountBadge(
                        count: paidPaymentsCount,
                        label: "Paid",
                        color: SemanticColors.success
                    )

                    PaymentCountBadge(
                        count: pendingPaymentsCount,
                        label: "Pending",
                        color: SemanticColors.warning
                    )
                }
            }

            VStack(spacing: Spacing.sm) {
                ForEach(sortedPayments) { payment in
                    PaymentRowV2(payment: payment)
                }
            }
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Computed Properties

    private var hasAnyFinancialInfo: Bool {
        vendor.quotedAmount != nil || !expenses.isEmpty || !payments.isEmpty
    }

    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var totalPaid: Double {
        payments.filter { $0.paid == true }.reduce(0) { $0 + $1.paymentAmount }
    }

    private var totalPending: Double {
        payments.filter { $0.paid != true }.reduce(0) { $0 + $1.paymentAmount }
    }

    private var totalPayments: Double {
        payments.reduce(0) { $0 + $1.paymentAmount }
    }

    private var remainingAmount: Double {
        (vendor.quotedAmount ?? 0) - totalPaid
    }

    private var paidPercentage: Double {
        guard totalPayments > 0 else { return 0 }
        return (totalPaid / totalPayments) * 100
    }

    private var pendingPercentage: Double {
        guard totalPayments > 0 else { return 0 }
        return (totalPending / totalPayments) * 100
    }

    private var paidPaymentsCount: Int {
        payments.filter { $0.paid == true }.count
    }

    private var pendingPaymentsCount: Int {
        payments.filter { $0.paid != true }.count
    }

    private var sortedPayments: [PaymentSchedule] {
        payments.sorted { $0.paymentDate < $1.paymentDate }
    }
}

// MARK: - Supporting Views

struct FinancialStatV2: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(label)
                .font(Typography.caption2)
                .foregroundColor(SemanticColors.textSecondary)

            Text(value.formatted(.currency(code: "USD")))
                .font(Typography.bodyRegular)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PaymentPieChart: View {
    let paidAmount: Double
    let pendingAmount: Double

    private var total: Double {
        paidAmount + pendingAmount
    }

    private var paidAngle: Double {
        guard total > 0 else { return 0 }
        return (paidAmount / total) * 360
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(SemanticColors.backgroundSecondary)

            // Pending slice (full circle background)
            Circle()
                .fill(SemanticColors.warning.opacity(Opacity.semiLight))

            // Paid slice
            if paidAmount > 0 {
                PieSlice(startAngle: -90, endAngle: -90 + paidAngle)
                    .fill(SemanticColors.success)
            }

            // Center circle with percentage
            Circle()
                .fill(SemanticColors.backgroundSecondary)
                .frame(width: 60, height: 60)

            VStack(spacing: 0) {
                Text("\(Int(paidPercentage))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Paid")
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
    }

    private var paidPercentage: Double {
        guard total > 0 else { return 0 }
        return (paidAmount / total) * 100
    }
}

struct PieSlice: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: Angle(degrees: startAngle),
            endAngle: Angle(degrees: endAngle),
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}

struct PaymentLegendItem: View {
    let color: Color
    let label: String
    let amount: Double
    let percentage: Double

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)

            Spacer()

            VStack(alignment: .trailing, spacing: 0) {
                Text(amount.formatted(.currency(code: "USD")))
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("\(Int(percentage))%")
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
            }
        }
    }
}

struct PaymentCountBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Text("\(count)")
                .font(Typography.caption)
                .fontWeight(.bold)

            Text(label)
                .font(Typography.caption2)
        }
        .foregroundColor(color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(color.opacity(Opacity.subtle))
        .cornerRadius(CornerRadius.pill)
    }
}

struct ExpenseRowV2: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(Opacity.subtle))
                    .frame(width: 40, height: 40)

                Image(systemName: "receipt.fill")
                    .font(.system(size: 16))
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(expense.expenseName)
                    .font(Typography.bodyRegular)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)

                Text(expense.expenseDate.formatted(date: .abbreviated, time: .omitted))
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(expense.amount.formatted(.currency(code: "USD")))
                    .font(Typography.bodyRegular)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)

                ExpenseStatusBadge(status: expense.paymentStatus)
            }
        }
        .padding(Spacing.sm)
        .background(SemanticColors.backgroundPrimary.opacity(Opacity.medium))
        .cornerRadius(CornerRadius.sm)
    }

    private var statusColor: Color {
        switch expense.paymentStatus {
        case .paid: return SemanticColors.success
        case .pending: return SemanticColors.warning
        case .overdue: return SemanticColors.error
        default: return SemanticColors.textSecondary
        }
    }
}

struct ExpenseStatusBadge: View {
    let status: PaymentStatus

    private var statusColor: Color {
        switch status {
        case .paid: return SemanticColors.success
        case .pending: return SemanticColors.warning
        case .overdue: return SemanticColors.error
        default: return SemanticColors.textSecondary
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(Typography.caption2)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(statusColor.opacity(Opacity.subtle))
            .cornerRadius(CornerRadius.pill)
    }
}

struct PaymentRowV2: View {
    let payment: PaymentSchedule

    private var isPaid: Bool {
        payment.paid == true
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(isPaid ? SemanticColors.success.opacity(Opacity.subtle) : SemanticColors.warning.opacity(Opacity.subtle))
                    .frame(width: 40, height: 40)

                Image(systemName: isPaid ? "checkmark.circle.fill" : "clock.fill")
                    .font(.system(size: 18))
                    .foregroundColor(isPaid ? SemanticColors.success : SemanticColors.warning)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(payment.paymentDate.formatted(date: .abbreviated, time: .omitted))
                    .font(Typography.bodyRegular)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)

                if let notes = payment.notes, !notes.isEmpty {
                    Text(notes)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(payment.paymentAmount.formatted(.currency(code: "USD")))
                    .font(Typography.bodyRegular)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)

                HStack(spacing: Spacing.xxs) {
                    Image(systemName: isPaid ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                    Text(isPaid ? "Paid" : "Pending")
                        .font(Typography.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(isPaid ? SemanticColors.success : SemanticColors.warning)
            }
        }
        .padding(Spacing.sm)
        .background(SemanticColors.backgroundPrimary.opacity(Opacity.medium))
        .cornerRadius(CornerRadius.sm)
    }
}
