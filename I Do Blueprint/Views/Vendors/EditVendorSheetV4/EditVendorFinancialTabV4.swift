//
//  EditVendorFinancialTabV4.swift
//  I Do Blueprint
//
//  Financial tab for Edit Vendor Modal V4 (View Only)
//  Displays: Quoted amount, payment schedule donut chart, expenses list
//

import SwiftUI

struct EditVendorFinancialTabV4: View {
    // MARK: - Properties
    
    let vendor: Vendor
    let expenses: [Expense]
    let payments: [PaymentSchedule]
    let isLoading: Bool
    
    // MARK: - Computed Properties
    
    private var quotedAmount: Double {
        vendor.quotedAmount ?? 0
    }
    
    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var paidAmount: Double {
        payments.filter { $0.paid }.reduce(0) { $0 + $1.paymentAmount }
    }
    
    private var pendingAmount: Double {
        totalExpenses - paidAmount
    }
    
    private var paidPercentage: Double {
        guard totalExpenses > 0 else { return 0 }
        return (paidAmount / totalExpenses) * 100
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: Spacing.xxl) {
            // View Only Banner
            viewOnlyBanner
            
            if isLoading {
                loadingView
            } else {
                // Main Content Grid
                HStack(alignment: .top, spacing: Spacing.xxl) {
                    // Left Column - Quoted Amount & Stats
                    VStack(spacing: Spacing.lg) {
                        quotedAmountCard
                        statsRow
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right Column - Payment Schedule Chart
                    paymentScheduleCard
                        .frame(maxWidth: .infinity)
                }
                
                // Expenses List
                expensesListSection
            }
        }
    }
    
    // MARK: - View Only Banner
    
