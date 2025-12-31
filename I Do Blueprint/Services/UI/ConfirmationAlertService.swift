//
//  ConfirmationAlertService.swift
//  I Do Blueprint
//
//  Service for confirmation dialog presentation
//

import AppKit
import Foundation

// MARK: - Confirmation Alert Service

/// Service for presenting confirmation dialogs
@MainActor
class ConfirmationAlertService {
    static let shared = ConfirmationAlertService()

    private init() {}

    /// Present a confirmation alert with Yes/No buttons asynchronously
    func showConfirmation(
        title: String,
        message: String,
        confirmButton: String = "Yes",
        cancelButton: String = "No",
        style: NSAlert.Style = .warning
    ) async -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: confirmButton)
        alert.addButton(withTitle: cancelButton)

        guard let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first else {
            return false
        }

        let response = await withCheckedContinuation { (continuation: CheckedContinuation<NSApplication.ModalResponse, Never>) in
            alert.beginSheetModal(for: window) { response in
                continuation.resume(returning: response)
            }
        }

        return response == .alertFirstButtonReturn
    }

    /// Present a confirmation alert with callback-based completion (deprecated)
    @available(*, deprecated, message: "Use async version instead")
    func showConfirmation(
        title: String,
        message: String,
        confirmButton: String = "Yes",
        cancelButton: String = "No",
        style: NSAlert.Style = .warning,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        Task {
            let confirmed = await showConfirmation(
                title: title,
                message: message,
                confirmButton: confirmButton,
                cancelButton: cancelButton,
                style: style
            )
            if confirmed {
                onConfirm()
            } else {
                onCancel?()
            }
        }
    }
}
