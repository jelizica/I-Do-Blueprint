//
//  CategoryFolderRowViewV2.swift
//  I Do Blueprint
//
//  Responsive row view for parent category folders
//  Supports compact window layouts (640-700px width)
//

import SwiftUI

struct CategoryFolderRowViewV2: View {
    let windowSize: WindowSize
    let category: BudgetCategory
    let subcategoryCount: Int
    let totalSpent: Double
    let totalBudgeted: Double
    @Binding var isExpanded: Bool
    let budgetStore: BudgetStoreV2
    let onEdit: (BudgetCategory) -> Void
    let onDelete: (BudgetCategory) -> Void

    private var utilizationPercentage: Double {
        totalBudgeted > 0 ? (totalSpent / totalBudgeted) * 100 : 0
    }

    private var statusColor: Color {
        if utilizationPercentage > 100 {
            AppColors.Budget.overBudget
        } else if utilizationPercentage > 80 {
            AppColors.Budget.pending
        } else {
            AppColors.Budget.underBudget
        }
    }
    
    // Responsive sizing
    private var iconSize: CGFloat {
        windowSize == .compact ? 14 : 16
    }
    
    private var progressBarWidth: CGFloat {
        windowSize == .compact ? 80 : 100
    }

    var body: some View {
        if windowSize == .compact {
            compactLayout
        } else {
            regularLayout
        }
    }
    
    // MARK: - Compact Layout
    
    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Top row: Chevron, Icon, Name, Menu
            HStack(spacing: Spacing.sm) {
                // Expansion chevron
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .frame(width: 12)

                // Folder icon
                Image(systemName: "folder.fill")
                    .font(.system(size: iconSize))
                    .foregroundColor(Color(hex: category.color) ?? AppColors.Budget.allocated)

                // Category name and count
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.categoryName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text("(\(subcategoryCount) subcategories)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Actions menu
                CategoryActionsMenu(
                    category: category,
                    budgetStore: budgetStore,
                    onEdit: onEdit,
                    onDelete: onDelete
                )
            }
            
            // Bottom row: Budget info and progress
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Budget amounts
                HStack(spacing: Spacing.xs) {
                    Text(NumberFormatter.currencyShort.string(from: NSNumber(value: totalSpent)) ?? "$0")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                    
                    Text("of")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(NumberFormatter.currencyShort.string(from: NSNumber(value: totalBudgeted)) ?? "$0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Progress bar
                if totalBudgeted > 0 {
                    HStack(spacing: Spacing.xs) {
                        ProgressView(value: min(utilizationPercentage / 100, 1.0))
                            .progressViewStyle(LinearProgressViewStyle(tint: statusColor))
                            .frame(maxWidth: .infinity)

                        Text("\(Int(utilizationPercentage))%")
                            .font(.caption2)
                            .foregroundColor(statusColor)
                            .fontWeight(.medium)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
            .padding(.leading, 24) // Align with name (chevron + icon + spacing)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded.toggle()
        }
    }
    
    // MARK: - Regular Layout
    
    private var regularLayout: some View {
        HStack(spacing: Spacing.md) {
            // Expansion chevron
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 12)

            // Folder icon
            Image(systemName: "folder.fill")
                .font(.body)
                .foregroundColor(Color(hex: category.color) ?? AppColors.Budget.allocated)

            // Category details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category.categoryName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("(\(subcategoryCount) subcategories)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let description = category.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Budget progress
                if totalBudgeted > 0 {
                    HStack(spacing: 8) {
                        ProgressView(value: min(utilizationPercentage / 100, 1.0))
                            .progressViewStyle(LinearProgressViewStyle(tint: statusColor))
                            .frame(width: progressBarWidth)

                        Text("\(Int(utilizationPercentage))%")
                            .font(.caption2)
                            .foregroundColor(statusColor)
                            .fontWeight(.medium)
                    }
                }
            }

            Spacer()

            // Budget information (sum of subcategories)
            VStack(alignment: .trailing, spacing: 2) {
                Text(NumberFormatter.currencyShort.string(from: NSNumber(value: totalSpent)) ?? "$0")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)

                Text("of \(NumberFormatter.currencyShort.string(from: NSNumber(value: totalBudgeted)) ?? "$0")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Actions menu
            CategoryActionsMenu(
                category: category,
                budgetStore: budgetStore,
                onEdit: onEdit,
                onDelete: onDelete
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded.toggle()
        }
    }
}

// MARK: - Actions Menu

private struct CategoryActionsMenu: View {
    let category: BudgetCategory
    let budgetStore: BudgetStoreV2
    let onEdit: (BudgetCategory) -> Void
    let onDelete: (BudgetCategory) -> Void

    var body: some View {
        Menu {
            Button("Edit") {
                onEdit(category)
            }

            Button("Duplicate") {
                duplicateCategory()
            }

            Divider()

            Button("Delete", role: .destructive) {
                onDelete(category)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.secondary)
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .highPriorityGesture(TapGesture().onEnded { _ in
            // Intentionally no-op: consumes tap to prevent parent expansion
        })
    }

    private func duplicateCategory() {
        guard let coupleId = SessionManager.shared.getTenantId() else {
            return
        }

        let duplicatedCategory = BudgetCategory(
            id: UUID(),
            coupleId: coupleId,
            categoryName: "Copy of \(category.categoryName)",
            parentCategoryId: category.parentCategoryId,
            allocatedAmount: category.allocatedAmount,
            spentAmount: 0.0, // Reset spent amount for new category
            typicalPercentage: category.typicalPercentage,
            priorityLevel: category.priorityLevel,
            isEssential: category.isEssential,
            notes: category.notes,
            forecastedAmount: category.forecastedAmount,
            confidenceLevel: category.confidenceLevel,
            lockedAllocation: category.lockedAllocation,
            description: category.description,
            createdAt: Date(),
            updatedAt: nil
        )

        Task {
            do {
                _ = try await budgetStore.categoryStore.addCategory(duplicatedCategory)
            } catch {
                AppLogger.ui.error("Failed to duplicate category", error: error)
            }
        }
    }
}
