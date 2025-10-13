//
//  DocumentStoreV2.swift
//  My Wedding Planning App
//
//  New architecture version of document management using repository pattern
//

import Combine
import Dependencies
import Foundation
import SwiftUI

/// New architecture version using repositories and dependency injection
@MainActor
class DocumentStoreV2: ObservableObject {
    @Published private(set) var documents: [Document] = []
    @Published var selectedDocument: Document?

    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: DocumentError?
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0

    // Filters and view state
    @Published var filters = DocumentFilters(
        selectedType: nil,
        selectedBucket: nil,
        tags: [],
        dateRange: nil,
        vendorId: nil)
    @Published var sortOption: DocumentSortOption = .uploadedDesc
    @Published var viewMode: DocumentViewMode = .grid
    @Published var searchQuery = ""

    // Batch selection
    @Published var selectedDocumentIds: Set<UUID> = []
    @Published var isSelectionMode: Bool = false

    // Available vendors and expenses for filters
    @Published var availableVendors: [(id: Int, name: String)] = []
    @Published var availableExpenses: [(id: UUID, description: String)] = []

    @Dependency(\.documentRepository) var repository
    @Dependency(\.vendorRepository) var vendorRepository
    @Dependency(\.budgetRepository) var budgetRepository

    // MARK: - Computed Properties

    var searchText: String {
        get { searchQuery }
        set { searchQuery = newValue }
    }

    var typeCounts: [DocumentType: Int] {
        var counts: [DocumentType: Int] = [:]
        for document in documents {
            counts[document.documentType, default: 0] += 1
        }
        return counts
    }

    var hasActiveFilters: Bool {
        filters.hasActiveFilters || !searchQuery.isEmpty
    }

    var isSelectingAll: Bool {
        !documents.isEmpty && selectedDocumentIds.count == filteredDocuments.count
    }

    // MARK: - Public Interface

