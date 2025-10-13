//
//  ErrorPresenter.swift
//  My Wedding Planning App
//
//  Shared adapter for presenting domain-specific errors with recovery hints
//

import SwiftUI

/// Unified error presentation adapter for domain-specific errors
struct ErrorPresenter {
    /// Presents an error in an alert with localized description and recovery suggestion
    static func alert(for error: LocalizedError?, isPresented: Binding<Bool>) -> Alert {
        guard let error = error else {
            return Alert(title: Text("Error"))
        }

        let title = Text("Error")
        let message: Text

        if let description = error.errorDescription,
           let recovery = error.recoverySuggestion {
            message = Text("\(description)\n\n\(recovery)")
        } else if let description = error.errorDescription {
            message = Text(description)
        } else {
            message = Text("An unexpected error occurred")
        }

        return Alert(
            title: title,
            message: message,
            dismissButton: .default(Text("OK")) {
                isPresented.wrappedValue = false
            }
        )
    }

    /// Presents an error as a banner view with description and optional recovery action
    static func banner(for error: LocalizedError?, onDismiss: @escaping () -> Void, onRetry: (() -> Void)? = nil) -> some View {
        Group {
            if let error = error {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)

                        Text(error.errorDescription ?? "An error occurred")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    if let recovery = error.recoverySuggestion {
                        Text(recovery)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let onRetry = onRetry {
                        Button(action: onRetry) {
                            Label("Retry", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }

    /// Returns a user-friendly error message string
    static func message(for error: LocalizedError?) -> String? {
        guard let error = error else { return nil }

        var message = error.errorDescription ?? "An error occurred"

        if let recovery = error.recoverySuggestion {
            message += "\n\n\(recovery)"
        }

        return message
    }

    /// Returns just the error description without recovery suggestion
    static func description(for error: LocalizedError?) -> String? {
        error?.errorDescription
    }

    /// Returns just the recovery suggestion
    static func recoverySuggestion(for error: LocalizedError?) -> String? {
        error?.recoverySuggestion
    }
}

// MARK: - View Extension for Convenient Error Presentation

extension View {
    /// Presents an error alert using domain-specific error types
    func errorAlert<E: LocalizedError>(error: Binding<E?>) -> some View {
        alert(isPresented: Binding(
            get: { error.wrappedValue != nil },
            set: { if !$0 { error.wrappedValue = nil } }
        )) {
            ErrorPresenter.alert(for: error.wrappedValue, isPresented: Binding(
                get: { error.wrappedValue != nil },
                set: { if !$0 { error.wrappedValue = nil } }
            ))
        }
    }

    /// Presents an error banner at the top of the view
    func errorBanner<E: LocalizedError>(error: Binding<E?>, onRetry: (() -> Void)? = nil) -> some View {
        VStack(spacing: 0) {
            if error.wrappedValue != nil {
                ErrorPresenter.banner(
                    for: error.wrappedValue,
                    onDismiss: { error.wrappedValue = nil },
                    onRetry: onRetry
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            self
        }
        .animation(.spring(), value: error.wrappedValue != nil)
    }
}
