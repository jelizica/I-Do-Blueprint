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

// MARK: - AppError Conformance
extension GuestError: AppError {
    var errorCode: String {
        switch self {
        case .fetchFailed: return "GUEST_FETCH_FAILED"
        case .createFailed: return "GUEST_CREATE_FAILED"
        case .updateFailed: return "GUEST_UPDATE_FAILED"
        case .deleteFailed: return "GUEST_DELETE_FAILED"
        case .notFound: return "GUEST_NOT_FOUND"
        case .validationFailed: return "GUEST_VALIDATION_FAILED"
        case .networkUnavailable: return "GUEST_NETWORK_UNAVAILABLE"
        case .unauthorized: return "GUEST_UNAUTHORIZED"
        case .duplicateGuest: return "GUEST_DUPLICATE"
        case .invalidEmail: return "GUEST_INVALID_EMAIL"
        case .invalidPlusOne: return "GUEST_INVALID_PLUS_ONE"
        case .rsvpDeadlinePassed: return "GUEST_RSVP_DEADLINE"
        case .guestListFull: return "GUEST_LIST_FULL"
        }
    }

    var userMessage: String { errorDescription ?? "An error occurred." }

    var technicalDetails: String {
        switch self {
        case .fetchFailed(let underlying): return "Fetch failed: \(underlying.localizedDescription)"
        case .createFailed(let underlying): return "Create failed: \(underlying.localizedDescription)"
        case .updateFailed(let underlying): return "Update failed: \(underlying.localizedDescription)"
        case .deleteFailed(let underlying): return "Delete failed: \(underlying.localizedDescription)"
        case .notFound(let id): return "Guest not found: \(id)"
        case .validationFailed(let reason): return "Validation failed: \(reason)"
        case .networkUnavailable: return "No network connection"
        case .unauthorized: return "Unauthorized"
        case .duplicateGuest(let name): return "Duplicate guest: \(name)"
        case .invalidEmail(let email): return "Invalid email: \(email)"
        case .invalidPlusOne(let reason): return "Invalid plus one: \(reason)"
        case .rsvpDeadlinePassed: return "RSVP deadline passed"
        case .guestListFull(let max): return "Guest list full (max=\(max))"
        }
    }

    var recoveryOptions: [ErrorRecoveryOption] {
        switch self {
        case .networkUnavailable: return [.checkConnection, .retry, .viewOfflineData]
        case .fetchFailed: return [.retry, .checkConnection, .viewOfflineData]
        case .createFailed, .updateFailed, .deleteFailed: return [.retry, .cancel]
        case .unauthorized: return [.cancel, .contactSupport]
        case .validationFailed, .duplicateGuest, .invalidEmail, .invalidPlusOne, .rsvpDeadlinePassed, .guestListFull, .notFound: return [.cancel]
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .networkUnavailable, .fetchFailed: return .warning
        case .createFailed, .updateFailed, .deleteFailed: return .error
        case .unauthorized: return .critical
        case .validationFailed, .duplicateGuest, .invalidEmail, .invalidPlusOne: return .error
        case .rsvpDeadlinePassed, .guestListFull, .notFound: return .warning
        }
    }

    var shouldReport: Bool {
        switch self {
        case .validationFailed, .duplicateGuest, .invalidEmail, .invalidPlusOne: return false
        default: return true
        }
    }
}
