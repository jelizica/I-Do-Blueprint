//
//  PaymentPlanDetailModal.swift
//  I Do Blueprint
//
//  Modal for viewing and editing payment plan details
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Modal that displays payment plan details with option to edit
struct PaymentPlanDetailModal: View {
    let plan: PaymentPlanSummary
    let paymentSchedules: [PaymentSchedule]
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: AppCoordinator
    @State private var showingEditMode = false
    @State private var selectedSchedule: PaymentSchedule?

    // MARK: - Proportional Modal Sizing Pattern

    private let minWidth: CGFloat = 700
    private let maxWidth: CGFloat = 900
    private let minHeight: CGFloat = 600
    private let maxHeight: CGFloat = 800
    private let windowChromeBuffer: CGFloat = 40
    private let widthProportion: CGFloat = 0.60
    private let heightProportion: CGFloat = 0.80

    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        let targetWidth = parentSize.width * widthProportion
        let targetHeight = parentSize.height * heightProportion - windowChromeBuffer
        let finalWidth = min(maxWidth, max(minWidth, targetWidth))
        let finalHeight = min(maxHeight, max(minHeight, targetHeight))
        return CGSize(width: finalWidth, height: finalHeight)
    }
    
    private var planPayments: [PaymentSchedule] {
        paymentSchedules
            .filter { schedule in
                if let schedulePlanId = schedule.paymentPlanId,
                   schedulePlanId == plan.paymentPlanId {
                    return true
                }
                return false
            }
            .sorted { $0.paymentDate < $1.paymentDate }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Plan Overview Section
                    planOverviewSection
                    
                    Divider()
                    
                    // Financial Summary Section
                    financialSummarySection
                    
                    Divider()
                    
                    // Payment Schedule Section
                    paymentScheduleSection
                    
                    Divider()
                    
                    // Plan Details Section
                    planDetailsSection
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("Payment Plan Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedSchedule) { schedule in
                PaymentEditModal(
                    payment: schedule,
                    expense: nil,
                    getVendorName: getVendorName,
                    onUpdate: onUpdate,
                    onDelete: {
                        onDelete(schedule)
                        selectedSchedule = nil
                    }
                )
            }
        }
        #if os(macOS)
        .frame(width: dynamicSize.width, height: dynamicSize.height)
        #endif
    }
    
    // MARK: - Plan Overview Section
    
    private var planOverviewSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(plan.vendor)
                        .font(Typography.title1)
                        .foregroundColor(SemanticColors.textPrimary)

                    Text(plan.planTypeDisplay)
                        .font(Typography.subheading)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                
                Spacer()
                
                // Status Badge
                HStack(spacing: Spacing.xs) {
                    Image(systemName: plan.statusIcon)
                        .foregroundColor(plan.planStatus.color)
                    
                    Text(plan.planStatus.displayName)
                        .font(Typography.bodyRegular)
                        .foregroundColor(plan.planStatus.color)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(plan.planStatus.color.opacity(0.1))
                .cornerRadius(CornerRadius.md)
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(plan.progressText)
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textPrimary)

                    Spacer()

                    Text("\(Int(plan.percentPaid))% paid")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                
                ProgressView(value: plan.percentPaid, total: 100)
                    .tint(plan.planStatus.color)
                    .frame(height: 8)
            }
            
            // Next Payment or Status Alert
            if plan.isOverdue {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(SemanticColors.statusWarning)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(plan.overdueCount) payment\(plan.overdueCount == 1 ? "" : "s") overdue")
                            .font(Typography.bodyRegular)
                            .foregroundColor(SemanticColors.statusWarning)

                        if plan.overdueAmount > 0 {
                            Text(plan.overdueAmount, format: .currency(code: "USD"))
                                .font(Typography.caption)
                                .foregroundColor(SemanticColors.statusWarning)
                        }
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SemanticColors.statusWarning.opacity(Opacity.subtle))
                .cornerRadius(CornerRadius.md)
            } else if let nextDate = plan.nextPaymentDate, let nextAmount = plan.nextPaymentAmount {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "calendar")
                        .foregroundColor(SemanticColors.statusPending)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next Payment")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)

                        HStack(spacing: Spacing.xs) {
                            Text(nextAmount, format: .currency(code: "USD"))
                                .font(Typography.bodyRegular)
                                .fontWeight(.semibold)
                                .foregroundColor(SemanticColors.textPrimary)

                            Text("on \(nextDate, format: .dateTime.month().day().year())")
                                .font(Typography.bodyRegular)
                                .foregroundColor(SemanticColors.textPrimary)
                        }

                        if let daysUntil = plan.daysUntilNextPayment {
                            Text("(\(daysUntil) day\(daysUntil == 1 ? "" : "s") from now)")
                                .font(Typography.caption)
                                .foregroundColor(SemanticColors.textSecondary)
                        }
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SemanticColors.statusPending.opacity(Opacity.subtle))
                .cornerRadius(CornerRadius.md)
            } else if plan.planStatus == .completed {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(SemanticColors.statusSuccess)

                    Text("All payments completed")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.statusSuccess)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SemanticColors.statusSuccess.opacity(Opacity.subtle))
                .cornerRadius(CornerRadius.md)
            }
        }
    }
    
    // MARK: - Financial Summary Section
    
    private var financialSummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Financial Summary")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)
            
            HStack(spacing: Spacing.lg) {
                financialCard(
                    title: "Total Amount",
                    amount: plan.totalAmount,
                    color: SemanticColors.textPrimary,
                    icon: "dollarsign.circle"
                )

                financialCard(
                    title: "Amount Paid",
                    amount: plan.amountPaid,
                    color: SemanticColors.statusSuccess,
                    icon: "checkmark.circle.fill"
                )

                financialCard(
                    title: "Remaining",
                    amount: plan.amountRemaining,
                    color: SemanticColors.statusPending,
                    icon: "clock.fill"
                )
            }
            
            if plan.hasDeposit && plan.depositAmount > 0 {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "banknote")
                        .foregroundColor(SemanticColors.statusPending)

                    Text("Deposit: \(plan.depositAmount, format: .currency(code: "USD"))")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textPrimary)

                    if let depositDate = plan.depositDate {
                        Text("• \(depositDate, format: .dateTime.month().day().year())")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
                .padding(Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SemanticColors.statusPending.opacity(Opacity.verySubtle))
                .cornerRadius(CornerRadius.sm)
            }
        }
    }
    
    private func financialCard(title: String, amount: Double, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Text(amount, format: .currency(code: "USD"))
                .font(Typography.heading)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background({
#if os(macOS)
            Color(NSColor.controlBackgroundColor)
#else
            Color(UIColor.systemBackground)
#endif
        }())
        .cornerRadius(CornerRadius.md)
    }
    
    // MARK: - Payment Schedule Section
    
    private var paymentScheduleSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Payment Schedule")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                Text("\(planPayments.count) payment\(planPayments.count == 1 ? "" : "s")")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            if planPayments.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(SemanticColors.textSecondary)

                    Text("No payments found for this plan")
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xl)
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(planPayments) { schedule in
                        PaymentScheduleDetailRow(
                            schedule: schedule,
                            onEdit: {
                                selectedSchedule = schedule
                            },
                            onTogglePaid: {
                                var updatedSchedule = schedule
                                updatedSchedule.paid.toggle()
                                updatedSchedule.updatedAt = Date()
                                onUpdate(updatedSchedule)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Plan Details Section
    
    private var planDetailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Plan Details")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                detailRow(label: "Payment Type", value: plan.paymentType.capitalized)
                detailRow(label: "Plan Type", value: plan.planTypeDisplay)
                
                if let vendorType = plan.vendorType {
                    detailRow(label: "Vendor Type", value: vendorType)
                }
                
                detailRow(
                    label: "First Payment",
                    value: plan.firstPaymentDate.formatted(.dateTime.month().day().year())
                )
                
                detailRow(
                    label: "Last Payment",
                    value: plan.lastPaymentDate.formatted(.dateTime.month().day().year())
                )
                
                if plan.hasRetainer {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(SemanticColors.primaryAction)
                            .font(.caption)

                        Text("Includes retainer payment")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.primaryAction)
                    }
                }
                
                if let notes = plan.combinedNotes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Notes")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)

                        Text(notes)
                            .font(Typography.bodyRegular)
                            .foregroundColor(SemanticColors.textPrimary)
                            .padding(Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background({
#if os(macOS)
                                Color(NSColor.controlBackgroundColor)
#else
                                Color(UIColor.systemBackground)
#endif
                            }())
                            .cornerRadius(CornerRadius.sm)
                    }
                }
                
                detailRow(
                    label: "Created",
                    value: plan.planCreatedAt.formatted(.dateTime.month().day().year())
                )
                
                if let updatedAt = plan.planUpdatedAt {
                    detailRow(
                        label: "Last Updated",
                        value: updatedAt.formatted(.dateTime.month().day().year())
                    )
                }
            }
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
                .frame(width: 140, alignment: .leading)

            Text(value)
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Payment Schedule Detail Row

