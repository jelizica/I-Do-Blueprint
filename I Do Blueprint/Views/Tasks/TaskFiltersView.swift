//
//  TaskFiltersView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct TaskFiltersView: View {
    @ObservedObject var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Status Filter
                Section("Status") {
                    Picker("Status", selection: $viewModel.selectedStatus) {
                        Text("All Statuses").tag(TaskStatus?.none)
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(TaskStatus?.some(status))
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Priority Filter
                Section("Priority") {
                    Picker("Priority", selection: $viewModel.selectedPriority) {
                        Text("All Priorities").tag(WeddingTaskPriority?.none)
                        ForEach(WeddingTaskPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(WeddingTaskPriority?.some(priority))
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Sort Order
                Section("Sort By") {
                    Picker("Sort Order", selection: $viewModel.sortOption) {
                        ForEach(TaskSortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Search
                Section("Search") {
                    TextField("Search tasks...", text: $viewModel.searchText)
                }

                // Actions
                Section {
                    Button("Clear All Filters") {
                        viewModel.clearFilters()
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onChange(of: viewModel.selectedStatus) { _, _ in viewModel.applyFilters() }
            .onChange(of: viewModel.selectedPriority) { _, _ in viewModel.applyFilters() }
            .onChange(of: viewModel.sortOption) { _, _ in viewModel.applyFilters() }
            .onChange(of: viewModel.searchText) { _, _ in viewModel.applyFilters() }
        }
        .frame(width: 400, height: 500)
    }
}

// MARK: - Preview

#Preview {
    TaskFiltersView(viewModel: TasksViewModel())
}
