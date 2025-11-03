//
//  DocumentCacheStrategy.swift
//  I Do Blueprint
//
//  Centralized document cache invalidation
//

import Foundation

actor DocumentCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared

    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .documentCreated(let tenantId), .documentUpdated(let tenantId), .documentDeleted(let tenantId):
            await invalidateDocumentCaches(tenantId: tenantId)
        default: break
        }
    }

    private func invalidateDocumentCaches(tenantId: UUID) async {
        let id = tenantId.uuidString
        await cache.remove("documents_\(id)")
        await cache.remove("documents_type_*_\(id)")
        await cache.remove("documents_bucket_*_\(id)")
        // Note: wildcard invalidation is symbolic; actual code should remove specific keys when tracked.
    }
}
