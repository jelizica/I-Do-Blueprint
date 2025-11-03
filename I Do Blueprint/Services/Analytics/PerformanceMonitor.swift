//
//  PerformanceMonitor.swift
//  I Do Blueprint
//
//  Performance monitoring and operation timing
//  Part of JES-60: Performance Optimization
//

import Foundation

/// Thread-safe performance monitoring for tracking operation durations
///
/// This monitor provides:
/// - Operation timing and statistics
/// - Slow operation detection and alerts
/// - Performance reports and analytics
/// - Historical performance data
///
/// ## Usage Example
/// ```swift
/// // In repository
/// func fetchGuests() async throws -> [Guest] {
///     let startTime = Date()
///
///     let guests = try await client.from("guest_list").select().execute().value
///
///     let duration = Date().timeIntervalSince(startTime)
///     await PerformanceMonitor.shared.recordOperation("fetchGuests", duration: duration)
///
///     return guests
/// }
///
/// // Check performance
/// let report = await PerformanceMonitor.shared.performanceReport()
/// print(report)
/// ```
actor PerformanceMonitor {

    // MARK: - Types

    struct PerfEvent: Sendable, Identifiable, Codable {
        let id: UUID = UUID()
        let operation: String
        let duration: TimeInterval
        let mainThread: TimeInterval?
        let timestamp: Date
    }

    struct PerfStats: Sendable, Codable, Identifiable {
        var id: String { operation }
        let operation: String
        let count: Int
        let samples: Int
        let average: TimeInterval
        let median: TimeInterval
        let min: TimeInterval
        let max: TimeInterval
        let p95: TimeInterval
    }

    // MARK: - Singleton

    static let shared = PerformanceMonitor()

    private let logger = AppLogger.analytics

    // MARK: - Configuration

    /// Enable verbose breadcrumbs/logs when performance monitoring is enabled via PerformanceFeatureFlags
    private var verboseEnabled: Bool {
        PerformanceFeatureFlags.enablePerformanceMonitoring
    }

    // MARK: - Storage

    /// Recent events buffer (for diagnostics UI)
    private var recentEvents: [PerfEvent] = []
    private let maxRecentEvents = 500

    /// Threshold for slow operation warnings (in seconds)
    private let slowOperationThreshold: TimeInterval = 1.0

    /// Maximum number of samples to keep per operation
    private let maxSamplesPerOperation = 100

    // MARK: - Private Properties

    /// Operation timing data
    private var operationTimes: [String: [TimeInterval]] = [:]

    /// Slow operation alerts
    private var slowOperations: [(operation: String, duration: TimeInterval, timestamp: Date)] = []

    /// Total operation counts
    private var operationCounts: [String: Int] = [:]

    // MARK: - Public Interface

    /// Records an operation duration (total time only)
    ///
    /// - Parameters:
    ///   - operation: The name of the operation (e.g., "fetchGuests")
    ///   - duration: The duration in seconds
    func recordOperation(_ operation: String, duration: TimeInterval) async {
        await recordOperation(operation, duration: duration, mainThread: nil)
    }

    /// Records an operation duration including optional main-thread time
    /// - Parameters:
    ///   - operation: Name (e.g., "guest.fetchGuests")
    ///   - duration: Total duration (s)
    ///   - mainThread: Optional time spent on main-thread (s)
    func recordOperation(_ operation: String, duration: TimeInterval, mainThread: TimeInterval?) async {
        // Record timing
        var times = operationTimes[operation, default: []]
        times.append(duration)

        // Keep only recent samples to prevent memory growth
        if times.count > maxSamplesPerOperation {
            times.removeFirst(times.count - maxSamplesPerOperation)
        }

        operationTimes[operation] = times

        // Increment count
        operationCounts[operation, default: 0] += 1

        // Check for slow operations
        if duration > slowOperationThreshold {
            let alert = (operation: operation, duration: duration, timestamp: Date())
            slowOperations.append(alert)

            // Keep only recent slow operations (last 50)
            if slowOperations.count > 50 {
                slowOperations.removeFirst(slowOperations.count - 50)
            }

            logger.warning("Slow operation detected: \(operation) took \(String(format: "%.2f", duration))s")
        }

        // Optional Sentry breadcrumb for visibility when enabled
        if verboseEnabled {
            var data: [String: Any] = [
                "operation": operation,
                "duration_ms": Int(duration * 1000)
            ]
            if let mainThread {
                data["main_thread_ms"] = Int(mainThread * 1000)
            }
            await MainActor.run {
                SentryService.shared.addBreadcrumb(
                    message: "perf_operation",
                    category: "performance",
                    data: data
                )
            }
        }

        // Record recent event for diagnostics
        let event = PerfEvent(
            operation: operation,
            duration: duration,
            mainThread: mainThread,
            timestamp: Date()
        )
        recentEvents.append(event)
        if recentEvents.count > maxRecentEvents {
            recentEvents.removeFirst(recentEvents.count - maxRecentEvents)
        }
    }

    /// Gets the average duration for an operation
    ///
    /// - Parameter operation: The operation name
    /// - Returns: The average duration in seconds, or nil if no data
    func averageDuration(for operation: String) -> TimeInterval? {
        guard let times = operationTimes[operation], !times.isEmpty else {
            return nil
        }
        return times.reduce(0, +) / Double(times.count)
    }

    /// Gets the median duration for an operation
    ///
    /// - Parameter operation: The operation name
    /// - Returns: The median duration in seconds, or nil if no data
    func medianDuration(for operation: String) -> TimeInterval? {
        guard let times = operationTimes[operation], !times.isEmpty else {
            return nil
        }

        let sorted = times.sorted()
        let count = sorted.count

        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        } else {
            return sorted[count / 2]
        }
    }

    /// Gets the 95th percentile duration for an operation
    ///
    /// - Parameter operation: The operation name
    /// - Returns: The 95th percentile duration in seconds, or nil if no data
    func p95Duration(for operation: String) -> TimeInterval? {
        guard let times = operationTimes[operation], !times.isEmpty else {
            return nil
        }

        let sorted = times.sorted()
        let index = Int(Double(sorted.count) * 0.95)
        return sorted[min(index, sorted.count - 1)]
    }

    /// Gets statistics for an operation
    ///
    /// - Parameter operation: The operation name
    /// - Returns: Dictionary with operation statistics
    func statistics(for operation: String) -> [String: Any]? {
        guard let times = operationTimes[operation], !times.isEmpty else {
            return nil
        }

        let sorted = times.sorted()
        let count = operationCounts[operation, default: 0]

        return [
            "operation": operation,
            "count": count,
            "samples": times.count,
            "average": times.reduce(0, +) / Double(times.count),
            "median": medianDuration(for: operation) ?? 0,
            "min": sorted.first ?? 0,
            "max": sorted.last ?? 0,
            "p95": p95Duration(for: operation) ?? 0
        ]
    }

    /// Gets all slow operations
    ///
    /// - Returns: Array of slow operation alerts
    func slowOperationAlerts() -> [(operation: String, duration: TimeInterval, timestamp: Date)] {
        slowOperations
    }

    /// Clears all performance data
    func clear() {
        operationTimes.removeAll()
        slowOperations.removeAll()
        operationCounts.removeAll()
    }

    /// Convenience to measure an async block and record total duration
    func measureAsync<T>(name: String, block: () async throws -> T) async rethrows -> T {
        let start = Date()
        do {
            let result = try await block()
            let duration = Date().timeIntervalSince(start)
            await recordOperation(name, duration: duration)
            return result
        } catch {
            let duration = Date().timeIntervalSince(start)
            await recordOperation(name, duration: duration)
            throw error
        }
    }

    /// Snapshot of recent events (most recent last)
    func getRecentEvents(limit: Int? = nil) -> [PerfEvent] {
        if let limit, limit > 0 { return Array(recentEvents.suffix(limit)) }
        return recentEvents
    }

    /// Available operations keys (alphabetical)
    func operationsList() -> [String] {
        Array(operationTimes.keys).sorted()
    }

    /// Typed statistics for all operations
    func statisticsSnapshot() -> [PerfStats] {
        let ops = operationsList()
        return ops.compactMap { op in
            guard let stats = statistics(for: op) else { return nil }
            return PerfStats(
                operation: op,
                count: stats["count"] as? Int ?? 0,
                samples: stats["samples"] as? Int ?? 0,
                average: stats["average"] as? TimeInterval ?? 0,
                median: stats["median"] as? TimeInterval ?? 0,
                min: stats["min"] as? TimeInterval ?? 0,
                max: stats["max"] as? TimeInterval ?? 0,
                p95: stats["p95"] as? TimeInterval ?? 0
            )
        }
    }

    /// Generates a performance report
    ///
    /// - Returns: A formatted string with performance statistics
    func performanceReport() -> String {
        var report = "⚡️ Performance Report\n"
        report += "=" * 50 + "\n\n"

        let operations = operationTimes.keys.sorted()

        if operations.isEmpty {
            report += "No performance data recorded.\n"
            return report
        }

        for operation in operations {
            guard let stats = statistics(for: operation) else { continue }

            report += "Operation: \(operation)\n"
            report += "  Count: \(stats["count"] ?? 0)\n"
            report += "  Average: \(formatDuration(stats["average"] as? TimeInterval ?? 0))\n"
            report += "  Median: \(formatDuration(stats["median"] as? TimeInterval ?? 0))\n"
            report += "  Min: \(formatDuration(stats["min"] as? TimeInterval ?? 0))\n"
            report += "  Max: \(formatDuration(stats["max"] as? TimeInterval ?? 0))\n"
            report += "  P95: \(formatDuration(stats["p95"] as? TimeInterval ?? 0))\n\n"
        }

        // Slow operations summary
        if !slowOperations.isEmpty {
            report += "=" * 50 + "\n"
            report += "⚠️ Slow Operations (>\(String(format: "%.1f", slowOperationThreshold))s):\n\n"

            let recentSlowOps = slowOperations.suffix(10)
            for alert in recentSlowOps {
                let timeAgo = formatTimeAgo(alert.timestamp)
                report += "  \(alert.operation): \(formatDuration(alert.duration)) (\(timeAgo))\n"
            }

            if slowOperations.count > 10 {
                report += "\n  ... and \(slowOperations.count - 10) more\n"
            }
        }

        return report
    }

    // MARK: - Private Helpers

    /// Formats a duration for display
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 0.001 {
            return String(format: "%.2fμs", duration * 1_000_000)
        } else if duration < 1.0 {
            return String(format: "%.0fms", duration * 1000)
        } else {
            return String(format: "%.2fs", duration)
        }
    }

    /// Formats a timestamp as "time ago"
    private func formatTimeAgo(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)

        if seconds < 60 {
            return "\(Int(seconds))s ago"
        } else if seconds < 3600 {
            return "\(Int(seconds / 60))m ago"
        } else if seconds < 86400 {
            return "\(Int(seconds / 3600))h ago"
        } else {
            return "\(Int(seconds / 86400))d ago"
        }
    }
}

// MARK: - String Extension for Report Formatting

private extension String {
    static func * (left: String, right: Int) -> String {
        String(repeating: left, count: right)
    }
}
