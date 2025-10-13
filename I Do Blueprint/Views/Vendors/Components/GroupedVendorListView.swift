//
//  GroupedVendorListView.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/9/25.
//  Grouped vendor list view component with status-based sections
//

import SwiftUI

struct GroupedVendorListView: View {
    let vendors: [Vendor]
    let totalCount: Int
    let isLoading: Bool
    let isSearching: Bool
    let onClearSearch: () -> Void
    @Binding var selectedVendorId: Int64?
    let onRefresh: () async -> Void

    private var groupedVendors: [(String, [Vendor])] {
        let grouped = Dictionary(grouping: vendors) { vendor in
            if vendor.isBooked == true {
                return "Booked"
            } else {
                return "Available"
            }
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        if isLoading {
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(0..<6, id: \.self) { _ in
                        VendorCardSkeleton()
                    }
                }
                .padding(Spacing.lg)
            }
            .background(AppColors.background)
        } else if vendors.isEmpty {
            if isSearching {
                SearchEmptyStateView(searchText: "", onClearSearch: onClearSearch)
            } else {
                EmptyVendorListView()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing.xl, pinnedViews: [.sectionHeaders]) {
                    ForEach(groupedVendors, id: \.0) { status, statusVendors in
                        Section {
                            LazyVStack(spacing: Spacing.md) {
                                ForEach(statusVendors, id: \.id) { vendor in
                                    Button {
                                        selectedVendorId = vendor.id
                                    } label: {
                                        ModernVendorCard(
                                            vendor: vendor,
                                            isSelected: selectedVendorId == vendor.id
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } header: {
                            VendorStatusSectionHeader(
                                status: status,
                                count: statusVendors.count
                            )
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .background(AppColors.background)
            .refreshable {
                await onRefresh()
            }
        }
    }
}
