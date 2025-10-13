//
//  BudgetItemsGrid.swift
//  I Do Blueprint
//
//  Created by Claude on 10/9/25.
//

import SwiftUI

struct BudgetItemsGrid: View {
    let filteredBudgetItems: [BudgetOverviewItem]
    let onEditExpense: (String, String) -> Void
    let onRemoveExpense: (String, String) async -> Void
    let onEditGift: (String, String) -> Void
    let onRemoveGift: (String) async -> Void
    let onAddExpense: (String) -> Void
    let onAddGift: (String) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
            ForEach(filteredBudgetItems, id: \.id) { item in
                CircularProgressBudgetCard(
                    item: item,
                    onEditExpense: onEditExpense,
                    onRemoveExpense: onRemoveExpense,
                    onEditGift: onEditGift,
                    onRemoveGift: onRemoveGift,
                    onAddExpense: onAddExpense,
                    onAddGift: onAddGift)
            }
        }
    }
}
