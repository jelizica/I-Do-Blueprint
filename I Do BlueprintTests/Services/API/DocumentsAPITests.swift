//
//  DocumentsAPITests.swift
//  I Do BlueprintTests
//
//  Integration tests for DocumentsAPI
//

import XCTest
@testable import I_Do_Blueprint

@MainActor
final class DocumentsAPITests: XCTestCase {
    var mockSupabase: MockDocumentsSupabaseClient!
    var api: DocumentsAPI!
    
    override func setUp() async throws {
        try await super.setUp()
        mockSupabase = MockDocumentsSupabaseClient()
        api = DocumentsAPI(supabase: mockSupabase)
    }
    
    override func tearDown() async throws {
        mockSupabase = nil
        api = nil
        try await super.tearDown()
    }
    
    // MARK: - Fetch Documents Tests
    
    func test_fetchDocuments_success() async throws {
        // Given
        let doc1 = Document.makeTest(fileName: "Contract.pdf", documentType: .contract)
        let doc2 = Document.makeTest(fileName: "Invoice.pdf", documentType: .invoice)
        mockSupabase.mockDocuments = [doc1, doc2]
        
        // When
        let documents = try await api.fetchDocuments()
        
        // Then
        XCTAssertEqual(documents.count, 2)
        XCTAssertEqual(documents[0].fileName, "Contract.pdf")
        XCTAssertEqual(documents[1].fileName, "Invoice.pdf")
    }
    
    func test_fetchDocuments_emptyData_returnsEmptyArray() async throws {
        // Given
        mockSupabase.mockDocuments = []
        
        // When
        let documents = try await api.fetchDocuments()
        
        // Then
        XCTAssertTrue(documents.isEmpty)
    }
    
    func test_fetchDocumentById_success() async throws {
        // Given
        let docId = UUID()
        let mockDoc = Document.makeTest(id: docId, fileName: "Test.pdf")
        mockSupabase.mockDocument = mockDoc
        
        // When
        let document = try await api.fetchDocumentById(docId)
        
        // Then
        XCTAssertEqual(document.id, docId)
        XCTAssertEqual(document.fileName, "Test.pdf")
    }
    
    func test_fetchDocumentsByType_success() async throws {
        // Given
        let contract1 = Document.makeTest(fileName: "Contract1.pdf", documentType: .contract)
        let contract2 = Document.makeTest(fileName: "Contract2.pdf", documentType: .contract)
        mockSupabase.mockDocuments = [contract1, contract2]
        
        // When
        let documents = try await api.fetchDocumentsByType(.contract)
        
        // Then
        XCTAssertEqual(documents.count, 2)
        XCTAssertTrue(documents.allSatisfy { $0.documentType == .contract })
    }
    
    func test_fetchDocumentsByVendor_success() async throws {
        // Given
        let vendorId = 123
        let doc1 = Document.makeTest(fileName: "Vendor1.pdf", vendorId: vendorId)
        let doc2 = Document.makeTest(fileName: "Vendor2.pdf", vendorId: vendorId)
        mockSupabase.mockDocuments = [doc1, doc2]
        
        // When
        let documents = try await api.fetchDocumentsByVendor(vendorId)
        
        // Then
        XCTAssertEqual(documents.count, 2)
        XCTAssertTrue(documents.allSatisfy { $0.vendorId == vendorId })
    }
    
    func test_fetchDocumentsByExpense_success() async throws {
        // Given
        let expenseId = UUID()
        let doc1 = Document.makeTest(fileName: "Expense1.pdf", expenseId: expenseId)
        let doc2 = Document.makeTest(fileName: "Expense2.pdf", expenseId: expenseId)
        mockSupabase.mockDocuments = [doc1, doc2]
        
        // When
        let documents = try await api.fetchDocumentsByExpense(expenseId)
        
        // Then
        XCTAssertEqual(documents.count, 2)
        XCTAssertTrue(documents.allSatisfy { $0.expenseId == expenseId })
    }
    
    func test_fetchDocumentsByBucket_success() async throws {
        // Given
        let bucketName = "wedding-documents"
        let doc1 = Document.makeTest(fileName: "Doc1.pdf", bucketName: bucketName)
        let doc2 = Document.makeTest(fileName: "Doc2.pdf", bucketName: bucketName)
        mockSupabase.mockDocuments = [doc1, doc2]
        
        // When
        let documents = try await api.fetchDocumentsByBucket(bucketName)
        
        // Then
        XCTAssertEqual(documents.count, 2)
        XCTAssertTrue(documents.allSatisfy { $0.bucketName == bucketName })
    }
    
    // MARK: - Create Document Tests
    
