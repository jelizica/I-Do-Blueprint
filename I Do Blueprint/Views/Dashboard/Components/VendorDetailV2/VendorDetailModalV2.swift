//
//  VendorDetailModalV2.swift
//  I Do Blueprint
//
//  Enhanced modal for displaying vendor details with improved design
//  Features: Action buttons, export settings, improved tab content
//

import SwiftUI
import Dependencies

struct VendorDetailModalV2: View {
    let vendor: Vendor
    @ObservedObject var vendorStore: VendorStoreV2
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

            // Content
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    switch selectedTab {
                    case 0:
                        VendorDetailOverviewTabV2(
                            vendor: vendor,
                            vendorStore: vendorStore
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
            .background(SemanticColors.backgroundPrimary)
        }
        .background(SemanticColors.backgroundPrimary)
        .sheet(isPresented: $showingEditSheet) {
            EditVendorSheetV2(vendor: vendor, vendorStore: vendorStore) { _ in
                // Reload will happen automatically through the store
            }
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
}
