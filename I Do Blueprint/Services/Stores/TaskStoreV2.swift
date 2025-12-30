//
//  TaskStoreV2.swift
//  My Wedding Planning App
//
//  New architecture version of task management using repository pattern
//

import Combine
import Dependencies
import Foundation
import SwiftUI

@MainActor
class TaskStoreV2: ObservableObject, CacheableStore {
    @Published var loadingState: LoadingState<[WeddingTask]> = .idle
    @Published private(set) var taskStats: TaskStats?
    @Published var selectedTask: WeddingTask?

    @Published var successMessage: String?

    // Filters
    @Published var filterStatus: TaskStatus?
    @Published var filterPriority: WeddingTaskPriority?
    @Published var searchQuery = ""
    @Published var sortOption: TaskSortOption = .dueDate

    @Dependency(\.taskRepository) var repository

    // MARK: - Cache Management
    var lastLoadTime: Date?
    let cacheValidityDuration: TimeInterval = 120 // 2 minutes (fast-changing)

    // Task tracking for cancellation handling
    private var loadTask: Task<Void, Never>?
    private var createTask: Task<Void, Never>?
    private var updateTask: Task<Void, Never>?
    private var deleteTask: Task<Void, Never>?

    // MARK: - Computed Properties for Backward Compatibility

    var tasks: [WeddingTask] {
        loadingState.data ?? []
    }

    var isLoading: Bool {
        loadingState.isLoading
    }

    var error: TaskError? {
        if case .error(let err) = loadingState {
            return err as? TaskError ?? .fetchFailed(underlying: err)
        }
        return nil
    }

    // MARK: - Task Operations

    func loadTasks(force: Bool = false) async {
        // Cancel any previous load task
        loadTask?.cancel()

        // Create new load task
        loadTask = Task { @MainActor in
            // Use cached data if still valid
            if !force && isCacheValid() {
                AppLogger.ui.debug("Using cached task data (age: \(Int(cacheAge()))s)")
                return
            }

            guard loadingState.isIdle || loadingState.hasError || force else { return }

            loadingState = .loading

            do {
                try Task.checkCancellation()

                async let tasksResult = repository.fetchTasks()
                async let statsResult = repository.fetchTaskStats()

                let fetchedTasks = try await tasksResult
                let fetchedStats = try await statsResult

                try Task.checkCancellation()

                taskStats = fetchedStats
                loadingState = .loaded(fetchedTasks)
                lastLoadTime = Date()
            } catch is CancellationError {
                AppLogger.ui.debug("TaskStoreV2.loadTasks: Load cancelled (expected during tenant switch)")
                loadingState = .idle
            } catch let error as URLError where error.code == .cancelled {
                AppLogger.ui.debug("TaskStoreV2.loadTasks: Load cancelled (URLError)")
                loadingState = .idle
            } catch {
                loadingState = .error(TaskError.fetchFailed(underlying: error))
            }
        }

        await loadTask?.value
    }

    func refreshTasks() async {
        await loadTasks(force: true)
    }

    func createTask(_ insertData: TaskInsertData) async {
        successMessage = nil

        do {
            let task = try await repository.createTask(insertData)

            if case .loaded(var currentTasks) = loadingState {
                currentTasks.append(task)
                loadingState = .loaded(currentTasks)
            }

            taskStats = try await repository.fetchTaskStats()
            // Invalidate cache due to mutation
            invalidateCache()
            showSuccess("Task created successfully")
        } catch {
            await handleError(error, operation: "createTask", context: [
                "taskName": insertData.taskName
            ]) { [weak self] in
                await self?.createTask(insertData)
            }
            
            loadingState = .error(TaskError.createFailed(underlying: error))
        }
    }

    func updateTask(_ task: WeddingTask) async {
        successMessage = nil

        // Optimistic update
        guard case .loaded(var currentTasks) = loadingState,
              let index = currentTasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        let original = currentTasks[index]
        currentTasks[index] = task
        loadingState = .loaded(currentTasks)

        do {
            let updated = try await repository.updateTask(task)

            if case .loaded(var tasks) = loadingState,
               let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[idx] = updated
                loadingState = .loaded(tasks)
            }

            taskStats = try await repository.fetchTaskStats()
            // Invalidate cache due to mutation
            invalidateCache()
            showSuccess("Task updated successfully")
        } catch {
            // Rollback on error
            if case .loaded(var tasks) = loadingState,
               let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[idx] = original
                loadingState = .loaded(tasks)
            }
            
            await handleError(error, operation: "updateTask", context: [
                "taskId": task.id.uuidString,
                "taskName": task.taskName
            ]) { [weak self] in
                await self?.updateTask(task)
            }
            
