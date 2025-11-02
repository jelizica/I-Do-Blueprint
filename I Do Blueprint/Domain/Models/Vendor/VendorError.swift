//
//  VendorError.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/9/25.
//

import Foundation

enum VendorError: LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case notFound(id: Int64)
    case validationFailed(reason: String)
    case networkUnavailable
    case unauthorized
    case duplicateVendor(name: String)
    case invalidContact(reason: String)
    case categoryNotFound
    case contractUploadFailed(underlying: Error)
    case importFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Unable to load vendors. Please check your connection and try again."
        case .createFailed:
            return "Couldn't add the vendor. Please try again."
        case .updateFailed:
            return "Couldn't save your vendor changes. Please try again."
        case .deleteFailed:
            return "Couldn't delete the vendor. Please try again."
        case .notFound:
            return "This vendor no longer exists."
        case .validationFailed(let reason):
            return "Invalid vendor information: \(reason)"
        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."
        case .unauthorized:
            return "You don't have permission to modify vendors."
        case .duplicateVendor(let name):
            return "A vendor named '\(name)' already exists."
        case .invalidContact(let reason):
            return "Invalid contact information: \(reason)"
        case .categoryNotFound:
            return "The selected vendor category doesn't exist."
        case .contractUploadFailed:
            return "Couldn't upload the contract. Please try again."
        case .importFailed:
            return "Couldn't import vendors from CSV. Please try again."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .unauthorized:
            return "Please sign in again or contact support."
        case .fetchFailed, .createFailed, .updateFailed, .deleteFailed, .importFailed:
            return "If the problem persists, please contact support."
        case .duplicateVendor:
            return "Please use a different vendor name or update the existing vendor."
        case .invalidContact:
            return "Please check the email address and phone number format."
        case .categoryNotFound:
            return "Please select a valid vendor category from the list."
        case .contractUploadFailed:
            return "Please check the file size and format, then try again."
        default:
            return nil
        }
    }

    /// Indicates whether this error is transient and can be retried
    var isRetryable: Bool {
        switch self {
        case .fetchFailed, .createFailed, .updateFailed, .deleteFailed, .importFailed:
            return true
        case .networkUnavailable:
            return true
        case .contractUploadFailed:
            return true
        case .notFound, .validationFailed, .unauthorized, .duplicateVendor, .invalidContact, .categoryNotFound:
            return false
        }
    }
}

// MARK: - AppError Conformance
extension VendorError: AppError {
    var errorCode: String {
        switch self {
        case .fetchFailed: return "VENDOR_FETCH_FAILED"
        case .createFailed: return "VENDOR_CREATE_FAILED"
        case .updateFailed: return "VENDOR_UPDATE_FAILED"
        case .deleteFailed: return "VENDOR_DELETE_FAILED"
        case .notFound: return "VENDOR_NOT_FOUND"
        case .validationFailed: return "VENDOR_VALIDATION_FAILED"
        case .networkUnavailable: return "VENDOR_NETWORK_UNAVAILABLE"
        case .unauthorized: return "VENDOR_UNAUTHORIZED"
        case .duplicateVendor: return "VENDOR_DUPLICATE"
        case .invalidContact: return "VENDOR_INVALID_CONTACT"
        case .categoryNotFound: return "VENDOR_CATEGORY_NOT_FOUND"
        case .contractUploadFailed: return "VENDOR_CONTRACT_UPLOAD_FAILED"
        case .importFailed: return "VENDOR_IMPORT_FAILED"
        }
    }

    var userMessage: String { errorDescription ?? "An error occurred." }

    var technicalDetails: String {
        switch self {
        case .fetchFailed(let underlying): return "Fetch failed: \(underlying.localizedDescription)"
        case .createFailed(let underlying): return "Create failed: \(underlying.localizedDescription)"
        case .updateFailed(let underlying): return "Update failed: \(underlying.localizedDescription)"
        case .deleteFailed(let underlying): return "Delete failed: \(underlying.localizedDescription)"
        case .notFound(let id): return "Vendor not found: \(id)"
        case .validationFailed(let reason): return "Validation failed: \(reason)"
        case .networkUnavailable: return "No network connection"
        case .unauthorized: return "Unauthorized"
        case .duplicateVendor(let name): return "Duplicate vendor: \(name)"
        case .invalidContact(let reason): return "Invalid contact: \(reason)"
        case .categoryNotFound: return "Category not found"
        case .contractUploadFailed(let underlying): return "Contract upload failed: \(underlying.localizedDescription)"
        case .importFailed(let underlying): return "Import failed: \(underlying.localizedDescription)"
        }
    }

    var recoveryOptions: [ErrorRecoveryOption] {
        switch self {
        case .networkUnavailable: return [.checkConnection, .retry, .viewOfflineData]
        case .fetchFailed: return [.retry, .checkConnection, .viewOfflineData]
        case .createFailed, .updateFailed, .deleteFailed, .importFailed, .contractUploadFailed: return [.retry, .cancel]
        case .unauthorized: return [.cancel, .contactSupport]
        case .validationFailed, .duplicateVendor, .invalidContact, .categoryNotFound, .notFound: return [.cancel]
        }
    }

    var severity: ErrorSeverity {
        switch self {
        case .networkUnavailable, .fetchFailed: return .warning
        case .createFailed, .updateFailed, .deleteFailed, .contractUploadFailed, .importFailed: return .error
        case .unauthorized: return .critical
        case .validationFailed, .duplicateVendor, .invalidContact, .categoryNotFound: return .error
        case .notFound: return .warning
        }
    }

    var shouldReport: Bool {
        switch self {
        case .validationFailed, .duplicateVendor, .invalidContact: return false
        default: return true
        }
    }
}
