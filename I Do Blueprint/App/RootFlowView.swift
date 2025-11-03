//
//  RootFlowView.swift
//  My Wedding Planning App
//
//  Centralizes auth and tenant branching to reduce duplication
//

import SwiftUI
// swiftlint:disable file_types_order

/// Root flow view that handles authentication and tenant selection state
/// This centralizes the branching logic that was previously duplicated between App and ContentView
struct RootFlowView: View {
    @EnvironmentObject var settingsStore: SettingsStoreV2
    @EnvironmentObject private var appStores: AppStores
    @StateObject private var supabaseManager = SupabaseManager.shared

    // Use shared coordinator instance
    @StateObject private var coordinator = AppCoordinator.shared
    @StateObject private var sessionManager = SessionManager.shared

    // Directly observe onboarding store for completion changes
    @ObservedObject private var onboardingStore = AppStores.shared.onboarding

    @State private var needsOnboarding: Bool?
    @State private var isCheckingOnboarding = false
    @State private var currentTenantId: UUID?

    // JES-196: staged post-onboarding loader
    @StateObject private var postOnboardingLoader = PostOnboardingLoader()
    @State private var showPostOnboardingOverlay = false
    @StateObject private var errorHandler = ErrorHandler.shared

    var body: some View {
        Group {
            if !supabaseManager.isAuthenticated {
                // Not authenticated: Show login screen
                AuthenticationView()
            } else if sessionManager.getTenantId() == nil {
                // Authenticated but no tenant: Show tenant selection
                TenantSelectionView()
            } else if isCheckingOnboarding {
                // Checking onboarding status
                LoadingView(message: "Loading...")
            } else if needsOnboarding == true {
                // Authenticated with tenant but needs onboarding
                OnboardingContainerView()
                    .environmentObject(appStores)
                    .onChange(of: onboardingStore.isCompleted) { _, isCompleted in
                        if isCompleted {
                            AppLogger.ui.info("RootFlowView: Onboarding completed, transitioning to main app")
                            needsOnboarding = false

                            // JES-196: Show staged loader overlay and start background sequence
                            showPostOnboardingOverlay = true
                            Task { @MainActor in
                                AppLogger.ui.info("RootFlowView: Starting PostOnboardingLoader sequence")
                                await postOnboardingLoader.start(appStores: appStores, settingsStore: settingsStore) {
                                    AppLogger.ui.info("RootFlowView: PostOnboardingLoader finished")
                                    showPostOnboardingOverlay = false
                                }
                            }
                        }
                    }
            } else {
                // Authenticated with tenant and onboarding complete: Show main app
                ZStack {
                    MainAppView()
                        .environmentObject(appStores)
                        .environmentObject(settingsStore)
                        .environmentObject(coordinator)

                    if showPostOnboardingOverlay {
                        PostOnboardingOverlayView(loader: postOnboardingLoader) {
                            // Skip for now — hide overlay but keep loads running
                            showPostOnboardingOverlay = false
                            postOnboardingLoader.cancel()
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
        .task(id: sessionManager.getTenantId()) {
            // Check onboarding status once authenticated with tenant
            // Re-runs when tenant changes (new wedding created)
            if supabaseManager.isAuthenticated, let tenantId = sessionManager.getTenantId() {
                // Detect tenant change
                if currentTenantId != tenantId {
                    AppLogger.ui.info("RootFlowView: Tenant changed to \(tenantId.uuidString)")
                    currentTenantId = tenantId
                    needsOnboarding = nil // Reset to trigger re-check

                    // Reset onboarding store for new tenant
                    appStores.onboarding.resetForNewTenant()
                }

                await checkOnboardingStatus()

                // Load settings after onboarding check
                if needsOnboarding == false {
                    AppLogger.ui.info("RootFlowView: Loading settings for authenticated user with tenant")
                    // Force reload settings for new tenant
                    await settingsStore.loadSettings(force: true)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tenantDidChange)) { notification in
            // Handle tenant change notification
            if let userInfo = notification.userInfo,
               let previousId = userInfo["previousId"] as? String,
               let newId = userInfo["newId"] as? String {
                AppLogger.ui.info("RootFlowView: Received tenant change notification from \(previousId) to \(newId)")

                // Reset onboarding check
                needsOnboarding = nil

                // Force reload settings for new tenant
                Task {
                    await settingsStore.loadSettings(force: true)
                    AppLogger.ui.info("RootFlowView: Settings reloaded for new tenant")
                }
            }
        }
        .sheet(
            isPresented: Binding(
                get: { errorHandler.isShowingError },
                set: { newValue in if !newValue { errorHandler.dismiss() } }
            )
        ) {
            if let appError = errorHandler.currentError {
                UnifiedErrorView(
                    error: appError,
                    onDismiss: { errorHandler.dismiss() },
                    onRecovery: { _ in errorHandler.dismiss() }
                )
            } else {
                // Fallback if state de-synced
                Text("An error occurred.")
                    .padding()
            }
        }
    }

    /// Checks if user needs to complete onboarding
    private func checkOnboardingStatus() async {
        guard !isCheckingOnboarding else { return }

        isCheckingOnboarding = true
        defer { isCheckingOnboarding = false }

        AppLogger.ui.info("RootFlowView: Checking onboarding status")

        let completed = await appStores.onboarding.checkIfCompleted()
        needsOnboarding = !completed

        if completed {
            AppLogger.ui.info("RootFlowView: Onboarding already completed")
        } else {
            AppLogger.ui.info("RootFlowView: Onboarding required")
            // Load existing progress if any
            await appStores.onboarding.loadProgress()
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
