//
//  TimelineModels.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Foundation

// MARK: - Timeline Item Model

struct TimelineItem: Codable, Equatable, Identifiable {
    let id: UUID
    let coupleId: UUID
    var title: String
    var description: String?
    var itemType: TimelineItemType
    var itemDate: Date
    var endDate: Date?
    var completed: Bool
    var relatedId: String?
    let createdAt: Date
    var updatedAt: Date

    // Related entities
    var task: TaskSummary?
    var milestone: Milestone?
    var vendor: VendorSummary?
    var payment: PaymentSummary?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case coupleId = "couple_id"
        case title = "title"
        case description = "description"
        case itemType = "item_type"
        case itemDate = "item_date"
        case endDate = "end_date"
        case completed = "completed"
        case relatedId = "related_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case task = "task"
        case milestone = "milestone"
        case vendor = "vendor"
        case payment = "payment"
    }

    var isOverdue: Bool {
        !completed && itemDate < Date()
    }

    var groupKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: itemDate)
    }
}

enum TimelineItemType: String, Codable, CaseIterable {
    case task = "task"
    case milestone = "milestone"
    case vendorEvent = "vendor_event"
    case payment = "payment"
    case reminder = "reminder"
    case ceremony = "ceremony"
    case other = "other"

    var displayName: String {
        switch self {
        case .task: "Task"
        case .milestone: "Milestone"
        case .vendorEvent: "Vendor Event"
        case .payment: "Payment"
        case .reminder: "Reminder"
        case .ceremony: "Ceremony"
        case .other: "Other"
        }
    }

    var iconName: String {
        switch self {
        case .task: "target"
        case .milestone: "star.fill"
        case .vendorEvent: "person.2.fill"
        case .payment: "creditcard.fill"
        case .reminder: "bell.fill"
        case .ceremony: "heart.fill"
        case .other: "circle.fill"
        }
    }

    var color: String {
        switch self {
        case .task: "#9333EA" // purple
        case .milestone: "#EAB308" // yellow
        case .vendorEvent: "#10B981" // green
        case .payment: "#3B82F6" // blue
        case .reminder: "#F97316" // orange
        case .ceremony: "#EC4899" // pink
        case .other: "#6B7280" // gray
        }
    }
}

// MARK: - Milestone Model

struct Milestone: Codable, Equatable, Identifiable {
    let id: UUID
    let coupleId: UUID
    var milestoneName: String
    var description: String?
    var milestoneDate: Date
    var completed: Bool
    var color: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case coupleId = "couple_id"
        case milestoneName = "milestone_name"
        case description = "description"
        case milestoneDate = "milestone_date"
        case completed = "completed"
        case color = "color"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var isOverdue: Bool {
        !completed && milestoneDate < Date()
    }
}

// MARK: - Timeline Insert/Update Data

struct TimelineItemInsertData: Codable {
    var coupleId: UUID
    var title: String
    var description: String?
    var itemType: TimelineItemType
    var itemDate: Date
    var endDate: Date?
    var completed: Bool
    var relatedId: String?

    enum CodingKeys: String, CodingKey {
        case coupleId = "couple_id"
        case title = "title"
        case description = "description"
        case itemType = "item_type"
        case itemDate = "item_date"
        case endDate = "end_date"
        case completed = "completed"
        case relatedId = "related_id"
    }
}

struct MilestoneInsertData: Codable {
    var coupleId: UUID
    var milestoneName: String
    var description: String?
    var milestoneDate: Date
    var completed: Bool
    var color: String?

    enum CodingKeys: String, CodingKey {
        case coupleId = "couple_id"
        case milestoneName = "milestone_name"
        case description = "description"
        case milestoneDate = "milestone_date"
        case completed = "completed"
        case color = "color"
    }
}

// MARK: - Timeline View Modes

enum TimelineViewMode: String, CaseIterable {
    case grouped = "Grouped"
    case linear = "Linear"
}

struct TimelineGroup: Identifiable {
    let id: String
    let title: String
    let items: [TimelineItem]
    var isExpanded: Bool = true

    var completedCount: Int {
        items.filter(\.completed).count
    }

    var overdueCount: Int {
        items.filter(\.isOverdue).count
    }
}
