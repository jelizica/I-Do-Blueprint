//
//  BudgetBouquetCategoryDetailView.swift
//  I Do Blueprint
//
//  Budget Bouquet Category Detail View - Drill-down view for a specific budget category
//  Shows individual budget items as card-style petals arranged around a center hub
//
//  Features:
//  - Header with back navigation and breadcrumbs
//  - Quick category navigation bar
//  - 4 stat cards (Total Budget, Spent, Remaining, Item Count)
//  - Flower visualization with items as card petals
//  - Center hub showing category totals
//  - Hover state shows item details at bottom
//

import SwiftUI

// MARK: - Category Detail Item Data

/// Represents a single budget item within a category for the detail view
struct CategoryDetailItem: Identifiable, Equatable {
    let id: String
    let itemName: String
    let description: String
    let budgeted: Double
    let spent: Double
    let color: Color

    var progressRatio: Double {
        guard budgeted > 0 else { return 0 }
        return min(1.0, spent / budgeted)
    }

    var isOverBudget: Bool {
        spent > budgeted
    }

    var remaining: Double {
        budgeted - spent
    }

    var statusLabel: String {
        let ratio = progressRatio
        if isOverBudget { return "Over Budget" }
        if ratio >= 0.85 { return "Near Limit" }
        if ratio >= 0.5 { return "On Track" }
        if ratio > 0 { return "Healthy" }
        return "Not Started"
    }

    var statusColor: Color {
        let ratio = progressRatio
        if isOverBudget { return SemanticColors.statusWarning }
        if ratio >= 0.85 { return Color.fromHex("#f59e0b") } // Amber
        if ratio >= 0.5 { return SemanticColors.statusSuccess }
        return SemanticColors.statusSuccess
    }
}

// MARK: - Main View

