//
//  ToastService.swift
//  I Do Blueprint
//
//  Service for non-blocking toast notifications
//

import Combine
import Foundation
import SwiftUI

// MARK: - Toast Configuration

struct ToastConfig: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval
}

extension ToastType {
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Toast Service

/// Service for presenting non-blocking toast notifications
@MainActor
class ToastService: ObservableObject {
    static let shared = ToastService()

    @Published var currentToast: ToastConfig?

    private init() {}

    /// Show a non-blocking toast notification
    func showToast(
        message: String,
        type: ToastType = .info,
        duration: TimeInterval = 3.0
    ) {
        currentToast = ToastConfig(
            message: message,
            type: type,
            duration: duration
        )

        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if currentToast?.id == currentToast?.id {
                currentToast = nil
            }
        }
    }

    /// Show a success toast
    func showSuccessToast(_ message: String, duration: TimeInterval = 3.0) {
        showToast(message: message, type: .success, duration: duration)
    }

    /// Show an error toast
    func showErrorToast(_ message: String, duration: TimeInterval = 4.0) {
        showToast(message: message, type: .error, duration: duration)
    }

    /// Show a warning toast
    func showWarningToast(_ message: String, duration: TimeInterval = 3.5) {
        showToast(message: message, type: .warning, duration: duration)
    }

    /// Show an info toast
    func showInfoToast(_ message: String, duration: TimeInterval = 3.0) {
        showToast(message: message, type: .info, duration: duration)
    }
}

// MARK: - Toast View

struct ToastView: View {
    let config: ToastConfig

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: config.type.icon)
                .foregroundColor(config.type.color)
                .font(.title3)

            Text(config.message)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: AppColors.textPrimary.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding()
    }
}
