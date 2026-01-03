---
title: Cache Strategy Consolidation and Monitoring Implementation
type: note
permalink: architecture/caching/cache-strategy-consolidation-and-monitoring-implementation
tags:
- caching
- monitoring
- sentry
- performance
- architecture
---

# Cache Strategy Consolidation and Monitoring Implementation

## Overview

Implemented comprehensive cache strategy consolidation and monitoring system for I Do Blueprint macOS app. This enhancement provides centralized configuration, Sentry integration, and health monitoring for the actor-based repository cache system.

## Problem Statement

The existing cache infrastructure had:
- Per-domain cache invalidation strategies without central configuration
- No cache performance monitoring or metrics
- Inconsistent cache key naming across domains
- No integration with Sentry for production monitoring
- Manual cache warming without standardized approach

## Solution Architecture

### 1. CacheConfiguration (Central Config)

**Location:** `Domain/Repositories/Caching/CacheConfiguration.swift`

**Key Features:**
- **TTL Configuration:** Standardized time-to-live values for different data types
  - `defaultTTL: 60s` - Standard cache entries
  - `frequentAccessTTL: 120s` - Guest lists, vendor lists
  - `stableDataTTL: 300s` - Settings, configuration
  - `aggregatedDataTTL: 60s` - Budget summaries, statistics
  - `searchResultsTTL: 30s` - Search and filtered data

- **Standardized Key Prefixes:** Enum-based cache key generation
  ```swift
  enum KeyPrefix: String {
      case guest, guestStats, guestCount, guestGroups, guestRSVP
      case budget, budgetSummary, budgetCategories, budgetExpenses
      case vendor, vendorDetail, vendorStats
      case task, taskDetail, taskStats, subtasks
      case timeline, timelineItems, milestones
      case document, documentDetail, documentSearch
      
      func key(tenantId: UUID) -> String
      func key(tenantId: UUID, id: String) -> String
  }
  ```

- **Cache Warming Strategy:** Predefined domain sets
  - `warmOnLaunch` - Critical data loaded at app start
  - `warmAfterOnboarding` - Full data set after user setup

- **Monitoring Configuration:**
  - `minimumHitRateThreshold: 0.5` - Alert threshold
  - `minimumAccessesForMetrics: 10` - Statistical significance
  - `cleanupInterval: 300s` - Automatic cleanup frequency
  - `maxCacheEntries: 1000` - Size limit before forced cleanup

- **Feature Flags:**
  - `enableMetrics: true` - Cache performance tracking
  - `enableAutoWarming: true` - Automatic cache warming
  - `enableSentryIntegration: true` - Production monitoring
  - `enableDebugLogging: DEBUG only` - Verbose cache logs

### 2. CacheMonitor (Monitoring Service)

**Location:** `Domain/Repositories/Caching/CacheMonitor.swift`

**Key Features:**

#### Health Monitoring
```swift
actor CacheMonitor {
    func generateHealthReport() async -> CacheHealthReport
    func trackOperation(_ operation: CacheOperation, hit: Bool, duration: TimeInterval?)
    func trackInvalidation(_ operation: CacheOperation, keysInvalidated: Int)
}
```

**CacheHealthReport Structure:**
- Overall hit rate and statistics
- Per-domain metrics with health status (Excellent/Good/Fair/Poor)
- Unhealthy domain identification
- Actionable recommendations
- Formatted report generation

**Health Status Thresholds:**
- 🟢 Excellent: ≥80% hit rate
- 🟡 Good: ≥60% hit rate
- 🟠 Fair: ≥40% hit rate
- 🔴 Poor: <40% hit rate
- ⚪️ Unknown: Insufficient data

#### Sentry Integration
- Breadcrumb tracking for cache operations (hit/miss)
- Automatic health check reporting
- Warning messages for unhealthy cache performance
- Context-rich error capture with metrics

#### Automatic Cleanup
- Background cleanup timer (5-minute intervals)
- Expired entry removal
- Forced cleanup when exceeding max entries
- Cleanup event logging to Sentry

#### Cache Warming
- Coordinated warming for specified domains
- Tenant-scoped warming operations
- Sentry breadcrumb tracking for warming events

### 3. Updated Cache Strategies

All domain-specific cache strategies updated to use new infrastructure:

**Updated Files:**
- `GuestCacheStrategy.swift`
- `BudgetCacheStrategy.swift`
- `VendorCacheStrategy.swift`
- `TaskCacheStrategy.swift`
- `TimelineCacheStrategy.swift`
- `DocumentCacheStrategy.swift`

**Pattern Applied:**
```swift
actor DomainCacheStrategy: CacheInvalidationStrategy {
    private let cache = RepositoryCache.shared
    private let monitor = CacheMonitor.shared
    
    func invalidate(for operation: CacheOperation) async {
        // Use CacheConfiguration.KeyPrefix for standardized keys
        // Track invalidation count
        // Report to monitor
        await monitor.trackInvalidation(operation, keysInvalidated: count)
    }
}
```

**Key Improvements:**
- Standardized key generation via `CacheConfiguration.KeyPrefix`
- Invalidation tracking with key counts
- Monitor integration for metrics
- Backward compatibility with legacy keys

## Implementation Details

### Cache Key Standardization

**Before:**
```swift
await cache.remove("guests_\(tenantId.uuidString)")
await cache.remove("guest_stats_\(tenantId.uuidString)")
```

**After:**
```swift
let keysToInvalidate = [
    CacheConfiguration.KeyPrefix.guest.key(tenantId: tenantId),
    CacheConfiguration.KeyPrefix.guestStats.key(tenantId: tenantId)
]
for key in keysToInvalidate {
    await cache.remove(key)
    keysInvalidated += 1
}
await monitor.trackInvalidation(operation, keysInvalidated: keysInvalidated)
```

