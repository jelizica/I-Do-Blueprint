//
//  VendorDetailModal.swift
//  I Do Blueprint
//
//  Modal for displaying vendor details from dashboard
//

// swiftlint:disable file_length

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
            modalHeader

            Divider()

            // Tab Bar
            tabBar

            Divider()

            // Content
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    switch selectedTab {
                    case 0: overviewTab
                    case 1: financialTab
                    case 2: documentsTab
                    case 3: notesTab
                    default: EmptyView()
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

    // MARK: - Header

    private var modalHeader: some View {
        HStack(spacing: Spacing.md) {
            // Vendor Icon or Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientForVendorType(vendor.vendorType ?? ""),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                if let image = loadedImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else {
                    Image(systemName: iconForVendorType(vendor.vendorType ?? ""))
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(vendor.vendorName)
                    .font(Typography.title2)
                    .foregroundColor(AppColors.textPrimary)

                HStack(spacing: Spacing.sm) {
                    if let type = vendor.vendorType {
                        Text(type)
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }

                    if vendor.isBooked == true {
                        Text("•")
                            .foregroundColor(AppColors.textSecondary)

                        HStack(spacing: Spacing.xxs) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Booked")
                                .font(Typography.caption2)
                        }
                        .foregroundColor(AppColors.Vendor.booked)
                    }
                }
            }

            Spacer()

            // Action Buttons
            HStack(spacing: Spacing.sm) {
                Button {
                    showingEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 32, height: 32)
                        .background(AppColors.primary.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                }
                .buttonStyle(.plain)
                .accessibleActionButton(label: "Edit vendor", hint: "Opens edit form")

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(AppColors.cardBackground)
                        .cornerRadius(CornerRadius.sm)
                }
                .buttonStyle(.plain)
                .accessibleActionButton(label: "Close modal", hint: "Closes vendor details")
            }
        }
        .padding(Spacing.xl)
        .background(AppColors.textPrimary)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            VendorModalTabButton(title: "Overview", icon: "info.circle", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            VendorModalTabButton(title: "Financial", icon: "dollarsign.circle", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            VendorModalTabButton(title: "Documents", icon: "doc.text", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            VendorModalTabButton(title: "Notes", icon: "note.text", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
        }
        .background(AppColors.textPrimary)
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        VStack(spacing: Spacing.xl) {
            // Quick Info Cards
            HStack(spacing: Spacing.md) {
                if let quotedAmount = vendor.quotedAmount {
                    VendorQuickInfoCard(
                        icon: "dollarsign.circle.fill",
                        title: "Quoted Amount",
                        value: quotedAmount.formatted(.currency(code: "USD")),
                        color: AppColors.Vendor.booked
                    )
                }

                if vendor.isBooked == true, let dateBooked = vendor.dateBooked {
                    VendorQuickInfoCard(
                        icon: "calendar.circle.fill",
                        title: "Booked Date",
                        value: dateBooked.formatted(date: .abbreviated, time: .omitted),
                        color: AppColors.success
                    )
                }
            }

            // Contact Information
            if hasContactInfo {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    SectionHeaderV2(
                        title: "Contact Information",
                        icon: "person.circle.fill",
                        color: AppColors.primary
                    )

                    VStack(spacing: Spacing.sm) {
                        if let contactName = vendor.contactName {
                            VendorContactRow(icon: "person.fill", label: "Contact", value: contactName)
                        }

                        if let phone = vendor.phoneNumber {
                            VendorContactRow(icon: "phone.fill", label: "Phone", value: phone, isLink: true) {
                                if let url = URL(string: "tel:\(phone.filter { !$0.isWhitespace })") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }

                        if let email = vendor.email {
                            VendorContactRow(icon: "envelope.fill", label: "Email", value: email, isLink: true) {
                                if let url = URL(string: "mailto:\(email)") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }

                        if let website = vendor.website {
                            VendorContactRow(icon: "globe", label: "Website", value: website, isLink: true) {
                                if let url = URL(string: website) {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                        }
                    }
                    .padding(Spacing.md)
                    .background(AppColors.cardBackground)
                    .cornerRadius(CornerRadius.md)
                }
            }

            // Address
            if let address = vendor.address {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    SectionHeaderV2(
                        title: "Address",
                        icon: "mappin.circle.fill",
                        color: AppColors.Vendor.contacted
                    )

                    Text(address)
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.cardBackground)
                        .cornerRadius(CornerRadius.md)
                }
            }
        }
    }

    // MARK: - Financial Tab

    private var financialTab: some View {
        VStack(spacing: Spacing.xl) {
            if isLoadingFinancials {
                VStack(spacing: Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Loading financial data...")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if hasAnyFinancialInfo {
                // Summary Cards
                HStack(spacing: Spacing.md) {
                    FinancialSummaryCard(
                        title: "Quoted Amount",
                        amount: vendor.quotedAmount ?? 0,
                        icon: "banknote.fill",
                        color: AppColors.primary
                    )

                    FinancialSummaryCard(
                        title: "Total Expenses",
                        amount: totalExpenses,
                        icon: "chart.bar.fill",
                        color: AppColors.warning
                    )

                    FinancialSummaryCard(
                        title: "Total Paid",
                        amount: totalPaid,
                        icon: "checkmark.circle.fill",
                        color: AppColors.success
                    )
                }

                // Expenses List
                if !expenses.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeaderV2(
                            title: "Expenses (\(expenses.count))",
                            icon: "list.bullet.circle.fill",
                            color: AppColors.warning
                        )

                        VStack(spacing: Spacing.sm) {
                            ForEach(expenses) { expense in
                                ExpenseRow(expense: expense)
                            }
                        }
                        .padding(Spacing.md)
                        .background(AppColors.cardBackground)
                        .cornerRadius(CornerRadius.md)
                    }
                }

                // Payments List
                if !payments.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeaderV2(
                            title: "Payment Schedule (\(payments.count))",
                            icon: "calendar.circle.fill",
                            color: AppColors.success
                        )

                        VStack(spacing: Spacing.sm) {
                            ForEach(payments) { payment in
                                PaymentRow(payment: payment)
                            }
                        }
                        .padding(Spacing.md)
                        .background(AppColors.cardBackground)
                        .cornerRadius(CornerRadius.md)
                    }
                }
            } else {
                VendorEmptyStateView(
                    icon: "dollarsign.circle",
                    title: "No Financial Information",
                    message: "Add quoted amount, expenses, or payment schedules to track financial details for this vendor."
                )
            }
        }
    }

    // MARK: - Documents Tab

    private var documentsTab: some View {
        VStack(spacing: Spacing.xl) {
            if isLoadingDocuments {
                VStack(spacing: Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Loading documents...")
                        .font(Typography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if !documents.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    SectionHeaderV2(
                        title: "Documents (\(documents.count))",
                        icon: "doc.text.fill",
                        color: AppColors.primary
                    )

                    VStack(spacing: Spacing.sm) {
                        ForEach(documents) { document in
                            DocumentRow(document: document)
                        }
                    }
                    .padding(Spacing.md)
                    .background(AppColors.cardBackground)
                    .cornerRadius(CornerRadius.md)
                }
            } else {
                VendorEmptyStateView(
                    icon: "doc.text",
                    title: "No Documents",
                    message: "Documents linked to this vendor will appear here. Upload documents from the Documents page and link them to this vendor."
                )
            }
        }
    }

    // MARK: - Notes Tab

    private var notesTab: some View {
        VStack(spacing: Spacing.xl) {
            if let notes = vendor.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    SectionHeaderV2(
                        title: "Notes",
                        icon: "note.text.fill",
                        color: AppColors.primary
                    )

                    Text(notes)
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.cardBackground)
                        .cornerRadius(CornerRadius.md)
                }
            } else {
                VendorEmptyStateView(
                    icon: "note.text",
                    title: "No Notes",
                    message: "Add notes to keep track of important details about this vendor."
                )
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

    // MARK: - Computed Properties

    private var hasContactInfo: Bool {
        vendor.contactName != nil || vendor.email != nil || vendor.phoneNumber != nil || vendor.website != nil
    }

    private var hasAnyFinancialInfo: Bool {
        vendor.quotedAmount != nil || !expenses.isEmpty || !payments.isEmpty
    }

    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var totalPaid: Double {
        payments.filter { $0.paid == true }.reduce(0) { $0 + $1.paymentAmount }
    }

    // MARK: - Helper Functions

    private func iconForVendorType(_ type: String) -> String {
        switch type.lowercased() {
        case "venue": return "mappin.circle.fill"
        case "photography", "photographer": return "camera.fill"
        case "catering", "caterer": return "fork.knife"
        case "music", "dj", "band": return "music.note"
        case "florist", "flowers": return "leaf.fill"
        default: return "briefcase.fill"
        }
    }

    private func gradientForVendorType(_ type: String) -> [Color] {
        switch type.lowercased() {
        case "venue": return [Color.fromHex("EC4899"), Color.fromHex("F43F5E")]
        case "photography", "photographer": return [Color.fromHex("A855F7"), Color.fromHex("EC4899")]
        case "catering", "caterer": return [Color.fromHex("F97316"), Color.fromHex("EC4899")]
        case "music", "dj", "band": return [Color.fromHex("3B82F6"), Color.fromHex("A855F7")]
        case "florist", "flowers": return [Color.fromHex("10B981"), Color.fromHex("059669")]
        default: return [Color.fromHex("6366F1"), Color.fromHex("8B5CF6")]
        }
    }
}

