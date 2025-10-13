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
    @Published private(set) var timelineItems: [TimelineItem] = []
    @Published private(set) var milestones: [Milestone] = []

    @Published var isLoading = false
    @Published var error: TimelineError?

    // View state
    @Published var viewMode: TimelineViewMode = .grouped
    @Published var filterType: TimelineItemType?
    @Published var showCompleted = true

    @Dependency(\.timelineRepository) var repository

    // MARK: - Timeline Items

    func loadTimelineItems() async {
        isLoading = true
        error = nil

        do {
            async let itemsResult = repository.fetchTimelineItems()
            async let milestonesResult = repository.fetchMilestones()

            timelineItems = try await itemsResult
            milestones = try await milestonesResult
        } catch {
            self.error = .fetchFailed(underlying: error)
        }

        isLoading = false
    }

    func refreshTimeline() async {
        await loadTimelineItems()
    }

    func createTimelineItem(_ insertData: TimelineItemInsertData) async {
        do {
            let item = try await repository.createTimelineItem(insertData)
            timelineItems.append(item)
            timelineItems.sort { $0.itemDate < $1.itemDate }
        } catch {
            self.error = .createFailed(underlying: error)
        }
    }

    func updateTimelineItem(_ item: TimelineItem) async {
        // Optimistic update
        if let index = timelineItems.firstIndex(where: { $0.id == item.id }) {
            let original = timelineItems[index]
            timelineItems[index] = item

            do {
                let updated = try await repository.updateTimelineItem(item)
                timelineItems[index] = updated
                timelineItems.sort { $0.itemDate < $1.itemDate }
            } catch {
                // Rollback on error
                timelineItems[index] = original
                self.error = .updateFailed(underlying: error)
            }
        }
    }

    func deleteTimelineItem(_ item: TimelineItem) async {
        // Optimistic delete
        guard let index = timelineItems.firstIndex(where: { $0.id == item.id }) else { return }
        let removed = timelineItems.remove(at: index)

        do {
            try await repository.deleteTimelineItem(id: item.id)
        } catch {
            // Rollback on error
            timelineItems.insert(removed, at: index)
            self.error = .deleteFailed(underlying: error)
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
            self.error = .createFailed(underlying: error)
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
                self.error = .updateFailed(underlying: error)
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
            self.error = .deleteFailed(underlying: error)
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
        milestones.filter { !$0.completed }
    }
}
