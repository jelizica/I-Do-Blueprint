//
//  TimelineStoreV2.swift
//  My Wedding Planning App
//
//  New architecture version of timeline management using repository pattern
//

import AppKit
import Combine
import Dependencies
import Foundation
import SwiftUI

@MainActor
class TimelineStoreV2: ObservableObject, CacheableStore {
    @Published var loadingState: LoadingState<[TimelineItem]> = .idle
    @Published private(set) var milestones: [Milestone] = []
    @Published var weddingDayEventsLoadingState: LoadingState<[WeddingDayEvent]> = .idle

    // View state
    @Published var viewMode: TimelineViewMode = .grouped
    @Published var filterType: TimelineItemType?
    @Published var showCompleted = true
    @Published var weddingDayViewMode: WeddingDayViewMode = .list

    @Dependency(\.timelineRepository) var repository

    // MARK: - Cache Management
    var lastLoadTime: Date?
    let cacheValidityDuration: TimeInterval = 300 // 5 minutes

    // Task tracking for cancellation handling
    private var loadTask: Task<Void, Never>?
    private var weddingDayEventsLoadTask: Task<Void, Never>?

    // MARK: - Computed Properties for Backward Compatibility

    var timelineItems: [TimelineItem] {
        loadingState.data ?? []
    }

    var isLoading: Bool {
        loadingState.isLoading
    }

    var error: TimelineError? {
        if case .error(let err) = loadingState {
            return err as? TimelineError ?? .fetchFailed(underlying: err)
        }
        return nil
    }

    // MARK: - Timeline Items

    func loadTimelineItems(force: Bool = false) async {
        // Cancel any previous load task
        loadTask?.cancel()

        // Create new load task
        loadTask = Task { @MainActor in
            // Use cached data if still valid
            if !force && isCacheValid() {
                AppLogger.ui.debug("Using cached timeline data (age: \(Int(cacheAge()))s)")
                return
            }

            guard loadingState.isIdle || loadingState.hasError || force else { return }

            loadingState = .loading

            do {
                try Task.checkCancellation()

                async let itemsResult = repository.fetchTimelineItems()
                async let milestonesResult = repository.fetchMilestones()

                let fetchedItems = try await itemsResult
                let fetchedMilestones = try await milestonesResult

                try Task.checkCancellation()

                milestones = fetchedMilestones
                loadingState = .loaded(fetchedItems)
                lastLoadTime = Date()
            } catch is CancellationError {
                AppLogger.ui.debug("TimelineStoreV2.loadTimelineItems: Load cancelled (expected during tenant switch)")
                loadingState = .idle
            } catch let error as URLError where error.code == .cancelled {
                AppLogger.ui.debug("TimelineStoreV2.loadTimelineItems: Load cancelled (URLError)")
                loadingState = .idle
            } catch {
                loadingState = .error(TimelineError.fetchFailed(underlying: error))
            }
        }

        await loadTask?.value
    }

    func refreshTimeline() async {
        await loadTimelineItems(force: true)
    }

    func createTimelineItem(_ insertData: TimelineItemInsertData) async {
    do {
    let item = try await repository.createTimelineItem(insertData)

    if case .loaded(var currentItems) = loadingState {
    currentItems.append(item)
    currentItems.sort { $0.itemDate < $1.itemDate }
    loadingState = .loaded(currentItems)
    }

    // Invalidate cache due to mutation
    invalidateCache()
    showSuccess("Timeline item created successfully")
    } catch {
    loadingState = .error(TimelineError.createFailed(underlying: error))
    await handleError(error, operation: "createTimelineItem") { [weak self] in
        await self?.createTimelineItem(insertData)
    }
    }
    }

