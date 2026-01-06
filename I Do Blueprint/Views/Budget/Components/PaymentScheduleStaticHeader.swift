//
//  PaymentScheduleStaticHeader.swift
//  I Do Blueprint
//
//  Static header bar for Payment Schedule with search and next payment context
//  Follows Expense Tracker's contextual dashboard approach
//

import SwiftUI

struct PaymentScheduleStaticHeader: View {
    let windowSize: WindowSize
    @Binding var searchQuery: String
    @Binding var viewMode: PaymentViewMode
    let nextPayment: PaymentSchedule?
    let overdueCount: Int
    let onOverdueClick: () -> Void
    let onNextPaymentClick: () -> Void
    let userTimezone: TimeZone
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            if windowSize == .compact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .padding(.horizontal, windowSize == .compact ? Spacing.md : Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Compact Layout
    
    private var compactLayout: some View {
        VStack(spacing: Spacing.sm) {
            // Row 1: Search bar (full-width)
            searchField
            
            // Row 2: Next payment + Overdue badge
            HStack {
                nextPaymentInfo
                Spacer()
                if overdueCount > 0 {
                    overdueBadge
                }
            }
        }
    }
    
    // MARK: - Regular Layout
    
    private var regularLayout: some View {
        HStack(spacing: Spacing.lg) {
            // Search bar (left)
            searchField
                .frame(maxWidth: 300)
            
            Spacer()
            
            // Next payment (center)
            nextPaymentInfo
            
            // Overdue badge (right)
            if overdueCount > 0 {
                overdueBadge
            }
        }
    }
    
    // MARK: - Search Field
    
    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(SemanticColors.textSecondary)
                .font(.system(size: 14))
            
            TextField("Search payments...", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular)
            
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(SemanticColors.textSecondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .help("Clear search")
            }
        }
        .padding(Spacing.sm)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Next Payment Info
    
    private var nextPaymentInfo: some View {
        Button(action: onNextPaymentClick) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(SemanticColors.primaryAction)
                    .font(.system(size: 14))
                
                if let payment = nextPayment {
                    Text("Next: \(payment.vendor)")
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.textPrimary)
                        .lineLimit(1)
                    
                    Text("•")
                        .foregroundColor(SemanticColors.textSecondary)
                        .font(Typography.bodySmall)
                    
                    Text(formatCurrency(payment.paymentAmount))
                        .font(Typography.bodySmall.weight(.semibold))
                        .foregroundColor(SemanticColors.textPrimary)
                        .lineLimit(1)
                    
                    Text("in \(daysUntil(payment.paymentDate)) days")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)
                } else {
                    Text("No upcoming payments")
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .help(nextPayment != nil ? "Click to scroll to this payment" : "")
    }
    
    // MARK: - Overdue Badge
    
    private var overdueBadge: some View {
        Button(action: onOverdueClick) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                Text("\(overdueCount)")
                    .font(.caption2.weight(.bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .help("Click to filter overdue payments")
    }
    
    // MARK: - Helper Functions
    
    private func formatCurrency(_ amount: Double) -> String {
        NumberFormatter.currencyShort.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    private func daysUntil(_ date: Date) -> Int {
        DateFormatting.daysBetween(from: Date(), to: date, in: userTimezone)
    }
}
