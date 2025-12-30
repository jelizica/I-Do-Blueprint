//
//  DocumentUploadStore.swift
//  I Do Blueprint
//
//  Sub-store for document upload operations
//  Extracted from DocumentStoreV2 as part of architecture improvement plan
//

import Foundation
import Combine
import Dependencies

/// Sub-store handling document upload operations
@MainActor
class DocumentUploadStore: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published private(set) var lastUploadError: DocumentError?
    
    @Dependency(\.documentRepository) var repository
    
    // MARK: - Upload Operations
    
    /// Upload a document with file data and metadata
    func uploadDocument(
        fileData: Data,
        metadata: FileUploadMetadata,
        coupleId: UUID
    ) async throws -> Document {
        isUploading = true
        uploadProgress = 0
        lastUploadError = nil
        
        defer {
            isUploading = false
        }
        
        do {
            let document = try await repository.uploadDocument(
                fileData: fileData,
                metadata: metadata,
                coupleId: coupleId
            )
            
            uploadProgress = 1.0
            AppLogger.ui.info("Document uploaded successfully: \(document.originalFilename)")
            return document
        } catch {
            AppLogger.ui.error("Failed to upload document", error: error)
            
            await handleError(error, operation: "uploadDocument", context: [
                "fileName": metadata.fileName,
                "fileSize": fileData.count
            ]) { [weak self] in
                guard let self = self else { return }
                _ = try? await self.uploadDocument(fileData: fileData, metadata: metadata, coupleId: coupleId)
            }
            
            let docError = DocumentError.uploadFailed(underlying: error)
            lastUploadError = docError
            throw docError
        }
    }
    
    /// Upload a file from a local URL with security-scoped resource handling
    func uploadFile(
        metadata: FileUploadMetadata,
        coupleId: UUID,
        uploadedBy: String
    ) async throws -> Document {
        // Start accessing security-scoped resource
        let didStartAccessing = metadata.localURL.startAccessingSecurityScopedResource()
        
        defer {
            // Always stop accessing when done
            if didStartAccessing {
                metadata.localURL.stopAccessingSecurityScopedResource()
            }
        }
        
        // Read file data directly from the file system
        let fileData: Data
        do {
            fileData = try Data(contentsOf: metadata.localURL)
            AppLogger.ui.info("Successfully read file data: \(metadata.fileName), size: \(fileData.count) bytes")
        } catch {
            AppLogger.ui.error("Failed to read file data from: \(metadata.localURL.path)", error: error)
            
            await handleError(error, operation: "uploadFile", context: [
                "fileName": metadata.fileName,
                "filePath": metadata.localURL.path
            ])
            
            throw NSError(
                domain: "DocumentUploadStore",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to read file data: \(error.localizedDescription)"]
            )
        }
        
        return try await uploadDocument(
            fileData: fileData,
            metadata: metadata,
            coupleId: coupleId
        )
    }
    
    /// Reset upload state
    func resetUploadState() {
        isUploading = false
        uploadProgress = 0
        lastUploadError = nil
    }
}
