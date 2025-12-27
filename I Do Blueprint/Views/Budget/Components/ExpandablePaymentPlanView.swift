//
//  ExpandablePaymentPlanView.swift
//  I Do Blueprint
//
//  Expandable card view for payment plans showing summary and individual payments
//

import SwiftUI

/// Expandable view that shows payment plan summary and individual payments when expanded
struct ExpandablePaymentPlanView: View {
    let plan: PaymentPlanSummary
    @ObservedObject var paymentStore: PaymentScheduleStore
    let isExpanded: Bool
    let onToggle: () -> Void
    
    private var planPayments: [PaymentSchedule] {
        paymentStore.paymentSchedules
            .filter { schedule in
                // Match by expense_id AND payment_plan_type
                // This ensures we only show payments that belong to this specific plan
                schedule.expenseId == plan.expenseId &&
                schedule.paymentPlanType == plan.paymentPlanType
            }
            .sorted { $0.paymentDate < $1.paymentDate }
    }
    
    /// Dynamic currency code based on user's locale
    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Payment Plan Summary (always visible)
            Button(action: onToggle) {
                HStack(spacing: Spacing.sm) {
                    // Expansion chevron
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(AppColors.textSecondary)
                        .font(.caption)
                        .frame(width: 20)
                        .accessibilityHidden(true)
                    
                    // Plan summary content
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        // Header with vendor name and status icon
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(plan.vendor)
                                    .font(Typography.heading)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text(plan.planTypeDisplay)
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: plan.statusIcon)
                                .foregroundColor(plan.planStatus.color)
                                .font(.title2)
                                .accessibilityLabel("\(plan.planStatus.displayName) status")
                        }
                        
                        // Progress Bar
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack {
                                Text(plan.progressText)
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Spacer()
                                
                                Text("\(Int(plan.percentPaid))% paid")
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            
                            ProgressView(value: plan.percentPaid, total: 100)
                                .tint(plan.planStatus.color)
                                .accessibilityLabel("Payment progress: \(Int(plan.percentPaid)) percent complete")
                        }
                        
