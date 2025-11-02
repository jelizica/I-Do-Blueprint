//
//  CacheOperation.swift
//  I Do Blueprint
//
//  Canonical set of cache-triggering operations
//

import Foundation

enum CacheOperation {
    // Guest operations
    case guestCreated(tenantId: UUID)
    case guestUpdated(tenantId: UUID)
    case guestDeleted(tenantId: UUID)
    case guestBulkImport(tenantId: UUID)

    // Budget operations
    case categoryCreated
    case categoryUpdated
    case categoryDeleted
    case expenseCreated(tenantId: UUID)
    case expenseUpdated(tenantId: UUID)
    case expenseDeleted(tenantId: UUID)

    // Vendor operations
    case vendorCreated(tenantId: UUID, vendorId: Int64?)
    case vendorUpdated(tenantId: UUID, vendorId: Int64?)
    case vendorDeleted(tenantId: UUID, vendorId: Int64?)

    // Task operations
    case taskCreated(tenantId: UUID, taskId: UUID)
    case taskUpdated(tenantId: UUID, taskId: UUID)
    case taskDeleted(tenantId: UUID, taskId: UUID)
    case subtaskCreated(tenantId: UUID, taskId: UUID)
    case subtaskUpdated(tenantId: UUID, taskId: UUID)

    // Timeline operations
    case timelineItemCreated(tenantId: UUID)
    case timelineItemUpdated(tenantId: UUID)
    case timelineItemDeleted(tenantId: UUID)
    case milestoneCreated(tenantId: UUID)
    case milestoneUpdated(tenantId: UUID)
    case milestoneDeleted(tenantId: UUID)

    // Document operations
    case documentCreated(tenantId: UUID)
    case documentUpdated(tenantId: UUID)
    case documentDeleted(tenantId: UUID)
}
