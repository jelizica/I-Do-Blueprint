//
//  DocumentDetailView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct DocumentDetailView: View {
    let document: Document
    @ObservedObject var viewModel: DocumentStoreV2

    @Environment(\.dismiss) private var dismiss
    @State private var fileName: String
    @State private var documentType: DocumentType
    @State private var vendorId: Int?
    @State private var expenseId: UUID?
    @State private var tags: [String]

    @State private var availableVendors: [(id: Int, name: String)] = []
    @State private var availableExpenses: [(id: UUID, description: String)] = []
    @State private var availablePayments: [(id: Int64, description: String)] = []
    @State private var isLoadingEntities = false
    @State private var isSaving = false
    @State private var showingDeleteConfirmation = false
    @State private var showingURLError = false
    @State private var urlErrorMessage = ""

    private let logger = AppLogger.ui

    init(document: Document, viewModel: DocumentStoreV2) {
        self.document = document
        self.viewModel = viewModel

        _fileName = State(initialValue: document.originalFilename)
        _documentType = State(initialValue: document.documentType)
        _vendorId = State(initialValue: document.vendorId)
        _expenseId = State(initialValue: document.expenseId)
        _tags = State(initialValue: document.tags)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // File preview
                    filePreview

                    // File name
                    fileNameSection

                    // Document type
                    documentTypeSection

                    // Vendor link
                    vendorSection

                    // Expense link
                    expenseSection

                    // Tags
                    tagsSection

                    // Payment link
                    paymentSection

                    // Metadata
                    metadataSection

                    // Danger zone
                    dangerZone
                }
                .padding(Spacing.xl)
            }
            .navigationTitle("Document Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .disabled(isSaving || !isFormValid)
                }
            }
            .task {
                await loadEntities()
            }
        }
        .frame(width: 900, height: 600)
        .alert("Invalid Document URL", isPresented: $showingURLError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(urlErrorMessage)
        }
    }

    // MARK: - File Preview

    private var filePreview: some View {
        VStack {
            if document.isImage, let url = try? getPublicURL(),
               let imageData = try? Data(contentsOf: url),
               let image = NSImage(data: imageData) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: iconForDocument)
                        .font(.system(size: 60))
                        .foregroundColor(colorForType(documentType))

                    Text(document.fileExtension)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 150)
            }

            HStack(spacing: 12) {
                Button("View") {
                    if let url = try? getPublicURL() {
                        // ✅ Validate URL before opening
                        do {
                            try URLValidator.validate(url)
                            NSWorkspace.shared.open(url)
                        } catch {
                            urlErrorMessage = error.localizedDescription
                            showingURLError = true
                            logger.error("Rejected unsafe document URL", error: error)
                        }
                    } else {
                        urlErrorMessage = "Document URL is missing or invalid"
                        showingURLError = true
                        logger.error("Failed to get document URL")
                    }
                }
                .buttonStyle(.bordered)

                Button("Download") {
                    Task {
                        await downloadFile()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - File Name Section

    private var fileNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("File Name")
                .font(.headline)

            TextField("File name", text: $fileName)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Document Type Section

    private var documentTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Document Type")
                .font(.headline)

            Picker("Type", selection: $documentType) {
                ForEach(DocumentType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: type.iconName)
                        Text(type.displayName)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Vendor Section

    private var vendorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Linked Vendor")
                .font(.headline)

            if isLoadingEntities {
                ProgressView()
                    .scaleEffect(0.7)
            } else if availableVendors.isEmpty {
                Text("No vendors available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Picker("Vendor", selection: $vendorId) {
                    Text("None").tag(Int?.none)

                    ForEach(availableVendors, id: \.id) { vendor in
                        Text(vendor.name).tag(Int?.some(vendor.id))
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Expense Section

    private var expenseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Linked Expense")
                .font(.headline)

            if isLoadingEntities {
                ProgressView()
                    .scaleEffect(0.7)
            } else if availableExpenses.isEmpty {
                Text("No expenses available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Picker("Expense", selection: $expenseId) {
                    Text("None").tag(UUID?.none)

                    ForEach(availableExpenses, id: \.id) { expense in
                        Text(expense.description).tag(UUID?.some(expense.id))
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: expenseId) { _ in
                    Task {
                        await loadPaymentsForExpense()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)

            DocumentTagInputView(tags: $tags)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Payment Section

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Linked Payments")
                .font(.headline)

            if expenseId == nil {
                Text("Select an expense to view related payments")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if isLoadingEntities {
                ProgressView()
                    .scaleEffect(0.7)
            } else if availablePayments.isEmpty {
                Text("No payments for this expense")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(availablePayments, id: \.id) { payment in
                        HStack(spacing: 8) {
                            Text(payment.description)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.vertical, Spacing.xs)

                        if payment.id != availablePayments.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metadata")
                .font(.headline)

            VStack(spacing: 8) {
                metadataRow(label: "File Size", value: document.formattedSize)
                metadataRow(label: "Uploaded", value: formatDate(document.uploadedAt))
                metadataRow(label: "Last Modified", value: formatDate(document.updatedAt))
                metadataRow(label: "Storage Bucket", value: document.bucketName)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger Zone")
                .font(.headline)
                .foregroundColor(.red)

            Button("Delete Document") {
                showingDeleteConfirmation = true
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .alert("Delete Document", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteDocument(document.id)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this document? This action cannot be undone.")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.05)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Helper Methods

    private var isFormValid: Bool {
        !fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveChanges() async {
        isSaving = true

        // Call viewModel directly - no closure, no Sendable issues
        await viewModel.updateDocument(
            document.id,
            fileName: fileName,
            documentType: documentType,
            vendorId: vendorId,
            expenseId: expenseId,
            tags: tags)

        // Ensure state update and dismiss happen on main actor
        await MainActor.run {
            isSaving = false
        }

        // Brief delay before dismiss to let the update settle
        try? await Task.sleep(nanoseconds: 50_000_000)

        await MainActor.run {
            dismiss()
        }
    }

    private func loadEntities() async {
        isLoadingEntities = true

        do {
            let api = DocumentsAPI()
            async let vendorsTask = api.fetchVendors()
            async let expensesTask = api.fetchExpenses()

            (availableVendors, availableExpenses) = try await (vendorsTask, expensesTask)

            // Load payments filtered by selected expense
            await loadPaymentsForExpense()
        } catch {
            logger.error("Failed to load entities", error: error)
        }

        isLoadingEntities = false
    }

    private func loadPaymentsForExpense() async {
        do {
            let api = DocumentsAPI()
            availablePayments = try await api.fetchPayments(forExpenseId: expenseId)
        } catch {
            logger.error("Failed to load payments", error: error)
        }
    }

    private func getPublicURL() throws -> URL {
        let api = DocumentsAPI()
        return try api.getPublicURL(bucketName: document.bucketName, path: document.storagePath)
    }

    private func downloadFile() async {
        do {
            let api = DocumentsAPI()
            let data = try await api.downloadFile(bucketName: document.bucketName, path: document.storagePath)

            let savePanel = NSSavePanel()
            savePanel.nameFieldStringValue = document.originalFilename
            savePanel.canCreateDirectories = true

            await MainActor.run {
                if savePanel.runModal() == .OK {
                    if let url = savePanel.url {
                        try? data.write(to: url)
                    }
                }
            }
        } catch {
            logger.error("Failed to download document", error: error)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var iconForDocument: String {
        if document.isPDF {
            "doc.richtext.fill"
        } else if document.isImage {
            "photo.fill"
        } else {
            "doc.fill"
        }
    }

    private func colorForType(_ type: DocumentType) -> Color {
        switch type.color {
        case "blue": .blue
        case "green": .green
        case "orange": .orange
        case "purple": .purple
        case "gray": .gray
        default: .primary
        }
    }
}

// MARK: - Preview

#Preview {
    DocumentDetailView(
        document: Document(
            id: UUID(),
            coupleId: UUID(),
            originalFilename: "Venue_Contract.pdf",
            storagePath: "contracts/venue.pdf",
            fileSize: 2_500_000,
            mimeType: "application/pdf",
            documentType: .contract,
            bucketName: "invoices-and-contracts",
            vendorId: 1,
            expenseId: nil,
            paymentId: nil,
            tags: ["venue", "signed"],
            uploadedBy: "user@example.com",
            uploadedAt: Date().addingTimeInterval(-86400 * 5),
            updatedAt: Date().addingTimeInterval(-86400 * 2),
            autoTagStatus: .manual,
            autoTagSource: .manual,
            autoTaggedAt: nil,
            autoTagError: nil),
        viewModel: DocumentStoreV2())
}
