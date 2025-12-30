//
//  TimelineStoreV2.swift
//  My Wedding Planning App
//
//  New architecture version of timeline management using repository pattern
//

import Combine
import Dependencies
import Foundation
import SwiftUI

@MainActor
class TimelineStoreV2: ObservableObject, CacheableStore {
    @Published var loadingState: LoadingState<[TimelineItem]> = .idle
    @Published private(set) var milestones: [Milestone] = []

    // View state
    @Published var viewMode: TimelineViewMode = .grouped
    @Published var filterType: TimelineItemType?
    @Published var showCompleted = true

    @Dependency(\.timelineRepository) var repository

    // MARK: - Cache Management
    var lastLoadTime: Date?
    let cacheValidityDuration: TimeInterval = 300 // 5 minutes

    // Task tracking for cancellation handling
    private var loadTask: Task<Void, Never>?

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

        // Reset state and invalidate cache
        loadingState = .idle
        milestones = []
        lastLoadTime = nil
    }
}
