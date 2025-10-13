//
//  TimelineError.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/9/25.
//

import Foundation

enum TimelineError: LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case notFound(id: UUID)
    case validationFailed(reason: String)
    case networkUnavailable
    case unauthorized
    case invalidDate(reason: String)
    case conflictingEvent(date: Date)
    case eventInPast
    case invalidDuration(reason: String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Unable to load timeline events. Please check your connection and try again."
        case .createFailed:
            return "Couldn't create the timeline event. Please try again."
        case .updateFailed:
            return "Couldn't save your timeline changes. Please try again."
        case .deleteFailed:
            return "Couldn't delete the timeline event. Please try again."
        case .notFound:
            return "This timeline event no longer exists."
        case .validationFailed(let reason):
            return "Invalid timeline data: \(reason)"
        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."
        case .unauthorized:
            return "You don't have permission to modify the timeline."
        case .invalidDate(let reason):
            return "Invalid event date: \(reason)"
        case .conflictingEvent(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return "Another event is already scheduled at \(formatter.string(from: date))."
        case .eventInPast:
            return "Cannot create events in the past."
        case .invalidDuration(let reason):
            return "Invalid event duration: \(reason)"
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
        case .invalidDate:
            return "Please select a valid date for the event."
        case .conflictingEvent:
            return "Choose a different time or reschedule the conflicting event."
        case .eventInPast:
            return "Please select a future date for the event."
        case .invalidDuration:
            return "Event duration must be at least 15 minutes."
        default:
            return nil
        }
    }
}
