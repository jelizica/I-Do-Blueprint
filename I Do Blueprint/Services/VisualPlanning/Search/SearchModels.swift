//
//  SearchModels.swift
//  I Do Blueprint
//
//  Data models for visual planning search
//

import Foundation
import SwiftUI

// MARK: - Search Results

struct SearchResults {
    var moodBoards: [MoodBoard] = []
    var colorPalettes: [ColorPalette] = []
    var seatingCharts: [SeatingChart] = []
    var stylePreferences: [StylePreferences] = []
    
    var isEmpty: Bool {
        moodBoards.isEmpty && colorPalettes.isEmpty && seatingCharts.isEmpty && stylePreferences.isEmpty
    }
    
    var totalCount: Int {
        moodBoards.count + colorPalettes.count + seatingCharts.count + stylePreferences.count
    }
}

// MARK: - Search Filters

struct SearchFilters: Codable {
    let tenantId: String
    var styleCategories: [StyleCategory] = []
    var seasons: [WeddingSeason] = []
    var paletteVisibility: [PaletteVisibility] = []
    var venueLayouts: [VenueLayout] = []
    var colors: [Color] = []
    var dateRange: ClosedRange<Date>?
    var guestCountRange: ClosedRange<Int>?
    var favoritesOnly = false
    var showTemplatesOnly = false
    var finalizedOnly = false
    var sortBy: SortOption = .relevance
    var sortOrder: SortOrder = .descending
    
    init(tenantId: String = "default") {
        self.tenantId = tenantId
    }
    
    enum CodingKeys: String, CodingKey {
        case tenantId = "tenantId"
        case styleCategories = "styleCategories"
        case seasons = "seasons"
        case paletteVisibility = "paletteVisibility"
        case venueLayouts = "venueLayouts"
        case favoritesOnly = "favoritesOnly"
        case showTemplatesOnly = "showTemplatesOnly"
        case finalizedOnly = "finalizedOnly"
        case sortBy = "sortBy"
        case sortOrder = "sortOrder"
        case dateRangeStart = "dateRangeStart"
        case dateRangeEnd = "dateRangeEnd"
        case guestCountRangeStart = "guestCountRangeStart"
        case guestCountRangeEnd = "guestCountRangeEnd"
        case colorData = "colorData"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tenantId = try container.decode(String.self, forKey: .tenantId)
        styleCategories = try container.decodeIfPresent([StyleCategory].self, forKey: .styleCategories) ?? []
        seasons = try container.decodeIfPresent([WeddingSeason].self, forKey: .seasons) ?? []
        paletteVisibility = try container.decodeIfPresent([PaletteVisibility].self, forKey: .paletteVisibility) ?? []
        venueLayouts = try container.decodeIfPresent([VenueLayout].self, forKey: .venueLayouts) ?? []
        favoritesOnly = try container.decodeIfPresent(Bool.self, forKey: .favoritesOnly) ?? false
        showTemplatesOnly = try container.decodeIfPresent(Bool.self, forKey: .showTemplatesOnly) ?? false
        finalizedOnly = try container.decodeIfPresent(Bool.self, forKey: .finalizedOnly) ?? false
        sortBy = try container.decodeIfPresent(SortOption.self, forKey: .sortBy) ?? .relevance
        sortOrder = try container.decodeIfPresent(SortOrder.self, forKey: .sortOrder) ?? .descending
        
        // Handle date range
        if let startDate = try container.decodeIfPresent(Date.self, forKey: .dateRangeStart),
           let endDate = try container.decodeIfPresent(Date.self, forKey: .dateRangeEnd) {
            dateRange = startDate ... endDate
        } else {
            dateRange = nil
        }
        
        // Handle guest count range
        if let startCount = try container.decodeIfPresent(Int.self, forKey: .guestCountRangeStart),
           let endCount = try container.decodeIfPresent(Int.self, forKey: .guestCountRangeEnd) {
            guestCountRange = startCount ... endCount
        } else {
            guestCountRange = nil
        }
        
        // Handle colors - for now, skip encoding/decoding colors
        colors = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tenantId, forKey: .tenantId)
        try container.encode(styleCategories, forKey: .styleCategories)
        try container.encode(seasons, forKey: .seasons)
        try container.encode(paletteVisibility, forKey: .paletteVisibility)
        try container.encode(venueLayouts, forKey: .venueLayouts)
        try container.encode(favoritesOnly, forKey: .favoritesOnly)
        try container.encode(showTemplatesOnly, forKey: .showTemplatesOnly)
        try container.encode(finalizedOnly, forKey: .finalizedOnly)
        try container.encode(sortBy, forKey: .sortBy)
        try container.encode(sortOrder, forKey: .sortOrder)
        
        // Handle date range
        if let dateRange {
            try container.encode(dateRange.lowerBound, forKey: .dateRangeStart)
            try container.encode(dateRange.upperBound, forKey: .dateRangeEnd)
        }
        
        // Handle guest count range
        if let guestCountRange {
            try container.encode(guestCountRange.lowerBound, forKey: .guestCountRangeStart)
            try container.encode(guestCountRange.upperBound, forKey: .guestCountRangeEnd)
        }
        
        // Colors are not encoded for now
    }
    
    enum SortOption: String, CaseIterable, Codable {
        case relevance = "relevance"
        case name = "name"
        case dateCreated = "date_created"
        case dateModified = "date_modified"
        case usage = "usage"
        
        var displayName: String {
            switch self {
            case .relevance: "Relevance"
            case .name: "Name"
            case .dateCreated: "Date Created"
            case .dateModified: "Date Modified"
            case .usage: "Usage"
            }
        }
    }
    
    enum SortOrder: String, CaseIterable, Codable {
        case ascending = "asc"
        case descending = "desc"
        
        var displayName: String {
            switch self {
            case .ascending: "Ascending"
            case .descending: "Descending"
            }
        }
    }
}

// MARK: - Quick Filters

enum QuickFilter: String, CaseIterable {
    case recent = "recent"
    case favorites = "favorites"
    case templates = "templates"
    case completed = "completed"
    case myColors = "my_colors"
    
    var displayName: String {
        switch self {
        case .recent: "Recent"
        case .favorites: "Favorites"
        case .templates: "Templates"
        case .completed: "Completed"
        case .myColors: "My Colors"
        }
    }
    
    var icon: String {
        switch self {
        case .recent: "clock"
        case .favorites: "heart.fill"
        case .templates: "doc.on.doc"
        case .completed: "checkmark.circle"
        case .myColors: "paintpalette"
        }
    }
}

// MARK: - Saved Search

struct SavedSearch: Codable, Identifiable {
    let id = UUID()
    let name: String
    let query: String
    let filters: SearchFilters
    let createdAt: Date
    let lastUsed: Date?
    
    init(name: String, query: String, filters: SearchFilters, createdAt: Date, lastUsed: Date? = nil) {
        self.name = name
        self.query = query
        self.filters = filters
        self.createdAt = createdAt
        self.lastUsed = lastUsed
    }
}
