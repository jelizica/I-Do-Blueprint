//
//  DuplicateScenarioDialogView.swift
//  I Do Blueprint
//
//  Extracted from BudgetDevelopmentView.swift
//

import SwiftUI

struct DuplicateScenarioDialogView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var duplicateData: ScenarioDialogData
    let onSave: () async -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("New Scenario Name", text: $duplicateData.name)
                    .textFieldStyle(.roundedBorder)

                Spacer()
            }
            .padding()
            .navigationTitle("Duplicate Scenario")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Duplicate") {
                        Task {
                            await onSave()
                        }
                        dismiss()
                    }
                    .disabled(duplicateData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
