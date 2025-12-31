//
//  SettingsViewV2.swift
//  I Do Blueprint
//
//  NOTE: This file is deprecated. Use SettingsView.swift instead.
//  Refactored settings view with extracted sidebar and detail components
//

import SwiftUI

struct SettingsViewV2: View {
    @Environment(\.appStores) private var appStores
    @State private var selectedSection: SettingsSection = .global
    @State private var selectedSubsection: AnySubsection = .global(.overview)
    @State private var showDeveloperSettings = false
    @State private var expandedSections: Set<SettingsSection> = [.global]
    
    private var store: SettingsStoreV2 {
        appStores.settings
    }
    
    var body: some View {
        NavigationSplitView {
            SettingsSidebarView(
                selectedSection: $selectedSection,
                selectedSubsection: $selectedSubsection,
                expandedSections: $expandedSections,
                onDeveloperTap: {
                    showDeveloperSettings = true
                }
            )
        } detail: {
            SettingsDetailView(
                selectedSection: selectedSection,
                selectedSubsection: selectedSubsection,
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
