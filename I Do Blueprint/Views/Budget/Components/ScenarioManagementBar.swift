import SwiftUI

/// Bar for managing budget scenarios (select, save, rename, duplicate, delete)
struct ScenarioManagementBar: View {
    @Binding var selectedScenario: String
    @Binding var saving: Bool
    
    let savedScenarios: [SavedScenario]
    let currentScenarioId: String?
    
    let onSaveScenario: () async -> Void
    let onLoadScenario: (String) async -> Void
    let onSetPrimaryScenario: (String) async -> Void
    let onShowRenameDialog: (String, String) -> Void
    let onShowDuplicateDialog: (String, String) -> Void
    let onShowDeleteDialog: (String, String) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Scenario Selector
            Picker("Scenario", selection: $selectedScenario) {
                Text("New Scenario").tag("new")
                ForEach(savedScenarios) { scenario in
                    HStack {
                        Text(scenario.scenarioName)
                        if scenario.isPrimary {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    .tag(scenario.id)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 250)
            .onChange(of: selectedScenario) { _, newValue in
                Task {
                    await onLoadScenario(newValue)
                }
            }
            
            // Save Button
            Button(action: {
                Task {
                    await onSaveScenario()
                }
            }) {
                HStack {
                    if saving {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Text("Save")
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.blue)
                .foregroundColor(AppColors.textPrimary)
                .cornerRadius(6)
            }
            .disabled(saving)
            .buttonStyle(PlainButtonStyle())
            
            // Scenario Actions Menu
            if selectedScenario != "new", let scenario = savedScenarios.first(where: { $0.id == selectedScenario }) {
                Menu {
                    Button("Set as Primary") {
                        Task {
                            await onSetPrimaryScenario(scenario.id)
                        }
                    }
                    .disabled(scenario.isPrimary)
                    
                    Divider()
                    
                    Button("Rename") {
                        onShowRenameDialog(scenario.id, scenario.scenarioName)
                    }
                    
                    Button("Duplicate") {
                        onShowDuplicateDialog(scenario.id, scenario.scenarioName)
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        onShowDeleteDialog(scenario.id, scenario.scenarioName)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .padding(Spacing.sm)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
