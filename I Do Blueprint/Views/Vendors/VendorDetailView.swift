//
//  VendorDetailView.swift
//  I Do Blueprint
//
//  Vendor detail view with tabbed interface
//

import AppKit
import SwiftUI

extension ContractStatus {
    var color: Color {
        switch self {
        case .draft: AppColors.Vendor.notContacted
        case .pending: AppColors.Vendor.pending
        case .signed: AppColors.Vendor.contract
        case .expired: AppColors.error
        case .none: AppColors.Vendor.notContacted
        }
    }
}

struct VendorDetailView: View {
    let vendor: Vendor
    let onSave: (Vendor) -> Void

    @State private var isEditing = false
    @State private var editedVendor: Vendor
    @State private var vendorDetails: VendorDetails
    @State private var isLoadingDetails = true
    @State private var selectedTab = 0
    @EnvironmentObject var vendorStore: VendorStoreV2

    init(vendor: Vendor, onSave: @escaping (Vendor) -> Void) {
        self.vendor = vendor
        self.onSave = onSave
        _editedVendor = State(initialValue: vendor)
        _vendorDetails = State(initialValue: VendorDetails(vendor: vendor))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with vendor image and basic info
            VendorHeaderView(vendor: vendor)
                .padding(.bottom, Spacing.xxl)

            // Status indicators
            VendorStatusView(vendor: vendor, vendorDetails: vendorDetails)
                .padding(.bottom, Spacing.xxl)

            // Tabbed Content
            TabbedDetailView(
                tabs: [
                    DetailTab(title: "Details", icon: "info.circle"),
                    DetailTab(title: "Contact", icon: "envelope.circle"),
                    DetailTab(title: "Financial", icon: "dollarsign.circle"),
                    DetailTab(title: "Contract", icon: "doc.text")
                ],
                selectedTab: $selectedTab
            ) { index in
                ScrollView {
                    VStack(spacing: 20) {
                        switch index {
                        case 0: VendorOverviewTab(vendor: vendor, editedVendor: $editedVendor, isEditing: isEditing)
                        case 1: VendorContactTab(vendor: vendor, editedVendor: $editedVendor, isEditing: isEditing)
                        case 2: VendorFinancialTab(vendor: vendor, vendorDetails: vendorDetails, editedVendor: $editedVendor, isEditing: isEditing)
                        case 3: VendorContractTab(vendor: vendor, vendorDetails: vendorDetails, editedVendor: $editedVendor, isEditing: isEditing)
                        default: EmptyView()
                        }
                    }
                    .padding(Spacing.xl)
                }
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .navigationTitle(vendor.vendorName)
        .task {
            await loadVendorDetails()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            editedVendor = vendor
                            isEditing = false
                        }
                        .buttonStyle(.bordered)

                        Button("Save") {
                            onSave(editedVendor)
                            isEditing = false
                        }
                        .buttonStyle(.borderedProminent)
                        .fontWeight(.semibold)
                    }
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func loadVendorDetails() async {
        isLoadingDetails = true
        defer { isLoadingDetails = false }

        // Fetch extended data in parallel
        async let reviewStats = try? await vendorStore.repository.fetchVendorReviewStats(vendorId: vendor.id)
        async let paymentSummary = try? await vendorStore.repository.fetchVendorPaymentSummary(vendorId: vendor.id)
        async let contractInfo = try? await vendorStore.repository.fetchVendorContractSummary(vendorId: vendor.id)

        vendorDetails.reviewStats = await reviewStats
        vendorDetails.paymentSummary = await paymentSummary
        vendorDetails.contractInfo = await contractInfo
    }
}

#Preview {
    VendorDetailView(
        vendor: Vendor(
            id: 1,
            createdAt: Date(),
            updatedAt: Date(),
            vendorName: "Elegant Flowers",
            vendorType: "Florist",
            vendorCategoryId: "flowers",
            contactName: "Sarah Johnson",
            phoneNumber: "(555) 123-4567",
            email: "sarah@elegantflowers.com",
            website: "https://elegantflowers.com",
            notes: "Specializes in wedding bouquets and centerpieces",
            quotedAmount: 2500.0,
            imageUrl: nil,
            isBooked: true,
            budgetCategoryId: nil,
            coupleId: UUID(),
            isArchived: false,
            archivedAt: nil,
            includeInExport: true)) { _ in }
}
