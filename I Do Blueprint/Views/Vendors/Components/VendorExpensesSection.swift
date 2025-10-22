//
//  VendorExpensesSection.swift
//  I Do Blueprint
//
//  Displays expenses linked to a vendor
//

import SwiftUI

struct VendorExpensesSection: View {
    let expenses: [Expense]
    var payments: [PaymentSchedule] = []
    
    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var paidExpenses: Double {
        // Calculate from actual paid payments linked to expenses
        var totalPaid: Double = 0
        
        for expense in expenses {
            // Get all payments for this expense
            let expensePayments = payments.filter { $0.expenseId == expense.id }
            
            // Sum up paid payments
            let paidForExpense = expensePayments
                .filter { $0.paid }
                .reduce(0) { $0 + $1.paymentAmount }
            
            totalPaid += paidForExpense
        }
        
        return totalPaid
    }
    
    private var pendingExpenses: Double {
        // Calculate pending as total minus paid
        totalExpenses - paidExpenses
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Section Header
            SectionHeaderV2(
                title: "Expenses",
                icon: "receipt.fill",
                color: AppColors.Vendor.booked
            )
            
            // Summary Cards
            HStack(spacing: Spacing.md) {
                ExpenseSummaryCard(
                    title: "Total",
                    amount: totalExpenses,
                    icon: "sum",
                    color: AppColors.primary
                )
                
                ExpenseSummaryCard(
                    title: "Paid",
                    amount: paidExpenses,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                ExpenseSummaryCard(
                    title: "Pending",
                    amount: pendingExpenses,
                    icon: "clock.fill",
                    color: .orange
                )
            }
            
            // Expense List
            VStack(spacing: Spacing.sm) {
                ForEach(expenses.sorted(by: { $0.expenseDate > $1.expenseDate })) { expense in
                    VendorExpenseRow(expense: expense)
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct ExpenseSummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Text(amount.formatted(.currency(code: "USD")))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct VendorExpenseRow: View {
    let expense: Expense
    
    private var statusColor: Color {
        switch expense.paymentStatus {
        case .paid: return .green
        case .pending: return .orange
        case .overdue: return .red
        case .partial: return .yellow
        case .cancelled: return .gray
        case .refunded: return .purple
        }
    }
    
    private var statusIcon: String {
        switch expense.paymentStatus {
        case .paid: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .partial: return "circle.lefthalf.filled"
        case .cancelled: return "xmark.circle.fill"
        case .refunded: return "arrow.uturn.backward.circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status Indicator
            Image(systemName: statusIcon)
                .font(.title3)
                .foregroundColor(statusColor)
                .frame(width: 24)
            
            // Expense Info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(expense.expenseName)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: Spacing.xs) {
                    Text(expense.expenseDate.formatted(date: .abbreviated, time: .omitted))
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    if let invoiceNumber = expense.invoiceNumber, !invoiceNumber.isEmpty {
                        Text("•")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                        
                        Text("Invoice: \(invoiceNumber)")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Amount and Status
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(expense.amount.formatted(.currency(code: "USD")))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(expense.paymentStatus.displayName)
                    .font(Typography.caption)
                    .foregroundColor(statusColor)
            }
        }
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    VStack {
        VendorExpensesSection(expenses: [
            Expense(
                id: UUID(),
                coupleId: UUID(),
                budgetCategoryId: UUID(),
                vendorId: 1,
                vendorName: "Test Vendor",
                expenseName: "Venue Deposit",
                amount: 5000,
                expenseDate: Date(),
                paymentMethod: "credit_card",
                paymentStatus: .paid,
                receiptUrl: nil,
                invoiceNumber: "INV-001",
                notes: nil,
                approvalStatus: "approved",
                approvedBy: nil,
                approvedAt: nil,
                invoiceDocumentUrl: nil,
                isTestData: false,
                createdAt: Date(),
                updatedAt: nil
            ),
            Expense(
                id: UUID(),
                coupleId: UUID(),
                budgetCategoryId: UUID(),
                vendorId: 1,
                vendorName: "Test Vendor",
                expenseName: "Final Payment",
                amount: 10000,
                expenseDate: Date().addingTimeInterval(86400 * 30),
                paymentMethod: nil,
                paymentStatus: .pending,
                receiptUrl: nil,
                invoiceNumber: "INV-002",
                notes: nil,
                approvalStatus: "pending",
                approvedBy: nil,
                approvedAt: nil,
                invoiceDocumentUrl: nil,
                isTestData: false,
                createdAt: Date(),
                updatedAt: nil
            )
        ])
    }
    .padding()
    .background(AppColors.background)
}
