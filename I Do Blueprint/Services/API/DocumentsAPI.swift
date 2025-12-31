//
//  DocumentsAPI.swift
//  I Do Blueprint
//
//  Coordinator for document operations
//

import Foundation
import Supabase

/// Coordinator for document operations
/// Delegates to specialized services for CRUD, storage, search, batch, and related entities
class DocumentsAPI {
    private let supabase: SupabaseClient?
    
    private let crudService: DocumentCRUDService
    private let storageService: DocumentStorageService
    private let searchService: DocumentSearchService
    private let batchService: DocumentBatchService
    private let relatedEntitiesService: DocumentRelatedEntitiesService
    
    init(supabase: SupabaseClient? = SupabaseManager.shared.client) {
        self.supabase = supabase
        
        // Initialize services
        self.crudService = DocumentCRUDService(supabase: supabase)
        self.storageService = DocumentStorageService(supabase: supabase)
        self.searchService = DocumentSearchService(supabase: supabase)
        self.relatedEntitiesService = DocumentRelatedEntitiesService(supabase: supabase)
        self.batchService = DocumentBatchService(crudService: crudService, storageService: storageService)
    }
    
    // MARK: - CRUD Operations (Delegated)
    
    func fetchDocuments() async throws -> [Document] {
        try await crudService.fetchDocuments()
    }
    
    func fetchDocumentById(_ id: UUID) async throws -> Document {
        try await crudService.fetchDocumentById(id)
    }
    
    func fetchDocumentsByType(_ type: DocumentType) async throws -> [Document] {
        try await crudService.fetchDocumentsByType(type)
    }
    
    func fetchDocumentsByVendor(_ vendorId: Int) async throws -> [Document] {
        try await crudService.fetchDocumentsByVendor(vendorId)
    }
    
    func fetchDocumentsByExpense(_ expenseId: UUID) async throws -> [Document] {
        try await crudService.fetchDocumentsByExpense(expenseId)
    }
    
    func fetchDocumentsByBucket(_ bucketName: String) async throws -> [Document] {
        try await crudService.fetchDocumentsByBucket(bucketName)
    }
    
    func createDocument(_ data: DocumentInsertData) async throws -> Document {
        try await crudService.createDocument(data)
    }
    
    func updateDocument(
        _ id: UUID,
        fileName: String,
        documentType: DocumentType,
        vendorId: Int?,
        expenseId: UUID?,
        tags: [String]
    ) async throws -> Document {
        try await crudService.updateDocument(
            id,
            fileName: fileName,
            documentType: documentType,
            vendorId: vendorId,
            expenseId: expenseId,
            tags: tags
        )
    }
    
    func deleteDocument(_ id: UUID) async throws {
        try await crudService.deleteDocument(id)
    }
    
    func getDocumentCountByType() async throws -> [(DocumentType, Int)] {
        try await crudService.getDocumentCountByType()
    }
    
    // MARK: - Storage Operations (Delegated)
    
    func uploadFile(localURL: URL, bucketName: String, fileName: String) async throws -> String {
        try await storageService.uploadFile(localURL: localURL, bucketName: bucketName, fileName: fileName)
    }
    
    func getPublicURL(bucketName: String, path: String) throws -> URL {
        try storageService.getPublicURL(bucketName: bucketName, path: path)
    }
    
    func downloadFile(bucketName: String, path: String) async throws -> Data {
        try await storageService.downloadFile(bucketName: bucketName, path: path)
    }
    
    func deleteFile(bucketName: String, path: String) async throws {
        try await storageService.deleteFile(bucketName: bucketName, path: path)
    }
    
    // MARK: - Search Operations (Delegated)
    
    func searchDocuments(query: String) async throws -> [Document] {
        try await searchService.searchDocuments(query: query)
    }
    
    // MARK: - Batch Operations (Delegated)
    
    func deleteDocumentWithFile(_ document: Document) async throws {
        try await batchService.deleteDocumentWithFile(document)
    }
    
    func batchDeleteDocuments(_ ids: [UUID]) async throws {
        try await batchService.batchDeleteDocuments(ids)
    }
    
    func batchUpdateTags(_ ids: [UUID], addTags: [String] = [], removeTags: [String] = []) async throws {
        try await batchService.batchUpdateTags(ids, addTags: addTags, removeTags: removeTags)
    }
    
    func batchUpdateType(_ ids: [UUID], type: DocumentType) async throws {
        try await batchService.batchUpdateType(ids, type: type)
    }
    
    // MARK: - Related Entities (Delegated)
    
    func fetchVendors() async throws -> [(id: Int, name: String)] {
        try await relatedEntitiesService.fetchVendors()
    }
    
    func fetchExpenses() async throws -> [(id: UUID, description: String)] {
        try await relatedEntitiesService.fetchExpenses()
    }
    
    func fetchPayments(forExpenseId expenseId: UUID? = nil) async throws -> [(id: Int64, description: String)] {
        try await relatedEntitiesService.fetchPayments(forExpenseId: expenseId)
    }
}
