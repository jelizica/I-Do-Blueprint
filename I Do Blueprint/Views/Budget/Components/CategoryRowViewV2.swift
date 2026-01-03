//
//  CategoryRowViewV2.swift
//  I Do Blueprint
//
//  Responsive row view for subcategory items
//  Supports compact window layouts (640-700px width)
//

import SwiftUI

struct CategoryRowViewV2: View {
    let windowSize: WindowSize
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
    
    // Responsive sizing
    private var iconSize: CGFloat {
        windowSize == .compact ? 10 : 12
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
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Top row: Icon, Name, Menu
            HStack(spacing: Spacing.sm) {
                // Subcategory icon
                Image(systemName: "doc.text.fill")
                    .font(.system(size: iconSize))
                    .foregroundColor(Color(hex: category.color) ?? AppColors.Budget.allocated)
                    .frame(width: 12)

                // Category name
                Text(category.categoryName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
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
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .menuStyle(BorderlessButtonMenuStyle())
            }
            
            // Bottom row: Budget info and progress
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Budget amounts
                HStack(spacing: Spacing.xs) {
                    Text(NumberFormatter.currencyShort.string(from: NSNumber(value: spentAmount)) ?? "$0")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                    
                    Text("of")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(NumberFormatter.currencyShort.string(from: NSNumber(value: category.allocatedAmount)) ?? "$0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Progress bar
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
            .padding(.leading, 20) // Align with name (icon + spacing)
        }
        .contextMenu {
            Button("Edit") {
                onEdit(category)
            }

            Button("Delete", role: .destructive) {
                onDelete(category)
            }
        }
    }
    
    // MARK: - Regular Layout
    
    private var regularLayout: some View {
        HStack(spacing: Spacing.md) {
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
                        .frame(width: progressBarWidth)

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
