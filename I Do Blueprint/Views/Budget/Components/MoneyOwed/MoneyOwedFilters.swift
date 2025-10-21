//
//  MoneyOwedFilters.swift
//  I Do Blueprint
//
//  Filter and sort components for money owed view
//

import SwiftUI

// MARK: - Money Owed Filters Section

struct MoneyOwedFiltersSection: View {
    @Binding var statusFilter: StatusFilter
    @Binding var selectedPriority: OwedPriority?
    @Binding var sortOrder: SortOrder

    var body: some View {
        VStack(spacing: 12) {
            // Status filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(StatusFilter.allCases, id: \.self) { status in
                        FilterChip(
                            title: status.rawValue,
                            isSelected: statusFilter == status,
                            action: { statusFilter = status })
                    }
                }
                .padding(.horizontal)
            }

            // Priority filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All Priorities",
                        isSelected: selectedPriority == nil,
                        action: { selectedPriority = nil })

                    ForEach(OwedPriority.allCases, id: \.self) { priority in
                        FilterChip(
                            title: priority.rawValue,
                            isSelected: selectedPriority == priority,
                            action: { selectedPriority = priority })
                    }
                }
                .padding(.horizontal)
            }

            // Sort order
            HStack {
                Text("Sort by:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button(order.rawValue) {
                            sortOrder = order
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortOrder.rawValue)
                            .font(.caption)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
        }
    }
}