                        // Financial Summary
                        HStack(spacing: Spacing.lg) {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Total")
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Text(plan.totalAmount, format: .currency(code: currencyCode))
                                    .font(Typography.subheading)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Paid")
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Text(plan.amountPaid, format: .currency(code: currencyCode))
                                    .font(Typography.subheading)
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Remaining")
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Text(plan.amountRemaining, format: .currency(code: currencyCode))
                                    .font(Typography.subheading)
                                    .foregroundColor(.orange)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Total: \(plan.totalAmount, format: .currency(code: currencyCode)), Paid: \(plan.amountPaid, format: .currency(code: currencyCode)), Remaining: \(plan.amountRemaining, format: .currency(code: currencyCode))")
                        
                        // Next Payment or Overdue Status
                        if plan.isOverdue {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                
                                Text("\(plan.overdueCount) payment\(plan.overdueCount == 1 ? "" : "s") overdue")
                                    .font(Typography.caption)
                                    .foregroundColor(.red)
                                
                                if plan.overdueAmount > 0 {
                                    Text("(\(plan.overdueAmount, format: .currency(code: currencyCode)))")
                                        .font(Typography.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.vertical, Spacing.xs)
                            .padding(.horizontal, Spacing.sm)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Overdue: \(plan.overdueCount) payment\(plan.overdueCount == 1 ? "" : "s"), \(plan.overdueAmount, format: .currency(code: currencyCode))")
                        } else if let nextDate = plan.nextPaymentDate, let nextAmount = plan.nextPaymentAmount {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                
                                Text("Next: \(nextAmount, format: .currency(code: currencyCode)) on \(nextDate, format: .dateTime.month().day())")
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                if let daysUntil = plan.daysUntilNextPayment {
                                    Text("(\(daysUntil) day\(daysUntil == 1 ? "" : "s"))")
                                        .font(Typography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            .padding(.vertical, Spacing.xs)
                            .padding(.horizontal, Spacing.sm)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Next payment: \(nextAmount, format: .currency(code: currencyCode)) on \(nextDate, format: .dateTime.month().day().year())")
                        } else if plan.planStatus == .completed {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                Text("All payments completed")
                                    .font(Typography.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, Spacing.xs)
                            .padding(.horizontal, Spacing.sm)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(CornerRadius.sm)
                            .accessibilityLabel("All payments completed")
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Payment plan for \(plan.vendor)")
            .accessibilityHint(isExpanded ? "Tap to collapse and hide individual payments" : "Tap to expand and view individual payments")
            
            // Individual Payments (shown when expanded)
            if isExpanded {
                Divider()
                    .padding(.horizontal, Spacing.md)
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Section header
                    HStack {
                        Text("Individual Payments")
                            .font(Typography.subheading)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Spacer()
                        
                        Text("\(planPayments.count) payment\(planPayments.count == 1 ? "" : "s")")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)
                    
                    // Payment list
                    if planPayments.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: Spacing.sm) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.title2)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                Text("No individual payments found")
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.vertical, Spacing.lg)
                            Spacer()
                        }
                        .accessibilityLabel("No individual payments found for this plan")
                    } else {
                        ForEach(planPayments) { schedule in
                            IndividualPaymentRow(schedule: schedule, paymentStore: paymentStore)
                                .padding(.horizontal, Spacing.md)
                        }
                        .padding(.bottom, Spacing.sm)
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Individual Payment Row

private struct IndividualPaymentRow: View {
    let schedule: PaymentSchedule
    @ObservedObject var paymentStore: PaymentScheduleStore
    
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    private let logger = AppLogger.ui
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status indicator
            Image(systemName: schedule.paid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(schedule.paid ? .green : .gray)
                .font(.body)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(schedule.paymentDate, format: .dateTime.month().day().year())
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if schedule.isDeposit {
                        Text("• Deposit")
                            .font(Typography.caption)
                            .foregroundColor(.blue)
                    } else if schedule.isRetainer {
                        Text("• Retainer")
                            .font(Typography.caption)
                            .foregroundColor(.purple)
                    }
                }
                
                if let notes = schedule.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(schedule.paymentAmount, format: .currency(code: "USD"))
                .font(Typography.bodyRegular)
                .fontWeight(.medium)
                .foregroundColor(schedule.paid ? .green : AppColors.textPrimary)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(schedule.paid ? Color.green.opacity(0.05) : Color.clear)
        .cornerRadius(CornerRadius.sm)
        .onTapGesture {
            Task { @MainActor in
                do {
                    try await paymentStore.togglePaidStatus(schedule)
                } catch {
                    logger.error("Failed to toggle payment status", error: error)
                    
                    // Update state on main actor
                    errorMessage = "Failed to update payment status. Please try again."
                    showAlert = true
                }
            }
        }
        .alert("Payment Update Failed", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                showAlert = false
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .accessibleActionButton(
            label: "Payment of \(schedule.paymentAmount.formatted(.currency(code: "USD"))) on \(schedule.paymentDate.formatted(.dateTime.month().day().year()))",
            hint: "Tap to mark as \(schedule.paid ? "unpaid" : "paid")"
        )
    }
}

// MARK: - Preview

#if DEBUG
struct ExpandablePaymentPlanView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            // Collapsed state
            ExpandablePaymentPlanView(
                plan: PaymentPlanSummary.makeTest(),
                paymentStore: PaymentScheduleStore(),
                isExpanded: false,
                onToggle: {}
            )
            
            // Expanded state
            ExpandablePaymentPlanView(
                plan: PaymentPlanSummary.makeTest(),
                paymentStore: PaymentScheduleStore(),
                isExpanded: true,
                onToggle: {}
            )
        }
        .padding()
        .frame(width: 600)
    }
}
#endif
