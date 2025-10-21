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
    var mockRepository: MockDocumentRepository!
    var coupleId: UUID!

    override func setUp() async throws {
        mockRepository = MockDocumentRepository()
        coupleId = UUID()
    }

    override func tearDown() {
        mockRepository = nil
        coupleId = nil
    }

    // MARK: - Load Tests

    func testLoadDocuments_Success() async throws {
        // Given
        let testDocuments = [
            Document.makeTest(id: UUID(), coupleId: coupleId, originalFilename: "contract.pdf"),
            Document.makeTest(id: UUID(), coupleId: coupleId, originalFilename: "invoice.pdf")
        ]
        mockRepository.documents = testDocuments

        // When
        let store = await withDependencies {
            $0.documentRepository = mockRepository
        } operation: {
            DocumentStoreV2()
        }

        await store.loadDocuments()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.documents.count, 2)
        XCTAssertEqual(store.documents[0].originalFilename, "contract.pdf")
    }

    func testLoadDocuments_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        let store = await withDependencies {
            $0.documentRepository = mockRepository
        } operation: {
            DocumentStoreV2()
        }

        await store.loadDocuments()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.documents.count, 0)
    }

    func testLoadDocuments_Empty() async throws {
        // Given
        mockRepository.documents = []

        // When
        let store = await withDependencies {
            $0.documentRepository = mockRepository
        } operation: {
            DocumentStoreV2()
        }

        await store.loadDocuments()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.documents.count, 0)
    }

    // MARK: - Upload Tests

    func testUploadDocument_OptimisticUpdate() async throws {
        // Given
        let fileData = Data([0x00, 0x01, 0x02])
        let metadata = FileUploadMetadata(
            localURL: URL(fileURLWithPath: "/tmp/test.pdf"),
            fileName: "test.pdf",
            documentType: .contract,
            vendorId: nil,
            expenseId: nil,
            tags: []
        )

        // When
        let store = await withDependencies {
            $0.documentRepository = mockRepository
        } operation: {
            DocumentStoreV2()
        }

        await store.uploadDocument(fileData: fileData, metadata: metadata, coupleId: coupleId)

        // Then
        XCTAssertEqual(store.documents.count, 1)
        XCTAssertFalse(store.isUploading)
    }

    // MARK: - Update Tests

    func testUpdateDocument_Success() async throws {
        // Given
        let document = Document.makeTest(id: UUID(), coupleId: coupleId, originalFilename: "original.pdf")
        mockRepository.documents = [document]

        // When
        let store = await withDependencies {
            $0.documentRepository = mockRepository
        } operation: {
            DocumentStoreV2()
        }

        await store.loadDocuments()

        var updatedDocument = document
        updatedDocument.originalFilename = "updated.pdf"
        await store.updateDocument(updatedDocument)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.documents.first?.originalFilename, "updated.pdf")
    }

    func testUpdateDocument_Failure_RollsBack() async throws {
        // Given
        let document = Document.makeTest(id: UUID(), coupleId: coupleId, originalFilename: "original.pdf")
        mockRepository.documents = [document]

        // When
        let store = await withDependencies {
            $0.documentRepository = mockRepository
        } operation: {
            DocumentStoreV2()
        }

        await store.loadDocuments()

        var updatedDocument = document
        updatedDocument.originalFilename = "updated.pdf"

        mockRepository.shouldThrowError = true
        await store.updateDocument(updatedDocument)

        // Then - Should rollback to original
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.documents.first?.originalFilename, "original.pdf")
    }

    // MARK: - Delete Tests

    func testDeleteDocument_Success() async throws {
        // Given
        let doc1 = Document.makeTest(id: UUID(), coupleId: coupleId, originalFilename: "doc1.pdf")
        let doc2 = Document.makeTest(id: UUID(), coupleId: coupleId, originalFilename: "doc2.pdf")
        mockRepository.documents = [doc1, doc2]

        // When
        let store = await withDependencies {
            $0.documentRepository = mockRepository
        } operation: {
            DocumentStoreV2()
        }

        await store.loadDocuments()
        await store.deleteDocument(doc1)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.documents.count, 1)
        XCTAssertEqual(store.documents.first?.originalFilename, "doc2.pdf")
    }

    func testDeleteDocument_Failure_RollsBack() async throws {
        // Given
        let document = Document.makeTest(id: UUID(), coupleId: coupleId, originalFilename: "doc1.pdf")
        mockRepository.documents = [document]

        // When
        let store = await withDependencies {
            $0.documentRepository = mockRepository
        } operation: {
            DocumentStoreV2()
        }

        await store.loadDocuments()

        mockRepository.shouldThrowError = true
        await store.deleteDocument(document)

        // Then - Should rollback
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.documents.count, 1)
    }

    // MARK: - Filter Tests

    func testFilterByType() async throws {
        // Given
        let documents = [
            Document.makeTest(coupleId: coupleId, documentType: .contract),
            Document.makeTest(coupleId: coupleId, documentType: .invoice),
            Document.makeTest(coupleId: coupleId, documentType: .contract)
        ]
        mockRepository.documents = documents

        // When
        let store = await withDependencies {
            $0.documentRepository = mockRepository
        } operation: {
            DocumentStoreV2()
        }

        await store.loadDocuments()
        store.filters.selectedType = DocumentType.contract
        let filtered = store.filteredDocuments

        // Then
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.documentType == DocumentType.contract })
    }

    func testFilterByBucket() async throws {
        // Given
        let documents = [
            Document.makeTest(coupleId: coupleId, bucketName: "invoices-and-contracts"),
            Document.makeTest(coupleId: coupleId, bucketName: "photos"),
            Document.makeTest(coupleId: coupleId, bucketName: "invoices-and-contracts")
        ]
        mockRepository.documents = documents

        // When
        let store = await withDependencies {
            $0.documentRepository = mockRepository
        } operation: {
            DocumentStoreV2()
        }

        await store.loadDocuments()
        store.filters.selectedBucket = DocumentBucket.invoicesAndContracts
        let filtered = store.filteredDocuments

        // Then
        XCTAssertEqual(filtered.count, 2)
    }

    // MARK: - Tag Management Tests

    func testUpdateDocumentTags() async throws {
        // Given
        let document = Document.makeTest(id: UUID(), coupleId: coupleId, originalFilename: "doc.pdf")
        mockRepository.documents = [document]

        // When
        let store = await withDependencies {
            $0.documentRepository = mockRepository
        } operation: {
            DocumentStoreV2()
        }

        await store.loadDocuments()
        await store.updateDocumentTags(id: document.id, tags: ["important", "wedding"])

        // Then
        XCTAssertNil(store.error)
    }

    // MARK: - Computed Properties Tests

    func testComputedProperty_TotalDocuments() async throws {
        // Given
        let documents = [
            Document.makeTest(coupleId: coupleId),
            Document.makeTest(coupleId: coupleId),
            Document.makeTest(coupleId: coupleId)
        ]
        mockRepository.documents = documents

        // When
        let store = await withDependencies {
            $0.documentRepository = mockRepository
        } operation: {
            DocumentStoreV2()
        }

        await store.loadDocuments()

        // Then
        let stats = store.documentStats
        XCTAssertEqual(stats.total, 3)
    }

    func testComputedProperty_DocumentsByType() async throws {
        // Given
        let documents = [
            Document.makeTest(coupleId: coupleId, documentType: .contract),
            Document.makeTest(coupleId: coupleId, documentType: .invoice),
            Document.makeTest(coupleId: coupleId, documentType: .contract)
        ]
        mockRepository.documents = documents

        // When
        let store = await withDependencies {
            $0.documentRepository = mockRepository
        } operation: {
            DocumentStoreV2()
        }

        await store.loadDocuments()
        let stats = store.documentStats

        // Then
        XCTAssertEqual(stats.contracts, 2)
        XCTAssertEqual(stats.invoices, 1)
    }
}