private struct PaymentScheduleDetailRow: View {
    let schedule: PaymentSchedule
    let onEdit: () -> Void
    let onTogglePaid: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status indicator
            Button(action: onTogglePaid) {
                Image(systemName: schedule.paid ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(schedule.paid ? SemanticColors.statusSuccess : SemanticColors.textTertiary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("Mark as \(schedule.paid ? "unpaid" : "paid")")
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Text(schedule.paymentDate, format: .dateTime.month().day().year())
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textPrimary)

                    if schedule.isDeposit {
                        Text("• Deposit")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.statusPending)
                    } else if schedule.isRetainer {
                        Text("• Retainer")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.primaryAction)
                    }

                    if let order = schedule.paymentOrder {
                        Text("• Payment #\(order)")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
                
                if let notes = schedule.notes, !notes.isEmpty {
                    Text(notes)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Text(schedule.paymentAmount, format: .currency(code: "USD"))
                .font(Typography.heading)
                .fontWeight(.semibold)
                .foregroundColor(schedule.paid ? SemanticColors.statusSuccess : SemanticColors.textPrimary)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(SemanticColors.statusPending)
                    .font(.body)
            }
            .buttonStyle(.plain)
            .help("Edit payment")
        }
        .padding(Spacing.md)
        .background({
            if schedule.paid {
                SemanticColors.statusSuccess.opacity(Opacity.verySubtle)
            } else {
                SemanticColors.backgroundSecondary
            }
        }())
        .cornerRadius(CornerRadius.md)
    }
}

// MARK: - Preview

#if DEBUG
struct PaymentPlanDetailModal_Previews: PreviewProvider {
    static var previews: some View {
        PaymentPlanDetailModal(
            plan: PaymentPlanSummary.makeTest(),
            paymentSchedules: [],
            onUpdate: { _ in },
            onDelete: { _ in },
            getVendorName: { _ in "Test Vendor" }
        )
    }
}
#endif
