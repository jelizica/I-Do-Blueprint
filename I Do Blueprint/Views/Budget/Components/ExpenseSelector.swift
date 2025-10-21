import SwiftUI

/// Expense selection component with expense details display
struct ExpenseSelector: View {
    let expenses: [Expense]
    @Binding var selectedExpenseId: UUID?
    var alreadyPaid: Double = 0
    var remainingAmount: Double?
    
    private var selectedExpense: Expense? {
        expenses.first { $0.id == selectedExpenseId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expense Selection")
                .font(.headline)
            
            if expenses.isEmpty {
                emptyStateView
            } else {
                expensePickerView
                
                if let selectedExpense {
                    expenseDetailsView(for: selectedExpense)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(AppColors.Budget.pending)
            
            Text("No expenses available")
                .font(.headline)
            
            Text("You need to create budget expenses first before setting up payment plans.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(AppColors.Budget.pending.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var expensePickerView: some View {
        Picker("Select Expense", selection: $selectedExpenseId) {
            Text("Choose an expense").tag(nil as UUID?)
            ForEach(expenses, id: \.id) { expense in
                HStack {
                    Text(expense.expenseName)
                    Spacer()
                    Text(NumberFormatter.currency.string(from: NSNumber(value: expense.amount)) ?? "$0")
                        .foregroundColor(.secondary)
                }
                .tag(expense.id as UUID?)
            }
        }
        .pickerStyle(.menu)
    }
    
    private func expenseDetailsView(for expense: Expense) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Total Amount")
                    .fontWeight(.medium)
                Spacer()
                Text(NumberFormatter.currency.string(from: NSNumber(value: expense.amount)) ?? "$0")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("Already Paid")
                Spacer()
                Text(NumberFormatter.currency.string(from: NSNumber(value: alreadyPaid)) ?? "$0")
                    .foregroundColor(AppColors.Budget.income)
            }
            
            HStack {
                Text("Remaining")
                Spacer()
                let remaining = remainingAmount ?? (expense.amount - alreadyPaid)
                Text(NumberFormatter.currency.string(from: NSNumber(value: remaining)) ?? "$0")
                    .foregroundColor(AppColors.Budget.pending)
            }
        }
        .padding()
        .background(AppColors.Budget.allocated.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    ExpenseSelector(
        expenses: [
            Expense(
                id: UUID(),
                coupleId: UUID(),
                budgetCategoryId: UUID(),
                vendorId: 1,
                expenseName: "Sample Expense",
                amount: 1000.00,
                expenseDate: Date(),
                paymentMethod: "credit_card",
                paymentStatus: .pending,
                notes: "Test expense",
                approvalStatus: "approved",
                invoiceDocumentUrl: nil,
                isTestData: true,
                createdAt: Date(),
                updatedAt: Date())
        ],
        selectedExpenseId: .constant(nil))
    .padding()
}
