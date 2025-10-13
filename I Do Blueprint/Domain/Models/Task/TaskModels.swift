//
//  TaskModels.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Foundation

// MARK: - Wedding Task Model

struct WeddingTask: Codable, Equatable, Identifiable {
    let id: UUID
    let coupleId: UUID
    var taskName: String
    var description: String?
    var budgetCategoryId: UUID?
    var priority: WeddingTaskPriority
    var dueDate: Date?
    var startDate: Date?
    var assignedTo: [String]
    var vendorId: Int64?
    var status: TaskStatus
    var dependsOnTaskId: UUID?
    var estimatedHours: Double?
    var costEstimate: Double?
    var notes: String?
    var milestoneId: UUID?
    let createdAt: Date
    var updatedAt: Date

    // Relationships
    var subtasks: [Subtask]?
    var milestone: Milestone?
    var vendor: VendorSummary?
    var budgetCategory: BudgetCategorySummary?

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case taskName = "task_name"
        case description
        case budgetCategoryId = "budget_category_id"
        case priority
        case dueDate = "due_date"
        case startDate = "start_date"
        case assignedTo = "assigned_to"
        case vendorId = "vendor_id"
        case status
        case dependsOnTaskId = "depends_on_task_id"
        case estimatedHours = "estimated_hours"
        case costEstimate = "cost_estimate"
        case notes
        case milestoneId = "milestone_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case subtasks
        case milestone
        case vendor
        case budgetCategory = "budget_category"
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case onHold = "on_hold"
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .notStarted: "Not Started"
        case .inProgress: "In Progress"
        case .onHold: "On Hold"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        }
    }

    var color: String {
        switch self {
        case .notStarted: "#6B7280" // gray
        case .inProgress: "#3B82F6" // blue
        case .onHold: "#F59E0B" // yellow
        case .completed: "#10B981" // green
        case .cancelled: "#EF4444" // red
        }
    }
}

enum WeddingTaskPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case urgent

    var displayName: String {
        rawValue.capitalized
    }

    var color: String {
        switch self {
        case .low: "#6B7280" // gray
        case .medium: "#3B82F6" // blue
        case .high: "#F59E0B" // orange
        case .urgent: "#EF4444" // red
        }
    }
}

// MARK: - Subtask Model

struct Subtask: Codable, Equatable, Identifiable {
    let id: UUID
    let taskId: UUID
    var subtaskName: String
    var status: TaskStatus
    var assignedTo: [String]
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case subtaskName = "subtask_name"
        case status
        case assignedTo = "assigned_to"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Budget Category Summary

struct BudgetCategorySummary: Codable, Equatable, Identifiable {
    let id: UUID
    let categoryName: String
    let parentCategoryId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case categoryName = "category_name"
        case parentCategoryId = "parent_category_id"
    }
}

// MARK: - Task Insert/Update Data

struct TaskInsertData: Codable {
    var taskName: String
    var description: String?
    var budgetCategoryId: UUID?
    var priority: WeddingTaskPriority
    var dueDate: String?
    var startDate: String?
    var assignedTo: [String]
    var vendorId: Int64?
    var status: TaskStatus
    var dependsOnTaskId: UUID?
    var estimatedHours: Double?
    var costEstimate: Double?
    var notes: String?
    var milestoneId: UUID?

    enum CodingKeys: String, CodingKey {
        case taskName = "task_name"
        case description
        case budgetCategoryId = "budget_category_id"
        case priority
        case dueDate = "due_date"
        case startDate = "start_date"
        case assignedTo = "assigned_to"
        case vendorId = "vendor_id"
        case status
        case dependsOnTaskId = "depends_on_task_id"
        case estimatedHours = "estimated_hours"
        case costEstimate = "cost_estimate"
        case notes
        case milestoneId = "milestone_id"
    }
}

struct SubtaskInsertData: Codable {
    var subtaskName: String
    var status: TaskStatus
    var assignedTo: [String]
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case subtaskName = "subtask_name"
        case status
        case assignedTo = "assigned_to"
        case notes
    }
}
