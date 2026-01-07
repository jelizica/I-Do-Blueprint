//
//  VendorSearchAndFiltersV4.swift
//  I Do Blueprint
//
//  Search and filter bar matching guest management design
//  Features dropdown filters and consistent 40px height
//

import SwiftUI

struct VendorSearchAndFiltersV4: View {
    let windowSize: WindowSize
    @Binding var searchText: String
    @Binding var selectedFilter: VendorFilterOption
    @Binding var selectedSort: VendorSortOption

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.md) {
                // Search Field (left)
                searchField
                
                // Filter Dropdown (center)
                filterDropdown
                
                Spacer()
                
                // Sort Menu (right)
                sortMenu
            }
            .padding(Spacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(SemanticColors.textSecondary)
                .font(.system(size: 14))

            TextField("Search vendors...", text: $searchText)
                .textFieldStyle(.plain)
                .font(Typography.bodyRegular)

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
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(width: 320, height: 40)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.white.opacity(0.6))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }

    // MARK: - Filter Dropdown

    private var filterDropdown: some View {
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
                    .font(.system(size: 14))
                Text(selectedFilter.displayName)
                    .font(.system(size: 13))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
            }
            .foregroundColor(SemanticColors.textPrimary)
            .padding(.horizontal, Spacing.md)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white.opacity(0.6))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
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
            HStack(spacing: Spacing.xs) {
                Text("Sort:")
                    .font(.system(size: 11))
                    .foregroundColor(SemanticColors.textSecondary)
                
                Text("Name (A-Z)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(SemanticColors.textPrimary)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(SemanticColors.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white.opacity(0.6))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(.plain)
        .help("Sort vendors")
    }
}
