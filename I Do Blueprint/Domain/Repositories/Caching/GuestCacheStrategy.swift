//
//  GuestCacheStrategy.swift
//  I Do Blueprint
//
//  Centralized guest cache invalidation
//

import Foundation

actor GuestCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared
    
    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .guestCreated(let tenantId),
             .guestUpdated(let tenantId),
             .guestDeleted(let tenantId),
             .guestBulkImport(let tenantId):
            await invalidateGuestCaches(tenantId: tenantId)
        default:
            break
        }
    }
    
    private func invalidateGuestCaches(tenantId: UUID) async {
        let id = tenantId.uuidString
        await cache.remove("guests_\(id)")
        await cache.remove("guest_stats_\(id)")
        await cache.remove("guest_count_\(id)")
        await cache.remove("guest_groups_\(id)")
        await cache.remove("guest_rsvp_summary_\(id)")
        // Related features depending on guests
        await cache.remove("seating_chart_\(id)")
        await cache.remove("meal_selections_\(id)")
    }
}
