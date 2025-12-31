//
//  MoodBoardSearchService.swift
//  I Do Blueprint
//
//  Domain-specific search service for mood boards
//

import Foundation
import SwiftUI

/// Service responsible for searching and filtering mood boards
actor MoodBoardSearchService {
    private let supabaseService: SupabaseVisualPlanningService
    private let logger = AppLogger.general
    
    init(supabaseService: SupabaseVisualPlanningService) {
        self.supabaseService = supabaseService
    }
    
    // MARK: - Public Interface
    
    /// Search mood boards with query and filters
    func search(query: String, filters: SearchFilters) async throws -> [MoodBoard] {
        let allMoodBoards = try await supabaseService.fetchMoodBoards(for: filters.tenantId)
        
        return allMoodBoards.filter { moodBoard in
            matchesCriteria(moodBoard, query: query, filters: filters)
        }
    }
    
    // MARK: - Private Helpers
    
    private func matchesCriteria(_ moodBoard: MoodBoard, query: String, filters: SearchFilters) -> Bool {
        // Text search
        let matchesText = query.isEmpty ||
            moodBoard.boardName.localizedCaseInsensitiveContains(query) ||
            (moodBoard.boardDescription?.localizedCaseInsensitiveContains(query) ?? false) ||
            moodBoard.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        
        // Style filter
        let matchesStyle = filters.styleCategories.isEmpty ||
            filters.styleCategories.contains(moodBoard.styleCategory)
        
        // Date range filter
        let matchesDateRange: Bool
        if let dateRange = filters.dateRange {
            matchesDateRange = dateRange.contains(moodBoard.createdAt)
        } else {
            matchesDateRange = true
        }
        
        // Template filter
        let matchesTemplate = !filters.showTemplatesOnly || moodBoard.isTemplate
        
        // Color filter (if mood board contains elements with matching colors)
        let matchesColor = filters.colors.isEmpty ||
            moodBoard.elements.contains { element in
                if let elementColor = element.elementData.color {
                    return filters.colors.contains { filterColor in
                        ColorComparisonHelper.areSimilar(elementColor, filterColor, threshold: 50)
                    }
                }
                return false
            }
        
        return matchesText && matchesStyle && matchesDateRange && matchesTemplate && matchesColor
    }
}
