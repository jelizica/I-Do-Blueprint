// Extracted from BudgetDevelopmentView.swift

import SwiftUI

struct BudgetItemsTable: View {
    @Binding var budgetItems: [BudgetItem]
    @Binding var newCategoryNames: [String: String]
    @Binding var newSubcategoryNames: [String: String]
    @Binding var newEventNames: [String: String]

    let budgetStore: BudgetStoreV2
    let selectedTaxRate: Double

    let onAddItem: () -> Void
    let onUpdateItem: (String, String, Any) -> Void
    let onRemoveItem: (String) -> Void
    let onAddCategory: (String, String) async -> Void
    let onAddSubcategory: (String, String) async -> Void
    let onAddEvent: (String, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()

                Button(action: onAddItem) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add Item")
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            if budgetItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("No budget items yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Click 'Add Item' to start building your budget")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.huge)
            } else {
                BudgetItemsTableView(
                    items: $budgetItems,
                    budgetStore: budgetStore,
                    selectedTaxRate: selectedTaxRate,
                    newCategoryNames: $newCategoryNames,
                    newSubcategoryNames: $newSubcategoryNames,
                    newEventNames: $newEventNames,
                    onUpdateItem: onUpdateItem,
                    onRemoveItem: onRemoveItem,
                    onAddCategory: onAddCategory,
                    onAddSubcategory: onAddSubcategory,
                    onAddEvent: onAddEvent)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}
