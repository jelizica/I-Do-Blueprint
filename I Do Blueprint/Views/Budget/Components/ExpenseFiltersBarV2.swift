//
//  ExpenseFiltersBarV2.swift
//  I Do Blueprint
//
//  Responsive filter bar for Expense Tracker
//  Follows collapsible filter menu pattern from Guest Management
//

import SwiftUI

struct ExpenseFiltersBarV2: View {
    let windowSize: WindowSize
    @Binding var searchText: String
    @Binding var selectedFilterStatus: PaymentStatus?
    @Binding var selectedCategoryFilter: Set<UUID>
    @Binding var viewMode: ExpenseViewMode
    @Binding var showBenchmarks: Bool
    let categories: [BudgetCategory]
    
    // Filter to parent categories only
    private var parentCategories: [BudgetCategory] {
        categories.filter { $0.parentCategoryId == nil }
    }
    
    private var hasActiveFilters: Bool {
        selectedFilterStatus != nil || !selectedCategoryFilter.isEmpty || !searchText.isEmpty
    }
    
    // Display text for category filter
    private var categoryDisplayText: String {
        if selectedCategoryFilter.isEmpty {
            return "Category"
        } else if selectedCategoryFilter.count == 1 {
            // Show single category name
            guard let firstId = selectedCategoryFilter.first,
                  let category = parentCategories.first(where: { $0.id == firstId }) else {
                return "Category"
            }
            return category.categoryName
        } else {
            // Show "FirstCategory +X more"
            guard let firstId = selectedCategoryFilter.first,
                  let category = parentCategories.first(where: { $0.id == firstId }) else {
                return "Category"
            }
            return "\(category.categoryName) +\(selectedCategoryFilter.count - 1) more"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if windowSize == .compact {
                compactLayout
            } else {
                regularLayout
            }
            
            // Clear all button (centered, conditional)
            if hasActiveFilters {
                HStack {
                    Spacer()
                    clearAllFiltersButton
                    Spacer()
                }
            }
        }
        .padding(Spacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.lg)
    }
    
    // MARK: - Compact Layout
    
    private var compactLayout: some View {
        VStack(spacing: Spacing.sm) {
            // Full-width search
            searchField
                .frame(maxWidth: .infinity)
            
            // Filter controls row
            HStack(spacing: Spacing.sm) {
                statusFilterMenu
                categoryFilterMenu
                viewModeToggleCompact
                benchmarksToggle
            }
        }
    }
    
    // MARK: - Regular Layout
    
    private var regularLayout: some View {
        HStack(spacing: Spacing.md) {
            searchField
                .frame(minWidth: 150, idealWidth: 200, maxWidth: 300)
            
            Picker("Status", selection: $selectedFilterStatus) {
                Text("All Status").tag(nil as PaymentStatus?)
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(status as PaymentStatus?)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)
            
            // Multi-select category menu (regular mode)
            Menu {
                Button("Clear All") {
                    selectedCategoryFilter = []
                }
                
                Divider()
                
                ForEach(parentCategories) { category in
                    Button {
                        if selectedCategoryFilter.contains(category.id) {
                            selectedCategoryFilter.remove(category.id)
                        } else {
                            selectedCategoryFilter.insert(category.id)
                        }
                    } label: {
                        HStack {
                            Text(category.categoryName)
                            if selectedCategoryFilter.contains(category.id) {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text(categoryDisplayText)
            }
            .frame(width: 200)
            
            Spacer()
            
            ExpenseViewModeToggle(viewMode: $viewMode)
            benchmarksToggle
        }
    }
    
    // MARK: - Search Field
    
    @ViewBuilder
    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
                .font(.system(size: 14))
            
            TextField("Search expenses...", text: $searchText)
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.sm)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
    
    // MARK: - Filter Menus (Compact)
    
    private var statusFilterMenu: some View {
        ZStack(alignment: .trailing) {
            Menu {
                Button("All Status") { selectedFilterStatus = nil }
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    Button(status.displayName) { selectedFilterStatus = status }
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.caption)
                    Text(selectedFilterStatus?.displayName ?? "Status")
                        .font(Typography.bodySmall)
                        .lineLimit(1)
                    if selectedFilterStatus == nil {
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.primary)
            
            // X clear button overlay
            if selectedFilterStatus != nil {
                Button {
                    selectedFilterStatus = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.primary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, Spacing.sm)
            }
        }
    }
    
    private var categoryFilterMenu: some View {
        ZStack(alignment: .trailing) {
            Menu {
                Button("Clear All") {
                    selectedCategoryFilter = []
                }
                
                Divider()
                
                // Parent categories only
                ForEach(parentCategories) { category in
                    Button {
                        if selectedCategoryFilter.contains(category.id) {
                            selectedCategoryFilter.remove(category.id)
                        } else {
                            selectedCategoryFilter.insert(category.id)
                        }
                    } label: {
                        HStack {
                            Text(category.categoryName)
                            if selectedCategoryFilter.contains(category.id) {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "folder")
                        .font(.caption)
                    Text(categoryDisplayText)
                        .font(Typography.bodySmall)
                        .lineLimit(1)
                    if selectedCategoryFilter.isEmpty {
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.bordered)
            .tint(.teal)
            
            // X clear button overlay
            if !selectedCategoryFilter.isEmpty {
                Button {
                    selectedCategoryFilter = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.teal)
                }
                .buttonStyle(.plain)
                .padding(.trailing, Spacing.sm)
            }
        }
    }
    
    // MARK: - View Mode Toggle (Compact)
    
    private var viewModeToggleCompact: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewMode = viewMode == .cards ? .list : .cards
            }
        } label: {
            Image(systemName: viewMode.icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 36, height: 36)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(viewMode == .cards ? "Switch to List" : "Switch to Cards")
    }
    
    // MARK: - Benchmarks Toggle
    
    private var benchmarksToggle: some View {
        Button {
            withAnimation { showBenchmarks.toggle() }
        } label: {
            Image(systemName: showBenchmarks ? "chart.bar.fill" : "chart.bar")
                .font(.system(size: 16))
                .foregroundColor(showBenchmarks ? AppColors.primary : AppColors.textPrimary)
                .frame(width: 36, height: 36)
                .background(showBenchmarks ? AppColors.primary.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(showBenchmarks ? "Hide Benchmarks" : "Show Benchmarks")
    }
    
    // MARK: - Clear All Filters Button
    
    private var clearAllFiltersButton: some View {
        Button {
            withAnimation {
                searchText = ""
                selectedFilterStatus = nil
                selectedCategoryFilter = []
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "xmark.circle")
                    .font(.caption)
                Text("Clear All Filters")
                    .font(Typography.bodySmall)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .foregroundColor(AppColors.primary)
        }
        .buttonStyle(.plain)
    }
}
