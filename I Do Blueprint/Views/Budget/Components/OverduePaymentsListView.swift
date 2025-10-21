import SwiftUI

/// Sheet view displaying overdue payments
struct OverduePaymentsListView: View {
    let expenses: [Expense]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(expenses) { expense in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(expense.expenseName)
                                .font(.headline)
                            
                            Spacer()
                            
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(AppColors.Budget.overBudget)
                        }
                        
                        if let vendor = expense.vendorName, !vendor.isEmpty {
                            Text("Vendor: \(vendor)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            if let dueDate = expense.dueDate {
                                Text("Due: \(dueDate, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(AppColors.Budget.overBudget)
                                
                                Spacer()
                            }
                            
                            Text(NumberFormatter.currency.string(from: NSNumber(value: expense.remainingAmount)) ?? "$0")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.Budget.overBudget)
                        }
                        
                        let daysOverdue = expense.dueDate.map { Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0 } ?? 0
                        if daysOverdue > 0 {
                            Text("\(daysOverdue) day\(daysOverdue == 1 ? "" : "s") overdue")
                                .font(.caption2)
                                .foregroundColor(AppColors.Budget.overBudget)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Overdue Payments")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

