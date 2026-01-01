//
//  VendorManagementViewV3.swift
//  I Do Blueprint
//
//  V3 of Vendor Management View - Connected to Supabase database
//  with import/export functionality
//
//  Refactored: Split into focused components to reduce complexity
//  - VendorManagementHeader: Header with action buttons
//  - VendorStatsSection: Statistics cards
//  - VendorSearchAndFilters: Search and filter controls
//  - VendorListGrid: Grid layout and empty states
//  - VendorCardV3: Individual vendor card
//

import SwiftUI
import PhoneNumberKit

struct VendorManagementViewV3: View {
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
            // Apply search filter
            let matchesSearch = searchText.isEmpty ||
                vendor.vendorName.localizedCaseInsensitiveContains(searchText) ||
                vendor.vendorType?.localizedCaseInsensitiveContains(searchText) == true ||
                vendor.email?.localizedCaseInsensitiveContains(searchText) == true
            
            // Apply status filter
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
        
        // Apply sorting
        return selectedSort.sort(filtered)
    }

    var body: some View {
        GeometryReader { geometry in
            let windowSize = geometry.size.width.windowSize
            let horizontalPadding = windowSize == .compact ? Spacing.lg : Spacing.huge
            let availableWidth = geometry.size.width - (horizontalPadding * 2)

            ZStack {
                AppGradients.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Section
                    VendorManagementHeader(
                        windowSize: windowSize,
                        showingImportSheet: $showingImportSheet,
                        showingExportOptions: $showingExportOptions,
                        showingAddVendor: $showingAddVendor,
                        exportHandler: exportHandler,
                        vendors: vendorStore.vendors
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, windowSize == .compact ? Spacing.lg : Spacing.xl)
                    .padding(.bottom, Spacing.lg)

                    // Content Section
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            // Stats Cards
                            VendorStatsSection(
                                windowSize: windowSize,
                                vendors: vendorStore.vendors
                            )

                            // Search and Filter Section
                            VendorSearchAndFilters(
                                windowSize: windowSize,
                                searchText: $searchText,
                                selectedFilter: $selectedFilter,
                                selectedSort: $selectedSort
                            )

                            // Vendor Grid
                            VendorListGrid(
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
                        .frame(width: availableWidth)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, windowSize == .compact ? Spacing.lg : Spacing.huge)
                    }
                }
            }
        }
        .task {
            await vendorStore.loadVendors()
        }
        .task(id: sessionManager.getTenantId()) {
            // Reload vendors when the tenant changes (safe outside view update cycle)
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

// MARK: - Add Vendor Sheet

struct AddVendorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vendorStore: VendorStoreV2

    @State private var vendorName = ""
    @State private var vendorType = ""
    @State private var contactName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var website = ""
    @State private var quotedAmount = ""
    @State private var notes = ""
    @State private var isBooked = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Vendor Information") {
                    TextField("Vendor Name", text: $vendorName)
                    TextField("Vendor Type", text: $vendorType)
                        .textContentType(.jobTitle)
                }

                Section("Contact Information") {
                    TextField("Contact Name", text: $contactName)
                        .textContentType(.name)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                    PhoneNumberTextFieldWrapper(
                        phoneNumber: $phoneNumber,
                        defaultRegion: "US",
                        placeholder: "Phone Number"
                    )
                    .frame(height: 40)
                    TextField("Website", text: $website)
                        .textContentType(.URL)
                }

                Section("Pricing") {
                    TextField("Quoted Amount", text: $quotedAmount)
                }

                Section("Additional Details") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                    Toggle("Booked", isOn: $isBooked)
                }
            }
            .navigationTitle("Add Vendor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveVendor()
                    }
                    .disabled(vendorName.isEmpty)
                }
            }
        }
    }

    private func saveVendor() {
        // Get the current couple ID from session
        guard let coupleId = SessionManager.shared.getTenantId() else {
            AppLogger.ui.error("Cannot create vendor: No couple ID available")
            return
        }

        let vendor = Vendor(
            id: 0, // Will be assigned by database
            createdAt: Date(),
            updatedAt: Date(),
            vendorName: vendorName,
            vendorType: vendorType.isEmpty ? nil : vendorType,
            vendorCategoryId: nil,
            contactName: contactName.isEmpty ? nil : contactName,
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            email: email.isEmpty ? nil : email,
            website: website.isEmpty ? nil : website,
            notes: notes.isEmpty ? nil : notes,
            quotedAmount: Double(quotedAmount),
            imageUrl: nil,
            isBooked: isBooked,
            dateBooked: isBooked ? Date() : nil,
            budgetCategoryId: nil,
            coupleId: coupleId,
            isArchived: false,
            archivedAt: nil,
            includeInExport: true,
            streetAddress: nil,
            streetAddress2: nil,
            city: nil,
            state: nil,
            postalCode: nil,
            country: "US",
            latitude: nil,
            longitude: nil
        )

        Task {
            await vendorStore.addVendor(vendor)
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    VendorManagementViewV3()
        .environment(\.appStores, AppStores.shared)
}
