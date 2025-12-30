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
    @Binding var expandedFolderIds: Set<String>
    let viewMode: BudgetOverviewDashboardViewV2.ViewMode
    let onEditExpense: (String, String) -> Void
    let onRemoveExpense: (String, String) async -> Void
    let onEditGift: (String, String) -> Void
    let onRemoveGift: (String) async -> Void // giftId parameter
    let onAddExpense: (String) -> Void
    let onAddGift: (String) -> Void
    
    // Computed property to get only top-level items (no parent)
    private var topLevelItems: [BudgetOverviewItem] {
        filteredBudgetItems
            .filter { $0.isTopLevel }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    // Get children of a folder
    private func getChildren(of folderId: String) -> [BudgetOverviewItem] {
        budgetItems
            .filter { $0.parentFolderId == folderId }
            .sorted { $0.displayOrder < $1.displayOrder }
    }
    
    // Calculate aggregated totals for a folder
    private func getFolderTotals(folderId: String) -> (budgeted: Double, spent: Double, effectiveSpent: Double) {
        let children = getChildren(of: folderId)
        return children.reduce((budgeted: 0.0, spent: 0.0, effectiveSpent: 0.0)) { accumulator, child in
            (
                budgeted: accumulator.budgeted + child.budgeted,
                spent: accumulator.spent + child.spent,
                effectiveSpent: accumulator.effectiveSpent + child.effectiveSpent
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Budget Items")
                    .font(.headline)

                Spacer()

                Text("\(topLevelItems.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            }

            if topLevelItems.isEmpty {
                emptyStateView
            } else {
                switch viewMode {
                case .cards:
                    cardsView
                case .table:
                    tableView
                }
            }
        }
    }
    
    private var cardsView: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 280, maximum: 380), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(topLevelItems) { item in
                if item.isFolder {
                    // Folder card with aggregated totals
                    folderCardView(item)
                } else {
                    // Regular item card
                    regularItemCard(item)
                }
            }
        }
    }
    
    // Helper to create a budget item card with all closures configured
    private func budgetItemCard(for item: BudgetOverviewItem) -> some View {
        CircularProgressBudgetCard(
            item: item,
            onEditExpense: { _, expenseId in
                onEditExpense(item.id, expenseId)
            },
            onRemoveExpense: { expenseIdFromCard, itemIdFromCard in
                Task {
                    await onRemoveExpense(expenseIdFromCard, itemIdFromCard)
                }
            },
            onEditGift: { _, giftId in
                onEditGift(item.id, giftId)
            },
            onRemoveGift: { giftId in
                Task {
                    await onRemoveGift(giftId)
                }
            },
            onAddExpense: { _ in onAddExpense(item.id) },
            onAddGift: { _ in onAddGift(item.id) }
        )
    }
    
    private func regularItemCard(_ item: BudgetOverviewItem) -> some View {
        budgetItemCard(for: item)
    }
    
    @ViewBuilder
    private func folderCardView(_ folder: BudgetOverviewItem) -> some View {
        let totals = getFolderTotals(folderId: folder.id)
        let isExpanded = expandedFolderIds.contains(folder.id)
        let children = getChildren(of: folder.id)
        
        // Debug logging
        let _ = print("🗂️ Folder '\(folder.itemName)' - ID: \(folder.id), isExpanded: \(isExpanded), children: \(children.count)")
        
        // Folder card
        FolderBudgetCard(
            folderName: folder.itemName,
            budgeted: totals.budgeted,
            spent: totals.spent,
            effectiveSpent: totals.effectiveSpent,
            childCount: children.count,
            isExpanded: isExpanded,
            onToggleExpand: {
                print("🔄 Toggle folder '\(folder.itemName)' - Current state: \(isExpanded)")
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedFolderIds.remove(folder.id)
                        print("✅ Removed folder ID: \(folder.id)")
                    } else {
                        expandedFolderIds.insert(folder.id)
                        print("✅ Added folder ID: \(folder.id)")
                    }
                    print("📊 expandedFolderIds now contains: \(expandedFolderIds)")
                }
            }
        )
        
        // Child items appear inline in the grid when expanded
        if isExpanded {
            ForEach(children) { child in
                budgetItemCard(for: child)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var tableView: some View {
        VStack(spacing: 0) {
            // Table header with flexible layout
            HStack(spacing: 16) {
                Text("Item")
                    .frame(minWidth: 120, maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(2)
                
                Text("Category")
                    .frame(minWidth: 80, maxWidth: 150, alignment: .leading)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(1)
                
                Text("Budgeted")
                    .frame(minWidth: 80, alignment: .trailing)
                    .fixedSize()
                
                Text("Spent")
                    .frame(minWidth: 80, alignment: .trailing)
                    .fixedSize()
                
                Text("Remaining")
                    .frame(minWidth: 80, alignment: .trailing)
                    .fixedSize()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(topLevelItems) { item in
                        if item.isFolder {
                            folderTableRow(item)
                        } else {
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
                                        await onRemoveExpense(expenseId, item.id)
                                    }
                                },
                                onRemoveGift: { giftId in
                                    Task {
                                        await onRemoveGift(giftId)
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
    
    private func folderTableRow(_ folder: BudgetOverviewItem) -> some View {
        let totals = getFolderTotals(folderId: folder.id)
        let isExpanded = expandedFolderIds.contains(folder.id)
        let children = getChildren(of: folder.id)
        
        return VStack(spacing: 0) {
            // Folder row
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedFolderIds.remove(folder.id)
                    } else {
                        expandedFolderIds.insert(folder.id)
                    }
                }
            }) {
                HStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "folder.fill")
                            .foregroundColor(.orange)
                        Text(folder.itemName)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(width: 200, alignment: .leading)
                    
                    Text("FOLDER")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .cornerRadius(4)
                        .frame(width: 120, alignment: .leading)
                    
                    Text("$\(totals.budgeted, specifier: "%.2f")")
                        .frame(width: 100, alignment: .trailing)
                    
                    Text("$\(totals.effectiveSpent, specifier: "%.2f")")
                        .frame(width: 100, alignment: .trailing)
                    
                    Text("$\(totals.budgeted - totals.effectiveSpent, specifier: "%.2f")")
                        .frame(width: 100, alignment: .trailing)
                        .foregroundColor(totals.budgeted - totals.effectiveSpent >= 0 ? .green : .red)
                    
                    Spacer()
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            }
            .buttonStyle(.plain)
            
            Divider()
            
            // Child rows (shown when expanded)
            if isExpanded {
                ForEach(children) { child in
                    VStack(spacing: 0) {
                        HStack(spacing: 16) {
                            Spacer().frame(width: 20) // Indent
                            BudgetTableRow(
                                item: child,
                                onAddExpense: {
                                    onAddExpense(child.id)
                                },
                                onAddGift: {
                                    onAddGift(child.id)
                                },
                                onRemoveExpense: { expenseId in
                                    Task {
                                        await onRemoveExpense(expenseId, child.id)
                                    }
                                },
                                onRemoveGift: { giftId in
                                    Task {
                                        await onRemoveGift(giftId)
                                    }
                                }
                            )
                        }
                        Divider()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
