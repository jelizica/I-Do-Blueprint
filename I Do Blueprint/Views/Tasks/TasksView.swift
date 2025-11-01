//
//  TasksView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct TasksView: View {
    @EnvironmentObject private var store: TaskStoreV2
    @State private var showingTaskModal = false
    @State private var selectedTask: WeddingTask?
    @State private var showingFilters = false

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading, store.tasks.isEmpty {
                    loadingView
                } else {
                    kanbanBoardView
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: 12) {
                        Button(action: { showingFilters.toggle() }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }

                        Button(action: { Task { await store.refreshTasks() } }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(store.isLoading)

                        Button(action: { showingTaskModal = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingTaskModal) {
                TaskModal(
                    task: selectedTask,
                    onSave: { taskData in
                        if let task = selectedTask {
                            var updatedTask = task
                            updatedTask.taskName = taskData.taskName
                            updatedTask.description = taskData.description
                            updatedTask.priority = taskData.priority
                            updatedTask.status = taskData.status
                            updatedTask.dueDate = Self.parseDate(taskData.dueDate)
                            updatedTask.startDate = Self.parseDate(taskData.startDate)
                            updatedTask.assignedTo = taskData.assignedTo
                            updatedTask.notes = taskData.notes
                            updatedTask.estimatedHours = taskData.estimatedHours
                            updatedTask.costEstimate = taskData.costEstimate
                            await store.updateTask(updatedTask)
                        } else {
                            await store.createTask(taskData)
                        }
                        selectedTask = nil
                    },
                    onCancel: {
                        selectedTask = nil
                    })
            }
            .sheet(isPresented: $showingFilters) {
                TaskFiltersView(store: store)
            }
            .task {
                await store.loadTasks()
            }
            .onReceive(NotificationCenter.default.publisher(for: .tenantDidChange)) { _ in
                Task {
                    await store.loadTasks()
                }
            }
        }
    }

    // MARK: - Loading View - Using Component Library

    private var loadingView: some View {
        LoadingView(message: "Loading tasks...")
            .frame(maxHeight: .infinity)
    }

    // MARK: - Kanban Board View

    private var kanbanBoardView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    KanbanColumn(
                        status: status,
                        tasks: store.tasks(for: status),
                        onTaskTap: { task in
                            selectedTask = task
                            showingTaskModal = true
                        },
                        onTaskMove: { task, newStatus in
                            await store.moveTask(task, to: newStatus)
                        })
                        .frame(width: 320)
                }
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Date Parsing

    private static func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}

// MARK: - Kanban Column

struct KanbanColumn: View {
    let status: TaskStatus
    let tasks: [WeddingTask]
    let onTaskTap: (WeddingTask) -> Void
    let onTaskMove: (WeddingTask, TaskStatus) async -> Void

    @State private var isDraggingOver = false

    private var statusConfig: (color: Color, icon: String) {
        switch status {
        case .notStarted:
            (.gray, "circle")
        case .inProgress:
            (.blue, "arrow.right.circle.fill")
        case .onHold:
            (.orange, "pause.circle.fill")
        case .completed:
            (.green, "checkmark.circle.fill")
        case .cancelled:
            (.red, "xmark.circle.fill")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column Header
            HStack(spacing: 8) {
                Image(systemName: statusConfig.icon)
                    .foregroundColor(statusConfig.color)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(status.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("\(tasks.count) tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusConfig.color.opacity(0.1)))

            // Progress Bar
            if !tasks.isEmpty {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(AppColors.textSecondary.opacity(0.2))
                            .frame(height: 4)

                        Rectangle()
                            .fill(statusConfig.color)
                            .frame(width: geometry.size.width, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, Spacing.md)
            }

            // Task Cards
            ScrollView {
                VStack(spacing: 12) {
                    if tasks.isEmpty {
                        emptyState
                    } else {
                        ForEach(tasks) { task in
                            TaskCard(task: task, onTap: { onTaskTap(task) })
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.md)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDraggingOver ? statusConfig.color : AppColors.textSecondary.opacity(0.2), lineWidth: 2))
    }

    private var emptyState: some View {
        // Using Component Library - UnifiedEmptyStateView
        UnifiedEmptyStateView(
            config: .custom(
                icon: statusConfig.icon,
                title: "No \(status.displayName) Tasks",
                message: "Tasks in this status will appear here",
                actionTitle: nil,
                onAction: nil
            )
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxl)
    }
}

// MARK: - Preview

#Preview {
    TasksView()
        .frame(width: 1200, height: 800)
}
