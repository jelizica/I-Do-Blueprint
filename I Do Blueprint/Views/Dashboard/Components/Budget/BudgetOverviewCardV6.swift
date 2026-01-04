//
//  BudgetOverviewCardV6.swift
//  I Do Blueprint
//
//  Native macOS "Wow Factor" version with premium visual design:
//  - SwiftUI Material backgrounds for vibrancy
//  - Gradient border strokes for depth
//  - Multi-layer macOS-native shadows
//  - Native progress bars with inner shadows and glow
//  - Hover elevation with spring animations
//  - System colors that adapt to light/dark mode
//  - Glass morphism effects
//

import SwiftUI

struct BudgetOverviewCardV6: View {
    @ObservedObject var store: BudgetStoreV2
    @ObservedObject var vendorStore: VendorStoreV2
    let userTimezone: TimeZone
    
    // Animation state
    @State private var hasAppeared = false
    @State private var isHovered = false

    // MARK: - Computed Properties
    
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
    
    private var paymentProgress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(totalPaid / totalBudget, 1.0)
    }
    
    private var expenseProgress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(totalExpenses / totalBudget, 1.0)
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

    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header with native icon badge
            headerSection
            
            // Native gradient divider
            NativeDividerStyle(opacity: 0.4)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.1), value: hasAppeared)
            
            // Progress section
            progressSection
            
            // Remaining budget highlight
            remainingBudgetSection
            
            // Payments due this month
            paymentsSection
            
            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 430)
        // Native macOS card styling
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.4 : 0.3),
                            Color.white.opacity(isHovered ? 0.15 : 0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        // Multi-layer macOS shadows
        .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 0.5)
        .shadow(color: Color.black.opacity(isHovered ? 0.08 : 0.05), radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
        .shadow(color: Color.black.opacity(isHovered ? 0.04 : 0.02), radius: isHovered ? 16 : 8, x: 0, y: isHovered ? 8 : 4)
        // Hover interaction
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: Spacing.md) {
            // Native icon badge
            NativeIconBadge(
                systemName: "dollarsign.circle.fill",
                color: AppColors.Budget.allocated,
                size: 44
            )
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Budget Overview")
                    .font(Typography.subheading)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(nsColor: .labelColor))

                if let scenario = store.primaryScenario {
                    Text("$\(formatAmount(totalPaid)) of $\(formatAmount(scenario.totalWithTax)) paid")
                        .font(Typography.caption)
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                } else {
                    Text("No primary scenario")
                        .font(Typography.caption)
                        .foregroundColor(Color(nsColor: .secondaryLabelColor))
                }
            }
            
            Spacer()
        }
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.sm)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : -10)
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: Spacing.md) {
            // Payments Progress
            NativeProgressRow(
                label: "Payments",
                amount: totalPaid,
                progress: paymentProgress,
                color: AppColors.Budget.allocated,
                icon: "creditcard.fill"
            )
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 10)
            .animation(.easeOut(duration: 0.4).delay(0.2), value: hasAppeared)

            // Expenses Progress
            NativeProgressRow(
                label: "Expenses",
                amount: totalExpenses,
                progress: expenseProgress,
                color: SemanticColors.warning,
                icon: "chart.bar.fill"
            )
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 10)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: hasAppeared)
        }
    }
    
    // MARK: - Remaining Budget Section
    
    private var remainingBudgetSection: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "banknote.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [SemanticColors.success, SemanticColors.success.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text("Remaining Budget")
                .font(Typography.caption)
                .foregroundColor(Color(nsColor: .secondaryLabelColor))

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
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SemanticColors.success.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.top, Spacing.xs)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4).delay(0.4), value: hasAppeared)
    }
    
    // MARK: - Payments Section
    
    private var paymentsSection: some View {
        Group {
            if !paymentsThisMonth.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    // Section divider
                    NativeDividerStyle(opacity: 0.3)
                        .padding(.vertical, Spacing.sm)
                        .opacity(hasAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.5), value: hasAppeared)

                    // Section header
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.Budget.allocated)
                        
                        Text("Payments Due This Month")
                            .font(Typography.caption.weight(.semibold))
                            .foregroundColor(Color(nsColor: .labelColor))
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.6), value: hasAppeared)

                    // Payment rows
                    ForEach(Array(paymentsThisMonth.prefix(5).enumerated()), id: \.element.id) { index, payment in
                        NativePaymentRow(
                            payment: payment,
                            vendorStore: vendorStore,
                            userTimezone: userTimezone
                        )
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.7 + Double(index) * 0.05), value: hasAppeared)
                    }
                }
            } else {
                // Empty state
                emptyPaymentsState
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyPaymentsState: some View {
        VStack(spacing: Spacing.md) {
            NativeDividerStyle(opacity: 0.3)
                .padding(.vertical, Spacing.sm)
            
            VStack(spacing: Spacing.sm) {
                // Success icon with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    SemanticColors.success.opacity(0.15),
                                    SemanticColors.success.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
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
                }
                .shadow(color: SemanticColors.success.opacity(0.2), radius: 8, x: 0, y: 4)
                
                Text("No payments due this month")
                    .font(Typography.caption)
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4).delay(0.5), value: hasAppeared)
    }

    // MARK: - Helpers
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Native Progress Row Component

