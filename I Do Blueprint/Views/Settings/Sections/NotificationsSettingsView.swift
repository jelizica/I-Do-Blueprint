//
//  NotificationsSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct NotificationsSettingsView: View {
    @ObservedObject var viewModel: SettingsStoreV2

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionHeader(
                title: "Notifications",
                subtitle: "Manage notification preferences",
                sectionName: "notifications",
                isSaving: viewModel.savingSections.contains("notifications"),
                hasUnsavedChanges: viewModel.localSettings.notifications != viewModel.settings.notifications,
                onSave: {
                    Task {
                        await viewModel.saveNotificationsSettings()
                    }
                })

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(label: "Email Notifications") {
                    Toggle("", isOn: $viewModel.localSettings.notifications.emailEnabled)
                        .labelsHidden()
                }

                SettingsRow(label: "Push Notifications") {
                    Toggle("", isOn: $viewModel.localSettings.notifications.pushEnabled)
                        .labelsHidden()
                }

                SettingsRow(label: "Digest Frequency") {
                    Picker("Digest Frequency", selection: $viewModel.localSettings.notifications.digestFrequency) {
                        Text("Daily").tag("daily")
                        Text("Weekly").tag("weekly")
                        Text("Monthly").tag("monthly")
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)
                }
            }
        }
    }
}

#Preview {
    NotificationsSettingsView(viewModel: SettingsStoreV2())
        .padding()
}
