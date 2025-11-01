//
//  AppDelegate.swift
//  I Do Blueprint
//
//  Universal Links and Deep Link handling for collaboration invitations
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = AppLogger.auth

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application launched - Universal Links handler registered")
    }

    // MARK: - Universal Links Handler

    func application(_ application: NSApplication, open urls: [URL]) {
        logger.debug("Received URL open request with \(urls.count) URL(s)")

        for url in urls {
            handleIncomingURL(url)
        }
    }

    // MARK: - URL Handling Logic

    private func handleIncomingURL(_ url: URL) {
        logger.info("Processing incoming URL: \(url.absoluteString)")

        // Handle Universal Link format: https://idoblueprint.app/accept-invitation?token=...
        if url.host == "idoblueprint.app" && url.path == "/accept-invitation" {
            handleUniversalLink(url)
            return
        }

        // Handle custom URL scheme: idoblueprint://accept-invitation?token=...
        if url.scheme == "idoblueprint" && url.host == "accept-invitation" {
            handleCustomScheme(url)
            return
        }

        logger.warning("Received unhandled URL: \(url.absoluteString)")
    }

    private func handleUniversalLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
            logger.error("Universal Link missing required 'token' parameter")
            showInvitationError("Invalid invitation link - missing token")
            return
        }

        logger.info("Processing Universal Link invitation with token")
        processInvitation(token: token, source: "universal_link")
    }

    private func handleCustomScheme(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value else {
            logger.error("Custom scheme URL missing required 'token' parameter")
            showInvitationError("Invalid invitation link - missing token")
            return
        }

        logger.info("Processing custom scheme invitation with token")
        processInvitation(token: token, source: "custom_scheme")
    }

    // MARK: - Invitation Processing

    private func processInvitation(token: String, source: String) {
        Task { @MainActor in
            // Get the AppCoordinator from the app environment
            guard let coordinator = getAppCoordinator() else {
                logger.error("Cannot process invitation - AppCoordinator not available")
                showInvitationError("Application not ready to process invitation")
                return
            }

            logger.info("Routing invitation to AppCoordinator (source: \(source))")

            // Route to invitation acceptance flow
            coordinator.handleInvitationDeepLink(token: token)

            // Log to Sentry for tracking (if enabled)
            // TEMPORARILY DISABLED - Sentry SDK not configured
            // await SentryService.shared.captureMessage(
            //     "Invitation deep link opened",
            //     context: [
            //         "source": source,
            //         "has_token": "true"
            //     ]
            // )
        }
    }

    // MARK: - Helper Methods

    private func getAppCoordinator() -> AppCoordinator? {
        // Access the AppCoordinator through the shared environment
        // This will be properly wired up when we integrate with AppCoordinator
        return AppCoordinator.shared
    }

    private func showInvitationError(_ message: String) {
        logger.error("Invitation error: \(message)")

        Task { @MainActor in
            let alert = NSAlert()
            alert.messageText = "Invitation Error"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

// MARK: - App Integration Extension

extension My_Wedding_Planning_AppApp {
    /// Configure the AppDelegate for Universal Links handling
    func configureAppDelegate() -> some Scene {
        WindowGroup {
            // Existing app content
        }
    }
}
