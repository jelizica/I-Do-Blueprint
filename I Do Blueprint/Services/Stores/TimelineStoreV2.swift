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
class TimelineStoreV2: ObservableObject {
    @Published var loadingState: LoadingState<[TimelineItem]> = .idle
    @Published private(set) var milestones: [Milestone] = []

    // View state
    @Published var viewMode: TimelineViewMode = .grouped
    @Published var filterType: TimelineItemType?
    @Published var showCompleted = true

    @Dependency(\.timelineRepository) var repository
    
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

    func loadTimelineItems() async {
        guard loadingState.isIdle || loadingState.hasError else { return }
        
        loadingState = .loading

        do {
            async let itemsResult = repository.fetchTimelineItems()
            async let milestonesResult = repository.fetchMilestones()

            let fetchedItems = try await itemsResult
            milestones = try await milestonesResult
            
            loadingState = .loaded(fetchedItems)
        } catch {
            loadingState = .error(TimelineError.fetchFailed(underlying: error))
        }
    }

    func refreshTimeline() async {
        await loadTimelineItems()
    }

    func createTimelineItem(_ insertData: TimelineItemInsertData) async {
    do {
    let item = try await repository.createTimelineItem(insertData)
    
    if case .loaded(var currentItems) = loadingState {
    currentItems.append(item)
    currentItems.sort { $0.itemDate < $1.itemDate }
    loadingState = .loaded(currentItems)
    }
    
    showSuccess("Timeline item created successfully")
    } catch {
    loadingState = .error(TimelineError.createFailed(underlying: error))
    await handleError(error, operation: "create timeline item") { [weak self] in
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
            
            showSuccess("Timeline item updated successfully")
        } catch {
            // Rollback on error
            if case .loaded(var items) = loadingState,
               let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = original
                loadingState = .loaded(items)
            }
            loadingState = .error(TimelineError.updateFailed(underlying: error))
            await handleError(error, operation: "update timeline item") { [weak self] in
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
            showSuccess("Timeline item deleted successfully")
        } catch {
            // Rollback on error
            if case .loaded(var items) = loadingState {
                items.insert(removed, at: index)
                loadingState = .loaded(items)
            }
            loadingState = .error(TimelineError.deleteFailed(underlying: error))
            await handleError(error, operation: "delete timeline item") { [weak self] in
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
        } catch {
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
            } catch {
                // Rollback on error
                milestones[index] = original
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
        } catch {
            // Rollback on error
            milestones.insert(removed, at: index)
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
}
