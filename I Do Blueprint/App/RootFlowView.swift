//
//  RootFlowView.swift
//  My Wedding Planning App
//
//  Centralizes auth and tenant branching to reduce duplication
//

import SwiftUI

/// Root flow view that handles authentication and tenant selection state
/// This centralizes the branching logic that was previously duplicated between App and ContentView
struct RootFlowView: View {
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @EnvironmentObject private var appStores: AppStores
    @StateObject private var supabaseManager = SupabaseManager.shared
    
    // Create coordinator with shared stores
    @StateObject private var coordinator: AppCoordinator = AppCoordinator(appStores: .shared)
    @StateObject private var sessionManager = SessionManager.shared

    var body: some View {
        Group {
            if !supabaseManager.isAuthenticated {
                // Not authenticated: Show login screen
                AuthenticationView()
            } else if sessionManager.getTenantId() == nil {
                // Authenticated but no tenant: Show tenant selection
                TenantSelectionView()
            } else {
                // Authenticated with tenant: Show main app
                MainAppView()
                    .environmentObject(appStores)
                    .environmentObject(settingsStore)
                    .environmentObject(coordinator)
            }
        }
        .task {
            // Load settings once authenticated with tenant
            if supabaseManager.isAuthenticated && sessionManager.getTenantId() != nil {
                AppLogger.ui.info("RootFlowView: Loading settings for authenticated user with tenant")
                if !settingsStore.hasLoaded {
                    await settingsStore.loadSettings()
                }
            }
        }
    }
}

/// Main application view (after authentication and tenant selection)
private struct MainAppView: View {
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @EnvironmentObject var appStores: AppStores
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        NavigationSplitView {
            // Sidebar
            AppSidebarView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
        } detail: {
            // Main content - shows the selected tab's view
            coordinator.selectedTab.view
                .environmentObject(appStores)
                .environmentObject(appStores.budget)
                .environmentObject(appStores.guest)
                .environmentObject(appStores.vendor)
                .environmentObject(appStores.document)
                .environmentObject(appStores.task)
                .environmentObject(appStores.timeline)
                .environmentObject(appStores.notes)
                .environmentObject(appStores.visualPlanning)
                .environmentObject(settingsStore)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(item: $coordinator.activeSheet) { sheet in
            sheet.view(coordinator: coordinator)
                .environmentObject(settingsStore)
        }
    }
}

#Preview("Authenticated with Tenant") {
    RootFlowView()
        .environmentObject(SettingsStoreV2())
}

#Preview("Not Authenticated") {
    RootFlowView()
        .environmentObject(SettingsStoreV2())
}
