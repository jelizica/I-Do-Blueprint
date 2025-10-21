//
//  TaskStoreV2Tests.swift
//  I Do BlueprintTests
//
//  Comprehensive tests for TaskStoreV2
//

import XCTest
import Dependencies
@testable import I_Do_Blueprint

@MainActor
final class TaskStoreV2Tests: XCTestCase {
    var mockRepository: MockTaskRepository!
    var coupleId: UUID!

    override func setUp() async throws {
        mockRepository = MockTaskRepository()
        coupleId = UUID()
    }

    override func tearDown() {
        mockRepository = nil
        coupleId = nil
    }

    // MARK: - Load Tests

    func testLoadTasks_Success() async throws {
        // Given
        let testTasks = [
            WeddingTask.makeTest(id: UUID(), coupleId: coupleId, taskName: "Book Venue"),
            WeddingTask.makeTest(id: UUID(), coupleId: coupleId, taskName: "Send Invitations")
        ]
        mockRepository.tasks = testTasks

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.tasks.count, 2)
        XCTAssertEqual(store.tasks[0].taskName, "Book Venue")
    }

    func testLoadTasks_Failure() async throws {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .fetchFailed(underlying: NSError(domain: "Test", code: -1))

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.tasks.count, 0)
    }

    func testLoadTasks_Empty() async throws {
        // Given
        mockRepository.tasks = []

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()

        // Then
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
        XCTAssertEqual(store.tasks.count, 0)
    }

    // MARK: - Create Tests

    func testCreateTask_Success() async throws {
        // Given
        let newTask = WeddingTask.makeTest(coupleId: coupleId, taskName: "Book Venue")

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        let insertData = TaskInsertData(
            taskName: "Book Venue",
            description: nil,
            budgetCategoryId: nil,
            priority: .medium,
            dueDate: nil,
            startDate: nil,
            assignedTo: [],
            vendorId: nil,
            status: .notStarted,
            dependsOnTaskId: nil,
            estimatedHours: nil,
            costEstimate: nil,
            notes: nil,
            milestoneId: nil
        )

        await store.createTask(insertData)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.tasks.count, 1)
    }

    func testUpdateTask_Success() async throws {
        // Given
        let task = WeddingTask.makeTest(id: UUID(), coupleId: coupleId, taskName: "Book Venue", status: .notStarted)
        mockRepository.tasks = [task]

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()

        var updatedTask = task
        updatedTask.status = .inProgress
        await store.updateTask(updatedTask)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.tasks.first?.status, .inProgress)
    }

    func testUpdateTask_Failure_RollsBack() async throws {
        // Given
        let task = WeddingTask.makeTest(id: UUID(), coupleId: coupleId, taskName: "Book Venue", status: .notStarted)
        mockRepository.tasks = [task]

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()

        var updatedTask = task
        updatedTask.status = .completed

        mockRepository.shouldThrowError = true
        await store.updateTask(updatedTask)

        // Then - Should rollback to original
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.tasks.first?.status, .notStarted)
    }

    // MARK: - Delete Tests

    func testDeleteTask_Success() async throws {
        // Given
        let task1 = WeddingTask.makeTest(id: UUID(), coupleId: coupleId, taskName: "Book Venue")
        let task2 = WeddingTask.makeTest(id: UUID(), coupleId: coupleId, taskName: "Send Invitations")
        mockRepository.tasks = [task1, task2]

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()
        await store.deleteTask(task1)

        // Then
        XCTAssertNil(store.error)
        XCTAssertEqual(store.tasks.count, 1)
        XCTAssertEqual(store.tasks.first?.taskName, "Send Invitations")
    }

    func testDeleteTask_Failure_RollsBack() async throws {
        // Given
        let task = WeddingTask.makeTest(id: UUID(), coupleId: coupleId, taskName: "Book Venue")
        mockRepository.tasks = [task]

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()

        mockRepository.shouldThrowError = true
        await store.deleteTask(task)

        // Then - Should rollback
        XCTAssertNotNil(store.error)
        XCTAssertEqual(store.tasks.count, 1)
    }

    func testUpdateTaskStatus() async throws {
        // Given
        let task = WeddingTask.makeTest(id: UUID(), coupleId: coupleId, taskName: "Book Venue", status: .notStarted)
        mockRepository.tasks = [task]

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()
        await store.toggleTaskStatus(task)

        // Then
        XCTAssertEqual(store.tasks.first?.status, .completed)
    }

    // MARK: - Computed Properties Tests

    func testComputedProperty_TotalTasks() async throws {
        // Given
        let tasks = [
            WeddingTask.makeTest(coupleId: coupleId),
            WeddingTask.makeTest(coupleId: coupleId),
            WeddingTask.makeTest(coupleId: coupleId)
        ]
        mockRepository.tasks = tasks

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()

        // Then
        XCTAssertEqual(store.tasks.count, 3)
    }

    func testComputedProperty_CompletedTasks() async throws {
        // Given
        let tasks = [
            WeddingTask.makeTest(coupleId: coupleId, status: .completed),
            WeddingTask.makeTest(coupleId: coupleId, status: .completed),
            WeddingTask.makeTest(coupleId: coupleId, status: .notStarted)
        ]
        mockRepository.tasks = tasks

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()

        // Then
        let completedTasks = store.tasks(for: .completed)
        XCTAssertEqual(completedTasks.count, 2)
    }

    func testComputedProperty_OverdueTasks() async throws {
        // Given
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let tasks = [
            WeddingTask.makeTest(coupleId: coupleId, status: .notStarted, dueDate: pastDate),
            WeddingTask.makeTest(coupleId: coupleId, status: .inProgress, dueDate: pastDate)
        ]
        mockRepository.tasks = tasks

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()

        // Then
        XCTAssertEqual(store.overdueTasks.count, 2)
    }

    func testComputedProperty_TasksInProgress() async throws {
        // Given
        let tasks = [
            WeddingTask.makeTest(coupleId: coupleId, status: .inProgress),
            WeddingTask.makeTest(coupleId: coupleId, status: .inProgress),
            WeddingTask.makeTest(coupleId: coupleId, status: .notStarted)
        ]
        mockRepository.tasks = tasks

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()

        // Then
        let inProgressTasks = store.tasks(for: .inProgress)
        XCTAssertEqual(inProgressTasks.count, 2)
    }

    func testFilterByStatus() async throws {
        // Given
        let tasks = [
            WeddingTask.makeTest(coupleId: coupleId, taskName: "Task 1", status: .completed),
            WeddingTask.makeTest(coupleId: coupleId, taskName: "Task 2", status: .notStarted),
            WeddingTask.makeTest(coupleId: coupleId, taskName: "Task 3", status: .completed)
        ]
        mockRepository.tasks = tasks

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()
        let completedTasks = store.tasks(for: .completed)

        // Then
        XCTAssertEqual(completedTasks.count, 2)
        XCTAssertTrue(completedTasks.allSatisfy { $0.status == .completed })
    }

    func testFilterByPriority() async throws {
        // Given
        let tasks = [
            WeddingTask.makeTest(coupleId: coupleId, priority: .high),
            WeddingTask.makeTest(coupleId: coupleId, priority: .low),
            WeddingTask.makeTest(coupleId: coupleId, priority: .high)
        ]
        mockRepository.tasks = tasks

        // When
        let store = await withDependencies {
            $0.taskRepository = mockRepository
        } operation: {
            TaskStoreV2()
        }

        await store.loadTasks()
        store.filterPriority = .high
        let filtered = store.filteredTasks

        // Then
        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { $0.priority == .high })
    }
}
