//
//  ExpenseCategoriesView.swift
//  I Do Blueprint
//
//  Main view for managing budget expense categories with responsive compact window support
//
//  ARCHITECTURE NOTE (2026-01-03):
//  This view follows the same pattern as ExpenseTrackerView, PaymentScheduleView, and
//  BudgetDevelopmentView - NO timer-based polling. Data is loaded once on appear and
//  recalculated only when user actions occur (search, filter, add/edit/delete).
//  
//  The previous timer-based polling caused freezes after ~5 minutes due to:
//  1. Timer firing every 0.5s accessing store properties
//  2. Store access triggering objectWillChange (via @EnvironmentObject subscription)
//  3. objectWillChange forwarding from sub-stores to BudgetStoreV2
//  4. Feedback loop accumulating over time
//

import SwiftUI

struct ExpenseCategoriesView: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @Binding var currentPage: BudgetPage
    
    @State private var showingAddCategory = false
    @State private var editingCategory: BudgetCategory?
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: BudgetCategory?
    @State private var expandedSections: Set<UUID> = []
    @State private var showOnlyOverBudget = false
    @State private var categoryToMove: BudgetCategory?
    
    // MARK: - Cached Values (to avoid expensive recalculations on scroll)
    // These are populated once on load and updated only when user actions occur
    @State private var cachedTotalAllocated: Double = 0
    @State private var cachedTotalSpent: Double = 0
    @State private var cachedOverBudgetCount: Int = 0
    @State private var cachedSpentByCategory: [UUID: Double] = [:]
    @State private var cachedParentCount: Int = 0
    @State private var cachedSubcategoryCount: Int = 0
    @State private var cachedFilteredCategories: [BudgetCategory] = []
    @State private var cachedParentCategories: [BudgetCategory] = []
    @State private var cachedSubcategoriesByParent: [UUID: [BudgetCategory]] = [:]
    @State private var cachedTotalCategoryCount: Int = 0
    @State private var hasCategories: Bool = false
    
    // Loading state
    @State private var isLoading: Bool = true
    
    // Dual initializer pattern
    init(currentPage: Binding<BudgetPage>) {
        self._currentPage = currentPage
    }
    
    init() {
        self._currentPage = .constant(.expenseCategories)
    }
    
    // MARK: - Data Calculation
    
    /// Recalculate ALL cached values synchronously on main thread
    /// Called only when:
    /// 1. View first appears (.task)
    /// 2. User changes search text (.onChange)
    /// 3. User changes filter (.onChange)
    /// 4. After add/edit/delete operations (sheet onDismiss)
    private func recalculateCachedValues() {
        // Capture current state ONCE (single store access)
        let allCategories = budgetStore.categoryStore.categories
        let expenses = budgetStore.expenseStore.expenses
        let currentSearchText = searchText
        let currentShowOnlyOverBudget = showOnlyOverBudget
        
        // Build spent-by-category dictionary ONCE (O(n) for expenses)
        var spentByCategory: [UUID: Double] = [:]
        for expense in expenses {
            let categoryId = expense.budgetCategoryId
            spentByCategory[categoryId, default: 0] += expense.amount
        }
        
        // Build set of parent IDs (categories that have children)
        let parentIds = Set(allCategories.compactMap { $0.parentCategoryId })
        
        // Find leaf categories (no children) - for accurate totals
        let leaves = allCategories.filter { !parentIds.contains($0.id) }
        
        // Calculate totals using the pre-computed dictionary
        let totalAllocated = leaves.reduce(0) { $0 + $1.allocatedAmount }
        
        let totalSpent = leaves.reduce(0) { total, category in
            total + (spentByCategory[category.id] ?? 0)
        }
        
        let overBudgetCount = allCategories.filter { category in
            let spent = spentByCategory[category.id] ?? 0
            return spent > category.allocatedAmount && category.allocatedAmount > 0
        }.count
        
        // Calculate parent/subcategory counts
        let parentCount = allCategories.filter { $0.parentCategoryId == nil }.count
        let subcategoryCountVal = allCategories.filter { $0.parentCategoryId != nil }.count
        
        // Calculate filtered categories (with search)
        let searchFiltered = currentSearchText.isEmpty ? allCategories : allCategories.filter { category in
            category.categoryName.localizedCaseInsensitiveContains(currentSearchText)
        }
        let filtered = searchFiltered.sorted { $0.categoryName < $1.categoryName }
        
        // Calculate parent categories from filtered list
        var parents = filtered.filter { $0.parentCategoryId == nil }
        
        // Apply over-budget filter if active (using pre-computed spentByCategory)
        if currentShowOnlyOverBudget {
            parents = parents.filter { category in
                let spent = spentByCategory[category.id] ?? 0
                return spent > category.allocatedAmount && category.allocatedAmount > 0
            }
        }
        
        // Build subcategories-by-parent dictionary for ALL categories (not just top-level)
        // This enables proper N-level hierarchy display when folders are nested
        var subcategoriesByParent: [UUID: [BudgetCategory]] = [:]
        for category in allCategories {
            let children = filtered.filter { $0.parentCategoryId == category.id }
            if !children.isEmpty {
                subcategoriesByParent[category.id] = children
            }
        }
        
        // Update all cached values at once
        cachedSpentByCategory = spentByCategory
        cachedTotalAllocated = totalAllocated
        cachedTotalSpent = totalSpent
        cachedOverBudgetCount = overBudgetCount
        cachedParentCount = parentCount
        cachedSubcategoryCount = subcategoryCountVal
        cachedFilteredCategories = filtered
        cachedParentCategories = parents
        cachedSubcategoriesByParent = subcategoriesByParent
        cachedTotalCategoryCount = allCategories.count
        hasCategories = !allCategories.isEmpty
        isLoading = false
    }
    
    // MARK: - Section Management
    
    private func expandAllSections() {
        // Use cached parent categories to avoid store access
        expandedSections = Set(cachedParentCategories.map { $0.id })
    }
    
    private func collapseAllSections() {
        expandedSections.removeAll()
    }
    
    // MARK: - Import/Export
    
    private func exportCategories() {
        AppLogger.ui.info("Export categories - Not yet implemented")
        // TODO: Implement CSV export
    }
    
    private func importCategories() {
        AppLogger.ui.info("Import categories - Not yet implemented")
        // TODO: Implement CSV import
    }

    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.xl
            
            VStack(spacing: 0) {
                // Unified Header
                ExpenseCategoriesUnifiedHeader(
                    windowSize: windowSize,
                    currentPage: $currentPage,
                    onExpandAll: expandAllSections,
                    onCollapseAll: collapseAllSections,
                    onExport: exportCategories,
                    onImport: importCategories
                )
                
                // Static Header - use cached counts
                ExpenseCategoriesStaticHeader(
                    windowSize: windowSize,
                    searchText: $searchText,
                    showOnlyOverBudget: $showOnlyOverBudget,
                    parentCount: cachedParentCount,
                    subcategoryCount: cachedSubcategoryCount,
                    overBudgetCount: cachedOverBudgetCount,
                    onAddCategory: { showingAddCategory = true }
                )

                // Content: Summary Cards + Categories - USE ONLY CACHED VALUES
                if isLoading {
                    // Loading state
                    VStack {
                        Spacer()
                        ProgressView("Loading categories...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if cachedFilteredCategories.isEmpty && !hasCategories {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Categories" : "No Results",
                        systemImage: searchText.isEmpty ? "folder" : "magnifyingglass",
                        description: Text(searchText.isEmpty ?
                            "Create your first budget category to start organizing expenses" :
                            "Try adjusting your search terms"))
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Summary Cards - use cached values
                            ExpenseCategoriesSummaryCards(
                                windowSize: windowSize,
                                totalCategories: cachedParentCount + cachedSubcategoryCount,
                                totalAllocated: cachedTotalAllocated,
                                totalSpent: cachedTotalSpent,
                                overBudgetCount: cachedOverBudgetCount
                            )
                            .padding(.horizontal, horizontalPadding)
                            .padding(.top, Spacing.lg)
                            .padding(.bottom, Spacing.md)
                            
                            // Categories List - USE CACHED parent categories and subcategories
                            LazyVStack(spacing: Spacing.sm) {
                                ForEach(cachedParentCategories, id: \.id) { parentCategory in
                                    CategorySectionViewV2(
                                        windowSize: windowSize,
                                        parentCategory: parentCategory,
                                        subcategories: cachedSubcategoriesByParent[parentCategory.id] ?? [],
                                        budgetStore: budgetStore,
                                        spentByCategory: cachedSpentByCategory,
                                        allSubcategoriesByParent: cachedSubcategoriesByParent,
                                        onEdit: { category in
                                            editingCategory = category
                                        },
                                        onDelete: { category in
                                            categoryToDelete = category
                                            showingDeleteAlert = true
                                        },
                                        onMove: { category in
                                            categoryToMove = category
                                        },
                                        isExpanded: Binding(
                                            get: { expandedSections.contains(parentCategory.id) },
                                            set: { isExpanded in
                                                if isExpanded {
                                                    expandedSections.insert(parentCategory.id)
                                                } else {
                                                    expandedSections.remove(parentCategory.id)
                                                }
                                            }
                                        )
                                    )
                                    .padding(.horizontal, horizontalPadding)
                                }
                            }
                            .padding(.bottom, Spacing.lg)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            // MARK: - Data Loading (follows ExpenseTrackerView pattern)
            // Load data ONCE on appear, no timer-based polling
            .task {
                await budgetStore.loadBudgetData(force: false)
                recalculateCachedValues()
            }
            // Recalculate when search text changes (debounced by SwiftUI)
            .onChange(of: searchText) { _, _ in
                recalculateCachedValues()
            }
            // Recalculate when over-budget filter changes
            .onChange(of: showOnlyOverBudget) { _, _ in
                recalculateCachedValues()
            }
            // MARK: - Sheets with onDismiss to refresh data
            .sheet(isPresented: $showingAddCategory, onDismiss: {
                // Refresh data after adding a category
                recalculateCachedValues()
            }) {
                AddCategoryView(budgetStore: budgetStore)
            }
            .sheet(item: $editingCategory, onDismiss: {
                // Refresh data after editing a category
                recalculateCachedValues()
            }) { category in
                EditCategoryView(category: category, budgetStore: budgetStore)
            }
            .alert("Delete Category", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let category = categoryToDelete {
                        Task {
                            do {
                                try await budgetStore.categoryStore.deleteCategory(id: category.id)
                                // Refresh data after deletion
                                recalculateCachedValues()
                            } catch {
                                AppLogger.ui.error("Failed to delete category", error: error)
                            }
                        }
                    }
                }
            } message: {
                if let category = categoryToDelete {
                    Text("Are you sure you want to delete '\(category.categoryName)'? This action cannot be undone.")
                }
            }
            .sheet(item: $categoryToMove, onDismiss: {
                // Refresh data after moving a category
                recalculateCachedValues()
            }) { category in
                MoveCategorySheet(
                    category: category,
                    allCategories: budgetStore.categoryStore.categories,
                    onMove: { newParentId in
                        Task {
                            do {
                                _ = try await budgetStore.categoryStore.moveCategory(
                                    id: category.id,
                                    toParent: newParentId
                                )
                                recalculateCachedValues()
                            } catch {
                                AppLogger.ui.error("Failed to move category", error: error)
                            }
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Header View (Legacy - kept for reference)

private struct ExpenseCategoriesHeaderView: View {
    let categoryCount: Int
    @Binding var searchText: String
    let onAddCategory: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expense Categories")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("\(categoryCount) categories")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onAddCategory) {
                    Label("Add Category", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search categories...", text: $searchText)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}
