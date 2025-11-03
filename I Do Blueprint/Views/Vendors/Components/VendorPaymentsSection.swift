//
//  VendorPaymentsSection.swift
//  I Do Blueprint
//
//  Displays payment schedules linked to a vendor
//

import SwiftUI

struct VendorPaymentsSection: View {
    let payments: [PaymentSchedule]

    private var totalAmount: Double {
        payments.reduce(0) { $0 + $1.paymentAmount }
    }

    private var paidAmount: Double {
        payments.filter { $0.paid }.reduce(0) { $0 + $1.paymentAmount }
    }

    private var remainingAmount: Double {
        totalAmount - paidAmount
    }

    private var upcomingPayments: [PaymentSchedule] {
        payments.filter { !$0.paid && $0.paymentDate >= Date() }
            .sorted { $0.paymentDate < $1.paymentDate }
    }

    private var overduePayments: [PaymentSchedule] {
        payments.filter { !$0.paid && $0.paymentDate < Date() }
            .sorted { $0.paymentDate < $1.paymentDate }
    }

    private var paidPayments: [PaymentSchedule] {
        payments.filter { $0.paid }
            .sorted { $0.paymentDate > $1.paymentDate }
    }

    private var progressPercentage: Double {
        guard totalAmount > 0 else { return 0 }
        return (paidAmount / totalAmount) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section Header
            SectionHeaderV2(
                title: "Payment Schedule",
                icon: "calendar.badge.clock",
                color: AppColors.Vendor.pending
            )

            // Progress Card
            PaymentProgressCard(
                totalAmount: totalAmount,
                paidAmount: paidAmount,
                remainingAmount: remainingAmount,
                progressPercentage: progressPercentage
            )

            // Overdue Payments (if any)
            if !overduePayments.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Overdue")
                        .font(.subheadline)
                        .foregroundColor(.red)

                    ForEach(overduePayments) { payment in
                        VendorPaymentRow(payment: payment, isOverdue: true)
                    }
                }
            }

            // Upcoming Payments
            if !upcomingPayments.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Upcoming")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)

                    ForEach(upcomingPayments) { payment in
                        VendorPaymentRow(payment: payment, isOverdue: false)
                    }
                }
            }

            // Paid Payments (collapsible)
            if !paidPayments.isEmpty {
                DisclosureGroup {
                    VStack(spacing: Spacing.sm) {
                        ForEach(paidPayments) { payment in
                            VendorPaymentRow(payment: payment, isOverdue: false)
                        }
                    }
                } label: {
                    HStack {
                        Text("Paid (\(paidPayments.count))")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)

                        Spacer()

                        Text(paidAmount.formatted(.currency(code: "USD")))
                            .font(Typography.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding(Spacing.sm)
                .background(AppColors.cardBackground)
                .cornerRadius(CornerRadius.md)
            }
        }
    }
}

// MARK: - Supporting Views

private struct PaymentProgressCard: View {
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

private struct VendorPaymentRow: View {
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
        let days = calendar.dateComponents([.day], from: Date(), to: payment.paymentDate).day
        return days
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

#Preview {
    VStack {
        VendorPaymentsSection(payments: [
            PaymentSchedule(
                id: 1,
                coupleId: UUID(),
                vendor: "Test Vendor",
                paymentDate: Date().addingTimeInterval(-86400 * 5),
                paymentAmount: 2000,
                notes: nil,
                vendorType: nil,
                paid: false,
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
                isDeposit: true,
                isRetainer: false,
                paymentOrder: 1,
                totalPaymentCount: 3,
                paymentPlanType: nil,
                createdAt: Date(),
                updatedAt: nil
            ),
            PaymentSchedule(
                id: 2,
                coupleId: UUID(),
                vendor: "Test Vendor",
                paymentDate: Date().addingTimeInterval(86400 * 15),
                paymentAmount: 5000,
                notes: nil,
                vendorType: nil,
                paid: false,
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
                paymentOrder: 2,
                totalPaymentCount: 3,
                paymentPlanType: nil,
                createdAt: Date(),
                updatedAt: nil
            ),
            PaymentSchedule(
                id: 3,
                coupleId: UUID(),
                vendor: "Test Vendor",
                paymentDate: Date().addingTimeInterval(86400 * 60),
                paymentAmount: 8000,
                notes: nil,
                vendorType: nil,
                paid: false,
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
                paymentOrder: 3,
                totalPaymentCount: 3,
                paymentPlanType: nil,
                createdAt: Date(),
                updatedAt: nil
            )
        ])
    }
    .padding()
    .background(AppColors.background)
}
