//
//  PaymentScheduleRowView.swift
//  I Do Blueprint
//
//  Individual payment schedule row with quick actions
//

import SwiftUI

struct PaymentScheduleRowView: View {
    let windowSize: WindowSize
    let payment: PaymentSchedule
    let expense: Expense?
    let onUpdate: (PaymentSchedule) -> Void
    let onDelete: (PaymentSchedule) -> Void
    let getVendorName: (Int64?) -> String?

    @State private var showingEditModal = false

    var body: some View {
        Button(action: {
            showingEditModal = true
        }) {
            if windowSize == .compact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingEditModal) {
            PaymentEditModal(
                payment: payment,
                expense: expense,
                getVendorName: getVendorName,
                onUpdate: onUpdate,
                onDelete: {
                    onDelete(payment)
                })
        }
    }
    
    // MARK: - Compact Layout
    
    private var compactLayout: some View {
        HStack(spacing: Spacing.sm) {
            // Status indicator
            Circle()
                .fill(payment.paid ? AppColors.Budget.income : AppColors.Budget.pending)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Vendor/Expense name + Amount
                HStack(alignment: .top) {
                    Text(vendorName)
                        .font(Typography.bodyRegular)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer(minLength: Spacing.sm)
                    
                    Text(formattedAmount)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(payment.paid ? AppColors.Budget.income : AppColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                // Date + Status badge
                HStack(spacing: Spacing.xs) {
                    Text(formatDateInUserTimezone(payment.paymentDate))
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    statusBadge
                }
                
                // Notes (if present)
                if let notes = payment.notes, !notes.isEmpty {
                    Text(notes)
                        .font(Typography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            // Action buttons (icon-only)
            VStack(spacing: Spacing.xs) {
                togglePaidButton
                    .help(payment.paid ? "Mark as unpaid" : "Mark as paid")
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.vertical, Spacing.sm)
        .contentShape(Rectangle())
    }
    
    // MARK: - Regular Layout
    
    private var regularLayout: some View {
        HStack(spacing: Spacing.md) {
            // Status indicator
            Circle()
                .fill(payment.paid ? AppColors.Budget.income : AppColors.Budget.pending)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(vendorName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(formattedAmount)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(payment.paid ? AppColors.Budget.income : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                if let notes = payment.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("Due: \(formatDateInUserTimezone(payment.paymentDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    statusBadge
                }
            }
            
            // Quick action buttons
            HStack(spacing: Spacing.sm) {
                togglePaidButton
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }
    
    // MARK: - Shared Components
    
    private var togglePaidButton: some View {
        Button(action: {
            var updatedPayment = payment
            updatedPayment.paid.toggle()
            updatedPayment.updatedAt = Date()
            onUpdate(updatedPayment)
        }) {
            Image(systemName: payment.paid ? "checkmark.square.fill" : "square")
                .foregroundColor(payment.paid ? AppColors.Budget.income : .secondary)
                .font(windowSize == .compact ? .body : .title2)
        }
        .buttonStyle(.plain)
    }
    
    private var statusBadge: some View {
        Text(payment.paid ? "Paid" : "Pending")
            .font(.caption)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(payment.paid ? AppColors.Budget.income.opacity(0.2) : AppColors.Budget.pending.opacity(0.2))
            .foregroundColor(payment.paid ? AppColors.Budget.income : AppColors.Budget.pending)
            .clipShape(Capsule())
    }
    
    // MARK: - Computed Properties
    
    private var vendorName: String {
        if let vendorName = getVendorName(payment.vendorId), !vendorName.isEmpty {
            return vendorName
        }
        return expense?.expenseName ?? "Unknown Expense"
    }
    
    private var formattedAmount: String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: payment.paymentAmount)) ?? "$0"
    }
}

// MARK: - Helper Functions

private func formatDateInUserTimezone(_ date: Date) -> String {
    // Use user's timezone for date formatting
    let userTimezone = DateFormatting.userTimeZone(from: AppStores.shared.settings.settings)
    return DateFormatting.formatDateMedium(date, timezone: userTimezone)
}
