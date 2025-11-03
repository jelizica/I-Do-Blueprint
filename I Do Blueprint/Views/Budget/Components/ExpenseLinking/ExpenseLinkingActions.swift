//
//  ExpenseLinkingActions.swift
//  I Do Blueprint
//
//  Actions for expense linking view
//

import Foundation

// MARK: - Expense Linking Actions

extension ExpenseLinkingView {

    // MARK: Load Data

    func loadExpenses() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all expenses using repository
            let allExpenses = try await budgetRepository.fetchExpenses()

            // Fetch vendors for expense display using repository
            let vendors = try await vendorRepository.fetchVendors()
            vendorCache = Dictionary(uniqueKeysWithValues: vendors.map { ($0.id, $0) })

            // Fetch categories for expense display using repository
            let categories = try await budgetRepository.fetchCategories()
            categoryCache = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

            // Fetch linked expense allocations for current scenario and budget item
            if let scenario = activeScenario {
                let allocations = try await budgetRepository.fetchExpenseAllocations(
                    scenarioId: scenario.id,
                    budgetItemId: budgetItem.id)
                linkedExpenseIds = Set(allocations.map { UUID(uuidString: $0.expenseId) }.compactMap { $0 })
            }

            await MainActor.run {
                expenses = allExpenses
                filterExpenses()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load expenses: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    // MARK: Filter

    func filterExpenses() {
        var filtered = expenses

        // Apply search filter
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { expense in
                expense.expenseName.lowercased().contains(searchLower) ||
                    (vendorCache[expense.vendorId ?? -1]?.vendorName.lowercased().contains(searchLower) ?? false) ||
                    (categoryCache[expense.budgetCategoryId]?.categoryName.lowercased().contains(searchLower) ?? false)
            }
        }

        // Hide linked expenses if requested
        if hideLinkedExpenses {
            filtered = filtered.filter { !linkedExpenseIds.contains($0.id) }
        }

        filteredExpenses = filtered
    }

    // MARK: Selection

    func toggleExpenseSelection(_ expense: Expense) {
        if selectedExpenses.contains(expense.id) {
            selectedExpenses.remove(expense.id)
        } else {
            selectedExpenses.insert(expense.id)
        }
    }

    func toggleSelectAll() {
        let available = availableExpenses
        if selectedExpenses.count == available.count {
            // Deselect all
            selectedExpenses.removeAll()
        } else {
            // Select all available
            selectedExpenses = Set(available.map(\.id))
        }
    }

    // MARK: Link Expenses

    func linkExpenses() {
        guard let scenario = activeScenario,
              !selectedExpenses.isEmpty else {
            logger.warning("Guard failed - scenario exists: \(activeScenario != nil), has selected expenses: \(!selectedExpenses.isEmpty)")
            return
        }

        isSubmitting = true
        errorMessage = nil
        linkingProgress = (current: 0, total: selectedExpenses.count)

        Task {
            var successCount = 0
            var failedExpenses: [(expense: Expense, error: String)] = []

            for (index, expenseId) in selectedExpenses.enumerated() {
                guard let expense = expenses.first(where: { $0.id == expenseId }) else {
                    logger.warning("Could not find expense with ID: \(expenseId)")
                    continue
                }

                do {
                    // Proportional link: add to current item and rebalance across all linked items
                    try await allocationService.linkExpenseProportionally(expense: expense, to: budgetItem.id, inScenario: scenario.id)
                    logger.info("Successfully linked (proportional) expense: \(expense.expenseName)")
                    successCount += 1

                    await MainActor.run {
                        linkingProgress = (current: index + 1, total: selectedExpenses.count)
                    }
                } catch {
                    logger.error("Failed to create allocation for expense \(expense.expenseName)", error: error)
                    failedExpenses.append((expense, error.localizedDescription))
                    await MainActor.run {
                        linkingProgress = (current: index + 1, total: selectedExpenses.count)
                    }
                }
            }

            await MainActor.run {
                if failedExpenses.isEmpty {
                    logger.info("All \(successCount) expenses linked successfully!")
                    // All successful
                    onSuccess()
                    isPresented = false
                } else if successCount == 0 {
                    logger.error("All expenses failed to link")
                    // All failed
                    errorMessage = "Failed to link all expenses: \(failedExpenses.map(\.error).joined(separator: ", "))"
                } else {
                    logger.warning("Mixed results - \(successCount) success, \(failedExpenses.count) failed")
                    // Mixed results
                    errorMessage = "Linked \(successCount) expenses. Failed: \(failedExpenses.map { "\($0.expense.expenseName) - \($0.error)" }.joined(separator: ", "))"
                    onSuccess() // Still refresh parent to show partial success
                }

                isSubmitting = false
                linkingProgress = nil
            }
        }
    }
}
