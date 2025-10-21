//
//  GuestError.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/9/25.
//

import Foundation

enum GuestError: LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case notFound(id: UUID)
    case validationFailed(reason: String)
    case networkUnavailable
    case unauthorized
    case duplicateGuest(name: String)
    case invalidEmail(email: String)
    case invalidPlusOne(reason: String)
    case rsvpDeadlinePassed
    case guestListFull(maxCapacity: Int)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Unable to load guest list. Please check your connection and try again."
        case .createFailed:
            return "Couldn't add the guest. Please try again."
        case .updateFailed:
            return "Couldn't save your guest changes. Please try again."
        case .deleteFailed:
            return "Couldn't delete the guest. Please try again."
        case .notFound:
            return "This guest no longer exists."
        case .validationFailed(let reason):
            return "Invalid guest information: \(reason)"
        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."
        case .unauthorized:
            return "You don't have permission to modify the guest list."
        case .duplicateGuest(let name):
            return "A guest named '\(name)' is already on your list."
        case .invalidEmail(let email):
            return "Invalid email address: \(email)"
        case .invalidPlusOne(let reason):
            return "Invalid plus-one information: \(reason)"
        case .rsvpDeadlinePassed:
            return "The RSVP deadline has passed for this guest."
        case .guestListFull(let maxCapacity):
            return "Guest list is full. Maximum capacity is \(maxCapacity) guests."
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
        case .duplicateGuest:
            return "Please check if this guest is already on your list or use a different name."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidPlusOne:
            return "Please verify the plus-one information and try again."
        case .rsvpDeadlinePassed:
            return "Contact the guest directly to update their RSVP status."
        case .guestListFull:
            return "Remove a guest or increase your venue capacity."
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
        case .notFound, .validationFailed, .unauthorized, .duplicateGuest, .invalidEmail, .invalidPlusOne, .rsvpDeadlinePassed, .guestListFull:
            return false
        }
    }
}
