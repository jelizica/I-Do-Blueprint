//
//  VendorSearchAndFilters.swift
//  I Do Blueprint
//
//  Search and filter controls for Vendor Management
//

import SwiftUI

struct VendorSearchAndFilters: View {
    @Binding var searchText: String
    @Binding var selectedFilter: VendorFilterOption
    @Binding var selectedSort: VendorSortOption
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Single Row: Search + Filter Toggles + Sort + Clear
            HStack(spacing: Spacing.sm) {
                searchField
                filterToggles
                Spacer()
                sortMenu
                clearFiltersButton
            }
            .padding(Spacing.lg)
            .background(AppColors.cardBackground)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Search Field
    
    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)
                .font(.body)

            TextField("Search vendors...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.sm)
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
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
                    .fill(selectedFilter == filter ? AppColors.primary : AppColors.cardBackground)
            )
            .foregroundColor(selectedFilter == filter ? .white : AppColors.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.pill)
                    .stroke(selectedFilter == filter ? AppColors.primary : AppColors.border, lineWidth: 1)
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
                                        .foregroundColor(AppColors.primary)
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
    
    // MARK: - Clear Filters Button
    
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
            .foregroundColor(AppColors.primary)
        }
    }
}
