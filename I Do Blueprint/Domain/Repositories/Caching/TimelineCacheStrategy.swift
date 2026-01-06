//
//  TimelineCacheStrategy.swift
//  I Do Blueprint
//
//  Centralized timeline cache invalidation (lightweight, future-proof)
//  Updated to use CacheConfiguration and CacheMonitor
//

import Foundation

actor TimelineCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared
    private let monitor = CacheMonitor.shared

    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .timelineItemCreated(let tenantId), .timelineItemUpdated(let tenantId), .timelineItemDeleted(let tenantId):
            await invalidateTimelineCaches(tenantId: tenantId, operation: operation)
        case .milestoneCreated(let tenantId), .milestoneUpdated(let tenantId), .milestoneDeleted(let tenantId):
            await invalidateMilestoneCaches(tenantId: tenantId, operation: operation)
        case .weddingDayEventCreated(let tenantId), .weddingDayEventUpdated(let tenantId), .weddingDayEventDeleted(let tenantId):
            await invalidateWeddingDayEventCaches(tenantId: tenantId, operation: operation)
        default: break
        }
    }

    private func invalidateTimelineCaches(tenantId: UUID, operation: CacheOperation) async {
        var keysInvalidated = 0
        
        // Use CacheConfiguration for standardized keys
        let keysToInvalidate = [
            CacheConfiguration.KeyPrefix.timeline.key(tenantId: tenantId),
            CacheConfiguration.KeyPrefix.timelineItems.key(tenantId: tenantId)
        ]
        
        for key in keysToInvalidate {
            await cache.remove(key)
            keysInvalidated += 1
        }
        
        // Also invalidate legacy keys for backward compatibility
        let id = tenantId.uuidString
        await cache.remove("timeline_items_\(id)")
        await cache.remove("timeline_stats_\(id)")
        keysInvalidated += 2
        
        await monitor.trackInvalidation(operation, keysInvalidated: keysInvalidated)
    }

    private func invalidateMilestoneCaches(tenantId: UUID, operation: CacheOperation) async {
        var keysInvalidated = 0

        // Use CacheConfiguration for standardized keys
        let key = CacheConfiguration.KeyPrefix.milestones.key(tenantId: tenantId)
        await cache.remove(key)
        keysInvalidated += 1

        // Also invalidate legacy key for backward compatibility
        let id = tenantId.uuidString
        await cache.remove("milestones_\(id)")
        keysInvalidated += 1

        await monitor.trackInvalidation(operation, keysInvalidated: keysInvalidated)
    }

    private func invalidateWeddingDayEventCaches(tenantId: UUID, operation: CacheOperation) async {
        var keysInvalidated = 0

        // Use CacheConfiguration for standardized keys
        let key = CacheConfiguration.KeyPrefix.weddingDayEvents.key(tenantId: tenantId)
        await cache.remove(key)
        keysInvalidated += 1

        // Also invalidate timeline caches since they're related
        let timelineKey = CacheConfiguration.KeyPrefix.timeline.key(tenantId: tenantId)
        await cache.remove(timelineKey)
        keysInvalidated += 1

        // Invalidate legacy keys for backward compatibility
        let id = tenantId.uuidString
        await cache.remove("wedding_events_\(id)")
        await cache.remove("wedding_day_events_\(id)")
        keysInvalidated += 2

        await monitor.trackInvalidation(operation, keysInvalidated: keysInvalidated)
    }
}
