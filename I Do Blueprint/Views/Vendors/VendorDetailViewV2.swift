//
//  VendorDetailViewV2.swift
//  My Wedding Planning App
//
//  Created by Claude on 10/1/25.
//  Visual profile-style vendor detail view matching GuestDetailViewV2
//

import SwiftUI
import Dependencies

struct VendorDetailViewV2: View {
    let vendor: Vendor
    var vendorStore: VendorStoreV2
    var onExportToggle: ((Bool) async -> Void)? = nil
    @State private var showingEditSheet = false
    @State private var selectedTab = 0
    
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

    var body: some View {
        VStack(spacing: 0) {
            // Hero Header Section with Edit and Delete Buttons
            VendorHeroHeaderView(
                vendor: vendor,
                onEdit: {
                    showingEditSheet = true
                },
                onDelete: {
                    Task {
                        await vendorStore.deleteVendor(vendor)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingEditSheet) {
            EditVendorSheetV2(vendor: vendor, vendorStore: vendorStore) { _ in
                // Reload will happen automatically through the store
            }
        }
        .task {
            await loadFinancialData()
            await loadDocuments()
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
            print("Error loading documents for vendor \(vendor.id): \(error)")
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
            // Log error but don't show to user - just show empty state
            print("Error loading financial data for vendor \(vendor.id): \(error)")
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
                if let quotedAmount = vendor.quotedAmount {
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
                            
                            if let budgetCategory = vendor.budgetCategoryName {
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
    
    private var hasAnyFinancialInfo: Bool {
        vendor.quotedAmount != nil || !expenses.isEmpty || !payments.isEmpty
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
