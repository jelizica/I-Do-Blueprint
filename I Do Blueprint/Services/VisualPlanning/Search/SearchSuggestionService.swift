//
//  SearchSuggestionService.swift
//  I Do Blueprint
//
//  Provides smart search suggestions
//

import Foundation

/// Service for generating search suggestions
struct SearchSuggestionService {
    
    // MARK: - Public Interface
    
    /// Get search suggestions for a query
    static func getSuggestions(for query: String) -> [String] {
        var suggestions: [String] = []
        
        // Style category suggestions
        let styleMatches = StyleCategory.allCases.filter {
            $0.displayName.localizedCaseInsensitiveContains(query)
        }
        suggestions.append(contentsOf: styleMatches.map(\.displayName))
        
        // Color name suggestions
        let colorNames = [
            "red", "blue", "green", "yellow", "purple", "pink",
            "orange", "black", "white", "gold", "silver"
        ]
        let colorMatches = colorNames.filter { $0.localizedCaseInsensitiveContains(query) }
        suggestions.append(contentsOf: colorMatches)
        
        // Common wedding terms
        let weddingTerms = [
            "romantic", "elegant", "rustic", "modern", "vintage",
            "floral", "natural", "luxurious"
        ]
        let termMatches = weddingTerms.filter { $0.localizedCaseInsensitiveContains(query) }
        suggestions.append(contentsOf: termMatches)
        
        return Array(Set(suggestions)).prefix(5).map { $0 }
    }
}
