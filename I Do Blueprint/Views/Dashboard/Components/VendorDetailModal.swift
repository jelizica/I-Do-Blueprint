//
//  VendorDetailModal.swift
//  I Do Blueprint
//
//  Modal for displaying vendor details from dashboard
//

import SwiftUI
import Dependencies

struct VendorDetailModal: View {
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
            // Header
            VendorDetailModalHeader(
                vendor: vendor,
                loadedImage: loadedImage,
                onEdit: { showingEditSheet = true },
                onDismiss: { dismiss() }
            )

            Divider()

            // Tab Bar
            VendorDetailModalTabBar(selectedTab: $selectedTab)

            Divider()

            // Content
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    switch selectedTab {
                    case 0:
                        VendorDetailOverviewTab(vendor: vendor)
                    case 1:
                        VendorDetailFinancialTab(
                            vendor: vendor,
                            expenses: expenses,
                            payments: payments,
                            isLoading: isLoadingFinancials
                        )
                    case 2:
                        VendorDetailDocumentsTab(
                            documents: documents,
                            isLoading: isLoadingDocuments
                        )
                    case 3:
                        VendorDetailNotesTab(vendor: vendor)
                    default:
                        EmptyView()
                    }
                }
                .padding(Spacing.xl)
            }
            .background(AppColors.background)
        }
        .background(AppColors.textPrimary)
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
            logger.info("VendorDetailModal appeared for vendor: \(vendor.vendorName)")
        }
    }

    // MARK: - Image Loading

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
    VendorDetailModal(
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
