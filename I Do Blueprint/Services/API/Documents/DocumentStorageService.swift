//
//  DocumentStorageService.swift
//  I Do Blueprint
//
//  File storage operations (upload, download, delete)
//

import Foundation
import Supabase

/// Service for document storage operations
class DocumentStorageService {
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
    
    // MARK: - Upload
    
    func uploadFile(localURL: URL, bucketName: String, fileName: String) async throws -> String {
        let client = try getClient()
        let startTime = Date()
        
        // Read file data
        let fileData = try Data(contentsOf: localURL)
        
        // Generate unique file path
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueFileName = "\(timestamp)_\(fileName)"
        let filePath = uniqueFileName
        
        do {
            try await RepositoryNetwork.withRetry(timeout: 30) {
                try await client.storage
                    .from(bucketName)
                    .upload(path: filePath, file: fileData, options: FileOptions(contentType: nil))
            }
            
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Uploaded file \(fileName) in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "uploadFile", outcome: .success, duration: duration)
            
            return filePath
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("File upload failed after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "uploadFile", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    // MARK: - Download
    
    func downloadFile(bucketName: String, path: String) async throws -> Data {
        let client = try getClient()
        let startTime = Date()
        
        do {
            let data = try await RepositoryNetwork.withRetry(timeout: 30) {
                try await client.storage
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
    
    // MARK: - Public URL
    
    func getPublicURL(bucketName: String, path: String) throws -> URL {
        let client = try getClient()
        let url = try client.storage
            .from(bucketName)
            .getPublicURL(path: path)
        
        return url
    }
    
    // MARK: - Delete
    
    func deleteFile(bucketName: String, path: String) async throws {
        let client = try getClient()
        let startTime = Date()
        
        do {
            try await RepositoryNetwork.withRetry(timeout: 30) {
                try await client.storage
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
}

// MARK: - Storage Errors

enum DocumentStorageError: LocalizedError {
    case invalidURL
    case fileNotFound
    case uploadFailed
    case downloadFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid file URL"
        case .fileNotFound: return "File not found"
        case .uploadFailed: return "Failed to upload file"
        case .downloadFailed: return "Failed to download file"
        case .deleteFailed: return "Failed to delete file"
        }
    }
}
