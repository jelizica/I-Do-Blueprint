//
//  BudgetOverviewItemsSection.swift
//  I Do Blueprint
//
//  Created by Claude on 10/9/25.
//

import SwiftUI

struct BudgetOverviewItemsSection: View {
    let windowSize: WindowSize
    let filteredBudgetItems: [BudgetOverviewItem]
    let budgetItems: [BudgetOverviewItem]
    @Binding var expandedFolderIds: Set<String>
    let viewMode: BudgetOverviewDashboardViewV2.ViewMode
    @ObservedObject var bouquetDataProvider: BouquetDataProvider
    let onEditExpense: (String, String) -> Void
    let onRemoveExpense: (String, String) async -> Void
    let onEditGift: (String, String) -> Void
    let onRemoveGift: (String) async -> Void // giftId parameter
    let onAddExpense: (String) -> Void
    let onAddGift: (String) -> Void
    
    // State for expanded table rows in compact mode
    @State private var expandedTableItemIds: Set<String> = []
    
    // Dynamic minimum card width based on content
    private var dynamicMinimumCardWidth: CGFloat {
        // Find the largest currency value across all items
        let maxBudgeted = filteredBudgetItems.map { $0.budgeted }.max() ?? 0
        let maxSpent = filteredBudgetItems.map { $0.effectiveSpent ?? 0 }.max() ?? 0
        let maxValue = max(maxBudgeted, maxSpent)
        
        // Estimate width needed for currency text
        // Format: "$XX,XXX.XX" - rough estimate based on digit count
        let digitCount = String(format: "%.2f", maxValue).count
        let estimatedCurrencyWidth: CGFloat = CGFloat(digitCount) * 8.5 + 10 // ~8.5px per character + padding
        
        // Find the longest word in all item names (words can't break)
        let longestWord = filteredBudgetItems
            .flatMap { $0.itemName.split(separator: " ") }
            .map { String($0) }
            .max(by: { $0.count < $1.count }) ?? ""
        
        // Estimate width for longest word
        // Using headline font (~14-16px), estimate ~9px per character
        let longestWordWidth: CGFloat = CGFloat(longestWord.count) * 9 + 10
        
        // Calculate minimum width components:
        // - Label width: ~70px ("BUDGETED", "SPENT", "REMAINING")
        // - Currency width: dynamic based on largest value
        // - Longest word width: ensures words don't break
        // - Horizontal padding: Spacing.sm * 2 = ~16px
        // - Progress circle minimum: 80px
        // - Safety margin: 20px
        let labelWidth: CGFloat = 70
        let horizontalPadding: CGFloat = 16
        let progressCircleMin: CGFloat = 80
        let safetyMargin: CGFloat = 20
        
        let calculatedWidth = max(
            labelWidth + estimatedCurrencyWidth + horizontalPadding + safetyMargin,
            progressCircleMin + horizontalPadding + safetyMargin,
            longestWordWidth + horizontalPadding + safetyMargin
        )
        
        // Clamp between reasonable bounds
        return min(max(calculatedWidth, 150), 250)
    }
    
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

