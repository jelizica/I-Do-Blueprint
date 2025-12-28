//
//  ExpandablePaymentPlanCardView.swift
//  I Do Blueprint
//
//  Expandable card view for payment plans in PaymentScheduleView
//

import SwiftUI

/// Expandable view that shows payment plan summary and individual payments when expanded
struct ExpandablePaymentPlanCardView: View {
    let plan: PaymentPlanSummary
    let paymentSchedules: [PaymentSchedule]
    let isExpanded: Bool
    let onToggle: () -> Void
    let onTogglePaidStatus: (PaymentSchedule) -> Void
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?
    
    @State private var showingDetailModal = false
    
    private var planPayments: [PaymentSchedule] {
        paymentSchedules
            .filter { schedule in
                // CRITICAL: Always match by payment_plan_id first
                // This ensures each plan only shows its own payments, even in hierarchical grouping
                if let schedulePlanId = schedule.paymentPlanId,
                   schedulePlanId == plan.paymentPlanId {
                    return true
                }
                
                return false
            }
            .sorted { $0.paymentDate < $1.paymentDate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Payment Plan Summary (always visible)
            VStack(alignment: .leading, spacing: 0) {
                // Tappable summary area with visual feedback
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
                                    
                                    Text(plan.totalAmount, format: .currency(code: "USD"))
                                        .font(Typography.subheading)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppColors.textPrimary)
                                }
                                
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Paid")
                                        .font(Typography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    Text(plan.amountPaid, format: .currency(code: "USD"))
                                        .font(Typography.subheading)
                                        .foregroundColor(.green)
                                }
                                
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("Remaining")
                                        .font(Typography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                    
                                    Text(plan.amountRemaining, format: .currency(code: "USD"))
                                        .font(Typography.subheading)
                                        .foregroundColor(.orange)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Total: \(plan.totalAmount, format: .currency(code: "USD")), Paid: \(plan.amountPaid, format: .currency(code: "USD")), Remaining: \(plan.amountRemaining, format: .currency(code: "USD"))")
                            
                            // Next Payment or Overdue Status
                            if plan.isOverdue {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    
                                    Text("\(plan.overdueCount) payment\(plan.overdueCount == 1 ? "" : "s") overdue")
                                        .font(Typography.caption)
                                        .foregroundColor(.red)
                                    
                                    if plan.overdueAmount > 0 {
                                        Text("(\(plan.overdueAmount, format: .currency(code: "USD")))")
                                            .font(Typography.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, Spacing.xs)
                                .padding(.horizontal, Spacing.sm)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(CornerRadius.sm)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Overdue: \(plan.overdueCount) payment\(plan.overdueCount == 1 ? "" : "s"), \(plan.overdueAmount, format: .currency(code: "USD"))")
                            } else if let nextDate = plan.nextPaymentDate, let nextAmount = plan.nextPaymentAmount {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                    
                                    Text("Next: \(nextAmount, format: .currency(code: "USD")) on \(nextDate, format: .dateTime.month().day())")
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
                                .accessibilityLabel("Next payment: \(nextAmount, format: .currency(code: "USD")) on \(nextDate, format: .dateTime.month().day().year())")
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
                .buttonStyle(PaymentPlanSummaryButtonStyle())
                .accessibilityLabel("Payment plan for \(plan.vendor)")
                .accessibilityHint(isExpanded ? "Tap to collapse and hide individual payments" : "Tap to expand and view individual payments")
                
                // View/Edit Plan Button (sibling, not nested)
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingDetailModal = true
                    }) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.caption)
                            
                            Text("View/Edit Plan")
                                .font(Typography.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, Spacing.xs)
                        .padding(.horizontal, Spacing.sm)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                    .help("View plan details and edit individual payments")
                    .accessibilityLabel("View or edit payment plan details")
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.md)
            }
            
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
                            IndividualPaymentRowCard(
                                schedule: schedule,
                                onTogglePaidStatus: {
                                    var updatedSchedule = schedule
                                    updatedSchedule.paid.toggle()
                                    updatedSchedule.updatedAt = Date()
                                    onTogglePaidStatus(updatedSchedule)
                                }
                            )
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
        .sheet(isPresented: $showingDetailModal) {
            PaymentPlanDetailModal(
                plan: plan,
                paymentSchedules: paymentSchedules,
                onUpdate: onUpdate,
                onDelete: onDelete,
                getVendorName: getVendorName
            )
        }
    }
}

// MARK: - Custom Button Style for Summary

private struct PaymentPlanSummaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Color(NSColor.controlBackgroundColor)
                    .cornerRadius(CornerRadius.md)
            )
            .overlay(
                (configuration.isPressed ? Color.black.opacity(0.1) : Color.clear)
                    .cornerRadius(CornerRadius.md)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(
                        configuration.isPressed ? AppColors.primary.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
            .contentShape(Rectangle())
    }
}

// MARK: - Individual Payment Row

private struct IndividualPaymentRowCard: View {
    let schedule: PaymentSchedule
    let onTogglePaidStatus: () -> Void
    
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
            onTogglePaidStatus()
        }
        .accessibleActionButton(
            label: "Payment of $\(String(format: "%.2f", schedule.paymentAmount)) on \(schedule.paymentDate.formatted(.dateTime.month().day().year()))",
            hint: "Tap to mark as \(schedule.paid ? "unpaid" : "paid")"
        )
    }
}

// MARK: - Preview

#if DEBUG
struct ExpandablePaymentPlanCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            // Collapsed state
            ExpandablePaymentPlanCardView(
                plan: PaymentPlanSummary.makeTest(),
                paymentSchedules: [],
                isExpanded: false,
                onToggle: {},
                onTogglePaidStatus: { _ in },
                onUpdate: { _ in },
                onDelete: { _ in },
                getVendorName: { _ in "Test Vendor" }
            )
            
            // Expanded state
            ExpandablePaymentPlanCardView(
                plan: PaymentPlanSummary.makeTest(),
                paymentSchedules: [],
                isExpanded: true,
                onToggle: {},
                onTogglePaidStatus: { _ in },
                onUpdate: { _ in },
                onDelete: { _ in },
                getVendorName: { _ in "Test Vendor" }
            )
        }
        .padding()
        .frame(width: 600)
    }
}
#endif
