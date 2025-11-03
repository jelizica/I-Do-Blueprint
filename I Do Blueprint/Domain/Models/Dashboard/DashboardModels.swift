//
//  DashboardModels.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Foundation

// MARK: - Dashboard Summary Metrics

struct DashboardSummary: Codable, Equatable {
    let tasks: TaskMetrics
    let payments: PaymentMetrics
    let reminders: ReminderMetrics
    let timeline: TimelineMetrics
    let guests: GuestMetrics
    let vendors: VendorMetrics
    let documents: DocumentMetrics
    let budget: BudgetMetrics
    let gifts: GiftMetrics
    let notes: NoteMetrics
}

// MARK: - Task Metrics

struct TaskMetrics: Codable, Equatable {
    let total: Int
    let completed: Int
    let inProgress: Int
    let notStarted: Int
    let onHold: Int
    let cancelled: Int
    let overdue: Int
    let dueThisWeek: Int
    let highPriority: Int
    let urgent: Int
    let completionRate: Double
    let recentTasks: [TaskSummary]

    enum CodingKeys: String, CodingKey {
        case total = "total"
        case completed = "completed"
        case inProgress = "in_progress"
        case notStarted = "not_started"
        case onHold = "on_hold"
        case cancelled = "cancelled"
        case overdue = "overdue"
        case dueThisWeek = "due_this_week"
        case highPriority = "high_priority"
        case urgent = "urgent"
        case completionRate = "completion_rate"
        case recentTasks = "recent_tasks"
    }
}

struct TaskSummary: Codable, Equatable, Identifiable {
    let id: UUID
    let taskName: String
    let priority: String
    let status: String
    let dueDate: Date?
    let assignedTo: [String]

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case taskName = "task_name"
        case priority = "priority"
        case status = "status"
        case dueDate = "due_date"
        case assignedTo = "assigned_to"
    }
}

// MARK: - Payment Metrics

struct PaymentMetrics: Codable, Equatable {
    let totalPayments: Int
    let paidPayments: Int
    let unpaidPayments: Int
    let overduePayments: Int
    let upcomingPayments: Int
    let totalAmount: Double
    let paidAmount: Double
    let unpaidAmount: Double
    let overdueAmount: Double
    let recentPayments: [PaymentSummary]

    enum CodingKeys: String, CodingKey {
        case totalPayments = "total_payments"
        case paidPayments = "paid_payments"
        case unpaidPayments = "unpaid_payments"
        case overduePayments = "overdue_payments"
        case upcomingPayments = "upcoming_payments"
        case totalAmount = "total_amount"
        case paidAmount = "paid_amount"
        case unpaidAmount = "unpaid_amount"
        case overdueAmount = "overdue_amount"
        case recentPayments = "recent_payments"
    }
}

struct PaymentSummary: Codable, Equatable, Identifiable {
    let id: Int64
    let vendor: String
    let amount: Double
    let dueDate: Date
    let paid: Bool

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case vendor = "vendor"
        case amount = "amount"
        case dueDate = "payment_date"
        case paid = "paid"
    }
}

// MARK: - Reminder Metrics

struct ReminderMetrics: Codable, Equatable {
    let total: Int
    let active: Int
    let completed: Int
    let overdue: Int
    let dueToday: Int
    let dueThisWeek: Int
    let recentReminders: [ReminderSummary]

    enum CodingKeys: String, CodingKey {
        case total = "total"
        case active = "active"
        case completed = "completed"
        case overdue = "overdue"
        case dueToday = "due_today"
        case dueThisWeek = "due_this_week"
        case recentReminders = "recent_reminders"
    }
}

struct ReminderSummary: Codable, Equatable, Identifiable {
    let id: UUID
    let reminderText: String
    let reminderDate: Date
    let completed: Bool

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case reminderText = "reminder_text"
        case reminderDate = "reminder_date"
        case completed = "completed"
    }
}

// MARK: - Timeline Metrics

struct TimelineMetrics: Codable, Equatable {
    let totalItems: Int
    let completedItems: Int
    let upcomingItems: Int
    let overdueItems: Int
    let milestones: Int
    let completedMilestones: Int
    let recentItems: [TimelineItemSummary]

    enum CodingKeys: String, CodingKey {
        case totalItems = "total_items"
        case completedItems = "completed_items"
        case upcomingItems = "upcoming_items"
        case overdueItems = "overdue_items"
        case milestones = "milestones"
        case completedMilestones = "completed_milestones"
        case recentItems = "recent_items"
    }
}

struct TimelineItemSummary: Codable, Equatable, Identifiable {
    let id: UUID
    let title: String
    let type: String
    let date: Date
    let completed: Bool

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case type = "type"
        case date = "date"
        case completed = "completed"
    }
}

// MARK: - Guest Metrics

