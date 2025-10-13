//
//  NotesError.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/9/25.
//

import Foundation

enum NotesError: LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case notFound(id: UUID)
    case validationFailed(reason: String)
    case networkUnavailable
    case unauthorized
    case emptyContent
    case titleTooLong(maxLength: Int)
    case contentTooLong(maxLength: Int)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Unable to load notes. Please check your connection and try again."
        case .createFailed:
            return "Couldn't create the note. Please try again."
        case .updateFailed:
            return "Couldn't save your note changes. Please try again."
        case .deleteFailed:
            return "Couldn't delete the note. Please try again."
        case .notFound:
            return "This note no longer exists."
        case .validationFailed(let reason):
            return "Invalid note data: \(reason)"
        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."
        case .unauthorized:
            return "You don't have permission to modify this note."
        case .emptyContent:
            return "Note content cannot be empty."
        case .titleTooLong(let maxLength):
            return "Note title is too long. Maximum length is \(maxLength) characters."
        case .contentTooLong(let maxLength):
            return "Note content is too long. Maximum length is \(maxLength) characters."
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
        case .emptyContent:
            return "Please add some content to the note before saving."
        case .titleTooLong, .contentTooLong:
            return "Please shorten the text and try again."
        default:
            return nil
        }
    }
}