    private var viewOnlyBanner: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "eye")
                .font(.system(size: 18))
                .foregroundColor(SemanticColors.textSecondary)
                .frame(width: 36, height: 36)
                .background(SemanticColors.backgroundPrimary.opacity(0.5))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.sm) {
                    Text("View Only Mode")
                        .font(Typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary)
                    
                    Text("Read-Only")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(SemanticColors.textTertiary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(SemanticColors.backgroundPrimary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                        .textCase(.uppercase)
                }
                
                Text("You are viewing the financial summary. Editing is disabled in this view.")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(glassCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
        .overlay(
            Rectangle()
                .fill(SemanticColors.textTertiary)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2)),
            alignment: .leading
        )
    }
    
    // MARK: - Quoted Amount Card
    
    private var quotedAmountCard: some View {
        VStack(spacing: Spacing.sm) {
            Text("Quoted Amount")
                .font(Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(SemanticColors.textSecondary)
            
            Text(formatCurrency(quotedAmount))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(SemanticColors.primaryAction)
            
            Text(vendor.vendorType?.uppercased() ?? "VENDOR")
                .font(Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(SemanticColors.textTertiary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .background(
            ZStack {
                glassCardBackground
                
                // Gradient overlay for pink tint
                LinearGradient(
                    colors: [
                        SemanticColors.primaryAction.opacity(Opacity.verySubtle),
                        Color.clear,
                        SemanticColors.primaryAction.opacity(Opacity.verySubtle)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(
                    LinearGradient(
                        colors: [
                            SemanticColors.primaryAction.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .macOSShadow(.subtle)
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: Spacing.md) {
            statCard(
                title: "Total",
                amount: totalExpenses,
                color: SemanticColors.textPrimary,
                subtitle: "Total Expenses"
            )
            
            statCard(
                title: "Paid",
                amount: paidAmount,
                color: AppColors.Vendor.booked,
                subtitle: "Paid Amount"
            )
            
            statCard(
                title: "Pending",
                amount: pendingAmount,
                color: SemanticColors.primaryAction,
                subtitle: "Pending Amount"
            )
        }
    }
    
    private func statCard(title: String, amount: Double, color: Color, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)
            
            Text(formatCurrency(amount))
                .font(Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            // Mini sparkline placeholder
            sparklineView(color: color)
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(SemanticColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(glassCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
    }
    
    private func sparklineView(color: Color) -> some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                path.move(to: CGPoint(x: 0, y: height * 0.8))
                path.addQuadCurve(
                    to: CGPoint(x: width * 0.4, y: height * 0.6),
                    control: CGPoint(x: width * 0.2, y: height * 0.7)
                )
                path.addQuadCurve(
                    to: CGPoint(x: width * 0.8, y: height * 0.2),
                    control: CGPoint(x: width * 0.6, y: height * 0.4)
                )
                path.addLine(to: CGPoint(x: width, y: height * 0.3))
            }
            .stroke(color.opacity(0.5), lineWidth: 2)
        }
        .frame(height: 24)
        .opacity(0.6)
    }
    
    // MARK: - Payment Schedule Card
    
    private var paymentScheduleCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Payment Schedule")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)
            
            HStack(spacing: Spacing.xl) {
                // Donut Chart
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(SemanticColors.borderLight, lineWidth: 12)
                    
                    // Paid portion (green)
                    Circle()
                        .trim(from: 0, to: CGFloat(paidPercentage / 100))
                        .stroke(
                            AppColors.Vendor.booked,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    // Pending portion (pink) - shown as remaining
                    Circle()
                        .trim(from: CGFloat(paidPercentage / 100), to: 1)
                        .stroke(
                            SemanticColors.primaryAction.opacity(0.3),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    // Center text
                    VStack(spacing: Spacing.xxs) {
                        Text("\(Int(paidPercentage))%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(SemanticColors.textPrimary)
                        
                        Text("Paid")
                            .font(Typography.caption)
                            .foregroundColor(SemanticColors.textSecondary)
                    }
                }
                .frame(width: 140, height: 140)
                
                // Legend
                VStack(alignment: .leading, spacing: Spacing.md) {
                    legendItem(
                        label: "Paid",
                        amount: paidAmount,
                        color: AppColors.Vendor.booked
                    )
                    
                    legendItem(
                        label: "Remaining",
                        amount: pendingAmount,
                        color: SemanticColors.primaryAction
                    )
                    
                    Divider()
                    
                    legendItem(
                        label: "Total",
                        amount: totalExpenses,
                        color: SemanticColors.textPrimary,
                        isBold: true
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Spacing.xl)
        .background(glassCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
        .macOSShadow(.subtle)
    }
    
    private func legendItem(label: String, amount: Double, color: Color, isBold: Bool = false) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(SemanticColors.textTertiary)
                    .tracking(0.5)
                
                Text(formatCurrency(amount))
                    .font(isBold ? Typography.bodyRegular : Typography.bodySmall)
                    .fontWeight(isBold ? .bold : .semibold)
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(color.opacity(Opacity.verySubtle))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(color.opacity(Opacity.light), lineWidth: 1)
        )
    }
    
    // MARK: - Expenses List Section
    
    private var expensesListSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Expenses List")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)
            
            if expenses.isEmpty {
                emptyExpensesView
            } else {
                VStack(spacing: Spacing.sm) {
                    ForEach(expenses) { expense in
                        expenseRow(expense)
                    }
                }
            }
        }
    }
    
    private var emptyExpensesView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text")
                .font(.system(size: 32))
                .foregroundColor(SemanticColors.textTertiary)
            
            Text("No expenses recorded")
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxl)
        .background(glassCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
    
    private func expenseRow(_ expense: Expense) -> some View {
        HStack(spacing: Spacing.md) {
            // Status Icon
            Circle()
                .fill(expenseStatusColor(expense).opacity(Opacity.light))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: expenseStatusIcon(expense))
                        .font(.system(size: 14))
                        .foregroundColor(expenseStatusColor(expense))
                )
                .overlay(
                    Circle()
                        .stroke(expenseStatusColor(expense).opacity(0.3), lineWidth: 1)
                )
            
            // Expense Info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(expense.expenseName)
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(formatDate(expense.expenseDate))
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
            
            // Amount & Status
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(formatCurrency(expense.amount))
                    .font(Typography.bodySmall)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(expenseStatusText(expense))
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textTertiary)
            }
            
            // Expand chevron
            Image(systemName: "chevron.down")
                .font(.system(size: 14))
                .foregroundColor(SemanticColors.textTertiary)
        }
        .padding(Spacing.md)
        .background(glassCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
    }
    
    private func expenseStatusColor(_ expense: Expense) -> Color {
        switch expense.paymentStatus {
        case .paid:
            return AppColors.Vendor.booked
        case .pending:
            return SemanticColors.primaryAction
        case .overdue:
            return SemanticColors.statusError
        case .partial:
            return SemanticColors.statusWarning
        case .cancelled, .refunded:
            return SemanticColors.textTertiary
        }
    }
    
    private func expenseStatusIcon(_ expense: Expense) -> String {
        switch expense.paymentStatus {
        case .paid:
            return "checkmark"
        case .pending:
            return "clock"
        case .overdue:
            return "exclamationmark.triangle"
        case .partial:
            return "chart.pie"
        case .cancelled, .refunded:
            return "xmark"
        }
    }
    
    private func expenseStatusText(_ expense: Expense) -> String {
        switch expense.paymentStatus {
        case .paid:
            return "Paid"
        case .pending:
            return "Pending"
        case .overdue:
            return "Overdue"
        case .partial:
            return "Partial"
        case .cancelled:
            return "Cancelled"
        case .refunded:
            return "Refunded"
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading financial data...")
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, Spacing.huge)
    }
    
    // MARK: - Helper Views
    
    private var glassCardBackground: some View {
        SemanticColors.backgroundPrimary.opacity(0.4)
    }
    
    // MARK: - Formatting Helpers
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("Financial Tab") {
    ScrollView {
        EditVendorFinancialTabV4(
            vendor: .makeTest(quotedAmount: 900),
            expenses: [],
            payments: [],
            isLoading: false
        )
        .padding()
    }
    .frame(width: 850, height: 700)
}

#Preview("Financial Tab - Loading") {
    EditVendorFinancialTabV4(
        vendor: .makeTest(quotedAmount: 900),
        expenses: [],
        payments: [],
        isLoading: true
    )
    .padding()
    .frame(width: 850, height: 500)
}
