//
//  DocumentCacheStrategy.swift
//  I Do Blueprint
//
//  Centralized document cache invalidation
//  Updated to use CacheConfiguration and CacheMonitor
//

import Foundation

actor DocumentCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared
    private let monitor = CacheMonitor.shared

    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .documentCreated(let tenantId), .documentUpdated(let tenantId), .documentDeleted(let tenantId):
            await invalidateDocumentCaches(tenantId: tenantId, operation: operation)
        default: break
        }
    }

    private func invalidateDocumentCaches(tenantId: UUID, operation: CacheOperation) async {
        var keysInvalidated = 0
        
        // Use CacheConfiguration for standardized keys
        let keysToInvalidate = [
            CacheConfiguration.KeyPrefix.document.key(tenantId: tenantId),
            CacheConfiguration.KeyPrefix.documentSearch.key(tenantId: tenantId)
        ]
        
        for key in keysToInvalidate {
            await cache.remove(key)
            keysInvalidated += 1
        }
        
        // Invalidate prefix-based caches (type and bucket filters)
        await cache.invalidatePrefix("documents_type_")
        await cache.invalidatePrefix("documents_bucket_")
        keysInvalidated += 2 // Approximate count for prefix invalidation
        
        // Also invalidate legacy keys for backward compatibility
        let id = tenantId.uuidString
        await cache.remove("documents_\(id)")
        keysInvalidated += 1
        
        await monitor.trackInvalidation(operation, keysInvalidated: keysInvalidated)
    }
}
