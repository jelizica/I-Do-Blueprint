//
//  LiveTimelineRepository.swift
//  My Wedding Planning App
//
//  Supabase implementation of timeline repository
//

import Foundation
import Supabase

actor LiveTimelineRepository: TimelineRepositoryProtocol {
    private let client: SupabaseClient?
    private let logger = AppLogger.repository
    
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
                        vendor:vendors(id, vendor_name),
                        payment:payment_schedules(*)
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
                        vendor:vendors(id, vendor_name),
                        payment:payment_schedules(*)
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
        let client = try getClient()
        let startTime = Date()

        do {
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
            logger.info("Created timeline item in \(duration)s")
            AnalyticsService.trackNetwork(operation: "createTimelineItem", outcome: .success, duration: duration)

            return item
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to create timeline item after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "createTimelineItem", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func updateTimelineItem(_ item: TimelineItem) async throws -> TimelineItem {
        let client = try getClient()
        let startTime = Date()

        do {
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
            logger.info("Updated timeline item in \(duration)s")
            AnalyticsService.trackNetwork(operation: "updateTimelineItem", outcome: .success, duration: duration)

            return updated
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to update timeline item after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "updateTimelineItem", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func deleteTimelineItem(id: UUID) async throws {
        let client = try getClient()
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("timeline_items")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted timeline item in \(duration)s")
            AnalyticsService.trackNetwork(operation: "deleteTimelineItem", outcome: .success, duration: duration)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to delete timeline item after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "deleteTimelineItem", outcome: .failure(code: nil), duration: duration)
            throw error
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
                    .order("milestone_date", ascending: true)
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
        let client = try getClient()
        let startTime = Date()

        do {
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
            logger.info("Created milestone in \(duration)s")
            AnalyticsService.trackNetwork(operation: "createMilestone", outcome: .success, duration: duration)

            return milestone
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to create milestone after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "createMilestone", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func updateMilestone(_ milestone: Milestone) async throws -> Milestone {
        let client = try getClient()
        let startTime = Date()

        do {
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
            logger.info("Updated milestone in \(duration)s")
            AnalyticsService.trackNetwork(operation: "updateMilestone", outcome: .success, duration: duration)

            return updated
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to update milestone after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "updateMilestone", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }

    func deleteMilestone(id: UUID) async throws {
        let client = try getClient()
        let startTime = Date()

        do {
            try await RepositoryNetwork.withRetry {
                try await client.database
                    .from("wedding_milestones")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            logger.info("Deleted milestone in \(duration)s")
            AnalyticsService.trackNetwork(operation: "deleteMilestone", outcome: .success, duration: duration)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("Failed to delete milestone after \(duration)s", error: error)
            AnalyticsService.trackNetwork(operation: "deleteMilestone", outcome: .failure(code: nil), duration: duration)
            throw error
        }
    }
}
