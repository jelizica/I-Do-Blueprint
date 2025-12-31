//
//  StylePreferencesSearchService.swift
//  I Do Blueprint
//
//  Domain-specific search service for style preferences
//

import Foundation

/// Service responsible for searching and filtering style preferences
actor StylePreferencesSearchService {
    private let supabaseService: SupabaseVisualPlanningService
    private let logger = AppLogger.general
    
    init(supabaseService: SupabaseVisualPlanningService) {
        self.supabaseService = supabaseService
    }
    
    // MARK: - Public Interface
    
    /// Search style preferences with query and filters
    func search(query: String, filters: SearchFilters) async throws -> StylePreferences? {
        let preferences = try await supabaseService.fetchStylePreferences(for: filters.tenantId)
        
        guard let preferences else { return nil }
        
        let matchesText = query.isEmpty ||
            preferences.inspirationKeywords.contains { $0.localizedCaseInsensitiveContains(query) } ||
            preferences.primaryStyle?.displayName.localizedCaseInsensitiveContains(query) == true ||
            preferences.styleInfluences.contains { $0.displayName.localizedCaseInsensitiveContains(query) }
        
        return matchesText ? preferences : nil
    }
}
