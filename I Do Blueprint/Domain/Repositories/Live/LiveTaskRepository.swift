//
//  LiveTaskRepository.swift
//  My Wedding Planning App
//
//  Supabase implementation of task repository
//

import Foundation
import Supabase

actor LiveTaskRepository: TaskRepositoryProtocol {
    private let client = SupabaseManager.shared.client

    func fetchTasks() async throws -> [WeddingTask] {
        return try await client.database
            .from("wedding_tasks")
            .select("""
                *,
                subtasks:wedding_subtasks(*),
                milestone:wedding_milestones(*),
                vendor:vendors(id, vendor_name),
                budget_category:budget_categories(id, category_name, parent_category_id)
            """)
            .order("due_date", ascending: true)
            .execute()
            .value
    }

    func fetchTask(id: UUID) async throws -> WeddingTask? {
        let tasks: [WeddingTask] = try await client.database
            .from("wedding_tasks")
            .select("""
                *,
                subtasks:wedding_subtasks(*),
                milestone:wedding_milestones(*),
                vendor:vendors(id, vendor_name),
                budget_category:budget_categories(id, category_name, parent_category_id)
            """)
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        return tasks.first
    }

    func createTask(_ insertData: TaskInsertData) async throws -> WeddingTask {
        return try await client.database
            .from("wedding_tasks")
            .insert(insertData)
            .select()
            .single()
            .execute()
            .value
    }

    func updateTask(_ task: WeddingTask) async throws -> WeddingTask {
        return try await client.database
            .from("wedding_tasks")
            .update(task)
            .eq("id", value: task.id)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteTask(id: UUID) async throws {
        try await client.database
            .from("wedding_tasks")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Subtasks

    func fetchSubtasks(taskId: UUID) async throws -> [Subtask] {
        return try await client.database
            .from("wedding_subtasks")
            .select()
            .eq("task_id", value: taskId)
            .order("created_at")
            .execute()
            .value
    }

    func createSubtask(taskId: UUID, insertData: SubtaskInsertData) async throws -> Subtask {
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

        let insert = SubtaskInsert(taskId: taskId, data: insertData)
        return try await client.database
            .from("wedding_subtasks")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
    }

    func updateSubtask(_ subtask: Subtask) async throws -> Subtask {
        return try await client.database
            .from("wedding_subtasks")
            .update(subtask)
            .eq("id", value: subtask.id)
            .select()
            .single()
            .execute()
            .value
    }

    func deleteSubtask(id: UUID) async throws {
        try await client.database
            .from("wedding_subtasks")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Statistics

    func fetchTaskStats() async throws -> TaskStats {
        let tasks: [WeddingTask] = try await fetchTasks()
        let now = Date()

        return TaskStats(
            total: tasks.count,
            notStarted: tasks.filter { $0.status == .notStarted }.count,
            inProgress: tasks.filter { $0.status == .inProgress }.count,
            completed: tasks.filter { $0.status == .completed }.count,
            overdue: tasks.filter { !$0.status.isCompleted && ($0.dueDate ?? .distantFuture) < now }.count)
    }
}

private extension TaskStatus {
    var isCompleted: Bool {
        self == .completed
    }
}
