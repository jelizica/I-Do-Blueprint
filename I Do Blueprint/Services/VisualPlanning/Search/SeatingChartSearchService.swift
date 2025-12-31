//
//  SeatingChartSearchService.swift
//  I Do Blueprint
//
//  Domain-specific search service for seating charts
//

import Foundation

/// Service responsible for searching and filtering seating charts
actor SeatingChartSearchService {
    private let supabaseService: SupabaseVisualPlanningService
    private let logger = AppLogger.general
    
    init(supabaseService: SupabaseVisualPlanningService) {
        self.supabaseService = supabaseService
    }
    
    // MARK: - Public Interface
    
    /// Search seating charts with query and filters
    func search(query: String, filters: SearchFilters) async throws -> [SeatingChart] {
        let allCharts = try await supabaseService.fetchSeatingCharts(for: filters.tenantId)
        
        return allCharts.filter { chart in
            matchesCriteria(chart, query: query, filters: filters)
        }
    }
    
    // MARK: - Private Helpers
    
    private func matchesCriteria(_ chart: SeatingChart, query: String, filters: SearchFilters) -> Bool {
        // Text search
        let matchesText = query.isEmpty ||
            chart.chartName.localizedCaseInsensitiveContains(query) ||
            (chart.chartDescription?.localizedCaseInsensitiveContains(query) ?? false) ||
            chart.guests.contains { guest in
                "\(guest.firstName) \(guest.lastName)".localizedCaseInsensitiveContains(query)
            }
        
        // Venue layout filter
        let matchesVenueLayout = filters.venueLayouts.isEmpty ||
            filters.venueLayouts.contains(chart.venueLayoutType)
        
        // Guest count range filter
        let matchesGuestCount: Bool
        if let guestCountRange = filters.guestCountRange {
            matchesGuestCount = guestCountRange.contains(chart.guests.count)
        } else {
            matchesGuestCount = true
        }
        
        // Finalized filter
        let matchesFinalized = !filters.finalizedOnly || chart.isFinalized
        
        // Date range filter
        let matchesDateRange: Bool
        if let dateRange = filters.dateRange {
            matchesDateRange = dateRange.contains(chart.createdAt)
        } else {
            matchesDateRange = true
        }
        
        return matchesText && matchesVenueLayout && matchesGuestCount && matchesFinalized && matchesDateRange
    }
}
