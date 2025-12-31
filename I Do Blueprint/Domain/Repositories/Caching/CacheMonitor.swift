//
//  CacheMonitor.swift
//  I Do Blueprint
//
//  Cache monitoring and health tracking with Sentry integration
//  Part of I Do Blueprint-09l: Cache Strategy Consolidation and Monitoring
//

import Foundation
import Sentry

/// Actor-based cache monitoring service with Sentry integration
actor CacheMonitor {
    
    // MARK: - Singleton
    
    static let shared = CacheMonitor()
    
    // MARK: - Properties
    
    private let cache = RepositoryCache.shared
    private nonisolated let logger = AppLogger(category: .cache)
    private var lastCleanup: Date = Date()
    private var lastHealthCheck: Date = Date()
    
    // MARK: - Initialization
    
    private init() {
        // Start automatic cleanup timer if enabled
        if CacheConfiguration.enableAutoWarming {
            Task {
                await startAutomaticCleanup()
            }
        }
    }
    
    // MARK: - Health Monitoring
    
    /// Generate a comprehensive cache health report
    func generateHealthReport() async -> CacheHealthReport {
        let stats = await cache.statistics()
        let totalHits = stats["totalHits"] as? Int ?? 0
        let totalMisses = stats["totalMisses"] as? Int ?? 0
        let activeEntries = stats["activeEntries"] as? Int ?? 0
        let overallHitRate = stats["overallHitRate"] as? Double ?? 0.0
        
        // Collect domain-specific metrics
        var domainMetrics: [CacheMetrics] = []
        var unhealthyDomains: [String] = []
        
        // Check each domain prefix
        for prefix in CacheConfiguration.KeyPrefix.allCases {
            let key = prefix.rawValue
            let hitRate = await cache.hitRate(for: key)
            
            // Only include domains with activity
            if hitRate > 0 || totalHits > 0 {
                let metric = CacheMetrics(
                    key: key,
                    hits: totalHits, // Simplified - in production would track per-key
                    misses: totalMisses,
                    hitRate: hitRate,
                    lastAccessed: Date(),
                    entryCount: activeEntries
                )
                
                domainMetrics.append(metric)
                
                if !metric.isHealthy {
                    unhealthyDomains.append(key)
                }
            }
        }
        
        // Generate recommendations
        let recommendations = generateRecommendations(
            overallHitRate: overallHitRate,
            unhealthyDomains: unhealthyDomains,
            activeEntries: activeEntries
        )
        
        let report = CacheHealthReport(
            timestamp: Date(),
            overallHitRate: overallHitRate,
            totalHits: totalHits,
            totalMisses: totalMisses,
            activeEntries: activeEntries,
            domainMetrics: domainMetrics,
            unhealthyDomains: unhealthyDomains,
            recommendations: recommendations
        )
        
        // Log to Sentry if enabled
        if CacheConfiguration.enableSentryIntegration {
            await reportToSentry(report)
        }
        
        lastHealthCheck = Date()
        return report
    }
    
    /// Track a cache operation for monitoring
    func trackOperation(
        _ operation: CacheOperation,
        hit: Bool,
        duration: TimeInterval? = nil
    ) async {
        guard CacheConfiguration.enableMetrics else { return }
        
        // Log to AppLogger
        if CacheConfiguration.enableDebugLogging {
            logger.debug("Cache \(hit ? "HIT" : "MISS") for operation: \(String(describing: operation))")
        }
        
        // Track in Sentry if enabled
        if CacheConfiguration.enableSentryIntegration {
            await MainActor.run {
                SentryService.shared.addBreadcrumb(
                    message: "Cache \(hit ? "hit" : "miss")",
                    category: "cache",
                    level: .debug,
                    data: [
                        "operation": String(describing: operation),
                        "hit": hit,
                        "duration": duration ?? 0
                    ]
                )
            }
        }
    }
    
    /// Track cache invalidation for monitoring
    func trackInvalidation(
        _ operation: CacheOperation,
        keysInvalidated: Int
    ) async {
        guard CacheConfiguration.enableMetrics else { return }
        
        logger.info("Cache invalidation: \(String(describing: operation)) - \(keysInvalidated) keys")
        
        if CacheConfiguration.enableSentryIntegration {
            await MainActor.run {
                SentryService.shared.addBreadcrumb(
                    message: "Cache invalidation",
                    category: "cache",
                    level: .info,
                    data: [
                        "operation": String(describing: operation),
                        "keys_invalidated": keysInvalidated
                    ]
                )
            }
        }
    }
    
    // MARK: - Automatic Cleanup
    
    /// Start automatic cache cleanup timer
    private func startAutomaticCleanup() async {
        while true {
            try? await Task.sleep(nanoseconds: UInt64(CacheConfiguration.cleanupInterval * 1_000_000_000))
            await performCleanup()
        }
    }
    
    /// Perform cache cleanup
    func performCleanup() async {
        let stats = await cache.statistics()
        let activeEntries = stats["activeEntries"] as? Int ?? 0
        
        // Clean up expired entries
        await cache.cleanupExpired()
        
        // Force cleanup if over max entries
        if activeEntries > CacheConfiguration.maxCacheEntries {
            logger.warning("Cache size exceeded maximum (\(activeEntries) > \(CacheConfiguration.maxCacheEntries)), forcing cleanup")
            await cache.clear()
            
            if CacheConfiguration.enableSentryIntegration {
                await MainActor.run {
                    SentryService.shared.captureMessage(
                        "Cache size exceeded maximum, forced cleanup",
                        context: [
                            "active_entries": activeEntries,
                            "max_entries": CacheConfiguration.maxCacheEntries
                        ],
                        level: .warning
                    )
                }
            }
        }
        
        lastCleanup = Date()
        logger.debug("Cache cleanup completed - active entries: \(activeEntries)")
    }
    
    // MARK: - Cache Warming
    
    /// Warm cache for specified domains
    func warmCache(
        domains: Set<CacheConfiguration.KeyPrefix>,
        tenantId: UUID
    ) async {
        guard CacheConfiguration.enableAutoWarming else { return }
        
        logger.info("Warming cache for \(domains.count) domains")
        
        for domain in domains {
            let key = domain.key(tenantId: tenantId)
            logger.debug("Warming cache for domain: \(domain.rawValue)")
            
            // Note: Actual warming would be done by repositories
            // This just tracks the warming operation
            if CacheConfiguration.enableSentryIntegration {
                await MainActor.run {
                    SentryService.shared.addBreadcrumb(
                        message: "Cache warming",
                        category: "cache",
                        level: .info,
                        data: [
                            "domain": domain.rawValue,
                            "tenant_id": tenantId.uuidString
                        ]
                    )
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// Generate recommendations based on cache health
    private func generateRecommendations(
        overallHitRate: Double,
        unhealthyDomains: [String],
        activeEntries: Int
    ) -> [String] {
        var recommendations: [String] = []
        
        // Overall hit rate recommendations
        if overallHitRate < 0.5 {
            recommendations.append("Overall hit rate is low (\(String(format: "%.1f%%", overallHitRate * 100))). Consider increasing TTL values or implementing cache warming.")
        }
        
        // Unhealthy domains
        if !unhealthyDomains.isEmpty {
            recommendations.append("The following domains have poor cache performance: \(unhealthyDomains.joined(separator: ", ")). Review access patterns and TTL settings.")
        }
        
        // Cache size
        if activeEntries > CacheConfiguration.maxCacheEntries * 80 / 100 {
            recommendations.append("Cache is approaching maximum size (\(activeEntries)/\(CacheConfiguration.maxCacheEntries)). Consider reducing TTL or implementing more aggressive cleanup.")
        }
        
        // No issues
        if recommendations.isEmpty {
            recommendations.append("Cache is performing well. No action needed.")
        }
        
        return recommendations
    }
    
    /// Report cache health to Sentry
    private func reportToSentry(_ report: CacheHealthReport) async {
        await MainActor.run {
            // Add breadcrumb for health check
            SentryService.shared.addBreadcrumb(
                message: "Cache health check",
                category: "cache",
                level: report.isHealthy ? .info : .warning,
                data: [
                    "overall_hit_rate": report.overallHitRate,
                    "total_hits": report.totalHits,
                    "total_misses": report.totalMisses,
                    "active_entries": report.activeEntries,
                    "unhealthy_domains": report.unhealthyDomains.count
                ]
            )
            
            // Capture message if unhealthy
            if !report.isHealthy {
                SentryService.shared.captureMessage(
                    "Cache health check failed",
                    context: [
                        "overall_hit_rate": report.overallHitRate,
                        "unhealthy_domains": report.unhealthyDomains,
                        "recommendations": report.recommendations
                    ],
                    level: .warning
                )
            }
        }
    }
}

// MARK: - CacheConfiguration.KeyPrefix Extension

extension CacheConfiguration.KeyPrefix: CaseIterable {
    static var allCases: [CacheConfiguration.KeyPrefix] {
        [
            .guest, .guestStats, .guestCount, .guestGroups, .guestRSVP,
            .budget, .budgetSummary, .budgetCategories, .budgetExpenses, .budgetOverview,
            .vendor, .vendorDetail, .vendorStats, .vendorCategories,
            .task, .taskDetail, .taskStats, .subtasks,
            .timeline, .timelineItems, .milestones,
            .document, .documentDetail, .documentSearch,
            .seatingChart, .mealSelections
        ]
    }
}
