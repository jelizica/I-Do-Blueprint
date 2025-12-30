//
//  CategoryRowView.swift
//  I Do Blueprint
//
//  Row view for subcategory items
//

import SwiftUI

struct CategoryRowView: View {
    let category: BudgetCategory
    let spentAmount: Double
    let budgetStore: BudgetStoreV2
    let onEdit: (BudgetCategory) -> Void
    let onDelete: (BudgetCategory) -> Void

    private var utilizationPercentage: Double {
        category.allocatedAmount > 0 ? (spentAmount / category.allocatedAmount) * 100 : 0
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
            // Subcategory icon
            Image(systemName: "doc.text.fill")
                .font(.caption)
                .foregroundColor(Color(hex: category.color) ?? AppColors.Budget.allocated)
                .frame(width: 12)

            // Category details
            VStack(alignment: .leading, spacing: 4) {
                Text(category.categoryName)
                    .font(.caption)
                    .fontWeight(.medium)

                if let description = category.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Budget progress
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

            Spacer()

            // Budget information
            VStack(alignment: .trailing, spacing: 2) {
                Text(NumberFormatter.currencyShort.string(from: NSNumber(value: spentAmount)) ?? "$0")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)

                Text("of \(NumberFormatter.currencyShort.string(from: NSNumber(value: category.allocatedAmount)) ?? "$0")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Actions menu
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
        }
        .padding(.vertical, Spacing.xs)
        .contextMenu {
            Button("Edit") {
                onEdit(category)
            }

            Button("Delete", role: .destructive) {
                onDelete(category)
            }
        }
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
