//
//  BouquetLegendView.swift
//  I Do Blueprint
//
//  Legend sidebar component for the Budget Bouquet visualization
//  Shows category colors, spending status indicators, and petal size guide
//

import SwiftUI

// MARK: - Main Legend View

struct BouquetLegendView: View {
    let categories: [BudgetCategory]
    let totalBudget: Double
    @Binding var hoveredCategoryId: UUID?
    @Binding var selectedCategoryId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            legendHeader

            // Category list
            categoryList

            Divider()
                .padding(.vertical, Spacing.sm)

            // Spending status legend
            spendingStatusLegend

            Divider()
                .padding(.vertical, Spacing.sm)

            // Petal size guide
            petalSizeGuide
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Header

    private var legendHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Budget Legend")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)

            Text("\(categories.count) categories")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textSecondary)
        }
    }

    // MARK: - Category List

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Categories")
                .font(Typography.subheading)
                .foregroundColor(SemanticColors.textSecondary)

            ForEach(categoriesSortedByAmount) { category in
                CategoryLegendRow(
                    category: category,
                    totalBudget: totalBudget,
                    isHovered: hoveredCategoryId == category.id,
                    isSelected: selectedCategoryId == category.id
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if selectedCategoryId == category.id {
                            selectedCategoryId = nil
                        } else {
                            selectedCategoryId = category.id
                        }
                    }
                }
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        hoveredCategoryId = hovering ? category.id : nil
                    }
                }
            }
        }
    }

    // MARK: - Spending Status Legend

    private var spendingStatusLegend: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Spending Status")
                .font(Typography.subheading)
                .foregroundColor(SemanticColors.textSecondary)

            ForEach(BouquetSpendingStatus.allCases, id: \.self) { status in
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(status.color)
                        .frame(width: 10, height: 10)

                    Text(status.label)
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.textPrimary)

                    Spacer()
                }
            }
        }
    }

    // MARK: - Petal Size Guide

    private var petalSizeGuide: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Petal Size")
                .font(Typography.subheading)
                .foregroundColor(SemanticColors.textSecondary)

            Text("Larger petals represent higher budget allocations")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            // Visual scale
            HStack(spacing: Spacing.md) {
                petalScaleItem(size: .small, label: "Low")
                petalScaleItem(size: .medium, label: "Med")
                petalScaleItem(size: .large, label: "High")
            }
            .padding(.top, Spacing.xs)
        }
    }

    @ViewBuilder
    private func petalScaleItem(size: PetalScaleSize, label: String) -> some View {
        VStack(spacing: Spacing.xxs) {
            // Mini petal representation
            Capsule()
                .fill(SemanticColors.primaryAction.opacity(0.6))
                .frame(width: size.width, height: size.height)

            Text(label)
                .font(Typography.caption2)
                .foregroundColor(SemanticColors.textTertiary)
        }
    }

    // MARK: - Helpers

    private var categoriesSortedByAmount: [BudgetCategory] {
        categories.sorted { $0.allocatedAmount > $1.allocatedAmount }
    }
}

// MARK: - Petal Scale Size

private enum PetalScaleSize {
    case small, medium, large

    var width: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        }
    }

    var height: CGFloat {
        switch self {
        case .small: return 20
        case .medium: return 32
        case .large: return 44
        }
    }
}

// MARK: - Category Legend Row

struct CategoryLegendRow: View {
    let category: BudgetCategory
    let totalBudget: Double
    let isHovered: Bool
    let isSelected: Bool

    private var percentage: Double {
        guard totalBudget > 0 else { return 0 }
        return (category.allocatedAmount / totalBudget) * 100
    }

    private var spendingStatus: BouquetSpendingStatus {
        BouquetSpendingStatus.from(category: category)
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Color indicator
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.fromHex(category.color))
                .frame(width: 4, height: 32)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Category name with status dot
                HStack(spacing: Spacing.xs) {
                    Text(category.categoryName)
                        .font(Typography.bodyRegular)
                        .foregroundColor(SemanticColors.textPrimary)
                        .lineLimit(1)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(SemanticColors.primaryAction)
                    }
                }

                // Budget amount and percentage
                HStack(spacing: Spacing.xs) {
                    Text(formatCurrency(category.allocatedAmount))
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textSecondary)

                    Text("(\(Int(percentage))%)")
                        .font(Typography.caption2)
                        .foregroundColor(SemanticColors.textTertiary)
                }
            }

            Spacer()

            // Status indicator
            Circle()
                .fill(spendingStatus.color)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(
                    isSelected
                        ? SemanticColors.primaryActionLight
                        : (isHovered ? SemanticColors.hover : Color.clear)
                )
        )
        .contentShape(Rectangle())
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Spending Status Extension

extension BouquetSpendingStatus: CaseIterable {
    static var allCases: [BouquetSpendingStatus] {
        [.underBudget, .onTrack, .overBudget, .notStarted]
    }
}

// MARK: - Preview

#Preview("Budget Legend") {
    BouquetLegendView(
        categories: [
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Venue",
                allocatedAmount: 15000,
                spentAmount: 12000,
                priorityLevel: 1,
                isEssential: true,
                forecastedAmount: 15000,
                confidenceLevel: 0.9,
                lockedAllocation: false,
                color: "#EF2A78",
                createdAt: Date()
            ),
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Photography",
                allocatedAmount: 5000,
                spentAmount: 2500,
                priorityLevel: 2,
                isEssential: true,
                forecastedAmount: 5000,
                confidenceLevel: 0.8,
                lockedAllocation: false,
                color: "#83A276",
                createdAt: Date()
            ),
            BudgetCategory(
                id: UUID(),
                coupleId: UUID(),
                categoryName: "Catering",
                allocatedAmount: 8000,
                spentAmount: 9000,
                priorityLevel: 1,
                isEssential: true,
                forecastedAmount: 8500,
                confidenceLevel: 0.7,
                lockedAllocation: false,
                color: "#8F24F5",
                createdAt: Date()
            )
        ],
        totalBudget: 28000,
        hoveredCategoryId: .constant(nil),
        selectedCategoryId: .constant(nil)
    )
    .frame(width: 280)
    .padding()
    .background(SemanticColors.backgroundPrimary)
}
