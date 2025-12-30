//
//  MilestonesControlsSection.swift
//  I Do Blueprint
//
//  Extracted from AllMilestonesView.swift as part of complexity reduction refactoring
//

import SwiftUI

/// Controls section with search and filter/sort options
struct MilestonesControlsSection: View {
    @Binding var searchQuery: String
    @Binding var selectedFilter: MilestoneFilter
    @Binding var sortOrder: MilestoneSortOrder
    
    var body: some View {
        VStack(spacing: 12) {
            // Search bar
            SearchBar(
                text: $searchQuery,
                placeholder: "Search milestones..."
            )
            
            // Filter and sort controls
            HStack(spacing: 12) {
                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(MilestoneFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                
                // Sort order button
                Menu {
                    ForEach(MilestoneSortOrder.allCases, id: \.self) { order in
                        Button(action: { sortOrder = order }) {
                            HStack {
                                Text(order.displayName)
                                if sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOrder.shortName)
                    }
                    .font(.caption)
                }
                .frame(width: 100)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}
