//
//  VendorDetailModalV2.swift
//  I Do Blueprint
//
//  Enhanced modal for displaying vendor details with improved design
//  Features: Proportional sizing, action buttons, export settings, improved tab content
//

import SwiftUI
import Dependencies

struct VendorDetailModalV2: View {
    let vendor: Vendor
    @ObservedObject var vendorStore: VendorStoreV2
    @EnvironmentObject private var budgetStore: BudgetStoreV2
    @EnvironmentObject private var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0
    @State private var showingEditSheet = false
    @State private var loadedImage: NSImage?

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

    private let logger = AppLogger.ui

    // MARK: - Size Constants (Proportional Modal Sizing Pattern)
    
    /// Minimum modal width
    private let minWidth: CGFloat = 500
    /// Maximum modal width
    private let maxWidth: CGFloat = 900
    /// Minimum modal height
    private let minHeight: CGFloat = 450
    /// Maximum modal height
    private let maxHeight: CGFloat = 950
    /// Buffer for window chrome (title bar, toolbar)
    private let windowChromeBuffer: CGFloat = 40
    /// Width proportion of parent window
    private let widthProportion: CGFloat = 0.65
    /// Height proportion of parent window
    private let heightProportion: CGFloat = 0.80

    // MARK: - Computed Properties
    
    /// Calculate dynamic size based on parent window size
    private var dynamicSize: CGSize {
        let parentSize = coordinator.parentWindowSize
        
        // Calculate proportional size
        let targetWidth = parentSize.width * widthProportion
        let targetHeight = parentSize.height * heightProportion - windowChromeBuffer
        
        // Clamp to min/max bounds
        let finalWidth = min(maxWidth, max(minWidth, targetWidth))
        let finalHeight = min(maxHeight, max(minHeight, targetHeight))
        
        return CGSize(width: finalWidth, height: finalHeight)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with vendor info and action buttons
            VendorDetailHeaderV2(
                vendor: vendor,
                loadedImage: loadedImage,
                onCall: handleCall,
                onEmail: handleEmail,
                onWebsite: handleWebsite,
                onEdit: { showingEditSheet = true },
                onDismiss: { dismiss() }
            )

            Divider()

            // Tab Bar
            VendorDetailTabBarV2(selectedTab: $selectedTab)

            Divider()

            // Content - transparent to show modal vibrancy
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    switch selectedTab {
                    case 0:
                        VendorDetailOverviewTabV2(
                            vendor: vendor,
                            vendorStore: vendorStore,
                            budgetCategories: budgetStore.categoryStore.categories
                        )
                    case 1:
                        VendorDetailFinancialTabV2(
                            vendor: vendor,
                            expenses: expenses,
                            payments: payments,
                            isLoading: isLoadingFinancials
                        )
                    case 2:
                        VendorDetailDocumentsTabV2(
                            vendor: vendor,
                            documents: documents,
                            isLoading: isLoadingDocuments
                        )
                    case 3:
                        VendorDetailNotesTabV2(
                            vendor: vendor,
                            vendorStore: vendorStore
                        )
                    default:
                        EmptyView()
                    }
                }
                .padding(Spacing.xl)
            }
        }
        .frame(width: dynamicSize.width, height: dynamicSize.height)
        .modalBackground(cornerRadius: CornerRadius.xl)
        .sheet(isPresented: $showingEditSheet) {
            EditVendorSheetV4(
                vendor: vendor,
                vendorStore: vendorStore,
                onSave: { _ in
                    // Reload will happen automatically through the store
                }
            )
        }
        .task {
            await loadVendorImage()
            await loadFinancialData()
            await loadDocuments()
        }
        .onAppear {
            logger.info("VendorDetailModalV2 appeared for vendor: \(vendor.vendorName)")
        }
    }

    // MARK: - Action Handlers

    private func handleCall() {
        guard let phone = vendor.phoneNumber else { return }
        let cleanPhone = phone.filter { !$0.isWhitespace }
        if let url = URL(string: "tel:\(cleanPhone)") {
            NSWorkspace.shared.open(url)
        }
    }

    private func handleEmail() {
        guard let email = vendor.email else { return }
        if let url = URL(string: "mailto:\(email)") {
            NSWorkspace.shared.open(url)
        }
    }

    private func handleWebsite() {
        guard let website = vendor.website else { return }
        var urlString = website
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Image Loading

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
            logger.error("Failed to load vendor image from URL: \(imageUrl)", error: error)
            await MainActor.run {
                loadedImage = nil
            }
        }
    }

    // MARK: - Data Loading

    private func loadFinancialData() async {
        isLoadingFinancials = true
        financialLoadError = nil

        do {
            async let expensesTask = budgetRepository.fetchExpensesByVendor(vendorId: vendor.id)
            async let paymentsTask = budgetRepository.fetchPaymentSchedulesByVendor(vendorId: vendor.id)

            expenses = try await expensesTask
            payments = try await paymentsTask

            logger.info("Loaded financial data for vendor \(vendor.vendorName): \(expenses.count) expenses, \(payments.count) payments")
        } catch {
            financialLoadError = error
            logger.error("Error loading financial data for vendor \(vendor.id)", error: error)
        }

        isLoadingFinancials = false
    }

    private func loadDocuments() async {
        isLoadingDocuments = true
        documentLoadError = nil

        do {
            documents = try await documentRepository.fetchDocuments(vendorId: Int(vendor.id))
            logger.info("Loaded \(documents.count) documents for vendor \(vendor.vendorName)")
        } catch {
            documentLoadError = error
            logger.error("Error loading documents for vendor \(vendor.id)", error: error)
        }

        isLoadingDocuments = false
    }
}

// MARK: - Preview

#Preview {
    VendorDetailModalV2(
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
            notes: "Specializes in luxury weddings. Has excellent portfolio and great reviews.",
            quotedAmount: 5000,
            imageUrl: nil,
            isBooked: true,
            dateBooked: Date(),
            budgetCategoryId: nil,
            coupleId: UUID(),
            isArchived: false,
            archivedAt: nil,
            includeInExport: true
        ),
        vendorStore: VendorStoreV2()
    )
    .environmentObject(AppCoordinator.shared)
    .environmentObject(BudgetStoreV2())
}
