//
//  TeamMembersSettingsView.swift
//  I Do Blueprint
//
//  Combined view for managing team members and meal options
//

import SwiftUI

struct TeamMembersSettingsView: View {
    @ObservedObject var viewModel: SettingsStoreV2
    
    // Meal Options State
    @State private var showAddMealOption = false
    @State private var editingMealOption: String?
    @State private var newMealOption = ""
    @State private var editedMealOption = ""
    @State private var mealOptionError: String?
    
    // Responsible Parties State
    @State private var showAddParty = false
    @State private var editingParty: String?
    @State private var newPartyName = ""
    @State private var editedPartyName = ""
    @State private var partyError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionHeader(
                title: "Team Members",
                subtitle: "Manage responsible parties and meal options for your wedding",
                sectionName: "team_members",
                isSaving: viewModel.savingSections.contains("guests") || viewModel.savingSections.contains("tasks"),
                hasUnsavedChanges: hasUnsavedChanges,
                onSave: {
                    Task {
                        await saveAllSettings()
                    }
                })

            Divider()

            // Responsible Parties Section
            GroupBox(label: HStack {
                Image(systemName: "person.2.badge.gearshape")
                Text("Task Responsible Parties")
                    .font(.headline)
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add vendors or team members who can be assigned to tasks. They will appear in task assignment dropdowns.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let parties = viewModel.localSettings.tasks.customResponsibleParties, !parties.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(parties, id: \.self) { party in
                                ResponsiblePartyRow(
                                    party: party,
                                    onEdit: {
                                        editingParty = party
                                        editedPartyName = party
                                    },
                                    onDelete: { removeParty(party) })
                            }
                        }
                    } else {
                        Text("No custom responsible parties added")
                            .foregroundColor(.secondary)
                            .padding()
                    }

                    if let error = partyError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
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

            Divider()

            // Meal Options Section
            GroupBox(label: HStack {
                Image(systemName: "fork.knife")
                Text("Guest Meal Options")
                    .font(.headline)
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add custom meal selections for your guests. Options will be automatically formatted to Title Case.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !viewModel.localSettings.guests.customMealOptions.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(viewModel.localSettings.guests.customMealOptions, id: \.self) { option in
                                MealOptionRow(
                                    option: option,
                                    onEdit: {
                                        editingMealOption = option
                                        editedMealOption = option
                                    },
                                    onDelete: { removeMealOption(option) })
                            }
                        }
                    } else {
                        Text("No custom meal options added")
                            .foregroundColor(.secondary)
                            .padding()
                    }

