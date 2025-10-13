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
    @Binding var groupByStatus: Bool

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
        }
    }
}
