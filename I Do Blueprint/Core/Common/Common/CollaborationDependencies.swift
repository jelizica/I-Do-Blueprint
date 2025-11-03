//
//  CollaborationDependencies.swift
//  I Do Blueprint
//
//  Dependency injection configuration for collaboration repositories
//

import Dependencies
import Foundation

// MARK: - Singleton Repository Instances

/// Singleton container for live collaboration repository instances
/// Prevents creating new instances on every dependency access
enum LiveCollaborationRepositories {
    static let collaboration: any CollaborationRepositoryProtocol = LiveCollaborationRepository()
    static let presence: any PresenceRepositoryProtocol = LivePresenceRepository()
    static let activityFeed: any ActivityFeedRepositoryProtocol = LiveActivityFeedRepository()
}

// MARK: - Dependency Keys

/// Dependency key for CollaborationRepository
private enum CollaborationRepositoryKey: DependencyKey {
    static let liveValue: any CollaborationRepositoryProtocol = LiveCollaborationRepositories.collaboration
    static let testValue: any CollaborationRepositoryProtocol = LiveCollaborationRepositories.collaboration
    static let previewValue: any CollaborationRepositoryProtocol = LiveCollaborationRepositories.collaboration
}

/// Dependency key for PresenceRepository
private enum PresenceRepositoryKey: DependencyKey {
    static let liveValue: any PresenceRepositoryProtocol = LiveCollaborationRepositories.presence
    static let testValue: any PresenceRepositoryProtocol = LiveCollaborationRepositories.presence
    static let previewValue: any PresenceRepositoryProtocol = LiveCollaborationRepositories.presence
}

/// Dependency key for ActivityFeedRepository
private enum ActivityFeedRepositoryKey: DependencyKey {
    static let liveValue: any ActivityFeedRepositoryProtocol = LiveCollaborationRepositories.activityFeed
    static let testValue: any ActivityFeedRepositoryProtocol = LiveCollaborationRepositories.activityFeed
    static let previewValue: any ActivityFeedRepositoryProtocol = LiveCollaborationRepositories.activityFeed
}

// MARK: - Dependency Extensions

extension DependencyValues {
    /// Access the collaboration repository dependency
    /// - In production: Returns LiveCollaborationRepository with Supabase
    /// - In tests: Returns MockCollaborationRepository with in-memory storage
    /// - In previews: Returns MockCollaborationRepository with sample data
    var collaborationRepository: any CollaborationRepositoryProtocol {
        get { self[CollaborationRepositoryKey.self] }
        set { self[CollaborationRepositoryKey.self] = newValue }
    }

    /// Access the presence repository dependency
    /// - In production: Returns LivePresenceRepository with Supabase
    /// - In tests: Returns MockPresenceRepository with in-memory storage
    /// - In previews: Returns MockPresenceRepository with sample data
    var presenceRepository: any PresenceRepositoryProtocol {
        get { self[PresenceRepositoryKey.self] }
        set { self[PresenceRepositoryKey.self] = newValue }
    }

    /// Access the activity feed repository dependency
    /// - In production: Returns LiveActivityFeedRepository with Supabase
    /// - In tests: Returns MockActivityFeedRepository with in-memory storage
    /// - In previews: Returns MockActivityFeedRepository with sample data
    var activityFeedRepository: any ActivityFeedRepositoryProtocol {
        get { self[ActivityFeedRepositoryKey.self] }
        set { self[ActivityFeedRepositoryKey.self] = newValue }
    }
}

// MARK: - Usage Examples

/*

 // In a Store:
 @Dependency(\.collaborationRepository) var repository
 @Dependency(\.presenceRepository) var presenceRepository
 @Dependency(\.activityFeedRepository) var activityFeedRepository

 // In tests:
 await withDependencies {
     let mockRepo = MockCollaborationRepository()
     mockRepo.collaborators = [.makeTest(email: "partner@example.com")]
     $0.collaborationRepository = mockRepo
 } operation: {
     let store = CollaborationStoreV2()
     await store.loadCollaborators()
     XCTAssertEqual(store.collaborators.count, 1)
 }

 // Override in previews:
 #Preview {
     withDependencies {
         let mockRepo = MockCollaborationRepository()
         mockRepo.collaborators = [
             .makeTest(email: "partner@example.com", status: .active),
             .makeTest(email: "planner@example.com", status: .active)
         ]
         $0.collaborationRepository = mockRepo
     } operation: {
         CollaboratorListView()
     }
 }

 */
