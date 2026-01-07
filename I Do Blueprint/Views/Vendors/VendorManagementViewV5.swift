//
//  VendorManagementViewV5.swift
//  I Do Blueprint
//
//  V5 of Vendor Management View - Adds view toggle between card grid and list view
//  Features:
//  - All V4 features (glassmorphism, stats cards, search/filter)
//  - View toggle button to switch between card grid and list view
//  - Defaults to grid (cards) view on each navigation to the tab
//  - View mode resets when navigating away from Vendors tab
//

import SwiftUI
import PhoneNumberKit

// MARK: - View Mode Enum

enum VendorViewMode: String, CaseIterable {
    case grid = "grid"
    case list = "list"

    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }

    var label: String {
        switch self {
        case .grid: return "Grid View"
        case .list: return "List View"
        }
    }
}

// MARK: - Vendor Management View V5

struct VendorManagementViewV5: View {
    @Environment(\.appStores) private var appStores
    @EnvironmentObject private var coordinator: AppCoordinator
    @StateObject private var exportHandler = VendorExportHandler()
    @StateObject private var sessionManager = SessionManager.shared

    @State private var showingImportSheet = false
    @State private var showingExportOptions = false
    @State private var showingAddVendor = false
    @State private var searchText = ""
    @State private var selectedFilter: VendorFilterOption = .all
    @State private var selectedSort: VendorSortOption = .nameAsc
    @State private var viewMode: VendorViewMode = .grid

    private var vendorStore: VendorStoreV2 {
        appStores.vendor
    }

    private var filteredAndSortedVendors: [Vendor] {
        let filtered = vendorStore.vendors.filter { vendor in
            let matchesSearch = searchText.isEmpty ||
                vendor.vendorName.localizedCaseInsensitiveContains(searchText) ||
                vendor.vendorType?.localizedCaseInsensitiveContains(searchText) == true ||
                vendor.email?.localizedCaseInsensitiveContains(searchText) == true

            let matchesFilter: Bool = switch selectedFilter {
            case .all:
                !vendor.isArchived
            case .available:
                !(vendor.isBooked ?? false) && !vendor.isArchived
            case .booked:
                (vendor.isBooked ?? false) && !vendor.isArchived
            case .archived:
                vendor.isArchived
            }

            return matchesSearch && matchesFilter
        }

        return selectedSort.sort(filtered)
    }

    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.huge

            ZStack {
                // Mesh gradient background
                MeshGradientBackgroundView()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.xxl) {
                        // Header Section with View Toggle
                        VendorHeaderV5(
                            windowSize: windowSize,
                            viewMode: $viewMode,
                            showingImportSheet: $showingImportSheet,
                            showingExportOptions: $showingExportOptions,
                            showingAddVendor: $showingAddVendor,
                            exportHandler: exportHandler,
                            vendors: vendorStore.vendors
                        )
                        .padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)

                        // Stats Cards Section - Always show ALL vendors (not filtered)
                        VendorStatsSectionV4(
                            windowSize: windowSize,
                            vendors: vendorStore.vendors,
                            totalBudget: appStores.budget.primaryScenarioTotal
                        )