    private var columns: [GridItem] {
        // Use dynamic calculation for minimum width
        let minWidth = dynamicMinimumCardWidth
        let maxWidth = minWidth + 60 // Allow some flexibility for better layout
        
        switch windowSize {
        case .compact:
            // Dynamic adaptive grid - fits as many as possible based on actual content
            return [GridItem(.adaptive(minimum: minWidth, maximum: maxWidth), spacing: Spacing.md)]
        case .regular:
            // Dynamic with slightly more room
            return [GridItem(.adaptive(minimum: minWidth + 20, maximum: maxWidth + 20), spacing: 16)]
        case .large:
            // Dynamic with even more room
            return [GridItem(.adaptive(minimum: minWidth + 40, maximum: maxWidth + 40), spacing: 16)]
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
                case .bouquet:
                    bouquetView
                }
            }
        }
    }
    
    private var cardsView: some View {
        LazyVGrid(
            columns: columns,
            spacing: windowSize == .compact ? Spacing.md : 16
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
    
    @ViewBuilder
    private var tableView: some View {
        if windowSize == .compact {
            compactTableView
        } else {
            regularTableView
        }
    }
    
    // MARK: - Bouquet View
    
    @State private var hoveredCategoryId: String?
    @State private var selectedCategoryId: String?
    
    private var bouquetView: some View {
        BouquetFlowerView(
            categories: bouquetDataProvider.categories,
            totalBudget: bouquetDataProvider.totalBudgeted,
            hoveredCategoryId: $hoveredCategoryId,
            selectedCategoryId: $selectedCategoryId,
            animateFlower: true,
            onPetalTap: nil
        )
        .frame(maxWidth: .infinity, minHeight: 600)
    }
    
    // MARK: - Compact Table View (Expandable Rows)
    
    private var compactTableView: some View {
        LazyVStack(spacing: 0) {
            ForEach(topLevelItems) { item in
                if item.isFolder {
                    compactFolderRow(item)
                } else {
                    compactItemRow(item)
                }
                Divider()
            }
        }
    }
    
    private func compactItemRow(_ item: BudgetOverviewItem) -> some View {
        let isExpanded = expandedTableItemIds.contains(item.id)
        
        return VStack(spacing: 0) {
            // Collapsed state: Item, Budgeted, Spent
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedTableItemIds.remove(item.id)
                    } else {
                        expandedTableItemIds.insert(item.id)
                    }
                }
            }) {
                HStack(spacing: Spacing.sm) {
                    // Chevron
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    
                    // Item name
                    Text(item.itemName)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Budgeted
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(item.budgeted, specifier: "%.0f")")
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                        Text("budgeted")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 70)
                    
                    // Spent
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(item.effectiveSpent ?? 0, specifier: "%.0f")")
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                        Text("spent")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 70)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            }
            .buttonStyle(.plain)
            
            // Expanded state: Category, Remaining, Linked Items
            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(spacing: Spacing.md) {
                        // Category badge
                        HStack(spacing: 4) {
                            Image(systemName: CategoryIcons.icon(for: item.category))
                                .font(.caption2)
                                .foregroundColor(CategoryIcons.color(for: item.category))
                            Text(item.category)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(CategoryIcons.color(for: item.category).opacity(0.15))
                        .cornerRadius(6)
                        
                        Spacer()
                        
                        // Remaining badge
                        let remaining = item.budgeted - (item.effectiveSpent ?? 0)
                        HStack(spacing: 4) {
                            Image(systemName: remaining >= 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(remaining >= 0 ? .green : .red)
                            Text("$\(remaining, specifier: "%.2f")")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(remaining >= 0 ? .green : .red)
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background((remaining >= 0 ? Color.green : Color.red).opacity(0.15))
                        .cornerRadius(6)
                    }
                    
                    // Linked items with better styling
                    if !item.expenses.isEmpty || !item.gifts.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("LINKED ITEMS")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                            
                            VStack(spacing: 4) {
                                ForEach(item.expenses.prefix(2), id: \.id) { expense in
                                    HStack(spacing: 6) {
                                        Image(systemName: "creditcard.fill")
                                            .font(.caption2)
                                            .foregroundColor(AppColors.Budget.allocated)
                                        Text(expense.title)
                                            .font(.caption)
                                            .lineLimit(1)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, 4)
                                    .background(AppColors.Budget.allocated.opacity(0.1))
                                    .cornerRadius(4)
                                }
                                
                                ForEach(item.gifts.prefix(2), id: \.id) { gift in
                                    HStack(spacing: 6) {
                                        Image(systemName: "gift.fill")
                                            .font(.caption2)
                                            .foregroundColor(AppColors.Budget.income)
                                        Text(gift.title)
                                            .font(.caption)
                                            .lineLimit(1)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, 4)
                                    .background(AppColors.Budget.income.opacity(0.1))
                                    .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private func compactFolderRow(_ folder: BudgetOverviewItem) -> some View {
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
                HStack(spacing: Spacing.sm) {
                    // Chevron
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    
                    // Folder icon with badge
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        
                        Text("\(children.count)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(3)
                            .background(Circle().fill(Color.orange))
                            .offset(x: 6, y: -6)
                    }
                    
                    // Folder name
                    Text(folder.itemName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Budgeted
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(totals.budgeted, specifier: "%.0f")")
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                        Text("budgeted")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 70)
                    
                    // Spent
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(totals.effectiveSpent, specifier: "%.0f")")
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                        Text("spent")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 70)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
                .background(Color.orange.opacity(0.1))
            }
            .buttonStyle(.plain)
            
            // Child items (shown when expanded)
            if isExpanded {
                ForEach(children) { child in
                    VStack(spacing: 0) {
                        HStack(spacing: Spacing.sm) {
                            Spacer().frame(width: 32) // Indent
                            compactItemRow(child)
                        }
                        Divider()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
    
    // MARK: - Regular Table View (Full Columns)
    
    private var regularTableView: some View {
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
