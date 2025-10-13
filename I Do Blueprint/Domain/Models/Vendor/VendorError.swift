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
}
