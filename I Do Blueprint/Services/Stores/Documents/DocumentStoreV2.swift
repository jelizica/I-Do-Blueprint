//
//  DocumentStoreV2.swift
//  I Do Blueprint
//
//  Document management store using repository pattern and composition
//  Refactored to use sub-stores following BudgetStoreV2 pattern
//

import Combine
import Dependencies
import Foundation
import SwiftUI

/// Document store using composition pattern with sub-stores
/// Following the BudgetStoreV2 architecture pattern
@MainActor
class DocumentStoreV2: ObservableObject, CacheableStore {
    // MARK: - Sub-Stores (Composition)
    
    /// Upload operations sub-store
    let upload: DocumentUploadStore
    
    /// Filter and search sub-store
    let filter: DocumentFilterStore
    
    /// Batch operations sub-store
    let batch: DocumentBatchStore
    
    // MARK: - Core State
    
    @Published var loadingState: LoadingState<[Document]> = .idle
    @Published var selectedDocument: Document?
    @Published var isRefreshing = false
    
    // Available vendors and expenses for filters
    @Published var availableVendors: [(id: Int, name: String)] = []
    @Published var availableExpenses: [(id: UUID, description: String)] = []
    
    // MARK: - Dependencies
    
    @Dependency(\.documentRepository) var repository
    @Dependency(\.vendorRepository) var vendorRepository
    @Dependency(\.budgetRepository) var budgetRepository
    
    // MARK: - Cache Management
    
    var lastLoadTime: Date?
    let cacheValidityDuration: TimeInterval = 600 // 10 minutes
    
    // Task tracking for cancellation handling
    private var loadTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        self.upload = DocumentUploadStore()
        self.filter = DocumentFilterStore()
        self.batch = DocumentBatchStore()
        
