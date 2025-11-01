//
//  TaskModal.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct TaskModal: View {
    let task: WeddingTask?
    let onSave: (TaskInsertData) async -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var taskName = ""
    @State private var description = ""
    @State private var priority: WeddingTaskPriority = .medium
    @State private var status: TaskStatus = .notStarted
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var startDate = Date()
    @State private var hasStartDate = false
    @State private var assignedTo: [String] = []
    @State private var newAssignee = ""
    @State private var notes = ""
    @State private var estimatedHours: Double = 0
    @State private var costEstimate: Double = 0
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Basic Info Section
                    basicInfoSection

                    // Dates Section
                    datesSection

                    // Assignment Section
                    assignmentSection

                    // Details Section
                    detailsSection

                    // Estimates Section
                    estimatesSection

                    // Notes Section
                    notesSection
                }
                .padding()
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
            .onAppear {
                loadTaskData()
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                // Task Name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Task Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Enter task name", text: $taskName)
                        .textFieldStyle(.roundedBorder)
                }

                // Description
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Enter description (optional)", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3 ... 6)
                }

                // Priority
                VStack(alignment: .leading, spacing: 6) {
                    Text("Priority")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Picker("Priority", selection: $priority) {
                        ForEach(WeddingTaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priorityColor(priority))
                                    .frame(width: 8, height: 8)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Status
                VStack(alignment: .leading, spacing: 6) {
                    Text("Status")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Picker("Status", selection: $status) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    // MARK: - Dates Section

    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dates")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                // Due Date
                Toggle("Due Date", isOn: $hasDueDate)
                    .fontWeight(.medium)

                if hasDueDate {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }

                Divider()

                // Start Date
                Toggle("Start Date", isOn: $hasStartDate)
                    .fontWeight(.medium)

                if hasStartDate {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    // MARK: - Assignment Section

    private var assignmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Assignment")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                HStack {
                    TextField("Add person", text: $newAssignee)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        addAssignee()
                    }
                    .disabled(newAssignee.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if !assignedTo.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(assignedTo, id: \.self) { person in
                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)

                                Text(person)
                                    .font(.subheadline)

                                Spacer()

                                Button(action: { removeAssignee(person) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Additional Details")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                Text("Vendor and milestone linking coming soon...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    // MARK: - Estimates Section

    private var estimatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Estimates")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                HStack {
                    Text("Estimated Hours")
                        .frame(width: 140, alignment: .leading)
                    TextField("0", value: $estimatedHours, format: .number)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("Cost Estimate")
                        .frame(width: 140, alignment: .leading)
                    TextField("$0", value: $costEstimate, format: .currency(code: "USD"))
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Add notes...", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(5 ... 10)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        !taskName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func priorityColor(_ priority: WeddingTaskPriority) -> Color {
        switch priority {
        case .urgent: .red
        case .high: .orange
        case .medium: .blue
        case .low: .gray
        }
    }

    private func addAssignee() {
        let trimmed = newAssignee.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty, !assignedTo.contains(trimmed) {
            assignedTo.append(trimmed)
            newAssignee = ""
        }
    }

    private func removeAssignee(_ person: String) {
        assignedTo.removeAll { $0 == person }
    }

    private func loadTaskData() {
        guard let task else { return }

        taskName = task.taskName
        description = task.description ?? ""
        priority = task.priority
        status = task.status
        assignedTo = task.assignedTo
        notes = task.notes ?? ""
        estimatedHours = task.estimatedHours ?? 0
        costEstimate = task.costEstimate ?? 0

        if let dueDate = task.dueDate {
            self.dueDate = dueDate
            hasDueDate = true
        }

        if let startDate = task.startDate {
            self.startDate = startDate
            hasStartDate = true
        }
    }

    private func saveTask() {
        isSaving = true

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let taskData = TaskInsertData(
            taskName: taskName.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description,
            budgetCategoryId: nil,
            priority: priority,
            dueDate: hasDueDate ? dateFormatter.string(from: dueDate) : nil,
            startDate: hasStartDate ? dateFormatter.string(from: startDate) : nil,
            assignedTo: assignedTo,
            vendorId: nil,
            status: status,
            dependsOnTaskId: nil,
            estimatedHours: estimatedHours > 0 ? estimatedHours : nil,
            costEstimate: costEstimate > 0 ? costEstimate : nil,
            notes: notes.isEmpty ? nil : notes,
            milestoneId: nil)

        Task {
            await onSave(taskData)
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    TaskModal(
        task: nil,
        onSave: { _ in },
        onCancel: {})
        .frame(width: 700, height: 800)
}
