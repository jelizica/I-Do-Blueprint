//
//  ExpandablePaymentPlanCardView.swift
//  I Do Blueprint
//
//  Expandable card view for payment plans in PaymentScheduleView
//

import SwiftUI

/// Expandable view that shows payment plan summary and individual payments when expanded
struct ExpandablePaymentPlanCardView: View {
    let windowSize: WindowSize
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
                            .foregroundColor(SemanticColors.textSecondary)
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
                                        .foregroundColor(SemanticColors.textPrimary)

                                    Text(plan.planTypeDisplay)
                                        .font(Typography.caption)
                                        .foregroundColor(SemanticColors.textSecondary)
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
                                        .foregroundColor(SemanticColors.textPrimary)

                                    Spacer()

                                    Text("\(Int(plan.percentPaid))% paid")
                                        .font(Typography.caption)
                                        .foregroundColor(SemanticColors.textSecondary)
                                }
                                
                                ProgressView(value: plan.percentPaid, total: 100)
                                    .tint(plan.planStatus.color)
                                    .frame(maxWidth: windowSize == .compact ? .infinity : 300)
                                    .accessibilityLabel("Payment progress: \(Int(plan.percentPaid)) percent complete")
                            }
                            
                            // Financial Summary
                            financialSummary
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Total: \(plan.totalAmount, format: .currency(code: "USD")), Paid: \(plan.amountPaid, format: .currency(code: "USD")), Remaining: \(plan.amountRemaining, format: .currency(code: "USD"))")
                            
                            // Next Payment or Overdue Status
                            if plan.isOverdue {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(SemanticColors.statusWarning)

                                    Text("\(plan.overdueCount) payment\(plan.overdueCount == 1 ? "" : "s") overdue")
                                        .font(Typography.caption)
                                        .foregroundColor(SemanticColors.statusWarning)

                                    if plan.overdueAmount > 0 {
                                        Text("(\(plan.overdueAmount, format: .currency(code: "USD")))")
                                            .font(Typography.caption)
                                            .foregroundColor(SemanticColors.statusWarning)
                                    }
                                }
                                .padding(.vertical, Spacing.xs)
                                .padding(.horizontal, Spacing.sm)
                                .background(SemanticColors.statusWarning.opacity(Opacity.subtle))
                                .cornerRadius(CornerRadius.sm)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Overdue: \(plan.overdueCount) payment\(plan.overdueCount == 1 ? "" : "s"), \(plan.overdueAmount, format: .currency(code: "USD"))")
                            } else if let nextDate = plan.nextPaymentDate, let nextAmount = plan.nextPaymentAmount {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(SemanticColors.statusPending)

                                    Text("Next: \(nextAmount, format: .currency(code: "USD")) on \(nextDate, format: .dateTime.month().day())")
                                        .font(Typography.caption)
                                        .foregroundColor(SemanticColors.textPrimary)

                                    if let daysUntil = plan.daysUntilNextPayment {
                                        Text("(\(daysUntil) day\(daysUntil == 1 ? "" : "s"))")
                                            .font(Typography.caption)
                                            .foregroundColor(SemanticColors.textSecondary)
                                    }
                                }
                                .padding(.vertical, Spacing.xs)
                                .padding(.horizontal, Spacing.sm)
                                .background(SemanticColors.statusPending.opacity(Opacity.subtle))
                                .cornerRadius(CornerRadius.sm)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Next payment: \(nextAmount, format: .currency(code: "USD")) on \(nextDate, format: .dateTime.month().day().year())")
                            } else if plan.planStatus == .completed {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(SemanticColors.statusSuccess)

                                    Text("All payments completed")
                                        .font(Typography.caption)
                                        .foregroundColor(SemanticColors.statusSuccess)
                                }
                                .padding(.vertical, Spacing.xs)
                                .padding(.horizontal, Spacing.sm)
                                .background(SemanticColors.statusSuccess.opacity(Opacity.subtle))
                                .cornerRadius(CornerRadius.sm)
                                .accessibilityLabel("All payments completed")
                            }
                        }
                    }
                    .padding(windowSize == .compact ? Spacing.sm : Spacing.md)
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
                        .foregroundColor(SemanticColors.statusPending)
                        .padding(.vertical, Spacing.xs)
                        .padding(.horizontal, Spacing.sm)
                        .background(SemanticColors.statusPending.opacity(Opacity.subtle))
                        .cornerRadius(CornerRadius.sm)
                    }
                    .buttonStyle(.plain)
                    .help("View plan details and edit individual payments")
                    .accessibilityLabel("View or edit payment plan details")
                }
                .padding(.horizontal, windowSize == .compact ? Spacing.sm : Spacing.md)
                .padding(.bottom, windowSize == .compact ? Spacing.sm : Spacing.md)
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
                            .foregroundColor(SemanticColors.textPrimary)

                        Spacer()

                        Text("\(planPayments.count) payment\(planPayments.count == 1 ? "" : "s")")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
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
                                    .foregroundColor(SemanticColors.textSecondary)

                                Text("No individual payments found")
                                    .font(Typography.caption)
                                    .foregroundColor(SemanticColors.textSecondary)
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
    
    // MARK: - Financial Summary
    
    @ViewBuilder
    private var financialSummary: some View {
        if windowSize == .compact {
            // Compact: Vertical stack
            VStack(alignment: .leading, spacing: Spacing.sm) {
                financialMetric(label: "Total", value: plan.totalAmount, color: SemanticColors.textPrimary)
                financialMetric(label: "Paid", value: plan.amountPaid, color: SemanticColors.statusSuccess)
                financialMetric(label: "Remaining", value: plan.amountRemaining, color: SemanticColors.statusPending)
            }
        } else {
            // Regular/Large: Horizontal row
            HStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Total")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    Text(plan.totalAmount, format: .currency(code: "USD"))
                        .font(Typography.subheading)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Paid")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    Text(plan.amountPaid, format: .currency(code: "USD"))
                        .font(Typography.subheading)
                        .foregroundColor(SemanticColors.statusSuccess)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Remaining")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    Text(plan.amountRemaining, format: .currency(code: "USD"))
                        .font(Typography.subheading)
                        .foregroundColor(SemanticColors.statusPending)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }
    
    private func financialMetric(label: String, value: Double, color: Color) -> some View {
        HStack {
            Text(label)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)

            Spacer()

            Text(value, format: .currency(code: "USD"))
                .font(Typography.bodyRegular)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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
                        configuration.isPressed ? SemanticColors.primaryAction.opacity(Opacity.medium) : Color.clear,
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
                .foregroundColor(schedule.paid ? SemanticColors.statusSuccess : SemanticColors.textTertiary)
                .font(.body)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: Spacing.xs) {
                    Text(schedule.paymentDate, format: .dateTime.month().day().year())
                        .font(Typography.caption)
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
                }

                if let notes = schedule.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(schedule.paymentAmount, format: .currency(code: "USD"))
                .font(Typography.bodyRegular)
                .fontWeight(.medium)
                .foregroundColor(schedule.paid ? SemanticColors.statusSuccess : SemanticColors.textPrimary)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(schedule.paid ? SemanticColors.statusSuccess.opacity(Opacity.verySubtle) : Color.clear)
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
                windowSize: .regular,
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
                windowSize: .regular,
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
