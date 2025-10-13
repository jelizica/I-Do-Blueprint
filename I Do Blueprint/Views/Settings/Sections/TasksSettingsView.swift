//
//  TasksSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct TasksSettingsView: View {
    @ObservedObject var viewModel: SettingsStoreV2
    @State private var showAddParty = false
    @State private var newPartyName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionHeader(
                title: "Tasks",
                subtitle: "Task management preferences and assignees",
                sectionName: "tasks",
                isSaving: viewModel.savingSections.contains("tasks"),
                hasUnsavedChanges: viewModel.localSettings.tasks != viewModel.settings.tasks,
                onSave: {
                    Task {
                        await viewModel.saveTasksSettings()
                    }
                })

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(label: "Default View") {
                    Picker("View", selection: $viewModel.localSettings.tasks.defaultView) {
                        Text("Kanban").tag("kanban")
                        Text("List").tag("list")
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 250)
                }

                SettingsRow(label: "Show Completed") {
                    Toggle("", isOn: $viewModel.localSettings.tasks.showCompleted)
                        .labelsHidden()
                }

                SettingsRow(label: "Notifications") {
                    Toggle("", isOn: $viewModel.localSettings.tasks.notificationsEnabled)
                        .labelsHidden()
                }
            }

            Divider()

            // Custom Responsible Parties
            GroupBox(label: Text("Custom Responsible Parties").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add vendors or team members who can be assigned to tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let parties = viewModel.localSettings.tasks.customResponsibleParties, !parties.isEmpty {
                        ForEach(parties, id: \.self) { party in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                Text(party)
                                Spacer()
                                Button(action: { removeParty(party) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    } else {
                        Text("No custom responsible parties added")
                            .foregroundColor(.secondary)
                            .padding()
                    }

                    Button(action: { showAddParty = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Responsible Party")
                        }
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showAddParty) {
            AddResponsiblePartySheet(
                name: $newPartyName,
                onSave: {
                    addParty()
                    showAddParty = false
                },
                onCancel: {
                    showAddParty = false
                    newPartyName = ""
                })
        }
    }

    private func addParty() {
        guard !newPartyName.isEmpty else { return }

        if viewModel.localSettings.tasks.customResponsibleParties == nil {
            viewModel.localSettings.tasks.customResponsibleParties = []
        }

        if !viewModel.localSettings.tasks.customResponsibleParties!.contains(newPartyName) {
            viewModel.localSettings.tasks.customResponsibleParties?.append(newPartyName)
        }

        newPartyName = ""
    }

    private func removeParty(_ party: String) {
        viewModel.localSettings.tasks.customResponsibleParties?.removeAll { $0 == party }
    }
}

// MARK: - Add Responsible Party Sheet

struct AddResponsiblePartySheet: View {
    @Binding var name: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Responsible Party")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("e.g., Wedding Planner, Mom, Best Man", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            Text("This person can be assigned to tasks and will appear in task assignment dropdowns.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Add", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}

#Preview {
    TasksSettingsView(viewModel: SettingsStoreV2())
        .padding()
        .frame(width: 700, height: 600)
}
