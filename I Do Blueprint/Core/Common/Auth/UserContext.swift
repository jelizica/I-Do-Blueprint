//
//  UserContext.swift
//  I Do Blueprint
//
//  Thread-safe user context accessible from any actor
//

import Foundation

enum UserContextError: LocalizedError {
    case noUserId
    case noUserEmail
    
    var errorDescription: String? {
        switch self {
        case .noUserId: return "No user ID available. Please sign in again."
        case .noUserEmail: return "No user email available. Please sign in again."
        }
    }
}

actor UserContextProvider {
    static let shared = UserContextProvider()
    
    private var currentUserId: UUID?
    private var currentUserEmail: String?
    
    func set(userId: UUID?, email: String?) {
        self.currentUserId = userId
        self.currentUserEmail = email
    }
    
    func getUserId() -> UUID? { currentUserId }
    func getUserEmail() -> String? { currentUserEmail }
    
    func requireUserId() throws -> UUID {
        guard let id = currentUserId else { throw UserContextError.noUserId }
        return id
    }
    
    func requireUserEmail() throws -> String {
        guard let email = currentUserEmail else { throw UserContextError.noUserEmail }
        return email
    }
    
    func clear() {
        currentUserId = nil
        currentUserEmail = nil
    }
}
