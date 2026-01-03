//
//  VendorDetailViewV3.swift
//  I Do Blueprint
//
//  V3 Vendor Detail View - Complete rebuild with clean architecture
//  Displays comprehensive vendor information across four tabs:
//  Overview, Financial, Documents, and Notes
//

import SwiftUI
import Dependencies
import Supabase
import Storage

struct VendorDetailViewV3: View {
    // MARK: - Properties

    let vendor: Vendor
    @ObservedObject var vendorStore: VendorStoreV2

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var coordinator: AppCoordinator

    // MARK: - Dependencies

    @Dependency(\.budgetRepository) private var budgetRepository
    @Dependency(\.documentRepository) private var documentRepository

    // MARK: - State

    @State private var currentVendor: Vendor
    @State private var selectedTab: VendorDetailTab = .overview
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    // Financial data
    @State private var expenses: [Expense] = []
    @State private var payments: [PaymentSchedule] = []
    @State private var isLoadingFinancials = false

    // Documents data
    @State private var documents: [Document] = []
    @State private var isLoadingDocuments = false

    // MARK: - Size Constants

    /// Preferred modal width (clamped between min and max)
    private let minWidth: CGFloat = 400
    private let maxWidth: CGFloat = 700

    /// Preferred modal height (clamped between min and max)
    private let minHeight: CGFloat = 350
    private let maxHeight: CGFloat = 850

    /// Threshold below which we use compact layout
    private let compactHeightThreshold: CGFloat = 550

    /// Buffer for window chrome (title bar, toolbar) that isn't available for content
    private let windowChromeBuffer: CGFloat = 40

    // MARK: - Logger

    private let logger = AppLogger.ui

    // MARK: - Computed Properties

    /// Calculate dynamic size based on parent window size from coordinator
    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        // Use 60% of parent width and 75% of parent height (minus chrome buffer), clamped to min/max bounds
        // The chrome buffer accounts for title bar (~28pt) + safety margin
        let targetWidth = min(maxWidth, max(minWidth, parentSize.width * 0.6))
        let targetHeight = min(maxHeight, max(minHeight, parentSize.height * 0.75 - windowChromeBuffer))

