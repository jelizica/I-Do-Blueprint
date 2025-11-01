//
//  LivePresenceRepository.swift
//  I Do Blueprint
//
//  Production implementation of PresenceRepositoryProtocol with caching
//

import Foundation
import Supabase

/// Production implementation of PresenceRepositoryProtocol
actor LivePresenceRepository: PresenceRepositoryProtocol {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.repository
    private let sessionManager: SessionManager
    private var currentSessionId: String?

    init(supabase: SupabaseClient? = nil, sessionManager: SessionManager = .shared) {
        self.supabase = supabase
        self.sessionManager = sessionManager
        self.currentSessionId = UUID().uuidString
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
    
    private func getUserId() async throws -> UUID {
        try await MainActor.run {
            try AuthContext.shared.requireUserId()
        }
    }
    
    private func getSessionId() -> String {
        if let sessionId = currentSessionId {
            return sessionId
        }
        let newSessionId = UUID().uuidString
        currentSessionId = newSessionId
        return newSessionId
    }

    // MARK: - Fetch Operations
    
    func fetchActivePresence() async throws -> [Presence] {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let cacheKey = "active_presence_\(tenantId.uuidString)"
            let startTime = Date()

            // Check cache first (short TTL for presence)
            if let cached: [Presence] = await RepositoryCache.shared.get(cacheKey, maxAge: 10) {
                logger.info("Cache hit: active presence (\(cached.count) items)")
                return cached
            }

            logger.info("Cache miss: fetching active presence from database")

            // Fetch only non-stale presence (heartbeat within last 5 minutes)
            let fiveMinutesAgo = Date().addingTimeInterval(-300)
            
            let presence: [Presence] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("presence")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .eq("status", value: "online")
                    .gte("last_heartbeat", value: fiveMinutesAgo)
                    .order("last_heartbeat", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            
            // Cache for 10 seconds (presence changes frequently)
            await RepositoryCache.shared.set(cacheKey, value: presence, ttl: 10)
            
            await PerformanceMonitor.shared.recordOperation("fetchActivePresence", duration: duration)

            logger.info("Fetched \(presence.count) active presence records in \(String(format: "%.2f", duration))s")

            return presence
        } catch {
            logger.error("Failed to fetch active presence", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchActivePresence"
            ])
            throw PresenceError.fetchFailed(underlying: error)
        }
    }
    
    func fetchPresence(userId: UUID) async throws -> Presence? {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            let presence: Presence? = try await RepositoryNetwork.withRetry {
                try? await client
                    .from("presence")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .eq("user_id", value: userId)
                    .order("last_heartbeat", ascending: false)
                    .limit(1)
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("fetchPresence", duration: duration)

            logger.info("Fetched presence for user in \(String(format: "%.2f", duration))s")

            return presence
        } catch {
            logger.error("Failed to fetch presence", error: error)
            return nil
        }
    }

    // MARK: - Presence Management
    
    func trackPresence(
        status: PresenceStatus,
        currentView: String?,
        currentResourceType: String?,
        currentResourceId: UUID?
    ) async throws -> Presence {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let userId = try await getUserId()
            let sessionId = getSessionId()
            let startTime = Date()

            let presence = Presence(
                id: UUID(),
                createdAt: Date(),
                updatedAt: Date(),
                coupleId: tenantId,
                userId: userId,
                sessionId: sessionId,
                status: status,
                currentView: currentView,
                currentResourceType: currentResourceType,
                currentResourceId: currentResourceId,
                isEditing: false,
                editingResourceType: nil,
                editingResourceId: nil,
                lastHeartbeat: Date(),
                metadata: [:]
            )

            // Upsert presence (insert or update if exists)
            let updated: Presence = try await RepositoryNetwork.withRetry {
                try await client
                    .from("presence")
                    .upsert(presence)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Invalidate cache
            await RepositoryCache.shared.remove("active_presence_\(tenantId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("trackPresence", duration: duration)
            
            logger.info("Tracked presence in \(String(format: "%.2f", duration))s")

            return updated
        } catch {
            logger.error("Failed to track presence", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "trackPresence",
                "status": status.rawValue
            ])
            throw PresenceError.updateFailed(underlying: error)
        }
    }
    
    func updateEditingState(
        isEditing: Bool,
        resourceType: String?,
        resourceId: UUID?
    ) async throws -> Presence {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let userId = try await getUserId()
            let sessionId = getSessionId()
            let startTime = Date()

            struct UpdatePayload: Encodable {
                let is_editing: Bool
                let editing_resource_type: String?
                let editing_resource_id: UUID?
                let last_heartbeat: Date
                let updated_at: Date
            }
            
            let updates = UpdatePayload(
                is_editing: isEditing,
                editing_resource_type: resourceType,
                editing_resource_id: resourceId,
                last_heartbeat: Date(),
                updated_at: Date()
            )

            let updated: Presence = try await RepositoryNetwork.withRetry {
                try await client
                    .from("presence")
                    .update(updates)
                    .eq("couple_id", value: tenantId)
                    .eq("user_id", value: userId)
                    .eq("session_id", value: sessionId)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Invalidate cache
            await RepositoryCache.shared.remove("active_presence_\(tenantId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("updateEditingState", duration: duration)
            
            logger.info("Updated editing state in \(String(format: "%.2f", duration))s")

            return updated
        } catch {
            logger.error("Failed to update editing state", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "updateEditingState",
                "isEditing": String(isEditing)
            ])
            throw PresenceError.updateFailed(underlying: error)
        }
    }
    
    func sendHeartbeat() async throws -> Presence {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let userId = try await getUserId()
            let sessionId = getSessionId()
            let startTime = Date()

            struct UpdatePayload: Encodable {
                let last_heartbeat: Date
                let updated_at: Date
            }
            
            let updates = UpdatePayload(
                last_heartbeat: Date(),
                updated_at: Date()
            )

            let updated: Presence = try await RepositoryNetwork.withRetry {
                try await client
                    .from("presence")
                    .update(updates)
                    .eq("couple_id", value: tenantId)
                    .eq("user_id", value: userId)
                    .eq("session_id", value: sessionId)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Don't invalidate cache for heartbeats (too frequent)

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("sendHeartbeat", duration: duration)
            
            logger.debug("Sent heartbeat in \(String(format: "%.2f", duration))s")

            return updated
        } catch {
            logger.error("Failed to send heartbeat", error: error)
            // Don't capture heartbeat failures in Sentry (too noisy)
            throw PresenceError.updateFailed(underlying: error)
        }
    }
    
    func stopTracking() async throws {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let userId = try await getUserId()
            let sessionId = getSessionId()
            let startTime = Date()

            // Set status to offline
            struct UpdatePayload: Encodable {
                let status: String
                let is_editing: Bool
                let editing_resource_type: String?
                let editing_resource_id: UUID?
                let updated_at: Date
            }
            
            let updates = UpdatePayload(
                status: "offline",
                is_editing: false,
                editing_resource_type: nil,
                editing_resource_id: nil,
                updated_at: Date()
            )

            try await RepositoryNetwork.withRetry {
                try await client
                    .from("presence")
                    .update(updates)
                    .eq("couple_id", value: tenantId)
                    .eq("user_id", value: userId)
                    .eq("session_id", value: sessionId)
                    .execute()
            }

            // Invalidate cache
            await RepositoryCache.shared.remove("active_presence_\(tenantId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("stopTracking", duration: duration)
            
            logger.info("Stopped tracking presence in \(String(format: "%.2f", duration))s")
        } catch {
            logger.error("Failed to stop tracking", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "stopTracking"
            ])
            throw PresenceError.updateFailed(underlying: error)
        }
    }

    // MARK: - Cleanup
    
    func cleanupStalePresence() async throws -> Int {
        do {
            let client = try getClient()
            let startTime = Date()

            // Call database function
            let result: [[String: Int]] = try await RepositoryNetwork.withRetry {
                try await client
                    .rpc("manual_cleanup_collaboration")
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("cleanupStalePresence", duration: duration)

            let presenceCleaned = result.first?["presence_cleaned"] ?? 0
            logger.info("Cleaned up \(presenceCleaned) stale presence records in \(String(format: "%.2f", duration))s")

            return presenceCleaned
        } catch {
            logger.error("Failed to cleanup stale presence", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "cleanupStalePresence"
            ])
            throw PresenceError.cleanupFailed(underlying: error)
        }
    }
}

// MARK: - Presence Errors

enum PresenceError: Error, LocalizedError {
    case fetchFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case cleanupFailed(underlying: Error)
    case tenantContextMissing
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch presence data: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update presence: \(error.localizedDescription)"
        case .cleanupFailed(let error):
            return "Failed to cleanup stale presence: \(error.localizedDescription)"
        case .tenantContextMissing:
            return "No couple selected. Please sign in."
        }
    }
}
