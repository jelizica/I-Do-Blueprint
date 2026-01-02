//
//  HierarchicalPaymentGroupView.swift
//  I Do Blueprint
//
//  Hierarchical view for payment plan groups (vendor or expense grouping)
//

import SwiftUI

/// Displays a hierarchical group of payment plans (e.g., all plans for a vendor or expense)
struct HierarchicalPaymentGroupView: View {
    let windowSize: WindowSize
    let group: PaymentPlanGroup
    let paymentSchedules: [PaymentSchedule]
    let onTogglePaidStatus: (PaymentSchedule) -> Void
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?
    
    @State private var isGroupExpanded: Bool = false
    @State private var expandedPlanIds: Set<UUID> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Group Header (Vendor or Expense name)
            groupHeaderButton
            
            // Plans within this group (shown when expanded)
            if isGroupExpanded {
                Divider()
                    .padding(.horizontal, Spacing.md)
                
                VStack(spacing: Spacing.md) {
                    ForEach(group.plans) { plan in
                        ExpandablePaymentPlanCardView(
                            windowSize: windowSize,
                            plan: plan,
                            paymentSchedules: paymentSchedules,
                            isExpanded: expandedPlanIds.contains(plan.id),
                            onToggle: {
                                togglePlanExpansion(planId: plan.id)
                            },
                            onTogglePaidStatus: onTogglePaidStatus,
                            onUpdate: onUpdate,
                            onDelete: onDelete,
                            getVendorName: getVendorName
                        )
                        .padding(.horizontal, Spacing.md)
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var groupHeaderButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isGroupExpanded.toggle()
            }
        }) {
            HStack(spacing: Spacing.md) {
                // Expansion chevron
                Image(systemName: isGroupExpanded ? "chevron.down" : "chevron.right")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.title3)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                
                // Group content
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Header with group name and status
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(group.groupName)
                                .font(Typography.title2)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("\(group.plans.count) payment plan\(group.plans.count == 1 ? "" : "s")")
                                .font(Typography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        // Status indicator
                        if group.allCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        } else if group.hasOverdue {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                        } else {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                        }
                    }
                    
                    // Progress Bar
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text("\(group.paymentsCompleted) of \(group.totalPayments) payments")
                                .font(Typography.caption)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                            
                            Text("\(Int(group.percentPaid))% paid")
                                .font(Typography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        ProgressView(value: group.percentPaid, total: 100)
                            .tint(group.allCompleted ? .green : (group.hasOverdue ? .red : .blue))
                            .accessibilityLabel("Payment progress: \(Int(group.percentPaid)) percent complete")
                    }
                    
                    // Financial Summary
                    HStack(spacing: Spacing.lg) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Total")
                                .font(Typography.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text(group.totalAmount, format: .currency(code: "USD"))
                                .font(Typography.heading)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Paid")
                                .font(Typography.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text(group.amountPaid, format: .currency(code: "USD"))
                                .font(Typography.heading)
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Remaining")
                                .font(Typography.caption)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text(group.amountRemaining, format: .currency(code: "USD"))
                                .font(Typography.heading)
                                .foregroundColor(.orange)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Total: \(group.totalAmount, format: .currency(code: "USD")), Paid: \(group.amountPaid, format: .currency(code: "USD")), Remaining: \(group.amountRemaining, format: .currency(code: "USD"))")
                    
                    // Next Payment or Status
                    if group.hasOverdue {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            
                            Text("\(group.overdueCount) payment\(group.overdueCount == 1 ? "" : "s") overdue")
                                .font(Typography.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, Spacing.xs)
                        .padding(.horizontal, Spacing.sm)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                    } else if let nextDate = group.nextPaymentDate {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            
                            Text("Next payment: \(nextDate, format: .dateTime.month().day())")
                                .font(Typography.caption)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(.vertical, Spacing.xs)
                        .padding(.horizontal, Spacing.sm)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                    } else if group.allCompleted {
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
                    }
                }
            }
            .padding(Spacing.md)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Payment group for \(group.groupName)")
        .accessibilityHint(isGroupExpanded ? "Tap to collapse and hide payment plans" : "Tap to expand and view payment plans")
    }
    
    private func togglePlanExpansion(planId: UUID) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedPlanIds.contains(planId) {
                expandedPlanIds.remove(planId)
            } else {
                expandedPlanIds.insert(planId)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct HierarchicalPaymentGroupView_Previews: PreviewProvider {
    static var previews: some View {
        let testGroup = PaymentPlanGroup(
            id: UUID(),
            groupName: "Coho Restaurant",
            groupType: .vendor(vendorId: 123),
            plans: [
                PaymentPlanSummary.makeTest(),
                PaymentPlanSummary.makeTest()
            ]
        )
        
        VStack(spacing: Spacing.lg) {
            HierarchicalPaymentGroupView(
                windowSize: .regular,
                group: testGroup,
                paymentSchedules: [],
                onTogglePaidStatus: { _ in },
                onUpdate: { _ in },
                onDelete: { _ in },
                getVendorName: { _ in "Test Vendor" }
            )
        }
        .padding()
        .frame(width: 700)
    }
}
#endif
