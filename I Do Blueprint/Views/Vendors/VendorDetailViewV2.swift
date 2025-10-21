//
//  VendorDetailViewV2.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/1/25.
//  Visual profile-style vendor detail view matching GuestDetailViewV2
//

import SwiftUI

struct VendorDetailViewV2: View {
    let vendor: Vendor
    var vendorStore: VendorStoreV2
    var onExportToggle: ((Bool) async -> Void)? = nil
    @State private var showingEditSheet = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Hero Header Section with Edit Button
            VendorHeroHeaderView(vendor: vendor, onEdit: {
                showingEditSheet = true
            })

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingEditSheet) {
            EditVendorSheetV2(vendor: vendor, vendorStore: vendorStore) { _ in
                // Reload will happen automatically through the store
            }
        }
    }

    // MARK: - Tab Content

    private var overviewTab: some View {
        VStack(spacing: Spacing.xxxl) {
            // Quick Actions Toolbar
            QuickActionsToolbar(actions: quickActions)

            // Export Flag Toggle Section
            VendorExportFlagSection(
                vendor: vendor,
                onToggle: { newValue in
                    Task {
                        await onExportToggle?(newValue)
                    }
                }
            )

            // Quick Info Cards
            VendorQuickInfoSection(vendor: vendor, contractInfo: nil)

            // Contact Section
            if hasContactInfo {
                VendorContactSection(vendor: vendor)
            }

            // Business Details
            VendorBusinessDetailsSection(vendor: vendor, reviewStats: nil)
        }
    }

    private var quickActions: [QuickAction] {
        var actions: [QuickAction] = []

        // Call action
        if let phoneNumber = vendor.phoneNumber {
            actions.append(QuickAction(icon: "phone.fill", title: "Call", color: AppColors.Vendor.booked) {
                if let url = URL(string: "tel:\(phoneNumber.filter { !$0.isWhitespace && $0 != "-" && $0 != "(" && $0 != ")" })") {
                    NSWorkspace.shared.open(url)
                }
            })
        }

        // Email action
        if let email = vendor.email {
            actions.append(QuickAction(icon: "envelope.fill", title: "Email", color: AppColors.Vendor.contacted) {
                if let url = URL(string: "mailto:\(email)") {
                    NSWorkspace.shared.open(url)
                }
            })
        }

        // Website action
        if let website = vendor.website, let url = URL(string: website) {
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
            // Financial Info
            if hasFinancialInfo {
                VendorFinancialSection(vendor: vendor)
            } else {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Financial Information")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Add quoted amount and payment details in the vendor settings.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.xxxl)
            }
        }
    }

    private var documentsTab: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Documents")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Document management for vendors coming soon.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xxxl)
    }

    private var notesTab: some View {
        VStack(spacing: Spacing.xxxl) {
            if let notes = vendor.notes, !notes.isEmpty {
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
        vendor.email != nil || vendor.phoneNumber != nil || vendor.website != nil
    }

    private var hasFinancialInfo: Bool {
        vendor.quotedAmount != nil
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
