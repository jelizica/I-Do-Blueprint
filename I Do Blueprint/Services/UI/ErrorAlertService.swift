//
//  ErrorAlertService.swift
//  I Do Blueprint
//
//  Service for error alert presentation
//

import AppKit
import Foundation

// MARK: - Error Alert Service

/// Service for presenting error alerts
@MainActor
class ErrorAlertService {
    static let shared = ErrorAlertService()

    private init() {}

    /// Present an error alert asynchronously
    func showError(
        title: String = "Error",
        message: String,
        error: Error? = nil
    ) async {
        let fullMessage: String
        if let error = error {
            fullMessage = "\(message)\n\nDetails: \(error.localizedDescription)"
        } else {
            fullMessage = message
        }

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = fullMessage
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")

        guard let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first else {
            return
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            alert.beginSheetModal(for: window) { _ in
                continuation.resume()
            }
        }
    }

    /// Show an error with optional retry action
    func showError(
        title: String = "Error",
        message: String,
        retryAction: (() async -> Void)? = nil
    ) async {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical

        if retryAction != nil {
            alert.addButton(withTitle: "Retry")
            alert.addButton(withTitle: "Cancel")
        } else {
            alert.addButton(withTitle: "OK")
        }

        guard let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first else {
            return
        }

        let response = await withCheckedContinuation { (continuation: CheckedContinuation<NSApplication.ModalResponse, Never>) in
            alert.beginSheetModal(for: window) { response in
                continuation.resume(returning: response)
            }
        }

        if response == .alertFirstButtonReturn, let retry = retryAction {
            await retry()
        }
    }

    /// Show a network error with automatic retry
    func showNetworkError(
        operation: String,
        retry: @escaping () async -> Void
    ) async {
        await showError(
            title: "Network Error",
            message: "Unable to \(operation). Please check your internet connection.",
            retryAction: retry
        )
    }

    /// Show a user-facing error with optional retry
    func showUserFacingError(
        _ error: UserFacingError,
        retryAction: (() async -> Void)? = nil
    ) async {
        let title = error.isRetryable ? "Temporary Error" : "Error"
        let message = [
            error.errorDescription,
            error.recoverySuggestion
        ].compactMap { $0 }.joined(separator: "\n\n")

        if error.isRetryable, let retry = retryAction {
            await showError(title: title, message: message, retryAction: retry)
        } else {
            await showError(title: title, message: message, error: nil)
        }
    }
}
