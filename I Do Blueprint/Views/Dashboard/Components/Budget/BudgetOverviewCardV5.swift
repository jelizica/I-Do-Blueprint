//
//  BudgetOverviewCardV5.swift
//  I Do Blueprint
//
//  Premium version with enhanced visual design:
//  - Multi-layer shadows for depth
//  - Hover states with scale animation
//  - Gradient progress bars with glow
//  - Icon badges with colored backgrounds
//  - Staggered fade-in animations
//  - Gradient dividers
//  - Enhanced typography hierarchy
//  - Illustrated empty states
//

import SwiftUI

struct BudgetOverviewCardV5: View {
    @ObservedObject var store: BudgetStoreV2
    @ObservedObject var vendorStore: VendorStoreV2
    let userTimezone: TimeZone
    
    // Animation state
    @State private var hasAppeared = false
    @State private var isHovered = false

    private var totalBudget: Double {
        guard let primaryScenario = store.primaryScenario else {
            return 0
        }
        return primaryScenario.totalWithTax
    }

    private var totalPaid: Double {
        return store.payments.totalPaid
    }

    private var totalExpenses: Double {
        guard case .loaded(let budgetData) = store.loadingState else {
            return 0
        }
        return budgetData.expenses.reduce(0) { $0 + $1.amount }
    }

    private var remainingBudget: Double {
        return totalBudget - totalPaid
    }

    private var paymentsThisMonth: [PaymentSchedule] {
        var calendar = Calendar.current
        calendar.timeZone = userTimezone
        
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        return store.payments.paymentSchedules.filter { payment in
            payment.paymentDate >= startOfMonth && payment.paymentDate <= endOfMonth
        }.sorted { $0.paymentDate < $1.paymentDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Enhanced Header with Icon Badge
            HStack(spacing: Spacing.md) {
                // Icon in colored circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.Budget.allocated.opacity(0.2),
                                AppColors.Budget.allocated.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        AppColors.Budget.allocated,
                                        AppColors.Budget.allocated.opacity(0.8)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: AppColors.Budget.allocated.opacity(0.2), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Budget Overview")
                        .font(Typography.subheading)
                        .foregroundColor(SemanticColors.textPrimary)

                    if let scenario = store.primaryScenario {
                        Text("$\(formatAmount(totalPaid)) of $\(formatAmount(scenario.totalWithTax)) paid")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    } else {
                        Text("No primary scenario")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.sm)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : -10)
            .animation(.easeOut(duration: 0.4), value: hasAppeared)

            // Gradient Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            SemanticColors.border.opacity(0.5),
                            SemanticColors.border,
                            SemanticColors.border.opacity(0.5),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: hasAppeared)

            // Payment vs Expense Breakdown with Enhanced Progress Bars
            VStack(spacing: Spacing.md) {
                // Payments Progress
                PremiumBudgetProgressRow(
                    label: "Payments",
                    amount: totalPaid,
                    total: totalBudget,
                    color: AppColors.Budget.allocated,
                    icon: "creditcard.fill"
                )
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: hasAppeared)

                // Expenses Progress
                PremiumBudgetProgressRow(
                    label: "Expenses",
                    amount: totalExpenses,
                    total: totalBudget,
                    color: SemanticColors.warning,
                    icon: "chart.bar.fill"
                )
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: hasAppeared)

