//
//  LoggingConfiguration.swift
//  I Do Blueprint
//
//  Centralized logging configuration with per-category log levels and sampling
//

import Foundation
import Combine

/// Configuration for logging behavior
@MainActor
final class LoggingConfiguration: ObservableObject {
    static let shared = LoggingConfiguration()
    
    /// Global log level (can be overridden per category)
    @Published var globalLogLevel: LogLevel = {
        #if DEBUG
        return .debug
        #else
        return .info
        #endif
    }()
    
    /// Per-category log level overrides
    @Published private(set) var categoryLevels: [LogCategory: LogLevel] = [:]
    
    /// Sampling configuration for high-frequency logs
    @Published private(set) var samplingRates: [LogCategory: Double] = [:]
    
    /// Whether to include file/function/line information in logs
    @Published var includeSourceLocation: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    /// Whether to enable performance metrics logging
    @Published var enablePerformanceMetrics: Bool = true
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Configuration Management
    
    /// Set log level for a specific category
    func setLogLevel(_ level: LogLevel, for category: LogCategory) {
        categoryLevels[category] = level
        saveConfiguration()
    }
    
    /// Remove category-specific log level (falls back to global)
    func removeLogLevel(for category: LogCategory) {
        categoryLevels.removeValue(forKey: category)
        saveConfiguration()
    }
    
    /// Set sampling rate for a category (0.0 to 1.0)
    /// - Parameter rate: Probability of logging (0.0 = never, 1.0 = always)
    func setSamplingRate(_ rate: Double, for category: LogCategory) {
        samplingRates[category] = min(max(rate, 0.0), 1.0)
        saveConfiguration()
    }
    
    /// Remove sampling rate for a category
    func removeSamplingRate(for category: LogCategory) {
        samplingRates.removeValue(forKey: category)
        saveConfiguration()
    }
    
    /// Get effective log level for a category
    func effectiveLogLevel(for category: LogCategory) -> LogLevel {
        categoryLevels[category] ?? globalLogLevel
    }
    
    /// Check if a log should be sampled (returns true if should log)
    func shouldSample(for category: LogCategory) -> Bool {
        guard let rate = samplingRates[category] else {
            return true // No sampling configured, always log
        }
        return Double.random(in: 0...1) <= rate
    }
    
    /// Check if a log level should be logged for a category
    func shouldLog(level: LogLevel, for category: LogCategory) -> Bool {
        let effectiveLevel = effectiveLogLevel(for: category)
        return level.priority >= effectiveLevel.priority
    }
    
    // MARK: - Preset Configurations
    
    /// Apply production-optimized logging configuration
    func applyProductionPreset() {
        globalLogLevel = .info
        
        // Reduce verbosity for high-frequency categories
        categoryLevels = [
            .cache: .warning,
            .network: .info,
            .database: .info
        ]
        
        // Sample high-frequency logs
        samplingRates = [
            .cache: 0.1,  // Log 10% of cache operations
            .network: 0.5 // Log 50% of network operations
        ]
        
        includeSourceLocation = false
        enablePerformanceMetrics = true
        
        saveConfiguration()
    }
    
    /// Apply development-optimized logging configuration
    func applyDevelopmentPreset() {
        globalLogLevel = .debug
        categoryLevels.removeAll()
        samplingRates.removeAll()
        includeSourceLocation = true
        enablePerformanceMetrics = true
        
        saveConfiguration()
    }
    
    /// Apply debugging preset (maximum verbosity)
    func applyDebuggingPreset() {
        globalLogLevel = .debug
        categoryLevels.removeAll()
        samplingRates.removeAll()
        includeSourceLocation = true
        enablePerformanceMetrics = true
        
        saveConfiguration()
    }
    
    /// Apply minimal logging preset (errors only)
    func applyMinimalPreset() {
        globalLogLevel = .error
        categoryLevels = [
            .api: .error,
            .repository: .error,
            .database: .error,
            .network: .error,
            .cache: .fault,
            .ui: .error,
            .auth: .warning,
            .storage: .error
        ]
        samplingRates.removeAll()
        includeSourceLocation = false
        enablePerformanceMetrics = false
        
        saveConfiguration()
    }
    
