//
//  ExpenseLinkingComponents.swift
//  I Do Blueprint
//
//  UI components for expense linking view
//

import SwiftUI

// MARK: - Expense Linking Components

extension ExpenseLinkingView {
    
    // MARK: Header Section
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select expenses to allocate to this budget item")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let scenario = activeScenario {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppColors.Budget.allocated)
                    Text("Active Scenario: \(scenario.scenarioName)")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppColors.Budget.allocated.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppColors.Budget.pending)
                    Text("Active scenario not available - expense linking disabled")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppColors.Budget.pending.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: Search Section
    
    var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search expenses by name, vendor, or category...", text: $searchText)
                .textFieldStyle(.plain)
                .onChange(of: searchText) {
                    filterExpenses()
                }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: Filter Section
    
    var filterSection: some View {
        HStack {
            Toggle("Hide already linked expenses", isOn: $hideLinkedExpenses)
                .onChange(of: hideLinkedExpenses) {
                    filterExpenses()
                }

            Spacer()

            if !expenses.isEmpty {
                Text("\(linkedExpenseIds.count) of \(expenses.count) expenses already linked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: Selection Summary
    
    var selectionSummary: some View {
        HStack {
            Button(action: toggleSelectAll) {
                HStack(spacing: 4) {
                    Image(systemName: selectedExpenses.count == availableExpenses.count ?
                        "checkmark.square.fill" : "square")
                    Text("Select All (\(availableExpenses.count) available)")
                        .font(.subheadline)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text("\(selectedExpenses.count) selected")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !linkedExpenseIds.isEmpty {
                Text("• \(linkedExpenseIds.count) already linked")
                    .font(.subheadline)
                    .foregroundColor(AppColors.Budget.allocated)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: Expenses List
    
    var expensesList: some View {
        VStack(spacing: 8) {
            if filteredExpenses.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredExpenses, id: \.id) { expense in
                    expenseRow(expense)
                        .id(expense.id)
                }
            }
        }
    }
    
    // MARK: Allocation Preview
    
    var allocationPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Allocation Method")
                .font(.headline)

            // Proportional allocation info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.Budget.allocated)
                    Text("Proportional allocation (automatic)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Text("Expenses will be allocated proportionally based on budget amounts within the scenario.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(AppColors.Budget.allocated.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // How it works
            VStack(alignment: .leading, spacing: 4) {
                Text("How proportional allocation works:")
                    .font(.caption)
                    .fontWeight(.medium)

                Text("• If only this budget item is linked, it receives 100% allocation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("• Multiple linked items split proportionally based on budget amounts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("• Over-budget allocations are allowed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Allocation Preview")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    Text("Budget Item: \(budgetItem.itemName)")
                        .font(.caption)
                    Spacer()
                    Text("Remaining: \(formatCurrency(budgetItem.budgeted - budgetItem.spent))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Text("Selected Expenses (\(selectedExpenses.count)):")
                    .font(.caption)
                    .fontWeight(.medium)

                ForEach(selectedExpensesList, id: \.id) { expense in
                    HStack {
                        Text(expense.expenseName)
                            .font(.caption)
                        Spacer()
                        Text(formatCurrency(expense.amount))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .id(expense.id)
                }

                Divider()

                HStack {
                    Text("Estimated Total Allocation:")
                        .font(.caption)
                        .fontWeight(.bold)
                    Spacer()
                    Text(formatCurrency(totalAllocationAmount))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.Budget.allocated)
                }

                if totalAllocationAmount > (budgetItem.budgeted - budgetItem.spent) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppColors.Budget.pending)
                        Text(
                            "Exceeds remaining budget by \(formatCurrency(totalAllocationAmount - (budgetItem.budgeted - budgetItem.spent)))")
                            .font(.caption)
                            .foregroundColor(AppColors.Budget.pending)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: Empty State
    
    var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)

            Text("No expenses found")
                .font(.headline)

            Text("Try adjusting your search terms or add new expenses")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: Error View
    
    func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.Budget.overBudget)
            Text(message)
                .font(.caption)
            Spacer()
            Button("Dismiss") {
                errorMessage = nil
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(AppColors.Budget.overBudget.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding()
    }
    
    // MARK: Footer Section
    
    var footerSection: some View {
        HStack {
            if let progress = linkingProgress {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Linking expenses...")
                        .font(.caption)
                    ProgressView(value: Double(progress.current), total: Double(progress.total))
                        .progressViewStyle(.linear)
                    Text("\(progress.current) of \(progress.total)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 200)
            }

            Spacer()

            Button("Cancel") {
                isPresented = false
            }
            .buttonStyle(.plain)

            Button(action: linkExpenses) {
                if isSubmitting {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(linkingProgress != nil ?
                            "Linking \(linkingProgress!.current) of \(linkingProgress!.total)..." :
                            "Linking...")
                    }
                } else if activeScenario == nil {
                    Text("Active Scenario Required")
                } else {
                    Text(selectedExpenses.count == 1 ?
                        "Link Expense" :
                        "Link \(selectedExpenses.count) Expenses")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedExpenses.isEmpty || isSubmitting || activeScenario == nil)
        }
        .padding()
    }
}
