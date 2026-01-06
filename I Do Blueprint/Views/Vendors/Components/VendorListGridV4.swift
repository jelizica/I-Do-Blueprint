//
//  VendorListGridV4.swift
//  I Do Blueprint
//
//  Premium grid layout for Vendor Management V4 with glassmorphism cards
//

import SwiftUI

struct VendorListGridV4: View {
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
                loadingView

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

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading vendors...")
                .font(Typography.bodyRegular)
                .foregroundColor(SemanticColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xxl)
    }

    // MARK: - Vendor Grid

    private var vendorGrid: some View {
        LazyVGrid(
            columns: gridColumns,
            spacing: Spacing.lg
        ) {
            ForEach(filteredVendors) { vendor in
                VendorCardV4(vendor: vendor)
                    .onTapGesture {
                        selectedVendor = vendor
                    }
            }
        }
    }

    private var gridColumns: [GridItem] {
        switch windowSize {
        case .compact:
            // 2 columns on compact
            return [
                GridItem(.flexible(), spacing: Spacing.md),
                GridItem(.flexible(), spacing: Spacing.md)
            ]
        case .regular:
            // 3 columns on regular
            return [
                GridItem(.flexible(), spacing: Spacing.lg),
                GridItem(.flexible(), spacing: Spacing.lg),
                GridItem(.flexible(), spacing: Spacing.lg)
            ]
        case .large:
            // 4 columns on large
            return [
                GridItem(.flexible(), spacing: Spacing.lg),
                GridItem(.flexible(), spacing: Spacing.lg),
                GridItem(.flexible(), spacing: Spacing.lg),
                GridItem(.flexible(), spacing: Spacing.lg)
            ]
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            // Icon
            Circle()
                .fill(SemanticColors.primaryAction.opacity(Opacity.light))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 32))
                        .foregroundColor(SemanticColors.primaryAction)
                )

            VStack(spacing: Spacing.sm) {
                Text("No Vendors Yet")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Add your first vendor to start tracking your wedding services")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button {
                showingAddVendor = true
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "plus")
                    Text("Add Vendor")
                }
                .font(Typography.bodyRegular)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(SemanticColors.primaryAction)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xxl)
    }

    // MARK: - No Results

    private var noResultsView: some View {
        VStack(spacing: Spacing.xl) {
            // Icon
            Circle()
                .fill(SemanticColors.textSecondary.opacity(Opacity.light))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(SemanticColors.textSecondary)
                )

            VStack(spacing: Spacing.sm) {
                Text("No Vendors Found")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Text("Try adjusting your search or filters")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
            }

            Button {
                onClearFilters()
            } label: {
                Text("Clear Filters")
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.primaryAction)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.vertical, Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(Color.white.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(SemanticColors.primaryAction, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xxl)
    }

    // MARK: - Error View

    private func errorView(error: Error) -> some View {
        VStack(spacing: Spacing.xl) {
            // Icon
            Circle()
                .fill(SemanticColors.statusError.opacity(Opacity.light))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(SemanticColors.statusError)
                )

            VStack(spacing: Spacing.sm) {
                Text("Error Loading Vendors")
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Text(error.localizedDescription)
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }

            Button {
                Task {
                    await onRetry()
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(Typography.bodyRegular)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(SemanticColors.primaryAction)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xxl)
    }
}
