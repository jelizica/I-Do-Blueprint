//
//  DocumentsAPI.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Foundation
import Supabase

class DocumentsAPI {
    private let supabase: SupabaseClient
    private let logger = AppLogger.api

    init(supabase: SupabaseClient = SupabaseManager.shared.client) {
        self.supabase = supabase
    }

    // MARK: - Fetch Documents

    func fetchDocuments() async throws -> [Document] {
        let startTime = Date()

        do {
            let response: [Document] = try await RepositoryNetwork.withRetry {
                try await self.supabase
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
        let startTime = Date()

        do {
            let response: Document = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("documents")
                    .select()
                    .eq("id", value: id.uuidString)
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
        let startTime = Date()

        do {
            let response: [Document] = try await RepositoryNetwork.withRetry {
                try await self.supabase
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
        let startTime = Date()

        do {
            let response: [Document] = try await RepositoryNetwork.withRetry {
                try await self.supabase
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
        let startTime = Date()

        do {
            let response: [Document] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("documents")
                    .select()
                    .eq("expense_id", value: expenseId.uuidString)
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
        let startTime = Date()

        do {
            let response: [Document] = try await RepositoryNetwork.withRetry {
                try await self.supabase
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

    // MARK: - Create Document

    func createDocument(_ data: DocumentInsertData) async throws -> Document {
        let startTime = Date()

        do {
            let response: Document = try await RepositoryNetwork.withRetry {
                try await self.supabase
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

    // MARK: - Update Document

    func updateDocument(
        _ id: UUID,
        fileName: String,
        documentType: DocumentType,
        vendorId: Int?,
        expenseId: UUID?,
        tags: [String]) async throws -> Document {

        // Build update payload
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

        let startTime = Date()

        do {
            // Use Supabase SDK with user's auth token (RLS will apply)
            let response: Document = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("documents")
                    .update(payload)
                    .eq("id", value: id.uuidString)
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

    // MARK: - Delete Document

    func deleteDocument(_ id: UUID) async throws {
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("documents")
                    .delete()
                    .eq("id", value: id.uuidString)
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

    func deleteDocumentWithFile(_ document: Document) async throws {
        let startTime = Date()

        do {
            // First delete the file from storage (with 30s timeout for storage)
            try await RepositoryNetwork.withRetry(timeout: 30) {
                try await self.deleteFile(bucketName: document.bucketName, path: document.storagePath)
            }

            // Then delete the database record
            try await deleteDocument(document.id)

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

    // MARK: - Storage Operations

    func uploadFile(localURL: URL, bucketName: String, fileName: String) async throws -> String {
        let startTime = Date()

        // Read file data
        let fileData = try Data(contentsOf: localURL)

        // Generate unique file path
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueFileName = "\(timestamp)_\(fileName)"
        let filePath = uniqueFileName

        do {
            // Upload to Supabase storage with retry
            try await RepositoryNetwork.withRetry(timeout: 30) {
                try await self.supabase.storage
                    .from(bucketName)
                    .upload(path: filePath, file: fileData, options: FileOptions(contentType: nil))
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Uploaded file \(fileName) in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "uploadFile", outcome: .success, duration: duration)

            // Return the file path
            return filePath
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("File upload failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "uploadFile", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func getPublicURL(bucketName: String, path: String) throws -> URL {
        let url = try supabase.storage
            .from(bucketName)
            .getPublicURL(path: path)

        return url
    }

    func downloadFile(bucketName: String, path: String) async throws -> Data {
        let startTime = Date()

        do {
            let data = try await RepositoryNetwork.withRetry(timeout: 30) {
                try await self.supabase.storage
                    .from(bucketName)
                    .download(path: path)
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Downloaded file in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "downloadFile", outcome: .success, duration: duration)

            return data
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("File download failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "downloadFile", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func deleteFile(bucketName: String, path: String) async throws {
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry(timeout: 30) {
                try await self.supabase.storage
                    .from(bucketName)
                    .remove(paths: [path])
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted file from storage in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "deleteFile", outcome: .success, duration: duration)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("File deletion failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "deleteFile", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    // MARK: - Search Documents

    func searchDocuments(query: String) async throws -> [Document] {
        let startTime = Date()

        do {
            let response: [Document] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("documents")
                    .select()
                    .or("file_name.ilike.%\(query)%,notes.ilike.%\(query)%")
                    .order("uploaded_at", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Searched documents, found \(response.count) results in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "searchDocuments", outcome: .success, duration: duration)

            return response
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Document search failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "searchDocuments", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    // MARK: - Batch Operations

    func batchDeleteDocuments(_ ids: [UUID]) async throws {
        for id in ids {
            // Fetch document first to get file path
            let document = try await fetchDocumentById(id)

            // Delete file and record
            try await deleteDocumentWithFile(document)
        }
    }

    func batchUpdateTags(_ ids: [UUID], addTags: [String] = [], removeTags: [String] = []) async throws {
        for id in ids {
            let document = try await fetchDocumentById(id)
            var updatedTags = document.tags

            // Add new tags
            for tag in addTags {
                if !updatedTags.contains(tag) {
                    updatedTags.append(tag)
                }
            }

            // Remove tags
            updatedTags.removeAll { removeTags.contains($0) }

            // Update document - pass all current values plus updated tags
            _ = try await updateDocument(
                id,
                fileName: document.originalFilename,
                documentType: document.documentType,
                vendorId: document.vendorId,
                expenseId: document.expenseId,
                tags: updatedTags)
        }
    }

    func batchUpdateType(_ ids: [UUID], type: DocumentType) async throws {
        for id in ids {
            let document = try await fetchDocumentById(id)

            // Update document - pass all current values plus updated type
            _ = try await updateDocument(
                id,
                fileName: document.originalFilename,
                documentType: type,
                vendorId: document.vendorId,
                expenseId: document.expenseId,
                tags: document.tags)
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

    // MARK: - Related Entities

    func fetchVendors() async throws -> [(id: Int, name: String)] {
        struct VendorResult: Decodable {
            let id: Int64
            let vendorName: String

            enum CodingKeys: String, CodingKey {
                case id
                case vendorName = "vendor_name"
            }
        }

        let startTime = Date()

        do {
            let vendors: [VendorResult] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("vendorInformation")
                    .select("id, vendor_name")
                    .order("vendor_name", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(vendors.count) vendors in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchVendors", outcome: .success, duration: duration)

            return vendors.map { (id: Int($0.id), name: $0.vendorName) }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Vendors fetch failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchVendors", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchExpenses() async throws -> [(id: UUID, description: String)] {
        struct ExpenseResult: Decodable {
            let id: UUID
            let expenseName: String

            enum CodingKeys: String, CodingKey {
                case id
                case expenseName = "expense_name"
            }
        }

        let startTime = Date()

        do {
            let expenses: [ExpenseResult] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("expenses")
                    .select("id, expense_name")
                    .order("expense_name", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(expenses.count) expenses in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchExpenses", outcome: .success, duration: duration)

            return expenses.map { (id: $0.id, description: $0.expenseName) }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Expenses fetch failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchExpenses", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchPayments(forExpenseId expenseId: UUID? = nil) async throws -> [(id: Int64, description: String)] {
        struct PaymentResult: Decodable {
            let id: Int64
            let vendor: String
            let paymentAmount: Double
            let paymentDate: String
            let paid: Bool
            let expenseId: UUID?

            enum CodingKeys: String, CodingKey {
                case id
                case vendor
                case paymentAmount = "payment_amount"
                case paymentDate = "payment_date"
                case paid
                case expenseId = "expense_id"
            }
        }

        let startTime = Date()

        do {
            var query = supabase
                .from("payment_plan_details_with_expenses")
                .select("id, vendor, payment_amount, payment_date, paid, expense_id")

            // Filter by expense if provided
            if let expenseId {
                query = query.eq("expense_id", value: expenseId.uuidString)
            }

            let payments: [PaymentResult] = try await RepositoryNetwork.withRetry {
                try await query
                    .order("payment_date", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(payments.count) payments in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchPayments", outcome: .success, duration: duration)

            return payments.map {
                let formattedAmount = String(format: "$%.2f", $0.paymentAmount)
                let status = $0.paid ? "✓" : "○"
                return (id: $0.id, description: "\($0.vendor) - \(formattedAmount) (\($0.paymentDate)) \(status)")
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Payments fetch failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchPayments", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
}

// MARK: - API Errors

enum DocumentsAPIError: LocalizedError {
    case invalidURL
    case fileNotFound
    case uploadFailed
    case downloadFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid file URL"
        case .fileNotFound:
            "File not found"
        case .uploadFailed:
            "Failed to upload file"
        case .downloadFailed:
            "Failed to download file"
        case .deleteFailed:
            "Failed to delete file"
        }
    }
}
