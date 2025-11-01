//
//  PresenceStoreV2.swift
//  I Do Blueprint
//
//  Real-time presence tracking store using repository pattern
//

import Combine
import Dependencies
import Foundation
import SwiftUI

/// Real-time presence tracking store for showing who's online and editing
@MainActor
class PresenceStoreV2: ObservableObject {
    @Published var loadingState: LoadingState<[Presence]> = .idle
    @Published private(set) var currentUserPresence: Presence?
    @Published private(set) var isTracking = false
    
    @Dependency(\.presenceRepository) var repository
    
    private var heartbeatTask: Task<Void, Never>?
    private let heartbeatInterval: TimeInterval = 30 // 30 seconds
    
    // MARK: - Computed Properties
    
    var activePresence: [Presence] {
        loadingState.data ?? []
    }
    
    var isLoading: Bool {
        loadingState.isLoading
    }
    
    var error: PresenceError? {
        if case .error(let err) = loadingState {
            return err as? PresenceError ?? .fetchFailed(underlying: err)
        }
        return nil
    }
    
    var onlineUsers: [Presence] {
        activePresence.filter { $0.isOnline }
    }
    
    var onlineCount: Int {
        onlineUsers.count
    }
    
    // MARK: - Public Interface
    
    func loadActivePresence() async {
        loadingState = .loading
        
        do {
            let presence = try await repository.fetchActivePresence()
            loadingState = .loaded(presence)
        } catch {
            loadingState = .error(PresenceError.fetchFailed(underlying: error))
        }
    }
    
    func startTracking(
        status: PresenceStatus = .online,
        currentView: String? = nil,
        currentResourceType: String? = nil,
        currentResourceId: UUID? = nil
    ) async {
        guard !isTracking else { return }
        
        do {
            let presence = try await repository.trackPresence(
                status: status,
                currentView: currentView,
                currentResourceType: currentResourceType,
                currentResourceId: currentResourceId
            )
            
            currentUserPresence = presence
            isTracking = true
            
            // Start heartbeat
            startHeartbeat()
            
            // Refresh active presence list
            await loadActivePresence()
        } catch {
            loadingState = .error(PresenceError.updateFailed(underlying: error))
        }
    }
    
    func stopTracking() async {
        guard isTracking else { return }
        
        // Stop heartbeat
        stopHeartbeat()
        
        do {
            try await repository.stopTracking()
            currentUserPresence = nil
            isTracking = false
            
            // Refresh active presence list
            await loadActivePresence()
        } catch {
            loadingState = .error(PresenceError.updateFailed(underlying: error))
        }
    }
    
    func updateEditingState(
        isEditing: Bool,
        resourceType: String? = nil,
        resourceId: UUID? = nil
    ) async {
        guard isTracking else { return }
        
        do {
            let updated = try await repository.updateEditingState(
                isEditing: isEditing,
                resourceType: resourceType,
                resourceId: resourceId
            )
            
            currentUserPresence = updated
            
            // Refresh active presence list
            await loadActivePresence()
        } catch {
            loadingState = .error(PresenceError.updateFailed(underlying: error))
        }
    }
    
    func updateCurrentView(_ viewName: String) async {
        guard isTracking else { return }
        
        do {
            let updated = try await repository.trackPresence(
                status: .online,
                currentView: viewName,
                currentResourceType: nil,
                currentResourceId: nil
            )
            
            currentUserPresence = updated
        } catch {
            // Silently fail for view updates
        }
    }
    
    func getUsersEditingResource(resourceType: String, resourceId: UUID) -> [Presence] {
        activePresence.filter {
            $0.isEditing &&
            $0.editingResourceType == resourceType &&
            $0.editingResourceId == resourceId
        }
    }
    
    func getUsersViewingResource(resourceType: String, resourceId: UUID) -> [Presence] {
        activePresence.filter {
            $0.currentResourceType == resourceType &&
            $0.currentResourceId == resourceId
        }
    }
    
    // MARK: - Heartbeat Management
    
    private func startHeartbeat() {
        stopHeartbeat() // Cancel any existing heartbeat
        
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self?.heartbeatInterval ?? 30) * 1_000_000_000)
                
                guard !Task.isCancelled else { break }
                
                await self?.sendHeartbeat()
            }
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }
    
    private func sendHeartbeat() async {
        guard isTracking else { return }
        
        do {
            let updated = try await repository.sendHeartbeat()
            currentUserPresence = updated
        } catch {
            // Silently fail for heartbeats to avoid noise
            // If heartbeat fails repeatedly, presence will become stale
        }
    }
    
    // MARK: - Cleanup
    
    nonisolated deinit {
        heartbeatTask?.cancel()
    }
}
