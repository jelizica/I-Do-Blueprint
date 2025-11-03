//
//  InlineLoadingStateView.swift
//  I Do Blueprint
//
//  Created for JES-47: Standardize Loading States
//

import SwiftUI

/// Inline loading state view for compact loading indicators
/// Used for refreshing data or loading within existing UI elements
struct InlineLoadingStateView<Content: View, Data>: View {
    let state: LoadingState<Data>
    let content: (Data) -> Content
    let errorIcon: String

    init(
        state: LoadingState<Data>,
        errorIcon: String = "exclamationmark.circle.fill",
        @ViewBuilder content: @escaping (Data) -> Content
    ) {
        self.state = state
        self.errorIcon = errorIcon
        self.content = content
    }

    var body: some View {
        ZStack {
            switch state {
            case .idle, .loading:
                ProgressView()
                    .scaleEffect(0.8)
                    .accessibilityLabel("Loading")

            case .loaded(let data):
                content(data)

            case .error(let error):
                Image(systemName: errorIcon)
                    .foregroundColor(.red)
                    .accessibilityLabel("Error: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview
#Preview("Inline Loading") {
    InlineLoadingStateView(
        state: .loading
    ) { (data: String) in
        Text(data)
    }
    .frame(width: 100, height: 100)
    .border(AppColors.textSecondary)
}

#Preview("Inline Loaded") {
    InlineLoadingStateView(
        state: .loaded("Loaded Data")
    ) { (data: String) in
        Text(data)
    }
    .frame(width: 100, height: 100)
    .border(AppColors.textSecondary)
}

#Preview("Inline Error") {
    InlineLoadingStateView(
        state: .error(NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed"]))
    ) { (data: String) in
        Text(data)
    }
    .frame(width: 100, height: 100)
    .border(AppColors.textSecondary)
}
