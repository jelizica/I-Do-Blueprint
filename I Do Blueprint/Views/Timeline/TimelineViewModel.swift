//
//  TimelineViewModel.swift
//  My Wedding Planning App
//
//  Created by Claude Code on 9/30/25.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class TimelineViewModel: ObservableObject {
    @Published var timelineItems: [TimelineItem] = []
    @Published var milestones: [Milestone] = []
    @Published var filteredItems: [TimelineItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedType: TimelineItemType?
    @Published var showCompletedOnly = false
    @Published var viewMode: TimelineViewMode = .grouped

    private let timelineAPI = TimelineAPI()
    private let logger = AppLogger.ui

    // MARK: - Load Data

    func load() async {
        // Prevent concurrent loads
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        logger.debug("TimelineViewModel starting load...")

        do {
            // Fetch timeline items (required)
            let items = try await timelineAPI.fetchTimelineItems()
            logger.debug("Received \(items.count) timeline items")

            timelineItems = items

            // Try to fetch milestones (optional - don't fail if table doesn't exist)
            do {
                let milestones = try await timelineAPI.fetchMilestones()
                self.milestones = milestones
                logger.debug("Received \(milestones.count) milestones")
            } catch {
                logger.warning("Could not load milestones (table may not exist): \(error.localizedDescription)")
                self.milestones = []
            }

            // Apply any active filters to the loaded data
            applyFilters()

            logger.debug("After filters - filteredItems count: \(filteredItems.count)")
        } catch {
            logger.error("Error loading timeline items", error: error)
            errorMessage = "Failed to load timeline: \(error.localizedDescription)"
        }

        isLoading = false
        logger.debug("Timeline load completed. isLoading: \(isLoading)")
    }

    func refresh() async {
        await load()
    }

    // MARK: - Filtering

    func applyFilters() {
        var result = timelineItems

        if let type = selectedType {
            result = result.filter { $0.itemType == type }
        }

        if showCompletedOnly {
            result = result.filter(\.completed)
        }

        filteredItems = result.sorted { $0.itemDate < $1.itemDate }
    }

    func clearFilters() {
        selectedType = nil
        showCompletedOnly = false
        applyFilters()
    }

    // MARK: - Grouping

    func groupedItemsByMonth() -> [String: [TimelineItem]] {
        var grouped: [String: [TimelineItem]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        // Group timeline items by month for calendar-style display
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

        // Sort month keys chronologically by converting back to dates
        return groupedItemsByMonth().keys.sorted { month1, month2 in
            guard let date1 = formatter.date(from: month1),
                  let date2 = formatter.date(from: month2) else {
                // Fallback to string comparison if date parsing fails
                return month1 < month2
            }
            return date1 < date2
        }
    }

    // MARK: - Milestone Helpers

    func upcomingMilestones() -> [Milestone] {
        let now = Date()
        return milestones
            .filter { !$0.completed && $0.milestoneDate >= now }
            .sorted(by: { $0.milestoneDate < $1.milestoneDate })
    }

    func completedMilestones() -> [Milestone] {
        milestones.filter(\.completed)
    }

    // MARK: - CRUD Operations

    func createTimelineItem(_ data: TimelineItemInsertData) async {
        do {
            let newItem = try await timelineAPI.createTimelineItem(data)
            timelineItems.append(newItem)
            applyFilters()
        } catch {
            errorMessage = "Failed to create item: \(error.localizedDescription)"
        }
    }

    func updateTimelineItem(_ id: UUID, data: TimelineItemInsertData) async {
        do {
            let updatedItem = try await timelineAPI.updateTimelineItem(id, data: data)
            // Replace the old item with updated version in local array
            if let index = timelineItems.firstIndex(where: { $0.id == id }) {
                timelineItems[index] = updatedItem
            }
            // Reapply filters to ensure filtered list stays in sync
            applyFilters()
        } catch {
            errorMessage = "Failed to update item: \(error.localizedDescription)"
        }
    }

    func toggleItemCompletion(_ item: TimelineItem) async {
        do {
            let updated = try await timelineAPI.updateTimelineItemCompletion(item.id, completed: !item.completed)
            if let index = timelineItems.firstIndex(where: { $0.id == item.id }) {
                timelineItems[index] = updated
            }
            applyFilters()
        } catch {
            errorMessage = "Failed to update completion: \(error.localizedDescription)"
        }
    }

    func deleteTimelineItem(_ id: UUID) async {
        do {
            try await timelineAPI.deleteTimelineItem(id)
            timelineItems.removeAll { $0.id == id }
            applyFilters()
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    func createMilestone(_ data: MilestoneInsertData) async {
        do {
            let newMilestone = try await timelineAPI.createMilestone(data)
            milestones.append(newMilestone)
        } catch {
            errorMessage = "Failed to create milestone: \(error.localizedDescription)"
        }
    }

    func updateMilestone(_ id: UUID, data: MilestoneInsertData) async {
        do {
            let updatedMilestone = try await timelineAPI.updateMilestone(id, data: data)
            if let index = milestones.firstIndex(where: { $0.id == id }) {
                milestones[index] = updatedMilestone
            }
        } catch {
            errorMessage = "Failed to update milestone: \(error.localizedDescription)"
        }
    }

    func toggleMilestoneCompletion(_ milestone: Milestone) async {
        do {
            let updated = try await timelineAPI.updateMilestoneCompletion(milestone.id, completed: !milestone.completed)
            if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
                milestones[index] = updated
            }
        } catch {
            errorMessage = "Failed to update milestone: \(error.localizedDescription)"
        }
    }

    func deleteMilestone(_ id: UUID) async {
        do {
            try await timelineAPI.deleteMilestone(id)
            milestones.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete milestone: \(error.localizedDescription)"
        }
    }
}
