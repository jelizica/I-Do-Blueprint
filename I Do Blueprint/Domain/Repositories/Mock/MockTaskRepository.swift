//
//  MockTaskRepository.swift
//  My Wedding Planning App
//
//  Mock implementation for testing
//

import Foundation

@MainActor
class MockTaskRepository: TaskRepositoryProtocol {
    var tasks: [WeddingTask] = []
    var subtasks: [Subtask] = []
    var taskStats: TaskStats?

    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "test", code: -1)

    func fetchTasks() async throws -> [WeddingTask] {
        if shouldThrowError { throw errorToThrow }
        return tasks
    }

    func fetchTask(id: UUID) async throws -> WeddingTask? {
        if shouldThrowError { throw errorToThrow }
        return tasks.first(where: { $0.id == id })
    }

    func createTask(_ insertData: TaskInsertData) async throws -> WeddingTask {
        if shouldThrowError { throw errorToThrow }

        let task = WeddingTask(
            id: UUID(),
            coupleId: UUID(),
            taskName: insertData.taskName,
            description: insertData.description,
            budgetCategoryId: insertData.budgetCategoryId,
            priority: insertData.priority,
            dueDate: insertData.dueDate.flatMap { ISO8601DateFormatter().date(from: $0) },
            startDate: insertData.startDate.flatMap { ISO8601DateFormatter().date(from: $0) },
            assignedTo: insertData.assignedTo,
            vendorId: insertData.vendorId,
            status: insertData.status,
            dependsOnTaskId: insertData.dependsOnTaskId,
            estimatedHours: insertData.estimatedHours,
            costEstimate: insertData.costEstimate,
            notes: insertData.notes,
            milestoneId: insertData.milestoneId,
            createdAt: Date(),
            updatedAt: Date(),
            subtasks: nil,
            milestone: nil,
            vendor: nil,
            budgetCategory: nil)
        tasks.append(task)
        return task
    }

    func updateTask(_ task: WeddingTask) async throws -> WeddingTask {
        if shouldThrowError { throw errorToThrow }

        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            throw NSError(domain: "test", code: 404)
        }

        var updated = task
        updated.updatedAt = Date()
        tasks[index] = updated
        return updated
    }

    func deleteTask(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        tasks.removeAll { $0.id == id }
    }

    func fetchSubtasks(taskId: UUID) async throws -> [Subtask] {
        if shouldThrowError { throw errorToThrow }
        return subtasks.filter { $0.taskId == taskId }
    }

    func createSubtask(taskId: UUID, insertData: SubtaskInsertData) async throws -> Subtask {
        if shouldThrowError { throw errorToThrow }

        let subtask = Subtask(
            id: UUID(),
            taskId: taskId,
            subtaskName: insertData.subtaskName,
            status: insertData.status,
            assignedTo: insertData.assignedTo,
            notes: insertData.notes,
            createdAt: Date(),
            updatedAt: Date())
        subtasks.append(subtask)
        return subtask
    }

    func updateSubtask(_ subtask: Subtask) async throws -> Subtask {
        if shouldThrowError { throw errorToThrow }

        guard let index = subtasks.firstIndex(where: { $0.id == subtask.id }) else {
            throw NSError(domain: "test", code: 404)
        }

        var updated = subtask
        updated.updatedAt = Date()
        subtasks[index] = updated
        return updated
    }

    func deleteSubtask(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        subtasks.removeAll { $0.id == id }
    }

    func fetchTaskStats() async throws -> TaskStats {
        if shouldThrowError { throw errorToThrow }
        return taskStats ?? TaskStats(total: 0, notStarted: 0, inProgress: 0, completed: 0, overdue: 0)
    }
}
