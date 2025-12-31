//
//  SettingsView.swift
//  My Wedding Planning App
//
//  Restructured settings with nested hierarchy
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.appStores) private var appStores
    @State private var selectedSection: SettingsSection = .global
    @State private var selectedSubsection: AnySubsection = .global(.overview)
    @State private var showDeveloperSettings = false
    @State private var expandedSections: Set<SettingsSection> = [.global, .account]

    private var store: SettingsStoreV2 {
        appStores.settings
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedSection) {
                ForEach(SettingsSection.allCases) { section in
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
                        subsectionButtons(for: section)
                    } label: {
                        Label {
                            Text(section.rawValue)
                        } icon: {
                            Image(systemName: section.icon)
                                .foregroundColor(section.color)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 250)
            .onAppear {
                restoreExpandedState()
            }
            .onChange(of: expandedSections) { _, _ in
                saveExpandedState()
            }
        } detail: {
            // Detail View
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Error/Success Messages
                    if let error = store.error {
                        ErrorBannerView(
                            message: error.localizedDescription,
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
            .navigationTitle(navigationTitle)
        }
        .task {
            await store.loadSettings()
        }
        .sheet(isPresented: $showDeveloperSettings) {
            DeveloperSettingsView()
        }
    }

    // MARK: - Subsection Buttons

    @ViewBuilder
    private func subsectionButtons(for section: SettingsSection) -> some View {
        switch section {
        case .global:
            ForEach(GlobalSubsection.allCases) { subsection in
                subsectionButton(.global(subsection), for: section)
            }
        case .account:
            ForEach(AccountSubsection.allCases) { subsection in
                subsectionButton(.account(subsection), for: section)
            }
        case .budgetVendors:
            ForEach(BudgetVendorsSubsection.allCases) { subsection in
                subsectionButton(.budgetVendors(subsection), for: section)
            }
        case .guestsTasks:
            ForEach(GuestsTasksSubsection.allCases) { subsection in
                subsectionButton(.guestsTasks(subsection), for: section)
            }
        case .appearance:
            ForEach(AppearanceSubsection.allCases) { subsection in
                subsectionButton(.appearance(subsection), for: section)
            }
        case .dataContent:
            ForEach(DataContentSubsection.allCases) { subsection in
                subsectionButton(.dataContent(subsection), for: section)
            }
        case .developer:
            ForEach(DeveloperSubsection.allCases) { subsection in
                subsectionButton(.developer(subsection), for: section)
            }
        }
    }

    private func subsectionButton(_ subsection: AnySubsection, for section: SettingsSection) -> some View {
        Button(action: {
            selectedSection = section
            selectedSubsection = subsection
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
            (selectedSection == section && selectedSubsection == subsection)
                ? Color.accentColor.opacity(0.1)
                : Color.clear
        )
        .cornerRadius(6)
    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        "\(selectedSection.rawValue) - \(selectedSubsection.rawValue)"
    }

    // MARK: - Section Content

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSubsection {
        // Global
        case .global(.overview):
            GlobalSettingsView(viewModel: store)
        case .global(.weddingEvents):
            WeddingEventsView()
            
        // Account
        case .account(.profile):
            AccountSettingsView()
        case .account(.collaboration):
            CollaborationSettingsView()
        case .account(.dataPrivacy):
            DangerZoneView(viewModel: store)
            
        // Budget & Vendors
        case .budgetVendors(.budgetConfiguration):
            BudgetConfigSettingsView(viewModel: store)
        case .budgetVendors(.budgetCategories):
            BudgetCategoriesSettingsView()
        case .budgetVendors(.vendorManagement):
            VendorsSettingsView(viewModel: store)
        case .budgetVendors(.vendorCategories):
            VendorCategoriesSettingsView(viewModel: store)
            
        // Guests & Tasks
        case .guestsTasks(.guestPreferences):
            GuestsSettingsView(viewModel: store)
        case .guestsTasks(.taskPreferences):
            TasksSettingsView(viewModel: store)
        case .guestsTasks(.teamMembers):
            TeamMembersSettingsView(viewModel: store)
            
        // Appearance
        case .appearance(.theme):
            ThemeSettingsView(viewModel: store)
        case .appearance(.notifications):
            NotificationsSettingsView(viewModel: store)
            
        // Data & Content
        case .dataContent(.documents):
            DocumentsSettingsView(viewModel: store)
        case .dataContent(.importantLinks):
            LinksSettingsView(viewModel: store)
            
        // Developer
        case .developer(.apiKeys):
            APIKeysSettingsView()
        case .developer(.featureFlags):
            FeatureFlagsSettingsView()
        }
    }

    // MARK: - State Persistence

    private func saveExpandedState() {
        let expanded = expandedSections.map { $0.rawValue }
        UserDefaults.standard.set(expanded, forKey: "SettingsExpandedSections")
    }

    private func restoreExpandedState() {
        if let saved = UserDefaults.standard.array(forKey: "SettingsExpandedSections") as? [String] {
            expandedSections = Set(saved.compactMap { SettingsSection(rawValue: $0) })
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 900, height: 600)
}
