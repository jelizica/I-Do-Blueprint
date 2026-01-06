//
//  VendorSearchAndFiltersV4.swift
//  I Do Blueprint
//
//  Premium glassmorphism search bar with segmented filter tabs
//

import SwiftUI

struct VendorSearchAndFiltersV4: View {
    let windowSize: WindowSize
    @Binding var searchText: String
    @Binding var selectedFilter: VendorFilterOption
    @Binding var selectedSort: VendorSortOption

    var body: some View {
        HStack(spacing: Spacing.lg) {
            // Search Field
            searchField

            if windowSize != .compact {
                // Filter Tabs (segmented control style)
                filterTabs

                Spacer()

                // Sort Menu
                sortMenu
            }
        }
        .padding(Spacing.md)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: 0)

        // Compact mode: filters below search
        if windowSize == .compact {
            VStack(spacing: Spacing.md) {
                // Filter tabs as scrollable pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(VendorFilterOption.allCases, id: \.self) { filter in
                            FilterPillV4(
                                title: filter.displayName,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedFilter = filter
                                }
                            }
                        }

                        Divider()
                            .frame(height: 20)

                        sortMenu
                    }
                    .padding(.horizontal, Spacing.sm)
                }
            }
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(SemanticColors.textSecondary)
                .font(.body)

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
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.white.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
        .frame(minWidth: 200, maxWidth: windowSize == .compact ? .infinity : 280)
    }

    // MARK: - Filter Tabs (Segmented Control Style)

    private var filterTabs: some View {
        HStack(spacing: 0) {
            ForEach(VendorFilterOption.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.displayName)
                        .font(Typography.bodySmall)
                        .fontWeight(selectedFilter == filter ? .semibold : .regular)
                        .foregroundColor(
                            selectedFilter == filter
                                ? SemanticColors.textOnPrimary
                                : SemanticColors.textSecondary
                        )
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            selectedFilter == filter
                                ? SemanticColors.primaryAction
                                : Color.clear
                        )
                        .cornerRadius(CornerRadius.md)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.white.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(SemanticColors.borderLight, lineWidth: 1)
        )
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
                Image(systemName: "arrow.up.arrow.down")
                Text(selectedSort.groupLabel)
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .font(Typography.bodySmall)
            .foregroundColor(SemanticColors.textPrimary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(Color.white.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(SemanticColors.borderLight, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("Sort vendors")
    }
}

// MARK: - Filter Pill (Compact Mode)

struct FilterPillV4: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.bodySmall)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(
                    isSelected
                        ? SemanticColors.textOnPrimary
                        : SemanticColors.textPrimary
                )
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? SemanticColors.primaryAction
                                : Color.white.opacity(isHovered ? 0.7 : 0.5)
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected
                                ? SemanticColors.primaryAction
                                : SemanticColors.borderLight,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
