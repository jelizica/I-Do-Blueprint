//
//  SearchResultTransformer.swift
//  I Do Blueprint
//
//  Transforms and sorts search results by relevance
//

import Foundation

/// Service responsible for transforming and sorting search results
struct SearchResultTransformer {
    
    // MARK: - Public Interface
    
    /// Sort search results by relevance to query
    static func sortByRelevance(_ results: inout SearchResults, query: String) {
        results.moodBoards = results.moodBoards.sorted {
            calculateRelevance($0.boardName, to: query) > calculateRelevance($1.boardName, to: query)
        }
        
        results.colorPalettes = results.colorPalettes.sorted {
            calculateRelevance($0.name, to: query) > calculateRelevance($1.name, to: query)
        }
        
        results.seatingCharts = results.seatingCharts.sorted {
            calculateRelevance($0.chartName, to: query) > calculateRelevance($1.chartName, to: query)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Calculate relevance score for text compared to query
    private static func calculateRelevance(_ text: String, to query: String) -> Double {
        let lowercaseText = text.lowercased()
        let lowercaseQuery = query.lowercased()
        
        // Exact match
        if lowercaseText == lowercaseQuery { return 1.0 }
        
        // Prefix match
        if lowercaseText.hasPrefix(lowercaseQuery) { return 0.8 }
        
        // Contains match
        if lowercaseText.contains(lowercaseQuery) { return 0.6 }
        
        // Fuzzy matching score
        let words = lowercaseQuery.components(separatedBy: " ")
        let matchingWords = words.filter { lowercaseText.contains($0) }
        return Double(matchingWords.count) / Double(words.count) * 0.4
    }
}
