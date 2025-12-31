//
//  GuestCacheStrategy.swift
//  I Do Blueprint
//
//  Centralized guest cache invalidation
//  Updated to use CacheConfiguration and CacheMonitor
//

import Foundation

actor GuestCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared
    private let monitor = CacheMonitor.shared

    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .guestCreated(let tenantId),
             .guestUpdated(let tenantId),
             .guestDeleted(let tenantId),
             .guestBulkImport(let tenantId):
            await invalidateGuestCaches(tenantId: tenantId, operation: operation)
        default:
            break
        }
    }

    private func invalidateGuestCaches(tenantId: UUID, operation: CacheOperation) async {
        var keysInvalidated = 0
        
        // Use CacheConfiguration for standardized keys
        let keysToInvalidate = [
            CacheConfiguration.KeyPrefix.guest.key(tenantId: tenantId),
            CacheConfiguration.KeyPrefix.guestStats.key(tenantId: tenantId),
            CacheConfiguration.KeyPrefix.guestCount.key(tenantId: tenantId),
            CacheConfiguration.KeyPrefix.guestGroups.key(tenantId: tenantId),
            CacheConfiguration.KeyPrefix.guestRSVP.key(tenantId: tenantId),
            // Related features depending on guests
            CacheConfiguration.KeyPrefix.seatingChart.key(tenantId: tenantId),
            CacheConfiguration.KeyPrefix.mealSelections.key(tenantId: tenantId)
        ]
        
        for key in keysToInvalidate {
            await cache.remove(key)
            keysInvalidated += 1
        }
        
        // Track invalidation in monitor
        await monitor.trackInvalidation(operation, keysInvalidated: keysInvalidated)
    }
}
