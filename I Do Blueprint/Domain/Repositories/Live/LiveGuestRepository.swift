//
//  LiveGuestRepository.swift
//  My Wedding Planning App
//
//  Production implementation of GuestRepositoryProtocol with caching
//

import Foundation
import Supabase

/// Production implementation of GuestRepositoryProtocol
actor LiveGuestRepository: GuestRepositoryProtocol {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.repository

    // SessionManager for tenant scoping
    private let sessionManager: SessionManager

    init(supabase: SupabaseClient? = nil, sessionManager: SessionManager = .shared) {
        self.supabase = supabase
        self.sessionManager = sessionManager
    }

    // Convenience initializer using SupabaseManager
    init() {
        supabase = SupabaseManager.shared.client
        sessionManager = .shared
    }
    
    private func getClient() throws -> SupabaseClient {
        guard let supabase = supabase else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return supabase
    }

    // Helper to get tenant ID, throws if not set
    private func getTenantId() async throws -> UUID {
        try await MainActor.run {
            try sessionManager.requireTenantId()
        }
    }

    func fetchGuests() async throws -> [Guest] {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let cacheKey = "guests_\(tenantId.uuidString)"
        let startTime = Date()

        // ✅ Check cache first
        if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: guests (\(cached.count) items)")
            return cached
        }

        logger.info("Cache miss: fetching guests from database")

        // Fetch from Supabase with retry and timeout - scoped by tenant
        do {
            let guests: [Guest] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("guest_list")
                    .select()
                    .eq("couple_id", value: tenantId.uuidString)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Cache the results
            await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
            
            // ✅ Record performance metrics
            await PerformanceMonitor.shared.recordOperation("fetchGuests", duration: duration)

            logger.info("Fetched \(guests.count) guests in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchGuests", outcome: .success, duration: duration)

            return guests
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record failed operation
            await PerformanceMonitor.shared.recordOperation("fetchGuests", duration: duration)
            
            logger.error("Failed to fetch guests after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchGuests", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
    
    // DEFERRED (2025-01): Guest pagination blocked by Swift Sendable conformance issues
    //
    // The PaginatedResult<T> type requires Sendable conformance, but Guest model
    // contains non-Sendable types (NSImage, etc.) that cannot easily conform.
    //
    // Workaround: Fetch all guests and implement client-side pagination if needed.
    // Performance impact is minimal for typical wedding guest lists (< 500 guests).
    //
    // Future: When Swift 6 stabilizes Sendable requirements, revisit this implementation.
    // Tracking: Consider creating separate Linear issue for pagination implementation
    //
    // Proposed signature (for future reference):
    // func fetchGuests(page: Int = 0, pageSize: Int = 50) async throws -> PaginatedResult<Guest>

    func fetchGuestStats() async throws -> GuestStats {
        let tenantId = try await getTenantId()
        let cacheKey = "guest_stats_\(tenantId.uuidString)"
        let startTime = Date()

        // ✅ Check cache first
        if let cached: GuestStats = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: guest stats")
            return cached
        }

        logger.info("Cache miss: calculating guest stats")

        // Fetch guests to calculate stats (already tenant-scoped)
        let guests = try await fetchGuests()

        let totalGuests = guests.count
        let attendingGuests = guests.filter { $0.rsvpStatus == .attending || $0.rsvpStatus == .confirmed }.count
        let pendingGuests = guests.filter { $0.rsvpStatus == .pending || $0.rsvpStatus == .invited }.count
        let declinedGuests = guests.filter { $0.rsvpStatus == .declined }.count

        // Calculate RSVP response rate as percentage
        let responseRate: Double
        if totalGuests > 0 {
            let responded = totalGuests - pendingGuests
            responseRate = (Double(responded) / Double(totalGuests)) * 100
        } else {
            responseRate = 0
        }

        let stats = GuestStats(
            totalGuests: totalGuests,
            attendingGuests: attendingGuests,
            pendingGuests: pendingGuests,
            declinedGuests: declinedGuests,
            responseRate: responseRate)

        let duration = Date().timeIntervalSince(startTime)
        
        // ✅ Cache the result
        await RepositoryCache.shared.set(cacheKey, value: stats, ttl: 60)
        
        // ✅ Record performance
        await PerformanceMonitor.shared.recordOperation("fetchGuestStats", duration: duration)

        logger.info("Calculated guest stats in \(String(format: "%.2f", duration))s")

        return stats
    }

    func createGuest(_ guest: Guest) async throws -> Guest {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let startTime = Date()

        do {
            let created: Guest = try await RepositoryNetwork.withRetry {
                try await client
                    .from("guest_list")
                    .insert(guest)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // ✅ Invalidate tenant-scoped cache
            await RepositoryCache.shared.remove("guests_\(tenantId.uuidString)")
            await RepositoryCache.shared.remove("guest_stats_\(tenantId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("createGuest", duration: duration)
            
            logger.info("Created guest in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "createGuest", outcome: .success, duration: duration)

            return created
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record failed operation
            await PerformanceMonitor.shared.recordOperation("createGuest", duration: duration)
            
            logger.error("Failed to create guest after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "createGuest", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func updateGuest(_ guest: Guest) async throws -> Guest {
        let client = try getClient()
        let tenantId = try await getTenantId()
        var updated = guest
        updated.updatedAt = Date()
        let startTime = Date()

        do {
            let result: Guest = try await RepositoryNetwork.withRetry {
                try await client
                    .from("guest_list")
                    .update(updated)
                    .eq("id", value: guest.id)
                    .eq("couple_id", value: tenantId.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // ✅ Invalidate tenant-scoped cache
            await RepositoryCache.shared.remove("guests_\(tenantId.uuidString)")
            await RepositoryCache.shared.remove("guest_stats_\(tenantId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("updateGuest", duration: duration)
            
            logger.info("Updated guest in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "updateGuest", outcome: .success, duration: duration)

            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record failed operation
            await PerformanceMonitor.shared.recordOperation("updateGuest", duration: duration)
            
            logger.error("Failed to update guest after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "updateGuest", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func deleteGuest(id: UUID) async throws {
        let client = try getClient()
        let tenantId = try await getTenantId()
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("guest_list")
                    .delete()
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId.uuidString)
                    .execute()
            }

            // ✅ Invalidate tenant-scoped cache
            await RepositoryCache.shared.remove("guests_\(tenantId.uuidString)")
            await RepositoryCache.shared.remove("guest_stats_\(tenantId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("deleteGuest", duration: duration)
            
            logger.info("Deleted guest in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "deleteGuest", outcome: .success, duration: duration)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // ✅ Record failed operation
            await PerformanceMonitor.shared.recordOperation("deleteGuest", duration: duration)
            
            logger.error("Failed to delete guest after \(String(format: "%.2f", duration))s", error: error)
            AnalyticsService.trackNetwork(operation: "deleteGuest", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func searchGuests(query: String) async throws -> [Guest] {
        let guests = try await fetchGuests()

        // Return all guests if search query is empty
        guard !query.isEmpty else {
            return guests
        }

        // Search across name, email, and phone fields
        return guests.filter { guest in
            guest.fullName.localizedCaseInsensitiveContains(query) ||
                guest.email?.localizedCaseInsensitiveContains(query) == true ||
                guest.phone?.contains(query) == true
        }
    }
}
