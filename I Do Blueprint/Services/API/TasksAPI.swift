//
//  TasksAPI.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Foundation
import Supabase

class TasksAPI {
    private let supabase: SupabaseClient

    init(supabase: SupabaseClient = SupabaseManager.shared.client) {
        self.supabase = supabase
    }

    // MARK: - Fetch Tasks

    func fetchTasks() async throws -> [WeddingTask] {
        let response: [WeddingTask] = try await supabase
            .from("wedding_tasks")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    func fetchTaskById(_ id: UUID) async throws -> WeddingTask {
        let response: WeddingTask = try await supabase
            .from("wedding_tasks")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - Create Task

    func createTask(_ taskData: TaskInsertData) async throws -> WeddingTask {
        let response: WeddingTask = try await supabase
            .from("wedding_tasks")
            .insert(taskData)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - Update Task

    func updateTask(_ id: UUID, data: TaskInsertData) async throws -> WeddingTask {
        let response: WeddingTask = try await supabase
            .from("wedding_tasks")
            .update(data)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func updateTaskStatus(_ id: UUID, status: TaskStatus) async throws -> WeddingTask {
        let response: WeddingTask = try await supabase
            .from("wedding_tasks")
            .update(["status": status.rawValue])
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    // MARK: - Delete Task

    func deleteTask(_ id: UUID) async throws {
        try await supabase
            .from("wedding_tasks")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Subtasks

    func fetchSubtasks(taskId: UUID) async throws -> [Subtask] {
        let response: [Subtask] = try await supabase
            .from("task_subtasks")
            .select()
            .eq("task_id", value: taskId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value

        return response
    }

    func createSubtask(taskId: UUID, data: SubtaskInsertData) async throws -> Subtask {
        // Create a subtask insert struct
        struct SubtaskInsert: Encodable {
            let taskId: String
            let subtaskName: String
            let status: String
            let assignedTo: [String]
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case taskId = "task_id"
                case subtaskName = "subtask_name"
                case status
                case assignedTo = "assigned_to"
                case notes
            }
        }

        let insertData = SubtaskInsert(
            taskId: taskId.uuidString,
            subtaskName: data.subtaskName,
            status: data.status.rawValue,
            assignedTo: data.assignedTo,
            notes: data.notes)

        let response: Subtask = try await supabase
            .from("task_subtasks")
            .insert(insertData)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func updateSubtask(_ id: UUID, data: SubtaskInsertData) async throws -> Subtask {
        // Create a subtask update struct
        struct SubtaskUpdate: Encodable {
            let subtaskName: String
            let status: String
            let assignedTo: [String]
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case subtaskName = "subtask_name"
                case status
                case assignedTo = "assigned_to"
                case notes
            }
        }

        let updateData = SubtaskUpdate(
            subtaskName: data.subtaskName,
            status: data.status.rawValue,
            assignedTo: data.assignedTo,
            notes: data.notes)

        let response: Subtask = try await supabase
            .from("task_subtasks")
            .update(updateData)
            .eq("id", value: id.uuidString)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func deleteSubtask(_ id: UUID) async throws {
        try await supabase
            .from("task_subtasks")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Batch Operations

    func updateTasksOrder(tasks _: [WeddingTask]) async throws {
        // Batch update task positions if needed
        // For now, tasks will be ordered by status and created_at
    }
}
