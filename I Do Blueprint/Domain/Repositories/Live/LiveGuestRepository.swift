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
    private let cacheStrategy = GuestCacheStrategy()

    // SessionManager for tenant scoping
    private let sessionManager: SessionManager

    // In-flight request de-duplication
    private var inFlightGuests: [UUID: Task<[Guest], Error>] = [:]

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
        try await TenantContextProvider.shared.requireTenantId()
    }

    func fetchGuests() async throws -> [Guest] {
        let tenantId = try await getTenantId()
        let cacheKey = "guests_\(tenantId.uuidString)"

        // ✅ Check cache first
        if let cached: [Guest] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
            logger.info("Cache hit: guests (\(cached.count) items)")
            return cached
        }

        // Coalesce in-flight requests per-tenant
        if let task = inFlightGuests[tenantId] {
            return try await task.value
        }

        let task = Task<[Guest], Error> { [weak self] in
            guard let self = self else { throw CancellationError() }
            let client = try await self.getClient()
            let startTime = Date()
            self.logger.info("Cache miss: fetching guests from database")
            let guests: [Guest] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("guest_list")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }
            let duration = Date().timeIntervalSince(startTime)
            await RepositoryCache.shared.set(cacheKey, value: guests, ttl: 60)
            await PerformanceMonitor.shared.recordOperation("fetchGuests", duration: duration)
            self.logger.info("Fetched \(guests.count) guests in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchGuests", outcome: .success, duration: duration)
            return guests
        }

        inFlightGuests[tenantId] = task
        do {
            let result = try await task.value
            inFlightGuests[tenantId] = nil
            return result
        } catch {
            inFlightGuests[tenantId] = nil
            logger.error("Failed to fetch guests", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchGuests",
                "repository": "LiveGuestRepository"
            ])
            throw GuestError.fetchFailed(underlying: error)
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
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            let created: Guest = try await RepositoryNetwork.withRetry {
                try await client
                    .from("guest_list")
                    .insert(guest)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // ✅ Invalidate tenant-scoped caches via strategy
            await cacheStrategy.invalidate(for: .guestCreated(tenantId: tenantId))

            let duration = Date().timeIntervalSince(startTime)

            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("createGuest", duration: duration)

            logger.info("Created guest in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "createGuest", outcome: .success, duration: duration)

            return created
        } catch {
            logger.error("Failed to create guest", error: error)
await SentryService.shared.captureError(error, context: [
                "operation": "createGuest",
                "repository": "LiveGuestRepository",
                "guestName": guest.fullName
            ])
            throw GuestError.createFailed(underlying: error)
        }
    }

    func updateGuest(_ guest: Guest) async throws -> Guest {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            var updated = guest
            updated.updatedAt = Date()
            let startTime = Date()

            let result: Guest = try await RepositoryNetwork.withRetry {
                try await client
                    .from("guest_list")
                    .update(updated)
                    .eq("id", value: guest.id)
                    .eq("couple_id", value: tenantId)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // ✅ Invalidate tenant-scoped caches via strategy
            await cacheStrategy.invalidate(for: .guestUpdated(tenantId: tenantId))

            let duration = Date().timeIntervalSince(startTime)

            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("updateGuest", duration: duration)

            logger.info("Updated guest in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "updateGuest", outcome: .success, duration: duration)

            return result
        } catch {
            logger.error("Failed to update guest", error: error)
await SentryService.shared.captureError(error, context: [
                "operation": "updateGuest",
                "repository": "LiveGuestRepository",
                "guestId": guest.id.uuidString
            ])
            throw GuestError.updateFailed(underlying: error)
        }
    }

    func deleteGuest(id: UUID) async throws {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            try await RepositoryNetwork.withRetry {
                try await client
                    .from("guest_list")
                    .delete()
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId)
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
            logger.error("Failed to delete guest", error: error)
await SentryService.shared.captureError(error, context: [
                "operation": "deleteGuest",
                "repository": "LiveGuestRepository",
                "guestId": id.uuidString
            ])
            throw GuestError.deleteFailed(underlying: error)
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

    func importGuests(_ guests: [Guest]) async throws -> [Guest] {
        guard !guests.isEmpty else {
            logger.info("No guests to import")
            return []
        }

        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            logger.info("Importing \(guests.count) guests...")

            // Ensure all guests have the correct couple_id
            var guestsToImport = guests
            for index in guestsToImport.indices {
                var guest = guestsToImport[index]
                guest = Guest(
                    id: guest.id,
                    createdAt: guest.createdAt,
                    updatedAt: guest.updatedAt,
                    firstName: guest.firstName,
                    lastName: guest.lastName,
                    email: guest.email,
                    phone: guest.phone,
                    guestGroupId: guest.guestGroupId,
                    relationshipToCouple: guest.relationshipToCouple,
                    invitedBy: guest.invitedBy,
                    rsvpStatus: guest.rsvpStatus,
                    rsvpDate: guest.rsvpDate,
                    plusOneAllowed: guest.plusOneAllowed,
                    plusOneName: guest.plusOneName,
                    plusOneAttending: guest.plusOneAttending,
                    attendingCeremony: guest.attendingCeremony,
                    attendingReception: guest.attendingReception,
                    attendingOtherEvents: guest.attendingOtherEvents,
                    dietaryRestrictions: guest.dietaryRestrictions,
                    accessibilityNeeds: guest.accessibilityNeeds,
                    tableAssignment: guest.tableAssignment,
                    seatNumber: guest.seatNumber,
                    preferredContactMethod: guest.preferredContactMethod,
                    addressLine1: guest.addressLine1,
                    addressLine2: guest.addressLine2,
                    city: guest.city,
                    state: guest.state,
                    zipCode: guest.zipCode,
                    country: guest.country,
                    invitationNumber: guest.invitationNumber,
                    isWeddingParty: guest.isWeddingParty,
                    weddingPartyRole: guest.weddingPartyRole,
                    preparationNotes: guest.preparationNotes,
                    coupleId: tenantId, // ✅ Ensure correct tenant ID
                    mealOption: guest.mealOption,
                    giftReceived: guest.giftReceived,
                    notes: guest.notes,
                    hairDone: guest.hairDone,
                    makeupDone: guest.makeupDone
                )
                guestsToImport[index] = guest
            }

            // Batch insert with retry
            let imported: [Guest] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("guest_list")
                    .insert(guestsToImport)
                    .select()
                    .execute()
                    .value
            }

            // ✅ Invalidate tenant-scoped cache
            await RepositoryCache.shared.remove("guests_\(tenantId.uuidString)")
            await RepositoryCache.shared.remove("guest_stats_\(tenantId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)

            // ✅ Record performance
            await PerformanceMonitor.shared.recordOperation("importGuests", duration: duration)

            logger.info("Imported \(imported.count) guests in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "importGuests", outcome: .success, duration: duration)

            return imported
        } catch {
            logger.error("Failed to import guests", error: error)
await SentryService.shared.captureError(error, context: [
                "operation": "importGuests",
                "repository": "LiveGuestRepository",
                "count": guests.count
            ])
            throw GuestError.createFailed(underlying: error)
        }
    }
}
