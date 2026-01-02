//
//  PaymentSummaryHeaderViewV2.swift
//  I Do Blueprint
//
//  Responsive payment schedule summary header with adaptive grid
//  Follows pattern from Budget Overview and Expense Tracker
//

import SwiftUI

struct PaymentSummaryHeaderViewV2: View {
    let windowSize: WindowSize
    let totalUpcoming: Double
    let totalOverdue: Double
    let scheduleCount: Int
    
    private var columns: [GridItem] {
        if windowSize == .compact {
            // 1 column in compact - stack vertically
            return [GridItem(.flexible())]
        } else {
            // 3 columns in regular/large
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: windowSize == .compact ? Spacing.sm : Spacing.lg) {
            PaymentOverviewCardV2(
                windowSize: windowSize,
                title: "Upcoming Payments",
                value: NumberFormatter.currencyShort.string(from: NSNumber(value: totalUpcoming)) ?? "$0",
                subtitle: "Due soon",
                icon: "calendar",
                color: AppColors.Budget.pending
            )
            
            PaymentOverviewCardV2(
                windowSize: windowSize,
                title: "Overdue Payments",
                value: NumberFormatter.currencyShort.string(from: NSNumber(value: totalOverdue)) ?? "$0",
                subtitle: "Past due",
                icon: "exclamationmark.triangle.fill",
                color: AppColors.Budget.overBudget
            )
            
            PaymentOverviewCardV2(
                windowSize: windowSize,
                title: "Total Schedules",
                value: "\(scheduleCount)",
                subtitle: "Active schedules",
                icon: "list.number",
                color: AppColors.Budget.allocated
            )
        }
        .padding(windowSize == .compact ? Spacing.md : Spacing.lg)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Payment Overview Card V2

struct PaymentOverviewCardV2: View {
    let windowSize: WindowSize
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: windowSize == .compact ? Spacing.sm : Spacing.md) {
            HStack {
                // Icon with circle background
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 11))
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(windowSize == .compact ? Spacing.md : Spacing.xl)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
