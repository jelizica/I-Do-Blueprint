//
//  CollaborationPermissionService.swift
//  I Do Blueprint
//
//  Domain service for collaboration permission checks and role management
//

import Foundation
import Supabase

/// Actor-based service handling permission and role business logic
actor CollaborationPermissionService {
    private let supabase: SupabaseClient
    private nonisolated let logger = AppLogger.repository
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // MARK: - Permission Checks
    
    /// Check if current user has a specific permission
    func hasPermission(_ permission: String, coupleId: UUID) async throws -> Bool {
        let startTime = Date()
        
        struct PermissionParams: Encodable {
            let p_couple_id: UUID
            let p_permission: String
        }
        
        let params = PermissionParams(p_couple_id: coupleId, p_permission: permission)
        
        let result: [[String: Bool]] = try await RepositoryNetwork.withRetry { [self] in
            try await supabase
                .rpc("user_has_permission", params: params)
                .execute()
                .value
        }
        
        let duration = Date().timeIntervalSince(startTime)
        await PerformanceMonitor.shared.recordOperation("hasPermission", duration: duration)
        
        let hasPermission = result.first?["result"] ?? false
        logger.info("Permission check '\(permission)': \(hasPermission)")
        
        return hasPermission
    }
    
    /// Get current user's role for a couple
    func getCurrentUserRole(coupleId: UUID, userId: UUID) async throws -> RoleName? {
        let startTime = Date()
        
        // Query collaborator and join with role to get role name
        let collaborators: [Collaborator] = try await RepositoryNetwork.withRetry { [self] in
            try await supabase
                .from("collaborators")
                .select("*, collaboration_roles(*)")
                .eq("couple_id", value: coupleId)
                .eq("user_id", value: userId)
                .eq("status", value: "active")
                .limit(1)
                .execute()
                .value
        }
        
        let duration = Date().timeIntervalSince(startTime)
        await PerformanceMonitor.shared.recordOperation("getCurrentUserRole", duration: duration)
        
        if let collaborator = collaborators.first {
            // Fetch role details
            let role = try await fetchRole(id: collaborator.roleId)
            logger.info("Current user role: \(role.roleName.displayName)")
            return role.roleName
        }
        
        logger.info("No role found for current user")
        return nil
    }
    
    /// Check if user can leave collaboration (not last owner)
    func canLeaveCollaboration(coupleId: UUID, userId: UUID) async throws -> Bool {
        let owners: [Collaborator] = try await RepositoryNetwork.withRetry { [self] in
            try await supabase
                .from("collaborators")
                .select("*, collaboration_roles!inner(role_name)")
                .eq("couple_id", value: coupleId)
                .eq("status", value: "active")
                .eq("collaboration_roles.role_name", value: "owner")
                .execute()
                .value
        }
        
        let isUserOwner = owners.contains { $0.userId == userId }
        
        // User can leave if they're not an owner, or if there are multiple owners
        return !isUserOwner || owners.count > 1
    }
    
    // MARK: - Role Operations
    
    /// Fetch all available roles
    func fetchRoles() async throws -> [CollaborationRole] {
        let cacheKey = "collaboration_roles"
        let startTime = Date()
        
        // Check cache first (roles rarely change)
        if let cached: [CollaborationRole] = await RepositoryCache.shared.get(cacheKey, maxAge: 3600) {
            logger.info("Cache hit: collaboration roles")
            return cached
        }
        
        logger.info("Cache miss: fetching collaboration roles from database")
        
        let roles: [CollaborationRole] = try await RepositoryNetwork.withRetry { [self] in
            try await supabase
                .from("collaboration_roles")
                .select()
                .execute()
                .value
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Cache for 1 hour (roles are system-wide and rarely change)
        await RepositoryCache.shared.set(cacheKey, value: roles, ttl: 3600)
        
        await PerformanceMonitor.shared.recordOperation("fetchRoles", duration: duration)
        
        logger.info("Fetched \(roles.count) roles in \(String(format: "%.2f", duration))s")
        
        return roles
    }
    
    /// Update collaborator's role
    func updateCollaboratorRole(
        collaboratorId: UUID,
        roleId: UUID,
        coupleId: UUID
    ) async throws {
        let startTime = Date()
        
        struct UpdatePayload: Encodable {
            let role_id: UUID
            let updated_at: Date
        }
        
        let updates = UpdatePayload(
            role_id: roleId,
            updated_at: Date()
        )
        
        _ = try await RepositoryNetwork.withRetry { [self] in
            try await supabase
                .from("collaborators")
                .update(updates)
                .eq("id", value: collaboratorId)
                .eq("couple_id", value: coupleId)
                .execute()
        }
        
        let duration = Date().timeIntervalSince(startTime)
        await PerformanceMonitor.shared.recordOperation("updateCollaboratorRole", duration: duration)
        
        logger.info("Updated collaborator role in \(String(format: "%.2f", duration))s")
    }
    
    // MARK: - Private Helpers
    
    private func fetchRole(id: UUID) async throws -> CollaborationRole {
        let roles = try await fetchRoles()
        guard let role = roles.first(where: { $0.id == id }) else {
            throw CollaborationError.roleNotFound
        }
        return role
    }
}