// MARK: - Supporting Views

private struct VendorModalTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(Typography.bodyRegular)
            }
            .foregroundColor(isSelected ? AppColors.primary : AppColors.textSecondary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                Rectangle()
                    .fill(isSelected ? AppColors.primary.opacity(0.1) : Color.clear)
            )
            .overlay(
                Rectangle()
                    .fill(isSelected ? AppColors.primary : Color.clear)
                    .frame(height: 2),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}

private struct VendorQuickInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)

                Text(value)
                    .font(Typography.bodyRegular)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
    }
}

private struct VendorContactRow: View {
    let icon: String
    let label: String
    let value: String
    var isLink: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 20)

            Text(label)
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 80, alignment: .leading)

            if isLink, let action = action {
                Button(action: action) {
                    Text(value)
                        .font(Typography.bodyRegular)
                        .foregroundColor(AppColors.primary)
                        .underline()
                }
                .buttonStyle(.plain)
            } else {
                Text(value)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()
        }
    }
}

private struct FinancialSummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(title)
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)

            Text(amount.formatted(.currency(code: "USD")))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(CornerRadius.md)
    }
}

private struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(expense.expenseName)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)

                Text(expense.expenseDate.formatted(date: .abbreviated, time: .omitted))
                    .font(Typography.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(expense.amount.formatted(.currency(code: "USD")))
                    .font(Typography.bodyRegular)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)

                VendorStatusBadge(status: expense.paymentStatus)
            }
        }
        .padding(Spacing.sm)
        .background(AppColors.textPrimary)
        .cornerRadius(CornerRadius.sm)
    }
}

