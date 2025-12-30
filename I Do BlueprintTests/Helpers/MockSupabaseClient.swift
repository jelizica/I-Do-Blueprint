//
//  MockSupabaseClient.swift
//  I Do BlueprintTests
//
//  Mock Supabase client implementations for API testing
//

import Foundation
import Supabase
@testable import I_Do_Blueprint

// MARK: - Supabase Client Protocol

/// Protocol defining the Supabase client interface needed by API classes
/// This allows for dependency injection and testing with mocks
protocol SupabaseClientProtocol {
    var database: DatabaseClient { get }
    var storage: StorageClient { get }
}

// MARK: - Real Supabase Client Wrapper

/// Wrapper for the real SupabaseClient that conforms to our protocol
class RealSupabaseClientWrapper: SupabaseClientProtocol {
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    var database: DatabaseClient {
        DatabaseClient(client: client)
    }
    
    var storage: StorageClient {
        StorageClient(client: client)
    }
}

// MARK: - Database Client

/// Wrapper for database operations
class DatabaseClient {
    private let client: SupabaseClient?
    private var mockQueryBuilder: MockQueryBuilder?
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    init(mockQueryBuilder: MockQueryBuilder) {
        self.client = nil
        self.mockQueryBuilder = mockQueryBuilder
    }
    
    func from(_ table: String) -> QueryBuilder {
        if let mock = mockQueryBuilder {
            return QueryBuilder(mockBuilder: mock)
        }
        // In real implementation, this would use the actual Supabase client
        fatalError("Real Supabase client not implemented in test wrapper")
    }
}

// MARK: - Storage Client

/// Wrapper for storage operations
class StorageClient {
    private let client: SupabaseClient?
    private var mockStorageOperations: MockStorageOperations?
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    init(mockOperations: MockStorageOperations) {
        self.client = nil
        self.mockStorageOperations = mockOperations
    }
    
    func from(_ bucket: String) -> BucketOperations {
        if let mock = mockStorageOperations {
            return BucketOperations(mockOperations: mock, bucket: bucket)
        }
        fatalError("Real Supabase client not implemented in test wrapper")
    }
}

// MARK: - Query Builder

/// Wrapper for query building operations
class QueryBuilder {
    private var mockBuilder: MockQueryBuilder?
    
    init(mockBuilder: MockQueryBuilder) {
        self.mockBuilder = mockBuilder
    }
    
    func select(_ columns: String = "*") -> QueryBuilder {
        mockBuilder?.select(columns)
        return self
    }
    
    func eq(_ column: String, value: Any) -> QueryBuilder {
        mockBuilder?.eq(column, value: value)
        return self
    }
    
    func order(_ column: String, ascending: Bool = true) -> QueryBuilder {
        mockBuilder?.order(column, ascending: ascending)
        return self
    }
    
    func insert<T: Encodable>(_ value: T) -> QueryBuilder {
        mockBuilder?.insert(value)
        return self
    }
    
    func update<T: Encodable>(_ value: T) -> QueryBuilder {
        mockBuilder?.update(value)
        return self
    }
    
    func delete() -> QueryBuilder {
        mockBuilder?.delete()
        return self
    }
    
    func execute<T: Decodable>() async throws -> QueryResponse<T> {
        guard let mock = mockBuilder else {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock not configured"])
        }
        return try await mock.execute()
    }
}

// MARK: - Bucket Operations

/// Wrapper for storage bucket operations
class BucketOperations {
    private var mockOperations: MockStorageOperations?
    private let bucket: String
    
    init(mockOperations: MockStorageOperations, bucket: String) {
        self.mockOperations = mockOperations
        self.bucket = bucket
    }
    
    func upload(path: String, file: Data) async throws -> String {
        guard let mock = mockOperations else {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock not configured"])
        }
        return try await mock.upload(bucket: bucket, path: path, file: file)
    }
    
    func download(path: String) async throws -> Data {
        guard let mock = mockOperations else {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock not configured"])
        }
        return try await mock.download(bucket: bucket, path: path)
    }
    
