//
//  TaskError.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/9/25.
//

import Foundation

enum TaskError: LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case notFound(id: UUID)
    case validationFailed(reason: String)
    case networkUnavailable
    case unauthorized
    case invalidDueDate(reason: String)
    case dependencyNotFound
    case circularDependency
    case statusTransitionInvalid(from: String, to: String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Unable to load tasks. Please check your connection and try again."
        case .createFailed:
            return "Couldn't create the task. Please try again."
        case .updateFailed:
            return "Couldn't save your task changes. Please try again."
        case .deleteFailed:
            return "Couldn't delete the task. Please try again."
        case .notFound:
            return "This task no longer exists."
        case .validationFailed(let reason):
            return "Invalid task data: \(reason)"
        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."
        case .unauthorized:
            return "You don't have permission to modify this task."
        case .invalidDueDate(let reason):
            return "Invalid due date: \(reason)"
        case .dependencyNotFound:
            return "A task dependency no longer exists."
        case .circularDependency:
            return "Cannot create circular task dependencies."
        case .statusTransitionInvalid(let from, let to):
            return "Cannot change task status from \(from) to \(to)."
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
        case .invalidDueDate:
            return "Please select a valid date for the task deadline."
        case .dependencyNotFound:
            return "Please remove the missing dependency or create it first."
        case .circularDependency:
            return "Remove the dependency that creates a circular reference."
        case .statusTransitionInvalid:
            return "Please follow the correct task workflow."
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
        case .notFound, .validationFailed, .unauthorized, .invalidDueDate, .dependencyNotFound, .circularDependency, .statusTransitionInvalid:
            return false
        }
    }
}
