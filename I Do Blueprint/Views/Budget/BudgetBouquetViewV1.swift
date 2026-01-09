//
//  BudgetBouquetViewV1.swift
//  I Do Blueprint
//
//  Budget Bouquet View - A flower-based visualization for budget categories
//  Each petal represents a budget category with:
//  - Petal size = budget amount (larger = higher allocation)
//  - Petal color = category type
//  - Progress fill = spending status (darker fill shows spent/budgeted ratio)
//
//  Data source: Budget development items grouped by category
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

    @StateObject private var dataProvider = BouquetDataProvider()
    @State private var hoveredCategoryId: String?
    @State private var selectedCategoryId: String?
    @State private var animateFlower: Bool = false
    @State private var isLoading: Bool = true

    /// Category selected for detail view navigation
    @State private var selectedCategoryForDetail: BouquetCategoryData?

    // MARK: - Computed Properties

    private var primaryScenarioId: String? {
        budgetStore.primaryScenario?.id.uuidString
    }

    private var hasData: Bool {
        dataProvider.hasData
    }

    // MARK: - Body

    var body: some View {
        Group {
            // Show category detail view if a category is selected for detail
            if let category = selectedCategoryForDetail {
                BudgetBouquetCategoryDetailView(
                    category: category,
                    allCategories: dataProvider.categories,
                    currentPage: currentPage,
                    onCategorySelected: { newCategory in
                        // Navigate to a different category's detail
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedCategoryForDetail = newCategory
                        }
                    },
                    onBackToBouquet: {
                        // Return to bouquet view
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedCategoryForDetail = nil
                        }
                    }
                )
            } else {
                // Show main bouquet view
                bouquetMainView
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
        .task {
            await loadData()
        }
    }

    // MARK: - Bouquet Main View

    @ViewBuilder
    private var bouquetMainView: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl

            VStack(spacing: 0) {
                // Header
                bouquetHeader(windowSize: windowSize)

                // Main content
                if isLoading {
                    loadingView
                } else if !hasData {
                    emptyStateView
                } else {
                    ScrollView {
                        mainContent(windowSize: windowSize, geometry: geometry)
                            .padding(.horizontal, horizontalPadding)
                            .padding(.top, Spacing.lg)
                    }
                }
            }
            .background(SemanticColors.backgroundPrimary)
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

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading budget data...")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View

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
                
                Text("Add budget items to your categories in the Budget Builder to see your beautiful flower visualization grow.")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            // Action button
            Button {
                // Navigate to budget builder
                currentPage.wrappedValue = .budgetBuilder
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                    Text("Go to Budget Builder")
                }
                .font(Typography.bodyRegular)
                .fontWeight(.medium)
                .foregroundColor(SemanticColors.textOnPrimary)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(
                    LinearGradient(
                        colors: [
                            SemanticColors.primaryAction,
                            SemanticColors.primaryActionHover
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(CornerRadius.lg)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
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
                    .frame(height: 500)

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
            .frame(minHeight: 600)
        }
    }

    // MARK: - Flower Section

    @ViewBuilder
    private func flowerSection(geometry: GeometryProxy) -> some View {
        // Calculate the height needed for the flower visualization
        // DEBUG: verify clicks reach the bouquet flower container at all.
        // If this prints but petals do not, hit-testing is failing at the petal level.
        // If this does NOT print, some higher-level overlay/gesture is swallowing clicks.
        let _ = { () -> Void in
            // no-op; keeps local debug intent close to the gesture below
        }()
        // Components: padding + maxPetalLength + centerHub + stem + leaves + pot + padding
        // Using approximate values that match BouquetFlowerView constants
        let centerHubRadius: CGFloat = 60
        let maxPetalLength: CGFloat = 140 // Approximate max petal length
        let stemAndPotHeight: CGFloat = 250 // Stem + leaves + pot
        let totalFlowerHeight = Spacing.lg + maxPetalLength + centerHubRadius + stemAndPotHeight + Spacing.lg
        
        VStack(spacing: Spacing.md) {
            BouquetFlowerView(
                categories: dataProvider.categories,
                totalBudget: dataProvider.totalBudgeted,
                hoveredCategoryId: $hoveredCategoryId,
                selectedCategoryId: $selectedCategoryId,
                animateFlower: animateFlower,
                onPetalTap: { category in
                    // Navigate to category detail view
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedCategoryForDetail = category
                    }
                }
            )
            .frame(height: totalFlowerHeight)

            // Selected category details
            if let selectedId = selectedCategoryId,
               let category = dataProvider.categories.first(where: { $0.id == selectedId }) {
                selectedCategoryDetail(category: category)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
        .onTapGesture {
            print("BOUQUET_CONTAINER_TAP")
        }
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

    private func loadData() async {
        isLoading = true
        
        // Get the primary scenario ID
        guard let scenarioId = primaryScenarioId else {
            isLoading = false
            return
        }
        
        // Load data from the budget development store
        await dataProvider.loadData(
            from: budgetStore.development,
            scenarioId: scenarioId
        )
        
        isLoading = false
    }
}

// MARK: - Preview

#Preview("Budget Bouquet - With Data") {
    BudgetBouquetViewV1()
        .environmentObject(BudgetStoreV2())
        .environmentObject(SettingsStoreV2())
        .frame(width: 1200, height: 800)
}

#Preview("Budget Bouquet - Empty State") {
    let view = BudgetBouquetViewV1()
    // The empty state will show when dataProvider has no categories
    return view
        .environmentObject(BudgetStoreV2())
        .environmentObject(SettingsStoreV2())
        .frame(width: 800, height: 600)
}
