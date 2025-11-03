//
//  TimelineCacheStrategy.swift
//  I Do Blueprint
//
//  Centralized timeline cache invalidation (lightweight, future-proof)
//

import Foundation

actor TimelineCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared

    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .timelineItemCreated(let tenantId), .timelineItemUpdated(let tenantId), .timelineItemDeleted(let tenantId):
            await invalidateTimelineCaches(tenantId: tenantId)
        case .milestoneCreated(let tenantId), .milestoneUpdated(let tenantId), .milestoneDeleted(let tenantId):
            await invalidateMilestoneCaches(tenantId: tenantId)
        default: break
        }
    }

    private func invalidateTimelineCaches(tenantId: UUID) async {
        let id = tenantId.uuidString
        await cache.remove("timeline_items_\(id)")
        await cache.remove("timeline_stats_\(id)")
    }

    private func invalidateMilestoneCaches(tenantId: UUID) async {
        let id = tenantId.uuidString
        await cache.remove("milestones_\(id)")
    }
}