            loadingState = .error(TaskError.updateFailed(underlying: error))
        }
    }

    func deleteTask(_ task: WeddingTask) async {
        successMessage = nil

        // Optimistic delete
        guard case .loaded(var currentTasks) = loadingState,
              let index = currentTasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }

        let removed = currentTasks.remove(at: index)
        loadingState = .loaded(currentTasks)

        do {
            try await repository.deleteTask(id: task.id)
            taskStats = try await repository.fetchTaskStats()
            // Invalidate cache due to mutation
            invalidateCache()
            showSuccess("Task deleted successfully")
        } catch {
            // Rollback on error
            if case .loaded(var tasks) = loadingState {
                tasks.insert(removed, at: index)
                loadingState = .loaded(tasks)
            }
            
            await handleError(error, operation: "deleteTask", context: [
                "taskId": task.id.uuidString,
                "taskName": task.taskName
            ]) { [weak self] in
                await self?.deleteTask(task)
            }
            
            loadingState = .error(TaskError.deleteFailed(underlying: error))
        }
    }

    func toggleTaskStatus(_ task: WeddingTask) async {
        var updated = task
        updated.status = task.status == .completed ? .notStarted : .completed
        updated.updatedAt = Date()
        await updateTask(updated)
    }

    // MARK: - Subtask Operations

    func loadSubtasks(for taskId: UUID) async -> [Subtask] {
        do {
            return try await repository.fetchSubtasks(taskId: taskId)
        } catch {
            loadingState = .error(TaskError.fetchFailed(underlying: error))
            return []
        }
    }

    func createSubtask(taskId: UUID, insertData: SubtaskInsertData) async {
        do {
            let subtask = try await repository.createSubtask(taskId: taskId, insertData: insertData)

            // Update task's subtasks in local state
            if case .loaded(var currentTasks) = loadingState,
               let index = currentTasks.firstIndex(where: { $0.id == taskId }) {
                var task = currentTasks[index]
                if task.subtasks == nil {
                    task.subtasks = []
                }
                task.subtasks?.append(subtask)
                currentTasks[index] = task
                loadingState = .loaded(currentTasks)
            }
        } catch {
            loadingState = .error(TaskError.createFailed(underlying: error))
        }
    }

    func updateSubtask(_ subtask: Subtask) async {
        do {
            let updated = try await repository.updateSubtask(subtask)

            // Update in local state
            if case .loaded(var currentTasks) = loadingState,
               let taskIndex = currentTasks.firstIndex(where: { $0.id == subtask.taskId }),
               let subtaskIndex = currentTasks[taskIndex].subtasks?.firstIndex(where: { $0.id == subtask.id }) {
                currentTasks[taskIndex].subtasks?[subtaskIndex] = updated
                loadingState = .loaded(currentTasks)
            }
        } catch {
            loadingState = .error(TaskError.updateFailed(underlying: error))
        }
    }

    func deleteSubtask(_ subtask: Subtask) async {
        do {
            try await repository.deleteSubtask(id: subtask.id)

            // Remove from local state
            if case .loaded(var currentTasks) = loadingState,
               let taskIndex = currentTasks.firstIndex(where: { $0.id == subtask.taskId }) {
                currentTasks[taskIndex].subtasks?.removeAll { $0.id == subtask.id }
                loadingState = .loaded(currentTasks)
            }
        } catch {
            loadingState = .error(TaskError.deleteFailed(underlying: error))
        }
    }

    // MARK: - Computed Properties

    var filteredTasks: [WeddingTask] {
        var filtered = tasks

        // Search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter {
                $0.taskName.localizedCaseInsensitiveContains(searchQuery) ||
                    ($0.description?.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }

        // Status filter
        if let status = filterStatus {
            filtered = filtered.filter { $0.status == status }
        }

        // Priority filter
        if let priority = filterPriority {
            filtered = filtered.filter { $0.priority == priority }
        }

        // Apply sort
        return sortTasks(filtered, by: sortOption)
    }

    private func sortTasks(_ tasks: [WeddingTask], by option: TaskSortOption) -> [WeddingTask] {
        switch option {
        case .dueDate:
            tasks.sorted { task1, task2 in
                guard let date1 = task1.dueDate else { return false }
                guard let date2 = task2.dueDate else { return true }
                return date1 < date2
            }
        case .priority:
            tasks.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
        case .createdDate:
            tasks.sorted { $0.createdAt > $1.createdAt }
        case .taskName:
            tasks.sorted { $0.taskName < $1.taskName }
        }
    }

    func clearFilters() {
        filterStatus = nil
        filterPriority = nil
        searchQuery = ""
        sortOption = .dueDate
    }

    func tasks(for status: TaskStatus) -> [WeddingTask] {
        filteredTasks.filter { $0.status == status }
    }

    func moveTask(_ task: WeddingTask, to newStatus: TaskStatus) async {
        var updated = task
        updated.status = newStatus
        updated.updatedAt = Date()
        await updateTask(updated)
    }

    func clearError() {
        if loadingState.hasError {
            loadingState = .idle
        }
    }

    func retryLoad() async {
        await loadTasks()
    }

    func clearSuccessMessage() {
        successMessage = nil
    }

    var overdueTasks: [WeddingTask] {
        let now = Date()
        return tasks.filter { task in
            task.status != .completed &&
                task.status != .cancelled &&
                (task.dueDate ?? .distantFuture) < now
        }
    }

    var upcomingTasks: [WeddingTask] {
        let now = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now

        return tasks.filter { task in
            task.status != .completed &&
                task.status != .cancelled &&
                (task.dueDate ?? .distantFuture) >= now &&
                (task.dueDate ?? .distantFuture) <= nextWeek
        }
    }

    var stats: TaskStats {
        taskStats ?? TaskStats(total: 0, notStarted: 0, inProgress: 0, completed: 0, overdue: 0)
    }

    // MARK: - Private Helpers

    private func showSuccess(_ message: String) {
        successMessage = message

        // Auto-hide after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            successMessage = nil
        }
    }

    // MARK: - State Management

    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        // Cancel in-flight tasks to avoid race conditions during tenant switch
        loadTask?.cancel()
        createTask?.cancel()
        updateTask?.cancel()
        deleteTask?.cancel()

        // Reset state and invalidate cache
        loadingState = .idle
        taskStats = nil
        lastLoadTime = nil
    }
}

// MARK: - Task Sort Option

enum TaskSortOption: String, CaseIterable {
    case dueDate = "Due Date"
    case priority = "Priority"
    case createdDate = "Created Date"
    case taskName = "Task Name"
}

// MARK: - Priority Sort Order

extension WeddingTaskPriority {
    var sortOrder: Int {
        switch self {
        case .urgent: 0
        case .high: 1
        case .medium: 2
        case .low: 3
        }
    }
}
