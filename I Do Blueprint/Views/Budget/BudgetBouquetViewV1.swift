//
//  BudgetBouquetViewV1.swift
//  I Do Blueprint
//
//  Budget Bouquet View - A flower-based visualization for budget categories
//  Each petal represents a budget category with:
//  - Petal size = budget amount (larger = higher allocation)
//  - Petal color = category type
//  - Opacity/glow = spending status (under budget, on track, over budget)
//
//  Alternative to the card-based BudgetDashboardViewV1
//

import SwiftUI

// MARK: - Main View

struct BudgetBouquetViewV1: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @EnvironmentObject var settingsStore: SettingsStoreV2

    /// Binding to parent's currentPage for unified header navigation
    var externalCurrentPage: Binding<BudgetPage>?

    @State private var internalCurrentPage: BudgetPage = .dashboardV1

    private var currentPage: Binding<BudgetPage> {
        externalCurrentPage ?? $internalCurrentPage
    }

    /// Convenience initializer with external binding
    init(currentPage: Binding<BudgetPage>) {
        self.externalCurrentPage = currentPage
    }

    /// Default initializer for standalone usage
    init() {
        self.externalCurrentPage = nil
    }

    // MARK: - State

    @State private var hoveredCategoryId: UUID?
    @State private var selectedCategoryId: UUID?
    @State private var animateFlower: Bool = false

    // MARK: - Computed Properties

    private var categories: [BudgetCategory] {
        budgetStore.categoryStore.categories
    }

    private var totalBudget: Double {
        categories.reduce(0) { $0 + $1.allocatedAmount }
    }

    private var totalSpent: Double {
        categories.reduce(0) { $0 + $1.spentAmount }
    }

    private var totalRemaining: Double {
        totalBudget - totalSpent
    }

    private var overallProgress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(1.0, totalSpent / totalBudget)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl

            VStack(spacing: 0) {
                // Header
                bouquetHeader(windowSize: windowSize)

                // Main content
                ScrollView {
                    mainContent(windowSize: windowSize, geometry: geometry)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, Spacing.lg)
                }
            }
            .background(SemanticColors.backgroundPrimary)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                animateFlower = true
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func bouquetHeader(windowSize: WindowSize) -> some View {
        HStack(alignment: .center, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Budget")
                    .font(Typography.title2)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Budget Bouquet")
                    .font(Typography.subheading)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer()

            // Navigation dropdown to other budget pages
            Menu {
                ForEach(Array(BudgetPage.allCases), id: \.self) { page in
                    Button(page.rawValue) {
                        currentPage.wrappedValue = page
                    }
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Text("Navigate")
                        .font(Typography.bodyRegular)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(SemanticColors.textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(SemanticColors.controlBackground)
                .cornerRadius(CornerRadius.md)
            }
        }
        .padding(.horizontal, windowSize == .compact ? Spacing.lg : Spacing.xl)
        .padding(.vertical, Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
    }

    // MARK: - Main Content

    @ViewBuilder
    private func mainContent(windowSize: WindowSize, geometry: GeometryProxy) -> some View {
        let isCompact = windowSize == .compact

        if isCompact {
            // Stacked layout for compact windows
            VStack(spacing: Spacing.xl) {
                // Flower visualization takes full width
                flowerSection(geometry: geometry)
                    .frame(height: 400)

                // Legend below
                legendSection

                // Stats and alerts
                statsSection

                alertsSection
            }
        } else {
            // Three-column layout for larger windows
            HStack(alignment: .top, spacing: Spacing.xl) {
                // Left: Legend
                legendSection
                    .frame(width: 280)

                // Center: Flower visualization
                flowerSection(geometry: geometry)
                    .frame(maxWidth: .infinity)

                // Right: Stats & Alerts
                VStack(spacing: Spacing.lg) {
                    statsSection
                    alertsSection
                }
                .frame(width: 300)
            }
            .frame(minHeight: 500)
        }
    }

    // MARK: - Flower Section

    @ViewBuilder
    private func flowerSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: Spacing.lg) {
            Text("Your Budget Bouquet")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)

            BouquetFlowerView(
                categories: categories,
                totalBudget: totalBudget,
                hoveredCategoryId: $hoveredCategoryId,
                selectedCategoryId: $selectedCategoryId,
                animateFlower: animateFlower
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Selected category details
            if let selectedId = selectedCategoryId,
               let category = categories.first(where: { $0.id == selectedId }) {
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
            categories: categories,
            totalBudget: totalBudget,
            hoveredCategoryId: $hoveredCategoryId,
            selectedCategoryId: $selectedCategoryId
        )
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        BouquetQuickStatsView(
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            totalRemaining: totalRemaining,
            overallProgress: overallProgress,
            categories: categories
        )
    }

    // MARK: - Alerts Section

    private var alertsSection: some View {
        BouquetAlertsView(categories: categories)
    }

    // MARK: - Selected Category Detail

    @ViewBuilder
    private func selectedCategoryDetail(category: BudgetCategory) -> some View {
        HStack(spacing: Spacing.lg) {
            // Category color indicator
            Circle()
                .fill(Color.fromHex(category.color))
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(category.categoryName)
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("\(formatCurrency(category.spentAmount)) of \(formatCurrency(category.allocatedAmount))")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Spacer()

            // Spending status badge
            spendingStatusBadge(for: category)

            Button {
                selectedCategoryId = nil
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

    // MARK: - Helpers

    @ViewBuilder
    private func spendingStatusBadge(for category: BudgetCategory) -> some View {
        let status = BouquetSpendingStatus.from(category: category)

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

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    private func loadData() async {
        // Data is already loaded via BudgetStoreV2 environment object
        // This is a hook for any additional data loading if needed
    }
}

// MARK: - Spending Status

enum BouquetSpendingStatus {
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

    static func from(category: BudgetCategory) -> BouquetSpendingStatus {
        guard category.allocatedAmount > 0 else { return .notStarted }

        let percentSpent = category.percentageSpent

        if category.spentAmount == 0 {
            return .notStarted
        } else if category.isOverBudget {
            return .overBudget
        } else if percentSpent >= 80 {
            return .onTrack
        } else {
            return .underBudget
        }
    }
}

// MARK: - Preview

#Preview {
    BudgetBouquetViewV1()
        .environmentObject(BudgetStoreV2())
        .environmentObject(SettingsStoreV2())
        .frame(width: 1200, height: 800)
}
