//
//  DocumentRepositoryProtocol.swift
//  My Wedding Planning App
//
//  Repository protocol for document/invoice management
//

import Dependencies
import Foundation

/// Protocol defining document repository operations
protocol DocumentRepositoryProtocol: Sendable {
    // MARK: - Document Operations

    /// Fetch all documents for the couple
    func fetchDocuments() async throws -> [Document]

    /// Fetch documents filtered by type
    func fetchDocuments(type: DocumentType) async throws -> [Document]

    /// Fetch documents filtered by bucket
    func fetchDocuments(bucket: DocumentBucket) async throws -> [Document]

    /// Fetch documents by vendor ID
    func fetchDocuments(vendorId: Int) async throws -> [Document]

    /// Fetch a single document by ID
    func fetchDocument(id: UUID) async throws -> Document?

    /// Create a new document record
    func createDocument(_ insertData: DocumentInsertData) async throws -> Document

    /// Update document metadata
    func updateDocument(_ document: Document) async throws -> Document

    /// Delete a document
    func deleteDocument(id: UUID) async throws

    /// Batch delete documents
    func batchDeleteDocuments(ids: [UUID]) async throws

    /// Update document tags
    func updateDocumentTags(id: UUID, tags: [String]) async throws -> Document

    /// Update document type
    func updateDocumentType(id: UUID, type: DocumentType) async throws -> Document

    // MARK: - Search Operations

    /// Search documents by filename
    func searchDocuments(query: String) async throws -> [Document]

    /// Get all unique tags across documents
    func fetchAllTags() async throws -> [String]

    // MARK: - Storage Operations

    /// Upload file to storage and create document record
    func uploadDocument(
        fileData: Data,
        metadata: FileUploadMetadata,
        coupleId: UUID) async throws -> Document

    /// Download file data from storage
    func downloadDocument(document: Document) async throws -> Data

    /// Get public URL for document
    func getPublicURL(for document: Document) async throws -> URL
}
