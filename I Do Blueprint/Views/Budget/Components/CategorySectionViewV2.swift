//
//  CategorySectionViewV2.swift
//  I Do Blueprint
//
//  Responsive section view for displaying a parent category with its subcategories
//  Supports compact window layouts (640-700px width)
//  Updated 2026-01-07: Added N-level hierarchy support for nested folders
//

import SwiftUI

struct CategorySectionViewV2: View {
    let windowSize: WindowSize
    let parentCategory: BudgetCategory
    let subcategories: [BudgetCategory]
    let budgetStore: BudgetStoreV2
    let spentByCategory: [UUID: Double] // Pre-computed spent amounts for O(1) lookup
    let allSubcategoriesByParent: [UUID: [BudgetCategory]] // Full hierarchy for recursive rendering
    let onEdit: (BudgetCategory) -> Void
    let onDelete: (BudgetCategory) -> Void
    let onMove: (BudgetCategory) -> Void
    @Binding var isExpanded: Bool

    // Track expanded state for nested folders
    @State private var expandedNestedFolders: Set<UUID> = []

    // Parent categories should only show sum of ALL descendants (recursive)
    // Uses pre-computed dictionary for O(1) lookups instead of O(n) per subcategory
    private var totalSpent: Double {
        calculateTotalSpentRecursive(for: parentCategory.id)
    }

    private func calculateTotalSpentRecursive(for categoryId: UUID) -> Double {
        let directChildren = allSubcategoriesByParent[categoryId] ?? []
        var total: Double = 0
        for child in directChildren {
            // Add this child's spent amount
            total += spentByCategory[child.id] ?? 0
            // Recursively add grandchildren's spent amounts
            total += calculateTotalSpentRecursive(for: child.id)
        }
        return total
    }

    private var totalBudgeted: Double {
        calculateTotalBudgetedRecursive(for: parentCategory.id)
    }

    private func calculateTotalBudgetedRecursive(for categoryId: UUID) -> Double {
        let directChildren = allSubcategoriesByParent[categoryId] ?? []
        var total: Double = 0
        for child in directChildren {
            // Only count leaf nodes (categories without children) to avoid double-counting
            let hasGrandchildren = allSubcategoriesByParent[child.id] != nil
            if !hasGrandchildren {
                total += child.allocatedAmount
            }
            // Recursively add grandchildren's budgets
            total += calculateTotalBudgetedRecursive(for: child.id)
        }
        return total
    }

    // Responsive padding based on window size
    private var sectionPadding: CGFloat {
        windowSize == .compact ? Spacing.md : Spacing.lg
    }

    private var sectionSpacing: CGFloat {
        windowSize == .compact ? Spacing.sm : Spacing.md
    }

