//
//  DocumentError.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 10/9/25.
//

import Foundation

enum DocumentError: LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case notFound(id: UUID)
    case validationFailed(reason: String)
    case networkUnavailable
    case unauthorized
    case uploadFailed(underlying: Error)
    case downloadFailed(underlying: Error)
    case fileTooLarge(maxSize: Int)
    case unsupportedFileType(type: String)
    case storageFull
    case invalidFileName(reason: String)

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Unable to load documents. Please check your connection and try again."
        case .createFailed:
            return "Couldn't create the document record. Please try again."
        case .updateFailed:
            return "Couldn't save your document changes. Please try again."
        case .deleteFailed:
            return "Couldn't delete the document. Please try again."
        case .notFound:
            return "This document no longer exists."
        case .validationFailed(let reason):
            return "Invalid document data: \(reason)"
        case .networkUnavailable:
            return "No internet connection available. Please check your network settings."
        case .unauthorized:
            return "You don't have permission to access this document."
        case .uploadFailed:
            return "Couldn't upload the document. Please try again."
        case .downloadFailed:
            return "Couldn't download the document. Please try again."
        case .fileTooLarge(let maxSize):
            return "File is too large. Maximum size is \(maxSize) MB."
        case .unsupportedFileType(let type):
            return "File type '\(type)' is not supported."
        case .storageFull:
            return "Storage is full. Please delete some documents to make space."
        case .invalidFileName(let reason):
            return "Invalid file name: \(reason)"
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
        case .uploadFailed, .downloadFailed:
            return "Check your internet connection and try again."
        case .fileTooLarge:
            return "Please compress the file or upload a smaller version."
        case .unsupportedFileType:
            return "Please convert the file to a supported format (PDF, DOCX, XLSX, PNG, JPG)."
        case .storageFull:
            return "Delete old documents or upgrade your storage plan."
        case .invalidFileName:
            return "Use only letters, numbers, spaces, and common punctuation in file names."
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
        case .uploadFailed, .downloadFailed:
            return true
        case .notFound, .validationFailed, .unauthorized, .fileTooLarge, .unsupportedFileType, .storageFull, .invalidFileName:
            return false
        }
    }
}
