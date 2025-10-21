//
//  LiveTaskRepository.swift
//  My Wedding Planning App
//
//  Supabase implementation of task repository with caching
//

import Foundation
import Supabase

actor LiveTaskRepository: TaskRepositoryProtocol {
    private let client: SupabaseClient?
    private let logger = AppLogger.repository
    
    // SessionManager for tenant scoping
    private let sessionManager: SessionManager
    
    init(client: SupabaseClient? = nil, sessionManager: SessionManager = .shared) {
        self.client = client
        self.sessionManager = sessionManager
    }
    
    init() {
        self.client = SupabaseManager.shared.client
        self.sessionManager = .shared
    }
    
    private func getClient() throws -> SupabaseClient {
        guard let client = client else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return client
    }
    
    // Helper to get tenant ID, throws if not set
    private func getTenantId() async throws -> UUID {
        try await MainActor.run {
            try sessionManager.requireTenantId()
        }
    }

    func fetchTasks() async throws -> [WeddingTask] {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let cacheKey = "tasks_\(tenantId.uuidString)"
        let startTime = Date()
        
        // ✅ Check cache first
        if let cached: [WeddingTask] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: tasks (\(cached.count) items)")
            return cached
        }
        
        logger.info("Cache miss: fetching tasks from database")
        
        do {
            let tasks: [WeddingTask] = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_tasks")
                    .select("""
                        *,
                        subtasks:wedding_subtasks(*),
                        milestone:wedding_milestones(*),
                        vendor:vendors(id, vendor_name),
                        budget_category:budget_categories(id, category_name, parent_category_id)
                    """)
                    .eq("couple_id", value: tenantId.uuidString)
                    .order("due_date", ascending: true)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Cache the results
            await RepositoryCache.shared.set(cacheKey, value: tasks, ttl: 60)
            
            // ✅ Record performance metrics
            await PerformanceMonitor.shared.recordOperation("fetchTasks", duration: duration)
            
            logger.info("Fetched \(tasks.count) tasks in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchTasks", outcome: .success, duration: duration)
            
            return tasks
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record failed operation
            await PerformanceMonitor.shared.recordOperation("fetchTasks", duration: duration)
            
            logger.error("Failed to fetch tasks after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchTasks", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchTask(id: UUID) async throws -> WeddingTask? {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let cacheKey = "task_\(id.uuidString)_\(tenantId.uuidString)"
        let startTime = Date()
        
        // ✅ Check cache first
        if let cached: WeddingTask = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: task \(id)")
            return cached
        }
        
        do {
            let tasks: [WeddingTask] = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_tasks")
                    .select("""
                        *,
                        subtasks:wedding_subtasks(*),
                        milestone:wedding_milestones(*),
                        vendor:vendors(id, vendor_name),
                        budget_category:budget_categories(id, category_name, parent_category_id)
                    """)
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId.uuidString)
                    .limit(1)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            if let task = tasks.first {
                // ✅ Cache the result
                await RepositoryCache.shared.set(cacheKey, value: task, ttl: 60)
                logger.info("Fetched task in \(String(format: "%.2f", duration))s")
            }
            
            return tasks.first
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch task after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func createTask(_ insertData: TaskInsertData) async throws -> WeddingTask {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let startTime = Date()
        
        do {
            let task: WeddingTask = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_tasks")
                    .insert(insertData)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            // ✅ Invalidate tenant-scoped cache
            await RepositoryCache.shared.remove("tasks_\(tenantId.uuidString)")
            await RepositoryCache.shared.remove("task_stats_\(tenantId.uuidString)")
            
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("createTask", duration: duration)
            
            logger.info("Created task in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "createTask", outcome: .success, duration: duration)
            
            return task
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record failed operation
            await PerformanceMonitor.shared.recordOperation("createTask", duration: duration)
            
            logger.error("Failed to create task after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "createTask", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func updateTask(_ task: WeddingTask) async throws -> WeddingTask {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let startTime = Date()
        
        do {
            let updated: WeddingTask = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_tasks")
                    .update(task)
                    .eq("id", value: task.id)
                    .eq("couple_id", value: tenantId.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            // ✅ Invalidate tenant-scoped cache
            await RepositoryCache.shared.remove("tasks_\(tenantId.uuidString)")
            await RepositoryCache.shared.remove("task_\(task.id.uuidString)_\(tenantId.uuidString)")
            await RepositoryCache.shared.remove("task_stats_\(tenantId.uuidString)")
            
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("updateTask", duration: duration)
            
            logger.info("Updated task in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "updateTask", outcome: .success, duration: duration)
            
            return updated
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record failed operation
            await PerformanceMonitor.shared.recordOperation("updateTask", duration: duration)
            
            logger.error("Failed to update task after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "updateTask", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func deleteTask(id: UUID) async throws {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let startTime = Date()
        
        do {
            try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_tasks")
                    .delete()
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId.uuidString)
                    .execute()
            }
            
            // ✅ Invalidate tenant-scoped cache
            await RepositoryCache.shared.remove("tasks_\(tenantId.uuidString)")
            await RepositoryCache.shared.remove("task_\(id.uuidString)_\(tenantId.uuidString)")
            await RepositoryCache.shared.remove("task_stats_\(tenantId.uuidString)")
            
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("deleteTask", duration: duration)
            
            logger.info("Deleted task in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "deleteTask", outcome: .success, duration: duration)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record failed operation
            await PerformanceMonitor.shared.recordOperation("deleteTask", duration: duration)
            
            logger.error("Failed to delete task after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "deleteTask", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    // MARK: - Subtasks

    func fetchSubtasks(taskId: UUID) async throws -> [Subtask] {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let cacheKey = "subtasks_\(taskId.uuidString)_\(tenantId.uuidString)"
        let startTime = Date()
        
        // ✅ Check cache first
        if let cached: [Subtask] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: subtasks for task \(taskId)")
            return cached
        }
        
        do {
            let subtasks: [Subtask] = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_subtasks")
                    .select()
                    .eq("task_id", value: taskId)
                    .order("created_at")
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Cache the results
            await RepositoryCache.shared.set(cacheKey, value: subtasks, ttl: 60)
            
            logger.info("Fetched \(subtasks.count) subtasks in \(String(format: "%.2f", duration))s")
            
            return subtasks
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch subtasks after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func createSubtask(taskId: UUID, insertData: SubtaskInsertData) async throws -> Subtask {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let startTime = Date()
        
        struct SubtaskInsert: Encodable {
            let task_id: UUID
            let subtask_name: String
            let status: TaskStatus
            let assigned_to: [String]
            let notes: String?

            init(taskId: UUID, data: SubtaskInsertData) {
                task_id = taskId
                subtask_name = data.subtaskName
                status = data.status
                assigned_to = data.assignedTo
                notes = data.notes
            }
        }

        do {
            let insert = SubtaskInsert(taskId: taskId, data: insertData)
            let subtask: Subtask = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_subtasks")
                    .insert(insert)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            // ✅ Invalidate related caches
            await RepositoryCache.shared.remove("subtasks_\(taskId.uuidString)_\(tenantId.uuidString)")
            await RepositoryCache.shared.remove("task_\(taskId.uuidString)_\(tenantId.uuidString)")
            
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("createSubtask", duration: duration)
            
            logger.info("Created subtask in \(String(format: "%.2f", duration))s")
            
            return subtask
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record failed operation
            await PerformanceMonitor.shared.recordOperation("createSubtask", duration: duration)
            
            logger.error("Failed to create subtask after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func updateSubtask(_ subtask: Subtask) async throws -> Subtask {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let startTime = Date()
        
        do {
            let updated: Subtask = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_subtasks")
                    .update(subtask)
                    .eq("id", value: subtask.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }
            
            // ✅ Invalidate related caches
            await RepositoryCache.shared.remove("subtasks_\(subtask.taskId.uuidString)_\(tenantId.uuidString)")
            await RepositoryCache.shared.remove("task_\(subtask.taskId.uuidString)_\(tenantId.uuidString)")
            
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("updateSubtask", duration: duration)
            
            logger.info("Updated subtask in \(String(format: "%.2f", duration))s")
            
            return updated
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record failed operation
            await PerformanceMonitor.shared.recordOperation("updateSubtask", duration: duration)
            
            logger.error("Failed to update subtask after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    func deleteSubtask(id: UUID) async throws {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let startTime = Date()
        
        do {
            // Fetch the subtask first to get the taskId for cache invalidation
            let subtasks: [Subtask] = try await client.database
                .from("wedding_subtasks")
                .select()
                .eq("id", value: id)
                .limit(1)
                .execute()
                .value
            
            try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_subtasks")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }
            
            // ✅ Invalidate related caches
            if let taskId = subtasks.first?.taskId {
                await RepositoryCache.shared.remove("subtasks_\(taskId.uuidString)_\(tenantId.uuidString)")
                await RepositoryCache.shared.remove("task_\(taskId.uuidString)_\(tenantId.uuidString)")
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("deleteSubtask", duration: duration)
            
            logger.info("Deleted subtask in \(String(format: "%.2f", duration))s")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record failed operation
            await PerformanceMonitor.shared.recordOperation("deleteSubtask", duration: duration)
            
            logger.error("Failed to delete subtask after \(String(format: "%.2f", duration))s", error: error)
            throw error
        }
    }

    // MARK: - Statistics

    func fetchTaskStats() async throws -> TaskStats {
        let tenantId = try await getTenantId()
        let cacheKey = "task_stats_\(tenantId.uuidString)"
        let startTime = Date()
        
        // ✅ Check cache first
        if let cached: TaskStats = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: task stats")
            return cached
        }
        
        logger.info("Cache miss: calculating task stats")
        
        let tasks: [WeddingTask] = try await fetchTasks()
        let now = Date()

        let stats = TaskStats(
            total: tasks.count,
            notStarted: tasks.filter { $0.status == .notStarted }.count,
            inProgress: tasks.filter { $0.status == .inProgress }.count,
            completed: tasks.filter { $0.status == .completed }.count,
            overdue: tasks.filter { !$0.status.isCompleted && ($0.dueDate ?? .distantFuture) < now }.count)
        
        let duration = Date().timeIntervalSince(startTime)
        
        // ✅ Cache the result
        await RepositoryCache.shared.set(cacheKey, value: stats, ttl: 60)
        
        // ✅ Record performance
        await PerformanceMonitor.shared.recordOperation("fetchTaskStats", duration: duration)
        
        logger.info("Calculated task stats in \(String(format: "%.2f", duration))s")
        
        return stats
    }
}

private extension TaskStatus {
    var isCompleted: Bool {
        self == .completed
    }
}
