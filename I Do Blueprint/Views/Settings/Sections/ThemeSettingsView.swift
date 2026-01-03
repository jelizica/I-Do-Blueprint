//
//  ThemeSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct ThemeSettingsView: View {
    @ObservedObject var viewModel: SettingsStoreV2

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionHeader(
                title: "Theme",
                subtitle: "Appearance and color preferences",
                sectionName: "theme",
                isSaving: viewModel.savingSections.contains("theme"),
                hasUnsavedChanges: viewModel.localSettings.theme != viewModel.settings.theme,
                onSave: {
                    Task {
                        await viewModel.saveThemeSettings()
                    }
                })

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(label: "Color Scheme") {
                    Picker("Color Scheme", selection: $viewModel.localSettings.theme.colorScheme) {
                        Text("Blush Romance (Default)").tag("blush-romance")
                        Text("Sage Serenity").tag("sage-serenity")
                        Text("Lavender Dream").tag("lavender-dream")
                        Text("Terracotta Warm").tag("terracotta-warm")
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 250)
                }

                SettingsRow(label: "Dark Mode") {
                    Toggle("", isOn: $viewModel.localSettings.theme.darkMode)
                        .labelsHidden()
                }
            }
        }
    }
}

#Preview {
    ThemeSettingsView(viewModel: SettingsStoreV2())
        .padding()
}
