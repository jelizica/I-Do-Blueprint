//
//  BudgetOverviewDashboardViewV2.swift
//  I Do Blueprint
//
//  Refactored: Components extracted to separate files
//

import Charts
import SwiftUI

@MainActor
struct BudgetOverviewDashboardViewV2: View {
    @EnvironmentObject var budgetStore: BudgetStoreV2
    @EnvironmentObject private var settingsStore: SettingsStoreV2

    // Navigation state - receives binding from parent (BudgetDashboardHubView)
    @Binding var currentPage: BudgetPage

    // State for scenario selection
    @State private var allScenarios: [SavedScenario] = []
    @State private var selectedScenarioId: String = ""
    @State private var primaryScenario: SavedScenario?
    @State private var currentScenario: SavedScenario?
    @State private var budgetItems: [BudgetOverviewItem] = []
    @State private var loading = true
    @State private var error: String?
    @State private var isRefreshing = false
    
    // Folder expansion state
    @State private var expandedFolderIds: Set<String> = []

    // Filter and search state
    @State private var activeFilters: [BudgetFilter] = []
    @State private var filteredBudgetItems: [BudgetOverviewItem] = []
    @State private var searchQuery = ""
    @State private var debouncedSearchQuery = ""

    // Modal state
    @State private var showExpenseLinkModal = false
    @State private var showGiftLinkModal = false
    @State private var selectedBudgetItem: BudgetOverviewItem?

    // Real-time sync timer
    @State private var refreshTimer: Timer?
    @State private var searchTimer: Timer?

    // View toggle state
    @State private var viewMode: ViewMode = .cards
    
    // Bouquet data provider
    @StateObject private var bouquetDataProvider = BouquetDataProvider()
    
    // Track when bouquet category detail view is showing (to hide parent summary cards)
    @State private var isBouquetDetailShowing: Bool = false

    private let logger = AppLogger.ui

    enum ViewMode {
        case cards
        case table
        case bouquet
    }

    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xxl
            let availableWidth = geometry.size.width - (horizontalPadding * 2)

