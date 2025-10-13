// Extracted from BudgetDevelopmentView.swift

import AppKit
import SwiftUI

struct BudgetConfigurationHeader: View {
    @Binding var selectedScenario: String
    @Binding var budgetName: String
    @Binding var selectedTaxRateId: Int64?
    @Binding var saving: Bool
    @Binding var uploading: Bool

    let savedScenarios: [SavedScenario]
    let currentScenarioId: String?
    let taxRates: [TaxInfo]
    let isGoogleAuthenticated: Bool

    let onExportJSON: () -> Void
    let onExportCSV: () -> Void
    let onExportToGoogleDrive: () async -> Void
    let onExportToGoogleSheets: () async -> Void
    let onSignInToGoogle: () async -> Void
    let onSignOutFromGoogle: () -> Void
    let onSaveScenario: () async -> Void
    let onUploadScenario: () async -> Void
    let onLoadScenario: (String) async -> Void
    let onSetPrimaryScenario: (String) async -> Void
    let onShowRenameDialog: (String, String) -> Void
    let onShowDuplicateDialog: (String, String) -> Void
    let onShowDeleteDialog: (String, String) -> Void
    let onShowTaxRateDialog: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Budget Development")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                HStack(spacing: 8) {
                    Menu {
                        Section(header: Text("Local Export")) {
                            Button(action: onExportJSON) {
                                Label("Export as JSON", systemImage: "doc.text")
                            }
                            Button(action: onExportCSV) {
                                Label("Export as CSV (Excel)", systemImage: "tablecells")
                            }
                        }

                        Section(header: Text("Google Export")) {
                            if isGoogleAuthenticated {
                                Button(action: { Task { await onExportToGoogleDrive() } }) {
                                    Label("Upload to Google Drive", systemImage: "icloud.and.arrow.up")
                                }
                                Button(action: { Task { await onExportToGoogleSheets() } }) {
                                    Label("Create Google Sheet", systemImage: "doc.on.doc")
                                }
                                Button(action: onSignOutFromGoogle) {
                                    Label("Sign Out from Google", systemImage: "person.crop.circle.badge.xmark")
                                }
                            } else {
                                Button(action: { Task { await onSignInToGoogle() } }) {
                                    Label("Sign in to Google", systemImage: "person.crop.circle.badge.checkmark")
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down")
                            Text("Export")
                        }
                    }
                    .buttonStyle(.bordered)

                    Button(action: { Task { await onSaveScenario() } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down.fill")
                            Text(saving ? "Saving..." : "Save")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(saving)

                    Button(action: { Task { await onUploadScenario() } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text(uploading ? "Uploading..." : "Upload")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(uploading || currentScenarioId == nil)
                }
            }

            HStack(spacing: 16) {
                // Scenario selector
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget Scenario")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Picker("Scenario", selection: $selectedScenario) {
                            Text("Create New Scenario").tag("new")
                            ForEach(savedScenarios, id: \.id) { scenario in
                                HStack {
                                    if scenario.isPrimary {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                    }
                                    Text(scenario.scenarioName)
                                }
                                .tag(scenario.id)
                            }
                        }
                        .onChange(of: selectedScenario) {
                            Task { await onLoadScenario(selectedScenario) }
                        }

                        if selectedScenario != "new" {
                            Menu {
                                Button("Set as Primary") {
                                    Task { await onSetPrimaryScenario(selectedScenario) }
                                }
                                .disabled(savedScenarios.first { $0.id == selectedScenario }?.isPrimary == true)

                                Button("Rename") {
                                    if let scenario = savedScenarios.first(where: { $0.id == selectedScenario }) {
                                        onShowRenameDialog(scenario.id, scenario.scenarioName)
                                    }
                                }

                                Button("Duplicate") {
                                    if let scenario = savedScenarios.first(where: { $0.id == selectedScenario }) {
                                        onShowDuplicateDialog(scenario.id, "\(scenario.scenarioName) (Copy)")
                                    }
                                }

                                Divider()

                                Button("Delete", role: .destructive) {
                                    if let scenario = savedScenarios.first(where: { $0.id == selectedScenario }) {
                                        onShowDeleteDialog(scenario.id, scenario.scenarioName)
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }

                // Scenario name (for new scenarios)
                if selectedScenario == "new" {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scenario Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Enter scenario name", text: $budgetName)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                // Tax rate selector
                VStack(alignment: .leading, spacing: 4) {
                    Text("Default Tax Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Picker("Tax Rate", selection: $selectedTaxRateId) {
                            ForEach(taxRates, id: \.id) { rate in
                                Text("\(rate.region) (\(String(format: "%.2f", rate.taxRate * 100))%)")
                                    .tag(rate.id as Int64?)
                            }
                        }

                        Button("Add Rate") {
                            onShowTaxRateDialog()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}
