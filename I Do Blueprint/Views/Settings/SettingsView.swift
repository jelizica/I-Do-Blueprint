//
//  SettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//  NOTE: This is the legacy version. Use SettingsViewV2 for new development.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.appStores) private var appStores
    @State private var selectedSection: SettingsSection = .global
    @State private var selectedGlobalSubsection: GlobalSubsection = .overview
    @State private var showDeveloperSettings = false
    @State private var tapCount = 0
    @State private var expandedSections: Set<SettingsSection> = [.global]

    private var store: SettingsStoreV2 {
        appStores.settings
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedSection) {
                ForEach(SettingsSection.allCases) { section in
                    if section.hasSubsections {
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedSections.contains(section) },
                                set: { isExpanded in
                                    if isExpanded {
                                        expandedSections.insert(section)
                                    } else {
                                        expandedSections.remove(section)
                                    }
                                }
                            )
                        ) {
                            ForEach(GlobalSubsection.allCases) { subsection in
                                Button(action: {
                                    selectedSection = section
                                    selectedGlobalSubsection = subsection
                                }) {
                                    Label {
                                        Text(subsection.rawValue)
                                    } icon: {
                                        Image(systemName: subsection.icon)
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 20)
                                .background(
                                    selectedSection == section && selectedGlobalSubsection == subsection
                                        ? Color.accentColor.opacity(0.1)
                                        : Color.clear
                                )
                                .cornerRadius(6)
                            }
                        } label: {
                            Label {
                                Text(section.rawValue)
                            } icon: {
                                Image(systemName: section.icon)
                                    .foregroundColor(section.color)
                            }
                        }
                    } else {
                        NavigationLink(value: section) {
                            Label {
                                Text(section.rawValue)
                            } icon: {
                                Image(systemName: section.icon)
                                    .foregroundColor(section.color)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
            .onTapGesture(count: 5) {
                // Triple-click on sidebar to open developer settings
                showDeveloperSettings = true
                tapCount = 0
            }
        } detail: {
            // Detail View
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Error/Success Messages - Using Component Library
                    if let error = store.error {
                        ErrorBannerView(
                            message: error.localizedDescription ?? "An error occurred",
                            onDismiss: {
                                store.clearError()
                            }
                        )
                    }

                    if let success = store.successMessage {
                        InfoCard(
                            icon: "checkmark.circle.fill",
                            title: "Success",
                            content: success,
                            color: .green,
                            action: {
                                store.clearSuccessMessage()
                            }
                        )
                    }

                    // Section Content
                    sectionContent
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(
                selectedSection == .global 
                    ? "Global - \(selectedGlobalSubsection.rawValue)"
                    : selectedSection.rawValue
            )
        }
        .task {
            await store.loadSettings()
        }
        .sheet(isPresented: $showDeveloperSettings) {
            DeveloperSettingsView()
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .global:
            switch selectedGlobalSubsection {
            case .overview:
                GlobalSettingsView(viewModel: store)
            case .weddingEvents:
                WeddingEventsView()
            }
        case .theme:
            ThemeSettingsView(viewModel: store)
        case .budget:
            BudgetConfigSettingsView(viewModel: store)
        case .tasks:
            TasksSettingsView(viewModel: store)
        case .vendors:
            VendorsSettingsView(viewModel: store)
        case .vendorCategories:
            VendorCategoriesSettingsView(viewModel: store)
        case .guests:
            GuestsSettingsView(viewModel: store)
        case .documents:
            DocumentsSettingsView(viewModel: store)
        case .collaboration:
            CollaborationSettingsView()
        case .notifications:
            NotificationsSettingsView(viewModel: store)
        case .links:
            LinksSettingsView(viewModel: store)
        case .apiKeys:
            APIKeysSettingsView()
        case .account:
            AccountSettingsView()
        case .featureFlags:
            FeatureFlagsSettingsView()
        case .danger:
            DangerZoneView(viewModel: store)
        }
    }
}

// Note: AlertMessage component replaced with ErrorBannerView and InfoCard from component library

#Preview {
    SettingsView()
        .frame(width: 900, height: 600)
}