    func test_createDocument_success() async throws {
        // Given
        let insertData = DocumentInsertData(
            coupleId: UUID(),
            fileName: "NewDoc.pdf",
            filePath: "/path/to/file",
            bucketName: "wedding-documents",
            documentType: .contract,
            vendorId: nil,
            expenseId: nil,
            tags: ["important"]
        )
        
        let mockDoc = Document.makeTest(
            fileName: insertData.fileName,
            documentType: insertData.documentType,
            tags: insertData.tags
        )
        mockSupabase.mockDocument = mockDoc
        
        // When
        let document = try await api.createDocument(insertData)
        
        // Then
        XCTAssertEqual(document.fileName, "NewDoc.pdf")
        XCTAssertEqual(document.documentType, .contract)
        XCTAssertEqual(document.tags, ["important"])
    }
    
    // MARK: - Update Document Tests
    
    func test_updateDocument_success() async throws {
        // Given
        let docId = UUID()
        let mockDoc = Document.makeTest(
            id: docId,
            fileName: "UpdatedDoc.pdf",
            documentType: .invoice,
            tags: ["updated"]
        )
        mockSupabase.mockDocument = mockDoc
        
        // When
        let document = try await api.updateDocument(
            docId,
            fileName: "UpdatedDoc.pdf",
            documentType: .invoice,
            vendorId: nil,
            expenseId: nil,
            tags: ["updated"]
        )
        
        // Then
        XCTAssertEqual(document.id, docId)
        XCTAssertEqual(document.fileName, "UpdatedDoc.pdf")
        XCTAssertEqual(document.documentType, .invoice)
    }
    
    // MARK: - Delete Document Tests
    
    func test_deleteDocument_success() async throws {
        // Given
        let docId = UUID()
        mockSupabase.deleteSucceeds = true
        
        // When/Then
        try await api.deleteDocument(docId)
        // Should not throw
    }
    
    // MARK: - Document Count Tests
    
    func test_getDocumentCountByType_success() async throws {
        // Given
        mockSupabase.mockDocumentCounts = [
            (.contract, 5),
            (.invoice, 3),
            (.receipt, 10)
        ]
        
        // When
        let counts = try await api.getDocumentCountByType()
        
        // Then
        XCTAssertEqual(counts.count, 3)
        XCTAssertTrue(counts.contains { $0.0 == .contract && $0.1 == 5 })
        XCTAssertTrue(counts.contains { $0.0 == .invoice && $0.1 == 3 })
        XCTAssertTrue(counts.contains { $0.0 == .receipt && $0.1 == 10 })
    }
    
    // MARK: - Storage Operations Tests
    
    func test_uploadFile_success() async throws {
        // Given
        let localURL = URL(fileURLWithPath: "/tmp/test.pdf")
        let bucketName = "wedding-documents"
        let fileName = "test.pdf"
        mockSupabase.mockUploadPath = "uploads/test.pdf"
        
        // When
        let path = try await api.uploadFile(localURL: localURL, bucketName: bucketName, fileName: fileName)
        
        // Then
        XCTAssertEqual(path, "uploads/test.pdf")
    }
    
    func test_getPublicURL_success() throws {
        // Given
        let bucketName = "wedding-documents"
        let path = "uploads/test.pdf"
        mockSupabase.mockPublicURL = URL(string: "https://example.com/uploads/test.pdf")!
        
        // When
        let url = try api.getPublicURL(bucketName: bucketName, path: path)
        
        // Then
        XCTAssertEqual(url.absoluteString, "https://example.com/uploads/test.pdf")
    }
    
    func test_downloadFile_success() async throws {
        // Given
        let bucketName = "wedding-documents"
        let path = "uploads/test.pdf"
        let mockData = "Test file content".data(using: .utf8)!
        mockSupabase.mockDownloadData = mockData
        
        // When
        let data = try await api.downloadFile(bucketName: bucketName, path: path)
        
        // Then
        XCTAssertEqual(data, mockData)
    }
    
    func test_deleteFile_success() async throws {
        // Given
        let bucketName = "wedding-documents"
        let path = "uploads/test.pdf"
        mockSupabase.deleteSucceeds = true
        
        // When/Then
        try await api.deleteFile(bucketName: bucketName, path: path)
        // Should not throw
    }
    
    // MARK: - Search Operations Tests
    
    func test_searchDocuments_success() async throws {
        // Given
        let query = "contract"
        let doc1 = Document.makeTest(fileName: "Contract1.pdf")
        let doc2 = Document.makeTest(fileName: "Contract2.pdf")
        mockSupabase.mockDocuments = [doc1, doc2]
        
        // When
        let documents = try await api.searchDocuments(query: query)
        
        // Then
        XCTAssertEqual(documents.count, 2)
        XCTAssertTrue(documents.allSatisfy { $0.fileName.lowercased().contains(query) })
    }
    
