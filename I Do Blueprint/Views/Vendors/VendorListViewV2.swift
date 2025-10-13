//
//  VendorListViewV2.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/1/25.
//  Modern redesigned vendor list with improved UI/UX matching GuestListViewV2
//

import SwiftUI
import Dependencies
import Combine

struct VendorListViewV2: View {
    @StateObject private var vendorStore = VendorStoreV2()
    @StateObject private var exportHandler = VendorExportHandler()
    @Dependency(\.alertPresenter) var alertPresenter
    @State private var searchText = ""
    @State private var selectedFilter: VendorFilterOption = .all
    @State private var selectedCategory: String?
    @State private var showingAddVendor = false
    @State private var selectedVendorId: Int64?
    @State private var groupByStatus = true

    private var selectedVendor: Vendor? {
        guard let id = selectedVendorId else { return nil }
        return vendorStore.vendors.first(where: { $0.id == id })
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Left panel - Vendor list with enhanced design
                VStack(spacing: 0) {
                    // Modern Stats Section
                    ModernVendorStatsView(stats: vendorStore.stats)
                        .padding(Spacing.md)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Vendor statistics")

                    Divider()

                    // Enhanced Search and Filters
                    ModernVendorSearchBar(
                        searchText: $searchText,
                        selectedFilter: $selectedFilter,
                        selectedCategory: $selectedCategory,
                        groupByStatus: $groupByStatus
                    )
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)

                    Divider()

                    // Vendor List with grouping option
                    if groupByStatus {
                        GroupedVendorListView(
                            vendors: filteredVendors,
                            totalCount: vendorStore.vendors.filter { !$0.isArchived }.count,
                            isLoading: vendorStore.isLoading,
                            isSearching: !searchText.isEmpty,
                            onClearSearch: { searchText = "" },
                            selectedVendorId: $selectedVendorId,
                            onRefresh: {
                                await vendorStore.loadVendors()
                            }
                        )
                    } else {
                        ModernVendorListView(
                            vendors: filteredVendors,
                            totalCount: vendorStore.vendors.filter { !$0.isArchived }.count,
                            isLoading: vendorStore.isLoading,
                            isSearching: !searchText.isEmpty,
                            onClearSearch: { searchText = "" },
                            selectedVendorId: $selectedVendorId,
                            onRefresh: {
                                await vendorStore.loadVendors()
                            }
                        )
                    }
                }
                .frame(width: 480)
                .background(AppColors.background)

                Divider()

                // Right panel - Enhanced Detail view
                if let vendor = selectedVendor {
                    VendorDetailViewV2(
                        vendor: vendor,
                        vendorStore: vendorStore,
                        onExportToggle: { newValue in
                            await toggleExportFlag(for: vendor, newValue: newValue)
                        }
                    )
                    .id(vendor.id)
                } else {
                    EmptyVendorDetailView()
                }
            }
            .navigationTitle("Wedding Vendors")
            .accessibilityAddTraits(.isHeader)
            .toolbar {
                VendorListToolbar(
                    exportableCount: exportHandler.exportableCount(from: vendorStore.vendors),
                    isExporting: exportHandler.isExporting,
                    onExport: { format in
                        await exportHandler.exportVendors(vendorStore.vendors, format: format)
                    },
                    onAdd: { showingAddVendor = true }
                )
            }
            .sheet(isPresented: $showingAddVendor) {
                Text("Add Vendor Form")
                    .frame(minWidth: 500, maxWidth: 600, minHeight: 500, maxHeight: 650)
            }
            .task {
                await vendorStore.loadVendors()
            }
            .task {
                await monitorVendorStoreAlerts()
            }
            .task {
                await monitorExportHandlerAlerts()
            }
        }
    }

    // MARK: - Helper Methods

    private func toggleExportFlag(for vendor: Vendor, newValue: Bool) async {
        var updatedVendor = vendor
        updatedVendor.includeInExport = newValue
        await vendorStore.updateVendor(updatedVendor)
    }

    /// Monitor VendorStore for errors and success messages, presenting them via AlertPresenter
    private func monitorVendorStoreAlerts() async {
        await withTaskGroup(of: Void.self) { group in
            // Monitor for errors
            group.addTask { @MainActor in
                for await error in self.vendorStore.$error.values {
                    guard let error = error else { continue }
                    await self.alertPresenter.showError(
                        title: "Vendor Error",
                        message: error.errorDescription ?? "An unknown error occurred",
                        error: error
                    )
                    self.vendorStore.error = nil
                }
            }

            // Monitor for success messages
            group.addTask { @MainActor in
                for await showingToast in self.vendorStore.$showSuccessToast.values {
                    guard showingToast else { continue }
                    self.alertPresenter.showSuccessToast(self.vendorStore.successMessage, duration: 3.0)
                    self.vendorStore.showSuccessToast = false
                }
            }
        }
    }

    /// Monitor ExportHandler for errors and success messages, presenting them via AlertPresenter
    private func monitorExportHandlerAlerts() async {
        await withTaskGroup(of: Void.self) { group in
            // Monitor export errors
            group.addTask { @MainActor in
                for await error in self.exportHandler.$exportError.values {
                    guard let error = error else { continue }
                    await self.alertPresenter.showError(
                        title: "Export Error",
                        message: error.errorDescription ?? "Export failed",
                        error: error
                    )
                    self.exportHandler.exportError = nil
                }
            }

            // Monitor export success
            group.addTask { @MainActor in
                for await showingSuccess in self.exportHandler.$showingExportSuccess.values {
                    guard showingSuccess else { continue }
                    let response = await self.alertPresenter.showAlert(
                        title: "Export Successful",
                        message: "Vendor contact list has been exported successfully.",
                        style: .informational,
                        buttons: ["Open File", "OK"]
                    )
                    if response == "Open File", let url = self.exportHandler.exportedFileURL {
                        await VendorExportService.shared.openFile(url)
                    }
                    self.exportHandler.showingExportSuccess = false
                }
            }
        }
    }

    private var filteredVendors: [Vendor] {
        vendorStore.vendors.filter { vendor in
            let matchesSearch = searchText.isEmpty ||
                vendor.vendorName.localizedCaseInsensitiveContains(searchText) ||
                vendor.vendorType?.localizedCaseInsensitiveContains(searchText) == true

            let matchesFilter: Bool = switch selectedFilter {
            case .all: !vendor.isArchived
            case .available: !(vendor.isBooked ?? false) && !vendor.isArchived
            case .booked: (vendor.isBooked ?? false) && !vendor.isArchived
            case .archived: vendor.isArchived
            }

            let matchesCategory = selectedCategory == nil ||
                vendor.vendorType == selectedCategory

            return matchesSearch && matchesFilter && matchesCategory
        }
    }
}

// MARK: - Extensions

extension Vendor {
    var initials: String {
        String(vendorName.prefix(2)).uppercased()
    }

    var statusDisplayName: String {
        isBooked == true ? "Booked" : "Available"
    }
}

extension VendorFilterOption {
    var iconName: String {
        switch self {
        case .all: return "building.2"
        case .available: return "clock.badge"
        case .booked: return "checkmark.seal.fill"
        case .archived: return "archivebox.fill"
        }
    }
}

#Preview {
    VendorListViewV2()
}