    func remove(paths: [String]) async throws {
        guard let mock = mockOperations else {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock not configured"])
        }
        try await mock.remove(bucket: bucket, paths: paths)
    }
    
    func getPublicURL(path: String) throws -> URL {
        guard let mock = mockOperations else {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock not configured"])
        }
        return try mock.getPublicURL(bucket: bucket, path: path)
    }
}

// MARK: - Query Response

/// Response wrapper for query results
struct QueryResponse<T: Decodable> {
    let value: T
}

// MARK: - Mock Query Builder

/// Mock implementation of query builder for testing
class MockQueryBuilder {
    var shouldThrowError = false
    var errorToThrow: Error?
    var mockData: Any?
    
    private var selectedColumns: String = "*"
    private var filters: [(column: String, value: Any)] = []
    private var orderColumn: String?
    private var orderAscending: Bool = true
    private var insertData: Any?
    private var updateData: Any?
    private var isDelete: Bool = false
    
    func select(_ columns: String) {
        selectedColumns = columns
    }
    
    func eq(_ column: String, value: Any) {
        filters.append((column, value))
    }
    
    func order(_ column: String, ascending: Bool) {
        orderColumn = column
        orderAscending = ascending
    }
    
    func insert<T: Encodable>(_ value: T) {
        insertData = value
    }
    
    func update<T: Encodable>(_ value: T) {
        updateData = value
    }
    
    func delete() {
        isDelete = true
    }
    
    func execute<T: Decodable>() async throws -> QueryResponse<T> {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        guard let data = mockData as? T else {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock data type mismatch"])
        }
        
        return QueryResponse(value: data)
    }
}

// MARK: - Mock Storage Operations

/// Mock implementation of storage operations for testing
class MockStorageOperations {
    var shouldThrowError = false
    var errorToThrow: Error?
    var mockUploadPath: String?
    var mockDownloadData: Data?
    var mockPublicURL: URL?
    var deleteSucceeds = true
    
    func upload(bucket: String, path: String, file: Data) async throws -> String {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }
        return mockUploadPath ?? path
    }
    
    func download(bucket: String, path: String) async throws -> Data {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Download failed"])
        }
        guard let data = mockDownloadData else {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock data configured"])
        }
        return data
    }
    
    func remove(bucket: String, paths: [String]) async throws {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        }
        if !deleteSucceeds {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Delete not allowed"])
        }
    }
    
    func getPublicURL(bucket: String, path: String) throws -> URL {
        if shouldThrowError {
            throw errorToThrow ?? NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Get URL failed"])
        }
        guard let url = mockPublicURL else {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock URL configured"])
        }
        return url
    }
}

// MARK: - Base Mock Supabase Client

/// Base mock Supabase client that can be subclassed for specific API tests
class BaseMockSupabaseClient: SupabaseClientProtocol {
    let mockQueryBuilder: MockQueryBuilder
    let mockStorageOperations: MockStorageOperations
    
    var shouldThrowError: Bool {
        get { mockQueryBuilder.shouldThrowError }
        set {
            mockQueryBuilder.shouldThrowError = newValue
            mockStorageOperations.shouldThrowError = newValue
        }
    }
    
    var errorToThrow: Error? {
        get { mockQueryBuilder.errorToThrow }
        set {
            mockQueryBuilder.errorToThrow = newValue
            mockStorageOperations.errorToThrow = newValue
        }
    }
    
    var deleteSucceeds: Bool {
        get { mockStorageOperations.deleteSucceeds }
        set { mockStorageOperations.deleteSucceeds = newValue }
    }
    
    init() {
        self.mockQueryBuilder = MockQueryBuilder()
        self.mockStorageOperations = MockStorageOperations()
    }
    
    var database: DatabaseClient {
        DatabaseClient(mockQueryBuilder: mockQueryBuilder)
    }
    
    var storage: StorageClient {
        StorageClient(mockOperations: mockStorageOperations)
    }
}
