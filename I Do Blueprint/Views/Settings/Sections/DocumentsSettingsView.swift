//
//  DocumentsSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct DocumentsSettingsView: View {
    @ObservedObject var viewModel: SettingsStoreV2

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionHeader(
                title: "Documents",
                subtitle: "Document management and vendor behavior preferences",
                sectionName: "documents",
                isSaving: viewModel.savingSections.contains("documents"),
                hasUnsavedChanges: viewModel.localSettings.documents != viewModel.settings.documents,
                onSave: {
                    Task {
                        await viewModel.saveDocumentsSettings()
                    }
                })

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(label: "Auto-organize") {
                    Toggle("", isOn: $viewModel.localSettings.documents.autoOrganize)
                        .labelsHidden()
                }

                SettingsRow(label: "Cloud Backup") {
                    Toggle("", isOn: $viewModel.localSettings.documents.cloudBackup)
                        .labelsHidden()
                }

                SettingsRow(label: "Retention Period") {
                    HStack {
                        TextField("Days", value: $viewModel.localSettings.documents.retentionDays, format: .number)
                            .frame(width: 100)
                            .textFieldStyle(.roundedBorder)
                        Text("days")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Vendor Behavior
            GroupBox(label: HStack {
                Image(systemName: "gearshape.2")
                Text("Vendor Behavior")
                    .font(.headline)
            }) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Configure how vendor information is handled across documents and expenses.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        VendorBehaviorToggle(
                            label: "Enforce Consistency",
                            description: "Ensure vendor information remains consistent across all documents and expenses",
                            isOn: $viewModel.localSettings.documents.vendorBehavior.enforceConsistency)

                        Divider()

                        VendorBehaviorToggle(
                            label: "Allow Inheritance",
                            description: "Automatically inherit vendor details from parent documents",
                            isOn: $viewModel.localSettings.documents.vendorBehavior.allowInheritance)

                        Divider()

                        VendorBehaviorToggle(
                            label: "Prefer Expense Vendor",
                            description: "When conflicts occur, use vendor information from expense records",
                            isOn: $viewModel.localSettings.documents.vendorBehavior.preferExpenseVendor)

                        Divider()

                        VendorBehaviorToggle(
                            label: "Enable Validation Logging",
                            description: "Log vendor validation events for troubleshooting",
                            isOn: $viewModel.localSettings.documents.vendorBehavior.enableValidationLogging)
                    }
                }
                .padding()
            }

            Spacer()
        }
    }
}

// MARK: - Vendor Behavior Toggle

struct VendorBehaviorToggle: View {
    let label: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.body)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

#Preview {
    DocumentsSettingsView(viewModel: SettingsStoreV2())
        .padding()
        .frame(width: 700, height: 700)
}
