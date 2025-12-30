//
//  CategorySectionView.swift
//  I Do Blueprint
//
//  Section view for displaying a parent category with its subcategories
//

import SwiftUI

struct CategorySectionView: View {
    let parentCategory: BudgetCategory
    let subcategories: [BudgetCategory]
    let budgetStore: BudgetStoreV2
    let onEdit: (BudgetCategory) -> Void
    let onDelete: (BudgetCategory) -> Void

    @State private var isExpanded = true

    // Parent categories should only show sum of subcategories (not their own allocated amount)
    private var totalSpent: Double {
        subcategories.reduce(0) { total, subcategory in
            total + budgetStore.categoryStore.spentAmount(for: subcategory.id, expenses: budgetStore.expenseStore.expenses)
        }
    }

    private var totalBudgeted: Double {
        subcategories.reduce(0) { total, subcategory in
            total + subcategory.allocatedAmount
        }
    }

    var body: some View {
        Section {
            // Parent category (folder) - clickable to expand/collapse
            CategoryFolderRowView(
                category: parentCategory,
                subcategoryCount: subcategories.count,
                totalSpent: totalSpent,
                totalBudgeted: totalBudgeted,
                isExpanded: $isExpanded,
                budgetStore: budgetStore,
                onEdit: onEdit,
                onDelete: onDelete)

            // Subcategories
            if isExpanded, !subcategories.isEmpty {
                ForEach(subcategories, id: \.id) { subcategory in
                    CategoryRowView(
                        category: subcategory,
                        spentAmount: budgetStore.categoryStore.spentAmount(for: subcategory.id, expenses: budgetStore.expenseStore.expenses),
                        budgetStore: budgetStore,
                        onEdit: onEdit,
                        onDelete: onDelete)
                        .padding(.leading, Spacing.xl)
                }
            }
        }
    }
}
