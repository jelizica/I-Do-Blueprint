import SwiftUI

@main
struct My_Wedding_Planning_AppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authContext = AuthContext.shared
    @StateObject private var appStores = AppStores.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var credentialsCheckFailed = false
    @State private var externalConfigError: ConfigurationError?

    // MARK: - Initialization

    init() {
        // Initialize Sentry as early as possible
        // TEMPORARILY DISABLED
        // SentryService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                // Check for configuration errors first (highest priority)
                if let configError = supabaseManager.configurationError ?? externalConfigError {
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
        // 1) Google OAuth preflight
        let googleAuthManager = GoogleAuthManager()
        if googleAuthManager.authError != nil {
            credentialsCheckFailed = true
            AppLogger.auth.error("Preflight check failed: Google OAuth credentials not configured")
        } else {
            credentialsCheckFailed = false
        }

        // 2) Config validation (Supabase + Sentry)
        let summary = ConfigValidator.validateAll()

        // For Supabase: SupabaseManager will surface blocking errors itself. No-op here unless we want to proactively show.
        // For Sentry: show ConfigurationErrorView if missing/invalid
        if let blocking = ConfigValidator.blockingErrorForUI(summary: summary) {
            // Only intercept Sentry-related errors here to avoid racing with Supabase initialization
            switch blocking {
            case .missingSentryDSN, .invalidSentryDSN:
                externalConfigError = blocking
            default:
                // Defer to SupabaseManager for other errors
                externalConfigError = nil
            }
        } else {
            externalConfigError = nil
        }

        // 3) Initialize Sentry if DSN looks valid
        if summary.sentryDSNPresent && summary.sentryDSNValid {
            SentryService.shared.configure()
            SentryService.shared.addBreadcrumb(
                message: "Config preflight passed",
                category: "app",
                data: [
                    "supabase_url_present": summary.supabaseURLPresent ? "true" : "false",
                    "anon_key_present": summary.supabaseAnonKeyPresent ? "true" : "false",
                    "sentry_dsn_present": "true"
                ]
            )
        }
    }
}

// MARK: - App Configuration

extension My_Wedding_Planning_AppApp {
    private var minimumWindowSize: CGSize {
        CGSize(width: 800, height: 600)
    }
}
