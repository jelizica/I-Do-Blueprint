//
//  SettingsView.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case global = "Global"
    case theme = "Theme"
    case budget = "Budget"
    case tasks = "Tasks"
    case vendors = "Vendors"
    case vendorCategories = "Categories"
    case guests = "Guests"
    case documents = "Documents"
    case collaboration = "Collaboration"
    case notifications = "Notifications"
    case links = "Links"
    case apiKeys = "API Keys"
    case account = "Account"
    case featureFlags = "Feature Flags"
    case danger = "Danger Zone"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .global: "globe"
        case .theme: "paintpalette"
        case .budget: "dollarsign.circle"
        case .tasks: "checklist"
        case .vendors: "person.2"
        case .vendorCategories: "star"
        case .guests: "person.3"
        case .documents: "doc"
        case .collaboration: "person.2.badge.gearshape"
        case .notifications: "bell"
        case .links: "link"
        case .apiKeys: "key.fill"
        case .account: "person.circle"
        case .featureFlags: "flag.fill"
        case .danger: "exclamationmark.triangle"
        }
    }

    var color: Color {
        switch self {
        case .danger: .red
        case .featureFlags: .orange
        default: .accentColor
        }
    }
}

struct SettingsView: View {
    @Environment(\.appStores) private var appStores
    @State private var selectedSection: SettingsSection = .global
    @State private var showDeveloperSettings = false
    @State private var tapCount = 0
    
    private var store: SettingsStoreV2 {
        appStores.settings
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    Label {
                        Text(section.rawValue)
                    } icon: {
                        Image(systemName: section.icon)
                            .foregroundColor(section.color)
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
            .navigationTitle(selectedSection.rawValue)
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
            GlobalSettingsView(viewModel: store)
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
