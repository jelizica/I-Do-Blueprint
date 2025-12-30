//
//  SettingsViewV2.swift
//  I Do Blueprint
//
//  Refactored settings view with extracted sidebar and detail components
//  Reduced nesting from level 10 to max level 4
//

import SwiftUI

struct SettingsViewV2: View {
    @Environment(\.appStores) private var appStores
    @State private var selectedSection: SettingsSection = .global
    @State private var selectedGlobalSubsection: GlobalSubsection = .overview
    @State private var showDeveloperSettings = false
    @State private var expandedSections: Set<SettingsSection> = [.global]
    
    private var store: SettingsStoreV2 {
        appStores.settings
    }
    
    var body: some View {
        NavigationSplitView {
            SettingsSidebarView(
                selectedSection: $selectedSection,
                selectedGlobalSubsection: $selectedGlobalSubsection,
                expandedSections: $expandedSections,
                onDeveloperTap: {
                    showDeveloperSettings = true
                }
            )
        } detail: {
            SettingsDetailView(
                selectedSection: selectedSection,
                selectedGlobalSubsection: selectedGlobalSubsection,
                store: store
            )
        }
        .task {
            await store.loadSettings()
        }
        .sheet(isPresented: $showDeveloperSettings) {
            DeveloperSettingsView()
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsViewV2()
        .frame(width: 900, height: 600)
}
