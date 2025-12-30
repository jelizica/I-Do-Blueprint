//
//  ExpenseCategoriesView.swift
//  I Do Blueprint
//
//  Main view for managing budget expense categories
//

import SwiftUI

struct ExpenseCategoriesView: View {
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @State private var showingAddCategory = false
    @State private var editingCategory: BudgetCategory?
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: BudgetCategory?

    private var filteredCategories: [BudgetCategory] {
        let categories = budgetStore.categoryStore.categories

        let searchFiltered = searchText.isEmpty ? categories : categories.filter { category in
            category.categoryName.localizedCaseInsensitiveContains(searchText)
        }

        return searchFiltered.sorted { $0.categoryName < $1.categoryName }
    }

    private var parentCategories: [BudgetCategory] {
        filteredCategories.filter { $0.parentCategoryId == nil }
    }

    private func subcategories(for parent: BudgetCategory) -> [BudgetCategory] {
        filteredCategories.filter { $0.parentCategoryId == parent.id }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ExpenseCategoriesHeaderView(
                categoryCount: filteredCategories.count,
                searchText: $searchText,
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