private struct NativeProgressRow: View {
    let label: String
    let amount: Double
    let progress: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text(label)
                    .font(Typography.caption)
                    .foregroundColor(Color(nsColor: .labelColor))

                Spacer()

                Text("$\(formatAmount(amount))")
                    .font(Typography.caption.weight(.semibold))
                    .foregroundColor(Color(nsColor: .labelColor))
            }

            // Native progress bar with inner shadow and glow
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track with inner shadow effect
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(nsColor: .separatorColor).opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                        )
                        .frame(height: 10)

                    // Progress fill with gradient and glow
                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geometry.size.width * progress, 10), height: 10)
                        .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 10)
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

// MARK: - Native Payment Row Component

private struct NativePaymentRow: View {
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
            // Date badge with native styling
            VStack(spacing: 2) {
                Text(formatDay(payment.paymentDate))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(nsColor: .labelColor))
                
                Text(formatMonth(payment.paymentDate))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
                    .textCase(.uppercase)
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 0.5)
            )
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(vendorName)
                    .font(Typography.caption.weight(.medium))
                    .foregroundColor(Color(nsColor: .labelColor))
                    .lineLimit(1)

                Text(formatFullDate(payment.paymentDate))
                    .font(Typography.caption2)
                    .foregroundColor(Color(nsColor: .secondaryLabelColor))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("$\(formatAmount(payment.paymentAmount))")
                    .font(Typography.caption.weight(.bold))
                    .foregroundColor(Color(nsColor: .labelColor))

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
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(isHovered ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
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

#Preview("Budget Overview V6 - Light") {
    ZStack {
        // Background to show vibrancy effect
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        BudgetOverviewCardV6(
            store: BudgetStoreV2(),
            vendorStore: VendorStoreV2(),
            userTimezone: .current
        )
        .frame(width: 400, height: 500)
        .padding()
    }
    .preferredColorScheme(.light)
}

#Preview("Budget Overview V6 - Dark") {
    ZStack {
        // Background to show vibrancy effect
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        BudgetOverviewCardV6(
            store: BudgetStoreV2(),
            vendorStore: VendorStoreV2(),
            userTimezone: .current
        )
        .frame(width: 400, height: 500)
        .padding()
    }
    .preferredColorScheme(.dark)
}

#Preview("Budget Overview V6 - With Gradient Background") {
    ZStack {
        // Colorful background to demonstrate vibrancy
        Image(systemName: "photo.artframe")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 500, height: 600)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.pink.opacity(0.4),
                        Color.orange.opacity(0.3),
                        Color.yellow.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        
        BudgetOverviewCardV6(
            store: BudgetStoreV2(),
            vendorStore: VendorStoreV2(),
            userTimezone: .current
        )
        .frame(width: 400, height: 500)
        .padding()
    }
}
