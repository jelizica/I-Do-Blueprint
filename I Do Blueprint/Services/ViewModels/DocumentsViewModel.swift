//
//  DocumentsViewModel.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class DocumentsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var documents: [Document] = []
    @Published var filteredDocuments: [Document] = []
    @Published var searchText: String = ""
    @Published var filters: DocumentFilters = .init(
        selectedType: nil,
        selectedBucket: nil,
        tags: [],
        dateRange: nil,
        vendorId: nil)
    @Published var sortOption: DocumentSortOption = .uploadedDesc
    @Published var viewMode: DocumentViewMode = .grid

    // Batch selection
    @Published var selectedDocumentIds: Set<UUID> = []
    @Published var isSelectionMode: Bool = false

    // Loading states
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var error: String?

    // Type counts for filter tabs
    @Published var typeCounts: [DocumentType: Int] = [:]

    // Available vendors and expenses for filters
    @Published var availableVendors: [(id: Int, name: String)] = []
    @Published var availableExpenses: [(id: UUID, description: String)] = []

    // Search history
    @Published var searchHistory: [SearchHistoryItem] = []
    private let maxSearchHistory = 10

    // MARK: - Private Properties

    private let api: DocumentsAPI
    private var allDocuments: [Document] = []
    private var cancellables = Set<AnyCancellable>()
    private var searchDebounce: AnyCancellable?
    private let logger = AppLogger.general

    // MARK: - Initialization

    init(api: DocumentsAPI = DocumentsAPI()) {
        self.api = api

        // Setup search debouncing
        setupSearchDebouncing()

        // Load search history from UserDefaults
        loadSearchHistory()
    }

    // MARK: - Data Loading

    func load() async {
        isLoading = true
        error = nil

        do {
            // Fetch all documents
            logger.debug("Fetching documents...")
            allDocuments = try await api.fetchDocuments()
            logger.info("Fetched \(allDocuments.count) documents")
            documents = allDocuments

            // Load vendors and expenses for filters
            async let vendorsTask = api.fetchVendors()
            async let expensesTask = api.fetchExpenses()

            (availableVendors, availableExpenses) = try await (vendorsTask, expensesTask)
            logger.debug("Loaded \(availableVendors.count) vendors and \(availableExpenses.count) expenses")

            // Calculate type counts
            calculateTypeCounts()

            // Apply initial filters
            applyFilters()
            logger.debug("After filters: \(filteredDocuments.count) documents")

            isLoading = false
        } catch {
            logger.error("Document load error", error: error)
            self.error = "Failed to load documents: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func refresh() async {
        isRefreshing = true
        await load()
        isRefreshing = false
    }

    // MARK: - Filtering

    func applyFilters() {
        var filtered = allDocuments

        // Filter by type
        if let selectedType = filters.selectedType {
            filtered = filtered.filter { $0.documentType == selectedType }
        }

        // Filter by bucket
        if let selectedBucket = filters.selectedBucket {
            filtered = filtered.filter { $0.bucketName == selectedBucket.rawValue }
        }

        // Filter by tags
        if !filters.tags.isEmpty {
            filtered = filtered.filter { document in
                filters.tags.allSatisfy { tag in
                    document.tags.contains(tag)
                }
            }
        }

        // Filter by date range
        if let dateRange = filters.dateRange {
            let interval = dateRange.dateInterval
            filtered = filtered.filter { document in
                interval.contains(document.uploadedAt)
            }
        }

        // Filter by vendor
        if let vendorId = filters.vendorId {
            filtered = filtered.filter { $0.vendorId == vendorId }
        }

        // Apply search
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter { document in
                document.originalFilename.lowercased().contains(query) ||
                    document.tags.contains(where: { $0.lowercased().contains(query) })
            }
        }

        // Apply sorting
        filtered = sortDocuments(filtered)

        filteredDocuments = filtered
    }

    func clearFilters() {
        filters.clear()
        searchText = ""
        applyFilters()
    }

    func setTypeFilter(_ type: DocumentType?) {
        filters.selectedType = type
        applyFilters()
    }

    func setBucketFilter(_ bucket: DocumentBucket?) {
        filters.selectedBucket = bucket
        applyFilters()
    }

    func addTagFilter(_ tag: String) {
        if !filters.tags.contains(tag) {
            filters.tags.append(tag)
            applyFilters()
        }
    }

    func removeTagFilter(_ tag: String) {
        filters.tags.removeAll { $0 == tag }
        applyFilters()
    }

    func setDateRangeFilter(_ dateRange: DocumentDateRange?) {
        filters.dateRange = dateRange
        applyFilters()
    }

    func setVendorFilter(_ vendorId: Int?) {
        filters.vendorId = vendorId
        applyFilters()
    }

    // MARK: - Sorting

    func sortDocuments(_ documents: [Document]) -> [Document] {
        switch sortOption {
        case .uploadedDesc:
            documents.sorted { $0.uploadedAt > $1.uploadedAt }
        case .uploadedAsc:
            documents.sorted { $0.uploadedAt < $1.uploadedAt }
        case .nameAsc:
            documents.sorted { $0.originalFilename.lowercased() < $1.originalFilename.lowercased() }
        case .nameDesc:
            documents.sorted { $0.originalFilename.lowercased() > $1.originalFilename.lowercased() }
        case .sizeDesc:
            documents.sorted { $0.fileSize > $1.fileSize }
        case .sizeAsc:
            documents.sorted { $0.fileSize < $1.fileSize }
        case .typeAsc:
            documents.sorted { $0.documentType.displayName < $1.documentType.displayName }
        }
    }

    func setSortOption(_ option: DocumentSortOption) {
        sortOption = option
        applyFilters()
    }

    // MARK: - Search

    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }

    func performSearch(_ query: String) {
        searchText = query

        // Add to search history if not empty
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addToSearchHistory(query)
        }
    }

    func clearSearch() {
        searchText = ""
        applyFilters()
    }

    // MARK: - Search History

    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: "DocumentSearchHistory"),
           let history = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) {
            searchHistory = history
        }
    }

    private func saveSearchHistory() {
        if let data = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(data, forKey: "DocumentSearchHistory")
        }
    }

    func addToSearchHistory(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Don't add if it's already the most recent
        if let mostRecent = searchHistory.first, mostRecent.query == trimmedQuery {
            return
        }

        // Remove any existing entry with same query
        searchHistory.removeAll { $0.query == trimmedQuery }

        // Add to front
        searchHistory.insert(SearchHistoryItem(query: trimmedQuery), at: 0)

        // Limit to max history
        if searchHistory.count > maxSearchHistory {
            searchHistory = Array(searchHistory.prefix(maxSearchHistory))
        }

        saveSearchHistory()
    }

    func clearSearchHistory() {
        searchHistory.removeAll()
        saveSearchHistory()
    }

    // MARK: - Type Counts

    private func calculateTypeCounts() {
        typeCounts = [:]
        for type in DocumentType.allCases {
            typeCounts[type] = allDocuments.filter { $0.documentType == type }.count
        }
    }

    // MARK: - Document Operations

    func createDocument(
        metadata: FileUploadMetadata,
        storagePath: String,
        coupleId: UUID,
        uploadedBy: String) async throws -> Document {
        let insertData = DocumentInsertData(
            coupleId: coupleId,
            originalFilename: metadata.fileName,
            storagePath: storagePath,
            fileSize: metadata.fileSize,
            mimeType: metadata.mimeType,
            documentType: metadata.documentType,
            bucketName: metadata.bucket.rawValue,
            vendorId: metadata.vendorId,
            expenseId: metadata.expenseId,
            tags: metadata.tags,
            uploadedBy: uploadedBy)

        let document = try await api.createDocument(insertData)

        // Refresh documents
        await refresh()

        return document
    }

    func updateDocument(
        _ id: UUID,
        fileName: String,
        documentType: DocumentType,
        vendorId: Int?,
        expenseId: UUID?,
        tags: [String]) async {
        do {
            _ = try await api.updateDocument(
                id,
                fileName: fileName,
                documentType: documentType,
                vendorId: vendorId,
                expenseId: expenseId,
                tags: tags)

            // Refresh documents
            await refresh()
        } catch {
            logger.error("Failed to update document", error: error)
            self.error = "Failed to update document: \(error.localizedDescription)"
        }
    }

    func deleteDocument(_ id: UUID) async {
        do {
            guard let document = allDocuments.first(where: { $0.id == id }) else {
                return
            }

            try await api.deleteDocumentWithFile(document)

            // Refresh documents
            await refresh()
        } catch {
            self.error = "Failed to delete document: \(error.localizedDescription)"
        }
    }

    // MARK: - Batch Operations

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
        guard !selectedDocumentIds.isEmpty else { return }

        do {
            try await api.batchDeleteDocuments(Array(selectedDocumentIds))

            // Clear selection and refresh
            selectedDocumentIds.removeAll()
            isSelectionMode = false
            await refresh()
        } catch {
            self.error = "Failed to delete documents: \(error.localizedDescription)"
        }
    }

    func batchAddTags(_ tags: [String]) async {
        guard !selectedDocumentIds.isEmpty else { return }

        do {
            try await api.batchUpdateTags(Array(selectedDocumentIds), addTags: tags)

            // Clear selection and refresh
            selectedDocumentIds.removeAll()
            isSelectionMode = false
            await refresh()
        } catch {
            self.error = "Failed to add tags: \(error.localizedDescription)"
        }
    }

    func batchRemoveTags(_ tags: [String]) async {
        guard !selectedDocumentIds.isEmpty else { return }

        do {
            try await api.batchUpdateTags(Array(selectedDocumentIds), removeTags: tags)

            // Clear selection and refresh
            selectedDocumentIds.removeAll()
            isSelectionMode = false
            await refresh()
        } catch {
            self.error = "Failed to remove tags: \(error.localizedDescription)"
        }
    }

    func batchChangeType(_ type: DocumentType) async {
        guard !selectedDocumentIds.isEmpty else { return }

        do {
            try await api.batchUpdateType(Array(selectedDocumentIds), type: type)

            // Clear selection and refresh
            selectedDocumentIds.removeAll()
            isSelectionMode = false
            await refresh()
        } catch {
            self.error = "Failed to change document types: \(error.localizedDescription)"
        }
    }

    // MARK: - File Operations

    func uploadFile(metadata: FileUploadMetadata, coupleId: UUID, uploadedBy: String) async throws -> Document {
        // Upload file to storage
        let filePath = try await api.uploadFile(
            localURL: metadata.localURL,
            bucketName: metadata.bucket.rawValue,
            fileName: metadata.fileName)

        // Create document record
        return try await createDocument(
            metadata: metadata,
            storagePath: filePath,
            coupleId: coupleId,
            uploadedBy: uploadedBy)
    }

    func getPublicURL(for document: Document) throws -> URL {
        try api.getPublicURL(bucketName: document.bucketName, path: document.storagePath)
    }

    func downloadFile(for document: Document) async throws -> Data {
        try await api.downloadFile(bucketName: document.bucketName, path: document.storagePath)
    }

    // MARK: - Helper Methods

    func getVendorName(for vendorId: Int) -> String? {
        availableVendors.first(where: { $0.id == vendorId })?.name
    }

    func getExpenseDescription(for expenseId: UUID) -> String? {
        availableExpenses.first(where: { $0.id == expenseId })?.description
    }

    var hasActiveFilters: Bool {
        filters.hasActiveFilters || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isSelectingAll: Bool {
        !filteredDocuments.isEmpty && selectedDocumentIds.count == filteredDocuments.count
    }
}
