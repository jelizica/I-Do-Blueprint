//
//  ModernVendorSearchBar.swift
//  I Do Blueprint
//
//  Extracted from VendorListViewV2.swift
//

import SwiftUI

struct ModernVendorSearchBar: View {
    @Binding var searchText: String
    @Binding var selectedFilter: VendorFilterOption
    @Binding var selectedCategory: String?
    @Binding var selectedSortOption: VendorSortOption
    @Binding var groupByStatus: Bool

    var filteredCount: Int = 0
    var totalCount: Int = 0

    private var hasActiveFilters: Bool {
        selectedFilter != .all || selectedCategory != nil || !searchText.isEmpty
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Search Field
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.body)

                TextField("Search by name, category...", text: $searchText)
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
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            )

            // Filters Row
            HStack(spacing: Spacing.sm) {
                // Filter Menu
                Menu {
                    ForEach(VendorFilterOption.allCases, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            Label(filter.displayName, systemImage: filter.iconName)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(selectedFilter.displayName)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(Typography.bodySmall)
                }
                .buttonStyle(.bordered)

                // Sort Menu
                Menu {
                    ForEach(VendorSortOption.grouped, id: \.0) { group in
                        Section(group.0) {
                            ForEach(group.1) { option in
                                Button {
                                    selectedSortOption = option
                                } label: {
                                    HStack {
                                        Label(option.displayName, systemImage: option.iconName)
                                        if selectedSortOption == option {
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
                        Text(selectedSortOption.groupLabel)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(Typography.bodySmall)
                }
                .buttonStyle(.bordered)
                .help("Sort vendors")

                Spacer()

                // Group Toggle
                Button {
                    groupByStatus.toggle()
                } label: {
                    Image(systemName: groupByStatus ? "square.grid.2x2" : "list.bullet")
                        .font(.body)
                }
                .buttonStyle(.bordered)
                .help(groupByStatus ? "List View" : "Group View")

                // Clear Filters
                if selectedFilter != .all || selectedCategory != nil {
                    Button {
                        selectedFilter = .all
                        selectedCategory = nil
                    } label: {
                        Text("Clear")
                            .font(Typography.bodySmall)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(AppColors.primary)
                }
            }

            // Active Filter Chips
            if hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Filter option chip
                        if selectedFilter != .all {
                            ActiveFilterChip(label: "Filter: \(selectedFilter.displayName)") {
                                selectedFilter = .all
                            }
                        }

                        // Category filter chip
                        if let category = selectedCategory {
                            ActiveFilterChip(label: "Category: \(category)") {
                                selectedCategory = nil
                            }
                        }

                        // Search filter chip
                        if !searchText.isEmpty {
                            ActiveFilterChip(label: "Search: \"\(searchText)\"") {
                                searchText = ""
                            }
                        }

                        // Result count
                        if totalCount > 0 {
                            Text("\(filteredCount) of \(totalCount) vendors")
                                .font(.caption)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.leading, Spacing.xs)
                        }

                        Spacer()

                        // Clear all button
                        Button("Clear all") {
                            searchText = ""
                            selectedFilter = .all
                            selectedCategory = nil
                        }
                        .font(.caption)
                        .foregroundColor(AppColors.primary)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Spacing.sm)
                }
            }
        }
    }
}
