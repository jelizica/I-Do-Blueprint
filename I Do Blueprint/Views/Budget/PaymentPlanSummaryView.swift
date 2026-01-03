//
//  PaymentPlanSummaryView.swift
//  I Do Blueprint
//
//  Card view for displaying payment plan summaries
//  Shows aggregated plan-level information with progress tracking
//

import SwiftUI

/// Card view displaying a payment plan summary
struct PaymentPlanSummaryView: View {
    let plan: PaymentPlanSummary
    let onTap: () -> Void
    
    var body: some View {
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
                    .accessibilityLabel("Payment progress: \(Int(plan.percentPaid)) percent complete")
            }
            
            // Financial Summary
            HStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Total")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    
                    Text(plan.totalAmount, format: .currency(code: "USD"))
                        .font(Typography.subheading)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Paid")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    
                    Text(plan.amountPaid, format: .currency(code: "USD"))
                        .font(Typography.subheading)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Remaining")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                    
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
                        .foregroundColor(SemanticColors.textPrimary)
                    
                    if let daysUntil = plan.daysUntilNextPayment {
                        Text("(\(daysUntil) day\(daysUntil == 1 ? "" : "s"))")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
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
        .padding(Spacing.md)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onTapGesture(perform: onTap)
        .accessibleActionButton(
            label: "Payment plan for \(plan.vendor)",
            hint: "Tap to view individual payments for this plan"
        )
    }
}

// MARK: - Preview

#if DEBUG
struct PaymentPlanSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.lg) {
            // In Progress Plan
            PaymentPlanSummaryView(
                plan: .makeTest(
                    vendor: "Truly Trusted Events",
                    vendorType: "Venue",
                    paymentType: "cyclical",
                    paymentPlanType: "cyclical-recurring",
                    planTypeDisplay: "Cyclical Payments",
                    totalPayments: 17,
                    totalAmount: 6250.0,
                    amountPaid: 4000.0,
                    amountRemaining: 2250.0,
                    percentPaid: 64.0,
                    actualPaymentCount: 17,
                    paymentsCompleted: 11,
                    paymentsRemaining: 6,
                    planStatus: .inProgress,
                    nextPaymentDate: Date().addingTimeInterval(15 * 24 * 60 * 60),
                    nextPaymentAmount: 250.0,
                    daysUntilNextPayment: 15
                ),
                onTap: {}
            )
            
            // Overdue Plan
            PaymentPlanSummaryView(
                plan: .makeTest(
                    vendor: "Marissa Solini Photography",
                    vendorType: "Photography",
                    paymentType: "interval",
                    paymentPlanType: "interval-recurring",
                    planTypeDisplay: "Custom Interval",
                    totalPayments: 4,
                    totalAmount: 6300.0,
                    amountPaid: 3150.0,
                    amountRemaining: 3150.0,
                    percentPaid: 50.0,
                    actualPaymentCount: 4,
                    paymentsCompleted: 2,
                    paymentsRemaining: 2,
                    planStatus: .overdue,
                    nextPaymentDate: Date().addingTimeInterval(-5 * 24 * 60 * 60),
                    nextPaymentAmount: 1575.0,
                    daysUntilNextPayment: -5,
                    overdueCount: 1,
                    overdueAmount: 1575.0
                ),
                onTap: {}
            )
            
            // Completed Plan
            PaymentPlanSummaryView(
                plan: .makeTest(
                    vendor: "Menashe & Sons",
                    vendorType: "Jewelry",
                    paymentType: "monthly",
                    paymentPlanType: "simple-recurring",
                    planTypeDisplay: "Monthly Payments",
                    totalPayments: 9,
                    totalAmount: 4500.0,
                    amountPaid: 4500.0,
                    amountRemaining: 0.0,
                    percentPaid: 100.0,
                    actualPaymentCount: 9,
                    paymentsCompleted: 9,
                    paymentsRemaining: 0,
                    allPaid: true,
                    planStatus: .completed,
                    nextPaymentDate: nil,
                    nextPaymentAmount: nil,
                    daysUntilNextPayment: nil
                ),
                onTap: {}
            )
        }
        .padding()
        .frame(width: 500)
    }
}
#endif
