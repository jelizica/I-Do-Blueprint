//
//  AppLogger.swift
//  I Do Blueprint
//
//  Structured logging facade with privacy controls
//

import Foundation
import OSLog

/// Log categories for different subsystems
enum LogCategory: String {
    case api = "API"
    case repository = "Repository"
    case ui = "UI"
    case export = "Export"
    case auth = "Auth"
    case storage = "Storage"
    case analytics = "Analytics"
    case network = "Network"
    case database = "Database"
    case cache = "Cache"
    case general = "General"
}

/// Log levels
enum LogLevel {
    case debug
    case info
    case warning
    case error
    case fault
}

/// Centralized logging facade
struct AppLogger: Sendable {
    private let logger: Logger
    private let category: LogCategory

    init(category: LogCategory) {
        self.category = category
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.idoblueprint", category: category.rawValue)
    }

    // MARK: - Public Logging Methods

    /// Log a debug message (only in DEBUG builds)
    nonisolated func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        logger.debug("\(message, privacy: .public) [\(fileBaseName(file)):\(line) \(function)]")
        #endif
    }

    /// Log an info message
    nonisolated func info(_ message: String, file: String = #file, function: String = #function) {
        logger.info("\(message, privacy: .public) [\(fileBaseName(file)) \(function)]")
    }

    /// Log a warning message
    nonisolated func warning(_ message: String, file: String = #file, function: String = #function) {
        logger.warning("\(message, privacy: .public) [\(fileBaseName(file)) \(function)]")
    }

    /// Log an error message
    nonisolated func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function) {
        if let error = error {
            logger.error("\(message, privacy: .public): \(error.localizedDescription, privacy: .public) [\(fileBaseName(file)) \(function)]")
        } else {
            logger.error("\(message, privacy: .public) [\(fileBaseName(file)) \(function)]")
        }
    }

    /// Log a critical fault
    nonisolated func fault(_ message: String, error: Error? = nil, file: String = #file, function: String = #function) {
        if let error = error {
            logger.fault("\(message, privacy: .public): \(error.localizedDescription, privacy: .public) [\(fileBaseName(file)) \(function)]")
        } else {
            logger.fault("\(message, privacy: .public) [\(fileBaseName(file)) \(function)]")
        }
    }

    // MARK: - Privacy-Safe Logging

    /// Log with explicit privacy control for sensitive data (redacted)
    nonisolated func logPrivate(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug:
            #if DEBUG
            logger.debug("\(message, privacy: .private)")
            #endif
        case .info:
            logger.info("\(message, privacy: .private)")
        case .warning:
            logger.warning("\(message, privacy: .private)")
        case .error:
            logger.error("\(message, privacy: .private)")
        case .fault:
            logger.fault("\(message, privacy: .private)")
        }
    }

    /// Log with public visibility (unredacted)
    nonisolated func logPublic(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug:
            #if DEBUG
            logger.debug("\(message, privacy: .public)")
            #endif
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .fault:
            logger.fault("\(message, privacy: .public)")
        }
    }

    // MARK: - PII Redaction Helpers

    /// Redact email addresses for logging
    func redactEmail(_ email: String) -> String {
        guard let atIndex = email.firstIndex(of: "@") else {
            return "[REDACTED_EMAIL]"
        }
        let prefix = email[..<atIndex]
        let suffix = email[email.index(after: atIndex)...]

        if prefix.count <= 2 {
            return "*@\(suffix)"
        }
        return "\(prefix.prefix(1))***@\(suffix)"
    }

    /// Redact sensitive data (API keys, tokens, etc.)
    func redactSecret(_ secret: String) -> String {
        if secret.count <= 8 {
            return "[REDACTED]"
        }
        return "\(secret.prefix(4))...\(secret.suffix(4))"
    }

    /// Log message with email redaction
    nonisolated func infoWithRedactedEmail(_ message: String, email: String) {
        let redacted = redactEmail(email)
        logger.info("\(message, privacy: .public) \(redacted, privacy: .public)")
    }

    // MARK: - Repository Logging Helpers

    /// Log repository operation success with minimal PII exposure
    nonisolated func repositorySuccess(_ operation: String, affectedRows: Int? = nil) {
        if let rows = affectedRows {
            logger.info("\(operation, privacy: .public) succeeded - affected rows: \(rows, privacy: .public)")
        } else {
            logger.info("\(operation, privacy: .public) succeeded")
        }
    }

    /// Log repository operation failure with error details
    nonisolated func repositoryFailure(_ operation: String, error: Error) {
        logger.error("\(operation, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
    }

    /// Log repository operation with redacted data summary
    nonisolated func repositoryOperation(_ operation: String, recordCount: Int? = nil) {
        if let count = recordCount {
            logger.info("\(operation, privacy: .public) - records: \(count, privacy: .public)")
        } else {
            logger.info("\(operation, privacy: .public)")
        }
    }

    // MARK: - Helpers

    nonisolated private func fileBaseName(_ file: String) -> String {
        URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
    }
}

// MARK: - Convenient Static Loggers

extension AppLogger {
    static let api = AppLogger(category: .api)
    static let repository = AppLogger(category: .repository)
    static let ui = AppLogger(category: .ui)
    static let export = AppLogger(category: .export)
    static let auth = AppLogger(category: .auth)
    static let storage = AppLogger(category: .storage)
    static let analytics = AppLogger(category: .analytics)
    static let network = AppLogger(category: .network)
    static let database = AppLogger(category: .database)
    static let cache = AppLogger(category: .cache)
    static let general = AppLogger(category: .general)
}
