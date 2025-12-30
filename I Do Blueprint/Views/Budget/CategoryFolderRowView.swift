//
//  CategoryFolderRowView.swift
//  I Do Blueprint
//
//  Row view for parent category folders
//

import SwiftUI

struct CategoryFolderRowView: View {
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

    var body: some View {
        HStack(spacing: 12) {
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
                            .frame(width: 100)

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
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture {
            // Toggle expansion when clicking anywhere except the menu
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
