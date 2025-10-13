//
//  SearchField.swift
//  I Do Blueprint
//
//  Shared search field component with clear button and accessibility
//

import SwiftUI

struct SearchField: View {
    @Binding var searchText: String
    var placeholder: String = "Search"
    var onClear: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            TextField(placeholder, text: $searchText)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .accessibilityLabel(placeholder)
                .accessibilityValue(searchText.isEmpty ? "Empty" : searchText)

            if !searchText.isEmpty {
                Button(action: clearSearch) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
                .accessibilityHint("Clears the current search text")
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    private func clearSearch() {
        searchText = ""
        onClear?()
        isFocused = false
    }
}

// MARK: - Search with Quick Filters

struct SearchFieldWithFilters<FilterType: Hashable>: View {
    @Binding var searchText: String
    @Binding var selectedFilter: FilterType?
    let filters: [FilterType]
    let filterLabel: (FilterType) -> String
    var placeholder: String = "Search"
    var onClear: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            SearchField(
                searchText: $searchText,
                placeholder: placeholder,
                onClear: onClear
            )

            if !filters.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { filter in
                            SharedFilterChip(
                                title: filterLabel(filter),
                                isSelected: selectedFilter == filter,
                                action: {
                                    if selectedFilter == filter {
                                        selectedFilter = nil
                                    } else {
                                        selectedFilter = filter
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Filter Chip

struct SharedFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
        )
        .foregroundColor(isSelected ? .white : .primary)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to filter by \(title)")
    }
}

// MARK: - Previews

#Preview("Search Field") {
    @Previewable @State var searchText = ""

    SearchField(searchText: $searchText, placeholder: "Search guests")
        .padding()
}

#Preview("Search Field with Text") {
    @Previewable @State var searchText = "John"

    SearchField(searchText: $searchText, placeholder: "Search guests")
        .padding()
}

#Preview("Search with Filters") {
    @Previewable @State var searchText = ""
    @Previewable @State var selectedFilter: String? = nil

    SearchFieldWithFilters(
        searchText: $searchText,
        selectedFilter: $selectedFilter,
        filters: ["All", "Confirmed", "Pending", "Declined"],
        filterLabel: { $0 },
        placeholder: "Search guests"
    )
    .padding()
}

#Preview("Search with Filters - Selected") {
    @Previewable @State var searchText = "Smith"
    @Previewable @State var selectedFilter: String? = "Confirmed"

    SearchFieldWithFilters(
        searchText: $searchText,
        selectedFilter: $selectedFilter,
        filters: ["All", "Confirmed", "Pending", "Declined"],
        filterLabel: { $0 },
        placeholder: "Search guests"
    )
    .padding()
}
