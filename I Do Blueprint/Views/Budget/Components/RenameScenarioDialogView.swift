//
//  RenameScenarioDialogView.swift
//  I Do Blueprint
//
//  Extracted from BudgetDevelopmentView.swift
//

import SwiftUI

struct RenameScenarioDialogView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var renameData: ScenarioDialogData
    let onSave: () async -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Scenario Name", text: $renameData.name)
                    .textFieldStyle(.roundedBorder)

                Spacer()
            }
            .padding()
            .navigationTitle("Rename Scenario")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Rename") {
                        Task {
                            await onSave()
                        }
                        dismiss()
                    }
                    .disabled(renameData.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
