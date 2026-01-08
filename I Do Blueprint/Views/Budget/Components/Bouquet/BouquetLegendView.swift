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
    let categories: [BouquetCategoryData]
    let totalBudget: Double
    @Binding var hoveredCategoryId: String?
    @Binding var selectedCategoryId: String?

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
            
            // Progress fill guide
            progressFillGuide
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

            ForEach(categories) { category in
                CategoryLegendRowV2(
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

            ForEach(SpendingStatusType.allCases, id: \.self) { status in
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
    
    // MARK: - Progress Fill Guide
    
    private var progressFillGuide: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Progress Fill")
                .font(Typography.subheading)
                .foregroundColor(SemanticColors.textSecondary)

            Text("Darker fill shows how much has been spent")
                .font(Typography.caption)
                .foregroundColor(SemanticColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)

            // Visual example
            HStack(spacing: Spacing.md) {
                progressFillExample(progress: 0.25, label: "25%")
                progressFillExample(progress: 0.50, label: "50%")
                progressFillExample(progress: 0.75, label: "75%")
                progressFillExample(progress: 1.0, label: "100%")
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
    
    @ViewBuilder
    private func progressFillExample(progress: Double, label: String) -> some View {
        VStack(spacing: Spacing.xxs) {
            ZStack(alignment: .bottom) {
                // Background
                Capsule()
                    .fill(SemanticColors.primaryAction.opacity(0.3))
                    .frame(width: 12, height: 36)
                
                // Fill
                Capsule()
                    .fill(SemanticColors.primaryAction)
                    .frame(width: 12, height: 36 * progress)
            }

            Text(label)
                .font(Typography.caption2)
                .foregroundColor(SemanticColors.textTertiary)
        }
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

// MARK: - Spending Status Type

private enum SpendingStatusType: CaseIterable {
    case underBudget
    case onTrack
    case overBudget
    case notStarted
    
    var label: String {
        switch self {
        case .underBudget: return "Under Budget"
        case .onTrack: return "On Track"
        case .overBudget: return "Over Budget"
        case .notStarted: return "Not Started"
        }
    }
    
    var color: Color {
        switch self {
        case .underBudget: return SemanticColors.statusSuccess
        case .onTrack: return SemanticColors.statusPending
        case .overBudget: return SemanticColors.statusWarning
        case .notStarted: return SemanticColors.textTertiary
        }
    }
}

// MARK: - Category Legend Row V2

struct CategoryLegendRowV2: View {
    let category: BouquetCategoryData
    let totalBudget: Double
    let isHovered: Bool
    let isSelected: Bool

    private var percentage: Double {
        guard totalBudget > 0 else { return 0 }
        return (category.totalBudgeted / totalBudget) * 100
    }

    private var statusColor: Color {
        if category.isOverBudget {
            return SemanticColors.statusWarning
        } else if category.progressRatio >= 0.9 {
            return SemanticColors.statusPending
        } else if category.progressRatio > 0 {
            return SemanticColors.statusSuccess
        } else {
            return SemanticColors.textTertiary
        }
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Color indicator
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(category.color)
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
                    Text(formatCurrency(category.totalBudgeted))
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
                .fill(statusColor)
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

// MARK: - Preview

#Preview("Budget Legend") {
    let provider = BouquetDataProvider.preview()
    
    return BouquetLegendView(
        categories: provider.categories,
        totalBudget: provider.totalBudgeted,
        hoveredCategoryId: .constant(nil),
        selectedCategoryId: .constant(nil)
    )
    .frame(width: 280)
    .padding()
    .background(SemanticColors.backgroundPrimary)
}
