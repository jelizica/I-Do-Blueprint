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
class TaskStoreV2: ObservableObject {
    @Published private(set) var tasks: [WeddingTask] = []
    @Published private(set) var taskStats: TaskStats?
    @Published var selectedTask: WeddingTask?

    @Published var isLoading = false
    @Published var error: TaskError?

    // Filters
    @Published var filterStatus: TaskStatus?
    @Published var filterPriority: WeddingTaskPriority?
    @Published var searchQuery = ""

    @Dependency(\.taskRepository) var repository

    // MARK: - Task Operations

    func loadTasks() async {
        isLoading = true
        error = nil

        do {
            async let tasksResult = repository.fetchTasks()
            async let statsResult = repository.fetchTaskStats()

            tasks = try await tasksResult
            taskStats = try await statsResult
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func refreshTasks() async {
        await loadTasks()
    }

    func createTask(_ insertData: TaskInsertData) async {
        isLoading = true
        error = nil

        do {
            let task = try await repository.createTask(insertData)
            tasks.append(task)
            taskStats = try await repository.fetchTaskStats()
        } catch {
            self.error = .createFailed(underlying: error)
        }

        isLoading = false
    }

    func updateTask(_ task: WeddingTask) async {
        // Optimistic update
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            let original = tasks[index]
            tasks[index] = task

            do {
                let updated = try await repository.updateTask(task)
                tasks[index] = updated
                taskStats = try await repository.fetchTaskStats()
            } catch {
                // Rollback on error
                tasks[index] = original
                self.error = .updateFailed(underlying: error)
            }
        }
    }

    func deleteTask(_ task: WeddingTask) async {
        // Optimistic delete
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let removed = tasks.remove(at: index)

        do {
            try await repository.deleteTask(id: task.id)
            taskStats = try await repository.fetchTaskStats()
        } catch {
            // Rollback on error
            tasks.insert(removed, at: index)
            self.error = .deleteFailed(underlying: error)
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
            self.error = .fetchFailed(underlying: error)
            return []
        }
    }

    func createSubtask(taskId: UUID, insertData: SubtaskInsertData) async {
        do {
            let subtask = try await repository.createSubtask(taskId: taskId, insertData: insertData)

            // Update task's subtasks in local state
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                var task = tasks[index]
                if task.subtasks == nil {
                    task.subtasks = []
                }
                task.subtasks?.append(subtask)
                tasks[index] = task
            }
        } catch {
            self.error = .createFailed(underlying: error)
        }
    }

    func updateSubtask(_ subtask: Subtask) async {
        do {
            let updated = try await repository.updateSubtask(subtask)

            // Update in local state
            if let taskIndex = tasks.firstIndex(where: { $0.id == subtask.taskId }),
               let subtaskIndex = tasks[taskIndex].subtasks?.firstIndex(where: { $0.id == subtask.id }) {
                tasks[taskIndex].subtasks?[subtaskIndex] = updated
            }
        } catch {
            self.error = .updateFailed(underlying: error)
        }
    }

    func deleteSubtask(_ subtask: Subtask) async {
        do {
            try await repository.deleteSubtask(id: subtask.id)

            // Remove from local state
            if let taskIndex = tasks.firstIndex(where: { $0.id == subtask.taskId }) {
                tasks[taskIndex].subtasks?.removeAll { $0.id == subtask.id }
            }
        } catch {
            self.error = .deleteFailed(underlying: error)
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

        return filtered.sorted { task1, task2 in
            // Sort by due date, then priority
            if let date1 = task1.dueDate, let date2 = task2.dueDate {
                return date1 < date2
            }
            return task1.priority.sortOrder < task2.priority.sortOrder
        }
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
}
