//
//  AuthContext.swift
//  I Do Blueprint
//
//  Created by Plan on 10/13/25.
//  Provides authenticated user and couple context throughout the app
//

import Foundation
import Combine

/// Provides authenticated user and couple context throughout the app
@MainActor
class AuthContext: ObservableObject {
    static let shared = AuthContext()

    @Published private(set) var currentUserId: UUID?
    @Published private(set) var currentUserEmail: String?
    @Published private(set) var currentCoupleId: UUID?
    @Published private(set) var isAuthenticated: Bool = false

    private let sessionManager = SessionManager.shared
    private let supabaseManager = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Initialize from session
        refresh()

        // Observe authentication state changes
        supabaseManager.$isAuthenticated
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.refresh()
                }
            }
            .store(in: &cancellables)
    }

    /// Refresh auth context from session
    func refresh() {
        isAuthenticated = supabaseManager.isAuthenticated

        if isAuthenticated {
            currentCoupleId = sessionManager.getTenantId()
            currentUserId = supabaseManager.currentUserId
            currentUserEmail = supabaseManager.currentUserEmail
            // Seed thread-safe user context for background actors
            Task {
                do {
                    try await UserContextProvider.shared.set(userId: currentUserId, email: currentUserEmail)
                } catch {
                    AppLogger.auth.error("Failed to seed user context", error: error)
                }
            }
        } else {
            currentCoupleId = nil
            currentUserId = nil
            currentUserEmail = nil
            Task {
                do {
                    try await UserContextProvider.shared.clear()
                } catch {
                    AppLogger.auth.error("Failed to clear user context", error: error)
                }
            }
        }
    }

    /// Get current couple ID or throw error
    func requireCoupleId() throws -> UUID {
        guard let coupleId = currentCoupleId else {
            throw AuthContextError.noCoupleId
        }
        return coupleId
    }

    /// Get current user ID or throw error
    func requireUserId() throws -> UUID {
        guard let userId = currentUserId else {
            throw AuthContextError.noUserId
        }
        return userId
    }

    /// Get current user email or throw error
    func requireUserEmail() throws -> String {
        guard let email = currentUserEmail else {
            throw AuthContextError.noUserEmail
        }
        return email
    }
}

enum AuthContextError: LocalizedError {
    case noCoupleId
    case noUserId
    case noUserEmail

    var errorDescription: String? {
        switch self {
        case .noCoupleId:
            return "No couple ID found. Please sign in again."
        case .noUserId:
            return "No user ID found. Please sign in again."
        case .noUserEmail:
            return "No user email found. Please sign in again."
        }
    }
}
