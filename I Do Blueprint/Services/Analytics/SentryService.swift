//
//  SentryService.swift
//  I Do Blueprint
//
//  Sentry error tracking and performance monitoring service
//

import Foundation
import Sentry
import SentrySwiftUI
import SwiftUI

/// Service for managing Sentry error tracking and performance monitoring
@MainActor
final class SentryService {

    // MARK: - Singleton

    static let shared = SentryService()

    // MARK: - Properties

    private let logger = AppLogger.analytics
    private var isInitialized = false
    private var activeTransactions: [String: Span] = [:]

    // MARK: - Initialization

    private init() {}
    
    // MARK: - Configuration
    
    /// Initialize Sentry SDK with configuration from AppConfig (with Config.plist fallback)
    func configure() {
        guard !isInitialized else {
            logger.warning("Sentry already initialized")
            return
        }
        
        let dsn = AppConfig.getSentryDSN()
        guard !dsn.isEmpty else {
            logger.error("Sentry DSN not found in AppConfig")
            return
        }
        
        SentrySDK.start { options in
            options.dsn = dsn

            // Enable debug mode in development builds
            #if DEBUG
            options.debug = true
            #else
            options.debug = false
            #endif

            // Enable uncaught NSException reporting for macOS
            options.enableUncaughtNSExceptionReporting = true

            // Performance monitoring - capture 100% in development, 10% in production
            #if DEBUG
            options.tracesSampleRate = 1.0
            #else
            options.tracesSampleRate = 0.1
            #endif

            // Profiling configuration
            #if DEBUG
            options.profilesSampleRate = 1.0
            #else
            options.profilesSampleRate = 0.1
            #endif

            // Set environment
            #if DEBUG
            options.environment = "development"
            #else
            options.environment = "production"
            #endif

            // Set release version
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                options.releaseName = "\(version) (\(build))"
            }

            // Enable automatic breadcrumbs
            options.enableAutoBreadcrumbTracking = true
            options.enableAutoSessionTracking = true
            options.sessionTrackingIntervalMillis = 30000 // 30 seconds

            // Attach stack traces to messages
            options.attachStacktrace = true

            // Configure before send callback to add custom context
            options.beforeSend = { [weak self] event in
                self?.enrichEvent(event)
                return event
            }

            // Configure before breadcrumb callback
            options.beforeBreadcrumb = { breadcrumb in
                // Filter out sensitive breadcrumbs if needed
                return breadcrumb
            }
        }
        