    func loadDocuments() async {
        isLoading = true
        error = nil

        do {
            documents = try await repository.fetchDocuments()
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func loadDocuments(type: DocumentType) async {
        isLoading = true
        error = nil

        do {
            documents = try await repository.fetchDocuments(type: type)
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func loadDocuments(bucket: DocumentBucket) async {
        isLoading = true
        error = nil

        do {
            documents = try await repository.fetchDocuments(bucket: bucket)
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func loadDocuments(vendorId: Int) async {
        isLoading = true
        error = nil

        do {
            documents = try await repository.fetchDocuments(vendorId: vendorId)
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func refreshDocuments() async {
        await loadDocuments()
    }

    func uploadDocument(
        fileData: Data,
        metadata: FileUploadMetadata,
        coupleId: UUID) async {
        isUploading = true
        uploadProgress = 0
        error = nil

        do {
            let document = try await repository.uploadDocument(
                fileData: fileData,
                metadata: metadata,
                coupleId: coupleId)
            documents.insert(document, at: 0)
            uploadProgress = 1.0
        } catch {
            self.error = .uploadFailed(underlying: error)
        }

        isUploading = false
    }

    func updateDocument(_ document: Document) async {
        // Optimistic update
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            let original = documents[index]
            documents[index] = document

            do {
                let updated = try await repository.updateDocument(document)
                documents[index] = updated
            } catch {
                // Rollback on error
                documents[index] = original
                self.error = .updateFailed(underlying: error)
            }
        }
    }

    func updateDocument(
        _ id: UUID,
        fileName: String,
        documentType: DocumentType,
        vendorId: Int?,
        expenseId: UUID?,
        tags: [String]) async {
        // Find the document
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let original = documents[index]

        // Create updated document
        var updated = original
        updated.originalFilename = fileName
        updated.documentType = documentType
        updated.vendorId = vendorId
        updated.expenseId = expenseId
        updated.tags = tags
        updated.updatedAt = Date()

        // Optimistic update
        documents[index] = updated

        do {
            let result = try await repository.updateDocument(updated)
            documents[index] = result
        } catch {
            // Rollback on error
            documents[index] = original
            self.error = .updateFailed(underlying: error)
        }
    }

    func updateDocumentTags(id: UUID, tags: [String]) async {
        // Optimistic update
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let original = documents[index]
        var updated = original
        updated.tags = tags
        updated.updatedAt = Date()
        documents[index] = updated

        do {
            let result = try await repository.updateDocumentTags(id: id, tags: tags)
            documents[index] = result
        } catch {
            // Rollback on error
            documents[index] = original
            self.error = .updateFailed(underlying: error)
        }
    }

    func updateDocumentType(id: UUID, type: DocumentType) async {
        // Optimistic update
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let original = documents[index]
        var updated = original
        updated.documentType = type
        updated.updatedAt = Date()
        documents[index] = updated

        do {
            let result = try await repository.updateDocumentType(id: id, type: type)
            documents[index] = result
        } catch {
            // Rollback on error
            documents[index] = original
            self.error = .updateFailed(underlying: error)
        }
    }

    func deleteDocument(_ document: Document) async {
        // Optimistic delete
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        let removed = documents.remove(at: index)

        do {
            try await repository.deleteDocument(id: document.id)
        } catch {
            // Rollback on error
            documents.insert(removed, at: index)
            self.error = .deleteFailed(underlying: error)
        }
    }

    func batchDeleteDocuments(ids: [UUID]) async {
        // Optimistic batch delete
        let originalDocuments = documents
        documents.removeAll { ids.contains($0.id) }

        do {
            try await repository.batchDeleteDocuments(ids: ids)
        } catch {
            // Rollback on error
            documents = originalDocuments
            self.error = .deleteFailed(underlying: error)
        }
    }

    func searchDocuments(query: String) async {
        isLoading = true
        error = nil

        do {
            documents = try await repository.searchDocuments(query: query)
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func downloadDocument(_ document: Document) async -> Data? {
        do {
            return try await repository.downloadDocument(document: document)
        } catch {
            self.error = .downloadFailed(underlying: error)
            return nil
        }
    }

    func getPublicURL(for document: Document) async -> URL? {
        do {
            return try await repository.getPublicURL(for: document)
        } catch {
            self.error = .fetchFailed(underlying: error)
            return nil
        }
    }

    // MARK: - Computed Properties

    var filteredDocuments: [Document] {
        var filtered = documents

        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter {
                $0.originalFilename.localizedCaseInsensitiveContains(searchQuery) ||
                    $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchQuery) })
            }
        }

        // Apply type filter
        if let selectedType = filters.selectedType {
            filtered = filtered.filter { $0.documentType == selectedType }
        }

        // Apply bucket filter
        if let selectedBucket = filters.selectedBucket {
            filtered = filtered.filter { $0.bucketName == selectedBucket.rawValue }
        }

        // Apply tag filters
        if !filters.tags.isEmpty {
            filtered = filtered.filter { document in
                filters.tags.allSatisfy { document.tags.contains($0) }
            }
        }

        // Apply vendor filter
        if let vendorId = filters.vendorId {
            filtered = filtered.filter { $0.vendorId == vendorId }
        }

        // Apply date range filter
        if let dateRange = filters.dateRange {
            let interval = dateRange.dateInterval
            filtered = filtered.filter {
                interval.contains($0.uploadedAt)
            }
        }

        // Apply sorting
        filtered = sortedDocuments(filtered, by: sortOption)

        return filtered
    }

    private func sortedDocuments(_ documents: [Document], by option: DocumentSortOption) -> [Document] {
        switch option {
        case .uploadedDesc:
            return documents.sorted { $0.uploadedAt > $1.uploadedAt }
        case .uploadedAsc:
            return documents.sorted { $0.uploadedAt < $1.uploadedAt }
        case .nameAsc:
            return documents.sorted { $0.originalFilename < $1.originalFilename }
        case .nameDesc:
            return documents.sorted { $0.originalFilename > $1.originalFilename }
        case .sizeDesc:
            return documents.sorted { $0.fileSize > $1.fileSize }
        case .sizeAsc:
            return documents.sorted { $0.fileSize < $1.fileSize }
        case .typeAsc:
            return documents.sorted { $0.documentType.rawValue < $1.documentType.rawValue }
        }
    }

    var documentStats: (total: Int, images: Int, pdfs: Int, contracts: Int, invoices: Int, totalSize: Int64) {
        let total = documents.count
        let images = documents.filter(\.isImage).count
        let pdfs = documents.filter(\.isPDF).count
        let contracts = documents.filter { $0.documentType == .contract }.count
        let invoices = documents.filter { $0.documentType == .invoice }.count
        let totalSize = documents.reduce(0) { $0 + $1.fileSize }

        return (total, images, pdfs, contracts, invoices, totalSize)
    }

    // MARK: - Additional Methods for View Compatibility

    func load() async {
        await loadDocuments()
    }

    func refresh() async {
        isRefreshing = true
        await loadDocuments()
        isRefreshing = false
    }

    func clearFilters() {
        filters = DocumentFilters(
            selectedType: nil,
            selectedBucket: nil,
            tags: [],
            dateRange: nil,
            vendorId: nil)
        searchQuery = ""
    }

    func setTypeFilter(_ type: DocumentType?) {
        filters.selectedType = type
    }

    func clearSearch() {
        searchQuery = ""
    }

    func applyFilters() {
        // No-op: filteredDocuments is now a computed property that automatically filters
        // This method exists for API compatibility with old DocumentsViewModel
    }

    func loadVendorsAndExpenses() async {
        do {
            async let vendorsTask = vendorRepository.fetchVendors()
            async let expensesTask = budgetRepository.fetchExpenses()

            let (vendors, expenses) = try await (vendorsTask, expensesTask)

            availableVendors = vendors.map { (id: Int($0.id), name: $0.vendorName) }
            availableExpenses = expenses.map { (id: $0.id, description: $0.expenseName) }
        } catch {
            self.error = .fetchFailed(underlying: error)
        }
    }

    // MARK: - Batch Selection Methods

    func toggleSelection(_ id: UUID) {
        if selectedDocumentIds.contains(id) {
            selectedDocumentIds.remove(id)
        } else {
            selectedDocumentIds.insert(id)
        }
    }

    func selectAll() {
        selectedDocumentIds = Set(filteredDocuments.map(\.id))
    }

    func deselectAll() {
        selectedDocumentIds.removeAll()
    }

    func batchDelete() async {
        let idsToDelete = Array(selectedDocumentIds)
        await batchDeleteDocuments(ids: idsToDelete)
        selectedDocumentIds.removeAll()
    }

    func batchUpdateType(_ type: DocumentType) async {
        let idsToUpdate = Array(selectedDocumentIds)
        guard !idsToUpdate.isEmpty else { return }

        // Optimistic update
        let originalDocuments = documents
        for id in idsToUpdate {
            if let index = documents.firstIndex(where: { $0.id == id }) {
                documents[index].documentType = type
                documents[index].updatedAt = Date()
            }
        }

        do {
            // Update documents with bounded concurrency (max 5 concurrent operations)
            let maxConcurrent = 5
            var completed = 0

            try await withThrowingTaskGroup(of: Void.self) { group in
                var iterator = idsToUpdate.makeIterator()
                var activeTasks = 0

                // Start initial batch
                while activeTasks < maxConcurrent, let id = iterator.next() {
                    group.addTask {
                        _ = try await self.repository.updateDocumentType(id: id, type: type)
                    }
                    activeTasks += 1
                }

                // Process results and start new tasks
                while activeTasks > 0 {
                    try await group.next()
                    activeTasks -= 1
                    completed += 1

                    // Show progress
                    await MainActor.run {
                        AlertPresenter.shared.showSuccessToast("Updated \(completed)/\(idsToUpdate.count) documents")
                    }

                    // Start next task if available
                    if let id = iterator.next() {
                        group.addTask {
                            _ = try await self.repository.updateDocumentType(id: id, type: type)
                        }
                        activeTasks += 1
                    }
                }
            }
        } catch {
            // Rollback on error
            documents = originalDocuments
            self.error = .updateFailed(underlying: error)
        }
    }

    /// Download multiple documents to a user-selected directory
    func batchDownload() async {
        let documentsToDownload = documents.filter { selectedDocumentIds.contains($0.id) }
        guard !documentsToDownload.isEmpty else { return }

        await MainActor.run {
            // Create open panel to select download directory
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.canCreateDirectories = true
            panel.allowsMultipleSelection = false
            panel.message = "Select download location for \(documentsToDownload.count) document(s)"

            panel.begin { response in
                guard response == .OK, let destinationURL = panel.url else {
                    return
                }

                Task {
                    var successCount = 0
                    var failedCount = 0
                    let maxConcurrent = 3 // Limit concurrent downloads

                    await withTaskGroup(of: (success: Bool, filename: String).self) { group in
                        var iterator = documentsToDownload.makeIterator()
                        var activeTasks = 0

                        // Start initial batch
                        while activeTasks < maxConcurrent, let document = iterator.next() {
                            group.addTask {
                                do {
                                    try await self.downloadDocument(document, to: destinationURL)
                                    return (true, document.originalFilename)
                                } catch {
                                    await AppLogger.ui.error("Failed to download document: \(document.originalFilename)", error: error)
                                    return (false, document.originalFilename)
                                }
                            }
                            activeTasks += 1
                        }

                        // Process results and start new tasks
                        while activeTasks > 0 {
                            if let result = await group.next() {
                                activeTasks -= 1
                                if result.success {
                                    successCount += 1
                                } else {
                                    failedCount += 1
                                }

                                // Show progress
                                let total = successCount + failedCount
                                await MainActor.run {
                                    AlertPresenter.shared.showSuccessToast("Downloaded \(total)/\(documentsToDownload.count) documents")
                                }

                                // Start next download if available
                                if let document = iterator.next() {
                                    group.addTask {
                                        do {
                                            try await self.downloadDocument(document, to: destinationURL)
                                            return (true, document.originalFilename)
                                        } catch {
                                            await AppLogger.ui.error("Failed to download document: \(document.originalFilename)", error: error)
                                            return (false, document.originalFilename)
                                        }
                                    }
                                    activeTasks += 1
                                }
                            }
                        }
                    }

                    await MainActor.run {
                        if failedCount == 0 {
                            AlertPresenter.shared.showSuccessToast("Downloaded \(successCount) document(s)")
                            NSWorkspace.shared.activateFileViewerSelecting([destinationURL])
                        } else {
                            Task { @MainActor in
                                await AlertPresenter.shared.showError(
                                    message: "Download partially failed",
                                    error: NSError(
                                        domain: "DocumentStoreV2",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Downloaded \(successCount), failed \(failedCount)"]
                                    )
                                )
                            }
                        }
                        self.selectedDocumentIds.removeAll()
                    }
                }
            }
        }
    }

    /// Download a single document to a specified directory
    private func downloadDocument(_ document: Document, to directory: URL) async throws {
        // Fetch document data from repository
        let data = try await repository.downloadDocument(document: document)

        // Create destination file URL
        let destinationURL = directory.appendingPathComponent(document.originalFilename)

        // Write to disk
        try data.write(to: destinationURL)
    }

    // MARK: - Upload with Metadata

    func uploadFile(
        metadata: FileUploadMetadata,
        coupleId: UUID,
        uploadedBy: String) async throws -> Document {
        guard let fileData = try? Data(contentsOf: metadata.localURL) else {
            throw NSError(
                domain: "DocumentStoreV2",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to read file data"])
        }

        isUploading = true
        uploadProgress = 0
        error = nil

        do {
            let document = try await repository.uploadDocument(
                fileData: fileData,
                metadata: metadata,
                coupleId: coupleId)
            documents.insert(document, at: 0)
            uploadProgress = 1.0
            isUploading = false
            return document
        } catch {
            isUploading = false
            self.error = .uploadFailed(underlying: error)
            throw error
        }
    }

    func deleteDocument(_ id: UUID) async {
        guard let document = documents.first(where: { $0.id == id }) else { return }
        await deleteDocument(document)
    }
}
