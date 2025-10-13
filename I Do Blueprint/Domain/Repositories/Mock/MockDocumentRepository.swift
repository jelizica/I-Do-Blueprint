//
//  MockDocumentRepository.swift
//  My Wedding Planning App
//
//  Mock implementation for testing
//

import Foundation

@MainActor
class MockDocumentRepository: DocumentRepositoryProtocol {
    var documents: [Document] = []
    var allTags: [String] = []

    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])

    // MARK: - Document Operations

    func fetchDocuments() async throws -> [Document] {
        if shouldThrowError { throw errorToThrow }
        return documents
    }

    func fetchDocuments(type: DocumentType) async throws -> [Document] {
        if shouldThrowError { throw errorToThrow }
        return documents.filter { $0.documentType == type }
    }

    func fetchDocuments(bucket: DocumentBucket) async throws -> [Document] {
        if shouldThrowError { throw errorToThrow }
        return documents.filter { $0.bucketName == bucket.rawValue }
    }

    func fetchDocuments(vendorId: Int) async throws -> [Document] {
        if shouldThrowError { throw errorToThrow }
        return documents.filter { $0.vendorId == vendorId }
    }

    func fetchDocument(id: UUID) async throws -> Document? {
        if shouldThrowError { throw errorToThrow }
        return documents.first(where: { $0.id == id })
    }

    func createDocument(_ insertData: DocumentInsertData) async throws -> Document {
        if shouldThrowError { throw errorToThrow }

        let document = Document(
            id: UUID(),
            coupleId: insertData.coupleId,
            originalFilename: insertData.originalFilename,
            storagePath: insertData.storagePath,
            fileSize: insertData.fileSize,
            mimeType: insertData.mimeType,
            documentType: insertData.documentType,
            bucketName: insertData.bucketName,
            vendorId: insertData.vendorId,
            expenseId: insertData.expenseId,
            paymentId: nil,
            tags: insertData.tags,
            uploadedBy: insertData.uploadedBy,
            uploadedAt: Date(),
            updatedAt: Date(),
            autoTagStatus: insertData.autoTagStatus,
            autoTagSource: insertData.autoTagSource,
            autoTaggedAt: nil,
            autoTagError: nil)
        documents.append(document)
        return document
    }

    func updateDocument(_ document: Document) async throws -> Document {
        if shouldThrowError { throw errorToThrow }

        guard let index = documents.firstIndex(where: { $0.id == document.id }) else {
            throw DocumentError.notFound(id: document.id)
        }

        var updated = document
        updated.updatedAt = Date()
        documents[index] = updated
        return updated
    }

    func deleteDocument(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }

        guard let index = documents.firstIndex(where: { $0.id == id }) else {
            throw DocumentError.notFound(id: id)
        }

        documents.remove(at: index)
    }

    func batchDeleteDocuments(ids: [UUID]) async throws {
        if shouldThrowError { throw errorToThrow }

        documents.removeAll { ids.contains($0.id) }
    }

    func updateDocumentTags(id: UUID, tags: [String]) async throws -> Document {
        if shouldThrowError { throw errorToThrow }

        guard let index = documents.firstIndex(where: { $0.id == id }) else {
            throw DocumentError.notFound(id: id)
        }

        var updated = documents[index]
        updated.tags = tags
        updated.updatedAt = Date()
        documents[index] = updated
        return updated
    }

    func updateDocumentType(id: UUID, type: DocumentType) async throws -> Document {
        if shouldThrowError { throw errorToThrow }

        guard let index = documents.firstIndex(where: { $0.id == id }) else {
            throw DocumentError.notFound(id: id)
        }

        var updated = documents[index]
        updated.documentType = type
        updated.updatedAt = Date()
        documents[index] = updated
        return updated
    }

    // MARK: - Search Operations

    func searchDocuments(query: String) async throws -> [Document] {
        if shouldThrowError { throw errorToThrow }

        return documents.filter {
            $0.originalFilename.localizedCaseInsensitiveContains(query)
        }
    }

    func fetchAllTags() async throws -> [String] {
        if shouldThrowError { throw errorToThrow }
        // Aggregate unique tags from all documents
        let allDocumentTags = documents.flatMap { $0.tags }
        return Array(Set(allDocumentTags))
    }

    // MARK: - Storage Operations

    func uploadDocument(
        fileData: Data,
        metadata: FileUploadMetadata,
        coupleId: UUID) async throws -> Document {
        if shouldThrowError { throw errorToThrow }

        let insertData = DocumentInsertData(
            coupleId: coupleId,
            originalFilename: metadata.fileName,
            storagePath: "mock/\(metadata.fileName)",
            fileSize: metadata.fileSize,
            mimeType: metadata.mimeType,
            documentType: metadata.documentType,
            bucketName: metadata.bucket.rawValue,
            vendorId: metadata.vendorId,
            expenseId: metadata.expenseId,
            tags: metadata.tags,
            uploadedBy: "test")

        return try await createDocument(insertData)
    }

    func downloadDocument(document: Document) async throws -> Data {
        if shouldThrowError { throw errorToThrow }
        return Data() // Return empty data for testing
    }

    func getPublicURL(for document: Document) async throws -> URL {
        if shouldThrowError { throw errorToThrow }
        return URL(string: "https://example.com/\(document.storagePath)")!
    }
}
