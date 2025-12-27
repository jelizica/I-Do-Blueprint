//
//  VendorManagementViewV3.swift
//  I Do Blueprint
//
//  V3 of Vendor Management View - Connected to Supabase database
//  with import/export functionality
//

import SwiftUI

struct VendorManagementViewV3: View {
    @Environment(\.appStores) private var appStores
    @StateObject private var exportHandler = VendorExportHandler()
    @State private var showingImportSheet = false
    @StateObject private var sessionManager = SessionManager.shared
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
        ZStack {
            AppGradients.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Section
                headerSection
                    .padding(.horizontal, Spacing.huge)
                    .padding(.top, Spacing.xxxl)
                    .padding(.bottom, Spacing.xxl)

                // Search and Filter Section
                searchAndFilterSection
                    .padding(.horizontal, Spacing.huge)
                    .padding(.bottom, Spacing.lg)

                // Content Section
                ScrollView {
                    vendorGridSection
                        .padding(.horizontal, Spacing.huge)
                        .padding(.bottom, Spacing.huge)
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
            VendorDetailViewV2(
                vendor: vendor,
                vendorStore: vendorStore
            )
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 0) {
            // Title and Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Vendor Management")
                    .font(Typography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)

                Text("Manage and track all your vendors in one place")
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // Action Buttons
            HStack(spacing: 12) {
                // Import Button
                Button {
                    showingImportSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14))
                        Text("Import")
                            .font(Typography.bodyRegular)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(height: 42)
                    .padding(.horizontal, Spacing.lg)
                    .background(AppColors.cardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.borderLight, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .accessibleActionButton(
                    label: "Import vendors",
                    hint: "Import vendors from CSV or Excel file"
                )

                // Export Button
                Button {
                    showingExportOptions = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                        Text("Export")
                            .font(Typography.bodyRegular)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(height: 42)
                    .padding(.horizontal, Spacing.lg)
                    .background(AppColors.cardBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.borderLight, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .accessibleActionButton(
                    label: "Export vendors",
                    hint: "Export vendor list to CSV or Google Sheets"
                )
                .confirmationDialog("Export Vendors", isPresented: $showingExportOptions) {
                    Button("Export to CSV") {
                        Task {
                            await exportHandler.exportVendors(vendorStore.vendors, format: .csv)
                        }
                    }
                    Button("Export to Google Sheets") {
                        Task {
                            await exportHandler.exportVendors(vendorStore.vendors, format: .googleSheets)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }

                // Add Vendor Button
                Button {
                    showingAddVendor = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add Vendor")
                            .font(Typography.bodyRegular)
                    }
                    .foregroundColor(AppColors.textPrimary)
                    .frame(height: 42)
                    .padding(.horizontal, Spacing.xl)
                    .background(AppColors.primary)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .accessibleActionButton(
                    label: "Add new vendor",
                    hint: "Create a new vendor entry"
                )
                .sheet(isPresented: $showingAddVendor) {
                    AddVendorSheet(vendorStore: vendorStore)
                }
            }
        }
        .frame(height: 68)
    }

    // MARK: - Search and Filter Section
    
    private var searchAndFilterSection: some View {
        HStack(spacing: Spacing.md) {
            // Search Bar
            HStack(spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)
                    .font(.system(size: 14))
                
                TextField("Search vendors...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(Typography.bodyRegular)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textSecondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(AppColors.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.borderLight, lineWidth: 0.5)
            )
            .frame(maxWidth: 400)
            
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(VendorFilterOption.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
            
            Spacer()
            
            // Sort Menu
            Menu {
                ForEach(VendorSortOption.allCases, id: \.self) { option in
                    Button {
                        selectedSort = option
                    } label: {
                        HStack {
                            Text(option.displayName)
                            if selectedSort == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14))
                    Text("Sort: \(selectedSort.displayName)")
                        .font(Typography.bodyRegular)
                }
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(AppColors.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.borderLight, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Vendor Grid Section

    private var vendorGridSection: some View {
        Group {
            switch vendorStore.loadingState {
            case .idle:
                EmptyView()

            case .loading:
                ProgressView("Loading vendors...")
                    .frame(maxWidth: .infinity, maxHeight: 400)

            case .loaded:
                if filteredAndSortedVendors.isEmpty {
                    if searchText.isEmpty && selectedFilter == .all {
                        emptyStateView
                    } else {
                        noResultsView
                    }
                } else {
                    vendorGrid(vendors: filteredAndSortedVendors)
                }

            case .error(let error):
                errorView(error: error)
            }
        }
    }

    private func vendorGrid(vendors: [Vendor]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Spacing.lg),
                GridItem(.flexible(), spacing: Spacing.lg),
                GridItem(.flexible(), spacing: Spacing.lg),
                GridItem(.flexible(), spacing: Spacing.lg)
            ],
            spacing: Spacing.lg
        ) {
            ForEach(vendors) { vendor in
                VendorCardV3(vendor: vendor)
                    .onTapGesture {
                        selectedVendor = vendor
                    }
            }
        }
    }

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
                searchText = ""
                selectedFilter = .all
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
                    await vendorStore.retryLoad()
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

// MARK: - Vendor Card Component

struct VendorCardV3: View {
    let vendor: Vendor
    @State private var loadedImage: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Avatar and Status Badge
            ZStack(alignment: .topTrailing) {
                // Avatar Circle with logo or default icon
                Circle()
                    .fill(AppColors.controlBackground)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Group {
                            if let image = loadedImage {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Spacing.xxl)
                    .padding(.leading, Spacing.xxl)

                // Status Badge
                statusBadge
                    .padding(.top, Spacing.xxl)
                    .padding(.trailing, Spacing.xxl)
            }
            .frame(height: 72)

            // Vendor Name
            Text(vendor.vendorName)
                .font(Typography.heading)
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, Spacing.xxl)
                .padding(.top, Spacing.sm)

            // Contact Email
            if let email = vendor.email, !email.isEmpty {
                Text(email)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.top, Spacing.xs)
            }

            // Vendor Type
            if let vendorType = vendor.vendorType, !vendorType.isEmpty {
                Text(vendorType)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.top, Spacing.sm)
            }

            Spacer()

            // Quoted Amount Section
            VStack(spacing: 0) {
                Divider()
                    .background(AppColors.borderLight)

                HStack {
                    Text("Quoted Amount")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)

                    Spacer()

                    Text(formatCurrency(vendor.quotedAmount ?? 0))
                        .font(Typography.numberMedium)
                        .foregroundColor(AppColors.textPrimary)
                }
                .padding(.horizontal, Spacing.xxl)
                .padding(.vertical, Spacing.md)
            }
        }
        .frame(width: 290, height: 243)
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.borderLight, lineWidth: 0.5)
        )
        .accessibleListItem(
            label: vendor.vendorName,
            hint: "Tap to view vendor details",
            value: vendor.isBooked == true ? "Booked" : "Available"
        )
        .task(id: vendor.imageUrl) {
            await loadVendorImage()
        }
    }

    /// Load vendor image asynchronously from URL
    private func loadVendorImage() async {
        guard let imageUrl = vendor.imageUrl,
              let url = URL(string: imageUrl) else {
            loadedImage = nil
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let nsImage = NSImage(data: data) {
                await MainActor.run {
                    loadedImage = nsImage
                }
            }
        } catch {
            await MainActor.run {
                loadedImage = nil
            }
        }
    }

private var statusBadge: some View {
        Group {
            if vendor.isArchived {
                Text("Archived")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.error)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.errorLight)
                    .cornerRadius(9999)
            } else if vendor.isBooked == true {
                Text("Booked")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.success)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.successLight)
                    .cornerRadius(9999)
            } else {
                Text("Available")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.warning)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .background(AppColors.warningLight)
                    .cornerRadius(9999)
            }
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
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
                    TextField("Phone Number", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
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
