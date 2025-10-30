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
    @State private var showingExportOptions = false
    @State private var showingAddVendor = false
    @State private var selectedVendor: Vendor?
    
    private var vendorStore: VendorStoreV2 {
        appStores.vendor
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.99)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Section
                headerSection
                    .padding(.horizontal, 40)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                
                // Content Section
                ScrollView {
                    vendorGridSection
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                }
            }
        }
        .task {
            await vendorStore.loadVendors()
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
                    .font(.custom("Roboto", size: 30).weight(.bold))
                    .foregroundColor(Color(red: 0.07, green: 0.09, blue: 0.15))
                
                Text("Manage and track all your vendors in one place")
                    .font(.custom("Roboto", size: 16))
                    .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.39))
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
                            .font(.custom("Roboto", size: 15.45))
                    }
                    .foregroundColor(Color(red: 0.22, green: 0.25, blue: 0.32))
                    .frame(height: 42)
                    .padding(.horizontal, 16)
                    .background(.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.82, green: 0.84, blue: 0.86), lineWidth: 0.5)
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
                            .font(.custom("Roboto", size: 16))
                    }
                    .foregroundColor(Color(red: 0.22, green: 0.25, blue: 0.32))
                    .frame(height: 42)
                    .padding(.horizontal, 16)
                    .background(.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.82, green: 0.84, blue: 0.86), lineWidth: 0.5)
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
                            .font(.custom("Roboto", size: 16))
                    }
                    .foregroundColor(.white)
                    .frame(height: 42)
                    .padding(.horizontal, 20)
                    .background(Color(red: 0.15, green: 0.39, blue: 0.92))
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
    
    // MARK: - Vendor Grid Section
    
    private var vendorGridSection: some View {
        Group {
            switch vendorStore.loadingState {
            case .idle:
                EmptyView()
                
            case .loading:
                ProgressView("Loading vendors...")
                    .frame(maxWidth: .infinity, maxHeight: 400)
                
            case .loaded(let vendors):
                if vendors.isEmpty {
                    emptyStateView
                } else {
                    vendorGrid(vendors: vendors)
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
            ForEach(vendors.filter { !$0.isArchived }) { vendor in
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
                .foregroundColor(Color(red: 0.82, green: 0.84, blue: 0.86))
            
            Text("No Vendors Yet")
                .font(.custom("Roboto", size: 20).weight(.semibold))
                .foregroundColor(Color(red: 0.07, green: 0.09, blue: 0.15))
            
            Text("Add your first vendor to get started")
                .font(.custom("Roboto", size: 14))
                .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
            
            Button {
                showingAddVendor = true
            } label: {
                Text("Add Vendor")
                    .font(.custom("Roboto", size: 16).weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.15, green: 0.39, blue: 0.92))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
    }
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error Loading Vendors")
                .font(.custom("Roboto", size: 20).weight(.semibold))
                .foregroundColor(Color(red: 0.07, green: 0.09, blue: 0.15))
            
            Text(error.localizedDescription)
                .font(.custom("Roboto", size: 14))
                .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                .multilineTextAlignment(.center)
            
            Button {
                Task {
                    await vendorStore.retryLoad()
                }
            } label: {
                Text("Retry")
                    .font(.custom("Roboto", size: 16).weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.15, green: 0.39, blue: 0.92))
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
                    .fill(Color(red: 0.90, green: 0.91, blue: 0.92))
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
                                    .foregroundColor(Color(red: 0.60, green: 0.62, blue: 0.65))
                            }
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                    .padding(.leading, 24)
                
                // Status Badge
                statusBadge
                    .padding(.top, 24)
                    .padding(.trailing, 24)
            }
            .frame(height: 72)
            
            // Vendor Name
            Text(vendor.vendorName)
                .font(.custom("Roboto", size: 18).weight(.semibold))
                .foregroundColor(Color(red: 0.07, green: 0.09, blue: 0.15))
                .lineLimit(1)
                .padding(.horizontal, 24)
                .padding(.top, 8)
            
            // Contact Email
            if let email = vendor.email, !email.isEmpty {
                Text(email)
                    .font(.custom("Roboto", size: 13.78))
                    .foregroundColor(Color(red: 0.29, green: 0.33, blue: 0.39))
                    .lineLimit(1)
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
            }
            
            // Vendor Type
            if let vendorType = vendor.vendorType, !vendorType.isEmpty {
                Text(vendorType)
                    .font(.custom("Roboto", size: 12))
                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            // Quoted Amount Section
            VStack(spacing: 0) {
                Divider()
                    .background(Color(red: 0.95, green: 0.96, blue: 0.96))
                
                HStack {
                    Text("Quoted Amount")
                        .font(.custom("Roboto", size: 13.90))
                        .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                    
                    Spacer()
                    
                    Text(formatCurrency(vendor.quotedAmount ?? 0))
                        .font(.custom("Roboto", size: 17.70).weight(.bold))
                        .foregroundColor(Color(red: 0.07, green: 0.09, blue: 0.15))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
        }
        .frame(width: 290, height: 243)
        .background(.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.90, green: 0.91, blue: 0.92), lineWidth: 0.5)
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
            if vendor.isBooked == true {
                Text("Booked")
                    .font(.custom("Roboto", size: 12).weight(.medium))
                    .foregroundColor(Color(red: 0.60, green: 0.11, blue: 0.11))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 1, green: 0.89, blue: 0.89))
                    .cornerRadius(9999)
            } else {
                Text("Available")
                    .font(.custom("Roboto", size: 12).weight(.medium))
                    .foregroundColor(Color(red: 0.09, green: 0.40, blue: 0.20))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.86, green: 0.99, blue: 0.91))
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
