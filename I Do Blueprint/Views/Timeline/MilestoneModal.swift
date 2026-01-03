//
//  MilestoneModal.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI

struct MilestoneModal: View {
    let milestone: Milestone?
    let onSave: (MilestoneInsertData) async -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsStore: SettingsStoreV2
    @State private var milestoneName = ""
    @State private var description = ""
    @State private var milestoneDate = Date()
    @State private var completed = false
    @State private var selectedColor = "blue"
    @State private var isSaving = false

    private let logger = AppLogger.ui

    private let availableColors = [
        ("red", Color.red),
        ("orange", Color.orange),
        ("yellow", Color.yellow),
        ("green", Color.green),
        ("blue", Color.blue),
        ("purple", Color.purple),
        ("pink", Color.pink)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Basic Info Section
                    basicInfoSection

                    // Date Section
                    dateSection

                    // Color Section
                    colorSection

                    // Description Section
                    descriptionSection
                }
                .padding()
            }
            .navigationTitle(milestone == nil ? "New Milestone" : "Edit Milestone")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMilestone()
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
            .onAppear {
                loadMilestoneData()
            }
        }
        .frame(width: 600, height: 550)
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                // Milestone Name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Milestone Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Enter milestone name", text: $milestoneName)
                        .textFieldStyle(.roundedBorder)
                }

                // Completed Toggle
                Toggle("Completed", isOn: $completed)
                    .fontWeight(.medium)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date")
                .font(.headline)
                .fontWeight(.semibold)

            DatePicker("Milestone Date", selection: $milestoneDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    // MARK: - Color Section

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Color")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                ForEach(availableColors, id: \.0) { colorName, color in
                    Button(action: { selectedColor = colorName }) {
                        ZStack {
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)

                            if selectedColor == colorName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(SemanticColors.textPrimary)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor)))
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Description")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("Add description (optional)...", text: $description, axis: .vertical)
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
        !milestoneName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func loadMilestoneData() {
        guard let milestone else { return }

        milestoneName = milestone.milestoneName
        description = milestone.description ?? ""
        milestoneDate = milestone.milestoneDate
        completed = milestone.completed
        selectedColor = milestone.color ?? "blue"
    }

    private func saveMilestone() {
        isSaving = true

        // Get couple ID from settings
        guard let coupleId = settingsStore.coupleId else {
            logger.warning("No couple ID available - user not authenticated")
            isSaving = false
            return
        }

        let milestoneData = MilestoneInsertData(
            coupleId: coupleId,
            milestoneName: milestoneName.trimmingCharacters(in: .whitespaces),
            description: description.isEmpty ? nil : description,
            milestoneDate: milestoneDate,
            completed: completed,
            color: selectedColor)

        Task {
            await onSave(milestoneData)
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    MilestoneModal(
        milestone: nil,
        onSave: { _ in },
        onCancel: {})
}
