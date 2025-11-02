//
//  VendorCacheStrategy.swift
//  I Do Blueprint
//
//  Centralized vendor cache invalidation
//

import Foundation

actor VendorCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared
    
    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .vendorCreated(let tenantId, let vendorId),
             .vendorUpdated(let tenantId, let vendorId),
             .vendorDeleted(let tenantId, let vendorId):
            await invalidateVendorCaches(tenantId: tenantId, vendorId: vendorId)
        default:
            break
        }
    }
    
    private func invalidateVendorCaches(tenantId: UUID, vendorId: Int64?) async {
        let id = tenantId.uuidString
        await cache.remove("vendors_\(id)")
        await cache.remove("vendor_stats_\(id)")
        if let vendorId {
            await cache.remove("vendor_reviews_\(vendorId)_\(id)")
            await cache.remove("vendor_review_stats_\(vendorId)_\(id)")
            await cache.remove("vendor_payment_summary_\(vendorId)_\(id)")
            await cache.remove("vendor_contract_summary_\(vendorId)_\(id)")
        }
    }
}
