//
//  TaskFiltersView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct TaskFiltersView: View {
    @ObservedObject var store: TaskStoreV2
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Status Filter
                Section("Status") {
                    Picker("Status", selection: $store.filterStatus) {
                        Text("All Statuses").tag(TaskStatus?.none)
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(TaskStatus?.some(status))
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Priority Filter
                Section("Priority") {
                    Picker("Priority", selection: $store.filterPriority) {
                        Text("All Priorities").tag(WeddingTaskPriority?.none)
                        ForEach(WeddingTaskPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(WeddingTaskPriority?.some(priority))
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Sort Order
                Section("Sort By") {
                    Picker("Sort Order", selection: $store.sortOption) {
                        ForEach(TaskSortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Search
                Section("Search") {
                    TextField("Search tasks...", text: $store.searchQuery)
                }

                // Actions
                Section {
                    Button("Clear All Filters") {
                        store.clearFilters()
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
        }
        .frame(width: 400, height: 500)
    }
}

// MARK: - Preview

#Preview {
    TaskFiltersView(store: TaskStoreV2())
}
