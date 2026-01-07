//
//  CacheConfiguration.swift
//  I Do Blueprint
//
//  Central cache configuration and monitoring
//  Part of I Do Blueprint-09l: Cache Strategy Consolidation and Monitoring
//

import Foundation

/// Central configuration for cache behavior across all domains
struct CacheConfiguration {
    
    // MARK: - TTL Configuration
    
    /// Default time-to-live for cache entries (in seconds)
    static let defaultTTL: TimeInterval = 60
    
    /// TTL for frequently accessed data (e.g., guest lists, vendor lists)
    static let frequentAccessTTL: TimeInterval = 120
    
    /// TTL for rarely changing data (e.g., settings, configuration)
    static let stableDataTTL: TimeInterval = 300
    
    /// TTL for aggregated/computed data (e.g., budget summaries, statistics)
    static let aggregatedDataTTL: TimeInterval = 60
    
    /// TTL for search results and filtered data
    static let searchResultsTTL: TimeInterval = 30
    
    // MARK: - Cache Key Prefixes
    
    /// Standardized cache key prefixes for each domain
    enum KeyPrefix: String {
        case guest = "guests"
        case guestStats = "guest_stats"
        case guestCount = "guest_count"
        case guestGroups = "guest_groups"
        case guestRSVP = "guest_rsvp_summary"
        
        case budget = "budget"
        case budgetSummary = "budget_summary"
        case budgetCategories = "budget_categories"
        case budgetExpenses = "budget_expenses"
        case budgetOverview = "budget_overview"
        case categoryMetrics = "category_metrics"
        
        case vendor = "vendors"
        case vendorDetail = "vendor_detail"
        case vendorStats = "vendor_stats"
        case vendorCategories = "vendor_categories"
        
        case task = "tasks"
        case taskDetail = "task_detail"
        case taskStats = "task_stats"
        case subtasks = "subtasks"
        
        case timeline = "timeline"
        case timelineItems = "timeline_items"
        case milestones = "milestones"
        case weddingDayEvents = "wedding_day_events"
        
        case document = "documents"
        case documentDetail = "document_detail"
        case documentSearch = "document_search"
        
        case seatingChart = "seating_chart"
        case mealSelections = "meal_selections"
        
        /// Generate a cache key with tenant ID
        func key(tenantId: UUID) -> String {
            "\(rawValue)_\(tenantId.uuidString)"
        }
        
        /// Generate a cache key with tenant ID and additional identifier
        func key(tenantId: UUID, id: String) -> String {
            "\(rawValue)_\(tenantId.uuidString)_\(id)"
        }

        // MARK: - Convenience Static Methods

        /// Category budget metrics cache key
        static func categoryMetrics(_ tenantId: UUID) -> String {
            KeyPrefix.categoryMetrics.key(tenantId: tenantId)
        }
    }
    
    // MARK: - Cache Warming Strategy
    
    /// Domains that should be warmed on app launch
    static let warmOnLaunch: Set<KeyPrefix> = [
        .guest,
        .vendor,
        .task,
        .budgetSummary
    ]
    
    /// Domains that should be warmed after onboarding
    static let warmAfterOnboarding: Set<KeyPrefix> = [
        .guest,
        .guestStats,
        .vendor,
        .vendorStats,
        .task,
        .taskStats,
        .budget,
        .budgetSummary,
        .timeline
    ]
    
    // MARK: - Monitoring Configuration
    
    /// Minimum hit rate threshold for alerting (0.0 to 1.0)
    static let minimumHitRateThreshold: Double = 0.5
    
    /// Number of accesses before hit rate is considered meaningful
    static let minimumAccessesForMetrics: Int = 10
    
    /// Interval for automatic cache cleanup (in seconds)
    static let cleanupInterval: TimeInterval = 300 // 5 minutes
    
    /// Maximum cache size (number of entries) before forced cleanup
    static let maxCacheEntries: Int = 1000
    
