//
//  VendorDetailFinancialTab.swift
//  I Do Blueprint
//
//  Financial tab content for vendor detail modal
//

import SwiftUI

struct VendorDetailFinancialTab: View {
    let vendor: Vendor
    let expenses: [Expense]
    let payments: [PaymentSchedule]
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            if isLoading {
                loadingView
            } else if hasAnyFinancialInfo {
                financialContent
            } else {
                VendorEmptyStateView(
                    icon: "dollarsign.circle",
                    title: "No Financial Information",
                    message: "Add quoted amount, expenses, or payment schedules to track financial details for this vendor."
                )
            }
        }
    }
    
    // MARK: - Components
    
    private var loadingView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading financial data...")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var financialContent: some View {
        VStack(spacing: Spacing.xl) {
            // Summary Cards
            summaryCards
            
            // Expenses List
            if !expenses.isEmpty {
                expensesList
            }
            
            // Payments List
            if !payments.isEmpty {
                paymentsList
            }
        }
    }
    
    private var summaryCards: some View {
        HStack(spacing: Spacing.md) {
            FinancialSummaryCard(
                title: "Quoted Amount",
                amount: vendor.quotedAmount ?? 0,
                icon: "banknote.fill",
                color: SemanticColors.primaryAction
            )
            
            FinancialSummaryCard(
                title: "Total Expenses",
                amount: totalExpenses,
                icon: "chart.bar.fill",
                color: SemanticColors.warning
            )
            
            FinancialSummaryCard(
                title: "Total Paid",
                amount: totalPaid,
                icon: "checkmark.circle.fill",
                color: SemanticColors.success
            )
        }
    }
    
    private var expensesList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Expenses (\(expenses.count))",
                icon: "list.bullet.circle.fill",
                color: SemanticColors.warning
            )
            
            VStack(spacing: Spacing.sm) {
                ForEach(expenses) { expense in
                    ExpenseRow(expense: expense)
                }
            }
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }
    }
    
    private var paymentsList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeaderV2(
                title: "Payment Schedule (\(payments.count))",
                icon: "calendar.circle.fill",
                color: SemanticColors.success
            )
            
            VStack(spacing: Spacing.sm) {
                ForEach(payments) { payment in
                    PaymentRow(payment: payment)
                }
            }
            .padding(Spacing.md)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(CornerRadius.md)
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasAnyFinancialInfo: Bool {
        vendor.quotedAmount != nil || !expenses.isEmpty || !payments.isEmpty
    }
    
    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var totalPaid: Double {
        payments.filter { $0.paid == true }.reduce(0) { $0 + $1.paymentAmount }
    }
}

// MARK: - Supporting Views

struct FinancialSummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(title)
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
            
            Text(amount.formatted(.currency(code: "USD")))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(SemanticColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.md)
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(expense.expenseName)
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(expense.expenseDate.formatted(date: .abbreviated, time: .omitted))
                    .font(Typography.caption2)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(expense.amount.formatted(.currency(code: "USD")))
                    .font(Typography.bodyRegular)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)
                
                VendorStatusBadge(status: expense.paymentStatus)
            }
        }
        .padding(Spacing.sm)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.sm)
    }
}

struct PaymentRow: View {
    let payment: PaymentSchedule
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(payment.paymentDate.formatted(date: .abbreviated, time: .omitted))
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textPrimary)
                
                if let notes = payment.notes, !notes.isEmpty {
                    Text(notes)
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(payment.paymentAmount.formatted(.currency(code: "USD")))
                    .font(Typography.bodyRegular)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)
                
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: payment.paid == true ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                    Text(payment.paid == true ? "Paid" : "Pending")
                        .font(Typography.caption2)
                }
                .foregroundColor(payment.paid == true ? SemanticColors.success : SemanticColors.warning)
            }
        }
        .padding(Spacing.sm)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.sm)
    }
}

struct VendorStatusBadge: View {
    let status: PaymentStatus
    
    private var statusColor: Color {
        switch status {
        case .paid: return SemanticColors.success
        case .pending: return SemanticColors.warning
        case .overdue: return SemanticColors.error
        default: return SemanticColors.textSecondary
        }
    }
    
    var body: some View {
        Text(status.displayName)
            .font(Typography.caption2)
            .foregroundColor(statusColor)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(statusColor.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
    }
}
