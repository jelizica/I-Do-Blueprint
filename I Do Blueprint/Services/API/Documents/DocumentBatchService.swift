//
//  DocumentBatchService.swift
//  I Do Blueprint
//
//  Batch operations for documents
//

import Foundation

/// Service for batch document operations
class DocumentBatchService {
    private let crudService: DocumentCRUDService
    private let storageService: DocumentStorageService
    private let logger = AppLogger.api
    
    init(crudService: DocumentCRUDService, storageService: DocumentStorageService) {
        self.crudService = crudService
        self.storageService = storageService
    }
    
    // MARK: - Batch Delete
    
    func batchDeleteDocuments(_ ids: [UUID]) async throws {
        for id in ids {
            let document = try await crudService.fetchDocumentById(id)
            try await deleteDocumentWithFile(document)
        }
    }
    
    func deleteDocumentWithFile(_ document: Document) async throws {
        let startTime = Date()
        
        do {
            // First delete the file from storage
            try await storageService.deleteFile(bucketName: document.bucketName, path: document.storagePath)
            
            // Then delete the database record
            try await crudService.deleteDocument(document.id)
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted document with file in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "deleteDocumentWithFile", outcome: .success, duration: duration)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Document with file deletion failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "deleteDocumentWithFile", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    // MARK: - Batch Update Tags
    
    func batchUpdateTags(_ ids: [UUID], addTags: [String] = [], removeTags: [String] = []) async throws {
        for id in ids {
            let document = try await crudService.fetchDocumentById(id)
            var updatedTags = document.tags
            
            // Add new tags
            for tag in addTags where !updatedTags.contains(tag) {
                updatedTags.append(tag)
            }
            
            // Remove tags
            updatedTags.removeAll { removeTags.contains($0) }
            
            // Update document
            _ = try await crudService.updateDocument(
                id,
                fileName: document.originalFilename,
                documentType: document.documentType,
                vendorId: document.vendorId,
                expenseId: document.expenseId,
                tags: updatedTags
            )
        }
    }
    
    // MARK: - Batch Update Type
    
    func batchUpdateType(_ ids: [UUID], type: DocumentType) async throws {
        for id in ids {
            let document = try await crudService.fetchDocumentById(id)
            
            _ = try await crudService.updateDocument(
                id,
                fileName: document.originalFilename,
                documentType: type,
                vendorId: document.vendorId,
                expenseId: document.expenseId,
                tags: document.tags
            )
        }
    }
}
