//
//  LiveDocumentRepository.swift
//  My Wedding Planning App
//
//  Supabase implementation of document repository
//

import Foundation
import Supabase

/// Supabase implementation of document repository
actor LiveDocumentRepository: DocumentRepositoryProtocol {
    private let client: SupabaseClient?
    private let supabase: SupabaseManager
    private let sessionManager = SessionManager.shared
    private let cacheStrategy = DocumentCacheStrategy()

    init(client: SupabaseClient? = nil) {
        self.client = client
        self.supabase = SupabaseManager.shared
    }

    init() {
        self.client = SupabaseManager.shared.client
        self.supabase = SupabaseManager.shared
    }

    private func getClient() throws -> SupabaseClient {
        guard let client = client else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return client
    }

    private func getTenantId() async throws -> UUID {
        try await TenantContextProvider.shared.requireTenantId()
    }

    // MARK: - Document Operations

    func fetchDocuments() async throws -> [Document] {
        let client = try getClient()
        let tenantId = try await getTenantId()
        return try await RepositoryNetwork.withRetry {
            try await client.database
                .from("documents")
                .select()
                .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
                .order("uploaded_at", ascending: false)
                .execute()
                .value
        }
    }

    func fetchDocuments(type: DocumentType) async throws -> [Document] {
        let client = try getClient()
        let tenantId = try await getTenantId()
        return try await RepositoryNetwork.withRetry {
            try await client.database
                .from("documents")
                .select()
                .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
                .eq("document_type", value: type.rawValue)
                .order("uploaded_at", ascending: false)
                .execute()
                .value
        }
    }

    func fetchDocuments(bucket: DocumentBucket) async throws -> [Document] {
        let client = try getClient()
        let tenantId = try await getTenantId()
        return try await RepositoryNetwork.withRetry {
            try await client.database
                .from("documents")
                .select()
                .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
                .eq("bucket_name", value: bucket.rawValue)
                .order("uploaded_at", ascending: false)
                .execute()
                .value
        }
    }

    func fetchDocuments(vendorId: Int) async throws -> [Document] {
        let client = try getClient()
        let tenantId = try await getTenantId()
        return try await RepositoryNetwork.withRetry {
            try await client.database
                .from("documents")
                .select()
                .eq("couple_id", value: tenantId)  // Explicit filter by couple_id
                .eq("vendor_id", value: vendorId)
                .order("uploaded_at", ascending: false)
                .execute()
                .value
        }
    }

    func fetchDocument(id: UUID) async throws -> Document? {
        let client = try getClient()
        let documents: [Document] = try await RepositoryNetwork.withRetry {
            try await client.database
                .from("documents")
                .select()
                .eq("id", value: id)
                .limit(1)
                .execute()
                .value
        }
        return documents.first
    }

    func createDocument(_ insertData: DocumentInsertData) async throws -> Document {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let document: Document = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("documents")
                    .insert(insertData)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .documentCreated(tenantId: tenantId))
            return document
        } catch {
            await SentryService.shared.captureError(error, context: [
                "operation": "createDocument",
                "repository": "LiveDocumentRepository"
            ])
            throw DocumentError.createFailed(underlying: error)
        }
    }

    func updateDocument(_ document: Document) async throws -> Document {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let updated: Document = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("documents")
                    .update(document)
                    .eq("id", value: document.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            // Invalidate caches via strategy
            await cacheStrategy.invalidate(for: .documentUpdated(tenantId: tenantId))
            return updated
        } catch {
            await SentryService.shared.captureError(error, context: [
                "operation": "updateDocument",
                "repository": "LiveDocumentRepository",
                "documentId": document.id.uuidString
            ])
            throw DocumentError.updateFailed(underlying: error)
        }
    }

    func deleteDocument(id: UUID) async throws {
        do {
            let client = try getClient()
            // First get the document to know the storage path
            guard let document = try await fetchDocument(id: id) else {
                throw DocumentError.notFound(id: id)
            }

            // Delete from storage (30s timeout for storage operations)
            try await RepositoryNetwork.withRetry(timeout: 30) {
                try await client.storage
                    .from(document.bucketName)
                    .remove(paths: [document.storagePath])
            }

            // Delete database record
            try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("documents")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }
            // Invalidate caches via strategy
            let tenantId = try await getTenantId()
            await cacheStrategy.invalidate(for: .documentDeleted(tenantId: tenantId))
        } catch let error as DocumentError {
            throw error
        } catch {
            await SentryService.shared.captureError(error, context: [
                "operation": "deleteDocument",
                "repository": "LiveDocumentRepository",
                "documentId": id.uuidString
            ])
            throw DocumentError.deleteFailed(underlying: error)
        }
    }

    func batchDeleteDocuments(ids: [UUID]) async throws {
        do {
            let client = try getClient()
            // Fetch all documents to get storage paths
            let documents = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("documents")
                    .select()
                    .in("id", values: ids)
                    .execute()
                    .value as [Document]
            }

            // Group by bucket for efficient deletion
            let documentsByBucket = Dictionary(grouping: documents, by: \.bucketName)

            // Delete from storage by bucket (30s timeout for storage operations)
            for (bucketName, bucketDocuments) in documentsByBucket {
                let paths = bucketDocuments.map(\.storagePath)
                try await RepositoryNetwork.withRetry(timeout: 30) {
                    try await client.storage
                        .from(bucketName)
                        .remove(paths: paths)
                }
            }

            // Delete database records
            try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("documents")
                    .delete()
                    .in("id", values: ids)
                    .execute()
            }
        } catch {
            await SentryService.shared.captureError(error, context: [
                "operation": "batchDeleteDocuments",
                "repository": "LiveDocumentRepository",
                "count": ids.count
            ])
            throw DocumentError.deleteFailed(underlying: error)
        }
    }

    func updateDocumentTags(id: UUID, tags: [String]) async throws -> Document {
        do {
            let client = try getClient()
            let updated: Document = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("documents")
                    .update(["tags": tags])
                    .eq("id", value: id)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            return updated
        } catch {
            await SentryService.shared.captureError(error, context: [
                "operation": "updateDocumentTags",
                "repository": "LiveDocumentRepository",
                "documentId": id.uuidString
            ])
            throw DocumentError.updateFailed(underlying: error)
        }
    }

    func updateDocumentType(id: UUID, type: DocumentType) async throws -> Document {
        do {
            let client = try getClient()
            let updated: Document = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("documents")
                    .update(["document_type": type.rawValue])
                    .eq("id", value: id)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            return updated
        } catch {
            await SentryService.shared.captureError(error, context: [
                "operation": "updateDocumentType",
                "repository": "LiveDocumentRepository",
                "documentId": id.uuidString,
                "type": type.rawValue
            ])
            throw DocumentError.updateFailed(underlying: error)
        }
    }

    // MARK: - Search Operations

    func searchDocuments(query: String) async throws -> [Document] {
        let client = try getClient()
        return try await RepositoryNetwork.withRetry {
            try await client.database
                .from("documents")
                .select()
                .ilike("original_filename", pattern: "%\(query)%")
                .order("uploaded_at", ascending: false)
                .execute()
                .value
        }
    }

    func fetchAllTags() async throws -> [String] {
        let documents: [Document] = try await fetchDocuments()
        let allTags = documents.flatMap(\.tags)
        return Array(Set(allTags)).sorted()
    }

    // MARK: - Storage Operations

    func uploadDocument(
        fileData: Data,
        metadata: FileUploadMetadata,
        coupleId: UUID) async throws -> Document {
        do {
            let client = try getClient()
            // Generate unique storage path
            let timestamp = Int(Date().timeIntervalSince1970)

            // Sanitize filename: replace spaces and remove/replace invalid characters
            // Supabase Storage doesn't allow: [ ] { } < > # % " ' ` ^ | \ and some others
            var sanitizedFilename = metadata.fileName
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "[", with: "(")
                .replacingOccurrences(of: "]", with: ")")
                .replacingOccurrences(of: "{", with: "(")
                .replacingOccurrences(of: "}", with: ")")
                .replacingOccurrences(of: "#", with: "-")
                .replacingOccurrences(of: "%", with: "-")
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "'", with: "")
                .replacingOccurrences(of: "`", with: "")
                .replacingOccurrences(of: "^", with: "")
                .replacingOccurrences(of: "|", with: "-")
                .replacingOccurrences(of: "\\", with: "-")
                .replacingOccurrences(of: "<", with: "")
                .replacingOccurrences(of: ">", with: "")

            let storagePath = "\(coupleId)/\(timestamp)_\(sanitizedFilename)"

            // Upload to storage (30s timeout for storage operations)
            try await RepositoryNetwork.withRetry(timeout: 30) {
                try await client.storage
                    .from(metadata.bucket.rawValue)
                    .upload(
                        path: storagePath,
                        file: fileData,
                        options: FileOptions(
                            cacheControl: "3600",
                            contentType: metadata.mimeType))
            }

            // Get user email from auth context
            let authContext = await AuthContext.shared
            let userEmail = try await authContext.requireUserEmail()

            // Create document record
            let insertData = DocumentInsertData(
                coupleId: coupleId,
                originalFilename: metadata.fileName,
                storagePath: storagePath,
                fileSize: metadata.fileSize,
                mimeType: metadata.mimeType,
                documentType: metadata.documentType,
                bucketName: metadata.bucket.rawValue,
                vendorId: metadata.vendorId,
                expenseId: metadata.expenseId,
                tags: metadata.tags,
                uploadedBy: userEmail
            )

            return try await createDocument(insertData)
        } catch {
            throw DocumentError.uploadFailed(underlying: error)
        }
    }

    func downloadDocument(document: Document) async throws -> Data {
        let client = try getClient()
        return try await RepositoryNetwork.withRetry(timeout: 30) {
            try await client.storage
                .from(document.bucketName)
                .download(path: document.storagePath)
        }
    }

    func getPublicURL(for document: Document) async throws -> URL {
        let client = try getClient()
        return try client.storage
            .from(document.bucketName)
            .getPublicURL(path: document.storagePath)
    }
}

// MARK: - Document Errors
// DocumentError enum is now defined in Domain/Models/Document/DocumentError.swift
