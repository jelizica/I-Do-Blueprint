import SwiftUI

@main
struct My_Wedding_Planning_AppApp: App {
    @StateObject private var authContext = AuthContext.shared
    @StateObject private var appStores = AppStores.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var credentialsCheckFailed = false
    
    // MARK: - Initialization
    
    init() {
        // Initialize Sentry as early as possible
        SentryService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                // Check for configuration errors first (highest priority)
                if let configError = supabaseManager.configurationError {
                    ConfigurationErrorView(
                        error: configError,
                        onRetry: {
                            // Restart app (requires user to relaunch)
                            NSApplication.shared.terminate(nil)
                        },
                        onContactSupport: {
                            // Open support email
                            if let url = URL(string: "mailto:support@idoblueprint.com?subject=Configuration%20Error&body=Error:%20\(configError.errorDescription ?? "Unknown")") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    )
                } else if credentialsCheckFailed {
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
                        .environmentObject(authContext)
                        .environmentObject(appStores)
                        .environmentObject(appStores.settings)
                        .onAppear {
                            authContext.refresh()
                        }
                }
            }
            .preferredColorScheme(appStores.settings.settings.theme.darkMode ? .dark : .light)
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
