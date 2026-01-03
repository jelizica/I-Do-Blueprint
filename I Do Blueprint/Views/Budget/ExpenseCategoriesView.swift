//
//  ExpenseCategoriesView.swift
//  I Do Blueprint
//
//  Main view for managing budget expense categories with responsive compact window support
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
    
    // Dual initializer pattern
    init(currentPage: Binding<BudgetPage>) {
        self._currentPage = currentPage
    }
    
    init() {
        self._currentPage = .constant(.expenseCategories)
    }

    private var filteredCategories: [BudgetCategory] {
        let categories = budgetStore.categoryStore.categories

        let searchFiltered = searchText.isEmpty ? categories : categories.filter { category in
            category.categoryName.localizedCaseInsensitiveContains(searchText)
        }

        return searchFiltered.sorted { $0.categoryName < $1.categoryName }
    }

    private var parentCategories: [BudgetCategory] {
        let parents = filteredCategories.filter { $0.parentCategoryId == nil }
        
        // Apply over-budget filter if active
        if showOnlyOverBudget {
            return parents.filter { parent in
                isOverBudget(parent)
            }
        }
        
        return parents
    }
    
    private var parentCategoryCount: Int {
        budgetStore.categoryStore.categories.filter { $0.parentCategoryId == nil }.count
    }
    
    private var subcategoryCount: Int {
        budgetStore.categoryStore.categories.filter { $0.parentCategoryId != nil }.count
    }
    
    private func isOverBudget(_ category: BudgetCategory) -> Bool {
        let spent = budgetStore.categoryStore.spentAmount(for: category.id, expenses: budgetStore.expenseStore.expenses)
        return spent > category.allocatedAmount && category.allocatedAmount > 0
    }

    private func subcategories(for parent: BudgetCategory) -> [BudgetCategory] {
        filteredCategories.filter { $0.parentCategoryId == parent.id }
    }
    
    // MARK: - Computed Properties for Summary Cards
    
    private var totalCategoryCount: Int {
        budgetStore.categoryStore.categories.count
    }
    
    private var totalAllocated: Double {
        budgetStore.categoryStore.categories.reduce(0) { $0 + $1.allocatedAmount }
    }
    
    private var totalSpent: Double {
        budgetStore.categoryStore.categories.reduce(0) { total, category in
            total + budgetStore.categoryStore.spentAmount(for: category.id, expenses: budgetStore.expenseStore.expenses)
        }
    }
    
    private var overBudgetCount: Int {
        budgetStore.categoryStore.categories.filter { category in
            let spent = budgetStore.categoryStore.spentAmount(for: category.id, expenses: budgetStore.expenseStore.expenses)
            return spent > category.allocatedAmount && category.allocatedAmount > 0
        }.count
    }
    
    // MARK: - Section Management
    
    private func expandAllSections() {
        expandedSections = Set(parentCategories.map { $0.id })
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
            let availableWidth = geometry.size.width - (horizontalPadding * 2)
            
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
                
                // Static Header
                ExpenseCategoriesStaticHeader(
                    windowSize: windowSize,
                    searchText: $searchText,
                    showOnlyOverBudget: $showOnlyOverBudget,
                    parentCount: parentCategoryCount,
                    subcategoryCount: subcategoryCount,
                    overBudgetCount: overBudgetCount,
                    onAddCategory: { showingAddCategory = true }
                )

                // Categories List
                if filteredCategories.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Categories" : "No Results",
                        systemImage: searchText.isEmpty ? "folder" : "magnifyingglass",
                        description: Text(searchText.isEmpty ?
                            "Create your first budget category to start organizing expenses" :
                            "Try adjusting your search terms"))
                } else {
                    List {
                        ForEach(parentCategories, id: \.id) { parentCategory in
                            CategorySectionView(
                                parentCategory: parentCategory,
                                subcategories: subcategories(for: parentCategory),
                                budgetStore: budgetStore,
                                onEdit: { category in
                                    editingCategory = category
                                },
                                onDelete: { category in
                                    categoryToDelete = category
                                    showingDeleteAlert = true
                                })
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .task {
                await budgetStore.loadBudgetData(force: true)
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView(budgetStore: budgetStore)
            }
            .sheet(item: $editingCategory) { category in
                EditCategoryView(category: category, budgetStore: budgetStore)
            }
            .alert("Delete Category", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let category = categoryToDelete {
                        Task {
                            do {
                                try await budgetStore.categoryStore.deleteCategory(id: category.id)
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
        }
    }
}

// MARK: - Header View

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