                    if let error = mealOptionError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }

                    Button(action: { showAddMealOption = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Meal Option")
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
                    partyError = nil
                })
        }
        .sheet(isPresented: Binding(
            get: { editingParty != nil },
            set: { if !$0 { editingParty = nil } })) {
            if editingParty != nil {
                EditResponsiblePartySheet(
                    name: $editedPartyName,
                    onSave: {
                        updateParty()
                    },
                    onCancel: {
                        editingParty = nil
                        editedPartyName = ""
                        partyError = nil
                    })
            }
        }
        .sheet(isPresented: $showAddMealOption) {
            AddMealOptionSheet(
                option: $newMealOption,
                onSave: {
                    addMealOption()
                    showAddMealOption = false
                },
                onCancel: {
                    showAddMealOption = false
                    newMealOption = ""
                    mealOptionError = nil
                })
        }
        .sheet(isPresented: Binding(
            get: { editingMealOption != nil },
            set: { if !$0 { editingMealOption = nil } })) {
            if editingMealOption != nil {
                EditMealOptionSheet(
                    option: $editedMealOption,
                    onSave: {
                        updateMealOption()
                    },
                    onCancel: {
                        editingMealOption = nil
                        editedMealOption = ""
                        mealOptionError = nil
                    })
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasUnsavedChanges: Bool {
        viewModel.localSettings.guests != viewModel.settings.guests ||
        viewModel.localSettings.tasks != viewModel.settings.tasks
    }
    
    // MARK: - Save Methods
    
    private func saveAllSettings() async {
        await viewModel.saveGuestsSettings()
        await viewModel.saveTasksSettings()
    }
    
    // MARK: - Responsible Party Methods
    
    private func addParty() {
        partyError = nil
        let trimmed = newPartyName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            partyError = "Name cannot be empty"
            return
        }
        
        if viewModel.localSettings.tasks.customResponsibleParties == nil {
            viewModel.localSettings.tasks.customResponsibleParties = []
        }
        
        // Check for duplicates (case-insensitive)
        if viewModel.localSettings.tasks.customResponsibleParties!
            .contains(where: { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
            partyError = "This responsible party already exists"
            return
        }
        
        viewModel.localSettings.tasks.customResponsibleParties?.append(trimmed)
        newPartyName = ""
    }
    
    private func updateParty() {
        guard let oldParty = editingParty else { return }
        
        partyError = nil
        let trimmed = editedPartyName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            partyError = "Name cannot be empty"
            return
        }
        
        // Check for duplicates (case-insensitive), excluding the current party
        if viewModel.localSettings.tasks.customResponsibleParties?.contains(where: {
            $0 != oldParty && $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }) == true {
            partyError = "This responsible party already exists"
            return
        }
        
        // Update the party
        if let index = viewModel.localSettings.tasks.customResponsibleParties?.firstIndex(of: oldParty) {
            viewModel.localSettings.tasks.customResponsibleParties?[index] = trimmed
        }
        
        // Clear editing state
        editingParty = nil
        editedPartyName = ""
    }
    
    private func removeParty(_ party: String) {
        viewModel.localSettings.tasks.customResponsibleParties?.removeAll { $0 == party }
    }
    
    // MARK: - Meal Option Methods
    
    private func addMealOption() {
        mealOptionError = nil
        let trimmed = newMealOption.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            mealOptionError = "Meal option cannot be empty"
            return
        }

        // Convert to title case
        let titleCased = titleCase(trimmed)

        // Check for duplicates (case-insensitive)
        if viewModel.localSettings.guests.customMealOptions
            .contains(where: { $0.localizedCaseInsensitiveCompare(titleCased) == .orderedSame }) {
            mealOptionError = "This meal option already exists"
            return
        }

        // Add to list
        viewModel.localSettings.guests.customMealOptions.append(titleCased)

        // Clear input
        newMealOption = ""
    }

    private func updateMealOption() {
        guard let oldOption = editingMealOption else { return }

        mealOptionError = nil
        let trimmed = editedMealOption.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            mealOptionError = "Meal option cannot be empty"
            return
        }

        // Convert to title case
        let titleCased = titleCase(trimmed)

        // Check for duplicates (case-insensitive), excluding the current option
        if viewModel.localSettings.guests.customMealOptions.contains(where: {
            $0 != oldOption && $0.localizedCaseInsensitiveCompare(titleCased) == .orderedSame
        }) {
            mealOptionError = "This meal option already exists"
            return
        }

        // Update the option
        if let index = viewModel.localSettings.guests.customMealOptions.firstIndex(of: oldOption) {
            viewModel.localSettings.guests.customMealOptions[index] = titleCased
        }

        // Clear editing state
        editingMealOption = nil
        editedMealOption = ""
    }

    private func removeMealOption(_ option: String) {
        viewModel.localSettings.guests.customMealOptions.removeAll { $0 == option }
    }

    private func titleCase(_ string: String) -> String {
        string.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}

// MARK: - Responsible Party Row

struct ResponsiblePartyRow: View {
    let party: String
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.blue)
            Text(party)
            Spacer()

            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Edit Responsible Party Sheet

struct EditResponsiblePartySheet: View {
    @Binding var name: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Responsible Party")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            Text("This person can be assigned to tasks and will appear in task assignment dropdowns.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Save", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 450, height: 300)
        .presentationDetents([.height(300)])
    }
}

#Preview {
    TeamMembersSettingsView(viewModel: SettingsStoreV2())
        .padding()
        .frame(width: 700, height: 800)
}
