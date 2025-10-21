//
//  BudgetError.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/9/25.
//

import Foundation

enum BudgetError: LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case notFound
    case validationFailed(reason: String)
    case networkUnavailable
    case unauthorized
    case budgetExceeded(category: String, amount: Double)
    case invalidAmount(reason: String)
    case categoryNotFound(name: String)
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Unable to load budget data. Please check your connection and try again."
        case .createFailed:
            return "Couldn't create the budget item. Please try again."
        case .updateFailed:
            return "Couldn't save your budget changes. Please try again."
        case .deleteFailed:
            return "Couldn't delete the budget item. Please try again."
        case .notFound:
            return "This budget item no longer exists."
        case .validationFailed(let reason):
            return "Invalid budget data: \(reason)"
        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."
        case .unauthorized:
            return "You don't have permission to modify the budget."
        case .budgetExceeded(let category, let amount):
            return "Budget exceeded for \(category) by $\(String(format: "%.2f", amount))."
        case .invalidAmount(let reason):
            return "Invalid amount: \(reason)"
        case .categoryNotFound(let name):
            return "Category '\(name)' not found in your budget."
        case .notImplemented:
            return "This feature is not yet implemented."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .unauthorized:
            return "Please sign in again or contact support."
        case .fetchFailed, .createFailed, .updateFailed, .deleteFailed:
            return "If the problem persists, please contact support."
        case .budgetExceeded:
            return "Consider adjusting your budget allocation or reducing expenses in this category."
        case .invalidAmount:
            return "Please enter a valid dollar amount greater than zero."
        case .categoryNotFound:
            return "Please select a valid budget category."
        default:
            return nil
        }
    }

    /// Indicates whether this error is transient and can be retried
    var isRetryable: Bool {
        switch self {
        case .fetchFailed, .createFailed, .updateFailed, .deleteFailed:
            return true
        case .networkUnavailable:
            return true
        case .notFound, .validationFailed, .unauthorized, .budgetExceeded, .invalidAmount, .categoryNotFound, .notImplemented:
            return false
        }
    }
}
