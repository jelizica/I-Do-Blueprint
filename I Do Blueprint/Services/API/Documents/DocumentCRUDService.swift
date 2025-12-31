//
//  DocumentCRUDService.swift
//  I Do Blueprint
//
//  CRUD operations for documents
//

import Foundation
import Supabase

/// Service for document CRUD operations
class DocumentCRUDService {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.api
    
    init(supabase: SupabaseClient? = SupabaseManager.shared.client) {
        self.supabase = supabase
    }
    
    private func getClient() throws -> SupabaseClient {
        guard let supabase = supabase else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return supabase
    }
    
    // MARK: - Fetch Operations
    
    func fetchDocuments() async throws -> [Document] {
        let client = try getClient()
        let startTime = Date()
        
        do {
            let response: [Document] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("documents")
                    .select()
                    .order("uploaded_at", ascending: false)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(response.count) documents in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchDocuments", outcome: .success, duration: duration)
            
            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Documents fetch failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchDocuments", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    func fetchDocumentById(_ id: UUID) async throws -> Document {
        let client = try getClient()
        let startTime = Date()
        
        do {
            let response: Document = try await RepositoryNetwork.withRetry {
                try await client
                    .from("documents")
                    .select()
                    .eq("id", value: id)
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched document by ID in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchDocumentById", outcome: .success, duration: duration)
            
            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Document fetch by ID failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchDocumentById", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    func fetchDocumentsByType(_ type: DocumentType) async throws -> [Document] {
        let client = try getClient()
        let startTime = Date()
        
        do {
            let response: [Document] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("documents")
                    .select()
                    .eq("document_type", value: type.rawValue)
                    .order("uploaded_at", ascending: false)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(response.count) documents by type in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchDocumentsByType", outcome: .success, duration: duration)
            
            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Documents fetch by type failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchDocumentsByType", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    func fetchDocumentsByVendor(_ vendorId: Int) async throws -> [Document] {
        let client = try getClient()
        let startTime = Date()
        
        do {
            let response: [Document] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("documents")
                    .select()
                    .eq("vendor_id", value: String(vendorId))
                    .order("uploaded_at", ascending: false)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(response.count) documents by vendor in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchDocumentsByVendor", outcome: .success, duration: duration)
            
            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Documents fetch by vendor failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchDocumentsByVendor", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    func fetchDocumentsByExpense(_ expenseId: UUID) async throws -> [Document] {
        let client = try getClient()
        let startTime = Date()
        
        do {
            let response: [Document] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("documents")
                    .select()
                    .eq("expense_id", value: expenseId)
                    .order("uploaded_at", ascending: false)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(response.count) documents by expense in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchDocumentsByExpense", outcome: .success, duration: duration)
            
            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Documents fetch by expense failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchDocumentsByExpense", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    func fetchDocumentsByBucket(_ bucketName: String) async throws -> [Document] {
        let client = try getClient()
        let startTime = Date()
        
        do {
            let response: [Document] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("documents")
                    .select()
                    .eq("bucket_name", value: bucketName)
                    .order("uploaded_at", ascending: false)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(response.count) documents by bucket in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchDocumentsByBucket", outcome: .success, duration: duration)
            
            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Documents fetch by bucket failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchDocumentsByBucket", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    // MARK: - Create Operation
    
    func createDocument(_ data: DocumentInsertData) async throws -> Document {
        let client = try getClient()
        let startTime = Date()
        
        do {
            let response: Document = try await RepositoryNetwork.withRetry {
                try await client
                    .from("documents")
                    .insert(data)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created document in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "createDocument", outcome: .success, duration: duration)
            
            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Document creation failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "createDocument", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    // MARK: - Update Operation
    
    func updateDocument(
        _ id: UUID,
        fileName: String,
        documentType: DocumentType,
        vendorId: Int?,
        expenseId: UUID?,
        tags: [String]
    ) async throws -> Document {
        struct DocumentUpdate: Encodable {
            let originalFilename: String
            let documentType: String
            let tags: [String]
            let vendorId: Int?
            let expenseId: String?
            
            enum CodingKeys: String, CodingKey {
                case originalFilename = "original_filename"
                case documentType = "document_type"
                case tags
                case vendorId = "vendor_id"
                case expenseId = "expense_id"
            }
        }
        
        let payload = DocumentUpdate(
            originalFilename: fileName,
            documentType: documentType.rawValue,
            tags: tags,
            vendorId: vendorId,
            expenseId: expenseId?.uuidString
        )
        
        let client = try getClient()
        let startTime = Date()
        
        do {
            let response: Document = try await RepositoryNetwork.withRetry {
                try await client
                    .from("documents")
                    .update(payload)
                    .eq("id", value: id)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Document updated successfully in \(String(format: "%.2f", duration))s: \(id.uuidString)")
            AnalyticsService.trackNetwork(operation: "updateDocument", outcome: .success, duration: duration)
            
            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Document update failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "updateDocument", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    // MARK: - Delete Operations
    
    func deleteDocument(_ id: UUID) async throws {
        let client = try getClient()
        let startTime = Date()
        
        do {
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("documents")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted document in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "deleteDocument", outcome: .success, duration: duration)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Document deletion failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "deleteDocument", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    // MARK: - Count Operations
    
    func getDocumentCountByType() async throws -> [(DocumentType, Int)] {
        var counts: [(DocumentType, Int)] = []
        
        for type in DocumentType.allCases {
            let documents = try await fetchDocumentsByType(type)
            counts.append((type, documents.count))
        }
        
        return counts
    }
}
