//
//  MockDocumentRepository.swift
//  I Do BlueprintTests
//
//  Mock implementation of DocumentRepositoryProtocol for testing
//

import Foundation
@testable import I_Do_Blueprint

class MockDocumentRepository: DocumentRepositoryProtocol {
    var documents: [Document] = []
    var shouldThrowError = false
    var errorToThrow: DocumentError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

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
        let document = Document.makeTest(originalFilename: insertData.originalFilename, fileSize: insertData.fileSize)
        documents.append(document)
        return document
    }

    func updateDocument(_ document: Document) async throws -> Document {
        if shouldThrowError { throw errorToThrow }
        if let index = documents.firstIndex(where: { $0.id == document.id }) {
            documents[index] = document
        }
        return document
    }

    func deleteDocument(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        documents.removeAll(where: { $0.id == id })
    }

    func batchDeleteDocuments(ids: [UUID]) async throws {
        if shouldThrowError { throw errorToThrow }
        documents.removeAll(where: { ids.contains($0.id) })
    }

    func updateDocumentTags(id: UUID, tags: [String]) async throws -> Document {
        if shouldThrowError { throw errorToThrow }
        guard let index = documents.firstIndex(where: { $0.id == id }) else {
            throw DocumentError.notFound(id: id)
        }
        var document = documents[index]
        document.tags = tags
        documents[index] = document
        return document
    }

    func updateDocumentType(id: UUID, type: DocumentType) async throws -> Document {
        if shouldThrowError { throw errorToThrow }
        guard let index = documents.firstIndex(where: { $0.id == id }) else {
            throw DocumentError.notFound(id: id)
        }
        var document = documents[index]
        document.documentType = type
        documents[index] = document
        return document
    }

    func searchDocuments(query: String) async throws -> [Document] {
        if shouldThrowError { throw errorToThrow }
        return documents.filter { $0.originalFilename.localizedCaseInsensitiveContains(query) }
    }

    func fetchAllTags() async throws -> [String] {
        if shouldThrowError { throw errorToThrow }
        let allTags = documents.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }

    func uploadDocument(fileData: Data, metadata: FileUploadMetadata, coupleId: UUID) async throws -> Document {
        if shouldThrowError { throw errorToThrow }
        let document = Document.makeTest(originalFilename: metadata.fileName, fileSize: Int64(fileData.count))
        documents.append(document)
        return document
    }

    func downloadDocument(document: Document) async throws -> Data {
        if shouldThrowError { throw errorToThrow }
        return Data()
    }

    func getPublicURL(for document: Document) async throws -> URL {
        if shouldThrowError { throw errorToThrow }
        return URL(string: "https://example.com/\(document.originalFilename)")!
    }
}