                        // Search and Filter Section with View Toggle
                        HStack(spacing: Spacing.md) {
                            VendorSearchAndFiltersV4(
                                windowSize: windowSize,
                                searchText: $searchText,
                                selectedFilter: $selectedFilter,
                                selectedSort: $selectedSort
                            )
                            
                            // View Toggle (moved here to align with search bar)
                            HStack(spacing: 4) {
                                Button(action: { viewMode = .grid }) {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 14))
                                        .foregroundColor(viewMode == .grid ? SemanticColors.textPrimary : SemanticColors.textSecondary)
                                        .frame(width: 36, height: 36)
                                        .background(viewMode == .grid ? Color.white.opacity(0.8) : Color.clear)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { viewMode = .list }) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 14))
                                        .foregroundColor(viewMode == .list ? SemanticColors.textPrimary : SemanticColors.textSecondary)
                                        .frame(width: 36, height: 36)
                                        .background(viewMode == .list ? Color.white.opacity(0.8) : Color.clear)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(2)
                            .frame(height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .fill(Color.white.opacity(0.3))
                            )
                        }

                        // Vendor Display - Grid or List based on viewMode
                        // Note: Using simple conditional instead of animation to ensure
                        // loadingState is properly observed when switching views
                        if viewMode == .grid {
                            VendorListGridV4(
                                windowSize: windowSize,
                                loadingState: vendorStore.loadingState,
                                filteredVendors: filteredAndSortedVendors,
                                searchText: searchText,
                                selectedFilter: selectedFilter,
                                onSelectVendor: { vendor in
                                    coordinator.present(.viewVendor(vendor))
                                },
                                showingAddVendor: $showingAddVendor,
                                onRetry: {
                                    await vendorStore.retryLoad()
                                },
                                onClearFilters: {
                                    searchText = ""
                                    selectedFilter = .all
                                }
                            )
                        } else {
                            VendorListViewV1(
                                windowSize: windowSize,
                                loadingState: vendorStore.loadingState,
                                filteredVendors: filteredAndSortedVendors,
                                searchText: searchText,
                                selectedFilter: selectedFilter,
                                onSelectVendor: { vendor in
                                    coordinator.present(.viewVendor(vendor))
                                },
                                showingAddVendor: $showingAddVendor,
                                onRetry: {
                                    await vendorStore.retryLoad()
                                },
                                onClearFilters: {
                                    searchText = ""
                                    selectedFilter = .all
                                }
                            )
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, windowSize == .compact ? Spacing.lg : Spacing.huge)
                }
            }
        }
        .task {
            await vendorStore.loadVendors()
        }
        .task(id: sessionManager.getTenantId()) {
            await vendorStore.loadVendors(force: true)
        }
        .onChange(of: coordinator.activeSheet) { oldValue, newValue in
            // Reload vendors when returning from detail/edit sheets
            // This ensures the list is refreshed after edits
            if oldValue != nil && newValue == nil {
                Task {
                    await vendorStore.loadVendors(force: true)
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            VendorCSVImportView()
                .environmentObject(vendorStore)
        }
        .sheet(isPresented: $showingAddVendor) {
            AddVendorSheet(vendorStore: vendorStore)
        }
    }
}

// MARK: - Vendor Header V5 (with View Toggle)

struct VendorHeaderV5: View {
    let windowSize: WindowSize
    @Binding var viewMode: VendorViewMode
    @Binding var showingImportSheet: Bool
    @Binding var showingExportOptions: Bool
    @Binding var showingAddVendor: Bool
    @ObservedObject var exportHandler: VendorExportHandler
    let vendors: [Vendor]

    var body: some View {
        HStack(alignment: .center) {
            // Title
            Text("Vendor Management")
                .font(Typography.title1)
                .foregroundColor(SemanticColors.textPrimary)

            Spacer()

            // Action Buttons
            if windowSize != .compact {
                actionButtons
            }
        }
    }

        
    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Spacing.md) {
            // Import Button
            Button {
                showingImportSheet = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import CSV")
                }
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textPrimary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassPanel(cornerRadius: CornerRadius.md, padding: 0)

            // Export Button
            Button {
                showingExportOptions = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
                .font(Typography.bodySmall)
                .foregroundColor(SemanticColors.textPrimary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
            .buttonStyle(.plain)
            .glassPanel(cornerRadius: CornerRadius.md, padding: 0)

            // Add Vendor Button
            Button {
                showingAddVendor = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "plus")
                    Text("Add Vendor")
                }
                .font(Typography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(SemanticColors.textOnPrimary)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(SemanticColors.primaryAction)
                )
            }
            .buttonStyle(.plain)
            .shadow(color: SemanticColors.primaryAction.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Preview

#Preview {
    VendorManagementViewV5()
        .environment(\.appStores, AppStores.shared)
        .environmentObject(AppCoordinator.shared)
}