            ZStack {
                // Mesh gradient background matching DashboardViewV7 and GuestDashboardViewV2
                MeshGradientBackground()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header section
                    headerSection(windowSize: windowSize)

                    if loading {
                        loadingView
                    } else if let error {
                        errorView(error)
                    } else {
                        overviewContent(windowSize: windowSize, availableWidth: availableWidth, horizontalPadding: horizontalPadding)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            logger.info("Budget Overview: View appeared, current tenant: \(SessionManager.shared.getTenantId()?.uuidString ?? "none")")
            Task {
                await loadInitialData()
                setupRealTimeSync()
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            searchTimer?.invalidate()
        }
        .onReceive(NotificationCenter.default.publisher(for: .tenantDidChange)) { notification in
            // Extract new tenant ID from notification
            guard let newTenantIdString = notification.userInfo?["newId"] as? String,
                  let newTenantId = UUID(uuidString: newTenantIdString) else {
                logger.error("Tenant change notification missing tenant ID")
                return
            }

            logger.info("Budget Overview: Received tenant change to \(newTenantIdString)")

            // Reset state when tenant changes
            selectedScenarioId = ""
            budgetItems = []
            filteredBudgetItems = []
            allScenarios = []
            primaryScenario = nil
            currentScenario = nil
            searchQuery = ""
            debouncedSearchQuery = ""
            activeFilters = []
            expandedFolderIds = []

            // Reload data for new tenant with validation
            Task {
                // Add small delay to ensure cache invalidation completes
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                await loadInitialData()

                // Verify we loaded the correct tenant's data
                guard let currentTenantId = SessionManager.shared.getTenantId(),
                      currentTenantId == newTenantId else {
                    logger.error("Budget Overview: Loaded data for wrong tenant! Expected \(newTenantIdString), retrying...")

                    // Retry with longer delay
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    await loadInitialData()

                    // Final validation
                    guard let finalTenantId = SessionManager.shared.getTenantId(),
                          finalTenantId == newTenantId else {
                        logger.error("Budget Overview: Still loading wrong tenant data after retry!")
                        return
                    }

                    logger.info("Budget Overview: Successfully loaded correct tenant data after retry")
                    return
                }

                logger.info("Budget Overview: Successfully loaded data for tenant \(newTenantIdString)")
            }
        }
        .onChange(of: searchQuery) {
            setupSearchDebounce()
        }
        .onChange(of: selectedScenarioId) {
            Task { await handleScenarioChange(selectedScenarioId) }
        }
        .onChange(of: debouncedSearchQuery) {
            applyFiltersAndSearch()
        }
        .onChange(of: activeFilters) {
            applyFiltersAndSearch()
        }
        // Modal sheets
        .sheet(item: Binding<BudgetOverviewItem?>(
            get: { showExpenseLinkModal ? selectedBudgetItem : nil },
            set: { _ in showExpenseLinkModal = false })) { budgetItem in
            ExpenseLinkingView(
                isPresented: $showExpenseLinkModal,
                budgetItem: budgetItem,
                activeScenario: currentScenario,
                onSuccess: {
                    Task { await refreshData() }
                })
        }
        .sheet(item: Binding<BudgetOverviewItem?>(
            get: { showGiftLinkModal ? selectedBudgetItem : nil },
            set: { _ in showGiftLinkModal = false })) { budgetItem in
            GiftLinkingView(
                isPresented: $showGiftLinkModal,
                budgetItem: budgetItem,
                activeScenario: currentScenario,
                onSuccess: {
                    Task { await refreshData() }
                })
        }
    }

    // MARK: - View Components

    private func headerSection(windowSize: WindowSize) -> some View {
        BudgetOverviewUnifiedHeader(
            windowSize: windowSize,
            selectedScenarioId: $selectedScenarioId,
            searchQuery: $searchQuery,
            viewMode: $viewMode,
            allScenarios: allScenarios,
            currentScenario: currentScenario,
            primaryScenario: primaryScenario,
            loading: loading,
            activeFilters: activeFilters
        )
    }

    private var loadingView: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(0..<5, id: \.self) { _ in
                    BudgetItemSkeleton()
                }
            }
            .padding(Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ errorMessage: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("Failed to Load Budget Data")
                .font(.headline)

            Text(errorMessage)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task { await refreshData() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRefreshing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func overviewContent(windowSize: WindowSize, availableWidth: CGFloat, horizontalPadding: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Summary cards - FIXED at top (outside ScrollView)
            // Hide when in bouquet view mode (Quick Stats panel shows this info)
            // Also hide when bouquet detail view is showing
            if viewMode != .bouquet && !isBouquetDetailShowing {
                summaryCardsSection(windowSize: windowSize)
                    .frame(width: availableWidth)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, windowSize == .compact ? Spacing.md : Spacing.lg)
                    .padding(.bottom, Spacing.md)
            }

            // Budget items grid - SCROLLABLE
            ScrollView(.vertical, showsIndicators: true) {
                budgetItemsSection(windowSize: windowSize)
                    // ⭐ CRITICAL: Constrain to available width to prevent edge clipping
                    .frame(width: availableWidth)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, windowSize == .compact ? Spacing.md : Spacing.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func summaryCardsSection(windowSize: WindowSize) -> some View {
        BudgetOverviewSummaryCards(
            windowSize: windowSize,
            totalBudget: totalBudget,
            totalExpenses: totalExpenses,
            totalRemaining: totalRemaining,
            itemCount: filteredBudgetItems.count)
    }

    private func budgetItemsSection(windowSize: WindowSize) -> some View {
        BudgetOverviewItemsSection(
            windowSize: windowSize,
            filteredBudgetItems: filteredBudgetItems,
            budgetItems: budgetItems,
            expandedFolderIds: $expandedFolderIds,
            viewMode: viewMode,
            bouquetDataProvider: bouquetDataProvider,
            scenarioId: selectedScenarioId,
            onEditExpense: handleEditExpense,
            onRemoveExpense: handleUnlinkExpense,
            onEditGift: handleEditGift,
            onRemoveGift: handleUnlinkGift,
            onAddExpense: handleAddExpense,
            onAddGift: handleAddGift,
            isBouquetDetailShowing: $isBouquetDetailShowing
        )
        .animation(.easeInOut(duration: 0.2), value: expandedFolderIds)
    }

    // MARK: - Computed Properties

    private var totalBudget: Double {
        filteredBudgetItems.reduce(0) { $0 + $1.budgeted }
    }

    private var totalExpenses: Double {
        filteredBudgetItems.reduce(0) { $0 + ($1.effectiveSpent ?? 0) }
    }

    private var totalRemaining: Double {
        totalBudget - totalExpenses
    }

    // MARK: - Data Loading and Management

    private func loadInitialData() async {
        loading = true
        error = nil

        do {
            await budgetStore.loadBudgetData(force: true)  // Force reload to ensure fresh data
            await fetchScenarios()
            await refreshData()
        } catch {
            self.error = error.localizedDescription
        }

        loading = false
    }

    private func fetchScenarios() async {
        allScenarios = budgetStore.savedScenarios
        primaryScenario = allScenarios.first { $0.isPrimary }

        if selectedScenarioId.isEmpty {
            selectedScenarioId = primaryScenario?.id ?? allScenarios.first?.id ?? ""
        }
    }

    private func refreshData() async {
        isRefreshing = true
        defer { isRefreshing = false }

        await budgetStore.refresh()
        currentScenario = budgetStore.savedScenarios.first { $0.id == selectedScenarioId }
        await loadBudgetItems()
        applyFiltersAndSearch()
    }

    private func loadBudgetItems() async {
        budgetItems = await budgetStore.development.loadBudgetDevelopmentItemsWithSpentAmounts(scenarioId: selectedScenarioId)
        
        // Load data into bouquet provider
        bouquetDataProvider.loadData(from: budgetItems)
    }

    // MARK: - Search and Filtering

    private func setupRealTimeSync() {
        // Disabled for performance
    }

    private func setupSearchDebounce() {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            debouncedSearchQuery = searchQuery
        }
    }

    private func applyFiltersAndSearch() {
        var filtered = budgetItems

        if !debouncedSearchQuery.isEmpty {
            filtered = filtered.filter { item in
                item.itemName.localizedCaseInsensitiveContains(debouncedSearchQuery) ||
                    item.category.localizedCaseInsensitiveContains(debouncedSearchQuery) ||
                    item.subcategory.localizedCaseInsensitiveContains(debouncedSearchQuery)
            }
        }

        for filter in activeFilters {
            filtered = applyBudgetFilter(items: filtered, filter: filter)
        }

        filteredBudgetItems = filtered
    }

    private func applyBudgetFilter(items: [BudgetOverviewItem], filter: BudgetFilter) -> [BudgetOverviewItem] {
        switch filter {
        case .overBudget:
            return items.filter { $0.effectiveSpent > $0.budgeted }
        case .underBudget:
            return items.filter { $0.effectiveSpent < $0.budgeted }
        case .onTrack:
            return items.filter { abs($0.effectiveSpent - $0.budgeted) / $0.budgeted < 0.1 }
        case .noExpenses:
            return items.filter { $0.expenses.isEmpty }
        case .all:
            return items
        }
    }

    private func handleScenarioChange(_ scenarioId: String) async {
        // Reset filters, search, and folder expansion state when scenario changes
        activeFilters = []
        searchQuery = ""
        debouncedSearchQuery = ""
        expandedFolderIds = []
        await refreshData()
    }

    // MARK: - Event Handlers

    private func handleEditExpense(expenseId: String, itemId: String) {
                guard let item = budgetItems.first(where: { $0.id == itemId }) else {
            logger.warning("Could not find budget item with ID: \(itemId)")
            return
        }

        if item.itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            logger.warning("Budget item has empty name - not showing expense linking modal")
            return
        }

        selectedBudgetItem = item
        showExpenseLinkModal = true
    }

    private func handleUnlinkExpense(expenseId: String, itemId: String) async {
        guard let scenario = currentScenario else {
            logger.warning("Cannot unlink expense: Current scenario not available")
            return
        }

        do {
            try await budgetStore.expenseStore.unlinkExpense(
                expenseId: expenseId,
                budgetItemId: itemId,
                scenarioId: scenario.id
            )
            logger.info("Expense unlinked successfully")

            // Delay to ensure database transaction commits and cache invalidation completes
            try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds

            await refreshData()
        } catch {
            logger.error("Error unlinking expense", error: error)
        }
    }

    private func handleEditGift(giftId _: String, itemId _: String) {
            }

    private func handleUnlinkGift(giftId: String) async {
        guard let giftUUID = UUID(uuidString: giftId) else {
            logger.error("Invalid gift ID format: \(giftId)")
            return
        }

        // Find the gift to unlink
        guard var gift = budgetStore.gifts.giftsAndOwed.first(where: { $0.id == giftUUID }) else {
            logger.error("Gift not found: \(giftId)")
            return
        }

        do {
            // Unlink by setting scenarioId to nil
            gift.scenarioId = nil

            // Update the gift through the gifts sub-store
            await budgetStore.gifts.updateGiftOrOwed(gift)
            logger.info("Gift unlinked successfully")

            // Delay to ensure database transaction commits and cache invalidation completes
            try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds

            await refreshData()
        } catch {
            logger.error("Error unlinking gift", error: error)
        }
    }

    private func handleAddExpense(itemId: String) {
        guard currentScenario != nil else {
            logger.warning("Cannot add expense: Current scenario not available")
            return
        }

        guard let item = budgetItems.first(where: { $0.id == itemId }) else { return }

        if item.itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            logger.warning("Budget item has empty name - not showing expense linking modal")
            return
        }

        selectedBudgetItem = item
        showExpenseLinkModal = true
    }

    private func handleAddGift(itemId: String) {
        guard currentScenario != nil else {
            logger.warning("Cannot add gift: Current scenario not available")
            return
        }

        guard let item = budgetItems.first(where: { $0.id == itemId }) else { return }
        selectedBudgetItem = item
        showGiftLinkModal = true
    }
}

#Preview {
    @Previewable @State var currentPage: BudgetPage = .budgetOverview
    
    BudgetOverviewDashboardViewV2(currentPage: $currentPage)
        .environmentObject(BudgetStoreV2())
}