struct BudgetBouquetCategoryDetailView: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @Environment(\.colorScheme) var colorScheme

    /// The category being displayed
    let category: BouquetCategoryData

    /// All categories for quick navigation
    let allCategories: [BouquetCategoryData]

    /// Binding to navigate back
    var currentPage: Binding<BudgetPage>

    /// Optional scenario ID override - if provided, uses this instead of budgetStore.primaryScenario
    var scenarioId: String?

    /// Callback when a different category is selected
    var onCategorySelected: ((BouquetCategoryData) -> Void)?

    /// Callback to navigate back to bouquet
    var onBackToBouquet: (() -> Void)?

    // MARK: - State

    @State private var items: [CategoryDetailItem] = []
    @State private var hoveredItemId: String?
    @State private var isLoading: Bool = true
    @State private var animateItems: Bool = false

    // MARK: - Computed Properties

    /// Returns the scenario ID to use - prefers the passed scenarioId, falls back to store's primaryScenario
    private var effectiveScenarioId: String? {
        if let scenarioId = scenarioId, !scenarioId.isEmpty {
            return scenarioId
        }
        return budgetStore.primaryScenario?.id.uuidString
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl

            VStack(spacing: 0) {
                // Header with back button and breadcrumbs
                headerSection(windowSize: windowSize)

                // Quick category navigation
                categoryNavigationBar(windowSize: windowSize)

                // Main content
                if isLoading {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Stats cards
                            statsCardsSection(windowSize: windowSize)

                            // Flower visualization with item petals
                            flowerVisualizationSection(geometry: geometry)

                            // Hovered item detail (if any)
                            if let hoveredId = hoveredItemId,
                               let item = items.first(where: { $0.id == hoveredId }) {
                                hoveredItemDetailCard(item: item)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, Spacing.xl)
                    }
                }
            }
            .background(SemanticColors.backgroundPrimary)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateItems = true
                }
            }
        }
        .task {
            await loadItems()
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private func headerSection(windowSize: WindowSize) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: Spacing.lg) {
                // Back button
                Button {
                    onBackToBouquet?()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back to Bouquet")
                            .font(Typography.bodyRegular)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(SemanticColors.textOnPrimary)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
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

                // Divider
                Rectangle()
                    .fill(SemanticColors.borderLight)
                    .frame(width: 1, height: 24)

                // Breadcrumbs
                HStack(spacing: Spacing.xs) {
                    Text("Budget")
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.primaryAction)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(SemanticColors.textTertiary)

                    Text("Budget Bouquet")
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.primaryAction)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(SemanticColors.textTertiary)

                    Text(category.categoryName)
                        .font(Typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textPrimary)
                }

                Spacer()

                // Total Budget display
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "wallet.pass.fill")
                        .foregroundColor(SemanticColors.statusSuccess)

                    Text("Total Budget:")
                        .font(Typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.textSecondary)

                    Text(formatCurrency(category.totalBudgeted))
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.statusSuccess)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(SemanticColors.statusSuccess.opacity(Opacity.verySubtle))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.lg)
                                .stroke(SemanticColors.statusSuccess.opacity(Opacity.medium), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, windowSize == .compact ? Spacing.lg : Spacing.xl)
            .padding(.vertical, Spacing.lg)
        }
        .background(SemanticColors.backgroundSecondary.opacity(0.8))
        .background(.ultraThinMaterial)
    }

    // MARK: - Category Navigation Bar

    @ViewBuilder
    private func categoryNavigationBar(windowSize: WindowSize) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("QUICK CATEGORY NAVIGATION")
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textTertiary)
                    .tracking(0.5)

                Spacer()
            }
            .padding(.horizontal, windowSize == .compact ? Spacing.lg : Spacing.xl)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(allCategories) { cat in
                        categoryNavigationButton(for: cat, isSelected: cat.id == category.id)
                    }
                }
                .padding(.horizontal, windowSize == .compact ? Spacing.lg : Spacing.xl)
                .padding(.bottom, Spacing.md)
            }
        }
        .background(SemanticColors.backgroundSecondary.opacity(0.6))
    }

    @ViewBuilder
    private func categoryNavigationButton(for cat: BouquetCategoryData, isSelected: Bool) -> some View {
        Button {
            if !isSelected {
                onCategorySelected?(cat)
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(cat.color)
                    .frame(width: 8, height: 8)

                Text(cat.categoryName)
                    .font(Typography.bodySmall)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? SemanticColors.textOnPrimary : SemanticColors.textSecondary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [
                                SemanticColors.primaryAction,
                                SemanticColors.primaryActionHover
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        SemanticColors.controlBackground
                    }
                }
            )
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(
                        isSelected ? Color.clear : SemanticColors.borderLight,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Cards Section

    @ViewBuilder
    private func statsCardsSection(windowSize: WindowSize) -> some View {
        let columns = windowSize == .compact ? 2 : 4
        let gridItems = Array(repeating: GridItem(.flexible(), spacing: Spacing.lg), count: columns)

        LazyVGrid(columns: gridItems, spacing: Spacing.lg) {
            // Total Budget
            CategoryDetailStatCard(
                icon: "dollarsign.circle.fill",
                iconGradient: [SemanticColors.primaryAction, SemanticColors.primaryActionHover],
                title: "Total Budget",
                value: formatCurrency(category.totalBudgeted),
                badge: statusBadge,
                badgeColor: statusBadgeColor
            )

            // Total Spent
            CategoryDetailStatCard(
                icon: "chart.line.uptrend.xyaxis",
                iconGradient: [SemanticColors.statusSuccess, Color.fromHex("#10b981")],
                title: "Total Spent",
                value: formatCurrency(category.totalSpent),
                valueColor: SemanticColors.statusSuccess,
                badge: "\(Int(category.progressRatio * 100))%",
                badgeColor: SemanticColors.primaryAction.opacity(0.15)
            )

            // Remaining
            CategoryDetailStatCard(
                icon: "banknote.fill",
                iconGradient: [Color.fromHex("#f59e0b"), Color.fromHex("#d97706")],
                title: "Remaining",
                value: formatCurrency(category.remaining),
                valueColor: Color.fromHex("#f59e0b"),
                badge: "\(Int((1 - category.progressRatio) * 100))%",
                badgeColor: SemanticColors.primaryActionHover.opacity(0.15)
            )

            // Budget Items
            CategoryDetailStatCard(
                icon: "square.stack.3d.up.fill",
                iconGradient: [Color.fromHex("#ec4899"), Color.fromHex("#db2777")],
                title: "Budget Items",
                value: "\(items.count)",
                badge: "Active",
                badgeColor: SemanticColors.primaryAction.opacity(0.15)
            )
        }
    }

    private var statusBadge: String {
        if category.isOverBudget { return "Over Budget" }
        if category.progressRatio >= 0.9 { return "Near Limit" }
        return "On Track"
    }

    private var statusBadgeColor: Color {
        if category.isOverBudget { return SemanticColors.statusWarning.opacity(0.15) }
        if category.progressRatio >= 0.9 { return Color.fromHex("#f59e0b").opacity(0.15) }
        return SemanticColors.statusSuccess.opacity(0.15)
    }

    // MARK: - Flower Visualization Section

    @ViewBuilder
    private func flowerVisualizationSection(geometry: GeometryProxy) -> some View {
        let availableWidth = geometry.size.width - (Spacing.xl * 2)
        let centerSize: CGFloat = 200
        let petalCardWidth: CGFloat = 220
        let visualizationSize = min(availableWidth, 900)

        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: CornerRadius.xxl)
                .fill(SemanticColors.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)

            // Connector lines (SVG-style dashed lines)
            if !items.isEmpty {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = min(size.width, size.height) / 2 - petalCardWidth / 2 - 20

                    for (index, _) in items.enumerated() {
                        let angle = petalAngle(for: index, total: items.count)
                        let endX = center.x + cos(angle) * radius
                        let endY = center.y + sin(angle) * radius

                        var path = Path()
                        path.move(to: center)
                        path.addLine(to: CGPoint(x: endX, y: endY))

                        context.stroke(
                            path,
                            with: .color(SemanticColors.borderLight.opacity(0.5)),
                            style: StrokeStyle(lineWidth: 2, dash: [5, 5])
                        )
                    }
                }
            }

            // Center Hub
            centerHub(size: centerSize)
                .frame(width: centerSize, height: centerSize)

            // Petal Cards arranged radially
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                petalCard(item: item, index: index, total: items.count, containerSize: visualizationSize, cardWidth: petalCardWidth)
            }
        }
        .frame(height: visualizationSize)
        .padding(Spacing.xl)
    }

    private func petalAngle(for index: Int, total: Int) -> Double {
        let startAngle = -Double.pi / 2 // Start from top
        let angleStep = (2 * Double.pi) / Double(max(total, 1))
        return startAngle + Double(index) * angleStep
    }

    @ViewBuilder
    private func centerHub(size: CGFloat) -> some View {
        ZStack {
            // Outer gradient ring with pulse animation
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            SemanticColors.primaryAction,
                            SemanticColors.primaryActionHover,
                            Color.fromHex("#ec4899")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: SemanticColors.primaryAction.opacity(0.4), radius: 20, x: 0, y: 0)

            // Inner white circle
            Circle()
                .fill(SemanticColors.backgroundPrimary)
                .padding(6)

            // Content
            VStack(spacing: Spacing.sm) {
                // Category icon
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [
                                SemanticColors.primaryAction,
                                SemanticColors.primaryActionHover
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: iconForCategory(category.categoryName))
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )

                // Category name
                Text(category.categoryName)
                    .font(Typography.bodyRegular)
                    .fontWeight(.bold)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                // Spent / Budget
                HStack(spacing: Spacing.xs) {
                    Text(formatCurrency(category.totalSpent))
                        .font(Typography.heading)
                        .foregroundColor(SemanticColors.primaryAction)

                    Text("/")
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.textTertiary)

                    Text(formatCurrency(category.totalBudgeted))
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.textSecondary)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .fill(SemanticColors.controlBackground)

                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .fill(
                                LinearGradient(
                                    colors: [SemanticColors.statusSuccess, Color.fromHex("#10b981")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(category.progressRatio))
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, Spacing.lg)

                // Status badges
                HStack(spacing: Spacing.xs) {
                    Text("\(Int(category.progressRatio * 100))% Used")
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.statusSuccess)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(SemanticColors.statusSuccess.opacity(Opacity.verySubtle))
                        .cornerRadius(CornerRadius.pill)

                    Text("\(items.count) Items")
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(SemanticColors.primaryActionHover)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(SemanticColors.primaryActionHover.opacity(Opacity.verySubtle))
                        .cornerRadius(CornerRadius.pill)
                }
            }
            .padding(Spacing.lg)
        }
    }

    @ViewBuilder
    private func petalCard(item: CategoryDetailItem, index: Int, total: Int, containerSize: CGFloat, cardWidth: CGFloat) -> some View {
        let angle = petalAngle(for: index, total: total)
        let radius = containerSize / 2 - cardWidth / 2 - 40
        let xOffset = cos(angle) * radius
        let yOffset = sin(angle) * radius
        let isHovered = hoveredItemId == item.id

        ItemPetalCard(item: item, isHovered: isHovered)
            .frame(width: cardWidth)
            .offset(x: animateItems ? xOffset : 0, y: animateItems ? yOffset : 0)
            .scaleEffect(animateItems ? 1 : 0.5)
            .opacity(animateItems ? 1 : 0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.7)
                    .delay(Double(index) * 0.1),
                value: animateItems
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    hoveredItemId = hovering ? item.id : nil
                }
            }
    }

    // MARK: - Hovered Item Detail Card

    @ViewBuilder
    private func hoveredItemDetailCard(item: CategoryDetailItem) -> some View {
        HStack(spacing: Spacing.lg) {
            // Color indicator
            Circle()
                .fill(item.color)
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.itemName)
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("\(formatCurrency(item.spent)) of \(formatCurrency(item.budgeted))")
                    .font(Typography.bodySmall)
                    .foregroundColor(SemanticColors.textSecondary)

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(Typography.caption)
                        .foregroundColor(SemanticColors.textTertiary)
                }
            }

            Spacer()

            // Progress info
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text("\(Int(item.progressRatio * 100))%")
                    .font(Typography.numberMedium)
                    .foregroundColor(item.color)

                Text("\(formatCurrency(item.remaining)) left")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textTertiary)
            }

            // Status badge
            Text(item.statusLabel)
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(item.statusColor)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(item.statusColor.opacity(Opacity.verySubtle))
                .cornerRadius(CornerRadius.pill)
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundTertiary)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading category items...")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    private func iconForCategory(_ categoryName: String) -> String {
        let name = categoryName.lowercased()
        if name.contains("venue") { return "building.2.fill" }
        if name.contains("photo") || name.contains("video") { return "camera.fill" }
        if name.contains("attire") || name.contains("dress") { return "tshirt.fill" }
        if name.contains("flower") || name.contains("decor") { return "leaf.fill" }
        if name.contains("entertainment") || name.contains("music") { return "music.note" }
        if name.contains("stationery") || name.contains("invitation") { return "envelope.fill" }
        if name.contains("transport") { return "car.fill" }
        if name.contains("cake") { return "birthday.cake.fill" }
        if name.contains("catering") || name.contains("food") { return "fork.knife" }
        if name.contains("ring") { return "diamond.fill" }
        if name.contains("honey") { return "airplane" }
        if name.contains("hair") || name.contains("makeup") { return "paintbrush.fill" }
        return "dollarsign.circle.fill"
    }

    private func loadItems() async {
        isLoading = true

        guard let scenarioId = effectiveScenarioId else {
            isLoading = false
            return
        }

        // Load budget items for this category
        let allItems = await budgetStore.development.loadBudgetDevelopmentItemsWithSpentAmounts(scenarioId: scenarioId)

        // Filter to this category and convert to CategoryDetailItem
        let categoryItems = allItems
            .filter { $0.category == category.categoryName && !$0.isFolder }
            .enumerated()
            .map { index, item in
                CategoryDetailItem(
                    id: item.id,
                    itemName: item.itemName,
                    description: item.subcategory,
                    budgeted: item.budgeted,
                    spent: item.spent,
                    color: colorForIndex(index)
                )
            }

        items = categoryItems
        isLoading = false
    }

    private func colorForIndex(_ index: Int) -> Color {
        let colors: [Color] = [
            Color.fromHex("#3b82f6"), // Blue
            Color.fromHex("#a855f7"), // Purple
            Color.fromHex("#ec4899"), // Pink
            Color.fromHex("#f59e0b"), // Amber
            Color.fromHex("#f43f5e"), // Rose
            Color.fromHex("#10b981"), // Green
            Color.fromHex("#14b8a6"), // Teal
            Color.fromHex("#06b6d4"), // Cyan
            Color.fromHex("#6366f1"), // Indigo
            Color.fromHex("#8b5cf6"), // Violet
        ]
        return colors[index % colors.count]
    }
}