        isInitialized = true
        logger.info("Sentry initialized successfully")
    }
    
    // MARK: - Error Capture
    
    /// Capture an error with optional context
    /// - Parameters:
    ///   - error: The error to capture
    ///   - context: Additional context information
    ///   - level: Severity level (default: .error)
    func captureError(
        _ error: Error,
        context: [String: Any]? = nil,
        level: SentryLevel = .error
    ) {
        guard isInitialized else {
            logger.warning("Sentry not initialized, cannot capture error")
            return
        }
        
        // Add context if provided
        if let context = context {
            SentrySDK.configureScope { scope in
                for (key, value) in context {
                    scope.setExtra(value: value, key: key)
                }
            }
        }
        
        // Capture the error
        let eventId = SentrySDK.capture(error: error) { scope in
            scope.setLevel(level)
        }
        
        logger.info("Error captured with Sentry - eventId: \(eventId)")
    }
    
    /// Capture a message with optional context
    /// - Parameters:
    ///   - message: The message to capture
    ///   - context: Additional context information
    ///   - level: Severity level (default: .info)
    func captureMessage(
        _ message: String,
        context: [String: Any]? = nil,
        level: SentryLevel = .info
    ) {
        guard isInitialized else {
            logger.warning("Sentry not initialized, cannot capture message")
            return
        }
        
        // Add context if provided
        if let context = context {
            SentrySDK.configureScope { scope in
                for (key, value) in context {
                    scope.setExtra(value: value, key: key)
                }
            }
        }
        
        // Capture the message
        let eventId = SentrySDK.capture(message: message) { scope in
            scope.setLevel(level)
        }
        
        logger.info("Message captured with Sentry - eventId: \(eventId)")
    }
    
    // MARK: - User Context
    
    /// Set user context for error tracking
    /// - Parameters:
    ///   - userId: User identifier
    ///   - email: User email (optional)
    ///   - username: Username (optional)
    func setUser(userId: String, email: String? = nil, username: String? = nil) {
        guard isInitialized else { return }
        
        let user = User(userId: userId)
        user.email = email
        user.username = username
        
        SentrySDK.setUser(user)
        logger.debug("Sentry user context set - userId: \(userId)")
    }
    
    /// Clear user context
    func clearUser() {
        guard isInitialized else { return }
        
        SentrySDK.setUser(nil)
        logger.debug("Sentry user context cleared")
    }
    
    // MARK: - Breadcrumbs
    
    /// Add a breadcrumb for debugging context
    /// - Parameters:
    ///   - message: Breadcrumb message
    ///   - category: Category (e.g., "navigation", "ui", "network")
    ///   - level: Severity level
    ///   - data: Additional data
    func addBreadcrumb(
        message: String,
        category: String,
        level: SentryLevel = .info,
        data: [String: Any]? = nil
    ) {
        guard isInitialized else { return }
        
        let crumb = Breadcrumb()
        crumb.message = message
        crumb.category = category
        crumb.level = level
        crumb.data = data
        
        SentrySDK.addBreadcrumb(crumb)
    }
    
    // MARK: - Performance Monitoring

    /// Start a performance transaction
    /// - Parameters:
    ///   - name: Transaction name
    ///   - operation: Operation type (e.g., "navigation", "task", "ui.load")
    /// - Returns: Transaction object to finish later
    func startTransaction(name: String, operation: String) -> Span? {
        guard isInitialized else { return nil }

        let transaction = SentrySDK.startTransaction(
            name: name,
            operation: operation,
            bindToScope: true
        )

        activeTransactions[name] = transaction
        return transaction
    }

    /// Finish a transaction by name
    /// - Parameters:
    ///   - name: Transaction name
    ///   - status: Optional transaction status
    func finishTransaction(name: String, status: SentrySpanStatus = .ok) {
        guard let transaction = activeTransactions[name] else { return }
        transaction.status = status
        transaction.finish()
        activeTransactions.removeValue(forKey: name)
    }

    /// Measure the time of a code block with automatic transaction handling
    /// - Parameters:
    ///   - name: Transaction name
    ///   - operation: Operation type
    ///   - block: Code block to measure
    func measure<T>(
        name: String,
        operation: String,
        block: () throws -> T
    ) rethrows -> T {
        let transaction = startTransaction(name: name, operation: operation)
        defer {
            transaction?.finish()
            activeTransactions.removeValue(forKey: name)
        }
        return try block()
    }

    /// Measure async code block
    func measureAsync<T>(
        name: String,
        operation: String,
        block: () async throws -> T
    ) async rethrows -> T {
        let transaction = startTransaction(name: name, operation: operation)
        defer {
            transaction?.finish()
            activeTransactions.removeValue(forKey: name)
        }
        return try await block()
    }
    
    // MARK: - Private Helpers
    
    // Note: loadDSN() method removed - now using AppConfig.getSentryDSN() directly
    
    /// Enrich event with additional context before sending
    nonisolated private func enrichEvent(_ event: Event) -> Event {
        // Add app-specific context
        event.context?["app"] = [
            "name": "I Do Blueprint",
            "platform": "macOS"
        ]
        
        // Add device context
        event.context?["device"] = [
            "model": ProcessInfo.processInfo.hostName,
            "os_version": ProcessInfo.processInfo.operatingSystemVersionString
        ]
        
        return event
    }
}

// MARK: - Convenience Extensions

extension SentryService {

