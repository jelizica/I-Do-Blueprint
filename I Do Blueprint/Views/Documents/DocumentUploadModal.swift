//
//  DocumentUploadModal.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentUploadModal: View {
    let onUpload: (FileUploadMetadata) async -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFiles: [FileUploadMetadata] = []
    @State private var currentFileIndex = 0
    @State private var isUploading = false
    @State private var showFilePicker = false
    @State private var isDragging = false

    // Available vendors, expenses, and payments
    @State private var availableVendors: [(id: Int, name: String)] = []
    @State private var availableExpenses: [(id: UUID, description: String)] = []
    @State private var availablePayments: [(id: Int64, description: String)] = []
    @State private var isLoadingEntities = false

    private let logger = AppLogger.ui

    var currentFile: Binding<FileUploadMetadata>? {
        guard !selectedFiles.isEmpty, currentFileIndex < selectedFiles.count else {
            return nil
        }
        return $selectedFiles[currentFileIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedFiles.isEmpty {
                    // File selection view
                    fileSelectionView
                } else {
                    // Metadata entry view
                    metadataEntryView
                }
            }
            .navigationTitle("Upload Documents")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .disabled(isUploading)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if selectedFiles.isEmpty {
                        Button("Select Files") {
                            showFilePicker = true
                        }
                    } else {
                        Button(currentFileIndex < selectedFiles.count - 1 ? "Next" : "Upload") {
                            handleNextOrUpload()
                        }
                        .disabled(isUploading || !isCurrentFileValid)
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.pdf, .image, .plainText, .data],
                allowsMultipleSelection: true) { result in
                handleFileSelection(result)
            }
            .task {
                await loadEntities()
            }
        }
        .frame(width: 700, height: 600)
    }

    // MARK: - File Selection View

    private var fileSelectionView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Drop zone
            VStack(spacing: 16) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 60))
                    .foregroundColor(isDragging ? .blue : .secondary)

                Text("Drop files here")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("or")
                    .foregroundColor(.secondary)

                Button("Browse Files") {
                    showFilePicker = true
                }
                .buttonStyle(.borderedProminent)

                Text("Supported formats: PDF, Images, Documents")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isDragging ? Color.blue : Color.gray.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isDragging ? Color.blue.opacity(0.05) : Color(NSColor.controlBackgroundColor)
                                .opacity(0.3))))
            .padding(40)
            .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
                handleDrop(providers: providers)
                return true
            }

            Spacer()
        }
    }

    // MARK: - Metadata Entry View

    private var metadataEntryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Progress indicator
                if selectedFiles.count > 1 {
                    progressIndicator
                }

                if let currentFile {
                    // File preview
                    filePreview(currentFile.wrappedValue)

                    // Document Type
                    documentTypeSection(currentFile)

                    // Bucket Selection
                    bucketSection(currentFile)

                    // Vendor Selection
                    vendorSection(currentFile)

                    // Expense Selection
                    expenseSection(currentFile)

                    // Payment Selection
                    paymentSection(currentFile)

                    // Tags
                    tagsSection(currentFile)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("File \(currentFileIndex + 1) of \(selectedFiles.count)")
                .font(.headline)

            ProgressView(value: Double(currentFileIndex + 1), total: Double(selectedFiles.count))
                .progressViewStyle(.linear)

            HStack {
                ForEach(0 ..< selectedFiles.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentFileIndex ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - File Preview

    private func filePreview(_ file: FileUploadMetadata) -> some View {
        HStack(spacing: 12) {
            // Thumbnail or icon
            if file.isImage, let imageData = try? Data(contentsOf: file.localURL),
               let image = NSImage(data: imageData) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "doc.fill")
                    .font(.system(size: 30))
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor)))
            }

            VStack(alignment: .leading, spacing: 4) {
                TextField("File name", text: Binding(
                    get: { file.fileName },
                    set: { if let index = selectedFiles.firstIndex(where: { $0.id == file.id }) {
                        selectedFiles[index].fileName = $0
                    }}))
                    .textFieldStyle(.plain)
                    .font(.body)
                    .fontWeight(.medium)

                Text(file.formattedSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Document Type Section

    private func documentTypeSection(_ file: Binding<FileUploadMetadata>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Document Type")
                .font(.headline)

            Picker("Select document type", selection: file.documentType) {
                ForEach(DocumentType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.iconName)
                        .tag(type)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Bucket Section

    private func bucketSection(_ file: Binding<FileUploadMetadata>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage Location")
                .font(.headline)

            Picker("Bucket", selection: file.bucket) {
                ForEach(DocumentBucket.allCases, id: \.self) { bucket in
                    HStack {
                        Image(systemName: bucket.iconName)
                        Text(bucket.displayName)
                    }
                    .tag(bucket)
                }
            }
            .pickerStyle(.radioGroup)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Vendor Section

    private func vendorSection(_ file: Binding<FileUploadMetadata>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Link to Vendor (Optional)")
                .font(.headline)

            if isLoadingEntities {
                ProgressView()
                    .scaleEffect(0.7)
            } else if availableVendors.isEmpty {
                Text("No vendors available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Picker("Vendor", selection: file.vendorId) {
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

    private func expenseSection(_ file: Binding<FileUploadMetadata>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Link to Expense (Optional)")
                .font(.headline)

            if isLoadingEntities {
                ProgressView()
                    .scaleEffect(0.7)
            } else if availableExpenses.isEmpty {
                Text("No expenses available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Picker("Expense", selection: file.expenseId) {
                    Text("None").tag(UUID?.none)

                    ForEach(availableExpenses, id: \.id) { expense in
                        Text(expense.description).tag(UUID?.some(expense.id))
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: file.wrappedValue.expenseId) { _ in
                    Task {
                        await loadPaymentsForCurrentFile()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Payment Section

    private func paymentSection(_ file: Binding<FileUploadMetadata>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Payments")
                .font(.headline)

            if file.wrappedValue.expenseId == nil {
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
                        .padding(.vertical, 4)

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

    // MARK: - Tags Section

    private func tagsSection(_ file: Binding<FileUploadMetadata>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)

            DocumentTagInputView(tags: file.tags)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor)))
    }

    // MARK: - Helper Methods

    private var isCurrentFileValid: Bool {
        guard let file = currentFile?.wrappedValue else { return false }
        return !file.fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func handleNextOrUpload() {
        if currentFileIndex < selectedFiles.count - 1 {
            // Move to next file
            currentFileIndex += 1
        } else {
            // Upload all files
            Task {
                await uploadFiles()
            }
        }
    }

    private func uploadFiles() async {
        isUploading = true

        for file in selectedFiles {
            await onUpload(file)
        }

        isUploading = false
        dismiss()
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            selectedFiles = urls.map { url in
                FileUploadMetadata(localURL: url, fileName: url.lastPathComponent)
            }
            currentFileIndex = 0
        case .failure(let error):
            logger.error("File selection error", error: error)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []

        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url {
                    urls.append(url)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            selectedFiles = urls.map { url in
                FileUploadMetadata(localURL: url, fileName: url.lastPathComponent)
            }
            currentFileIndex = 0
        }

        return true
    }

    private func loadEntities() async {
        isLoadingEntities = true

        do {
            let api = DocumentsAPI()
            async let vendorsTask = api.fetchVendors()
            async let expensesTask = api.fetchExpenses()

            (availableVendors, availableExpenses) = try await (vendorsTask, expensesTask)

            // Load payments filtered by selected expense (if any)
            await loadPaymentsForCurrentFile()
        } catch {
            logger.error("Failed to load entities", error: error)
        }

        isLoadingEntities = false
    }

    private func loadPaymentsForCurrentFile() async {
        guard let file = currentFile?.wrappedValue else { return }

        do {
            let api = DocumentsAPI()
            availablePayments = try await api.fetchPayments(forExpenseId: file.expenseId)
        } catch {
            logger.error("Failed to load payments", error: error)
        }
    }
}

// MARK: - Document Tag Input View

struct DocumentTagInputView: View {
    @Binding var tags: [String]
    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tag input
            HStack {
                TextField("Add tag...", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addTag()
                    }

                Button("Add") {
                    addTag()
                }
                .buttonStyle(.borderless)
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            // Existing tags
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.caption)

                                Button(action: {
                                    tags.removeAll { $0 == tag }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.1)))
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, !tags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
        }
    }
}

// MARK: - Preview

#Preview {
    DocumentUploadModal(
        onUpload: { _ in },
        onCancel: {})
}
