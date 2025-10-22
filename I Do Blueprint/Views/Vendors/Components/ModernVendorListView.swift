//
//  ModernVendorListView.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/9/25.
//  Modern vendor list view component
//

import SwiftUI

struct ModernVendorListView: View {
    let vendors: [Vendor]
    let totalCount: Int
    let isLoading: Bool
    let isSearching: Bool
    let onClearSearch: () -> Void
    @Binding var selectedVendorId: Int64?
    let onRefresh: () async -> Void
    var onEdit: ((Vendor) -> Void)? = nil
    var onDelete: ((Vendor) -> Void)? = nil

    var body: some View {
        ZStack {
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
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if vendors.isEmpty {
                if isSearching {
                    UnifiedEmptyStateView(config: .searchResults(query: ""))
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    UnifiedEmptyStateView(config: .vendors(onAdd: {}))
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Count header
                        ListCountHeaderView(
                            filteredCount: vendors.count,
                            totalCount: totalCount,
                            itemName: vendors.count == 1 ? "vendor" : "vendors"
                        )
                        .padding(.bottom, Spacing.sm)

                        LazyVStack(spacing: Spacing.md) {
                            ForEach(Array(vendors.enumerated()), id: \.element.id) { index, vendor in
                                Button {
                                    HapticFeedback.selectionChanged()
                                    selectedVendorId = vendor.id
                                } label: {
                                    ModernVendorCard(
                                        vendor: vendor,
                                        isSelected: selectedVendorId == vendor.id,
                                        onEdit: onEdit != nil ? { onEdit?(vendor) } : nil,
                                        onDelete: onDelete != nil ? { onDelete?(vendor) } : nil
                                    )
                                }
                                .buttonStyle(.plain)
                                .id(vendor.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .opacity
                                ))
                                .animation(
                                    AnimationPresets.gentleSpring.delay(Double(index) * 0.05),
                                    value: vendors.count
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
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(AnimationPresets.mediumEase, value: isLoading)
        .animation(AnimationPresets.mediumEase, value: vendors.isEmpty)
    }
}
