//
//  VendorSearchAndFilters.swift
//  I Do Blueprint
//
//  Search and filter controls for Vendor Management
//

import SwiftUI

struct VendorSearchAndFilters: View {
    let windowSize: WindowSize
    @Binding var searchText: String
    @Binding var selectedFilter: VendorFilterOption
    @Binding var selectedSort: VendorSortOption
    
    private var hasActiveFilters: Bool {
        selectedFilter != .all || !searchText.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if windowSize == .compact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(SemanticColors.backgroundSecondary)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Compact Layout
    
    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Search bar (full width)
            searchField
            
            // Filter menu + Sort menu row
            HStack(spacing: Spacing.sm) {
                statusFilterMenu
                    .frame(maxWidth: .infinity, alignment: .leading)
                sortMenu
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Clear filters button (centered, only when active)
            if hasActiveFilters {
                HStack {
                    Spacer()
                    clearAllFiltersButton
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Regular Layout
    
    private var regularLayout: some View {
        HStack(spacing: Spacing.sm) {
            searchField
            filterToggles
            Spacer()
            sortMenu
            if hasActiveFilters {
                clearFiltersButton
            }
        }
    }
    
    // MARK: - Status Filter Menu (Compact Mode)
    
    private var statusFilterMenu: some View {
        Menu {
            ForEach(VendorFilterOption.allCases, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    HStack {
                        Text(filter.displayName)
                        if selectedFilter == filter {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.caption)
                Text(selectedFilter.displayName)
                    .font(Typography.bodySmall)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.bordered)
        .tint(SemanticColors.primaryAction)
        .help("Filter by vendor status")
    }
    
    // MARK: - Search Field
    
    @ViewBuilder
    private var searchField: some View {
        let content = HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(SemanticColors.textSecondary)
                .font(.body)

            TextField("Search vendors...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(SemanticColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.sm)
        
        if windowSize == .compact {
            content
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(SemanticColors.backgroundSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                        )
                )
        } else {
            content
                .frame(minWidth: 150, idealWidth: 200, maxWidth: 250)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(SemanticColors.backgroundSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(SemanticColors.borderPrimary, lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - Filter Toggles
    
    private var filterToggles: some View {
        ForEach(VendorFilterOption.allCases, id: \.self) { filter in
            Button {
                selectedFilter = filter
            } label: {
                Text(filter.displayName)
                    .font(Typography.bodySmall)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.pill)
                    .fill(selectedFilter == filter ? SemanticColors.primaryAction : SemanticColors.backgroundSecondary)
            )
            .foregroundColor(selectedFilter == filter ? .white : SemanticColors.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.pill)
                    .stroke(selectedFilter == filter ? SemanticColors.primaryAction : SemanticColors.borderPrimary, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Sort Menu
    
    private var sortMenu: some View {
        Menu {
            ForEach(VendorSortOption.grouped, id: \.0) { group in
                Section(group.0) {
                    ForEach(group.1) { option in
                        Button {
                            selectedSort = option
                        } label: {
                            HStack {
                                Label(option.displayName, systemImage: option.iconName)
                                if selectedSort == option {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(SemanticColors.primaryAction)
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                Text(selectedSort.groupLabel)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .font(Typography.bodySmall)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.bordered)
        .help("Sort vendors")
    }
    
    // MARK: - Clear All Filters Button (Compact Mode)
    
    private var clearAllFiltersButton: some View {
        Button {
            searchText = ""
            selectedFilter = .all
        } label: {
            Text("Clear All Filters")
                .font(Typography.bodySmall)
        }
        .buttonStyle(.borderless)
        .foregroundColor(SemanticColors.primaryAction)
    }
    
    // MARK: - Clear Filters Button (Regular Mode)
    
    @ViewBuilder
    private var clearFiltersButton: some View {
        if selectedFilter != .all || !searchText.isEmpty {
            Button {
                searchText = ""
                selectedFilter = .all
            } label: {
                Text("Clear")
                    .font(Typography.bodySmall)
            }
            .buttonStyle(.borderless)
            .foregroundColor(SemanticColors.primaryAction)
        }
    }
}