        return CGSize(width: targetWidth, height: targetHeight)
    }

    /// Whether to use compact layout (smaller header, everything scrolls)
    private var isCompactMode: Bool {
        dynamicSize.height < compactHeightThreshold
    }

    // MARK: - Initialization

    init(vendor: Vendor, vendorStore: VendorStoreV2) {
        self.vendor = vendor
        self.vendorStore = vendorStore
        _currentVendor = State(initialValue: vendor)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if isCompactMode {
                // COMPACT MODE: Compact header scrolls with content
                ScrollView {
                    VStack(spacing: 0) {
                        // Compact Header (horizontal, smaller)
                        V3VendorCompactHeader(
                            vendor: currentVendor,
                            onClose: { dismiss() }
                        )

                        // Tab Bar
                        V3VendorTabBar(
                            selectedTab: $selectedTab,
                            documentCount: documents.count
                        )

                        Divider()

                        // Tab Content
                        tabContent
                            .padding(.top, Spacing.md)
                    }
                }
            } else {
                // NORMAL MODE: Fixed hero header, scrollable content
                // Hero Header
                V3VendorHeroHeader(
                    vendor: currentVendor,
                    onEdit: { showingEditSheet = true },
                    onDelete: { showingDeleteAlert = true },
                    onClose: { dismiss() },
                    onLogoUpdated: handleLogoUpdate
                )

                // Tab Bar
                V3VendorTabBar(
                    selectedTab: $selectedTab,
                    documentCount: documents.count
                )

                Divider()

                // Tab Content
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(VendorDetailTab.overview)

                    financialTab
                        .tag(VendorDetailTab.financial)

                    documentsTab
                        .tag(VendorDetailTab.documents)

                    notesTab
                        .tag(VendorDetailTab.notes)
                }
                .tabViewStyle(.automatic)
            }
        }
        // Dynamic frame size based on parent window size
        // This explicit frame tells the sheet how big to be
        .frame(width: dynamicSize.width, height: dynamicSize.height)
        .background(SemanticColors.backgroundPrimary)
        .sheet(isPresented: $showingEditSheet) {
            EditVendorSheetV2(vendor: currentVendor, vendorStore: vendorStore) { updatedVendor in
                currentVendor = updatedVendor
            }
        }
        .alert("Delete Vendor", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteVendor()
            }
        } message: {
            Text("Are you sure you want to delete \(currentVendor.vendorName)? This action cannot be undone.")
        }
        .task {
            await loadAllData()
        }
        .onChange(of: vendorStore.vendors) { _, newVendors in
            // Update current vendor if it changed in the store
            if let updated = newVendors.first(where: { $0.id == currentVendor.id }) {
                currentVendor = updated
            }
        }
        .onAppear {
            logger.info("VendorDetailViewV3 appeared for vendor: \(vendor.vendorName)")
        }
    }

    // MARK: - Tab Content

    /// Tab content for compact mode (no TabView wrapper)
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            overviewContent
        case .financial:
            financialContent
        case .documents:
            documentsContent
        case .notes:
            notesContent
        }
    }

    // MARK: - Tab Views (Normal Mode)

    private var overviewTab: some View {
        ScrollView {
            V3VendorOverviewContent(
                vendor: currentVendor,
                onEdit: { showingEditSheet = true },
                onExportToggle: handleExportToggle
            )
            .padding(Spacing.xl)
        }
    }

    private var financialTab: some View {
        ScrollView {
            V3VendorFinancialContent(
                vendor: currentVendor,
                expenses: expenses,
                payments: payments,
                isLoading: isLoadingFinancials
            )
            .padding(Spacing.xl)
        }
    }

    private var documentsTab: some View {
        ScrollView {
            V3VendorDocumentsContent(
                documents: documents,
                isLoading: isLoadingDocuments
            )
            .padding(Spacing.xl)
        }
    }

    private var notesTab: some View {
        ScrollView {
            V3VendorNotesContent(notes: currentVendor.notes)
                .padding(Spacing.xl)
        }
    }

    // MARK: - Content Views (Compact Mode)

    private var overviewContent: some View {
        V3VendorOverviewContent(
            vendor: currentVendor,
            onEdit: { showingEditSheet = true },
            onExportToggle: handleExportToggle
        )
        .padding(Spacing.lg)
    }

    private var financialContent: some View {
        V3VendorFinancialContent(
            vendor: currentVendor,
            expenses: expenses,
            payments: payments,
            isLoading: isLoadingFinancials
        )
        .padding(Spacing.lg)
    }

    private var documentsContent: some View {
        V3VendorDocumentsContent(
            documents: documents,
            isLoading: isLoadingDocuments
        )
        .padding(Spacing.lg)
    }

    private var notesContent: some View {
        V3VendorNotesContent(notes: currentVendor.notes)
            .padding(Spacing.lg)
    }

    // MARK: - Data Loading

    private func loadAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await loadFinancialData()
            }
            group.addTask {
                await loadDocuments()
            }
        }
    }

    private func loadFinancialData() async {
        await MainActor.run {
            isLoadingFinancials = true
        }

        do {
            async let expensesTask = budgetRepository.fetchExpensesByVendor(vendorId: currentVendor.id)
            async let paymentsTask = budgetRepository.fetchPaymentSchedulesByVendor(vendorId: currentVendor.id)

            let fetchedExpenses = try await expensesTask
            let fetchedPayments = try await paymentsTask

            await MainActor.run {
                expenses = fetchedExpenses
                payments = fetchedPayments
                isLoadingFinancials = false
            }

            logger.info("Loaded financial data for vendor \(currentVendor.vendorName): \(fetchedExpenses.count) expenses, \(fetchedPayments.count) payments")
        } catch {
            logger.error("Error loading financial data for vendor \(currentVendor.id)", error: error)
            await MainActor.run {
                isLoadingFinancials = false
            }
        }
    }

    private func loadDocuments() async {
        await MainActor.run {
            isLoadingDocuments = true
        }

        do {
            let fetchedDocuments = try await documentRepository.fetchDocuments(vendorId: Int(currentVendor.id))

            await MainActor.run {
                documents = fetchedDocuments
                isLoadingDocuments = false
            }

            logger.info("Loaded \(fetchedDocuments.count) documents for vendor \(currentVendor.vendorName)")
        } catch {
            logger.error("Error loading documents for vendor \(currentVendor.id)", error: error)
            await MainActor.run {
                isLoadingDocuments = false
            }
        }
    }

    // MARK: - Actions

    private func handleLogoUpdate(_ image: NSImage?) async {
        do {
            // Get Supabase client
            guard let supabase = SupabaseManager.shared.client else {
                throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
            }

            var updatedVendor = currentVendor

            if let logoImage = image {
                // Convert NSImage to PNG data
                guard let tiffData = logoImage.tiffRepresentation,
                      let bitmapImage = NSBitmapImageRep(data: tiffData),
                      let imageData = bitmapImage.representation(using: .png, properties: [:]) else {
                    logger.error("Failed to convert logo image to PNG data")
                    return
                }

                // Generate unique filename with vendor ID
                let fileName = "vendor_\(currentVendor.id)_\(UUID().uuidString).png"
                let filePath = fileName

                logger.info("Uploading logo to Supabase Storage: \(filePath)")

                // Upload to Supabase Storage with retry
                try await NetworkRetry.withRetry {
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

                logger.info("Logo uploaded successfully: \(publicURL.absoluteString)")
            } else {
                // Remove logo
                updatedVendor.imageUrl = nil
                logger.info("Logo removed for vendor: \(currentVendor.vendorName)")
            }

            // Update vendor in database
            await vendorStore.updateVendor(updatedVendor)

            await MainActor.run {
                currentVendor = updatedVendor
            }

        } catch {
            logger.error("Error updating vendor logo", error: error)
        }
    }

    private func handleExportToggle(_ includeInExport: Bool) async {
        var updatedVendor = currentVendor
        updatedVendor.includeInExport = includeInExport

        await vendorStore.updateVendor(updatedVendor)

        await MainActor.run {
            currentVendor = updatedVendor
        }

        logger.info("Export flag updated for vendor \(currentVendor.vendorName): \(includeInExport)")
    }

    private func deleteVendor() {
        Task {
            await vendorStore.deleteVendor(currentVendor)
            await MainActor.run {
                dismiss()
            }
            logger.info("Vendor deleted: \(currentVendor.vendorName)")
        }
    }
}

// MARK: - Preview

#Preview("Vendor Detail V3") {
    VendorDetailViewV3(
        vendor: .makeTest(),
        vendorStore: VendorStoreV2()
    )
}

#Preview("Vendor Detail V3 - Available") {
    VendorDetailViewV3(
        vendor: .makeTest(isBooked: false, dateBooked: nil),
        vendorStore: VendorStoreV2()
    )
}
