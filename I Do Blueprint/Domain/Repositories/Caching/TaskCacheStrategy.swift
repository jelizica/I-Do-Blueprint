//
//  TaskCacheStrategy.swift
//  I Do Blueprint
//
//  Centralized task cache invalidation
//

import Foundation

actor TaskCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared
    
    func invalidate(for operation: CacheOperation) async {
        switch operation {
        case .taskCreated(let tenantId, let taskId),
             .taskUpdated(let tenantId, let taskId),
             .taskDeleted(let tenantId, let taskId),
             .subtaskCreated(let tenantId, let taskId),
             .subtaskUpdated(let tenantId, let taskId):
            await invalidateTaskCaches(tenantId: tenantId, taskId: taskId)
        default: break
        }
    }
    
    private func invalidateTaskCaches(tenantId: UUID, taskId: UUID) async {
        let id = tenantId.uuidString
        await cache.remove("tasks_\(id)")
        await cache.remove("task_\(taskId.uuidString)_\(id)")
        await cache.remove("task_stats_\(id)")
        await cache.remove("subtasks_\(taskId.uuidString)_\(id)")
    }
}
