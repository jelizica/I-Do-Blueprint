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
    @State private var selectedItemForDetail: CategoryDetailItem?
    @State private var linkedExpensesForSelectedItem: [LinkedExpenseItem] = []
    @State private var linkedGiftsForSelectedItem: [LinkedGiftItem] = []

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
        let _ = AppLogger.ui.debug("BudgetBouquetCategoryDetailView body: isLoading=\(isLoading), items.count=\(items.count), animateItems=\(animateItems)")
        
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    // Header with back button and breadcrumbs
                    headerSection(windowSize: windowSize)

                    // Quick category navigation
                    categoryNavigationBar(windowSize: windowSize)

                    // Main content - 3-column layout like main bouquet page
                    if isLoading {
                        loadingView
                    } else {
                        threeColumnLayout(windowSize: windowSize, horizontalPadding: horizontalPadding)
                            .frame(minHeight: geometry.size.height - 200) // Account for header/nav
                    }
                }
            }
            .background(SemanticColors.backgroundPrimary)
        }
        .onAppear {
            AppLogger.ui.info("BudgetBouquetCategoryDetailView: onAppear for category '\(category.categoryName)'")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateItems = true
                }
            }
        }
        .task(id: category.id) {
            // Use task(id:) to reload when category changes
            AppLogger.ui.info("BudgetBouquetCategoryDetailView: task triggered for category '\(category.categoryName)' (id: \(category.id))")
            animateItems = false
            await loadItems()
            // Re-trigger animation after loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateItems = true
                }
            }
        }
        .sheet(item: $selectedItemForDetail) { item in
            BudgetItemDetailModalV1(
                item: item,
                categoryName: category.categoryName,
                categoryColor: category.color,
                linkedExpenses: linkedExpensesForSelectedItem,
                linkedGifts: linkedGiftsForSelectedItem,
                onLinkExpense: {
                    // TODO: Navigate to expense linking view
                    AppLogger.ui.info("BudgetBouquetCategoryDetailView: Link Expense tapped for '\(item.itemName)'")
                },
                onLinkGift: {
                    // TODO: Navigate to gift linking view
                    AppLogger.ui.info("BudgetBouquetCategoryDetailView: Link Gift tapped for '\(item.itemName)'")
                },
                onEditItem: {
                    // TODO: Navigate to edit budget item view
                    AppLogger.ui.info("BudgetBouquetCategoryDetailView: Edit Item tapped for '\(item.itemName)'")
                }
            )
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private func headerSection(windowSize: WindowSize) -> some View {
        let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl
        
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
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal, horizontalPadding)
        .padding(.top, Spacing.lg)
    }

    // MARK: - Category Navigation Bar

    @ViewBuilder
    private func categoryNavigationBar(windowSize: WindowSize) -> some View {
        let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl
        
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("QUICK CATEGORY NAVIGATION")
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColors.textTertiary)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(allCategories) { cat in
                        categoryNavigationButton(for: cat, isSelected: cat.id == category.id)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
        .padding(.horizontal, horizontalPadding)
        .padding(.top, Spacing.md)
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

    // MARK: - Three Column Layout (1:2:1 Proportional)
    
    @ViewBuilder
    private func threeColumnLayout(windowSize: WindowSize, horizontalPadding: CGFloat) -> some View {
        GeometryReader { geometry in
            // Calculate 1:2:1 proportional widths
            let totalWidth = geometry.size.width - horizontalPadding * 2
            let spacing = Spacing.lg * 2 // Two gaps between three columns
            let availableWidth = totalWidth - spacing
            
            // 1:2:1 ratio = 4 parts total
            let sideColumnWidth = availableWidth / 4  // 1 part each
            let centerColumnWidth = availableWidth / 2  // 2 parts
            
            // Center is square: height = width
            let centerHeight = centerColumnWidth
            
            // Wrap in ScrollView for dynamic sizing that may exceed viewport
            ScrollView(.vertical, showsIndicators: true) {
                HStack(alignment: .top, spacing: Spacing.lg) {
                    // Left: Items Legend (1 part width, matches center height)
                    itemsLegendSection(height: centerHeight)
                        .frame(width: sideColumnWidth, height: centerHeight, alignment: .top)
                    
                    // Center: Flower visualization (2 parts width, square)
                    centerFlowerSection(size: centerColumnWidth)
                        .frame(width: centerColumnWidth, height: centerHeight, alignment: .top)
                    
                    // Right: Quick Stats (1 part width, matches center height)
                    quickStatsSection(height: centerHeight)
                        .frame(width: sideColumnWidth, height: centerHeight, alignment: .top)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xl) // Add bottom padding for scroll content
            }
        }
    }
    
    // MARK: - Items Legend Section (Left Column)
    
    @ViewBuilder
    private func itemsLegendSection(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header (fixed, doesn't scroll)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Budget Items")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text("\(items.count) items in \(category.categoryName)")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textTertiary)
            }
            
            Divider()
            
            // Items list header
            Text("ITEMS")
                .font(Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(SemanticColors.textTertiary)
                .tracking(0.5)
            
            // Scrollable items list - takes remaining space
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    ForEach(items) { item in
                        itemLegendRow(item: item)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
    }
    
    @ViewBuilder
    private func itemLegendRow(item: CategoryDetailItem) -> some View {
        let isHovered = hoveredItemId == item.id
        
        HStack(spacing: Spacing.sm) {
            // Color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(item.color)
                .frame(width: 4, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.itemName)
                    .font(Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)
                
                Text("\(formatCurrency(item.spent)) (\(Int(item.progressRatio * 100))%)")
                    .font(Typography.caption)
                    .foregroundColor(SemanticColors.textSecondary)
            }
            
            Spacer()
            
            // Status dot
            Circle()
                .fill(item.color)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
        .background(isHovered ? item.color.opacity(0.1) : Color.clear)
        .cornerRadius(CornerRadius.sm)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredItemId = hovering ? item.id : nil
            }
        }
    }
    
    // MARK: - Center Flower Section
    
    @ViewBuilder
    private func centerFlowerSection(size: CGFloat) -> some View {
        // Flower visualization fills available space (square)
        smallFlowerVisualization
            .padding(Spacing.lg)
            .background(SemanticColors.backgroundSecondary)
            .cornerRadius(CornerRadius.lg)
    }
    
    @ViewBuilder
    private var smallFlowerVisualization: some View {
        GeometryReader { geometry in
            let containerSize = min(geometry.size.width, geometry.size.height)
            
            // Calculate container scale factor (relative to reference size of 400px)
            let referenceSize: CGFloat = 400
            let containerScale = containerSize / referenceSize
            let clampedContainerScale = min(2.0, max(0.6, containerScale))
            
            // Dynamic scaling based on item count
            let itemCount = items.count
            let itemCountScale = calculateScaleFactor(itemCount: itemCount, containerSize: containerSize)
            
            // Combined scale factor
            let combinedScale = clampedContainerScale * itemCountScale
            
            // Scale center hub and petal cards based on both container size and item count
            let baseCenterSize: CGFloat = 120
            let basePetalCardWidth: CGFloat = 150
            let basePetalCardHeight: CGFloat = 75
            
            let centerSize: CGFloat = max(60, baseCenterSize * combinedScale)
            let petalCardWidth: CGFloat = max(80, basePetalCardWidth * combinedScale)
            let petalCardHeight: CGFloat = max(50, basePetalCardHeight * combinedScale)
            
            // Calculate radius to fit all items - scales with container
            let minRadius = centerSize / 2 + (20 * clampedContainerScale) // Minimum distance from center
            let maxRadius = containerSize / 2 - petalCardWidth / 2 - (10 * clampedContainerScale)
            let optimalRadius = calculateOptimalRadius(
                itemCount: itemCount,
                cardWidth: petalCardWidth,
                minRadius: minRadius,
                maxRadius: maxRadius
            )
            
            ZStack {
                // Connector lines
                if !items.isEmpty {
                    Canvas { context, size in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)

                        for (index, _) in items.enumerated() {
                            let angle = petalAngle(for: index, total: items.count)
                            let endX = center.x + cos(angle) * optimalRadius
                            let endY = center.y + sin(angle) * optimalRadius

                            var path = Path()
                            path.move(to: center)
                            path.addLine(to: CGPoint(x: endX, y: endY))

                            context.stroke(
                                path,
                                with: .color(SemanticColors.borderLight.opacity(0.4)),
                                style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                            )
                        }
                    }
                    .allowsHitTesting(false) // Canvas must not intercept taps meant for petal cards
                }
                
                // Center Hub (scaled) - disable hit testing so petal cards behind can receive taps
                smallCenterHub(size: centerSize)
                    .frame(width: centerSize, height: centerSize)
                    .allowsHitTesting(false) // Don't block taps from reaching petal cards

                // Petal Cards (scaled)
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    scaledPetalCard(
                        item: item,
                        index: index,
                        total: items.count,
                        radius: optimalRadius,
                        cardWidth: petalCardWidth,
                        cardHeight: petalCardHeight,
                        scaleFactor: combinedScale
                    )
                }
            }
        }
    }
    
    /// Calculate scale factor based on item count
    private func calculateScaleFactor(itemCount: Int, containerSize: CGFloat) -> CGFloat {
        // Base scale for small item counts
        if itemCount <= 4 {
            return 1.0
        } else if itemCount <= 6 {
            return 0.9
        } else if itemCount <= 8 {
            return 0.8
        } else if itemCount <= 10 {
            return 0.7
        } else if itemCount <= 14 {
            return 0.6
        } else {
            return max(0.45, 0.6 - Double(itemCount - 14) * 0.02)
        }
    }
    
    /// Calculate optimal radius to prevent overlap
    private func calculateOptimalRadius(itemCount: Int, cardWidth: CGFloat, minRadius: CGFloat, maxRadius: CGFloat) -> CGFloat {
        guard itemCount > 1 else { return minRadius + 50 }
        
        // Calculate the minimum radius needed to prevent card overlap
        // Cards are arranged in a circle, so we need enough circumference
        let angleStep = (2 * Double.pi) / Double(itemCount)
        
        // Minimum arc length between card centers should be slightly more than card width
        let minArcLength = cardWidth * 0.8 // Allow some overlap for visual appeal
        
        // radius = arcLength / angle
        let calculatedRadius = minArcLength / CGFloat(angleStep)
        
        // Clamp to reasonable bounds
        return min(maxRadius, max(minRadius, calculatedRadius))
    }
    
    // MARK: - Scaled Petal Card (Dynamic sizing based on item count)
    
    @ViewBuilder
    private func scaledPetalCard(
        item: CategoryDetailItem,
        index: Int,
        total: Int,
        radius: CGFloat,
        cardWidth: CGFloat,
        cardHeight: CGFloat,
        scaleFactor: CGFloat
    ) -> some View {
        let angle = petalAngle(for: index, total: total)
        let xOffset = cos(angle) * radius
        let yOffset = sin(angle) * radius
        let isHovered = hoveredItemId == item.id

        // Font sizes scale with the card
        let titleFontSize: CGFloat = max(9, 12 * scaleFactor)
        let subtitleFontSize: CGFloat = max(8, 10 * scaleFactor)
        let valueFontSize: CGFloat = max(9, 11 * scaleFactor)
        let iconSize: CGFloat = max(18, 28 * scaleFactor)

        // Compact petal card with dynamic sizing
        // NOTE: Gesture modifiers (contentShape, onTapGesture, onHover) must be applied
        // BEFORE offset/position transforms. SwiftUI's offset() moves visuals but NOT hit areas.
        // We apply gestures to the card content, then transform the entire gestured view.
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(item.color)
                    .frame(width: iconSize, height: iconSize)
                    .overlay(
                        Image(systemName: "tag.fill")
                            .font(.system(size: max(8, 12 * scaleFactor)))
                            .foregroundColor(.white)
                    )

                Text(item.itemName)
                    .font(.system(size: titleFontSize, weight: .semibold))
                    .foregroundColor(SemanticColors.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }

            HStack {
                Text(formatCurrency(item.spent))
                    .font(.system(size: valueFontSize, weight: .bold))
                    .foregroundColor(item.color)

                Spacer()

                Text("\(Int(item.progressRatio * 100))%")
                    .font(.system(size: subtitleFontSize))
                    .foregroundColor(SemanticColors.textTertiary)
            }

            // Progress bar - use fixed frame instead of GeometryReader to avoid hit-test issues
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(SemanticColors.controlBackground)

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(item.color)
                    .frame(width: cardWidth * 0.85 * CGFloat(item.progressRatio)) // Approximate width
            }
            .frame(height: max(2, 4 * scaleFactor))
        }
        .padding(max(4, 8 * scaleFactor))
        .frame(width: cardWidth)
        .background(SemanticColors.backgroundPrimary)
        .cornerRadius(max(4, 8 * scaleFactor))
        .overlay(
            RoundedRectangle(cornerRadius: max(4, 8 * scaleFactor))
                .stroke(isHovered ? item.color : item.color.opacity(0.3), lineWidth: isHovered ? 1.5 : 0.5)
        )
        .shadow(color: isHovered ? item.color.opacity(0.25) : Color.black.opacity(0.03), radius: isHovered ? 8 : 3, x: 0, y: isHovered ? 2 : 1)
        // macOS Hit Testing Fix:
        // 1. Use .contentShape(.interaction, ...) for explicit interaction hit testing
        // 2. Use .simultaneousGesture() instead of .onTapGesture() for ScrollView compatibility
        // 3. Apply transforms (offset, scale) and then gestures in proper order
        .contentShape(.interaction, Rectangle()) // Explicit interaction shape for macOS
        .zIndex(isHovered ? 100 : Double(total - index)) // Bring hovered card to front
        .offset(x: animateItems ? xOffset : 0, y: animateItems ? yOffset : 0)
        .scaleEffect(animateItems ? 1 : 0.5)
        .opacity(animateItems ? 1 : 0)
        .onHover { hovering in
            hoveredItemId = hovering ? item.id : nil
        }
        // Use simultaneousGesture for better compatibility with nested ScrollViews on macOS
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // Open the budget item detail modal
                    AppLogger.ui.info("Petal card tapped: \(item.itemName)")
                    Task {
                        await loadLinkedItemsForItem(item)
                        selectedItemForDetail = item
                    }
                }
        )
        .animation(
            .spring(response: 0.4, dampingFraction: 0.7)
                .delay(Double(index) * 0.05),
            value: animateItems
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
    
    // MARK: - Load Linked Items for Modal
    
    private func loadLinkedItemsForItem(_ item: CategoryDetailItem) async {
        let logger = AppLogger.ui
        logger.info("BudgetBouquetCategoryDetailView: Loading linked items for '\(item.itemName)' (id: \(item.id))")
        
        // Load budget overview items to get linked expenses and gifts
        guard let scenarioId = effectiveScenarioId else {
            logger.warning("BudgetBouquetCategoryDetailView: No scenario ID for loading linked items")
            linkedExpensesForSelectedItem = []
            linkedGiftsForSelectedItem = []
            return
        }
        
        // Fetch budget overview items which include linked expenses and gifts
        // This method returns BudgetOverviewItem which contains expenses and gifts arrays
        let overviewItems = await budgetStore.development.loadBudgetDevelopmentItemsWithSpentAmounts(scenarioId: scenarioId)
        
        // Find the matching item
        if let matchingItem = overviewItems.first(where: { $0.id == item.id }) {
            // Convert ExpenseLink to LinkedExpenseItem
            linkedExpensesForSelectedItem = matchingItem.expenses.map { expense in
                LinkedExpenseItem(from: expense)
            }
            
            // Convert GiftLink to LinkedGiftItem
            linkedGiftsForSelectedItem = matchingItem.gifts.map { gift in
                LinkedGiftItem(from: gift)
            }
            
            logger.info("BudgetBouquetCategoryDetailView: Loaded \(linkedExpensesForSelectedItem.count) expenses and \(linkedGiftsForSelectedItem.count) gifts for '\(item.itemName)'")
        } else {
            logger.warning("BudgetBouquetCategoryDetailView: No matching overview item found for '\(item.itemName)'")
            linkedExpensesForSelectedItem = []
            linkedGiftsForSelectedItem = []
        }
    }
    
    @ViewBuilder
    private func smallCenterHub(size: CGFloat) -> some View {
        ZStack {
            // Outer gradient ring
            Circle()
                .fill(
                    LinearGradient(
                        colors: [category.color, category.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: category.color.opacity(0.3), radius: 15, x: 0, y: 0)
            
            // Inner white circle
            Circle()
                .fill(SemanticColors.backgroundPrimary)
                .padding(4)
            
            // Content
            VStack(spacing: Spacing.xs) {
                Text(formatCurrencyShort(category.totalSpent))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(SemanticColors.textPrimary)
                
                Text(category.categoryName)
                    .font(Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(SemanticColors.textSecondary)
                    .lineLimit(1)
                
                Text("\(Int(category.progressRatio * 100))% Spent")
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textTertiary)
            }
            .padding(Spacing.sm)
        }
    }
    
    @ViewBuilder
    private func smallPetalCard(item: CategoryDetailItem, index: Int, total: Int, containerSize: CGFloat, cardWidth: CGFloat) -> some View {
        let angle = petalAngle(for: index, total: total)
        let radius = containerSize / 2 - cardWidth / 2 - 30
        let xOffset = cos(angle) * radius
        let yOffset = sin(angle) * radius
        let isHovered = hoveredItemId == item.id
        
        // Compact petal card
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(item.color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "tag.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.itemName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SemanticColors.textPrimary)
                        .lineLimit(1)
                    
                    if !item.description.isEmpty {
                        Text(item.description)
                            .font(.system(size: 10))
                            .foregroundColor(SemanticColors.textTertiary)
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 0)
            }
            
            HStack {
                Text("Spent")
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textSecondary)
                Spacer()
                Text(formatCurrency(item.spent))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(item.color)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(SemanticColors.controlBackground)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(item.color)
                        .frame(width: geo.size.width * CGFloat(item.progressRatio))
                }
            }
            .frame(height: 4)
        }
        .padding(Spacing.sm)
        .frame(width: cardWidth)
        .background(SemanticColors.backgroundPrimary)
        .cornerRadius(CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(isHovered ? item.color : item.color.opacity(0.3), lineWidth: isHovered ? 2 : 1)
        )
        .shadow(color: isHovered ? item.color.opacity(0.2) : Color.black.opacity(0.05), radius: isHovered ? 10 : 5, x: 0, y: 2)
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .offset(x: animateItems ? xOffset : 0, y: animateItems ? yOffset : 0)
        .scaleEffect(animateItems ? 1 : 0.5)
        .opacity(animateItems ? 1 : 0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.7)
                .delay(Double(index) * 0.08),
            value: animateItems
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredItemId = hovering ? item.id : nil
            }
        }
    }
    
    // MARK: - Quick Stats Section (Right Column)
    
    @ViewBuilder
    private func quickStatsSection(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Header
            Text("Quick Stats")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)
            
            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                quickStatItem(
                    icon: "dollarsign.circle.fill",
                    iconColor: SemanticColors.primaryAction,
                    label: "Total Budget",
                    value: formatCurrency(category.totalBudgeted)
                )
                
                quickStatItem(
                    icon: "creditcard.fill",
                    iconColor: SemanticColors.statusSuccess,
                    label: "Spent",
                    value: formatCurrency(category.totalSpent),
                    valueColor: SemanticColors.statusSuccess
                )
                
                quickStatItem(
                    icon: "banknote.fill",
                    iconColor: category.remaining >= 0 ? Color.fromHex("#f59e0b") : SemanticColors.statusWarning,
                    label: "Remaining",
                    value: formatCurrency(category.remaining),
                    valueColor: category.remaining >= 0 ? Color.fromHex("#f59e0b") : SemanticColors.statusWarning
                )
                
                quickStatItem(
                    icon: "list.bullet",
                    iconColor: Color.fromHex("#ec4899"),
                    label: "Items",
                    value: "\(items.count)"
                )
            }
            
            Divider()
            
            // Overall Progress
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Overall Progress")
                        .font(Typography.bodySmall)
                        .foregroundColor(SemanticColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(category.progressRatio * 100))%")
                        .font(Typography.bodySmall)
                        .fontWeight(.bold)
                        .foregroundColor(category.isOverBudget ? SemanticColors.statusWarning : SemanticColors.statusSuccess)
                }
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .fill(SemanticColors.controlBackground)
                        
                        RoundedRectangle(cornerRadius: CornerRadius.pill)
                            .fill(
                                LinearGradient(
                                    colors: category.isOverBudget
                                        ? [SemanticColors.statusWarning, SemanticColors.statusWarning.opacity(0.8)]
                                        : [SemanticColors.statusSuccess, Color.fromHex("#10b981")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(min(category.progressRatio, 1.0)))
                    }
                }
                .frame(height: 8)
                
                Text(category.isOverBudget ? "Over budget by \(formatCurrency(abs(category.remaining)))" : "Budget on track")
                    .font(Typography.caption)
                    .foregroundColor(category.isOverBudget ? SemanticColors.statusWarning : SemanticColors.textTertiary)
            }
            
            Divider()
            
            // Status badge
            HStack {
                Circle()
                    .fill(category.isOverBudget ? SemanticColors.statusWarning : SemanticColors.statusSuccess)
                    .frame(width: 8, height: 8)
                
                Text(statusBadge)
                    .font(Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(category.isOverBudget ? SemanticColors.statusWarning : SemanticColors.statusSuccess)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(statusBadgeColor)
            .cornerRadius(CornerRadius.pill)
        }
        .padding(Spacing.lg)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
    }
    
    @ViewBuilder
    private func quickStatItem(icon: String, iconColor: Color, label: String, value: String, valueColor: Color = SemanticColors.textPrimary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(iconColor)
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textTertiary)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SemanticColors.backgroundTertiary)
        .cornerRadius(CornerRadius.md)
    }
    
    private func formatCurrencyShort(_ value: Double) -> String {
        if value >= 1000 {
            return "$\(Int(value / 1000))K"
        }
        return formatCurrency(value)
    }

    // MARK: - Stats Cards Section (Compact) - Kept for reference

    @ViewBuilder
    private func statsCardsSection(windowSize: WindowSize) -> some View {
        // Always use 4 columns for compact horizontal layout
        let gridItems = Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 4)

        LazyVGrid(columns: gridItems, spacing: Spacing.sm) {
            // Total Budget
            CompactStatCard(
                icon: "dollarsign.circle.fill",
                iconColor: SemanticColors.primaryAction,
                title: "Total Budget",
                value: formatCurrency(category.totalBudgeted),
                badge: statusBadge,
                badgeColor: statusBadgeColor
            )

            // Total Spent
            CompactStatCard(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: SemanticColors.statusSuccess,
                title: "Total Spent",
                value: formatCurrency(category.totalSpent),
                valueColor: SemanticColors.statusSuccess,
                badge: "\(Int(category.progressRatio * 100))%",
                badgeColor: SemanticColors.primaryAction.opacity(0.15)
            )

            // Remaining
            CompactStatCard(
                icon: "banknote.fill",
                iconColor: Color.fromHex("#f59e0b"),
                title: "Remaining",
                value: formatCurrency(category.remaining),
                valueColor: category.remaining >= 0 ? Color.fromHex("#f59e0b") : SemanticColors.statusWarning,
                badge: "\(Int((1 - category.progressRatio) * 100))%",
                badgeColor: SemanticColors.primaryActionHover.opacity(0.15)
            )

            // Budget Items
            CompactStatCard(
                icon: "square.stack.3d.up.fill",
                iconColor: Color.fromHex("#ec4899"),
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
        
        let logger = AppLogger.ui

        guard let scenarioId = effectiveScenarioId else {
            logger.error("BudgetBouquetCategoryDetailView: No scenario ID available. scenarioId param: \(self.scenarioId ?? "nil"), store primaryScenario: \(budgetStore.primaryScenario?.id.uuidString ?? "nil")")
            isLoading = false
            return
        }
        
        logger.info("BudgetBouquetCategoryDetailView: Loading items for category '\(category.categoryName)' with scenarioId: \(scenarioId)")

        // Load budget items for this category
        let allItems = await budgetStore.development.loadBudgetDevelopmentItemsWithSpentAmounts(scenarioId: scenarioId)
        
        logger.info("BudgetBouquetCategoryDetailView: Loaded \(allItems.count) total items")
        
        // Log unique categories for debugging
        let uniqueCategories = Set(allItems.map { $0.category })
        logger.info("BudgetBouquetCategoryDetailView: Unique categories in data: \(uniqueCategories.sorted().joined(separator: ", "))")

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
        
        logger.info("BudgetBouquetCategoryDetailView: Filtered to \(categoryItems.count) items for category '\(category.categoryName)'")

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

// MARK: - Compact Stat Card Component (Space-efficient version)

struct CompactStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var valueColor: Color = SemanticColors.textPrimary
    var badge: String = ""
    var badgeColor: Color = SemanticColors.statusSuccess.opacity(0.15)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .top) {
                // Smaller icon
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(iconColor)
                    )

                Spacer()

                // Badge
                if !badge.isEmpty {
                    Text(badge)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(badgeTextColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(badgeColor)
                        .cornerRadius(CornerRadius.pill)
                }
            }

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(SemanticColors.textSecondary)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(Spacing.sm)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.borderLight.opacity(0.5), lineWidth: 1)
        )
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

// MARK: - Category Detail Stat Card Component (Original - kept for reference)

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
