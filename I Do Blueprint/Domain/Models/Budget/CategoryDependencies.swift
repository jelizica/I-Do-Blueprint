//
//  CategoryDependencies.swift
//  I Do Blueprint
//
//  Data models for budget category dependency checking and batch operations
//

import Foundation

/// Represents dependencies that prevent category deletion
struct CategoryDependencies: Sendable {
    let categoryId: UUID
    let categoryName: String
    let expenseCount: Int
    let budgetItemCount: Int
    let subcategoryCount: Int
    let taskCount: Int
    let vendorCount: Int
    
    /// Whether the category can be safely deleted
    var canDelete: Bool {
        expenseCount == 0 && subcategoryCount == 0 && taskCount == 0 && vendorCount == 0
    }
    
    /// Reasons why deletion is blocked
    var blockingReasons: [String] {
        var reasons: [String] = []
        if expenseCount > 0 {
            reasons.append("\(expenseCount) expense\(expenseCount == 1 ? "" : "s")")
        }
        if subcategoryCount > 0 {
            reasons.append("\(subcategoryCount) subcategor\(subcategoryCount == 1 ? "y" : "ies")")
        }
        if taskCount > 0 {
            reasons.append("\(taskCount) task\(taskCount == 1 ? "" : "s")")
        }
        if vendorCount > 0 {
            reasons.append("\(vendorCount) vendor\(vendorCount == 1 ? "" : "s")")
        }
        return reasons
    }
    
    /// User-friendly summary message
    var summary: String {
        if canDelete {
            if budgetItemCount > 0 {
                return "This category has \(budgetItemCount) budget item\(budgetItemCount == 1 ? "" : "s") that will be orphaned."
            }
            return "This category can be safely deleted."
        } else {
            let reasons = blockingReasons.joined(separator: ", ")
            return "Cannot delete: linked to \(reasons)."
        }
    }
}

/// Result of a batch delete operation
struct BatchDeleteResult: Sendable {
    let succeeded: [UUID]
    struct SendableErrorWrapper: Sendable, Codable, Equatable {
        let typeName: String
        let message: String

        init(_ error: Error) {
            self.typeName = String(describing: type(of: error))
            self.message = error.localizedDescription
        }
    }

    let failed: [(UUID, SendableErrorWrapper)]
    
    var successCount: Int { succeeded.count }
    var failureCount: Int { failed.count }
    var totalAttempted: Int { successCount + failureCount }
    
    /// User-friendly summary message
    var summary: String {
        if failureCount == 0 {
            return "Successfully deleted \(successCount) categor\(successCount == 1 ? "y" : "ies")."
        } else if successCount == 0 {
            return "Failed to delete all \(failureCount) categor\(failureCount == 1 ? "y" : "ies")."
        } else {
            return "Deleted \(successCount) categor\(successCount == 1 ? "y" : "ies"), \(failureCount) failed."
        }
    }
}
