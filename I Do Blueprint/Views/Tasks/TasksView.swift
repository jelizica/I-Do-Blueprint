//
//  TasksView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct TasksView: View {
    @StateObject private var viewModel = TasksViewModel()
    @State private var showingTaskModal = false
    @State private var selectedTask: WeddingTask?
    @State private var showingFilters = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading, viewModel.tasks.isEmpty {
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

                        Button(action: { Task { await viewModel.refresh() } }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(viewModel.isLoading)

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
                            await viewModel.updateTask(task.id, data: taskData)
                        } else {
                            await viewModel.createTask(taskData)
                        }
                        selectedTask = nil
                    },
                    onCancel: {
                        selectedTask = nil
                    })
            }
            .sheet(isPresented: $showingFilters) {
                TaskFiltersView(viewModel: viewModel)
            }
            .task {
                await viewModel.load()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: Spacing.md) {
                        ForEach(0..<4, id: \.self) { _ in
                            TaskCardSkeleton()
                        }
                    }
                    .frame(width: 320)
                }
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Kanban Board View

    private var kanbanBoardView: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    KanbanColumn(
                        status: status,
                        tasks: viewModel.tasks(for: status),
                        onTaskTap: { task in
                            selectedTask = task
                            showingTaskModal = true
                        },
                        onTaskMove: { task, newStatus in
                            await viewModel.moveTask(task, to: newStatus)
                        })
                        .frame(width: 320)
                }
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusConfig.color.opacity(0.1)))

            // Progress Bar
            if !tasks.isEmpty {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)

                        Rectangle()
                            .fill(statusConfig.color)
                            .frame(width: geometry.size.width, height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 12)
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
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDraggingOver ? statusConfig.color : Color.gray.opacity(0.2), lineWidth: 2))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: statusConfig.icon)
                .font(.system(size: 40))
                .foregroundColor(statusConfig.color.opacity(0.3))

            Text("No tasks")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview {
    TasksView()
        .frame(width: 1200, height: 800)
}