private struct PaymentRow: View {
    let payment: PaymentSchedule

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(payment.paymentDate.formatted(date: .abbreviated, time: .omitted))
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)

                if let notes = payment.notes, !notes.isEmpty {
                    Text(notes)
                        .font(Typography.caption2)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text(payment.paymentAmount.formatted(.currency(code: "USD")))
                    .font(Typography.bodyRegular)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)

                HStack(spacing: Spacing.xxs) {
                    Image(systemName: payment.paid == true ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                    Text(payment.paid == true ? "Paid" : "Pending")
                        .font(Typography.caption2)
                }
                .foregroundColor(payment.paid == true ? AppColors.success : AppColors.warning)
            }
        }
        .padding(Spacing.sm)
        .background(AppColors.textPrimary)
        .cornerRadius(CornerRadius.sm)
    }
}

private struct DocumentRow: View {
    let document: Document

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "doc.fill")
                .font(.system(size: 16))
                .foregroundColor(AppColors.primary)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(document.originalFilename)
                    .font(Typography.bodyRegular)
                    .foregroundColor(AppColors.textPrimary)

                Text(document.documentType.displayName)
                    .font(Typography.caption2)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Text(document.uploadedAt.formatted(date: .abbreviated, time: .omitted))
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(Spacing.sm)
        .background(AppColors.textPrimary)
        .cornerRadius(CornerRadius.sm)
    }
}

private struct VendorStatusBadge: View {
    let status: PaymentStatus

    private var statusColor: Color {
        switch status {
        case .paid: return AppColors.success
        case .pending: return AppColors.warning
        case .overdue: return AppColors.error
        default: return AppColors.textSecondary
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(Typography.caption2)
            .foregroundColor(statusColor)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(statusColor.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
    }
}

private struct VendorEmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary)

            Text(title)
                .font(Typography.heading)
                .foregroundColor(AppColors.textSecondary)

            Text(message)
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
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
