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
    let onSelectVendor: (Vendor) -> Void
    @Binding var showingAddVendor: Bool
    let onRetry: () async -> Void
    let onClearFilters: () -> Void

    var body: some View {
        Group {
            switch loadingState {
            case .idle:
                // Show loading indicator while waiting for data to load
                // This prevents blank screen during initial load
                loadingView

            case .loading:
                loadingView

            case .loaded:
                if filteredVendors.isEmpty {
                    if searchText.isEmpty && selectedFilter == .all {
                        emptyStateView
                    } else {
                        noResultsForFilterView
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
                        onSelectVendor(vendor)
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

    // MARK: - Empty State (No vendors at all)

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

    // MARK: - No Results for Filter (Filter-specific empty state)

    private var noResultsForFilterView: some View {
        VStack(spacing: Spacing.xl) {
            // Icon based on filter type
            Circle()
                .fill(filterIconColor.opacity(Opacity.light))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: filterIconName)
                        .font(.system(size: 32))
                        .foregroundColor(filterIconColor)
                )

            VStack(spacing: Spacing.sm) {
                Text(filterEmptyTitle)
                    .font(Typography.heading)
                    .foregroundColor(SemanticColors.textPrimary)

                Text(filterEmptyMessage)
                    .font(Typography.bodyRegular)
                    .foregroundColor(SemanticColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            // Show different actions based on context
            if !searchText.isEmpty {
                Button {
                    onClearFilters()
                } label: {
                    Text("Clear Search")
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
            } else {
                Button {
                    onClearFilters()
                } label: {
                    Text("View All Vendors")
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
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .glassPanel(cornerRadius: CornerRadius.xl, padding: Spacing.xxl)
    }

    // MARK: - Filter-specific UI helpers

    private var filterIconName: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        }
        switch selectedFilter {
        case .all:
            return "building.2"
        case .available:
            return "clock"
        case .booked:
            return "checkmark.circle"
        case .archived:
            return "archivebox"
        }
    }

    private var filterIconColor: Color {
        if !searchText.isEmpty {
            return SemanticColors.textSecondary
        }
        switch selectedFilter {
        case .all:
            return SemanticColors.primaryAction
        case .available:
            return SemanticColors.statusPending
        case .booked:
            return SemanticColors.statusSuccess
        case .archived:
            return SemanticColors.textSecondary
        }
    }

    private var filterEmptyTitle: String {
        if !searchText.isEmpty {
            return "No Matching Vendors"
        }
        switch selectedFilter {
        case .all:
            return "No Vendors Found"
        case .available:
            return "No Available Vendors"
        case .booked:
            return "No Booked Vendors"
        case .archived:
            return "No Archived Vendors"
        }
    }

    private var filterEmptyMessage: String {
        if !searchText.isEmpty {
            return "No vendors match your search for \"\(searchText)\". Try a different search term or clear the search."
        }
        switch selectedFilter {
        case .all:
            return "Add vendors to start tracking your wedding services."
        case .available:
            return "All your vendors are either booked or archived. Add new vendors to see them here."
        case .booked:
            return "You haven't booked any vendors yet. Mark vendors as booked when you've confirmed them."
        case .archived:
            return "You don't have any archived vendors. Archive vendors you're no longer considering."
        }
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