// MARK: - Category Detail Stat Card Component

struct CategoryDetailStatCard: View {
    let icon: String
    let iconGradient: [Color]
    let title: String
    let value: String
    var valueColor: Color = SemanticColors.textPrimary
    var badge: String = ""
    var badgeColor: Color = SemanticColors.statusSuccess.opacity(0.15)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                // Icon
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: iconGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    )

                Spacer()

                // Badge
                if !badge.isEmpty {
                    Text(badge)
                        .font(Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(badgeTextColor)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xxs)
                        .background(badgeColor)
                        .cornerRadius(CornerRadius.pill)
                }
            }

            Text(title)
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)

            Text(value)
                .font(Typography.displaySmall)
                .foregroundColor(valueColor)
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.xl)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var badgeTextColor: Color {
        if badgeColor == SemanticColors.statusSuccess.opacity(0.15) {
            return SemanticColors.statusSuccess
        }
        if badgeColor == SemanticColors.statusWarning.opacity(0.15) {
            return SemanticColors.statusWarning
        }
        return SemanticColors.primaryAction
    }
}

// MARK: - Item Petal Card Component

struct ItemPetalCard: View {
    let item: CategoryDetailItem
    let isHovered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Header row
            HStack(alignment: .top) {
                HStack(spacing: Spacing.sm) {
                    // Icon
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [item.color, item.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "tag.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(item.itemName)
                            .font(Typography.bodyRegular)
                            .fontWeight(.bold)
                            .foregroundColor(SemanticColors.textPrimary)
                            .lineLimit(1)

                        if !item.description.isEmpty {
                            Text(item.description)
                                .font(Typography.caption)
                                .foregroundColor(SemanticColors.textTertiary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                Image(systemName: "link")
                    .font(.system(size: 12))
                    .foregroundColor(SemanticColors.primaryAction.opacity(0.6))
            }

            // Spent row
            HStack {
                Text("Spent")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                Spacer()
                Text(formatCurrency(item.spent))
                    .font(Typography.bodySmall)
                    .fontWeight(.bold)
                    .foregroundColor(item.color)
            }

            // Budget row
            HStack {
                Text("Budget")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
                Spacer()
                Text(formatCurrency(item.budgeted))
                    .font(Typography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundColor(SemanticColors.textPrimary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: CornerRadius.pill)
                        .fill(SemanticColors.controlBackground)

                    RoundedRectangle(cornerRadius: CornerRadius.pill)
                        .fill(
                            LinearGradient(
                                colors: [item.color, item.color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(item.progressRatio))
                }
            }
            .frame(height: 6)

            // Bottom row
            HStack {
                Text("\(Int(item.progressRatio * 100))% Used")
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(item.color)

                Spacer()

                Text("\(formatCurrency(item.remaining)) left")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textTertiary)
            }
        }
        .padding(Spacing.md)
        .background(SemanticColors.backgroundPrimary)
        .cornerRadius(CornerRadius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(
                    isHovered ? item.color : item.color.opacity(0.3),
                    lineWidth: isHovered ? 2 : 1
                )
        )
        .shadow(
            color: isHovered ? item.color.opacity(0.3) : Color.black.opacity(0.08),
            radius: isHovered ? 15 : 8,
            x: 0,
            y: isHovered ? 8 : 4
        )
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
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

#Preview("Bouquet Category Detail View") {
    let category = BouquetCategoryData(
        id: "venue",
        categoryName: "Venue & Catering",
        totalBudgeted: 15000,
        totalSpent: 10200,
        itemCount: 5,
        color: Color.fromHex("#f43f5e")
    )

    let allCategories = [
        category,
        BouquetCategoryData(
            id: "photo",
            categoryName: "Photography",
            totalBudgeted: 6000,
            totalSpent: 4500,
            itemCount: 3,
            color: Color.fromHex("#a855f7")
        ),
        BouquetCategoryData(
            id: "flowers",
            categoryName: "Flowers & Decor",
            totalBudgeted: 4500,
            totalSpent: 2000,
            itemCount: 4,
            color: Color.fromHex("#f59e0b")
        )
    ]

    return BudgetBouquetCategoryDetailView(
        category: category,
        allCategories: allCategories,
        currentPage: .constant(.budgetBouquet),
        onCategorySelected: { _ in },
        onBackToBouquet: { }
    )
    .environmentObject(BudgetStoreV2())
    .frame(width: 1200, height: 900)
}
