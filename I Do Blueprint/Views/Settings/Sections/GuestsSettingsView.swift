//
//  GuestsSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct GuestsSettingsView: View {
    @ObservedObject var viewModel: SettingsStoreV2
    @State private var showAddMealOption = false
    @State private var editingMealOption: String?
    @State private var newMealOption = ""
    @State private var editedMealOption = ""
    @State private var mealOptionError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionHeader(
                title: "Guests",
                subtitle: "Guest management preferences and meal options",
                sectionName: "guests",
                isSaving: viewModel.savingSections.contains("guests"),
                hasUnsavedChanges: viewModel.localSettings.guests != viewModel.settings.guests,
                onSave: {
                    Task {
                        await viewModel.saveGuestsSettings()
                    }
                })

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(label: "Default View") {
                    Picker("View", selection: $viewModel.localSettings.guests.defaultView) {
                        Text("List").tag("list")
                        Text("Table").tag("table")
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 250)
                }

                SettingsRow(label: "Show Meal Preferences") {
                    Toggle("", isOn: $viewModel.localSettings.guests.showMealPreferences)
                        .labelsHidden()
                }

                SettingsRow(label: "RSVP Reminders") {
                    Toggle("", isOn: $viewModel.localSettings.guests.rsvpReminders)
                        .labelsHidden()
                }
            }

            Divider()

            // Custom Meal Options
            GroupBox(label: HStack {
                Image(systemName: "fork.knife")
                Text("Custom Meal Options")
                    .font(.headline)
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(
                        "Add custom meal selections for your guests. Options will be automatically formatted to Title Case.")
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

// MARK: - Meal Option Row

struct MealOptionRow: View {
    let option: String
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "fork.knife.circle.fill")
                .foregroundColor(.blue)
            Text(option)
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

// MARK: - Add Meal Option Sheet

struct AddMealOptionSheet: View {
    @Binding var option: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Meal Option")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 6) {
                Text("Meal Option")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("e.g., Vegetarian, Gluten-Free, Vegan", text: $option)
                    .textFieldStyle(.roundedBorder)
            }

            Text("The option will be automatically formatted to Title Case and checked for duplicates.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Add", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(option.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 450, height: 300)
        .presentationDetents([.height(300)])
    }
}

// MARK: - Edit Meal Option Sheet

struct EditMealOptionSheet: View {
    @Binding var option: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Meal Option")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 6) {
                Text("Meal Option")
                    .font(.subheadline)
                    .fontWeight(.medium)
                TextField("Meal Option", text: $option)
                    .textFieldStyle(.roundedBorder)
            }

            Text("The option will be automatically formatted to Title Case and checked for duplicates.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Save", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .disabled(option.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .frame(width: 450, height: 300)
        .presentationDetents([.height(300)])
    }
}

#Preview {
    GuestsSettingsView(viewModel: SettingsStoreV2())
        .padding()
        .frame(width: 700, height: 700)
}
