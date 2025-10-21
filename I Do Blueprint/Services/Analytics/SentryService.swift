//
//  SentryService.swift
//  I Do Blueprint
//
//  Sentry error tracking and performance monitoring service
//

import Foundation
import Sentry

/// Service for managing Sentry error tracking and performance monitoring
@MainActor
final class SentryService {
    
    // MARK: - Singleton
    
    static let shared = SentryService()
    
    // MARK: - Properties
    
    private let logger = AppLogger.analytics
    private var isInitialized = false
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Initialize Sentry SDK with configuration from Config.plist
    func configure() {
        guard !isInitialized else {
            logger.warning("Sentry already initialized")
            return
        }
        
        guard let dsn = loadDSN() else {
            logger.error("Sentry DSN not found in Config.plist")
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
            options.profilesSampleRate = 1.0
            
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
    ///   - operation: Operation type (e.g., "navigation", "task")
    /// - Returns: Transaction object to finish later
    func startTransaction(name: String, operation: String) -> Span? {
        guard isInitialized else { return nil }
        
        let transaction = SentrySDK.startTransaction(
            name: name,
            operation: operation,
            bindToScope: true
        )
        
        return transaction
    }
    
    // MARK: - Private Helpers
    
    /// Load Sentry DSN from Config.plist
    private func loadDSN() -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let dsn = config["SENTRY_DSN"] as? String,
              !dsn.isEmpty else {
            return nil
        }
        return dsn
    }
    
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
}