    // MARK: - Persistence
    
    private var configurationURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("I Do Blueprint", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("logging-config.json")
    }
    
    private func saveConfiguration() {
        let config = SerializableConfig(
            globalLogLevel: globalLogLevel.rawValue,
            categoryLevels: categoryLevels.mapValues { $0.rawValue },
            samplingRates: samplingRates,
            includeSourceLocation: includeSourceLocation,
            enablePerformanceMetrics: enablePerformanceMetrics
        )
        
        if let data = try? JSONEncoder().encode(config) {
            try? data.write(to: configurationURL)
        }
    }
    
    private func loadConfiguration() {
        guard let data = try? Data(contentsOf: configurationURL),
              let config = try? JSONDecoder().decode(SerializableConfig.self, from: data) else {
            return
        }
        
        if let level = LogLevel(rawValue: config.globalLogLevel) {
            globalLogLevel = level
        }
        
        // Convert string keys back to LogCategory
        categoryLevels = Dictionary(uniqueKeysWithValues:
            config.categoryLevels.compactMap { key, value in
                guard let category = LogCategory(rawValue: key),
                      let level = LogLevel(rawValue: value) else {
                    return nil
                }
                return (category, level)
            }
        )
        
        samplingRates = Dictionary(uniqueKeysWithValues:
            config.samplingRates.compactMap { key, value in
                guard let category = LogCategory(rawValue: key) else {
                    return nil
                }
                return (category, value)
            }
        )
        
        includeSourceLocation = config.includeSourceLocation
        enablePerformanceMetrics = config.enablePerformanceMetrics
    }
    
    // MARK: - Helper Types
    
    private struct SerializableConfig: Codable {
        let globalLogLevel: String
        let categoryLevels: [String: String]
        let samplingRates: [String: Double]
        let includeSourceLocation: Bool
        let enablePerformanceMetrics: Bool
        
        enum CodingKeys: String, CodingKey {
            case globalLogLevel
            case categoryLevels
            case samplingRates
            case includeSourceLocation
            case enablePerformanceMetrics
        }
        
        init(globalLogLevel: String, categoryLevels: [LogCategory: String], samplingRates: [LogCategory: Double], includeSourceLocation: Bool, enablePerformanceMetrics: Bool) {
            self.globalLogLevel = globalLogLevel
            self.categoryLevels = Dictionary(uniqueKeysWithValues: categoryLevels.map { ($0.key.rawValue, $0.value) })
            self.samplingRates = Dictionary(uniqueKeysWithValues: samplingRates.map { ($0.key.rawValue, $0.value) })
            self.includeSourceLocation = includeSourceLocation
            self.enablePerformanceMetrics = enablePerformanceMetrics
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            globalLogLevel = try container.decode(String.self, forKey: .globalLogLevel)
            categoryLevels = try container.decode([String: String].self, forKey: .categoryLevels)
            samplingRates = try container.decode([String: Double].self, forKey: .samplingRates)
            includeSourceLocation = try container.decode(Bool.self, forKey: .includeSourceLocation)
            enablePerformanceMetrics = try container.decode(Bool.self, forKey: .enablePerformanceMetrics)
        }
    }
}

// MARK: - LogLevel Extensions

extension LogLevel {
    var rawValue: String {
        switch self {
        case .debug: return "debug"
        case .info: return "info"
        case .warning: return "warning"
        case .error: return "error"
        case .fault: return "fault"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "debug": self = .debug
        case "info": self = .info
        case "warning": self = .warning
        case "error": self = .error
        case "fault": self = .fault
        default: return nil
        }
    }
    
    var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .fault: return 4
        }
    }
    
    var displayName: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        case .fault: return "Fault"
        }
    }
}

extension LogCategory {
    var displayName: String {
        rawValue
    }
}
