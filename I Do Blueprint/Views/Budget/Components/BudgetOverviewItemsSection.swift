//
//  BudgetOverviewItemsSection.swift
//  I Do Blueprint
//
//  Created by Claude on 10/9/25.
//

import SwiftUI

struct BudgetOverviewItemsSection: View {
    let filteredBudgetItems: [BudgetOverviewItem]
    let budgetItems: [BudgetOverviewItem]
    let viewMode: BudgetOverviewDashboardViewV2.ViewMode
    let onEditExpense: (String, String) -> Void
    let onRemoveExpense: (String, String) async -> Void
    let onEditGift: (String, String) -> Void
    let onRemoveGift: (String) async -> Void
    let onAddExpense: (String) -> Void
    let onAddGift: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Budget Items")
                    .font(.headline)

                Spacer()

                Text("\(filteredBudgetItems.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            }

            if filteredBudgetItems.isEmpty {
                emptyStateView
            } else {
                switch viewMode {
                case .cards:
                    BudgetItemsGrid(
                        filteredBudgetItems: filteredBudgetItems,
                        onEditExpense: onEditExpense,
                        onRemoveExpense: onRemoveExpense,
                        onEditGift: onEditGift,
                        onRemoveGift: onRemoveGift,
                        onAddExpense: onAddExpense,
                        onAddGift: onAddGift)
                case .table:
                    VStack(spacing: 0) {
                        // Table header
                        HStack(spacing: 16) {
                            Text("Item").frame(width: 200, alignment: .leading)
                            Text("Category").frame(width: 120, alignment: .leading)
                            Text("Budgeted").frame(width: 100, alignment: .trailing)
                            Text("Spent").frame(width: 100, alignment: .trailing)
                            Text("Remaining").frame(width: 100, alignment: .trailing)
                            Spacer()
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))

                        Divider()

                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredBudgetItems) { item in
                                    BudgetTableRow(
                                        item: item,
                                        onAddExpense: {
                                            onAddExpense(item.id)
                                        },
                                        onAddGift: {
                                            onAddGift(item.id)
                                        },
                                        onRemoveExpense: { expenseId in
                                            Task {
                                                await onRemoveExpense(item.id, expenseId)
                                            }
                                        },
                                        onRemoveGift: {
                                            Task {
                                                await onRemoveGift(item.id)
                                            }
                                        }
                                    )
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            if budgetItems.isEmpty {
                Text("No budget items found.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    Text("No budget items match the current filters.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Try adjusting your filters to see more items.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}
