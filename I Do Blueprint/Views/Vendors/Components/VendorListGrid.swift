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
        LazyVGrid(
            columns: gridColumns(for: windowSize),
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
    
    // MARK: - Grid Columns
    
    private func gridColumns(for windowSize: WindowSize) -> [GridItem] {
        switch windowSize {
        case .compact:
            // 2 columns in compact
            return Array(repeating: GridItem(.flexible(), spacing: Spacing.lg), count: 2)
        case .regular:
            // 3 columns in regular
            return Array(repeating: GridItem(.flexible(), spacing: Spacing.lg), count: 3)
        case .large:
            // 4 columns in large
            return Array(repeating: GridItem(.flexible(), spacing: Spacing.lg), count: 4)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)

            Text("No Vendors Yet")
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)

            Text("Add your first vendor to get started")
                .font(Typography.bodySmall)
                .foregroundColor(AppColors.textSecondary)

            Button {
                showingAddVendor = true
            } label: {
                Text("Add Vendor")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
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
                .foregroundColor(AppColors.textSecondary)

            Text("No Vendors Found")
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)

            Text("Try adjusting your search or filters")
                .font(Typography.bodySmall)
                .foregroundColor(AppColors.textSecondary)

            Button {
                onClearFilters()
            } label: {
                Text("Clear Filters")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.cardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.borderLight, lineWidth: 0.5)
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
                .foregroundColor(AppColors.error)

            Text("Error Loading Vendors")
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)

            Text(error.localizedDescription)
                .font(Typography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await onRetry()
                }
            } label: {
                Text("Retry")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.vertical, Spacing.md)
                    .background(AppColors.primary)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
    }
}
