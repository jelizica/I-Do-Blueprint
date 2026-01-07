//
//  CategorySectionViewV2.swift
//  I Do Blueprint
//
//  Responsive section view for displaying a parent category with its subcategories
//  Supports compact window layouts (640-700px width)
//

import SwiftUI

struct CategorySectionViewV2: View {
    let windowSize: WindowSize
    let parentCategory: BudgetCategory
    let subcategories: [BudgetCategory]
    let budgetStore: BudgetStoreV2
    let spentByCategory: [UUID: Double] // Pre-computed spent amounts for O(1) lookup
    let onEdit: (BudgetCategory) -> Void
    let onDelete: (BudgetCategory) -> Void
    let onMove: (BudgetCategory) -> Void
    @Binding var isExpanded: Bool

    // Parent categories should only show sum of subcategories (not their own allocated amount)
    // Uses pre-computed dictionary for O(1) lookups instead of O(n) per subcategory
    private var totalSpent: Double {
        subcategories.reduce(0) { total, subcategory in
            total + (spentByCategory[subcategory.id] ?? 0)
        }
    }

    private var totalBudgeted: Double {
        subcategories.reduce(0) { total, subcategory in
            total + subcategory.allocatedAmount
        }
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
                    subcategoryCount: subcategories.count,
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

                // Subcategories - use pre-computed spent amounts for O(1) lookup
                if isExpanded {
                    VStack(spacing: Spacing.xs) {
                        ForEach(subcategories, id: \.id) { subcategory in
                            CategoryRowViewV2(
                                windowSize: windowSize,
                                category: subcategory,
                                spentAmount: spentByCategory[subcategory.id] ?? 0,
                                budgetStore: budgetStore,
                                onEdit: onEdit,
                                onDelete: onDelete,
                                onMove: onMove
                            )
                            .padding(.horizontal, sectionPadding)
                            .padding(.vertical, Spacing.xs)
                            .padding(.leading, windowSize == .compact ? Spacing.lg : Spacing.xl)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                            )
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
}