    /// Capture a test error to verify Sentry integration
    func captureTestError() {
        let testError = NSError(
            domain: "com.idoblueprint.test",
            code: 999,
            userInfo: [
                NSLocalizedDescriptionKey: "This is a test error to verify Sentry integration"
            ]
        )

        captureError(
            testError,
            context: [
                "test": true,
                "timestamp": Date().ISO8601Format()
            ],
            level: .warning
        )

        logger.info("Test error sent to Sentry")
    }

    // MARK: - Navigation Tracking

    /// Track navigation to a view
    /// - Parameters:
    ///   - viewName: Name of the view
    ///   - metadata: Additional metadata
    func trackNavigation(to viewName: String, metadata: [String: Any]? = nil) {
        addBreadcrumb(
            message: "Navigation to \(viewName)",
            category: "navigation",
            level: .info,
            data: metadata
        )
    }

    // MARK: - User Action Tracking

    /// Track a user action
    /// - Parameters:
    ///   - action: Action name (e.g., "button_click", "form_submit")
    ///   - category: Action category (e.g., "vendors", "tasks", "budget")
    ///   - metadata: Additional metadata
    func trackAction(_ action: String, category: String, metadata: [String: Any]? = nil) {
        addBreadcrumb(
            message: action,
            category: "user.\(category)",
            level: .info,
            data: metadata
        )
    }

    // MARK: - Network Tracking

    /// Track network request
    /// - Parameters:
    ///   - url: Request URL
    ///   - method: HTTP method
    ///   - statusCode: Response status code
    ///   - duration: Request duration
    func trackNetworkRequest(
        url: String,
        method: String,
        statusCode: Int? = nil,
        duration: TimeInterval? = nil
    ) {
        var data: [String: Any] = [
            "url": url,
            "method": method
        ]

        if let statusCode = statusCode {
            data["status_code"] = statusCode
        }

        if let duration = duration {
            data["duration"] = duration
        }

        addBreadcrumb(
            message: "\(method) \(url)",
            category: "network",
            level: statusCode == nil || statusCode! < 400 ? .info : .error,
            data: data
        )
    }

    // MARK: - Data Operations

    /// Track data operation (create, update, delete)
    /// - Parameters:
    ///   - operation: Operation type (create, update, delete, fetch)
    ///   - entity: Entity type (vendor, task, guest, etc.)
    ///   - success: Whether operation succeeded
    ///   - metadata: Additional metadata
    func trackDataOperation(
        _ operation: String,
        entity: String,
        success: Bool,
        metadata: [String: Any]? = nil
    ) {
        var data = metadata ?? [:]
        data["operation"] = operation
        data["entity"] = entity
        data["success"] = success

        addBreadcrumb(
            message: "\(operation) \(entity)",
            category: "data",
            level: success ? .info : .warning,
            data: data
        )
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    /// Track this view's appearance in Sentry
    /// - Parameter name: View name for tracking
    /// - Returns: Modified view
    func trackView(_ name: String) -> some View {
        self.onAppear {
            Task { @MainActor in
                SentryService.shared.trackNavigation(to: name)
            }
        }
    }

    /// Measure this view's load time in Sentry
    /// - Parameter name: Transaction name
    /// - Returns: Modified view
    func measureViewLoad(_ name: String) -> some View {
        self.modifier(ViewPerformanceModifier(transactionName: name))
    }
}

// MARK: - View Performance Modifier

private struct ViewPerformanceModifier: ViewModifier {
    let transactionName: String
    @State private var transaction: Span?

    func body(content: Content) -> some View {
        content
            .onAppear {
                Task { @MainActor in
                    transaction = SentryService.shared.startTransaction(
                        name: transactionName,
                        operation: "ui.load"
                    )
                }
            }
            .onDisappear {
                Task { @MainActor in
                    SentryService.shared.finishTransaction(
                        name: transactionName,
                        status: .ok
                    )
                }
            }
    }
}
