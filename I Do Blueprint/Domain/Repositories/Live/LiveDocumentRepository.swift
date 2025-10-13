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
    private let client = SupabaseManager.shared.client
    private let supabase = SupabaseManager.shared

    // MARK: - Document Operations

    func fetchDocuments() async throws -> [Document] {
        return try await RepositoryNetwork.withRetry {
            try await self.client.database
                .from("documents")
                .select()
                .order("uploaded_at", ascending: false)
                .execute()
                .value
        }
    }

    func fetchDocuments(type: DocumentType) async throws -> [Document] {
        return try await RepositoryNetwork.withRetry {
            try await self.client.database
                .from("documents")
                .select()
                .eq("document_type", value: type.rawValue)
                .order("uploaded_at", ascending: false)
                .execute()
                .value
        }
    }

    func fetchDocuments(bucket: DocumentBucket) async throws -> [Document] {
        return try await RepositoryNetwork.withRetry {
            try await self.client.database
                .from("documents")
                .select()
                .eq("bucket_name", value: bucket.rawValue)
                .order("uploaded_at", ascending: false)
                .execute()
                .value
        }
    }

    func fetchDocuments(vendorId: Int) async throws -> [Document] {
        return try await RepositoryNetwork.withRetry {
            try await self.client.database
                .from("documents")
                .select()
                .eq("vendor_id", value: vendorId)
                .order("uploaded_at", ascending: false)
                .execute()
                .value
        }
    }

    func fetchDocument(id: UUID) async throws -> Document? {
        let documents: [Document] = try await RepositoryNetwork.withRetry {
            try await self.client.database
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
        return try await RepositoryNetwork.withRetry {
            try await self.client.database
                .from("documents")
                .insert(insertData)
                .select()
                .single()
                .execute()
                .value
        }
    }

    func updateDocument(_ document: Document) async throws -> Document {
        return try await RepositoryNetwork.withRetry {
            try await self.client.database
                .from("documents")
                .update(document)
                .eq("id", value: document.id)
                .select()
                .single()
                .execute()
                .value
        }
    }

    func deleteDocument(id: UUID) async throws {
        // First get the document to know the storage path
        guard let document = try await fetchDocument(id: id) else {
            throw DocumentError.notFound(id: id)
        }

        // Delete from storage (30s timeout for storage operations)
        try await RepositoryNetwork.withRetry(timeout: 30) {
            try await self.client.storage
                .from(document.bucketName)
                .remove(paths: [document.storagePath])
        }

        // Delete database record
        try await RepositoryNetwork.withRetry {
            try await self.client.database
                .from("documents")
                .delete()
                .eq("id", value: id)
                .execute()
        }
    }

    func batchDeleteDocuments(ids: [UUID]) async throws {
        // Fetch all documents to get storage paths
        let documents = try await RepositoryNetwork.withRetry {
            try await self.client.database
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
                try await self.client.storage
                    .from(bucketName)
                    .remove(paths: paths)
            }
        }

        // Delete database records
        try await RepositoryNetwork.withRetry {
            try await self.client.database
                .from("documents")
                .delete()
                .in("id", values: ids)
                .execute()
        }
    }

    func updateDocumentTags(id: UUID, tags: [String]) async throws -> Document {
        return try await RepositoryNetwork.withRetry {
            try await self.client.database
                .from("documents")
                .update(["tags": tags])
                .eq("id", value: id)
                .select()
                .single()
                .execute()
                .value
        }
    }

    func updateDocumentType(id: UUID, type: DocumentType) async throws -> Document {
        return try await RepositoryNetwork.withRetry {
            try await self.client.database
                .from("documents")
                .update(["document_type": type.rawValue])
                .eq("id", value: id)
                .select()
                .single()
                .execute()
                .value
        }
    }

    // MARK: - Search Operations

    func searchDocuments(query: String) async throws -> [Document] {
        return try await RepositoryNetwork.withRetry {
            try await self.client.database
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
        // Generate unique storage path
        let timestamp = Int(Date().timeIntervalSince1970)
        let sanitizedFilename = metadata.fileName.replacingOccurrences(of: " ", with: "_")
        let storagePath = "\(coupleId)/\(timestamp)_\(sanitizedFilename)"

        // Upload to storage (30s timeout for storage operations)
        try await RepositoryNetwork.withRetry(timeout: 30) {
            try await self.client.storage
                .from(metadata.bucket.rawValue)
                .upload(
                    path: storagePath,
                    file: fileData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: metadata.mimeType))
        }

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
            uploadedBy: "user" // TODO: Get from auth context
        )

        return try await createDocument(insertData)
    }

    func downloadDocument(document: Document) async throws -> Data {
        return try await RepositoryNetwork.withRetry(timeout: 30) {
            try await self.client.storage
                .from(document.bucketName)
                .download(path: document.storagePath)
        }
    }

    func getPublicURL(for document: Document) async throws -> URL {
        return try client.storage
            .from(document.bucketName)
            .getPublicURL(path: document.storagePath)
    }
}

// MARK: - Document Errors
// DocumentError enum is now defined in Domain/Models/Document/DocumentError.swift
