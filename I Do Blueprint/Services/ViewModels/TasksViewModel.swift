//
//  TasksViewModel.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class TasksViewModel: ObservableObject {
    @Published var tasks: [WeddingTask] = []
    @Published var filteredTasks: [WeddingTask] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var successMessage: String?

    // Filters
    @Published var selectedStatus: TaskStatus?
    @Published var selectedPriority: WeddingTaskPriority?
    @Published var searchText = ""
    @Published var sortOption: TaskSortOption = .dueDate

    private let api: TasksAPI

    init(api: TasksAPI = TasksAPI()) {
        self.api = api
    }

    // MARK: - Lifecycle

    func load() async {
        // Prevent concurrent loads
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            tasks = try await api.fetchTasks()
            // Apply any active filters to loaded tasks
            applyFilters()
        } catch {
            self.error = "Failed to load tasks: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refresh() async {
        await load()
    }

    // MARK: - Task Management

    func createTask(_ taskData: TaskInsertData) async {
        error = nil
        successMessage = nil

        do {
            let newTask = try await api.createTask(taskData)
            tasks.append(newTask)
            applyFilters()
            successMessage = "Task created successfully"
        } catch {
            self.error = "Failed to create task: \(error.localizedDescription)"
        }
    }

    func updateTask(_ id: UUID, data: TaskInsertData) async {
        error = nil
        successMessage = nil

        do {
            let updatedTask = try await api.updateTask(id, data: data)
            if let index = tasks.firstIndex(where: { $0.id == id }) {
                tasks[index] = updatedTask
                applyFilters()
                successMessage = "Task updated successfully"
            }
        } catch {
            self.error = "Failed to update task: \(error.localizedDescription)"
        }
    }

    func updateTaskStatus(_ id: UUID, status: TaskStatus) async {
        error = nil

        do {
            let updatedTask = try await api.updateTaskStatus(id, status: status)
            if let index = tasks.firstIndex(where: { $0.id == id }) {
                tasks[index] = updatedTask
                applyFilters()
            }
        } catch {
            self.error = "Failed to update task status: \(error.localizedDescription)"
        }
    }

    func deleteTask(_ id: UUID) async {
        error = nil
        successMessage = nil

        do {
            try await api.deleteTask(id)
            tasks.removeAll { $0.id == id }
            applyFilters()
            successMessage = "Task deleted successfully"
        } catch {
            self.error = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    // MARK: - Filtering & Sorting

    func applyFilters() {
        var result = tasks

        if let status = selectedStatus {
            result = result.filter { $0.status == status }
        }

        if let priority = selectedPriority {
            result = result.filter { $0.priority == priority }
        }

        // Search both task name and description fields
        if !searchText.isEmpty {
            result = result.filter {
                $0.taskName.localizedCaseInsensitiveContains(searchText) ||
                    $0.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        // Apply selected sort order to filtered results
        result = sortTasks(result, by: sortOption)

        filteredTasks = result
    }

    private func sortTasks(_ tasks: [WeddingTask], by option: TaskSortOption) -> [WeddingTask] {
        switch option {
        case .dueDate:
            // Sort by due date, placing tasks without dates at the end
            tasks.sorted { task1, task2 in
                guard let date1 = task1.dueDate else { return false }
                guard let date2 = task2.dueDate else { return true }
                return date1 < date2
            }
        case .priority:
            // Sort by priority level (urgent → high → medium → low)
            tasks.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
        case .createdDate:
            // Sort by creation date, newest first
            tasks.sorted { $0.createdAt > $1.createdAt }
        case .taskName:
            // Alphabetical sort by task name
            tasks.sorted { $0.taskName < $1.taskName }
        }
    }

    func clearFilters() {
        selectedStatus = nil
        selectedPriority = nil
        searchText = ""
        sortOption = .dueDate
        applyFilters()
    }

    // MARK: - Kanban Board Helpers

    func tasks(for status: TaskStatus) -> [WeddingTask] {
        filteredTasks.filter { $0.status == status }
    }

    func moveTask(_ task: WeddingTask, to newStatus: TaskStatus) async {
        await updateTaskStatus(task.id, status: newStatus)
    }

    // MARK: - Utility

    func clearError() {
        error = nil
    }

    func clearSuccessMessage() {
        successMessage = nil
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
