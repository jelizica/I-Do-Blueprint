//
//  DocumentStoreV2Tests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for DocumentStoreV2
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class DocumentStoreV2Tests: XCTestCase {
    var store: DocumentStoreV2!
    var mockRepository: MockDocumentRepository!

    override func setUp() async throws {
        mockRepository = MockDocumentRepository()
        store = withDependencies {
            $0.documentRepository = mockRepository
            $0.vendorRepository = MockVendorRepository()
            $0.budgetRepository = MockBudgetRepository()
        } operation: {
            DocumentStoreV2()
        }
    }

    override func tearDown() async throws {
        store = nil
        mockRepository = nil
    }

    // MARK: - Load Documents Tests

    func testLoadDocuments_Success() async throws {
        // Given
        let mockDocuments = [
            createMockDocument(filename: "contract.pdf", type: .contract),
            createMockDocument(filename: "invoice.pdf", type: .invoice),
        ]
        mockRepository.documents = mockDocuments

        // When
        await store.loadDocuments()

        // Then
        XCTAssertEqual(store.documents.count, 2)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testLoadDocuments_EmptyResult() async throws {
        // Given
        mockRepository.documents = []

        // When
        await store.loadDocuments()

        // Then
        XCTAssertTrue(store.documents.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testLoadDocuments_Error() async throws {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await store.loadDocuments()

        // Then
        XCTAssertTrue(store.documents.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Upload Document Tests

    func testUploadDocument_Success() async throws {
        // Given
        let fileData = "test content".data(using: .utf8)!
        let metadata = FileUploadMetadata(
            localURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            filename: "test.pdf",
            mimeType: "application/pdf",
            fileSize: Int64(fileData.count),
            documentType: .contract,
            vendorId: nil,
            expenseId: nil,
            tags: []
        )
        let coupleId = UUID()
        let newDoc = createMockDocument(filename: "test.pdf")
        mockRepository.uploadedDocument = newDoc

        // When
        await store.uploadDocument(fileData: fileData, metadata: metadata, coupleId: coupleId)

        // Then
        XCTAssertEqual(store.documents.count, 1)
        XCTAssertEqual(store.documents[0].originalFilename, "test.pdf")
        XCTAssertFalse(store.isUploading)
        XCTAssertEqual(store.uploadProgress, 1.0)
        XCTAssertNil(store.error)
    }

    // MARK: - Update Document Tests

    func testUpdateDocument_Success() async throws {
        // Given
        let originalDoc = createMockDocument(filename: "original.pdf")
        store.documents = [originalDoc]

        var updatedDoc = originalDoc
        updatedDoc.originalFilename = "updated.pdf"
        mockRepository.updatedDocument = updatedDoc

        // When
        await store.updateDocument(updatedDoc)

        // Then
        XCTAssertEqual(store.documents[0].originalFilename, "updated.pdf")
        XCTAssertNil(store.error)
    }

    func testUpdateDocument_RollbackOnError() async throws {
        // Given
        let originalDoc = createMockDocument(filename: "original.pdf")
        store.documents = [originalDoc]

        var updatedDoc = originalDoc
        updatedDoc.originalFilename = "updated.pdf"
        mockRepository.shouldThrowError = true

        // When
        await store.updateDocument(updatedDoc)

        // Then
        XCTAssertEqual(store.documents[0].originalFilename, "original.pdf")
        XCTAssertNotNil(store.error)
    }

    // MARK: - Delete Document Tests

    func testDeleteDocument_Success() async throws {
        // Given
        let doc = createMockDocument(filename: "to_delete.pdf")
        store.documents = [doc]

        // When
        await store.deleteDocument(doc)

        // Then
        XCTAssertTrue(store.documents.isEmpty)
        XCTAssertNil(store.error)
    }

    func testDeleteDocument_RollbackOnError() async throws {
        // Given
        let doc = createMockDocument(filename: "to_delete.pdf")
        store.documents = [doc]
        mockRepository.shouldThrowError = true

        // When
        await store.deleteDocument(doc)

        // Then
        XCTAssertEqual(store.documents.count, 1)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Batch Delete Tests

    func testBatchDeleteDocuments_Success() async throws {
        // Given
        let doc1 = createMockDocument(filename: "doc1.pdf")
        let doc2 = createMockDocument(filename: "doc2.pdf")
        let doc3 = createMockDocument(filename: "doc3.pdf")
        store.documents = [doc1, doc2, doc3]

        // When
        await store.batchDeleteDocuments(ids: [doc1.id, doc2.id])

        // Then
        XCTAssertEqual(store.documents.count, 1)
        XCTAssertEqual(store.documents[0].id, doc3.id)
        XCTAssertNil(store.error)
    }

    // MARK: - Filtering Tests

    func testFilteredDocuments_BySearchQuery() {
        // Given
        store.documents = [
            createMockDocument(filename: "contract.pdf", type: .contract),
            createMockDocument(filename: "invoice.pdf", type: .invoice),
        ]
        store.searchQuery = "contract"

        // When
        let filtered = store.filteredDocuments

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].originalFilename, "contract.pdf")
    }

    func testFilteredDocuments_ByType() {
        // Given
        store.documents = [
            createMockDocument(filename: "contract.pdf", type: .contract),
            createMockDocument(filename: "invoice.pdf", type: .invoice),
        ]
        store.filters.selectedType = .contract

        // When
        let filtered = store.filteredDocuments

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].documentType, .contract)
    }

    func testFilteredDocuments_ByBucket() {
        // Given
        store.documents = [
            createMockDocument(filename: "doc1.pdf", bucket: .contracts),
            createMockDocument(filename: "doc2.pdf", bucket: .invoices),
        ]
        store.filters.selectedBucket = .contracts

        // When
        let filtered = store.filteredDocuments

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].bucketName, DocumentBucket.contracts.rawValue)
    }

    // MARK: - Sorting Tests

    func testSortedDocuments_ByUploadedDesc() {
        // Given
        let oldDate = Date().addingTimeInterval(-3600)
        let newDate = Date()

        store.documents = [
            createMockDocument(filename: "old.pdf", uploadedAt: oldDate),
            createMockDocument(filename: "new.pdf", uploadedAt: newDate),
        ]
        store.sortOption = .uploadedDesc

        // When
        let filtered = store.filteredDocuments

        // Then
        XCTAssertEqual(filtered[0].originalFilename, "new.pdf")
        XCTAssertEqual(filtered[1].originalFilename, "old.pdf")
    }

    // MARK: - Document Stats Tests

    func testDocumentStats_Calculation() {
        // Given
        store.documents = [
            createMockDocument(filename: "image.jpg", type: .other, mimeType: "image/jpeg", fileSize: 1000),
            createMockDocument(filename: "doc.pdf", type: .contract, mimeType: "application/pdf", fileSize: 2000),
            createMockDocument(filename: "invoice.pdf", type: .invoice, mimeType: "application/pdf", fileSize: 3000),
        ]

        // When
        let stats = store.documentStats

        // Then
        XCTAssertEqual(stats.total, 3)
        XCTAssertEqual(stats.images, 1)
        XCTAssertEqual(stats.pdfs, 2)
        XCTAssertEqual(stats.contracts, 1)
        XCTAssertEqual(stats.invoices, 1)
        XCTAssertEqual(stats.totalSize, 6000)
    }

    // MARK: - Helper Methods

    private func createMockDocument(
        filename: String,
        type: DocumentType = .other,
        bucket: DocumentBucket = .contracts,
        mimeType: String = "application/pdf",
        fileSize: Int64 = 1000,
        uploadedAt: Date = Date()
    ) -> Document {
        Document(
            id: UUID(),
            tenantId: UUID(),
            originalFilename: filename,
            storagePath: "/path/\(filename)",
            bucketName: bucket.rawValue,
            fileSize: fileSize,
            mimeType: mimeType,
            documentType: type,
            uploadedBy: UUID(),
            uploadedAt: uploadedAt,
            vendorId: nil,
            expenseId: nil,
            tags: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Repository

class MockDocumentRepository: DocumentRepositoryProtocol {
    var documents: [Document] = []
    var uploadedDocument: Document?
    var updatedDocument: Document?
    var shouldThrowError = false

    func fetchDocuments() async throws -> [Document] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return documents
    }

    func fetchDocuments(type: DocumentType) async throws -> [Document] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return documents.filter { $0.documentType == type }
    }

    func fetchDocuments(bucket: DocumentBucket) async throws -> [Document] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return documents.filter { $0.bucketName == bucket.rawValue }
    }

    func fetchDocuments(vendorId: Int) async throws -> [Document] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return documents.filter { $0.vendorId == vendorId }
    }

    func uploadDocument(fileData: Data, metadata: FileUploadMetadata, coupleId: UUID) async throws -> Document {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return uploadedDocument ?? Document(
            id: UUID(),
            tenantId: UUID(),
            originalFilename: metadata.filename,
            storagePath: "/path/\(metadata.filename)",
            bucketName: "contracts",
            fileSize: metadata.fileSize,
            mimeType: metadata.mimeType,
            documentType: metadata.documentType,
            uploadedBy: UUID(),
            uploadedAt: Date(),
            vendorId: metadata.vendorId,
            expenseId: metadata.expenseId,
            tags: metadata.tags,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func updateDocument(_ document: Document) async throws -> Document {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return updatedDocument ?? document
    }

    func updateDocumentTags(id: UUID, tags: [String]) async throws -> Document {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        guard let doc = documents.first(where: { $0.id == id }) else {
            throw NSError(domain: "test", code: -1)
        }
        var updated = doc
        updated.tags = tags
        return updated
    }

    func updateDocumentType(id: UUID, type: DocumentType) async throws -> Document {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        guard let doc = documents.first(where: { $0.id == id }) else {
            throw NSError(domain: "test", code: -1)
        }
        var updated = doc
        updated.documentType = type
        return updated
    }

    func deleteDocument(id: UUID) async throws {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
    }

    func batchDeleteDocuments(ids: [UUID]) async throws {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
    }

    func searchDocuments(query: String) async throws -> [Document] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return documents.filter { $0.originalFilename.contains(query) }
    }

    func downloadDocument(document: Document) async throws -> Data {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return Data()
    }

    func getPublicURL(for document: Document) async throws -> URL {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return URL(string: "https://example.com/\(document.storagePath)")!
    }

    func invalidateCache() async {
        // No-op for mock
    }
}
