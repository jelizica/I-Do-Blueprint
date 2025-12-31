//
//  VisualPlanningSearchService.swift
//  I Do Blueprint
//
//  Orchestrates search across visual planning content
//

import Combine
import Foundation
import SwiftUI

@MainActor
class VisualPlanningSearchService: ObservableObject {
    @Published var searchResults: SearchResults = .init()
    @Published var searchQuery = ""
    @Published var isSearching = false
    @Published var activeFilters: SearchFilters = .init()
    
    private let supabaseService: SupabaseVisualPlanningService
    private let savedSearchManager: SavedSearchManager
    private var searchCancellable: AnyCancellable?
    private let logger = AppLogger.general
    
    // Domain-specific search services
    private let moodBoardSearchService: MoodBoardSearchService
    private let colorPaletteSearchService: ColorPaletteSearchService
    private let seatingChartSearchService: SeatingChartSearchService
    private let stylePreferencesSearchService: StylePreferencesSearchService
    
    init(supabaseService: SupabaseVisualPlanningService) {
        self.supabaseService = supabaseService
        self.savedSearchManager = SavedSearchManager()
        
        // Initialize domain-specific services
        self.moodBoardSearchService = MoodBoardSearchService(supabaseService: supabaseService)
        self.colorPaletteSearchService = ColorPaletteSearchService(supabaseService: supabaseService)
        self.seatingChartSearchService = SeatingChartSearchService(supabaseService: supabaseService)
        self.stylePreferencesSearchService = StylePreferencesSearchService(supabaseService: supabaseService)
        
        setupSearchDebouncing()
    }
    
    // MARK: - Search Functionality
    
    private func setupSearchDebouncing() {
        searchCancellable = $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                if !query.isEmpty {
                    Task {
                        await self?.performSearch()
                    }
                }
            }
    }
    
    func performSearch() async {
        isSearching = true
        defer { isSearching = false }
        
        do {
            let results = try await searchContent(
                query: searchQuery,
                filters: activeFilters
            )
            searchResults = results
        } catch {
            logger.warning("Search failed: \(error.localizedDescription)")
            searchResults = SearchResults()
        }
    }
    
    private func searchContent(query: String, filters: SearchFilters) async throws -> SearchResults {
        var results = SearchResults()
        
        // Search across all domains in parallel
        async let moodBoards = moodBoardSearchService.search(query: query, filters: filters)
        async let colorPalettes = colorPaletteSearchService.search(query: query, filters: filters)
        async let seatingCharts = seatingChartSearchService.search(query: query, filters: filters)
        async let stylePreferences = stylePreferencesSearchService.search(query: query, filters: filters)
        
        // Await all results
        results.moodBoards = try await moodBoards
        results.colorPalettes = try await colorPalettes
        results.seatingCharts = try await seatingCharts
        if let preferences = try await stylePreferences {
            results.stylePreferences = [preferences]
        }
        
        // Sort by relevance
        SearchResultTransformer.sortByRelevance(&results, query: query)
        
        return results
    }
    
    // MARK: - Quick Filters
    
    func applyQuickFilter(_ filter: QuickFilter) {
        switch filter {
        case .recent:
            activeFilters.dateRange = Date().addingTimeInterval(-7 * 24 * 60 * 60) ... Date()
        case .favorites:
            activeFilters.favoritesOnly = true
        case .templates:
            activeFilters.showTemplatesOnly = true
        case .completed:
            activeFilters.finalizedOnly = true
        case .myColors:
            // Apply user's primary colors from style preferences
            Task {
                if let preferences = try? await supabaseService.fetchStylePreferences(for: activeFilters.tenantId) {
                    activeFilters.colors = preferences.primaryColors
                    await performSearch()
                }
            }
        }
        
        Task {
            await performSearch()
        }
    }
    
    func clearFilters() {
        activeFilters = SearchFilters(tenantId: activeFilters.tenantId)
        Task {
            await performSearch()
        }
    }
    
    // MARK: - Saved Searches
    
    var savedSearches: [SavedSearch] {
        savedSearchManager.savedSearches
    }
    
    func saveCurrentSearch(name: String) {
        savedSearchManager.saveSearch(name: name, query: searchQuery, filters: activeFilters)
    }
    
    func loadSavedSearch(_ savedSearch: SavedSearch) {
        searchQuery = savedSearch.query
        activeFilters = savedSearch.filters
        savedSearchManager.markAsUsed(savedSearch)
        
        Task {
            await performSearch()
        }
    }
    
    func deleteSavedSearch(at index: Int) {
        savedSearchManager.deleteSearch(at: index)
    }
    
    // MARK: - Search Suggestions
    
    func getSearchSuggestions(for query: String) -> [String] {
        SearchSuggestionService.getSuggestions(for: query)
    }
}
