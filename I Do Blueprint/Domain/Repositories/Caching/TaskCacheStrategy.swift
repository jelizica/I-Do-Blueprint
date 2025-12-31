//
//  TaskCacheStrategy.swift
//  I Do Blueprint
//
//  Centralized task cache invalidation
//  Updated to use CacheConfiguration and CacheMonitor
//

import Foundation

actor TaskCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared
    private let monitor = CacheMonitor.shared

    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .taskCreated(let tenantId, let taskId),
             .taskUpdated(let tenantId, let taskId),
             .taskDeleted(let tenantId, let taskId),
             .subtaskCreated(let tenantId, let taskId),
             .subtaskUpdated(let tenantId, let taskId):
            await invalidateTaskCaches(tenantId: tenantId, taskId: taskId, operation: operation)
        default: break
        }
    }

    private func invalidateTaskCaches(tenantId: UUID, taskId: UUID, operation: CacheOperation) async {
        var keysInvalidated = 0
        
        // Use CacheConfiguration for standardized keys
        let keysToInvalidate = [
            CacheConfiguration.KeyPrefix.task.key(tenantId: tenantId),
            CacheConfiguration.KeyPrefix.taskDetail.key(tenantId: tenantId, id: taskId.uuidString),
            CacheConfiguration.KeyPrefix.taskStats.key(tenantId: tenantId),
            CacheConfiguration.KeyPrefix.subtasks.key(tenantId: tenantId, id: taskId.uuidString)
        ]
        
        for key in keysToInvalidate {
            await cache.remove(key)
            keysInvalidated += 1
        }
        
        // Also invalidate legacy keys for backward compatibility
        let id = tenantId.uuidString
        await cache.remove("tasks_\(id)")
        await cache.remove("task_\(taskId.uuidString)_\(id)")
        await cache.remove("task_stats_\(id)")
        await cache.remove("subtasks_\(taskId.uuidString)_\(id)")
        keysInvalidated += 4
        
        await monitor.trackInvalidation(operation, keysInvalidated: keysInvalidated)
    }
}
