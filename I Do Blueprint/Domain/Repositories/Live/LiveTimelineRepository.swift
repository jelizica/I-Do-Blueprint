//
//  LiveTimelineRepository.swift
//  My Wedding Planning App
//
//  Supabase implementation of timeline repository
//

import Foundation
import Storage
import Supabase

actor LiveTimelineRepository: TimelineRepositoryProtocol {
    private let client: SupabaseClient?
    private let logger = AppLogger.repository
    private let cacheStrategy = TimelineCacheStrategy()

    init(client: SupabaseClient? = SupabaseManager.shared.client) {
        self.client = client
    }

    private func getClient() throws -> SupabaseClient {
        guard let client = client else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return client
    }

    // MARK: - Timeline Items

    func fetchTimelineItems() async throws -> [TimelineItem] {
        let client = try getClient()
        let startTime = Date()

        do {
            let items: [TimelineItem] = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("timeline_items")
                    .select("""
                        *,
                        task:wedding_tasks(*),
                        milestone:wedding_milestones(*),
                        vendor:vendor_information(id, vendor_name),
                        payment:payment_plans(*)
                    """)
                    .order("item_date", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(items.count) timeline items in \(duration)s")
            AnalyticsService.trackNetwork(operation: "fetchTimelineItems", outcome: .success, duration: duration)

            return items
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch timeline items after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchTimelineItems", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchTimelineItem(id: UUID) async throws -> TimelineItem? {
        let client = try getClient()
        let startTime = Date()

        do {
            let items: [TimelineItem] = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("timeline_items")
                    .select("""
                        *,
                        task:wedding_tasks(*),
                        milestone:wedding_milestones(*),
                        vendor:vendor_information(id, vendor_name),
                        payment:payment_plans(*)
                    """)
                    .eq("id", value: id)
                    .limit(1)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
                        AnalyticsService.trackNetwork(operation: "fetchTimelineItem", outcome: .success, duration: duration)

            return items.first
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch timeline item after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchTimelineItem", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func createTimelineItem(_ insertData: TimelineItemInsertData) async throws -> TimelineItem {
        do {
            let client = try getClient()
            let startTime = Date()

            let tenantId = try await TenantContextProvider.shared.requireTenantId()
            let item: TimelineItem = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("timeline_items")
                    .insert(insertData)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created timeline item: \(insertData.title)")
            AnalyticsService.trackNetwork(operation: "createTimelineItem", outcome: .success, duration: duration)
            await cacheStrategy.invalidate(for: .timelineItemCreated(tenantId: tenantId))

            return item
        } catch {
            logger.error("Failed to create timeline item", error: error)
            throw TimelineError.createFailed(underlying: error)
        }
    }

    func updateTimelineItem(_ item: TimelineItem) async throws -> TimelineItem {
        do {
            let client = try getClient()
            let startTime = Date()

            let tenantId = try await TenantContextProvider.shared.requireTenantId()
            let updated: TimelineItem = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("timeline_items")
                    .update(item)
                    .eq("id", value: item.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated timeline item: \(item.title)")
            AnalyticsService.trackNetwork(operation: "updateTimelineItem", outcome: .success, duration: duration)
            await cacheStrategy.invalidate(for: .timelineItemUpdated(tenantId: tenantId))

            return updated
        } catch {
            logger.error("Failed to update milestone", error: error)
            throw TimelineError.updateFailed(underlying: error)
        }
    }

    func deleteTimelineItem(id: UUID) async throws {
        do {
            let client = try getClient()
            let startTime = Date()

            try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("timeline_items")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let tenantId = try await TenantContextProvider.shared.requireTenantId()
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted timeline item: \(id)")
            AnalyticsService.trackNetwork(operation: "deleteTimelineItem", outcome: .success, duration: duration)
            await cacheStrategy.invalidate(for: .timelineItemDeleted(tenantId: tenantId))
        } catch {
            logger.error("Failed to delete timeline item", error: error)
            throw TimelineError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Milestones

    func fetchMilestones() async throws -> [Milestone] {
        let client = try getClient()
        let startTime = Date()

        do {
            let milestones: [Milestone] = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_milestones")
                    .select()
                    .order("target_date", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(milestones.count) milestones in \(duration)s")
            AnalyticsService.trackNetwork(operation: "fetchMilestones", outcome: .success, duration: duration)

            return milestones
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch milestones after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchMilestones", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func fetchMilestone(id: UUID) async throws -> Milestone? {
        let client = try getClient()
        let startTime = Date()

        do {
            let milestones: [Milestone] = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_milestones")
                    .select()
                    .eq("id", value: id)
                    .limit(1)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
                        AnalyticsService.trackNetwork(operation: "fetchMilestone", outcome: .success, duration: duration)

            return milestones.first
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch milestone after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchMilestone", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func createMilestone(_ insertData: MilestoneInsertData) async throws -> Milestone {
        do {
            let client = try getClient()
            let startTime = Date()

            let tenantId = try await TenantContextProvider.shared.requireTenantId()
            let milestone: Milestone = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_milestones")
                    .insert(insertData)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created milestone: \(insertData.milestoneName)")
            AnalyticsService.trackNetwork(operation: "createMilestone", outcome: .success, duration: duration)
            await cacheStrategy.invalidate(for: .milestoneCreated(tenantId: tenantId))

            return milestone
        } catch {
            logger.error("Failed to create milestone", error: error)
            throw TimelineError.createFailed(underlying: error)
        }
    }

    func updateMilestone(_ milestone: Milestone) async throws -> Milestone {
        do {
            let client = try getClient()
            let startTime = Date()

            let tenantId = try await TenantContextProvider.shared.requireTenantId()
            let updated: Milestone = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_milestones")
                    .update(milestone)
                    .eq("id", value: milestone.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated milestone: \(milestone.milestoneName)")
            AnalyticsService.trackNetwork(operation: "updateMilestone", outcome: .success, duration: duration)
            await cacheStrategy.invalidate(for: .milestoneUpdated(tenantId: tenantId))

            return updated
        } catch {
            logger.error("Failed to update timeline item", error: error)
            throw TimelineError.updateFailed(underlying: error)
        }
    }

    func deleteMilestone(id: UUID) async throws {
        do {
            let client = try getClient()
            let startTime = Date()

            try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_milestones")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let tenantId = try await TenantContextProvider.shared.requireTenantId()
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted milestone: \(id)")
            AnalyticsService.trackNetwork(operation: "deleteMilestone", outcome: .success, duration: duration)
            await cacheStrategy.invalidate(for: .milestoneDeleted(tenantId: tenantId))
        } catch {
            logger.error("Failed to delete milestone", error: error)
            throw TimelineError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Wedding Day Events

    func fetchWeddingDayEvents() async throws -> [WeddingDayEvent] {
        let client = try getClient()
        let startTime = Date()
        let tenantId = try await TenantContextProvider.shared.requireTenantId()

        // Check cache first
        let cacheKey = CacheConfiguration.KeyPrefix.weddingDayEvents.key(tenantId: tenantId)
        if let cached: [WeddingDayEvent] = await RepositoryCache.shared.get(cacheKey, maxAge: CacheConfiguration.frequentAccessTTL) {
            logger.debug("Cache hit: wedding day events (\(cached.count) items)")
            return cached
        }

        do {
            let events: [WeddingDayEvent] = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_events")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .order("event_date", ascending: true)
                    .order("start_time", ascending: true)
                    .execute()
                    .value
            }

            // Cache results
            await RepositoryCache.shared.set(cacheKey, value: events, ttl: CacheConfiguration.frequentAccessTTL)

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(events.count) wedding day events in \(duration)s")
            AnalyticsService.trackNetwork(operation: "fetchWeddingDayEvents", outcome: .success, duration: duration)

            return events
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch wedding day events after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchWeddingDayEvents", outcome: .failure(code: nil), duration: duration)
            throw TimelineError.fetchFailed(underlying: error)
        }
    }

    func fetchWeddingDayEvents(forDate date: Date) async throws -> [WeddingDayEvent] {
        let client = try getClient()
        let startTime = Date()
        let tenantId = try await TenantContextProvider.shared.requireTenantId()

        // Format date for PostgreSQL DATE comparison
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let dateString = dateFormatter.string(from: date)

        do {
            let events: [WeddingDayEvent] = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_events")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .eq("event_date", value: dateString)
                    .order("start_time", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(events.count) wedding day events for \(dateString) in \(duration)s")
            AnalyticsService.trackNetwork(operation: "fetchWeddingDayEventsForDate", outcome: .success, duration: duration)

            return events
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch wedding day events for date after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchWeddingDayEventsForDate", outcome: .failure(code: nil), duration: duration)
            throw TimelineError.fetchFailed(underlying: error)
        }
    }

    func fetchWeddingDayEvent(id: UUID) async throws -> WeddingDayEvent? {
        let client = try getClient()
        let startTime = Date()

        do {
            let events: [WeddingDayEvent] = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_events")
                    .select()
                    .eq("id", value: id)
                    .limit(1)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            AnalyticsService.trackNetwork(operation: "fetchWeddingDayEvent", outcome: .success, duration: duration)

            return events.first
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch wedding day event after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchWeddingDayEvent", outcome: .failure(code: nil), duration: duration)
            throw TimelineError.fetchFailed(underlying: error)
        }
    }

    func createWeddingDayEvent(_ insertData: WeddingDayEventInsertData) async throws -> WeddingDayEvent {
        do {
            let client = try getClient()
            let startTime = Date()

            let tenantId = try await TenantContextProvider.shared.requireTenantId()
            let event: WeddingDayEvent = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_events")
                    .insert(insertData)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Created wedding day event: \(insertData.eventName)")
            AnalyticsService.trackNetwork(operation: "createWeddingDayEvent", outcome: .success, duration: duration)
            await cacheStrategy.invalidate(for: .weddingDayEventCreated(tenantId: tenantId))

            return event
        } catch {
            logger.error("Failed to create wedding day event", error: error)
            throw TimelineError.createFailed(underlying: error)
        }
    }

    func updateWeddingDayEvent(_ event: WeddingDayEvent) async throws -> WeddingDayEvent {
        do {
            let client = try getClient()
            let startTime = Date()

            let tenantId = try await TenantContextProvider.shared.requireTenantId()
            let updated: WeddingDayEvent = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_events")
                    .update(event)
                    .eq("id", value: event.id)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Updated wedding day event: \(event.eventName)")
            AnalyticsService.trackNetwork(operation: "updateWeddingDayEvent", outcome: .success, duration: duration)
            await cacheStrategy.invalidate(for: .weddingDayEventUpdated(tenantId: tenantId))

            return updated
        } catch {
            logger.error("Failed to update wedding day event", error: error)
            throw TimelineError.updateFailed(underlying: error)
        }
    }

    func deleteWeddingDayEvent(id: UUID) async throws {
        do {
            let client = try getClient()
            let startTime = Date()

            try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_events")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let tenantId = try await TenantContextProvider.shared.requireTenantId()
            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted wedding day event: \(id)")
            AnalyticsService.trackNetwork(operation: "deleteWeddingDayEvent", outcome: .success, duration: duration)
            await cacheStrategy.invalidate(for: .weddingDayEventDeleted(tenantId: tenantId))
        } catch {
            logger.error("Failed to delete wedding day event", error: error)
            throw TimelineError.deleteFailed(underlying: error)
        }
    }

    // MARK: - Event Photos

    func uploadEventPhoto(imageData: Data, eventId: UUID, coupleId: UUID) async throws -> String {
        let client = try getClient()
        let startTime = Date()

        // Create a unique filename with couple_id/event_id path for RLS
        let fileName = "\(coupleId.uuidString)/\(eventId.uuidString)/\(UUID().uuidString).png"

        do {
            try await RepositoryNetwork.withRetry {
                try await client.storage
                    .from("event-photos")
                    .upload(
                        path: fileName,
                        file: imageData,
                        options: FileOptions(
                            cacheControl: "3600",
                            contentType: "image/png",
                            upsert: false
                        )
                    )
            }

            // Since the bucket is private, create a signed URL (valid for 1 year)
            let signedUrl = try await client.storage
                .from("event-photos")
                .createSignedURL(path: fileName, expiresIn: 31_536_000) // 1 year in seconds

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Uploaded event photo: \(fileName) in \(duration)s")
            AnalyticsService.trackNetwork(operation: "uploadEventPhoto", outcome: .success, duration: duration)

            return signedUrl.absoluteString
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to upload event photo after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "uploadEventPhoto", outcome: .failure(code: nil), duration: duration)
            throw TimelineError.photoUploadFailed(underlying: error)
        }
    }

    func deleteEventPhoto(photoUrl: String) async throws {
        let client = try getClient()
        let startTime = Date()

        // Extract the file path from the URL
        // URL format: https://xxx.supabase.co/storage/v1/object/sign/event-photos/couple_id/event_id/filename.png?token=...
        guard let urlComponents = URLComponents(string: photoUrl),
              let path = urlComponents.path.components(separatedBy: "event-photos/").last else {
            logger.error("Failed to extract file path from photo URL: \(photoUrl)")
            throw TimelineError.invalidPhotoUrl
        }

        // Remove query params from path
        let cleanPath = path.components(separatedBy: "?").first ?? path

        do {
            try await RepositoryNetwork.withRetry {
                try await client.storage
                    .from("event-photos")
                    .remove(paths: [cleanPath])
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted event photo: \(cleanPath) in \(duration)s")
            AnalyticsService.trackNetwork(operation: "deleteEventPhoto", outcome: .success, duration: duration)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to delete event photo after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "deleteEventPhoto", outcome: .failure(code: nil), duration: duration)
            throw TimelineError.photoDeleteFailed(underlying: error)
        }
    }

    // MARK: - Sub-Event Filtering

    func fetchParentWeddingDayEvents() async throws -> [WeddingDayEvent] {
        let client = try getClient()
        let startTime = Date()
        let tenantId = try await TenantContextProvider.shared.requireTenantId()

        // Check cache first
        let cacheKey = CacheConfiguration.KeyPrefix.weddingDayEvents.key(tenantId: tenantId) + "_parents"
        if let cached: [WeddingDayEvent] = await RepositoryCache.shared.get(cacheKey, maxAge: CacheConfiguration.frequentAccessTTL) {
            logger.debug("Cache hit: parent wedding day events (\(cached.count) items)")
            return cached
        }

        do {
            let events: [WeddingDayEvent] = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_events")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .filter("parent_event_id", operator: "is", value: "null")
                    .order("event_date", ascending: true)
                    .order("start_time", ascending: true)
                    .execute()
                    .value
            }

            // Cache results
            await RepositoryCache.shared.set(cacheKey, value: events, ttl: CacheConfiguration.frequentAccessTTL)

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(events.count) parent wedding day events in \(duration)s")
            AnalyticsService.trackNetwork(operation: "fetchParentWeddingDayEvents", outcome: .success, duration: duration)

            return events
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch parent wedding day events after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchParentWeddingDayEvents", outcome: .failure(code: nil), duration: duration)
            throw TimelineError.fetchFailed(underlying: error)
        }
    }

    func fetchSubEvents(parentEventId: UUID) async throws -> [WeddingDayEvent] {
        let client = try getClient()
        let startTime = Date()
        let tenantId = try await TenantContextProvider.shared.requireTenantId()

        do {
            let events: [WeddingDayEvent] = try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_events")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .eq("parent_event_id", value: parentEventId)
                    .order("start_time", ascending: true)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Fetched \(events.count) sub-events for parent \(parentEventId) in \(duration)s")
            AnalyticsService.trackNetwork(operation: "fetchSubEvents", outcome: .success, duration: duration)

            return events
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to fetch sub-events after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "fetchSubEvents", outcome: .failure(code: nil), duration: duration)
            throw TimelineError.fetchFailed(underlying: error)
        }
    }
}
