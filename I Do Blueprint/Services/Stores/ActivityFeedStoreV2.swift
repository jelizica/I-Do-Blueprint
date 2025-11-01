//
//  ActivityFeedStoreV2.swift
//  I Do Blueprint
//
//  Activity feed store using repository pattern
//

import Combine
import Dependencies
import Foundation
import SwiftUI

/// Activity feed store for tracking and displaying collaboration activities
@MainActor
class ActivityFeedStoreV2: ObservableObject {
    @Published var loadingState: LoadingState<[ActivityEvent]> = .idle
    @Published private(set) var unreadCount: Int = 0
    @Published private(set) var activityStats: ActivityStats?
    @Published private(set) var filteredActivities: [ActivityEvent] = []
    
    // Filter state
    @Published var selectedActionType: ActionType?
    @Published var selectedResourceType: ResourceType?
    @Published var selectedActorId: UUID?
    
    @Dependency(\.activityFeedRepository) var repository
    
    private let pageSize = 50
    private var currentOffset = 0
    private var hasMorePages = true
    
    // MARK: - Computed Properties
    
    var activities: [ActivityEvent] {
        loadingState.data ?? []
    }
    
    var isLoading: Bool {
        loadingState.isLoading
    }
    
    var error: ActivityFeedError? {
        if case .error(let err) = loadingState {
            return err as? ActivityFeedError ?? .fetchFailed(underlying: err)
        }
        return nil
    }
    
    var unreadActivities: [ActivityEvent] {
        activities.filter { !$0.isRead }
    }
    
    var hasUnread: Bool {
        unreadCount > 0
    }
    
    // MARK: - Public Interface
    
    func loadActivities(refresh: Bool = false) async {
        // Reset pagination on refresh
        if refresh {
            currentOffset = 0
            hasMorePages = true
        }
        
        // Only load if idle, error, or refresh
        guard loadingState.isIdle || loadingState.hasError || refresh else {
            return
        }
        
        loadingState = .loading
        
        do {
            async let activitiesResult = repository.fetchActivities(
                limit: pageSize,
                offset: currentOffset
            )
            async let unreadResult = repository.fetchUnreadCount()
            async let statsResult = repository.fetchActivityStats()
            
            let fetchedActivities = try await activitiesResult
            unreadCount = try await unreadResult
            activityStats = try await statsResult
            
            // Check if we have more pages
            hasMorePages = fetchedActivities.count == pageSize
            
            if refresh {
                loadingState = .loaded(fetchedActivities)
                filteredActivities = fetchedActivities
            } else {
                // Append to existing activities for pagination
                if case .loaded(let existing) = loadingState {
                    let combined = existing + fetchedActivities
                    loadingState = .loaded(combined)
                    filteredActivities = combined
                } else {
                    loadingState = .loaded(fetchedActivities)
                    filteredActivities = fetchedActivities
                }
            }
            
            currentOffset += fetchedActivities.count
        } catch {
            loadingState = .error(ActivityFeedError.fetchFailed(underlying: error))
        }
    }
    
    func loadMoreActivities() async {
        guard hasMorePages && !isLoading else { return }
        await loadActivities(refresh: false)
    }
    
    func filterActivities() async {
        do {
            var filtered: [ActivityEvent]
            
            // Apply filters based on selection
            if let actionType = selectedActionType {
                filtered = try await repository.fetchActivities(
                    actionType: actionType,
                    limit: pageSize
                )
            } else if let resourceType = selectedResourceType {
                filtered = try await repository.fetchActivities(
                    resourceType: resourceType,
                    limit: pageSize
                )
            } else if let actorId = selectedActorId {
                filtered = try await repository.fetchActivities(
                    actorId: actorId,
                    limit: pageSize
                )
            } else {
                // No filters, use all activities
                filtered = activities
            }
            
            filteredActivities = filtered
        } catch {
            loadingState = .error(ActivityFeedError.fetchFailed(underlying: error))
        }
    }
    
    func markAsRead(id: UUID) async {
        // Optimistic update
        if case .loaded(var currentActivities) = loadingState,
           let index = currentActivities.firstIndex(where: { $0.id == id }) {
            var activity = currentActivities[index]
            let wasUnread = !activity.isRead
            activity.isRead = true
            currentActivities[index] = activity
            loadingState = .loaded(currentActivities)
            
            // Update filtered list
            if let filteredIndex = filteredActivities.firstIndex(where: { $0.id == id }) {
                filteredActivities[filteredIndex].isRead = true
            }
            
            // Decrement unread count
            if wasUnread && unreadCount > 0 {
                unreadCount -= 1
            }
        }
        
        do {
            _ = try await repository.markAsRead(id: id)
        } catch {
            // Silently fail for mark as read
            // Could add error handling if needed
        }
    }
    
    func markAllAsRead() async {
        // Optimistic update
        if case .loaded(var currentActivities) = loadingState {
            for index in currentActivities.indices {
                currentActivities[index].isRead = true
            }
            loadingState = .loaded(currentActivities)
            
            // Update filtered list
            for index in filteredActivities.indices {
                filteredActivities[index].isRead = true
            }
            
            unreadCount = 0
        }
        
        do {
            _ = try await repository.markAllAsRead()
        } catch {
            loadingState = .error(ActivityFeedError.updateFailed(underlying: error))
        }
    }
    
    func clearFilters() {
        selectedActionType = nil
        selectedResourceType = nil
        selectedActorId = nil
        filteredActivities = activities
    }
    
    func getActivitiesForResource(resourceType: ResourceType, resourceId: UUID) -> [ActivityEvent] {
        activities.filter {
            $0.resourceType == resourceType &&
            $0.resourceId == resourceId
        }
    }
    
    func getRecentActivitiesForActor(actorId: UUID, limit: Int = 10) -> [ActivityEvent] {
        Array(activities.filter { $0.actorId == actorId }.prefix(limit))
    }
    
    // MARK: - Retry Helper
    
    func retryLoad() async {
        await loadActivities(refresh: true)
    }
}