                // Remaining Budget with Emphasis
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SemanticColors.success)
                    
                    Text("Remaining Budget")
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    Spacer()

                    Text("$\(formatAmount(remainingBudget))")
                        .font(Typography.bodyRegular.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    SemanticColors.success,
                                    SemanticColors.success.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SemanticColors.success.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(SemanticColors.success.opacity(0.2), lineWidth: 1)
                )
                .padding(.top, Spacing.xs)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: hasAppeared)

                // Payments Due This Month
                if !paymentsThisMonth.isEmpty {
                    // Gradient Divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    SemanticColors.border.opacity(0.3),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.vertical, Spacing.sm)
                        .opacity(hasAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.5), value: hasAppeared)

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.Budget.allocated)
                        
                        Text("Payments Due This Month")
                            .font(Typography.caption.weight(.semibold))
                            .foregroundColor(SemanticColors.textPrimary)
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.6), value: hasAppeared)

                    ForEach(Array(paymentsThisMonth.prefix(5).enumerated()), id: \.element.id) { index, payment in
                        PremiumPaymentDueRow(
                            payment: payment,
                            vendorStore: vendorStore,
                            userTimezone: userTimezone
                        )
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.7 + Double(index) * 0.05), value: hasAppeared)
                    }
                } else {
                    // Empty State with Illustration
                    VStack(spacing: Spacing.md) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        SemanticColors.border.opacity(0.3),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                            .padding(.vertical, Spacing.sm)
                        
                        VStack(spacing: Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            SemanticColors.success,
                                            SemanticColors.success.opacity(0.7)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            Text("No payments due this month")
                                .font(Typography.caption)
                                .foregroundColor(SemanticColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.5), value: hasAppeared)
                }
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 430)
        .background(SemanticColors.backgroundSecondary)
        // Multi-layer shadows for depth
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(isHovered ? 0.06 : 0.04), radius: isHovered ? 16 : 12, x: 0, y: isHovered ? 8 : 6)
        .cornerRadius(CornerRadius.md)
        // Hover interaction
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            hasAppeared = true
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Premium Progress Row Component

private struct PremiumBudgetProgressRow: View {
    let label: String
    let amount: Double
    let total: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)

                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textPrimary)

                Spacer()

                Text("$\(formatAmount(amount))")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundColor(SemanticColors.textPrimary)
            }

            // Enhanced Progress Bar with Gradient and Glow
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(SemanticColors.borderPrimaryLight)
                        .frame(height: 10)

                    // Gradient progress fill with glow
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color,
                                    color.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geometry.size.width * progressPercentage, 10), height: 10)
                        .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressPercentage)
                }
            }
            .frame(height: 10)
        }
    }

    private var progressPercentage: CGFloat {
        guard total > 0 else { return 0 }
        return min(CGFloat(amount / total), 1.0)
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Premium Payment Due Row Component

private struct PremiumPaymentDueRow: View {
    let payment: PaymentSchedule
    @ObservedObject var vendorStore: VendorStoreV2
    let userTimezone: TimeZone
    @State private var isHovered = false

    private var vendorName: String {
        guard let vendorId = payment.vendorId else {
            return payment.notes ?? "Payment"
        }

        if let vendor = vendorStore.vendors.first(where: { $0.id == vendorId }) {
            return vendor.vendorName
        }

        return payment.notes ?? "Payment"
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Date badge
            VStack(spacing: 2) {
                Text(formatDay(payment.paymentDate))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(formatMonth(payment.paymentDate))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(SemanticColors.textSecondary)
                    .textCase(.uppercase)
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(SemanticColors.borderPrimaryLight)
            )
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(vendorName)
                    .font(Typography.caption.weight(.medium))
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)

                Text(formatFullDate(payment.paymentDate))
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("$\(formatAmount(payment.paymentAmount))")
                    .font(Typography.caption.weight(.bold))
                    .foregroundColor(SemanticColors.textPrimary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(payment.paid ? SemanticColors.success : SemanticColors.warning)
                        .frame(width: 6, height: 6)
                    
                    Text(payment.paid ? "Paid" : "Unpaid")
                        .font(Typography.caption2)
                        .foregroundColor(payment.paid ? SemanticColors.success : SemanticColors.warning)
                }
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? SemanticColors.borderPrimaryLight.opacity(0.5) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func formatDay(_ date: Date) -> String {
        return DateFormatting.formatDate(date, format: "d", timezone: userTimezone)
    }
    
    private func formatMonth(_ date: Date) -> String {
        return DateFormatting.formatDate(date, format: "MMM", timezone: userTimezone)
    }
    
    private func formatFullDate(_ date: Date) -> String {
        return DateFormatting.formatDate(date, format: "MMM d, yyyy", timezone: userTimezone)
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Preview

#Preview("Budget Overview V5 - Light") {
    BudgetOverviewCardV5(
        store: BudgetStoreV2(),
        vendorStore: VendorStoreV2(),
        userTimezone: .current
    )
    .frame(width: 400, height: 500)
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Budget Overview V5 - Dark") {
    BudgetOverviewCardV5(
        store: BudgetStoreV2(),
        vendorStore: VendorStoreV2(),
        userTimezone: .current
    )
    .frame(width: 400, height: 500)
    .padding()
    .preferredColorScheme(.dark)
}
