//
//  VendorDetailViewV2.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/1/25.
//  Visual profile-style vendor detail view matching GuestDetailViewV2
//

import SwiftUI
import Dependencies
import Supabase

struct VendorDetailViewV2: View {
    let vendor: Vendor
    var vendorStore: VendorStoreV2
    var onExportToggle: ((Bool) async -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var selectedTab = 0
    @State private var currentVendor: Vendor
    @State private var isSavingLogo = false

    // Financial data
    @State private var expenses: [Expense] = []
    @State private var payments: [PaymentSchedule] = []
    @State private var isLoadingFinancials = false
    @State private var financialLoadError: Error?

    // Documents data
    @State private var documents: [Document] = []
    @State private var isLoadingDocuments = false
    @State private var documentLoadError: Error?

    @Dependency(\.budgetRepository) var budgetRepository
    @Dependency(\.documentRepository) var documentRepository

    init(vendor: Vendor, vendorStore: VendorStoreV2, onExportToggle: ((Bool) async -> Void)? = nil) {
        self.vendor = vendor
        self.vendorStore = vendorStore
        self.onExportToggle = onExportToggle
        _currentVendor = State(initialValue: vendor)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Hero Header Section with Edit, Delete, Close, and Logo Upload
            VendorHeroHeaderView(
                vendor: currentVendor,
                onEdit: {
                    showingEditSheet = true
                },
                onDelete: {
                    Task {
                        await vendorStore.deleteVendor(vendor)
                        dismiss()
                    }
                },
                onClose: {
                    dismiss()
                },
                onLogoUpdated: { logoImage in
                    Task {
                        await handleLogoUpdate(logoImage)
                    }
                }
            )

            // Tabbed Content
            TabbedDetailView(
                tabs: [
                    DetailTab(title: "Overview", icon: "info.circle"),
                    DetailTab(title: "Financial", icon: "dollarsign.circle"),
                    DetailTab(title: "Documents", icon: "doc.text"),
                    DetailTab(title: "Notes", icon: "note.text")
                ],
                selectedTab: $selectedTab
            ) { index in
                ScrollView {
                    VStack(spacing: Spacing.xxxl) {
                        switch index {
                        case 0: overviewTab
                        case 1: financialTab
                        case 2: documentsTab
                        case 3: notesTab
                        default: EmptyView()
                        }
                    }
                    .padding(Spacing.xxl)
                }
                .background(AppColors.background)
            }
        }
        .background(AppColors.background)
        .frame(maxWidth: 900, maxHeight: 700)
        .sheet(isPresented: $showingEditSheet) {
            EditVendorSheetV2(vendor: vendor, vendorStore: vendorStore) { _ in
                // Reload will happen automatically through the store
            }
        }
        .task {
            await loadFinancialData()
            await loadDocuments()
        }
        .onChange(of: vendorStore.vendors) { _ in
            // Update currentVendor when the store's vendor list changes
            if let updatedVendor = vendorStore.vendors.first(where: { $0.id == vendor.id }) {
                currentVendor = updatedVendor
            }
        }
    }

    // MARK: - Data Loading

    private func loadDocuments() async {
        isLoadingDocuments = true
        documentLoadError = nil

        do {
            documents = try await documentRepository.fetchDocuments(vendorId: Int(vendor.id))
        } catch {
            documentLoadError = error
            AppLogger.ui.error("Error loading documents for vendor \(vendor.id)", error: error)
        }

        isLoadingDocuments = false
    }

    private func loadFinancialData() async {
        isLoadingFinancials = true
        financialLoadError = nil

        do {
            async let expensesTask = budgetRepository.fetchExpensesByVendor(vendorId: vendor.id)
            async let paymentsTask = budgetRepository.fetchPaymentSchedulesByVendor(vendorId: vendor.id)

            expenses = try await expensesTask
            payments = try await paymentsTask
        } catch {
            financialLoadError = error
            AppLogger.ui.error("Error loading financial data for vendor \(vendor.id)", error: error)
        }

        isLoadingFinancials = false
    }

    // MARK: - Tab Content

    private var overviewTab: some View {
        VStack(spacing: Spacing.xxxl) {
            // Quick Actions Toolbar
            QuickActionsToolbar(actions: quickActions)

            // Export Flag Toggle Section
            VendorExportFlagSection(
                vendor: currentVendor,
                onToggle: { newValue in
                    Task {
                        await onExportToggle?(newValue)
                    }
                }
            )

            // Quick Info Cards
            VendorQuickInfoSection(vendor: currentVendor, contractInfo: nil)

            // Contact Section
            if hasContactInfo {
                VendorContactSection(vendor: currentVendor)
            }

            // Business Details
            VendorBusinessDetailsSection(vendor: currentVendor, reviewStats: nil)
        }
    }