    // MARK: - Batch Operations Tests
    
    func test_deleteDocumentWithFile_success() async throws {
        // Given
        let document = Document.makeTest(fileName: "ToDelete.pdf")
        mockSupabase.deleteSucceeds = true
        
        // When/Then
        try await api.deleteDocumentWithFile(document)
        // Should not throw
    }
    
    func test_batchDeleteDocuments_success() async throws {
        // Given
        let ids = [UUID(), UUID(), UUID()]
        mockSupabase.deleteSucceeds = true
        
        // When/Then
        try await api.batchDeleteDocuments(ids)
        // Should not throw
    }
    
    func test_batchUpdateTags_success() async throws {
        // Given
        let ids = [UUID(), UUID()]
        let addTags = ["important", "urgent"]
        let removeTags = ["old"]
        mockSupabase.updateSucceeds = true
        
        // When/Then
        try await api.batchUpdateTags(ids, addTags: addTags, removeTags: removeTags)
        // Should not throw
    }
    
    func test_batchUpdateType_success() async throws {
        // Given
        let ids = [UUID(), UUID()]
        let type = DocumentType.contract
        mockSupabase.updateSucceeds = true
        
        // When/Then
        try await api.batchUpdateType(ids, type: type)
        // Should not throw
    }
    
    // MARK: - Related Entities Tests
    
    func test_fetchVendors_success() async throws {
        // Given
        mockSupabase.mockVendors = [(1, "Vendor A"), (2, "Vendor B")]
        
        // When
        let vendors = try await api.fetchVendors()
        
        // Then
        XCTAssertEqual(vendors.count, 2)
        XCTAssertEqual(vendors[0].id, 1)
        XCTAssertEqual(vendors[0].name, "Vendor A")
    }
    
    func test_fetchExpenses_success() async throws {
        // Given
        let expenseId1 = UUID()
        let expenseId2 = UUID()
        mockSupabase.mockExpenses = [(expenseId1, "Expense A"), (expenseId2, "Expense B")]
        
        // When
        let expenses = try await api.fetchExpenses()
        
        // Then
        XCTAssertEqual(expenses.count, 2)
        XCTAssertEqual(expenses[0].id, expenseId1)
        XCTAssertEqual(expenses[0].description, "Expense A")
    }
    
    func test_fetchPayments_success() async throws {
        // Given
        mockSupabase.mockPayments = [(1, "Payment A"), (2, "Payment B")]
        
        // When
        let payments = try await api.fetchPayments()
        
        // Then
        XCTAssertEqual(payments.count, 2)
        XCTAssertEqual(payments[0].id, 1)
        XCTAssertEqual(payments[0].description, "Payment A")
    }
    
    func test_fetchPayments_forExpense_success() async throws {
        // Given
        let expenseId = UUID()
        mockSupabase.mockPayments = [(1, "Payment for Expense")]
        
        // When
        let payments = try await api.fetchPayments(forExpenseId: expenseId)
        
        // Then
        XCTAssertEqual(payments.count, 1)
        XCTAssertEqual(payments[0].description, "Payment for Expense")
    }
    
    // MARK: - Error Handling Tests
    
    func test_fetchDocuments_networkError_throwsError() async {
        // Given
        mockSupabase.shouldThrowError = true
        mockSupabase.errorToThrow = NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        // When/Then
        do {
            _ = try await api.fetchDocuments()
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

// MARK: - Mock Supabase Client for Documents

class MockDocumentsSupabaseClient {
    var shouldThrowError = false
    var errorToThrow: Error?
    var deleteSucceeds = true
    var updateSucceeds = true
    
    // Mock data
    var mockDocuments: [Document] = []
    var mockDocument: Document?
    var mockDocumentCounts: [(DocumentType, Int)] = []
    var mockUploadPath: String?
    var mockPublicURL: URL?
    var mockDownloadData: Data?
    var mockVendors: [(id: Int, name: String)] = []
    var mockExpenses: [(id: UUID, description: String)] = []
    var mockPayments: [(id: Int64, description: String)] = []
}

// MARK: - Document Test Helper

extension Document {
    static func makeTest(
        id: UUID = UUID(),
        coupleId: UUID = UUID(),
        fileName: String = "test.pdf",
        filePath: String = "/path/to/file",
        bucketName: String = "wedding-documents",
        documentType: DocumentType = .other,
        vendorId: Int? = nil,
        expenseId: UUID? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> Document {
        Document(
            id: id,
            coupleId: coupleId,
            fileName: fileName,
            filePath: filePath,
            bucketName: bucketName,
            documentType: documentType,
            vendorId: vendorId,
            expenseId: expenseId,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
