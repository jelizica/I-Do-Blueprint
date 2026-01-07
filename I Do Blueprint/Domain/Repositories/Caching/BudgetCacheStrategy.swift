//
//  BudgetCacheStrategy.swift
//  I Do Blueprint
//
//  Centralized budget cache invalidation
//  Updated to use CacheConfiguration and CacheMonitor
//

import Foundation

actor BudgetCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared
    private let monitor = CacheMonitor.shared

    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .categoryCreated, .categoryUpdated, .categoryDeleted:
            await invalidateCategoryCaches(operation: operation)
        case .expenseCreated(let tenantId), .expenseUpdated(let tenantId), .expenseDeleted(let tenantId):
            await invalidateExpenseCaches(tenantId: tenantId, operation: operation)
        default:
            break
        }
    }

    private func invalidateCategoryCaches(operation: CacheOperation) async {
        var keysInvalidated = 0
        
        // Note: Categories are not tenant-specific in current implementation
        // Using generic keys for backward compatibility
        await cache.remove("budget_categories")
        keysInvalidated += 1
        
        await cache.remove("budget_summary")
        keysInvalidated += 1
        
        // Invalidate category metrics cache (uses tenant-specific keys)
        // Use prefix invalidation to clear all tenant-specific category metrics
        await cache.invalidatePrefix("category_metrics_")
        keysInvalidated += 1
        
        await monitor.trackInvalidation(operation, keysInvalidated: keysInvalidated)
    }

    private func invalidateExpenseCaches(tenantId: UUID, operation: CacheOperation) async {
        var keysInvalidated = 0
        
        // Use CacheConfiguration for standardized keys
        let keysToInvalidate = [
            CacheConfiguration.KeyPrefix.budgetExpenses.key(tenantId: tenantId),
            CacheConfiguration.KeyPrefix.budgetSummary.key(tenantId: tenantId),
            CacheConfiguration.KeyPrefix.budgetOverview.key(tenantId: tenantId)
        ]
        
        for key in keysToInvalidate {
            await cache.remove(key)
            keysInvalidated += 1
        }
        
        // Also invalidate legacy keys for backward compatibility
        let id = tenantId.uuidString
        await cache.remove("expenses_\(id)")
        await cache.remove("budget_summary")
        await cache.remove("budget_overview_items")
        keysInvalidated += 3
        
        await monitor.trackInvalidation(operation, keysInvalidated: keysInvalidated)
    }
}
