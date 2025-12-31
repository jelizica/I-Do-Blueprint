//
//  VendorCacheStrategy.swift
//  I Do Blueprint
//
//  Centralized vendor cache invalidation
//  Updated to use CacheConfiguration and CacheMonitor
//

import Foundation

actor VendorCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared
    private let monitor = CacheMonitor.shared

    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .vendorCreated(let tenantId, let vendorId),
             .vendorUpdated(let tenantId, let vendorId),
             .vendorDeleted(let tenantId, let vendorId):
            await invalidateVendorCaches(tenantId: tenantId, vendorId: vendorId, operation: operation)
        default:
            break
        }
    }

    private func invalidateVendorCaches(tenantId: UUID, vendorId: Int64?, operation: CacheOperation) async {
        var keysInvalidated = 0
        
        // Use CacheConfiguration for standardized keys
        let keysToInvalidate = [
            CacheConfiguration.KeyPrefix.vendor.key(tenantId: tenantId),
            CacheConfiguration.KeyPrefix.vendorStats.key(tenantId: tenantId)
        ]
        
        for key in keysToInvalidate {
            await cache.remove(key)
            keysInvalidated += 1
        }
        
        // Vendor-specific caches
        if let vendorId {
            let vendorIdString = String(vendorId)
            let vendorSpecificKeys = [
                CacheConfiguration.KeyPrefix.vendorDetail.key(tenantId: tenantId, id: vendorIdString),
                "vendor_reviews_\(vendorId)_\(tenantId.uuidString)",
                "vendor_review_stats_\(vendorId)_\(tenantId.uuidString)",
                "vendor_payment_summary_\(vendorId)_\(tenantId.uuidString)",
                "vendor_contract_summary_\(vendorId)_\(tenantId.uuidString)"
            ]
            
            for key in vendorSpecificKeys {
                await cache.remove(key)
                keysInvalidated += 1
            }
        }
        
        await monitor.trackInvalidation(operation, keysInvalidated: keysInvalidated)
    }
}
