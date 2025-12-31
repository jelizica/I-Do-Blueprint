//
//  DocumentSearchService.swift
//  I Do Blueprint
//
//  Document search operations
//

import Foundation
import Supabase

/// Service for document search operations
class DocumentSearchService {
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
    
    func searchDocuments(query: String) async throws -> [Document] {
        let client = try getClient()
        let startTime = Date()
        
        do {
            let response: [Document] = try await RepositoryNetwork.withRetry {
                try await client
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
}
