//
//  ColorPaletteSearchService.swift
//  I Do Blueprint
//
//  Domain-specific search service for color palettes
//

import Foundation
import SwiftUI

/// Service responsible for searching and filtering color palettes
actor ColorPaletteSearchService {
    private let supabaseService: SupabaseVisualPlanningService
    private let logger = AppLogger.general
    
    init(supabaseService: SupabaseVisualPlanningService) {
        self.supabaseService = supabaseService
    }
    
    // MARK: - Public Interface
    
    /// Search color palettes with query and filters
    func search(query: String, filters: SearchFilters) async throws -> [ColorPalette] {
        let allPalettes = try await supabaseService.fetchColorPalettes(for: filters.tenantId)
        
        return allPalettes.filter { palette in
            matchesCriteria(palette, query: query, filters: filters)
        }
    }
    
    // MARK: - Private Helpers
    
    private func matchesCriteria(_ palette: ColorPalette, query: String, filters: SearchFilters) -> Bool {
        // Text search
        let matchesText = query.isEmpty ||
            palette.name.localizedCaseInsensitiveContains(query) ||
            (palette.description?.localizedCaseInsensitiveContains(query) ?? false)
        
        // Season filter (ColorPalette no longer has season property)
        let matchesSeason = filters.seasons.isEmpty
        
        // Palette type filter (ColorPalette no longer has visibility property)
        let matchesPaletteVisibility = filters.paletteVisibility.isEmpty
        
        // Favorites filter
        let matchesFavorites = !filters.favoritesOnly || palette.isDefault
        
        // Color similarity filter
        let matchesColor = filters.colors.isEmpty ||
            filters.colors.contains { filterColor in
                palette.colors.compactMap { Color.fromHexString($0) }.contains { paletteColor in
                    ColorComparisonHelper.areSimilar(paletteColor, filterColor, threshold: 50)
                }
            }
        
        // Date range filter
        let matchesDateRange: Bool
        if let dateRange = filters.dateRange {
            matchesDateRange = dateRange.contains(palette.createdAt)
        } else {
            matchesDateRange = true
        }
        
        return matchesText && matchesSeason && matchesPaletteVisibility && matchesFavorites && matchesColor &&
            matchesDateRange
    }
}