    private var quickActions: [QuickAction] {
        var actions: [QuickAction] = []

        // Call action
        if let phoneNumber = currentVendor.phoneNumber {
            actions.append(QuickAction(icon: "phone.fill", title: "Call", color: AppColors.Vendor.booked) {
                if let url = URL(string: "tel:\(phoneNumber.filter { !$0.isWhitespace && $0 != "-" && $0 != "(" && $0 != ")" })") {
                    NSWorkspace.shared.open(url)
                }
            })
        }

        // Email action
        if let email = currentVendor.email {
            actions.append(QuickAction(icon: "envelope.fill", title: "Email", color: AppColors.Vendor.contacted) {
                if let url = URL(string: "mailto:\(email)") {
                    NSWorkspace.shared.open(url)
                }
            })
        }

        // Website action
        if let website = currentVendor.website, let url = URL(string: website) {
            actions.append(QuickAction(icon: "globe", title: "Website", color: AppColors.Vendor.pending) {
                NSWorkspace.shared.open(url)
            })
        }

        // Edit action
        actions.append(QuickAction(icon: "pencil", title: "Edit", color: AppColors.primary) {
            showingEditSheet = true
        })

        return actions
    }

    private var financialTab: some View {
        VStack(spacing: Spacing.xxxl) {
            if isLoadingFinancials {
                // Loading State
                VStack(spacing: Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Loading financial data...")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hasAnyFinancialInfo {
                // Quoted Amount Section
                if let quotedAmount = currentVendor.quotedAmount {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeaderV2(
                            title: "Quoted Amount",
                            icon: "banknote.fill",
                            color: AppColors.Vendor.booked
                        )

                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Total Quote")
                                    .font(Typography.caption)
                                    .foregroundColor(AppColors.textSecondary)

                                Text(quotedAmount.formatted(.currency(code: "USD")))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(AppColors.primary)
                            }

                            Spacer()

                            if let budgetCategory = currentVendor.budgetCategoryName {
                                VStack(alignment: .trailing, spacing: Spacing.xs) {
                                    Text("Category")
                                        .font(Typography.caption)
                                        .foregroundColor(AppColors.textSecondary)

                                    Text(budgetCategory)
                                        .font(.system(size: 15))
                                        .foregroundColor(AppColors.textPrimary)
                                }
                            }
                        }
                        .padding(Spacing.lg)
                        .background(AppColors.cardBackground)
                        .cornerRadius(CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(AppColors.primary.opacity(0.2), lineWidth: 1)
                        )
                    }
                }

                // Expenses Section
                if !expenses.isEmpty {
                    VendorExpensesSection(expenses: expenses, payments: payments)
                }

                // Payments Section
                if !payments.isEmpty {
                    VendorPaymentsSection(payments: payments)
                }
            } else {
                // Empty State
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Financial Information")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Add quoted amount, expenses, or payment schedules to track financial details for this vendor.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xxxl)
            }
        }
    }

    private var documentsTab: some View {
        VStack(spacing: Spacing.xxxl) {
            if isLoadingDocuments {
                // Loading State
                VStack(spacing: Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Loading documents...")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !documents.isEmpty {
                // Documents List
                VendorDocumentsSection(documents: documents)
            } else {
                // Empty State
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Documents")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Documents linked to this vendor will appear here. Upload documents from the Documents page and link them to this vendor.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xxxl)
            }
        }
    }

    private var notesTab: some View {
        VStack(spacing: Spacing.xxxl) {
            if let notes = currentVendor.notes, !notes.isEmpty {
                VendorNotesSection(notes: notes)
            } else {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "note.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Notes")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Add notes to keep track of important details about this vendor.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xxxl)
            }
        }
    }

    // MARK: - Computed Properties

    private var hasContactInfo: Bool {
        currentVendor.email != nil || currentVendor.phoneNumber != nil || currentVendor.website != nil
    }

    private var hasFinancialInfo: Bool {
        currentVendor.quotedAmount != nil
    }

    private var hasAnyFinancialInfo: Bool {
        currentVendor.quotedAmount != nil || !expenses.isEmpty || !payments.isEmpty
    }

    // MARK: - Logo Upload

    private func handleLogoUpdate(_ logoImage: NSImage?) async {
        isSavingLogo = true

        do {
            // Get Supabase client
            guard let supabase = SupabaseManager.shared.client else {
                throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
            }

            var updatedVendor = currentVendor

            if let logoImage = logoImage {
                // Convert NSImage to PNG data
                guard let tiffData = logoImage.tiffRepresentation,
                      let bitmapImage = NSBitmapImageRep(data: tiffData),
                      let imageData = bitmapImage.representation(using: .png, properties: [:]) else {
                    AppLogger.ui.error("Failed to convert logo image to PNG data")
                    isSavingLogo = false
                    return
                }

                // Generate unique filename with vendor ID
                let fileName = "vendor_\(currentVendor.id)_\(UUID().uuidString).png"
                let filePath = fileName

                AppLogger.ui.info("Uploading logo to Supabase Storage: \(filePath)")

                // Upload to Supabase Storage with retry
                try await RepositoryNetwork.withRetry(timeout: 30) {
                    try await supabase.storage
                        .from("vendor-profile-pics")
                        .upload(
                            path: filePath,
                            file: imageData,
                            options: FileOptions(
                                cacheControl: "3600",
                                contentType: "image/png",
                                upsert: true
                            )
                        )
                }

                // Get public URL for the uploaded file
                let publicURL = try supabase.storage
                    .from("vendor-profile-pics")
                    .getPublicURL(path: filePath)

                updatedVendor.imageUrl = publicURL.absoluteString

                AppLogger.ui.info("Logo uploaded successfully: \(publicURL.absoluteString)")
            } else {
                // Remove logo - delete from storage if exists
                if let imageUrl = currentVendor.imageUrl,
                   let url = URL(string: imageUrl),
                   let path = extractStoragePath(from: url) {
                    do {
                        try await RepositoryNetwork.withRetry(timeout: 30) {
                            try await supabase.storage
                                .from("vendor-profile-pics")
                                .remove(paths: [path])
                        }
                        AppLogger.ui.info("Logo deleted from storage: \(path)")
                    } catch {
                        AppLogger.ui.error("Failed to delete logo from storage", error: error)
                        // Continue anyway to remove the URL from database
                    }
                }

                updatedVendor.imageUrl = nil
                AppLogger.ui.info("Logo removed for vendor: \(currentVendor.vendorName)")
            }

            // Update vendor in the store
            await vendorStore.updateVendor(updatedVendor)

            // Wait for store to reload and get the updated vendor from the store
            // This ensures the database update is reflected
            if let refreshedVendor = vendorStore.vendors.first(where: { $0.id == currentVendor.id }) {
                currentVendor = refreshedVendor
                AppLogger.ui.info("Vendor logo updated successfully, refreshed from store")
            } else {
                // Fallback to local update if vendor not found in store yet
                currentVendor = updatedVendor
                AppLogger.ui.info("Vendor logo updated successfully, using local state")
            }
        } catch {
            AppLogger.ui.error("Failed to update vendor logo", error: error)
            SentryService.shared.captureError(error, context: [
                "operation": "updateVendorLogo",
                "vendorId": String(currentVendor.id)
            ])
        }

        isSavingLogo = false
    }

    /// Extract storage path from Supabase public URL
    private func extractStoragePath(from url: URL) -> String? {
        // Example URL: https://project.supabase.co/storage/v1/object/public/vendor-profile-pics/file.png
        // We need to extract: file.png
        let pathComponents = url.pathComponents
        if let publicIndex = pathComponents.firstIndex(of: "public"),
           publicIndex + 2 < pathComponents.count {
            let relevantComponents = pathComponents[(publicIndex + 2)...]
            return relevantComponents.joined(separator: "/")
        }
        return nil
    }
}

#Preview {
    VendorDetailViewV2(
        vendor: Vendor(
            id: 1,
            createdAt: Date(),
            updatedAt: Date(),
            vendorName: "Elegant Events Co.",
            vendorType: "Event Planner",
            vendorCategoryId: nil,
            contactName: "Sarah Johnson",
            phoneNumber: "+1 (555) 987-6543",
            email: "sarah@elegantevents.com",
            website: "https://elegantevents.com",
            notes: "Specializes in luxury weddings. Has excellent portfolio and great reviews. Recommended by multiple friends.",
            quotedAmount: 5000,
            imageUrl: nil,
            isBooked: true,
            budgetCategoryId: nil,
            coupleId: UUID(),
            isArchived: false,
            archivedAt: nil,
            includeInExport: true
        ),
        vendorStore: VendorStoreV2()
    )
}
