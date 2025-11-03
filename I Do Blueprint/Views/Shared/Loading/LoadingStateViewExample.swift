//
//  LoadingStateViewExample.swift
//  I Do Blueprint
//
//  Example demonstrating LoadingStateView usage
//  Created for JES-47: Standardize Loading States
//

import SwiftUI
import Combine

/// Example view demonstrating how to use LoadingStateView
/// This serves as a reference for implementing loading states in new features
struct LoadingStateViewExample: View {
    @StateObject private var viewModel = ExampleViewModel()

    var body: some View {
        NavigationStack {
            LoadingStateView(
                state: viewModel.loadingState,
                content: { items in
                    List(items) { item in
                        HStack {
                            Text(item.name)
                                .font(.headline)
                            Spacer()
                            Text(item.value)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                },
                onRetry: {
                    Task {
                        await viewModel.retryLoad()
                    }
                }
            )
            .navigationTitle("Example View")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") {
                        Task {
                            await viewModel.loadData()
                        }
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
}

// MARK: - Example ViewModel

@MainActor
class ExampleViewModel: ObservableObject {
    @Published var loadingState: LoadingState<[ExampleItem]> = .idle

    func loadData() async {
        guard loadingState.isIdle || loadingState.hasError else { return }

        loadingState = .loading

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Simulate data loading
        let items = [
            ExampleItem(id: UUID(), name: "Item 1", value: "Value 1"),
            ExampleItem(id: UUID(), name: "Item 2", value: "Value 2"),
            ExampleItem(id: UUID(), name: "Item 3", value: "Value 3")
        ]

        loadingState = .loaded(items)
    }

    func retryLoad() async {
        await loadData()
    }
}

// MARK: - Example Model

struct ExampleItem: Identifiable {
    let id: UUID
    let name: String
    let value: String
}

// MARK: - Preview

#Preview("Loading State") {
    LoadingStateViewExample()
}
