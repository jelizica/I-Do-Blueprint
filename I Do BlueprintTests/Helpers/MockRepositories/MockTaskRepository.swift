//
//  MockTaskRepository.swift
//  I Do BlueprintTests
//
//  Mock implementation of TaskRepositoryProtocol for testing
//

import Foundation
@testable import I_Do_Blueprint

class MockTaskRepository: TaskRepositoryProtocol {
    var tasks: [WeddingTask] = []
    var subtasks: [Subtask] = []
    var taskStats: TaskStats = TaskStats(total: 0, notStarted: 0, inProgress: 0, completed: 0, overdue: 0)
    var shouldThrowError = false
    var errorToThrow: TaskError = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

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
        let task = WeddingTask.makeTest(taskName: insertData.taskName)
        tasks.append(task)
        return task
    }

    func updateTask(_ task: WeddingTask) async throws -> WeddingTask {
        if shouldThrowError { throw errorToThrow }
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
        return task
    }

    func deleteTask(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        tasks.removeAll(where: { $0.id == id })
    }

    func fetchSubtasks(taskId: UUID) async throws -> [Subtask] {
        if shouldThrowError { throw errorToThrow }
        return subtasks.filter { $0.taskId == taskId }
    }

    func createSubtask(taskId: UUID, insertData: SubtaskInsertData) async throws -> Subtask {
        if shouldThrowError { throw errorToThrow }
        let subtask = Subtask.makeTest(taskId: taskId, subtaskName: insertData.subtaskName)
        subtasks.append(subtask)
        return subtask
    }

    func updateSubtask(_ subtask: Subtask) async throws -> Subtask {
        if shouldThrowError { throw errorToThrow }
        if let index = subtasks.firstIndex(where: { $0.id == subtask.id }) {
            subtasks[index] = subtask
        }
        return subtask
    }

    func deleteSubtask(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        subtasks.removeAll(where: { $0.id == id })
    }

    func fetchTaskStats() async throws -> TaskStats {
        if shouldThrowError { throw errorToThrow }
        return taskStats
    }
}
