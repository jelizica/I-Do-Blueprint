//
//  LoadingStateView.swift
//  I Do Blueprint
//
//  Generic loading state handler for async data
//

import SwiftUI

/// Enum representing different loading states
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)

    var isIdle: Bool {
        if case .idle = self {
            return true
        }
        return false
    }

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    var hasError: Bool {
        if case .error = self {
            return true
        }
        return false
    }

    var data: T? {
        if case .loaded(let data) = self {
            return data
        }
        return nil
    }

    var error: Error? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
}

/// View that handles different loading states with appropriate UI
struct LoadingStateView<Content: View, Data>: View {
    private let logger = AppLogger.ui
    let state: LoadingState<Data>
    let content: (Data) -> Content
    let onRetry: (() -> Void)?
    let emptyState: (() -> AnyView)?

    init(
        state: LoadingState<Data>,
        @ViewBuilder content: @escaping (Data) -> Content,
        onRetry: (() -> Void)? = nil,
        emptyState: (() -> AnyView)? = nil
    ) {
        self.state = state
        self.content = content
        self.onRetry = onRetry
        self.emptyState = emptyState
    }

    var body: some View {
        switch state {
        case .idle:
            if let emptyState = emptyState {
                emptyState()
            } else {
                EmptyView()
            }

        case .loading:
            LoadingView(message: "Loading...")

        case .loaded(let data):
            content(data)

        case .error(let error):
            ErrorStateView(
                error: error,
                onRetry: onRetry
            )
        }
    }
}

/// Simple loading view with spinner and message
struct LoadingView: View {
    let message: String

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(.circular)

            Text(message)
                .font(Typography.bodyRegular)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// Inline loading indicator for smaller spaces
struct InlineLoadingView: View {
    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .scaleEffect(0.8)

            if let message = message {
                Text(message)
                    .font(Typography.bodySmall)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "Loading")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Previews

#Preview("Loading View") {
    LoadingView(message: "Loading guests...")
}

#Preview("Inline Loading View") {
    InlineLoadingView(message: "Saving...")
        .padding()
}

#Preview("Loading State - Loading") {
    LoadingStateView(
        state: .loading as LoadingState<[String]>,
        content: { data in
            List(data, id: \.self) { item in
                Text(item)
            }
        }
    )
}

#Preview("Loading State - Loaded") {
    LoadingStateView(
        state: .loaded(["Item 1", "Item 2", "Item 3"]),
        content: { data in
            List(data, id: \.self) { item in
                Text(item)
            }
        }
    )
}

#Preview("Loading State - Error") {
    LoadingStateView(
        state: .error(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load data"])) as LoadingState<[String]>,
        content: { data in
            List(data, id: \.self) { item in
                Text(item)
            }
        },
        onRetry: {
            // TODO: Implement action - print("Retry tapped")
        }
    )
}