    /// Check if this is a leaf category (no subcategories)
    private var isLeafCategory: Bool {
        subcategories.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // For leaf categories (no children), show as a regular row, not a folder
            if isLeafCategory {
                // Leaf category - show as regular row without folder icon or chevron
                CategoryRowViewV2(
                    windowSize: windowSize,
                    category: parentCategory,
                    spentAmount: spentByCategory[parentCategory.id] ?? 0,
                    budgetStore: budgetStore,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onMove: onMove
                )
                .padding(.horizontal, sectionPadding)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            } else {
                // Parent category with children (folder) - clickable to expand/collapse
                CategoryFolderRowViewV2(
                    windowSize: windowSize,
                    category: parentCategory,
                    subcategoryCount: countAllDescendants(of: parentCategory.id),
                    totalSpent: totalSpent,
                    totalBudgeted: totalBudgeted,
                    isExpanded: $isExpanded,
                    budgetStore: budgetStore,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onMove: onMove
                )
                .padding(.horizontal, sectionPadding)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )

                // Subcategories - recursively render nested folders
                if isExpanded {
                    VStack(spacing: Spacing.xs) {
                        ForEach(subcategories, id: \.id) { subcategory in
                            recursiveChildRow(for: subcategory, indentLevel: 1)
                        }
                    }
                    .padding(.top, Spacing.xs)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    // MARK: - Recursive Rendering

    /// Count all descendants recursively
    private func countAllDescendants(of categoryId: UUID) -> Int {
        let directChildren = allSubcategoriesByParent[categoryId] ?? []
        var count = directChildren.count
        for child in directChildren {
            count += countAllDescendants(of: child.id)
        }
        return count
    }

    /// Recursive child row - renders folders or leaf items with proper indentation
    /// Uses AnyView for type erasure to support recursive calls
    private func recursiveChildRow(for category: BudgetCategory, indentLevel: Int) -> AnyView {
        let children = allSubcategoriesByParent[category.id] ?? []
        let hasChildren = !children.isEmpty
        let isNestedExpanded = expandedNestedFolders.contains(category.id)
        let indentAmount = CGFloat(indentLevel) * (windowSize == .compact ? Spacing.lg : Spacing.xl)

        return AnyView(
            VStack(spacing: Spacing.xs) {
                if hasChildren {
                    // This subcategory is itself a folder - show as nested folder
                    NestedFolderRowView(
                        windowSize: windowSize,
                        category: category,
                        childCount: countAllDescendants(of: category.id),
                        totalSpent: calculateTotalSpentRecursive(for: category.id),
                        totalBudgeted: calculateTotalBudgetedRecursive(for: category.id),
                        isExpanded: Binding(
                            get: { expandedNestedFolders.contains(category.id) },
                            set: { newValue in
                                if newValue {
                                    expandedNestedFolders.insert(category.id)
                                } else {
                                    expandedNestedFolders.remove(category.id)
                                }
                            }
                        ),
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onMove: onMove
                    )
                    .padding(.horizontal, sectionPadding)
                    .padding(.vertical, Spacing.xs)
                    .padding(.leading, indentAmount)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    )

                    // Recursively show children if expanded
                    if isNestedExpanded {
                        ForEach(children, id: \.id) { child in
                            recursiveChildRow(for: child, indentLevel: indentLevel + 1)
                        }
                    }
                } else {
                    // Leaf category - show as regular row
                    CategoryRowViewV2(
                        windowSize: windowSize,
                        category: category,
                        spentAmount: spentByCategory[category.id] ?? 0,
                        budgetStore: budgetStore,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onMove: onMove
                    )
                    .padding(.horizontal, sectionPadding)
                    .padding(.vertical, Spacing.xs)
                    .padding(.leading, indentAmount)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    )
                }
            }
        )
    }
}

// MARK: - Nested Folder Row View

/// A simplified folder row for nested folders (not top-level)
private struct NestedFolderRowView: View {
    let windowSize: WindowSize
    let category: BudgetCategory
    let childCount: Int
    let totalSpent: Double
    let totalBudgeted: Double
    @Binding var isExpanded: Bool
    let onEdit: (BudgetCategory) -> Void
    let onDelete: (BudgetCategory) -> Void
    let onMove: (BudgetCategory) -> Void

    private var categoryColor: Color {
        Color(hex: category.color) ?? AppColors.Budget.allocated
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Expand/collapse button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
            }
            .buttonStyle(.plain)

            // Folder icon
            Image(systemName: "folder.fill")
                .foregroundColor(categoryColor)
                .font(.body)

            // Category name and child count
            VStack(alignment: .leading, spacing: 2) {
                Text(category.categoryName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(childCount) item\(childCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Budget info
            if totalBudgeted > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(NumberFormatter.currencyShort.string(from: NSNumber(value: totalSpent)) ?? "$0")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("of \(NumberFormatter.currencyShort.string(from: NSNumber(value: totalBudgeted)) ?? "$0")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Actions menu
            Menu {
                Button {
                    onEdit(category)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button {
                    onMove(category)
                } label: {
                    Label("Move to Folder", systemImage: "folder.badge.plus")
                }

                Divider()

                Button(role: .destructive) {
                    onDelete(category)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }
}
