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
    private let supabase: SupabaseClient
    private let cache: RepositoryCache
    private let logger = AppLogger.repository

    // SessionManager for tenant scoping
    private let sessionManager: SessionManager

    init(supabase: SupabaseClient, sessionManager: SessionManager = .shared) {
        self.supabase = supabase
        self.sessionManager = sessionManager
        cache = RepositoryCache()
    }

    // Convenience initializer using SupabaseManager
    init() {
        supabase = SupabaseManager.shared.client
        sessionManager = .shared
        cache = RepositoryCache()
    }

    // Helper to get tenant ID, throws if not set
    private func getTenantId() async throws -> UUID {
        try await MainActor.run {
            try sessionManager.requireTenantId()
        }
    }

    func fetchGuests() async throws -> [Guest] {
        let tenantId = try await getTenantId()
        let cacheKey = "guests_\(tenantId.uuidString)"
        let startTime = Date()

        // Check cache first
        if let cached: [Guest] = await cache.get(cacheKey, maxAge: 60) {
            logger.debug("Cache hit for guests")
            return cached
        }

        // Fetch from Supabase with retry and timeout - scoped by tenant
        do {
            let guests: [Guest] = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("guest_list")
                    .select()
                    .eq("couple_id", value: tenantId.uuidString)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }

            // Cache the result
            await cache.set(cacheKey, value: guests)

            // Emit metrics
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(guests.count) guests in \(duration)s")
            AnalyticsService.trackNetwork(operation: "fetchGuests", outcome: .success, duration: duration)

            return guests
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch guests after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchGuests", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchGuestStats() async throws -> GuestStats {
        let tenantId = try await getTenantId()
        let cacheKey = "guest_stats_\(tenantId.uuidString)"

        // Check cache first
        if let cached: GuestStats = await cache.get(cacheKey, maxAge: 60) {
            return cached
        }

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

        // Cache the result
        await cache.set(cacheKey, value: stats)

        return stats
    }

    func createGuest(_ guest: Guest) async throws -> Guest {
        let tenantId = try await getTenantId()
        let startTime = Date()

        do {
            let created: Guest = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("guest_list")
                    .insert(guest)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Invalidate tenant-scoped cache
            await cache.remove("guests_\(tenantId.uuidString)")
            await cache.remove("guest_stats_\(tenantId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created guest in \(duration)s")
            AnalyticsService.trackNetwork(operation: "createGuest", outcome: .success, duration: duration)

            return created
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to create guest after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "createGuest", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func updateGuest(_ guest: Guest) async throws -> Guest {
        let tenantId = try await getTenantId()
        var updated = guest
        updated.updatedAt = Date()
        let startTime = Date()

        do {
            let result: Guest = try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("guest_list")
                    .update(updated)
                    .eq("id", value: guest.id)
                    .eq("couple_id", value: tenantId.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Invalidate tenant-scoped cache
            await cache.remove("guests_\(tenantId.uuidString)")
            await cache.remove("guest_stats_\(tenantId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated guest in \(duration)s")
            AnalyticsService.trackNetwork(operation: "updateGuest", outcome: .success, duration: duration)

            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to update guest after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "updateGuest", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func deleteGuest(id: UUID) async throws {
        let tenantId = try await getTenantId()
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry {
                try await self.supabase
                    .from("guest_list")
                    .delete()
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId.uuidString)
                    .execute()
            }

            // Invalidate tenant-scoped cache
            await cache.remove("guests_\(tenantId.uuidString)")
            await cache.remove("guest_stats_\(tenantId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted guest in \(duration)s")
            AnalyticsService.trackNetwork(operation: "deleteGuest", outcome: .success, duration: duration)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to delete guest after \(duration)s", error: error)
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
