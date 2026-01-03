//
//  VendorListGrid.swift
//  I Do Blueprint
//
//  Grid layout and empty states for Vendor Management
//

import SwiftUI

struct VendorListGrid: View {
    let windowSize: WindowSize
    let loadingState: LoadingState<[Vendor]>
    let filteredVendors: [Vendor]
    let searchText: String
    let selectedFilter: VendorFilterOption
    @Binding var selectedVendor: Vendor?
    @Binding var showingAddVendor: Bool
    let onRetry: () async -> Void
    let onClearFilters: () -> Void
    
    var body: some View {
        Group {
            switch loadingState {
            case .idle:
                EmptyView()

            case .loading:
                ProgressView("Loading vendors...")
                    .frame(maxWidth: .infinity, maxHeight: 400)

            case .loaded:
                if filteredVendors.isEmpty {
                    if searchText.isEmpty && selectedFilter == .all {
                        emptyStateView
                    } else {
                        noResultsView
                    }
                } else {
                    vendorGrid
                }

            case .error(let error):
                errorView(error: error)
            }
        }
    }
    
    // MARK: - Vendor Grid
    
    private var vendorGrid: some View {
        Group {
            if windowSize == .compact {
                // Compact: Adaptive grid of vertical mini-cards
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 130), spacing: Spacing.md)],
                    alignment: .center,
                    spacing: Spacing.md
                ) {
                    ForEach(filteredVendors) { vendor in
                        VendorCompactCard(vendor: vendor)
                            .onTapGesture {
                                selectedVendor = vendor
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .clipped()
            } else {
                // Regular/Large: Adaptive grid with flexible columns (matches GuestListGrid)
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 250, maximum: 350), spacing: Spacing.lg)],
                    spacing: Spacing.lg
                ) {
                    ForEach(filteredVendors) { vendor in
                        VendorCardV3(vendor: vendor)
                            .onTapGesture {
                                selectedVendor = vendor
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - Grid Columns
    // Note: No longer needed - using adaptive columns like GuestListGrid
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(SemanticColors.textSecondary)

            Text("No Vendors Yet")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)

            Text("Add your first vendor to get started")
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)

            Button {
                showingAddVendor = true
            } label: {
                Text("Add Vendor")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textOnPrimary)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.vertical, Spacing.md)
                    .background(SemanticColors.primaryAction)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
    }
    
    // MARK: - No Results
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(SemanticColors.textSecondary)

            Text("No Vendors Found")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)

            Text("Try adjusting your search or filters")
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)

            Button {
                onClearFilters()
            } label: {
                Text("Clear Filters")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textPrimary)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.vertical, Spacing.md)
                    .background(SemanticColors.backgroundSecondary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(SemanticColors.borderLight, lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
    }
    
    // MARK: - Error View
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(SemanticColors.statusWarning)

            Text("Error Loading Vendors")
                .font(Typography.heading)
                .foregroundColor(SemanticColors.textPrimary)

            Text(error.localizedDescription)
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await onRetry()
                }
            } label: {
                Text("Retry")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textOnPrimary)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.vertical, Spacing.md)
                    .background(SemanticColors.primaryAction)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
    }
}
