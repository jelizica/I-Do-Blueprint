//
//  VendorManagementViewV4.swift
//  I Do Blueprint
//
//  V4 of Vendor Management View - Premium glassmorphism design
//  Features:
//  - Glassmorphism card panels with frosted glass effect
//  - Circular progress indicators for budget stats
//  - Enhanced vendor cards with initials avatar
//  - Responsive 4-column grid layout
//

import SwiftUI
import PhoneNumberKit

struct VendorManagementViewV4: View {
    @Environment(\.appStores) private var appStores
    @StateObject private var exportHandler = VendorExportHandler()
    @StateObject private var sessionManager = SessionManager.shared

    @State private var showingImportSheet = false
    @State private var showingExportOptions = false
    @State private var showingAddVendor = false
    @State private var selectedVendor: Vendor?
    @State private var searchText = ""
    @State private var selectedFilter: VendorFilterOption = .all
    @State private var selectedSort: VendorSortOption = .nameAsc

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
                        // Header Section
                        VendorHeaderV4(
                            windowSize: windowSize,
                            showingImportSheet: $showingImportSheet,
                            showingExportOptions: $showingExportOptions,
                            showingAddVendor: $showingAddVendor,
                            exportHandler: exportHandler,
                            vendors: vendorStore.vendors
                        )
                        .padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)

                        // Stats Cards Section
                        VendorStatsSectionV4(
                            windowSize: windowSize,
                            vendors: vendorStore.vendors,
                            totalBudget: appStores.budget.primaryScenarioTotal
                        )

                        // Search and Filter Section
                        VendorSearchAndFiltersV4(
                            windowSize: windowSize,
                            searchText: $searchText,
                            selectedFilter: $selectedFilter,
                            selectedSort: $selectedSort
                        )

                        // Vendor Grid
                        VendorListGridV4(
                            windowSize: windowSize,
                            loadingState: vendorStore.loadingState,
                            filteredVendors: filteredAndSortedVendors,
                            searchText: searchText,
                            selectedFilter: selectedFilter,
                            selectedVendor: $selectedVendor,
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
        .sheet(isPresented: $showingImportSheet) {
            VendorCSVImportView()
                .environmentObject(vendorStore)
        }
        .sheet(item: $selectedVendor) { vendor in
            VendorDetailViewV3(
                vendor: vendor,
                vendorStore: vendorStore
            )
            .environmentObject(AppCoordinator.shared)
        }
        .sheet(isPresented: $showingAddVendor) {
            AddVendorSheet(vendorStore: vendorStore)
        }
    }
}

// MARK: - Mesh Gradient Background

struct MeshGradientBackgroundView: View {
    @Environment(\.appStores) private var appStores

    private var themeSettings: ThemeSettings {
        appStores.settings.settings.theme
    }

    var body: some View {
        let colors = AppGradients.meshGradientColors(for: themeSettings)

        ZStack {
            // Base color
            colors.base

            // Color blobs with blur
            Circle()
                .fill(colors.blob1)
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -100, y: -200)

            Circle()
                .fill(colors.blob2)
                .frame(width: 350, height: 350)
                .blur(radius: 80)
                .offset(x: 150, y: 100)

            Circle()
                .fill(colors.blob3)
                .frame(width: 300, height: 300)
                .blur(radius: 90)
                .offset(x: -50, y: 300)
        }
    }
}

// MARK: - Preview

#Preview {
    VendorManagementViewV4()
        .environment(\.appStores, AppStores.shared)
}
