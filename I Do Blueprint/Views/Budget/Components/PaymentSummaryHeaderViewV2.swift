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
        } else if windowSize == .regular {
            // 2 columns in regular (space-dependent)
            return [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        } else {
            // 3 columns in large
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }
    
    var body: some View {
        Group {
            if windowSize == .compact {
                // Compact: Use adaptive grid like Budget Overview - fits as many cards as possible
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 140, maximum: 200), spacing: Spacing.sm)
                ], spacing: Spacing.sm) {
                    PaymentOverviewCompactCard(
                        title: "Upcoming",
                        value: totalUpcoming,
                        icon: "calendar",
                        color: AppColors.Budget.pending
                    )
                    
                    PaymentOverviewCompactCard(
                        title: "Overdue",
                        value: totalOverdue,
                        icon: "exclamationmark.triangle.fill",
                        color: AppColors.Budget.overBudget
                    )
                    
                    PaymentOverviewCompactCard(
                        title: "Schedules",
                        value: Double(scheduleCount),
                        icon: "list.number",
                        color: AppColors.Budget.allocated,
                        formatAsCurrency: false
                    )
                }
            } else {
                // Regular/Large: Use grid layout
                LazyVGrid(columns: columns, spacing: Spacing.lg) {
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
            }
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
        VStack(spacing: windowSize == .compact ? Spacing.xs : Spacing.sm) {
            HStack {
                // Icon with circle background (reduced from 44x44 to 32x32)
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 11))
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(SemanticColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(windowSize == .compact ? Spacing.sm : Spacing.md)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Payment Overview Compact Card

/// A smaller, inline version for compact mode - matches Budget Overview pattern
/// Uses adaptive grid to fit multiple cards per row
private struct PaymentOverviewCompactCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    var formatAsCurrency: Bool = true
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Smaller icon with background circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                // Title: size 9, uppercase
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                    .lineLimit(1)
                
                // Value: size 14, bold, rounded
                Text(formattedValue)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.03), color.opacity(0.01)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(isHovered ? 0.3 : 0.1), lineWidth: 1)
                )
        )
        .shadow(
            color: color.opacity(0.05),
            radius: 3,
            x: 0,
            y: 1
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var formattedValue: String {
        if formatAsCurrency {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencySymbol = "$"
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
            formatter.groupingSeparator = ","
            formatter.usesGroupingSeparator = true
            return formatter.string(from: NSNumber(value: value)) ?? "$0"
        } else {
            return String(format: "%.0f", value)
        }
    }
}
