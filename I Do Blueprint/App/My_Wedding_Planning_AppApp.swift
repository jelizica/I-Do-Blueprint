import SwiftUI

@main
struct My_Wedding_Planning_AppApp: App {
    @StateObject private var settingsStore = SettingsStoreV2()
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var credentialsCheckFailed = false

    var body: some Scene {
        WindowGroup {
            Group {
                if credentialsCheckFailed {
                    // Show actionable credentials missing error
                    CredentialsErrorView(onRetry: {
                        Task {
                            credentialsCheckFailed = false
                            await performPreflightChecks()
                        }
                    })
                } else {
                    // Use centralized RootFlowView for auth/tenant branching
                    RootFlowView()
                        .environmentObject(settingsStore)
                }
            }
            .preferredColorScheme(settingsStore.settings.theme.darkMode ? .dark : .light)
            .task {
                // Preflight check for Google OAuth credentials
                await performPreflightChecks()

                // Refresh remote feature flags in the background
                FeatureFlags.refreshRemoteFlags()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }

    // MARK: - Preflight Checks

    @MainActor
    private func performPreflightChecks() async {
        let googleAuthManager = GoogleAuthManager()
        if googleAuthManager.authError != nil {
            credentialsCheckFailed = true
            AppLogger.auth.error("Preflight check failed: Google OAuth credentials not configured")
        }
    }
}

// MARK: - App Configuration

extension My_Wedding_Planning_AppApp {
    private var minimumWindowSize: CGSize {
        CGSize(width: 800, height: 600)
    }
}
