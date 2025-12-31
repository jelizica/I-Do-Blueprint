//
//  SavedSearchManager.swift
//  I Do Blueprint
//
//  Manages saved searches with UserDefaults persistence
//

import Combine
import Foundation

/// Manager for saved search persistence
@MainActor
class SavedSearchManager: ObservableObject {
    @Published var savedSearches: [SavedSearch] = []
    
    private let userDefaultsKey = "SavedSearches"
    
    init() {
        loadSavedSearches()
    }
    
    // MARK: - Public Interface
    
    /// Save a new search
    func saveSearch(name: String, query: String, filters: SearchFilters) {
        let savedSearch = SavedSearch(
            name: name,
            query: query,
            filters: filters,
            createdAt: Date()
        )
        
        savedSearches.append(savedSearch)
        persist()
    }
    
    /// Delete a saved search at index
    func deleteSearch(at index: Int) {
        savedSearches.remove(at: index)
        persist()
    }
    
    /// Update last used timestamp for a search
    func markAsUsed(_ savedSearch: SavedSearch) {
        if let index = savedSearches.firstIndex(where: { $0.id == savedSearch.id }) {
            var updated = savedSearch
            savedSearches[index] = SavedSearch(
                name: updated.name,
                query: updated.query,
                filters: updated.filters,
                createdAt: updated.createdAt,
                lastUsed: Date()
            )
            persist()
        }
    }
    
    // MARK: - Private Helpers
    
    private func loadSavedSearches() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let searches = try? JSONDecoder().decode([SavedSearch].self, from: data) {
            savedSearches = searches
        }
    }
    
    private func persist() {
        if let data = try? JSONEncoder().encode(savedSearches) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}