        setupSubStoreBindings()
    }
    
    /// Setup bindings to propagate sub-store changes
    private func setupSubStoreBindings() {
        // Forward upload store changes
        upload.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Forward filter store changes
        filter.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Forward batch store changes
        batch.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties (Backward Compatibility)
    
    var documents: [Document] {
        loadingState.data ?? []
    }
    
    var isLoading: Bool {
        loadingState.isLoading
    }
    
    var error: DocumentError? {
        if case .error(let err) = loadingState {
            return err as? DocumentError ?? .fetchFailed(underlying: err)
        }
        return nil
    }
    
    /// Filtered and sorted documents using filter sub-store
    var filteredDocuments: [Document] {
        filter.applyFilters(to: documents)
    }
    
    var typeCounts: [DocumentType: Int] {
        var counts: [DocumentType: Int] = [:]
        for document in documents {
            counts[document.documentType, default: 0] += 1
        }
        return counts
    }
    
    var documentStats: DocumentStats {
        let total = documents.count
        let images = documents.filter(\.isImage).count
        let pdfs = documents.filter(\.isPDF).count
        let contracts = documents.filter { $0.documentType == .contract }.count
        let invoices = documents.filter { $0.documentType == .invoice }.count
        let totalSize = documents.reduce(0) { $0 + $1.fileSize }
        
        return DocumentStats(
            total: total,
            images: images,
            pdfs: pdfs,
            contracts: contracts,
            invoices: invoices,
            totalSize: totalSize
        )
    }
    
    // MARK: - Backward Compatibility Proxies
    
    // Upload proxies
    var isUploading: Bool { upload.isUploading }
    var uploadProgress: Double { upload.uploadProgress }
    
    // Filter proxies
    var filters: DocumentFilters {
        get { filter.filters }
        set { filter.filters = newValue }
    }
    var sortOption: DocumentSortOption {
        get { filter.sortOption }
        set { filter.sortOption = newValue }
    }
    var viewMode: DocumentViewMode {
        get { filter.viewMode }
        set { filter.viewMode = newValue }
    }
    var searchQuery: String {
        get { filter.searchQuery }
        set { filter.searchQuery = newValue }
    }
    var searchText: String {
        get { filter.searchQuery }
        set { filter.searchQuery = newValue }
    }
    var hasActiveFilters: Bool { filter.hasActiveFilters }
    
    // Batch proxies
    var selectedDocumentIds: Set<UUID> {
        get { batch.selectedDocumentIds }
        set { batch.selectedDocumentIds = newValue }
    }
    var isSelectionMode: Bool {
        get { batch.isSelectionMode }
        set { batch.isSelectionMode = newValue }
    }
    var isSelectingAll: Bool {
        batch.isSelectingAll(from: filteredDocuments)
    }
    
    // MARK: - Load Operations
    
    func loadDocuments(force: Bool = false) async {
        // Cancel any previous load task
        loadTask?.cancel()
        
        // Create new load task
        loadTask = Task { @MainActor in
            // Use cached data if still valid
            if !force && isCacheValid() {
                AppLogger.ui.debug("Using cached document data (age: \(Int(cacheAge()))s)")
                return
            }
            
            guard loadingState.isIdle || loadingState.hasError || force else { return }
            
            loadingState = .loading
            
            do {
                try Task.checkCancellation()
                
                let fetchedDocuments = try await repository.fetchDocuments()
                
                try Task.checkCancellation()
                
                loadingState = .loaded(fetchedDocuments)
                lastLoadTime = Date()
            } catch is CancellationError {
                AppLogger.ui.debug("DocumentStoreV2.loadDocuments: Load cancelled (expected during tenant switch)")
                loadingState = .idle
            } catch let error as URLError where error.code == .cancelled {
                AppLogger.ui.debug("DocumentStoreV2.loadDocuments: Load cancelled (URLError)")
                loadingState = .idle
            } catch {
                loadingState = .error(DocumentError.fetchFailed(underlying: error))
                ErrorHandler.shared.handle(
                    error,
                    context: ErrorContext(operation: "loadDocuments", feature: "document")
                )
            }
        }
        
        await loadTask?.value
    }
    
    func loadDocuments(type: DocumentType) async {
        loadingState = .loading
        
        do {
            let fetchedDocuments = try await repository.fetchDocuments(type: type)
            loadingState = .loaded(fetchedDocuments)
        } catch {
            loadingState = .error(DocumentError.fetchFailed(underlying: error))
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(operation: "loadDocumentsByType", feature: "document", metadata: ["type": type.rawValue])
            )
        }
    }
    
    func loadDocuments(bucket: DocumentBucket) async {
        loadingState = .loading
        
        do {
            let fetchedDocuments = try await repository.fetchDocuments(bucket: bucket)
            loadingState = .loaded(fetchedDocuments)
        } catch {
            loadingState = .error(DocumentError.fetchFailed(underlying: error))
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(operation: "loadDocumentsByBucket", feature: "document", metadata: ["bucket": bucket.rawValue])
            )
        }
    }
    
    func loadDocuments(vendorId: Int) async {
        loadingState = .loading
        
        do {
            let fetchedDocuments = try await repository.fetchDocuments(vendorId: vendorId)
            loadingState = .loaded(fetchedDocuments)
        } catch {
            loadingState = .error(DocumentError.fetchFailed(underlying: error))
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(operation: "loadDocumentsByVendor", feature: "document", metadata: ["vendorId": vendorId])
            )
        }
    }
    
    func refreshDocuments() async {
        await loadDocuments(force: true)
    }
    
    func load() async {
        await loadDocuments()
    }
    
    func refresh() async {
        isRefreshing = true
        await loadDocuments(force: true)
        isRefreshing = false
    }
    
    func retryLoad() async {
        await loadDocuments()
    }
    
    // MARK: - Upload Operations (Delegated to Sub-Store)
    
    func uploadDocument(
        fileData: Data,
        metadata: FileUploadMetadata,
        coupleId: UUID
    ) async {
        do {
            let document = try await upload.uploadDocument(
                fileData: fileData,
                metadata: metadata,
                coupleId: coupleId
            )
            
            // Add to local state
            if case .loaded(var currentDocuments) = loadingState {
                currentDocuments.insert(document, at: 0)
                loadingState = .loaded(currentDocuments)
            }
            
            invalidateCache()
            showSuccess("Document uploaded successfully")
        } catch {
            loadingState = .error(DocumentError.uploadFailed(underlying: error))
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(
                    operation: "uploadDocument",
                    feature: "document",
                    metadata: ["fileName": metadata.fileName]
                )
            )
        }
    }
    
    func uploadFile(
        metadata: FileUploadMetadata,
        coupleId: UUID,
        uploadedBy: String
    ) async throws -> Document {
        let document = try await upload.uploadFile(
            metadata: metadata,
            coupleId: coupleId,
            uploadedBy: uploadedBy
        )
        
        // Add to local state
        if case .loaded(var currentDocuments) = loadingState {
            currentDocuments.insert(document, at: 0)
            loadingState = .loaded(currentDocuments)
        }
        
        return document
    }
    
    // MARK: - Update Operations
    
    func updateDocument(_ document: Document) async {
        // Optimistic update
        guard case .loaded(var currentDocuments) = loadingState,
              let index = currentDocuments.firstIndex(where: { $0.id == document.id }) else {
            return
        }
        
        let original = currentDocuments[index]
        currentDocuments[index] = document
        loadingState = .loaded(currentDocuments)
        
        do {
            let updated = try await repository.updateDocument(document)
            
            if case .loaded(var docs) = loadingState,
               let idx = docs.firstIndex(where: { $0.id == document.id }) {
                docs[idx] = updated
                loadingState = .loaded(docs)
            }
            
            invalidateCache()
            showSuccess("Document updated successfully")
        } catch {
            // Rollback on error
            if case .loaded(var docs) = loadingState,
               let idx = docs.firstIndex(where: { $0.id == document.id }) {
                docs[idx] = original
                loadingState = .loaded(docs)
            }
            loadingState = .error(DocumentError.updateFailed(underlying: error))
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(operation: "updateDocument", feature: "document", metadata: ["documentId": document.id.uuidString])
            )
        }
    }
    
    func updateDocument(
        _ id: UUID,
        fileName: String,
        documentType: DocumentType,
        vendorId: Int?,
        expenseId: UUID?,
        tags: [String]
    ) async {
        guard case .loaded(var currentDocuments) = loadingState,
              let index = currentDocuments.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let original = currentDocuments[index]
        
        var updated = original
        updated.originalFilename = fileName
        updated.documentType = documentType
        updated.vendorId = vendorId
        updated.expenseId = expenseId
        updated.tags = tags
        updated.updatedAt = Date()
        
        currentDocuments[index] = updated
        loadingState = .loaded(currentDocuments)
        
        do {
            let result = try await repository.updateDocument(updated)
            
            if case .loaded(var docs) = loadingState,
               let idx = docs.firstIndex(where: { $0.id == id }) {
                docs[idx] = result
                loadingState = .loaded(docs)
            }
        } catch {
            if case .loaded(var docs) = loadingState,
               let idx = docs.firstIndex(where: { $0.id == id }) {
                docs[idx] = original
                loadingState = .loaded(docs)
            }
            loadingState = .error(DocumentError.updateFailed(underlying: error))
            ErrorHandler.shared.handle(
                error,
                context: ErrorContext(operation: "updateDocumentFields", feature: "document", metadata: ["documentId": id.uuidString])
            )
        }
    }
    
    func updateDocumentTags(id: UUID, tags: [String]) async {
        guard case .loaded(var currentDocuments) = loadingState,
              let index = currentDocuments.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let original = currentDocuments[index]
        var updated = original
        updated.tags = tags
        updated.updatedAt = Date()
        currentDocuments[index] = updated
        loadingState = .loaded(currentDocuments)
        
        do {
            let result = try await repository.updateDocumentTags(id: id, tags: tags)
            
            if case .loaded(var docs) = loadingState,
               let idx = docs.firstIndex(where: { $0.id == id }) {
                docs[idx] = result
                loadingState = .loaded(docs)
            }
        } catch {
            if case .loaded(var docs) = loadingState,
               let idx = docs.firstIndex(where: { $0.id == id }) {
                docs[idx] = original
                loadingState = .loaded(docs)
            }
            loadingState = .error(DocumentError.updateFailed(underlying: error))
        }
    }
    
    func updateDocumentType(id: UUID, type: DocumentType) async {
        guard case .loaded(var currentDocuments) = loadingState,
              let index = currentDocuments.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let original = currentDocuments[index]
        var updated = original
        updated.documentType = type
        updated.updatedAt = Date()
        currentDocuments[index] = updated
        loadingState = .loaded(currentDocuments)
        
        do {
            let result = try await repository.updateDocumentType(id: id, type: type)
            
            if case .loaded(var docs) = loadingState,
               let idx = docs.firstIndex(where: { $0.id == id }) {
                docs[idx] = result
                loadingState = .loaded(docs)
            }
        } catch {
            if case .loaded(var docs) = loadingState,
               let idx = docs.firstIndex(where: { $0.id == id }) {
                docs[idx] = original
                loadingState = .loaded(docs)
            }
            loadingState = .error(DocumentError.updateFailed(underlying: error))
        }
    }
    
    // MARK: - Delete Operations
    
    func deleteDocument(_ document: Document) async {
        guard case .loaded(var currentDocuments) = loadingState,
              let index = currentDocuments.firstIndex(where: { $0.id == document.id }) else {
            return
        }
        
        let removed = currentDocuments.remove(at: index)
        loadingState = .loaded(currentDocuments)
        
        do {
            try await repository.deleteDocument(id: document.id)
            invalidateCache()
            showSuccess("Document deleted successfully")
        } catch {
            if case .loaded(var docs) = loadingState {
                docs.insert(removed, at: index)
                loadingState = .loaded(docs)
            }
            loadingState = .error(DocumentError.deleteFailed(underlying: error))
            await handleError(error, operation: "delete document") { [weak self] in
                await self?.deleteDocument(document)
            }
        }
    }
    
    func deleteDocument(_ id: UUID) async {
        guard let document = documents.first(where: { $0.id == id }) else { return }
        await deleteDocument(document)
    }
    
    // MARK: - Batch Operations (Delegated to Sub-Store)
    
    func toggleSelection(_ id: UUID) {
        batch.toggleSelection(id)
    }
    
    func selectAll() {
        batch.selectAll(from: filteredDocuments)
    }
    
    func deselectAll() {
        batch.deselectAll()
    }
    
    func batchDelete() async {
        guard case .loaded(var currentDocuments) = loadingState else { return }
        
        let originalDocuments = currentDocuments
        let idsToDelete = Array(batch.selectedDocumentIds)
        currentDocuments.removeAll { idsToDelete.contains($0.id) }
        loadingState = .loaded(currentDocuments)
        
        do {
            _ = try await batch.batchDelete()
        } catch {
            loadingState = .loaded(originalDocuments)
            loadingState = .error(DocumentError.deleteFailed(underlying: error))
        }
    }
    
    func batchDeleteDocuments(ids: [UUID]) async {
        guard case .loaded(var currentDocuments) = loadingState else { return }
        
        let originalDocuments = currentDocuments
        currentDocuments.removeAll { ids.contains($0.id) }
        loadingState = .loaded(currentDocuments)
        
        do {
            try await repository.batchDeleteDocuments(ids: ids)
        } catch {
            loadingState = .loaded(originalDocuments)
            loadingState = .error(DocumentError.deleteFailed(underlying: error))
        }
    }
    
    func batchUpdateType(_ type: DocumentType) async {
        guard case .loaded(var currentDocuments) = loadingState else { return }
        
        let originalDocuments = currentDocuments
        let idsToUpdate = Array(batch.selectedDocumentIds)
        
        // Optimistic update
        for id in idsToUpdate {
            if let index = currentDocuments.firstIndex(where: { $0.id == id }) {
                currentDocuments[index].documentType = type
                currentDocuments[index].updatedAt = Date()
            }
        }
        loadingState = .loaded(currentDocuments)
        
        do {
            _ = try await batch.batchUpdateType(type)
        } catch {
            loadingState = .loaded(originalDocuments)
            loadingState = .error(DocumentError.updateFailed(underlying: error))
        }
    }
    
    func batchDownload() async {
        await batch.batchDownload(documents: documents)
    }
    
    // MARK: - Search Operations
    
    func searchDocuments(query: String) async {
        loadingState = .loading
        
        do {
            let fetchedDocuments = try await repository.searchDocuments(query: query)
            loadingState = .loaded(fetchedDocuments)
        } catch {
            loadingState = .error(DocumentError.fetchFailed(underlying: error))
        }
    }
    
    // MARK: - Download Operations
    
    func downloadDocument(_ document: Document) async -> Data? {
        do {
            return try await repository.downloadDocument(document: document)
        } catch {
            loadingState = .error(DocumentError.downloadFailed(underlying: error))
            return nil
        }
    }
    
    func getPublicURL(for document: Document) async -> URL? {
        do {
            return try await repository.getPublicURL(for: document)
        } catch {
            loadingState = .error(DocumentError.fetchFailed(underlying: error))
            return nil
        }
    }
    
    // MARK: - Filter Operations (Delegated to Sub-Store)
    
    func clearFilters() {
        filter.clearFilters()
    }
    
    func setTypeFilter(_ type: DocumentType?) {
        filter.setTypeFilter(type)
    }
    
    func clearSearch() {
        filter.clearSearch()
    }
    
    func applyFilters() {
        // No-op: filteredDocuments is computed property
    }
    
    // MARK: - Load Related Data
    
    func loadVendorsAndExpenses() async {
        do {
            async let vendorsTask = vendorRepository.fetchVendors()
            async let expensesTask = budgetRepository.fetchExpenses()
            
            let (vendors, expenses) = try await (vendorsTask, expensesTask)
            
            availableVendors = vendors.map { (id: Int($0.id), name: $0.vendorName) }
            availableExpenses = expenses.map { (id: $0.id, description: $0.expenseName) }
        } catch {
            loadingState = .error(DocumentError.fetchFailed(underlying: error))
        }
    }
    
    // MARK: - State Management
    
    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        loadTask?.cancel()
        loadingState = .idle
        lastLoadTime = nil
        batch.reset()
        filter.clearFilters()
        upload.resetUploadState()
    }
}

// MARK: - Document Stats

struct DocumentStats {
    let total: Int
    let images: Int
    let pdfs: Int
    let contracts: Int
    let invoices: Int
    let totalSize: Int64
}
