//
//  TaskRepositoryProtocol.swift
//  My Wedding Planning App
//
//  Repository protocol for task management
//

import Dependencies
import Foundation

/// Protocol defining task repository operations
protocol TaskRepositoryProtocol: Sendable {
    // MARK: - Task Operations

    func fetchTasks() async throws -> [WeddingTask]
    func fetchTask(id: UUID) async throws -> WeddingTask?
    func createTask(_ insertData: TaskInsertData) async throws -> WeddingTask
    func updateTask(_ task: WeddingTask) async throws -> WeddingTask
    func deleteTask(id: UUID) async throws

    // MARK: - Subtask Operations

    func fetchSubtasks(taskId: UUID) async throws -> [Subtask]
    func createSubtask(taskId: UUID, insertData: SubtaskInsertData) async throws -> Subtask
    func updateSubtask(_ subtask: Subtask) async throws -> Subtask
    func deleteSubtask(id: UUID) async throws

    // MARK: - Statistics

    func fetchTaskStats() async throws -> TaskStats
}

struct TaskStats: Equatable, Codable, Sendable {
    let total: Int
    let notStarted: Int
    let inProgress: Int
    let completed: Int
    let overdue: Int
}