    func updateTimelineItem(_ item: TimelineItem) async {
        // Optimistic update
        guard case .loaded(var currentItems) = loadingState,
              let index = currentItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        let original = currentItems[index]
        currentItems[index] = item
        loadingState = .loaded(currentItems)

        do {
            let updated = try await repository.updateTimelineItem(item)

            if case .loaded(var items) = loadingState,
               let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = updated
                items.sort { $0.itemDate < $1.itemDate }
                loadingState = .loaded(items)
            }

            // Invalidate cache due to mutation
            invalidateCache()
            showSuccess("Timeline item updated successfully")
        } catch {
            // Rollback on error
            if case .loaded(var items) = loadingState,
               let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = original
                loadingState = .loaded(items)
            }
            loadingState = .error(TimelineError.updateFailed(underlying: error))
            await handleError(error, operation: "updateTimelineItem", context: [
                "itemId": item.id.uuidString
            ]) { [weak self] in
                await self?.updateTimelineItem(item)
            }
        }
    }

    func deleteTimelineItem(_ item: TimelineItem) async {
        // Optimistic delete
        guard case .loaded(var currentItems) = loadingState,
              let index = currentItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        let removed = currentItems.remove(at: index)
        loadingState = .loaded(currentItems)

        do {
            try await repository.deleteTimelineItem(id: item.id)
            // Invalidate cache due to mutation
            invalidateCache()
            showSuccess("Timeline item deleted successfully")
        } catch {
            // Rollback on error
            if case .loaded(var items) = loadingState {
                items.insert(removed, at: index)
                loadingState = .loaded(items)
            }
            loadingState = .error(TimelineError.deleteFailed(underlying: error))
            await handleError(error, operation: "deleteTimelineItem", context: [
                "itemId": item.id.uuidString
            ]) { [weak self] in
                await self?.deleteTimelineItem(item)
            }
        }
    }

    func toggleItemCompletion(_ item: TimelineItem) async {
        var updated = item
        updated.completed.toggle()
        updated.updatedAt = Date()
        await updateTimelineItem(updated)
    }

    // MARK: - Milestones

    func createMilestone(_ insertData: MilestoneInsertData) async {
        do {
            let milestone = try await repository.createMilestone(insertData)
            milestones.append(milestone)
            milestones.sort { $0.milestoneDate < $1.milestoneDate }
            // Invalidate cache due to mutation
            invalidateCache()
        } catch {
            await handleError(error, operation: "createMilestone") { [weak self] in
                await self?.createMilestone(insertData)
            }
            loadingState = .error(TimelineError.createFailed(underlying: error))
        }
    }

    func updateMilestone(_ milestone: Milestone) async {
        // Optimistic update
        if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
            let original = milestones[index]
            milestones[index] = milestone

            do {
                let updated = try await repository.updateMilestone(milestone)
                milestones[index] = updated
                milestones.sort { $0.milestoneDate < $1.milestoneDate }
                // Invalidate cache due to mutation
                invalidateCache()
            } catch {
                // Rollback on error
                milestones[index] = original
                await handleError(error, operation: "updateMilestone", context: [
                    "milestoneId": milestone.id.uuidString
                ]) { [weak self] in
                    await self?.updateMilestone(milestone)
                }
                loadingState = .error(TimelineError.updateFailed(underlying: error))
            }
        }
    }

    func deleteMilestone(_ milestone: Milestone) async {
        // Optimistic delete
        guard let index = milestones.firstIndex(where: { $0.id == milestone.id }) else { return }
        let removed = milestones.remove(at: index)

        do {
            try await repository.deleteMilestone(id: milestone.id)
            // Invalidate cache due to mutation
            invalidateCache()
        } catch {
            // Rollback on error
            milestones.insert(removed, at: index)
            await handleError(error, operation: "deleteMilestone", context: [
                "milestoneId": milestone.id.uuidString
            ]) { [weak self] in
                await self?.deleteMilestone(milestone)
            }
            loadingState = .error(TimelineError.deleteFailed(underlying: error))
        }
    }

    func toggleMilestoneCompletion(_ milestone: Milestone) async {
        var updated = milestone
        updated.completed.toggle()
        updated.updatedAt = Date()
        await updateMilestone(updated)
    }

    // MARK: - Wedding Day Events

    /// All wedding day events from the loading state
    var weddingDayEvents: [WeddingDayEvent] {
        weddingDayEventsLoadingState.data ?? []
    }

    /// Whether wedding day events are currently loading
    var isLoadingWeddingDayEvents: Bool {
        weddingDayEventsLoadingState.isLoading
    }

    /// Load all wedding day events
    func loadWeddingDayEvents(force: Bool = false) async {
        // Cancel any previous load task
        weddingDayEventsLoadTask?.cancel()

        weddingDayEventsLoadTask = Task { @MainActor in
            // Skip if already loaded and not forcing
            if !force && weddingDayEventsLoadingState.data != nil {
                AppLogger.ui.debug("Using cached wedding day events data")
                return
            }

            guard weddingDayEventsLoadingState.isIdle || weddingDayEventsLoadingState.hasError || force else { return }

            weddingDayEventsLoadingState = .loading

            do {
                try Task.checkCancellation()

                let events = try await repository.fetchWeddingDayEvents()

                try Task.checkCancellation()

                weddingDayEventsLoadingState = .loaded(events)
            } catch is CancellationError {
                AppLogger.ui.debug("TimelineStoreV2.loadWeddingDayEvents: Load cancelled")
                weddingDayEventsLoadingState = .idle
            } catch let error as URLError where error.code == .cancelled {
                AppLogger.ui.debug("TimelineStoreV2.loadWeddingDayEvents: Load cancelled (URLError)")
                weddingDayEventsLoadingState = .idle
            } catch {
                weddingDayEventsLoadingState = .error(TimelineError.fetchFailed(underlying: error))
            }
        }

        await weddingDayEventsLoadTask?.value
    }

    /// Load wedding day events for a specific date
    func loadWeddingDayEvents(forDate date: Date) async -> [WeddingDayEvent] {
        do {
            return try await repository.fetchWeddingDayEvents(forDate: date)
        } catch {
            await handleError(error, operation: "loadWeddingDayEventsForDate")
            return []
        }
    }

    /// Refresh wedding day events
    func refreshWeddingDayEvents() async {
        await loadWeddingDayEvents(force: true)
    }

    /// Create a new wedding day event
    func createWeddingDayEvent(_ insertData: WeddingDayEventInsertData) async {
        do {
            let event = try await repository.createWeddingDayEvent(insertData)

            if case .loaded(var currentEvents) = weddingDayEventsLoadingState {
                currentEvents.append(event)
                currentEvents.sort { ($0.startTime ?? $0.eventDate) < ($1.startTime ?? $1.eventDate) }
                weddingDayEventsLoadingState = .loaded(currentEvents)
            }

            invalidateCache()
            showSuccess("Event added successfully")
        } catch {
            weddingDayEventsLoadingState = .error(TimelineError.createFailed(underlying: error))
            await handleError(error, operation: "createWeddingDayEvent") { [weak self] in
                await self?.createWeddingDayEvent(insertData)
            }
        }
    }

    /// Update an existing wedding day event
    func updateWeddingDayEvent(_ event: WeddingDayEvent) async {
        // Optimistic update
        guard case .loaded(var currentEvents) = weddingDayEventsLoadingState,
              let index = currentEvents.firstIndex(where: { $0.id == event.id }) else {
            return
        }

        let original = currentEvents[index]
        currentEvents[index] = event
        weddingDayEventsLoadingState = .loaded(currentEvents)

        do {
            let updated = try await repository.updateWeddingDayEvent(event)

            if case .loaded(var events) = weddingDayEventsLoadingState,
               let idx = events.firstIndex(where: { $0.id == event.id }) {
                events[idx] = updated
                events.sort { ($0.startTime ?? $0.eventDate) < ($1.startTime ?? $1.eventDate) }
                weddingDayEventsLoadingState = .loaded(events)
            }

            invalidateCache()
            showSuccess("Event updated successfully")
        } catch {
            // Rollback on error
            if case .loaded(var events) = weddingDayEventsLoadingState,
               let idx = events.firstIndex(where: { $0.id == event.id }) {
                events[idx] = original
                weddingDayEventsLoadingState = .loaded(events)
            }
            weddingDayEventsLoadingState = .error(TimelineError.updateFailed(underlying: error))
            await handleError(error, operation: "updateWeddingDayEvent", context: [
                "eventId": event.id.uuidString
            ]) { [weak self] in
                await self?.updateWeddingDayEvent(event)
            }
        }
    }

    /// Delete a wedding day event
    func deleteWeddingDayEvent(_ event: WeddingDayEvent) async {
        // Optimistic delete
        guard case .loaded(var currentEvents) = weddingDayEventsLoadingState,
              let index = currentEvents.firstIndex(where: { $0.id == event.id }) else {
            return
        }

        let removed = currentEvents.remove(at: index)
        weddingDayEventsLoadingState = .loaded(currentEvents)

        do {
            try await repository.deleteWeddingDayEvent(id: event.id)
            invalidateCache()
            showSuccess("Event deleted successfully")
        } catch {
            // Rollback on error
            if case .loaded(var events) = weddingDayEventsLoadingState {
                events.insert(removed, at: index)
                weddingDayEventsLoadingState = .loaded(events)
            }
            weddingDayEventsLoadingState = .error(TimelineError.deleteFailed(underlying: error))
            await handleError(error, operation: "deleteWeddingDayEvent", context: [
                "eventId": event.id.uuidString
            ]) { [weak self] in
                await self?.deleteWeddingDayEvent(event)
            }
        }
    }

    /// Update the status of a wedding day event
    func updateWeddingDayEventStatus(_ event: WeddingDayEvent, status: WeddingDayEventStatus) async {
        var updated = event
        updated.status = status
        updated.updatedAt = Date()
        await updateWeddingDayEvent(updated)
    }

    // MARK: - Wedding Day Event Computed Properties

    /// Events grouped by category
    var weddingDayEventsByCategory: [WeddingDayEventCategory: [WeddingDayEvent]] {
        Dictionary(grouping: weddingDayEvents, by: \.category)
    }

    /// Events sorted by start time for Gantt chart display
    var weddingDayEventsForGantt: [WeddingDayEvent] {
        weddingDayEvents.sorted { event1, event2 in
            let time1 = event1.startTime ?? event1.eventDate
            let time2 = event2.startTime ?? event2.eventDate
            return time1 < time2
        }
    }

    /// Events with dependencies (for dependency line rendering)
    var weddingDayEventsWithDependencies: [WeddingDayEvent] {
        weddingDayEvents.filter { $0.hasDependency }
    }

    /// Key events (main event or key event status)
    var keyWeddingDayEvents: [WeddingDayEvent] {
        weddingDayEvents.filter { $0.isHighlighted }
    }

    /// Events pending confirmation
    var pendingWeddingDayEvents: [WeddingDayEvent] {
        weddingDayEvents.filter { $0.status == .pending }
    }

    /// Total duration of all events in minutes
    var totalWeddingDayDuration: Int {
        weddingDayEvents.reduce(0) { $0 + $1.calculatedDurationMinutes }
    }

    /// Find the dependency event for a given event
    func dependencyEvent(for event: WeddingDayEvent) -> WeddingDayEvent? {
        guard let dependsOnId = event.dependsOnEventId else { return nil }
        return weddingDayEvents.first { $0.id == dependsOnId }
    }

    /// Find events that depend on a given event
    func dependentEvents(on event: WeddingDayEvent) -> [WeddingDayEvent] {
        weddingDayEvents.filter { $0.dependsOnEventId == event.id }
    }

    /// Parent events only (excludes sub-events) - for settings display
    var parentWeddingDayEvents: [WeddingDayEvent] {
        weddingDayEvents.filter { $0.isParentEvent }
    }

    /// Get sub-events for a specific parent event
    func subEvents(for parentEvent: WeddingDayEvent) -> [WeddingDayEvent] {
        weddingDayEvents.filter { $0.parentEventId == parentEvent.id }
    }

    // MARK: - Photo Management

    /// Upload a photo for an event and update the event's photo_urls array
    /// - Parameters:
    ///   - image: The NSImage to upload
    ///   - event: The event to add the photo to
    func uploadPhoto(_ image: NSImage, for event: WeddingDayEvent) async {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let imageData = bitmapImage.representation(using: .png, properties: [:]) else {
            AppLogger.ui.error("Failed to convert image to PNG data")
            return
        }

        do {
            let coupleId = try await TenantContextProvider.shared.requireTenantId()
            let photoUrl = try await repository.uploadEventPhoto(
                imageData: imageData,
                eventId: event.id,
                coupleId: coupleId
            )

            // Update the event with the new photo URL
            var updatedEvent = event
            updatedEvent.photoUrls.append(photoUrl)
            updatedEvent.updatedAt = Date()

            await updateWeddingDayEvent(updatedEvent)
            showSuccess("Photo uploaded successfully")
        } catch {
            await handleError(error, operation: "uploadPhoto", context: [
                "eventId": event.id.uuidString
            ]) { [weak self] in
                await self?.uploadPhoto(image, for: event)
            }
        }
    }

    /// Delete a photo from an event
    /// - Parameters:
    ///   - photoUrl: The URL of the photo to delete
    ///   - event: The event to remove the photo from
    func deletePhoto(_ photoUrl: String, from event: WeddingDayEvent) async {
        do {
            try await repository.deleteEventPhoto(photoUrl: photoUrl)

            // Update the event to remove the photo URL
            var updatedEvent = event
            updatedEvent.photoUrls.removeAll { $0 == photoUrl }
            updatedEvent.updatedAt = Date()

            await updateWeddingDayEvent(updatedEvent)
            showSuccess("Photo deleted successfully")
        } catch {
            await handleError(error, operation: "deletePhoto", context: [
                "eventId": event.id.uuidString,
                "photoUrl": photoUrl
            ]) { [weak self] in
                await self?.deletePhoto(photoUrl, from: event)
            }
        }
    }

    // MARK: - Guest and Vendor Assignment

    /// Assign guests to an event
    /// - Parameters:
    ///   - guestIds: Array of guest UUIDs to assign
    ///   - event: The event to assign guests to
    func assignGuests(_ guestIds: [UUID], to event: WeddingDayEvent) async {
        var updatedEvent = event
        updatedEvent.assignedGuestIds = guestIds
        updatedEvent.updatedAt = Date()
        await updateWeddingDayEvent(updatedEvent)
    }

    /// Assign vendors to an event
    /// - Parameters:
    ///   - vendorIds: Array of vendor IDs (Int64) to assign
    ///   - event: The event to assign vendors to
    func assignVendors(_ vendorIds: [Int64], to event: WeddingDayEvent) async {
        var updatedEvent = event
        updatedEvent.assignedVendorIds = vendorIds
        updatedEvent.updatedAt = Date()
        await updateWeddingDayEvent(updatedEvent)
    }

    // MARK: - Sub-Event Management

    /// Create a sub-event under a parent event
    /// - Parameters:
    ///   - insertData: The sub-event data
    ///   - parentEvent: The parent event
    func createSubEvent(_ insertData: WeddingDayEventInsertData, under parentEvent: WeddingDayEvent) async {
        var subEventData = insertData
        subEventData.parentEventId = parentEvent.id
        await createWeddingDayEvent(subEventData)
    }

    // MARK: - Computed Properties

    var filteredItems: [TimelineItem] {
        var filtered = timelineItems

        // Filter by type
        if let type = filterType {
            filtered = filtered.filter { $0.itemType == type }
        }

        // Filter by completion
        if !showCompleted {
            filtered = filtered.filter { !$0.completed }
        }

        return filtered
    }

    var groupedItems: [TimelineGroup] {
        let groups = Dictionary(grouping: filteredItems, by: \.groupKey)

        return groups.map { key, items in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let date = formatter.date(from: key.replacingOccurrences(of: "-", with: " ")) ?? Date()
            let title = formatter.string(from: date)

            return TimelineGroup(
                id: key,
                title: title,
                items: items.sorted { $0.itemDate < $1.itemDate })
        }.sorted { $0.id < $1.id }
    }

    var upcomingItems: [TimelineItem] {
        let now = Date()
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: now) ?? now

        return filteredItems.filter { item in
            !item.completed &&
                item.itemDate >= now &&
                item.itemDate <= nextMonth
        }
    }

    var overdueItems: [TimelineItem] {
        let now = Date()
        return filteredItems.filter { item in
            !item.completed && item.itemDate < now
        }
    }

    var completedMilestones: [Milestone] {
        milestones.filter(\.completed)
    }

    var upcomingMilestones: [Milestone] {
        let now = Date()
        return milestones
            .filter { !$0.completed && $0.milestoneDate >= now }
            .sorted(by: { $0.milestoneDate < $1.milestoneDate })
    }

    // MARK: - Helper Methods

    func groupedItemsByMonth() -> [String: [TimelineItem]] {
        var grouped: [String: [TimelineItem]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        for item in filteredItems {
            let key = formatter.string(from: item.itemDate)
            if grouped[key] == nil {
                grouped[key] = []
            }
            grouped[key]?.append(item)
        }

        return grouped
    }

    func sortedMonthKeys() -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        return groupedItemsByMonth().keys.sorted { month1, month2 in
            guard let date1 = formatter.date(from: month1),
                  let date2 = formatter.date(from: month2) else {
                return month1 < month2
            }
            return date1 < date2
        }
    }

    func clearFilters() {
        filterType = nil
        showCompleted = true
    }

    func completedItemsCount() -> Int {
        filteredItems.filter(\.completed).count
    }

    // MARK: - Retry Helper

    func retryLoad() async {
        await loadTimelineItems()
    }

    // MARK: - State Management

    /// Reset loaded state (for logout/tenant switch)
    func resetLoadedState() {
        // Cancel in-flight tasks to avoid race conditions during tenant switch
        loadTask?.cancel()
        weddingDayEventsLoadTask?.cancel()

        // Reset state and invalidate cache
        loadingState = .idle
        weddingDayEventsLoadingState = .idle
        milestones = []
        lastLoadTime = nil
    }
}