struct GuestMetrics: Codable, Equatable {
    let totalGuests: Int
    let rsvpYes: Int
    let rsvpNo: Int
    let rsvpPending: Int
    let attended: Int
    let mealSelections: [String: Int]
    let recentRsvps: [GuestSummary]

    enum CodingKeys: String, CodingKey {
        case totalGuests = "total_guests"
        case rsvpYes = "rsvp_yes"
        case rsvpNo = "rsvp_no"
        case rsvpPending = "rsvp_pending"
        case attended = "attended"
        case mealSelections = "meal_selections"
        case recentRsvps = "recent_rsvps"
    }
}

struct GuestSummary: Codable, Equatable, Identifiable {
    let id: UUID
    let guestName: String
    let rsvpStatus: String?
    let mealSelection: String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case guestName = "guest_name"
        case rsvpStatus = "rsvp_status"
        case mealSelection = "meal_selection"
    }
}

// MARK: - Vendor Metrics

struct VendorMetrics: Codable, Equatable {
    let totalVendors: Int
    let activeContracts: Int
    let pendingContracts: Int
    let completedServices: Int
    let totalSpent: Double
    let recentVendors: [VendorSummary]

    enum CodingKeys: String, CodingKey {
        case totalVendors = "total_vendors"
        case activeContracts = "active_contracts"
        case pendingContracts = "pending_contracts"
        case completedServices = "completed_services"
        case totalSpent = "total_spent"
        case recentVendors = "recent_vendors"
    }
}

struct VendorSummary: Codable, Equatable, Identifiable {
    let id: Int64
    let vendorName: String
    let vendorType: String
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case vendorName = "vendor_name"
        case vendorType = "vendor_type"
        case status = "status"
    }
}

// MARK: - Document Metrics

struct DocumentMetrics: Codable, Equatable {
    let totalDocuments: Int
    let invoices: Int
    let contracts: Int
    let other: Int
    let recentDocuments: [DocumentSummary]

    enum CodingKeys: String, CodingKey {
        case totalDocuments = "total_documents"
        case invoices = "invoices"
        case contracts = "contracts"
        case other = "other"
        case recentDocuments = "recent_documents"
    }
}

struct DocumentSummary: Codable, Equatable, Identifiable {
    let id: UUID
    let documentName: String
    let documentType: String
    let uploadedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case documentName = "document_name"
        case documentType = "document_type"
        case uploadedAt = "uploaded_at"
    }
}

// MARK: - Budget Metrics

struct BudgetMetrics: Codable, Equatable {
    let totalBudget: Double
    let spent: Double
    let remaining: Double
    let percentageUsed: Double
    let categories: Int
    let overBudgetCategories: Int
    let recentExpenses: [ExpenseSummary]

    enum CodingKeys: String, CodingKey {
        case totalBudget = "total_budget"
        case spent = "spent"
        case remaining = "remaining"
        case percentageUsed = "percentage_used"
        case categories = "categories"
        case overBudgetCategories = "over_budget_categories"
        case recentExpenses = "recent_expenses"
    }
}

struct ExpenseSummary: Codable, Equatable, Identifiable {
    let id: UUID
    let expenseName: String
    let amount: Double
    let expenseDate: Date

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case expenseName = "expense_name"
        case amount = "amount"
        case expenseDate = "expense_date"
    }
}

// MARK: - Gift Metrics

struct GiftMetrics: Codable, Equatable {
    let totalGifts: Int
    let totalValue: Double
    let thankedGifts: Int
    let unthankedGifts: Int
    let recentGifts: [GiftSummary]

    enum CodingKeys: String, CodingKey {
        case totalGifts = "total_gifts"
        case totalValue = "total_value"
        case thankedGifts = "thanked_gifts"
        case unthankedGifts = "unthanked_gifts"
        case recentGifts = "recent_gifts"
    }
}

struct GiftSummary: Codable, Equatable, Identifiable {
    let id: UUID
    let giftDescription: String?
    let giftValue: Double?
    let thanked: Bool

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case giftDescription = "gift_description"
        case giftValue = "gift_value"
        case thanked = "thanked"
    }
}

// MARK: - Note Metrics

struct NoteMetrics: Codable, Equatable {
    let totalNotes: Int
    let recentNotes: Int
    let notesByType: [String: Int]
    let recentNotesList: [NoteSummary]

    enum CodingKeys: String, CodingKey {
        case totalNotes = "total_notes"
        case recentNotes = "recent_notes"
        case notesByType = "notes_by_type"
        case recentNotesList = "recent_notes_list"
    }
}

struct NoteSummary: Codable, Equatable, Identifiable {
    let id: UUID
    let title: String?
    let content: String
    let relatedType: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case content = "content"
        case relatedType = "related_type"
        case createdAt = "created_at"
    }
}

// MARK: - Trend Data

struct TrendData: Equatable {
    let percentage: Double
    let period: String
    let isPositive: Bool
}
