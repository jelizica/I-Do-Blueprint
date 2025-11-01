//
//  LiveActivityFeedRepository.swift
//  I Do Blueprint
//
//  Production implementation of ActivityFeedRepositoryProtocol with caching
//

import Foundation
import Supabase

/// Production implementation of ActivityFeedRepositoryProtocol
actor LiveActivityFeedRepository: ActivityFeedRepositoryProtocol {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.repository
    private let sessionManager: SessionManager

    init(supabase: SupabaseClient? = nil, sessionManager: SessionManager = .shared) {
        self.supabase = supabase
        self.sessionManager = sessionManager
    }

    convenience init() {
        self.init(supabase: SupabaseManager.shared.client)
    }
    
    private func getClient() throws -> SupabaseClient {
        guard let supabase = supabase else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return supabase
    }

    private func getTenantId() async throws -> UUID {
        try await MainActor.run {
            try sessionManager.requireTenantId()
        }
    }

    // MARK: - Fetch Operations
    
    func fetchActivities(limit: Int = 50, offset: Int = 0) async throws -> [ActivityEvent] {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let cacheKey = "activities_\(tenantId.uuidString)_\(limit)_\(offset)"
            let startTime = Date()

            // Check cache first (short TTL for activity feed)
            if let cached: [ActivityEvent] = await RepositoryCache.shared.get(cacheKey, maxAge: 30) {
                logger.info("Cache hit: activities (\(cached.count) items)")
                return cached
            }

            logger.info("Cache miss: fetching activities from database")

            let activities: [ActivityEvent] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("activity_events")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .order("created_at", ascending: false)
                    .limit(limit)
                    .range(from: offset, to: offset + limit - 1)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            
            // Cache for 30 seconds
            await RepositoryCache.shared.set(cacheKey, value: activities, ttl: 30)
            
            await PerformanceMonitor.shared.recordOperation("fetchActivities", duration: duration)

            logger.info("Fetched \(activities.count) activities in \(String(format: "%.2f", duration))s")

            return activities
        } catch {
            logger.error("Failed to fetch activities", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchActivities",
                "limit": String(limit),
                "offset": String(offset)
            ])
            throw ActivityFeedError.fetchFailed(underlying: error)
        }
    }
    
    func fetchActivities(actionType: ActionType, limit: Int = 50) async throws -> [ActivityEvent] {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            let activities: [ActivityEvent] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("activity_events")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .eq("action_type", value: actionType.rawValue)
                    .order("created_at", ascending: false)
                    .limit(limit)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("fetchActivitiesByAction", duration: duration)

            logger.info("Fetched \(activities.count) activities by action in \(String(format: "%.2f", duration))s")

            return activities
        } catch {
            logger.error("Failed to fetch activities by action", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchActivitiesByAction",
                "actionType": actionType.rawValue
            ])
            throw ActivityFeedError.fetchFailed(underlying: error)
        }
    }
    
    func fetchActivities(resourceType: ResourceType, limit: Int = 50) async throws -> [ActivityEvent] {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            let activities: [ActivityEvent] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("activity_events")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .eq("resource_type", value: resourceType.rawValue)
                    .order("created_at", ascending: false)
                    .limit(limit)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("fetchActivitiesByResource", duration: duration)

            logger.info("Fetched \(activities.count) activities by resource in \(String(format: "%.2f", duration))s")

            return activities
        } catch {
            logger.error("Failed to fetch activities by resource", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchActivitiesByResource",
                "resourceType": resourceType.rawValue
            ])
            throw ActivityFeedError.fetchFailed(underlying: error)
        }
    }
    
    func fetchActivities(actorId: UUID, limit: Int = 50) async throws -> [ActivityEvent] {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            let activities: [ActivityEvent] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("activity_events")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .eq("actor_id", value: actorId)
                    .order("created_at", ascending: false)
                    .limit(limit)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("fetchActivitiesByActor", duration: duration)

            logger.info("Fetched \(activities.count) activities by actor in \(String(format: "%.2f", duration))s")

            return activities
        } catch {
            logger.error("Failed to fetch activities by actor", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchActivitiesByActor",
                "actorId": actorId.uuidString
            ])
            throw ActivityFeedError.fetchFailed(underlying: error)
        }
    }
    
    func fetchUnreadCount() async throws -> Int {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let cacheKey = "unread_count_\(tenantId.uuidString)"
            let startTime = Date()

            // Check cache first
            if let cached: Int = await RepositoryCache.shared.get(cacheKey, maxAge: 10) {
                logger.info("Cache hit: unread count")
                return cached
            }

            logger.info("Cache miss: fetching unread count from database")

            // Count unread activities
            let result: [ActivityEvent] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("activity_events")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .eq("is_read", value: false)
                    .execute()
                    .value
            }

            let count = result.count
            let duration = Date().timeIntervalSince(startTime)
            
            // Cache for 10 seconds
            await RepositoryCache.shared.set(cacheKey, value: count, ttl: 10)
            
            await PerformanceMonitor.shared.recordOperation("fetchUnreadCount", duration: duration)

            logger.info("Fetched unread count: \(count) in \(String(format: "%.2f", duration))s")

            return count
        } catch {
            logger.error("Failed to fetch unread count", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchUnreadCount"
            ])
            throw ActivityFeedError.fetchFailed(underlying: error)
        }
    }

    // MARK: - Update Operations
    
    func markAsRead(id: UUID) async throws -> ActivityEvent {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            struct UpdatePayload: Encodable {
                let is_read: Bool
            }
            
            let updates = UpdatePayload(is_read: true)

            let updated: ActivityEvent = try await RepositoryNetwork.withRetry {
                try await client
                    .from("activity_events")
                    .update(updates)
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Invalidate cache
            await RepositoryCache.shared.remove("unread_count_\(tenantId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("markAsRead", duration: duration)
            
            logger.info("Marked activity as read in \(String(format: "%.2f", duration))s")

            return updated
        } catch {
            logger.error("Failed to mark activity as read", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "markAsRead",
                "activityId": id.uuidString
            ])
            throw ActivityFeedError.updateFailed(underlying: error)
        }
    }
    
    func markAllAsRead() async throws -> Int {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            struct UpdatePayload: Encodable {
                let is_read: Bool
            }
            
            let updates = UpdatePayload(is_read: true)

            // Update all unread activities
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("activity_events")
                    .update(updates)
                    .eq("couple_id", value: tenantId)
                    .eq("is_read", value: false)
                    .execute()
            }

            // Get count of updated activities
            let count = try await fetchUnreadCount()

            // Invalidate cache
            await RepositoryCache.shared.remove("unread_count_\(tenantId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("markAllAsRead", duration: duration)
            
            logger.info("Marked all activities as read in \(String(format: "%.2f", duration))s")

            return count
        } catch {
            logger.error("Failed to mark all as read", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "markAllAsRead"
            ])
            throw ActivityFeedError.updateFailed(underlying: error)
        }
    }

    // MARK: - Statistics
    
    func fetchActivityStats() async throws -> ActivityStats {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let cacheKey = "activity_stats_\(tenantId.uuidString)"
            let startTime = Date()

            // Check cache first
            if let cached: ActivityStats = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
                logger.info("Cache hit: activity stats")
                return cached
            }

            logger.info("Cache miss: calculating activity stats")

            // Fetch all activities for stats calculation
            let activities = try await fetchActivities(limit: 1000, offset: 0)

            let totalActivities = activities.count
            
            // Count by action type
            var activitiesByAction: [ActionType: Int] = [:]
            for activity in activities {
                activitiesByAction[activity.actionType, default: 0] += 1
            }
            
            // Count by resource type
            var activitiesByResource: [ResourceType: Int] = [:]
            for activity in activities {
                activitiesByResource[activity.resourceType, default: 0] += 1
            }
            
            // Count recent activities (last 24 hours)
            let oneDayAgo = Date().addingTimeInterval(-86400)
            let recentActivityCount = activities.filter { $0.createdAt > oneDayAgo }.count

            let stats = ActivityStats(
                totalActivities: totalActivities,
                activitiesByAction: activitiesByAction,
                activitiesByResource: activitiesByResource,
                recentActivityCount: recentActivityCount
            )

            let duration = Date().timeIntervalSince(startTime)
            
            // Cache for 1 minute
            await RepositoryCache.shared.set(cacheKey, value: stats, ttl: 60)
            
            await PerformanceMonitor.shared.recordOperation("fetchActivityStats", duration: duration)

            logger.info("Calculated activity stats in \(String(format: "%.2f", duration))s")

            return stats
        } catch {
            logger.error("Failed to fetch activity stats", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchActivityStats"
            ])
            throw ActivityFeedError.fetchFailed(underlying: error)
        }
    }
}

// MARK: - Activity Feed Errors

enum ActivityFeedError: Error, LocalizedError {
    case fetchFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case tenantContextMissing
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch activity feed: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update activity: \(error.localizedDescription)"
        case .tenantContextMissing:
            return "No couple selected. Please sign in."
        }
    }
}
