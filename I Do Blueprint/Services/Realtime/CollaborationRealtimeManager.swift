//
//  CollaborationRealtimeManager.swift
//  I Do Blueprint
//
//  Real-time manager for collaboration features using Supabase Realtime
//

import Combine
import Foundation
import Realtime
import Supabase
import SwiftUI

/// Real-time manager for collaboration features
@MainActor
class CollaborationRealtimeManager: ObservableObject {
    static let shared = CollaborationRealtimeManager()

    @Published private(set) var isConnected = false
    @Published private(set) var connectionState: ConnectionState = .disconnected

    private let supabase: SupabaseManager
    private let logger = AppLogger.network

    // Channels
    private var presenceChannel: RealtimeChannelV2?
    private var collaboratorsChannel: RealtimeChannelV2?
    private var activityChannel: RealtimeChannelV2?

    // Callbacks
    private var collaboratorCallbacks: [(CollaboratorChange) -> Void] = []
    private var activityCallbacks: [(ActivityEvent) -> Void] = []

    // Reconnection
    private var reconnectTask: Task<Void, Never>?
    private let maxReconnectAttempts = 5
    private var reconnectAttempts = 0

    enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error(Error)
    }

    struct CollaboratorChange {
        let collaborator: Collaborator
        let changeType: ChangeType

        enum ChangeType {
            case insert
            case update
            case delete
        }
    }

    private init(supabase: SupabaseManager = .shared) {
        self.supabase = supabase
    }

    // MARK: - Connection Management

    func connect(coupleId: UUID) async {
        guard !isConnected else {
            logger.info("Already connected to realtime")
            return
        }

        connectionState = .connecting
        logger.info("Connecting to realtime for couple: \(coupleId.uuidString)")

        do {
            // Setup channels
            try await setupPresenceChannel(coupleId: coupleId)
            try await setupCollaboratorsChannel(coupleId: coupleId)
            try await setupActivityChannel(coupleId: coupleId)

            isConnected = true
            connectionState = .connected
            reconnectAttempts = 0

            logger.info("Successfully connected to all realtime channels")

            // Track connection in Sentry
            SentryService.shared.addBreadcrumb(
                message: "Realtime connected",
                category: "realtime",
                data: ["coupleId": coupleId.uuidString]
            )
        } catch {
            connectionState = .error(error)
            logger.error("Failed to connect to realtime", error: error)

            SentryService.shared.captureError(error, context: [
                "operation": "realtimeConnect",
                "coupleId": coupleId.uuidString
            ])

            // Attempt reconnection
            await scheduleReconnect(coupleId: coupleId)
        }
    }

    func disconnect() async {
        guard isConnected else { return }

        logger.info("Disconnecting from realtime")

        // Cancel reconnection attempts
        reconnectTask?.cancel()
        reconnectTask = nil

        // Unsubscribe from all channels
        await unsubscribeFromAllChannels()

        isConnected = false
        connectionState = .disconnected
        reconnectAttempts = 0

        logger.info("Disconnected from realtime")
    }

    private func scheduleReconnect(coupleId: UUID) async {
        guard reconnectAttempts < maxReconnectAttempts else {
            logger.error("Max reconnection attempts reached")
            return
        }

        reconnectAttempts += 1
        connectionState = .reconnecting

        let delay = min(pow(2.0, Double(reconnectAttempts)), 30.0) // Exponential backoff, max 30s
        logger.info("Scheduling reconnect attempt \(reconnectAttempts) in \(delay)s")

        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            guard !Task.isCancelled else { return }

            await connect(coupleId: coupleId)
        }
    }

    // MARK: - Presence Channel

    private func setupPresenceChannel(coupleId: UUID) async throws {
        guard let client = supabase.client else {
            throw RealtimeError.clientNotInitialized
        }

        let channelName = "presence:\(coupleId.uuidString)"
        let channel = client.realtimeV2.channel(channelName)

        // Subscribe to the channel
        try await channel.subscribe()

        presenceChannel = channel
        logger.info("Presence channel subscribed: \(channelName)")
    }

    // MARK: - Collaborators Channel

    private func setupCollaboratorsChannel(coupleId: UUID) async throws {
        guard let client = supabase.client else {
            throw RealtimeError.clientNotInitialized
        }

        let channelName = "collaborators:\(coupleId.uuidString)"
        let channel = client.realtimeV2.channel(channelName)

        // Listen for INSERT events
        _ = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "collaborators",
            filter: "couple_id=eq.\(coupleId.uuidString)"
        ) { [weak self] action in
            Task { @MainActor [weak self] in
                await self?.handleCollaboratorInsert(action)
            }
        }

        // Listen for UPDATE events
        _ = channel.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table: "collaborators",
            filter: "couple_id=eq.\(coupleId.uuidString)"
        ) { [weak self] action in
            Task { @MainActor [weak self] in
                await self?.handleCollaboratorUpdate(action)
            }
        }

        // Listen for DELETE events
        _ = channel.onPostgresChange(
            DeleteAction.self,
            schema: "public",
            table: "collaborators",
            filter: "couple_id=eq.\(coupleId.uuidString)"
        ) { [weak self] action in
            Task { @MainActor [weak self] in
                await self?.handleCollaboratorDelete(action)
            }
        }

        // Subscribe to the channel
        try await channel.subscribe()

        collaboratorsChannel = channel
        logger.info("Collaborators channel subscribed: \(channelName)")
    }

    private func handleCollaboratorInsert(_ action: InsertAction) async {
        logger.debug("Collaborator insert received")

        do {
            let collaborator = try action.decodeRecord(as: Collaborator.self, decoder: JSONDecoder())
            notifyCollaboratorCallbacks(.init(collaborator: collaborator, changeType: .insert))
        } catch {
            logger.error("Failed to decode collaborator insert", error: error)
        }
    }

    private func handleCollaboratorUpdate(_ action: UpdateAction) async {
        logger.debug("Collaborator update received")

        do {
            let collaborator = try action.decodeRecord(as: Collaborator.self, decoder: JSONDecoder())
            notifyCollaboratorCallbacks(.init(collaborator: collaborator, changeType: .update))
        } catch {
            logger.error("Failed to decode collaborator update", error: error)
        }
    }

    private func handleCollaboratorDelete(_ action: DeleteAction) async {
        logger.debug("Collaborator delete received")

        do {
            let collaborator = try action.decodeOldRecord(as: Collaborator.self, decoder: JSONDecoder())
            notifyCollaboratorCallbacks(.init(collaborator: collaborator, changeType: .delete))
        } catch {
            logger.error("Failed to decode collaborator delete", error: error)
        }
    }

    // MARK: - Activity Channel

    private func setupActivityChannel(coupleId: UUID) async throws {
        guard let client = supabase.client else {
            throw RealtimeError.clientNotInitialized
        }

        let channelName = "activity:\(coupleId.uuidString)"
        let channel = client.realtimeV2.channel(channelName)

        // Listen for INSERT events only (new activities)
        _ = channel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "activity_events",
            filter: "couple_id=eq.\(coupleId.uuidString)"
        ) { [weak self] action in
            Task { @MainActor [weak self] in
                await self?.handleActivityInsert(action)
            }
        }

        // Subscribe to the channel
        try await channel.subscribe()

        activityChannel = channel
        logger.info("Activity channel subscribed: \(channelName)")
    }

    private func handleActivityInsert(_ action: InsertAction) async {
        logger.debug("Activity insert received")

        do {
            let activity = try action.decodeRecord(as: ActivityEvent.self, decoder: JSONDecoder())
            notifyActivityCallbacks(activity)
        } catch {
            logger.error("Failed to decode activity insert", error: error)
        }
    }

    // MARK: - Callbacks

    func onCollaboratorChange(_ callback: @escaping (CollaboratorChange) -> Void) {
        collaboratorCallbacks.append(callback)
    }

    func onActivityChange(_ callback: @escaping (ActivityEvent) -> Void) {
        activityCallbacks.append(callback)
    }

    private func notifyCollaboratorCallbacks(_ change: CollaboratorChange) {
        for callback in collaboratorCallbacks {
            callback(change)
        }
    }

    private func notifyActivityCallbacks(_ activity: ActivityEvent) {
        for callback in activityCallbacks {
            callback(activity)
        }
    }

    // MARK: - Cleanup

    private func unsubscribeFromAllChannels() async {
        if let channel = presenceChannel {
            try? await channel.unsubscribe()
            presenceChannel = nil
        }

        if let channel = collaboratorsChannel {
            try? await channel.unsubscribe()
            collaboratorsChannel = nil
        }

        if let channel = activityChannel {
            try? await channel.unsubscribe()
            activityChannel = nil
        }

        // Clear callbacks
        collaboratorCallbacks.removeAll()
        activityCallbacks.removeAll()
    }
}

// MARK: - Errors

enum RealtimeError: Error, LocalizedError {
    case clientNotInitialized
    case channelSubscriptionFailed(String)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .clientNotInitialized:
            return "Supabase client not initialized"
        case .channelSubscriptionFailed(let channel):
            return "Failed to subscribe to channel: \(channel)"
        case .decodingFailed(let error):
            return "Failed to decode realtime payload: \(error.localizedDescription)"
        }
    }
}
