//
//  TimelineRepositoryProtocol.swift
//  My Wedding Planning App
//
//  Repository protocol for timeline management
//

import Dependencies
import Foundation

protocol TimelineRepositoryProtocol: Sendable {
    // MARK: - Timeline Items

    func fetchTimelineItems() async throws -> [TimelineItem]
    func fetchTimelineItem(id: UUID) async throws -> TimelineItem?
    func createTimelineItem(_ insertData: TimelineItemInsertData) async throws -> TimelineItem
    func updateTimelineItem(_ item: TimelineItem) async throws -> TimelineItem
    func deleteTimelineItem(id: UUID) async throws

    // MARK: - Milestones

    func fetchMilestones() async throws -> [Milestone]
    func fetchMilestone(id: UUID) async throws -> Milestone?
    func createMilestone(_ insertData: MilestoneInsertData) async throws -> Milestone
    func updateMilestone(_ milestone: Milestone) async throws -> Milestone
    func deleteMilestone(id: UUID) async throws

    // MARK: - Wedding Day Events

    func fetchWeddingDayEvents() async throws -> [WeddingDayEvent]
    func fetchWeddingDayEvents(forDate date: Date) async throws -> [WeddingDayEvent]
    func fetchWeddingDayEvent(id: UUID) async throws -> WeddingDayEvent?
    func createWeddingDayEvent(_ insertData: WeddingDayEventInsertData) async throws -> WeddingDayEvent
    func updateWeddingDayEvent(_ event: WeddingDayEvent) async throws -> WeddingDayEvent
    func deleteWeddingDayEvent(id: UUID) async throws

    // MARK: - Event Photos

    /// Uploads a photo to Supabase Storage for an event
    /// - Parameters:
    ///   - imageData: The image data (PNG format)
    ///   - eventId: The event ID for organizing storage
    ///   - coupleId: The couple ID for tenant isolation
    /// - Returns: The signed URL of the uploaded photo
    func uploadEventPhoto(imageData: Data, eventId: UUID, coupleId: UUID) async throws -> String

    /// Deletes a photo from Supabase Storage
    /// - Parameter photoUrl: The URL of the photo to delete
    func deleteEventPhoto(photoUrl: String) async throws

    // MARK: - Sub-Event Filtering

    /// Fetches only parent events (events without a parent_event_id)
    func fetchParentWeddingDayEvents() async throws -> [WeddingDayEvent]

    /// Fetches sub-events for a given parent event
    func fetchSubEvents(parentEventId: UUID) async throws -> [WeddingDayEvent]
}
