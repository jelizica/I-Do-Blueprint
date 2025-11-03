//
//  BudgetCacheStrategy.swift
//  I Do Blueprint
//
//  Centralized budget cache invalidation
//

import Foundation

actor BudgetCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared

    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .categoryCreated, .categoryUpdated, .categoryDeleted:
            await invalidateCategoryCaches()
        case .expenseCreated(let tenantId), .expenseUpdated(let tenantId), .expenseDeleted(let tenantId):
            await invalidateExpenseCaches(tenantId: tenantId)
        default:
            break
        }
    }

    private func invalidateCategoryCaches() async {
        await cache.remove("budget_categories")
        await cache.remove("budget_summary")
    }

    private func invalidateExpenseCaches(tenantId: UUID) async {
        let id = tenantId.uuidString
        await cache.remove("expenses_\(id)")
        await cache.remove("budget_summary")
        await cache.remove("budget_overview_items")
    }
}
