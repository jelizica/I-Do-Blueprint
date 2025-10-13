//
//  VendorsSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct VendorsSettingsView: View {
    @ObservedObject var viewModel: SettingsStoreV2
    @State private var isFormattingPhones = false
    @State private var formatResult: PhoneFormatResult?
    @State private var formatError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionHeader(
                title: "Vendors",
                subtitle: "Vendor management preferences and tools",
                sectionName: "vendors",
                isSaving: viewModel.savingSections.contains("vendors"),
                hasUnsavedChanges: viewModel.localSettings.vendors != viewModel.settings.vendors,
                onSave: {
                    Task {
                        await viewModel.saveVendorsSettings()
                    }
                })

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(label: "Default View") {
                    Picker("View", selection: $viewModel.localSettings.vendors.defaultView) {
                        Text("Grid").tag("grid")
                        Text("List").tag("list")
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 250)
                }

                SettingsRow(label: "Show Payment Status") {
                    Toggle("", isOn: $viewModel.localSettings.vendors.showPaymentStatus)
                        .labelsHidden()
                }

                SettingsRow(label: "Auto Reminders") {
                    Toggle("", isOn: $viewModel.localSettings.vendors.autoReminders)
                        .labelsHidden()
                }
            }

            Divider()

            // Phone Number Formatter
            GroupBox(label: HStack {
                Image(systemName: "phone.circle.fill")
                Text("Format Phone Numbers")
                    .font(.headline)
            }) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Update all existing vendor and contact phone numbers to a consistent format.")
                        .font(.body)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Formats:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("• US numbers: (555) 123-4567")
                            .font(.caption)
                        Text("• International: +44 20 1234 5678")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    if let error = formatError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.body)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }

                    if let result = formatResult {
                        FormatResultsView(result: result)
                    }

                    Button(action: handleFormatPhoneNumbers) {
                        HStack {
                            if isFormattingPhones {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Formatting...")
                            } else {
                                Image(systemName: "phone.fill")
                                Text("Format All Phone Numbers")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isFormattingPhones)
                }
                .padding()
            }
        }
    }

    private func handleFormatPhoneNumbers() {
        isFormattingPhones = true
        formatError = nil
        formatResult = nil

        Task {
            do {
                let result = try await viewModel.formatPhoneNumbers()
                formatResult = result
            } catch {
                formatError = "Failed to format phone numbers: \(error.localizedDescription)"
            }
            isFormattingPhones = false
        }
    }
}

// MARK: - Format Results View

struct FormatResultsView: View {
    let result: PhoneFormatResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(result.message)
                    .font(.body)
                    .fontWeight(.medium)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)

            if let vendors = result.vendors {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vendor Phone Numbers")
                        .font(.headline)

                    HStack(spacing: 16) {
                        StatLabel(title: "Total", value: "\(vendors.total)", color: .blue)
                        StatLabel(title: "Updated", value: "\(vendors.updated)", color: .green)
                        StatLabel(title: "Unchanged", value: "\(vendors.unchanged)", color: .gray)
                        if !vendors.errors.isEmpty {
                            StatLabel(title: "Errors", value: "\(vendors.errors.count)", color: .red)
                        }
                    }

                    if !vendors.errors.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Errors:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            ForEach(vendors.errors) { error in
                                Text("\(error.vendorName ?? "Unknown"): \(error.error)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }

            if let contacts = result.contacts {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contact Phone Numbers")
                        .font(.headline)

                    HStack(spacing: 16) {
                        StatLabel(title: "Total", value: "\(contacts.total)", color: .blue)
                        StatLabel(title: "Updated", value: "\(contacts.updated)", color: .green)
                        StatLabel(title: "Unchanged", value: "\(contacts.unchanged)", color: .gray)
                        if !contacts.errors.isEmpty {
                            StatLabel(title: "Errors", value: "\(contacts.errors.count)", color: .red)
                        }
                    }

                    if !contacts.errors.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Errors:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            ForEach(contacts.errors) { error in
                                Text("\(error.contactName ?? "Unknown"): \(error.error)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }
        }
    }
}

struct StatLabel: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VendorsSettingsView(viewModel: SettingsStoreV2())
        .padding()
        .frame(width: 700, height: 700)
}
