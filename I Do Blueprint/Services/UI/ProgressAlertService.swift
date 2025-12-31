//
//  ProgressAlertService.swift
//  I Do Blueprint
//
//  Service for progress alert presentation
//

import AppKit
import Foundation

// MARK: - Progress Alert Service

/// Service for presenting progress alerts for long-running operations
@MainActor
class ProgressAlertService {
    static let shared = ProgressAlertService()

    private init() {}

    /// Show a progress alert for long-running operations
    func showProgress(
        title: String,
        message: String,
        operation: @escaping () async throws -> Void
    ) async {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational

        // Create custom accessory view with progress indicator
        let accessoryView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 40))
        let progressIndicator = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: 300, height: 20))
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = true
        progressIndicator.startAnimation(nil)
        accessoryView.addSubview(progressIndicator)

        let statusLabel = NSTextField(frame: NSRect(x: 0, y: 22, width: 300, height: 18))
        statusLabel.stringValue = "Processing..."
        statusLabel.isEditable = false
        statusLabel.isBordered = false
        statusLabel.backgroundColor = .clear
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        accessoryView.addSubview(statusLabel)

        alert.accessoryView = accessoryView

        // Show alert in a detached task so it doesn't block
        let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first

        guard let window = window else {
            // No window available, run operation without progress UI
            do {
                try await operation()
                ToastService.shared.showSuccessToast("Operation completed")
            } catch {
                await ErrorAlertService.shared.showError(message: "Operation failed", error: error)
            }
            return
        }

        Task { @MainActor in
            alert.beginSheetModal(for: window) { _ in
                // Modal dismissed
            }
        }

        // Run the operation
        Task {
            do {
                try await operation()
                await MainActor.run {
                    window.endSheet(alert.window)
                    ToastService.shared.showSuccessToast("Operation completed")
                }
            } catch {
                await MainActor.run {
                    window.endSheet(alert.window)
                }
                await ErrorAlertService.shared.showError(message: "Operation failed", error: error)
            }
        }
    }
}
