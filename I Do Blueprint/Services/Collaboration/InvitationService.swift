//
//  InvitationService.swift
//  I Do Blueprint
//
//  Lightweight service to prefetch invitation details for deep links.
//

import Foundation

@MainActor
final class InvitationService {
    static let shared = InvitationService()
    private init() {}

    /// Fetch invitation details by token using the collaboration repository
    func fetchInvitation(token: String) async throws -> InvitationDetails {
        // Use a throwaway store to access the injected repository
        let store = CollaborationStoreV2()
        return try await store.repository.fetchInvitationByToken(token)
    }
}
