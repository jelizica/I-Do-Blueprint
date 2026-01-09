//
//  BouquetContentView.swift
//  I Do Blueprint
//
//  Reusable bouquet content component that displays the full bouquet layout:
//  - Left: Legend sidebar (categories, spending status, petal size guide)
//  - Center: Flower visualization with petal tap interaction
//  - Right: Quick stats and alerts
//
//  This component is used by:
//  - BudgetBouquetViewV1 (standalone page)
//  - BudgetOverviewItemsSection (embedded in toggle view)
//

import SwiftUI

// MARK: - Bouquet Content View

/// A reusable view that displays the complete bouquet visualization with legend, flower, and stats.
/// Can be embedded in different contexts (standalone page or toggle view).
struct BouquetContentView: View {
    // MARK: - Properties
    
    /// Data provider containing category information
    @ObservedObject var dataProvider: BouquetDataProvider
    
    /// Current window size for responsive layout
    let windowSize: WindowSize
    
    /// Callback when a petal is tapped (for navigation to detail view)
    var onPetalTap: ((BouquetCategoryData) -> Void)?
    
    // MARK: - State
    
    @State private var hoveredCategoryId: String?
    @State private var selectedCategoryId: String?
    @State private var animateFlower: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if dataProvider.categories.isEmpty {
                emptyStateView
            } else {
                mainContent
            }
        }
        .onAppear {
            // Delay animation start slightly for smoother appearance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateFlower = true
                }
            }
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        let isCompact = windowSize == .compact
        
        if isCompact {
            compactLayout
        } else {
            wideLayout
        }
    }
    
    // MARK: - Compact Layout (Stacked)
    
    private var compactLayout: some View {
        VStack(spacing: Spacing.xl) {
            // Flower visualization takes full width
            flowerSection
                .frame(height: 500)
            
            // Legend below
            legendSection
            
            // Stats and alerts
            statsSection
            
            alertsSection
        }
    }
    
    // MARK: - Wide Layout (Three Columns)
    
    private var wideLayout: some View {
        HStack(alignment: .top, spacing: Spacing.xl) {
            // Left: Legend
            legendSection
                .frame(width: 280)
            
            // Center: Flower visualization
            flowerSection
                .frame(maxWidth: .infinity)
            
            // Right: Stats & Alerts
            VStack(spacing: Spacing.lg) {
                statsSection
                alertsSection
            }
            .frame(width: 300)
        }
        .frame(minHeight: 600)
    }
    
    // MARK: - Flower Section
    
    @ViewBuilder
    private var flowerSection: some View {
        let centerHubRadius: CGFloat = 60
        let maxPetalLength: CGFloat = 140
        let stemAndPotHeight: CGFloat = 250
        let totalFlowerHeight = Spacing.lg + maxPetalLength + centerHubRadius + stemAndPotHeight + Spacing.lg
        
        VStack(spacing: Spacing.md) {
            BouquetFlowerView(
                categories: dataProvider.categories,
                totalBudget: dataProvider.totalBudgeted,
                hoveredCategoryId: $hoveredCategoryId,
                selectedCategoryId: $selectedCategoryId,
                animateFlower: animateFlower,
                onPetalTap: { category in
                    onPetalTap?(category)
                }
            )
            .frame(height: totalFlowerHeight)
            
            // Selected category details (shown when a category is selected via legend)
            if let selectedId = selectedCategoryId,
               let category = dataProvider.categories.first(where: { $0.id == selectedId }) {
                selectedCategoryDetail(category: category)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
    }
    
    // MARK: - Legend Section
    
    private var legendSection: some View {
        BouquetLegendView(
            categories: dataProvider.categories,
            totalBudget: dataProvider.totalBudgeted,
            hoveredCategoryId: $hoveredCategoryId,
            selectedCategoryId: $selectedCategoryId
        )
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        BouquetQuickStatsView(
            totalBudget: dataProvider.totalBudgeted,
            totalSpent: dataProvider.totalSpent,
            totalRemaining: dataProvider.totalBudgeted - dataProvider.totalSpent,
            overallProgress: dataProvider.overallProgress,
            categories: dataProvider.categories
        )
    }
    
    // MARK: - Alerts Section
    
    private var alertsSection: some View {
        BouquetAlertsView(categories: dataProvider.categories)
    }
    
    // MARK: - Selected Category Detail
    
    @ViewBuilder
    private func selectedCategoryDetail(category: BouquetCategoryData) -> some View {
        HStack(spacing: Spacing.lg) {
            // Category color indicator
            Circle()
                .fill(category.color)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(category.categoryName)
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text("\(formatCurrency(category.totalSpent)) of \(formatCurrency(category.totalBudgeted))")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
                
                Text("\(category.itemCount) item\(category.itemCount == 1 ? "" : "s")")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textTertiary)
            }
            
            Spacer()
            
            // Spending status badge
            spendingStatusBadge(for: category)
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedCategoryId = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(SemanticColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundTertiary)
        .cornerRadius(CornerRadius.md)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            // Decorative icon
            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            SemanticColors.primaryAction.opacity(0.6),
                            SemanticColors.primaryActionHover.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, Spacing.md)
            
            VStack(spacing: Spacing.sm) {
                Text("Your Budget Bouquet is Waiting to Bloom")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Add budget items to your categories to see your beautiful flower visualization grow.")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .padding(Spacing.xl)
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func spendingStatusBadge(for category: BouquetCategoryData) -> some View {
        let status = spendingStatus(for: category)
        
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(status.label)
                .font(Typography.caption)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(status.color.opacity(Opacity.verySubtle))
        .cornerRadius(CornerRadius.pill)
    }
    
    private func spendingStatus(for category: BouquetCategoryData) -> (label: String, color: Color) {
        if category.isOverBudget {
            return ("Over Budget", SemanticColors.statusWarning)
        } else if category.progressRatio >= 0.9 {
            return ("On Track", SemanticColors.statusPending)
        } else if category.progressRatio > 0 {
            return ("Under Budget", SemanticColors.statusSuccess)
        } else {
            return ("Not Started", SemanticColors.textTertiary)
        }
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

#Preview("Bouquet Content - Wide") {
    let provider = BouquetDataProvider.preview()
    
    return BouquetContentView(
        dataProvider: provider,
        windowSize: .large,
        onPetalTap: { category in
            print("Tapped: \(category.categoryName)")
        }
    )
    .frame(width: 1200, height: 700)
    .background(SemanticColors.backgroundPrimary)
}

#Preview("Bouquet Content - Compact") {
    let provider = BouquetDataProvider.preview()
    
    return ScrollView {
        BouquetContentView(
            dataProvider: provider,
            windowSize: .compact,
            onPetalTap: { category in
                print("Tapped: \(category.categoryName)")
            }
        )
    }
    .frame(width: 400, height: 800)
    .background(SemanticColors.backgroundPrimary)
}