### Monitoring Integration

**Cache Operation Tracking:**
```swift
// In repositories
let hit = cachedData != nil
await CacheMonitor.shared.trackOperation(.guestCreated(tenantId: tenantId), hit: hit)
```

**Health Check Generation:**
```swift
let report = await CacheMonitor.shared.generateHealthReport()
print(report.formattedReport())
// Automatically sent to Sentry if unhealthy
```

### Backward Compatibility

All strategies maintain backward compatibility by invalidating both:
1. New standardized keys (via `CacheConfiguration.KeyPrefix`)
2. Legacy keys (existing string-based keys)

This ensures smooth transition without breaking existing cache invalidation.

## Benefits

### 1. Centralized Configuration
- Single source of truth for TTL values
- Consistent cache key naming across all domains
- Easy adjustment of cache behavior project-wide

### 2. Production Monitoring
- Real-time cache performance metrics in Sentry
- Automatic alerting for poor cache performance
- Breadcrumb trail for debugging cache issues
- Health reports with actionable recommendations

### 3. Improved Maintainability
- Standardized cache invalidation patterns
- Reduced code duplication across strategies
- Clear separation of concerns (config, monitoring, invalidation)

### 4. Performance Insights
- Hit rate tracking per domain
- Identification of cache inefficiencies
- Data-driven optimization opportunities

### 5. Automatic Cleanup
- Prevents cache memory bloat
- Removes expired entries automatically
- Forced cleanup at size limits

## Usage Examples

### Generate Health Report
```swift
let report = await CacheMonitor.shared.generateHealthReport()
print(report.formattedReport())

if !report.isHealthy {
    // Take action based on recommendations
    for recommendation in report.recommendations {
        print("⚠️ \(recommendation)")
    }
}
```

### Warm Cache on Launch
```swift
await CacheMonitor.shared.warmCache(
    domains: CacheConfiguration.warmOnLaunch,
    tenantId: currentTenantId
)
```

### Track Cache Operations
```swift
// Automatically tracked by updated cache strategies
await cacheStrategy.invalidate(for: .guestCreated(tenantId: tenantId))
// Sends metrics to CacheMonitor → Sentry
```

## Testing Considerations

### Unit Tests Needed
1. **CacheConfiguration Tests**
   - Verify key generation with tenant IDs
   - Test TTL value consistency
   - Validate feature flag behavior

2. **CacheMonitor Tests**
   - Health report generation accuracy
   - Sentry integration (mock)
   - Automatic cleanup timing
   - Cache warming coordination

3. **Updated Strategy Tests**
   - Verify standardized key usage
   - Confirm monitor tracking calls
   - Test backward compatibility
   - Validate invalidation counts

### Integration Tests
- End-to-end cache invalidation flows
- Health monitoring under load
- Sentry breadcrumb verification
- Cache warming effectiveness

## Future Enhancements

### Potential Improvements
1. **Adaptive TTL:** Adjust TTL based on access patterns
2. **Cache Preloading:** Predictive cache warming based on user behavior
3. **Distributed Caching:** Support for multi-device cache coordination
4. **Cache Analytics Dashboard:** Visual representation of cache metrics
5. **A/B Testing:** Compare cache strategies for optimization

### Monitoring Enhancements
1. **Custom Sentry Dashboards:** Dedicated cache performance views
2. **Alerting Rules:** Automated notifications for cache degradation
3. **Historical Trending:** Track cache performance over time
4. **Anomaly Detection:** Identify unusual cache patterns

## Related Files

### Core Implementation
- `Domain/Repositories/RepositoryCache.swift` - Base cache actor
- `Domain/Repositories/Caching/CacheConfiguration.swift` - Central config
- `Domain/Repositories/Caching/CacheMonitor.swift` - Monitoring service
- `Domain/Repositories/Caching/CacheOperation.swift` - Operation enum
- `Domain/Repositories/Caching/CacheInvalidationStrategy.swift` - Strategy protocol

### Updated Strategies
- `Domain/Repositories/Caching/GuestCacheStrategy.swift`
- `Domain/Repositories/Caching/BudgetCacheStrategy.swift`
- `Domain/Repositories/Caching/VendorCacheStrategy.swift`
- `Domain/Repositories/Caching/TaskCacheStrategy.swift`
- `Domain/Repositories/Caching/TimelineCacheStrategy.swift`
- `Domain/Repositories/Caching/DocumentCacheStrategy.swift`

### Integration Points
- `Services/Analytics/SentryService.swift` - Monitoring integration
- `Utilities/Logging/AppLogger.swift` - Cache logging category

## Documentation References

- **Best Practices:** `best_practices.md` - Cache patterns section
- **Architecture:** `docs/CACHE_ARCHITECTURE.md` - Cache system overview
- **Domain Services:** `docs/DOMAIN_SERVICES_ARCHITECTURE.md` - Repository patterns

## Completion Status

✅ **Completed:**
- CacheConfiguration implementation
- CacheMonitor with Sentry integration
- All 6 cache strategies updated
- Standardized key generation
- Health monitoring and reporting
- Automatic cleanup system

⏳ **Remaining Work:**
- Build verification (Xcode build test)
- Unit tests for new components
- Integration tests for monitoring
- Documentation updates in CACHE_ARCHITECTURE.md
- Performance benchmarking

## Issue Tracking

**Beads Issue:** `I Do Blueprint-09l` - Cache Strategy Consolidation and Monitoring
**Status:** Implementation complete, pending build verification and testing
**Priority:** P2 (Medium)
**Labels:** caching, performance, monitoring

---

**Implementation Date:** 2025-12-29
**Author:** AI Assistant (Claude)
**Review Status:** Pending code review and testing