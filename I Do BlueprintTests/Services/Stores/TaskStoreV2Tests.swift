//
//  TaskStoreV2Tests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for TaskStoreV2 following VendorStoreV2Tests pattern
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class TaskStoreV2Tests: XCTestCase {
    var store: TaskStoreV2!
    var mockRepository: MockTaskRepository!

    override func setUp() async throws {
        mockRepository = MockTaskRepository()
        store = withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }
    }

    override func tearDown() async throws {
        store = nil
        mockRepository = nil
    }

    // MARK: - Load Tasks Tests

    func testLoadTasks_Success() async throws {
        // Given
        let mockTasks = [
            createMockTask(title: "Book venue", status: .notStarted),
            createMockTask(title: "Send invitations", status: .inProgress),
        ]
        let mockStats = TaskStats(
            total: 2,
            completed: 0,
            inProgress: 1,
            notStarted: 1,
            overdue: 0
        )
        mockRepository.tasks = mockTasks
        mockRepository.taskStats = mockStats

        // When
        await store.loadTasks()

        // Then
        XCTAssertEqual(store.tasks.count, 2)
        XCTAssertEqual(store.tasks[0].title, "Book venue")
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertNotNil(store.taskStats)
        XCTAssertEqual(store.taskStats?.total, 2)
    }

    func testLoadTasks_EmptyResult() async throws {
        // Given
        mockRepository.tasks = []
        mockRepository.taskStats = TaskStats(
            total: 0,
            completed: 0,
            inProgress: 0,
            notStarted: 0,
            overdue: 0
        )

        // When
        await store.loadTasks()

        // Then
        XCTAssertTrue(store.tasks.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testLoadTasks_Error() async throws {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await store.loadTasks()

        // Then
        XCTAssertTrue(store.tasks.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Create Task Tests

    func testCreateTask_Success() async throws {
        // Given
        let insertData = TaskInsertData(
            title: "New Task",
            description: "Description",
            status: .notStarted,
            priority: .medium,
            dueDate: Date(),
            categoryId: nil
        )
        let newTask = createMockTask(title: "New Task")
        mockRepository.createdTask = newTask

        // When
        await store.createTask(insertData)

        // Then
        XCTAssertEqual(store.tasks.count, 1)
        XCTAssertEqual(store.tasks[0].title, "New Task")
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func testCreateTask_Error() async throws {
        // Given
        mockRepository.shouldThrowError = true
        let insertData = TaskInsertData(
            title: "New Task",
            description: nil,
            status: .notStarted,
            priority: .medium,
            dueDate: nil,
            categoryId: nil
        )

        // When
        await store.createTask(insertData)

        // Then
        XCTAssertTrue(store.tasks.isEmpty)
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
    }

    // MARK: - Update Task Tests

    func testUpdateTask_Success() async throws {
        // Given
        let originalTask = createMockTask(title: "Original")
        store.tasks = [originalTask]

        var updatedTask = originalTask
        updatedTask.title = "Updated"
        mockRepository.updatedTask = updatedTask

        // When
        await store.updateTask(updatedTask)

        // Then
        XCTAssertEqual(store.tasks[0].title, "Updated")
        XCTAssertNil(store.error)
    }

    func testUpdateTask_RollbackOnError() async throws {
        // Given
        let originalTask = createMockTask(title: "Original")
        store.tasks = [originalTask]

        var updatedTask = originalTask
        updatedTask.title = "Updated"
        mockRepository.shouldThrowError = true

        // When
        await store.updateTask(updatedTask)

        // Then - should rollback to original
        XCTAssertEqual(store.tasks[0].title, "Original")
        XCTAssertNotNil(store.error)
    }

    // MARK: - Delete Task Tests

    func testDeleteTask_Success() async throws {
        // Given
        let task = createMockTask(title: "To Delete")
        store.tasks = [task]

        // When
        await store.deleteTask(task)

        // Then
        XCTAssertTrue(store.tasks.isEmpty)
        XCTAssertNil(store.error)
    }

    func testDeleteTask_RollbackOnError() async throws {
        // Given
        let task = createMockTask(title: "To Delete")
        store.tasks = [task]
        mockRepository.shouldThrowError = true

        // When
        await store.deleteTask(task)

        // Then - should rollback
        XCTAssertEqual(store.tasks.count, 1)
        XCTAssertEqual(store.tasks[0].title, "To Delete")
        XCTAssertNotNil(store.error)
    }

    // MARK: - Toggle Status Tests

    func testToggleTaskStatus_CompletesNotStartedTask() async throws {
        // Given
        let task = createMockTask(title: "Task", status: .notStarted)
        store.tasks = [task]

        var completed = task
        completed.status = .completed
        mockRepository.updatedTask = completed

        // When
        await store.toggleTaskStatus(task)

        // Then
        XCTAssertEqual(store.tasks[0].status, .completed)
    }

    func testToggleTaskStatus_UncompleteCompletedTask() async throws {
        // Given
        let task = createMockTask(title: "Task", status: .completed)
        store.tasks = [task]

        var notStarted = task
        notStarted.status = .notStarted
        mockRepository.updatedTask = notStarted

        // When
        await store.toggleTaskStatus(task)

        // Then
        XCTAssertEqual(store.tasks[0].status, .notStarted)
    }

    // MARK: - Helper Methods

    private func createMockTask(
        title: String,
        status: TaskStatus = .notStarted,
        priority: WeddingTaskPriority = .medium
    ) -> WeddingTask {
        WeddingTask(
            id: UUID(),
            tenantId: UUID(),
            title: title,
            description: nil,
            status: status,
            priority: priority,
            dueDate: nil,
            completedAt: nil,
            categoryId: nil,
            assigneeId: nil,
            subtasks: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Repository

class MockTaskRepository: TaskRepositoryProtocol {
    var tasks: [WeddingTask] = []
    var taskStats: TaskStats?
    var createdTask: WeddingTask?
    var updatedTask: WeddingTask?
    var shouldThrowError = false

    func fetchTasks() async throws -> [WeddingTask] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return tasks
    }

    func fetchTaskStats() async throws -> TaskStats {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return taskStats ?? TaskStats(total: 0, completed: 0, inProgress: 0, notStarted: 0, overdue: 0)
    }

    func createTask(_ insertData: TaskInsertData) async throws -> WeddingTask {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return createdTask ?? WeddingTask(
            id: UUID(),
            tenantId: UUID(),
            title: insertData.title,
            description: insertData.description,
            status: insertData.status,
            priority: insertData.priority,
            dueDate: insertData.dueDate,
            completedAt: nil,
            categoryId: insertData.categoryId,
            assigneeId: nil,
            subtasks: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func updateTask(_ task: WeddingTask) async throws -> WeddingTask {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return updatedTask ?? task
    }

    func deleteTask(id: UUID) async throws {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
    }

    func fetchSubtasks(taskId: UUID) async throws -> [Subtask] {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return []
    }

    func createSubtask(taskId: UUID, insertData: SubtaskInsertData) async throws -> Subtask {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return Subtask(id: UUID(), taskId: taskId, title: insertData.title, isCompleted: false, createdAt: Date())
    }

    func updateSubtask(_ subtask: Subtask) async throws -> Subtask {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
        return subtask
    }

    func deleteSubtask(id: UUID) async throws {
        if shouldThrowError { throw NSError(domain: "test", code: -1) }
    }

    func invalidateCache() async {
        // No-op for mock
    }
}
