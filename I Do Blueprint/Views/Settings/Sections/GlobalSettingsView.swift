//
//  GlobalSettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct GlobalSettingsView: View {
    @ObservedObject var viewModel: SettingsStoreV2
    @StateObject private var sessionManager = SessionManager.shared
    @State private var showCoupleSwitch = false
    @State private var currentCoupleInfo: String = "Loading..."

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsSectionHeader(
                title: "Global Settings",
                subtitle: "Core wedding information and preferences",
                sectionName: "global",
                isSaving: viewModel.savingSections.contains("global"),
                hasUnsavedChanges: viewModel.localSettings.global != viewModel.settings.global,
                onSave: {
                    Task {
                        await viewModel.saveGlobalSettings()
                    }
                })

            Divider()

            // Current Couple Section
            GroupBox(label: Text("Current Wedding").font(.headline)) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Selected Wedding:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(currentCoupleInfo)
                            .font(.subheadline)
                    }

                    Divider()

                    Button(action: {
                        showCoupleSwitch = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Switch Wedding")
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .sheet(isPresented: $showCoupleSwitch) {
                TenantSelectionView()
                    .onDisappear {
                        // Update couple info when sheet is dismissed
                        if let tenantId = sessionManager.getTenantId() {
                            currentCoupleInfo = String(tenantId.uuidString.prefix(8)) + "..."
                        } else {
                            currentCoupleInfo = "None selected"
                        }
                    }
            }
            .onAppear {
                if let tenantId = sessionManager.getTenantId() {
                    currentCoupleInfo = String(tenantId.uuidString.prefix(8)) + "..."
                } else {
                    currentCoupleInfo = "None selected"
                }
            }

            // Partner Names Section
            GroupBox(label: Text("Partner Information").font(.headline)) {
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Partner 1").font(.subheadline).bold()
                            TextField("Full Name", text: $viewModel.localSettings.global.partner1FullName)
                            TextField("Nickname (Optional)", text: $viewModel.localSettings.global.partner1Nickname)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Partner 2").font(.subheadline).bold()
                            TextField("Full Name", text: $viewModel.localSettings.global.partner2FullName)
                            TextField("Nickname (Optional)", text: $viewModel.localSettings.global.partner2Nickname)
                        }
                    }
                }
                .padding()
            }

            // Basic Settings
            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(label: "Currency") {
                    TextField("Currency", text: $viewModel.localSettings.global.currency)
                        .frame(maxWidth: 120)
                }

                SettingsRow(label: "Wedding Date") {
                    HStack(spacing: 12) {
                        if viewModel.localSettings.global.isWeddingDateTBD {
                            Text("TBD (To Be Determined)")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            DatePicker(
                                "Wedding Date",
                                selection: Binding(
                                    get: {
                                        // Parse weddingDate string (YYYY-MM-DD) to Date
                                        let dateString = viewModel.localSettings.global.weddingDate
                                        if dateString.isEmpty {
                                            return Date()
                                        }
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "yyyy-MM-dd"
                                        return formatter.date(from: dateString) ?? Date()
                                    },
                                    set: { newDate in
                                        // Format Date to string (YYYY-MM-DD)
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "yyyy-MM-dd"
                                        viewModel.localSettings.global.weddingDate = formatter.string(from: newDate)
                                    }
                                ),
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .frame(maxWidth: 200)
                        }

                        Toggle("TBD", isOn: $viewModel.localSettings.global.isWeddingDateTBD)
                            .toggleStyle(.checkbox)
                            .help("Check if wedding date is to be determined")
                    }
                }

                SettingsRow(label: "Timezone") {
                    TextField("Timezone", text: $viewModel.localSettings.global.timezone)
                        .frame(maxWidth: 250)
                }
            }

            // Wedding Events
            GroupBox(label: Text("Wedding Events").font(.headline)) {
                if viewModel.localSettings.global.weddingEvents.isEmpty {
                    Text("No events configured")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.localSettings.global.weddingEvents) { event in
                        WeddingEventRow(event: event)
                    }
                }
            }
        }
    }
}

struct WeddingEventRow: View {
    let event: SettingsWeddingEvent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.eventName)
                    .font(.headline)
                if event.isMainEvent {
                    Text("Main Event")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(event.eventDate)
                    .font(.subheadline)
                Text(event.eventTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, Spacing.sm)
    }
}

#Preview {
    GlobalSettingsView(viewModel: SettingsStoreV2())
        .padding()
}
