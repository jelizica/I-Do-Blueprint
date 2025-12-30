//
//  DocumentFilterStore.swift
//  I Do Blueprint
//
//  Sub-store for document filtering and search operations
//  Extracted from DocumentStoreV2 as part of architecture improvement plan
//

import Foundation
import Combine

/// Sub-store handling document filtering, search, and sorting
@MainActor
class DocumentFilterStore: ObservableObject {
    @Published var filters = DocumentFilters(
        selectedType: nil,
        selectedBucket: nil,
        tags: [],
        dateRange: nil,
        vendorId: nil
    )
    @Published var sortOption: DocumentSortOption = .uploadedDesc
    @Published var viewMode: DocumentViewMode = .grid
    @Published var searchQuery = ""
    
    // MARK: - Computed Properties
    
    var hasActiveFilters: Bool {
        filters.hasActiveFilters || !searchQuery.isEmpty
    }
    
    // Backward compatibility alias
    var searchText: String {
        get { searchQuery }
        set { searchQuery = newValue }
    }
    
    // MARK: - Filter Operations
    
    /// Apply all filters and sorting to a document list
    func applyFilters(to documents: [Document]) -> [Document] {
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
        return sortDocuments(filtered)
    }
    
    /// Sort documents by current sort option
    func sortDocuments(_ documents: [Document]) -> [Document] {
        switch sortOption {
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
    
    // MARK: - Filter Setters
    
    func setTypeFilter(_ type: DocumentType?) {
        filters.selectedType = type
    }
    
    func setBucketFilter(_ bucket: DocumentBucket?) {
        filters.selectedBucket = bucket
    }
    
    func setVendorFilter(_ vendorId: Int?) {
        filters.vendorId = vendorId
    }
    
    func setDateRangeFilter(_ dateRange: DocumentDateRange?) {
        filters.dateRange = dateRange
    }
    
    func addTagFilter(_ tag: String) {
        if !filters.tags.contains(tag) {
            filters.tags.append(tag)
        }
    }
    
    func removeTagFilter(_ tag: String) {
        filters.tags.removeAll { $0 == tag }
    }
    
    // MARK: - Clear Operations
    
    func clearFilters() {
        filters = DocumentFilters(
            selectedType: nil,
            selectedBucket: nil,
            tags: [],
            dateRange: nil,
            vendorId: nil
        )
        searchQuery = ""
    }
    
    func clearSearch() {
        searchQuery = ""
    }
}