    // MARK: - Feature Flags
    
    /// Enable cache metrics tracking
    static let enableMetrics: Bool = true
    
    /// Enable automatic cache warming
    static let enableAutoWarming: Bool = true
    
    /// Enable Sentry integration for cache monitoring
    static let enableSentryIntegration: Bool = true
    
    /// Enable debug logging for cache operations
    #if DEBUG
    static let enableDebugLogging: Bool = true
    #else
    static let enableDebugLogging: Bool = false
    #endif
}

// MARK: - Cache Metrics

/// Cache performance metrics for monitoring
struct CacheMetrics: Codable {
    let key: String
    let hits: Int
    let misses: Int
    let hitRate: Double
    let lastAccessed: Date
    let entryCount: Int
    
    var isHealthy: Bool {
        guard hits + misses >= CacheConfiguration.minimumAccessesForMetrics else {
            return true // Not enough data to determine health
        }
        return hitRate >= CacheConfiguration.minimumHitRateThreshold
    }
    
    var healthStatus: HealthStatus {
        guard hits + misses >= CacheConfiguration.minimumAccessesForMetrics else {
            return .unknown
        }
        
        if hitRate >= 0.8 {
            return .excellent
        } else if hitRate >= 0.6 {
            return .good
        } else if hitRate >= 0.4 {
            return .fair
        } else {
            return .poor
        }
    }
    
    enum HealthStatus: String {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        case unknown = "Unknown"
        
        var emoji: String {
            switch self {
            case .excellent: return "🟢"
            case .good: return "🟡"
            case .fair: return "🟠"
            case .poor: return "🔴"
            case .unknown: return "⚪️"
            }
        }
    }
}

// MARK: - Cache Health Report

/// Comprehensive cache health report
struct CacheHealthReport {
    let timestamp: Date
    let overallHitRate: Double
    let totalHits: Int
    let totalMisses: Int
    let activeEntries: Int
    let domainMetrics: [CacheMetrics]
    let unhealthyDomains: [String]
    let recommendations: [String]
    
    var isHealthy: Bool {
        overallHitRate >= CacheConfiguration.minimumHitRateThreshold &&
        unhealthyDomains.isEmpty
    }
    
    /// Generate a formatted report string
    func formattedReport() -> String {
        var report = "📊 Cache Health Report\n"
        report += "Generated: \(timestamp.formatted())\n"
        report += String(repeating: "=", count: 60) + "\n\n"
        
        // Overall statistics
        report += "Overall Statistics:\n"
        report += "  Hit Rate: \(String(format: "%.1f%%", overallHitRate * 100)) "
        report += overallHitRate >= 0.8 ? "🟢\n" : overallHitRate >= 0.6 ? "🟡\n" : "🔴\n"
        report += "  Total Hits: \(totalHits)\n"
        report += "  Total Misses: \(totalMisses)\n"
        report += "  Active Entries: \(activeEntries)\n\n"
        
        // Domain-specific metrics
        if !domainMetrics.isEmpty {
            report += "Domain Metrics:\n"
            for metric in domainMetrics.sorted(by: { $0.hitRate > $1.hitRate }) {
                report += "  \(metric.healthStatus.emoji) \(metric.key)\n"
                report += "    Hit Rate: \(String(format: "%.1f%%", metric.hitRate * 100))\n"
                report += "    Hits: \(metric.hits) | Misses: \(metric.misses)\n"
            }
            report += "\n"
        }
        
        // Unhealthy domains
        if !unhealthyDomains.isEmpty {
            report += "⚠️ Unhealthy Domains:\n"
            for domain in unhealthyDomains {
                report += "  • \(domain)\n"
            }
            report += "\n"
        }
        
        // Recommendations
        if !recommendations.isEmpty {
            report += "💡 Recommendations:\n"
            for recommendation in recommendations {
                report += "  • \(recommendation)\n"
            }
        }
        
        return report
    }
}
