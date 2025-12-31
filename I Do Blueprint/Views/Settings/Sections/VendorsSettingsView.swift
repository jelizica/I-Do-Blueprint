//
//  VendorsSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct VendorsSettingsView: View {
    @ObservedObject var viewModel: SettingsStoreV2

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

            // Phone numbers are now automatically formatted when saving guests and vendors
            // No manual formatting needed - see PhoneNumberService and repository implementations
        }
    }
}

#Preview {
    VendorsSettingsView(viewModel: SettingsStoreV2())
        .padding()
        .frame(width: 700, height: 700)
}
