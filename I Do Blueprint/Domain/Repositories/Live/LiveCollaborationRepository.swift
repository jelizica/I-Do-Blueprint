//
//  LiveCollaborationRepository.swift
//  I Do Blueprint
//
//  Production implementation of CollaborationRepositoryProtocol with caching
//  Delegates complex business logic to domain services
//

import Foundation
import Supabase

/// Production implementation of CollaborationRepositoryProtocol
actor LiveCollaborationRepository: CollaborationRepositoryProtocol {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.repository
    
    // Domain services for complex business logic
    private lazy var invitationService: CollaborationInvitationService? = {
        guard let client = supabase else { return nil }
        return CollaborationInvitationService(supabase: client)
    }()
    
    private lazy var permissionService: CollaborationPermissionService? = {
        guard let client = supabase else { return nil }
        return CollaborationPermissionService(supabase: client)
    }()
    
    init(supabase: SupabaseClient? = nil) {
        self.supabase = supabase
    }
    
    convenience init() {
        self.init(supabase: SupabaseManager.shared.client)
    }
    
    private func getClient() throws -> SupabaseClient {
        guard let supabase = supabase else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        return supabase
    }
    
    private func getTenantId() async throws -> UUID {
        try await TenantContextProvider.shared.requireTenantId()
    }
    
    private func getUserId() async throws -> UUID {
        try await UserContextProvider.shared.requireUserId()
    }
    
    // MARK: - Fetch Operations
    
    func fetchCollaborators() async throws -> [Collaborator] {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let cacheKey = "collaborators_\(tenantId.uuidString)"
            let startTime = Date()
            
            // Check cache first
            if let cached: [Collaborator] = await RepositoryCache.shared.get(cacheKey, maxAge: 60) {
                logger.info("Cache hit: collaborators (\(cached.count) items)")
                return cached
            }
            
            logger.info("Cache miss: fetching collaborators from database")
            
            // Fetch from Supabase with retry
            let collaborators: [Collaborator] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("collaborators")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            // Cache the results
            await RepositoryCache.shared.set(cacheKey, value: collaborators, ttl: 60)
            
            // Record performance
            await PerformanceMonitor.shared.recordOperation("fetchCollaborators", duration: duration)
            
            logger.info("Fetched \(collaborators.count) collaborators in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "fetchCollaborators", outcome: .success, duration: duration)
            
            return collaborators
        } catch {
            logger.error("Failed to fetch collaborators", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchCollaborators"
            ])
            throw CollaborationError.fetchFailed(underlying: error)
        }
    }
    
    func fetchRoles() async throws -> [CollaborationRole] {
        guard let service = permissionService else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        
        do {
            return try await service.fetchRoles()
        } catch {
            logger.error("Failed to fetch roles", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchRoles"
            ])
            throw CollaborationError.fetchFailed(underlying: error)
        }
    }
    
    func fetchCollaborator(id: UUID) async throws -> Collaborator {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()
            
            let collaborator: Collaborator = try await RepositoryNetwork.withRetry {
                try await client
                    .from("collaborators")
                    .select()
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId)
                    .single()
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("fetchCollaborator", duration: duration)
            
            logger.info("Fetched collaborator in \(String(format: "%.2f", duration))s")
            
            return collaborator
        } catch {
            logger.error("Failed to fetch collaborator", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchCollaborator",
                "collaboratorId": id.uuidString
            ])
            throw CollaborationError.fetchFailed(underlying: error)
        }
    }
    
    func fetchCurrentUserCollaborator() async throws -> Collaborator? {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let userId = try await getUserId()
            let startTime = Date()
            
            let collaborators: [Collaborator] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("collaborators")
                    .select()
                    .eq("couple_id", value: tenantId)
                    .eq("user_id", value: userId)
                    .eq("status", value: "active")
                    .limit(1)
                    .execute()
                    .value
            }
            
            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("fetchCurrentUserCollaborator", duration: duration)
            
            if let collaborator = collaborators.first {
                logger.info("Fetched current user collaborator in \(String(format: "%.2f", duration))s")
                return collaborator
            } else {
                logger.info("No collaborator record found for current user")
                return nil
            }
        } catch {
            logger.error("Failed to fetch current user collaborator", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchCurrentUserCollaborator"
            ])
            throw CollaborationError.fetchFailed(underlying: error)
        }
    }
    
    func fetchInvitationByToken(_ token: String) async throws -> InvitationDetails {
        guard let service = invitationService else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        
        do {
            return try await service.fetchInvitationByToken(token)
        } catch let error as CollaborationError {
            throw error
        } catch {
            logger.error("Failed to fetch invitation by token", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchInvitationByToken"
            ])
            throw CollaborationError.fetchFailed(underlying: error)
        }
    }
    
    // MARK: - Create, Update, Delete Operations
    
    func inviteCollaborator(email: String, roleId: UUID, displayName: String?) async throws -> Collaborator {
        guard let service = invitationService else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        
        do {
            let tenantId = try await getTenantId()
            let userId = try await getUserId()
            
            let invitation = try await service.createInvitation(
                email: email,
                roleId: roleId,
                displayName: displayName,
                coupleId: tenantId,
                invitedBy: userId
            )
            
            // Invalidate invitations cache
            await RepositoryCache.shared.remove("invitations_\(tenantId.uuidString)")
            
            // Return a temporary collaborator representation for UI compatibility
            return Collaborator(
                id: invitation.id,
                createdAt: invitation.createdAt,
                updatedAt: invitation.updatedAt,
                coupleId: invitation.coupleId,
                userId: UUID(), // Placeholder - will be set on acceptance
                roleId: invitation.roleId,
                invitedBy: invitation.invitedBy,
                invitedAt: invitation.invitedAt,
                acceptedAt: nil,
                status: .pending,
                email: invitation.email,
                displayName: invitation.displayName,
                avatarUrl: nil,
                lastSeenAt: nil
            )
        } catch {
            logger.error("Failed to invite collaborator", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "inviteCollaborator",
                "email": email
            ])
            throw CollaborationError.createFailed(underlying: error)
        }
    }
    
    func acceptInvitation(id: UUID) async throws -> Collaborator {
        guard let service = invitationService else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        
        do {
            let result = try await service.acceptInvitation(id: id)
            
            // Construct Collaborator from result
            let collaborator = Collaborator(
                id: result.collaboratorId,
                createdAt: Date(),
                updatedAt: Date(),
                coupleId: result.coupleId,
                userId: result.userId,
                roleId: result.roleId,
                invitedBy: result.userId,
                invitedAt: Date(),
                acceptedAt: Date(),
                status: .active,
                email: result.email,
                displayName: result.displayName,
                avatarUrl: nil,
                lastSeenAt: nil
            )
            
            // Invalidate caches
            await RepositoryCache.shared.remove("collaborators_\(result.coupleId.uuidString)")
            await RepositoryCache.shared.remove("invitations_\(result.coupleId.uuidString)")
            
            return collaborator
        } catch let error as CollaborationError {
            throw error
        } catch {
            logger.error("Failed to accept invitation", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "acceptInvitation",
                "invitationId": id.uuidString
            ])
            throw CollaborationError.updateFailed(underlying: error)
        }
    }
    
    func updateCollaboratorRole(id: UUID, roleId: UUID) async throws -> Collaborator {
        guard let service = permissionService else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            
            // Update role via service
            try await service.updateCollaboratorRole(
                collaboratorId: id,
                roleId: roleId,
                coupleId: tenantId
            )
            
            // Fetch updated collaborator
            let updated: Collaborator = try await RepositoryNetwork.withRetry {
                try await client
                    .from("collaborators")
                    .select()
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId)
                    .single()
                    .execute()
                    .value
            }
            
            // Invalidate cache
            await RepositoryCache.shared.remove("collaborators_\(tenantId.uuidString)")
            
            logger.info("Updated collaborator role")
            
            return updated
        } catch {
            logger.error("Failed to update collaborator role", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "updateCollaboratorRole",
                "collaboratorId": id.uuidString
            ])
            throw CollaborationError.updateFailed(underlying: error)
        }
    }
    
    func removeCollaborator(id: UUID) async throws {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()
            
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("collaborators")
                    .delete()
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId)
                    .execute()
            }
            
            // Invalidate cache
            await RepositoryCache.shared.remove("collaborators_\(tenantId.uuidString)")
            
            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("removeCollaborator", duration: duration)
            
            logger.info("Removed collaborator in \(String(format: "%.2f", duration))s")
        } catch {
            logger.error("Failed to remove collaborator", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "removeCollaborator",
                "collaboratorId": id.uuidString
            ])
            throw CollaborationError.deleteFailed(underlying: error)
        }
    }
    
    func fetchUserCollaborations() async throws -> [UserCollaboration] {
        do {
            let client = try getClient()
            let userId = try await getUserId()
            let startTime = Date()
            
            // Check cache first (5 minute TTL for user collaborations)
            let cacheKey = "user_collaborations_\(userId.uuidString)"
            if let cached: [UserCollaboration] = await RepositoryCache.shared.get(cacheKey, maxAge: 300) {
                logger.info("Cache hit: user collaborations (\(cached.count) items)")
                return cached
            }
            
            logger.info("Cache miss: fetching all collaborations for user")
            
            // Fetch collaborators
            let collaboratorRows = try await fetchCollaboratorRows(userId: userId, client: client)
            
            // Fetch couple profiles
            let coupleProfiles = try await fetchCoupleProfiles(
                coupleIds: collaboratorRows.map { $0.couple_id },
                client: client
            )
            
            // Fetch roles
            let roles = try await fetchRoleMap(
                roleIds: collaboratorRows.map { $0.role_id },
                client: client
            )
            
            // Identify owner couples
            let ownerRoleId = roles.first(where: { $0.value == "owner" })?.key
            let couplesWhereUserIsOwner = Set(
                collaboratorRows
                    .filter { $0.role_id == ownerRoleId }
                    .map { $0.couple_id }
            )
            
            logger.info("User is owner of \(couplesWhereUserIsOwner.count) couples")
            
            // Build collaborations
            var collaborations = buildUserCollaborations(
                rows: collaboratorRows,
                coupleProfiles: coupleProfiles,
                roles: roles,
                ownerCouples: couplesWhereUserIsOwner
            )
            
            // Sort by wedding date
            collaborations.sort { lhs, rhs in
                switch (lhs.weddingDate, rhs.weddingDate) {
                case (nil, nil): return false
                case (nil, _): return false
                case (_, nil): return true
                case (let date1?, let date2?): return date1 < date2
                }
            }
            
            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("fetchUserCollaborations", duration: duration)
            
            // Cache the results
            await RepositoryCache.shared.set(cacheKey, value: collaborations, ttl: 300)
            
            logger.info("Fetched \(collaborations.count) collaborations in \(String(format: "%.2f", duration))s")
            
            return collaborations
        } catch {
            logger.error("Failed to fetch user collaborations", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "fetchUserCollaborations"
            ])
            throw CollaborationError.fetchFailed(underlying: error)
        }
    }
    
    func leaveCollaboration(coupleId: UUID) async throws {
        guard let service = permissionService else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        
        do {
            let client = try getClient()
            let userId = try await getUserId()
            let startTime = Date()
            
            logger.info("User leaving collaboration for couple: \(coupleId.uuidString)")
            
            // Check if user can leave
            let canLeave = try await service.canLeaveCollaboration(coupleId: coupleId, userId: userId)
            
            guard canLeave else {
                logger.warning("Cannot leave - user is the last owner")
                throw CollaborationError.lastOwnerCannotLeave
            }
            
            // Delete the collaborator record
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("collaborators")
                    .delete()
                    .eq("couple_id", value: coupleId)
                    .eq("user_id", value: userId)
                    .execute()
            }
            
            // Invalidate cache
            await RepositoryCache.shared.remove("collaborators_\(coupleId.uuidString)")
            
            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("leaveCollaboration", duration: duration)
            
            logger.info("Left collaboration in \(String(format: "%.2f", duration))s")
            
            await SentryService.shared.trackAction(
                "collaboration_left",
                category: "collaboration",
                metadata: [
                    "couple_id": coupleId.uuidString,
                    "user_id": userId.uuidString
                ]
            )
        } catch let error as CollaborationError {
            throw error
        } catch {
            logger.error("Failed to leave collaboration", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "leaveCollaboration",
                "coupleId": coupleId.uuidString
            ])
            throw CollaborationError.deleteFailed(underlying: error)
        }
    }
    
    func declineInvitation(id: UUID) async throws {
        guard let service = invitationService else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        
        do {
            try await service.declineInvitation(id: id)
        } catch {
            logger.error("Failed to decline invitation", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "declineInvitation",
                "invitationId": id.uuidString
            ])
            throw CollaborationError.updateFailed(underlying: error)
        }
    }
    
    // MARK: - Permission Checks
    
    func hasPermission(_ permission: String) async throws -> Bool {
        guard let service = permissionService else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        
        do {
            let tenantId = try await getTenantId()
            return try await service.hasPermission(permission, coupleId: tenantId)
        } catch {
            logger.error("Failed to check permission", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "hasPermission",
                "permission": permission
            ])
            throw CollaborationError.fetchFailed(underlying: error)
        }
    }
    
    func getCurrentUserRole() async throws -> RoleName? {
        guard let service = permissionService else {
            throw SupabaseManager.shared.configurationError ?? ConfigurationError.configFileUnreadable
        }
        
        do {
            let tenantId = try await getTenantId()
            let userId = try await getUserId()
            return try await service.getCurrentUserRole(coupleId: tenantId, userId: userId)
        } catch {
            logger.error("Failed to get current user role", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "getCurrentUserRole"
            ])
            throw CollaborationError.fetchFailed(underlying: error)
        }
    }
    
    // MARK: - Onboarding Support
    
    func createOwnerCollaborator(
        coupleId: UUID,
        userId: UUID,
        email: String,
        displayName: String?
    ) async throws -> Collaborator {
        do {
            let client = try getClient()
            let startTime = Date()
            
            logger.info("Creating owner collaborator for couple: \(coupleId.uuidString)")
            
            // Check if collaborator already exists (idempotency)
            let existing: [Collaborator] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("collaborators")
                    .select()
                    .eq("couple_id", value: coupleId)
                    .eq("user_id", value: userId)
                    .limit(1)
                    .execute()
                    .value
            }
            
            if let existingCollaborator = existing.first {
                logger.info("Owner collaborator already exists, returning existing record")
                return existingCollaborator
            }
            
            // Call database function with SECURITY DEFINER to bypass RLS
            struct FunctionParams: Encodable {
                let p_couple_id: UUID
                let p_user_id: UUID
                let p_email: String
                let p_display_name: String?
            }
            
            let params = FunctionParams(
                p_couple_id: coupleId,
                p_user_id: userId,
                p_email: email,
                p_display_name: displayName
            )
            
            let collaborators: [Collaborator] = try await RepositoryNetwork.withRetry {
                try await client
                    .rpc("create_owner_collaborator", params: params)
                    .execute()
                    .value
            }
            
            guard let created = collaborators.first else {
                throw CollaborationError.createFailed(underlying: NSError(
                    domain: "LiveCollaborationRepository",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Function returned no collaborator"]
                ))
            }
            
            // Invalidate cache
            await RepositoryCache.shared.remove("collaborators_\(coupleId.uuidString)")
            
            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("createOwnerCollaborator", duration: duration)
            
            logger.info("Created owner collaborator in \(String(format: "%.2f", duration))s")
            
            await SentryService.shared.trackAction(
                "owner_collaborator_created",
                category: "onboarding",
                metadata: [
                    "couple_id": coupleId.uuidString,
                    "user_id": userId.uuidString,
                    "has_display_name": displayName != nil
                ]
            )
            
            return created
        } catch let error as CollaborationError {
            throw error
        } catch {
            logger.error("Failed to create owner collaborator", error: error)
            await SentryService.shared.captureError(error, context: [
                "operation": "createOwnerCollaborator",
                "couple_id": coupleId.uuidString,
                "user_id": userId.uuidString
            ])
            throw CollaborationError.createFailed(underlying: error)
        }
    }
    
    // MARK: - Private Helpers
    
    private struct CollaboratorRow: Decodable {
        let id: UUID
        let couple_id: UUID
        let role_id: UUID
        let status: String
        let invited_by: UUID?
        let invited_at: Date
        let accepted_at: Date?
        let last_seen_at: Date?
        let email: String
    }
    
    private func fetchCollaboratorRows(userId: UUID, client: SupabaseClient) async throws -> [CollaboratorRow] {
        try await RepositoryNetwork.withRetry {
            try await client
                .from("collaborators")
                .select("id, couple_id, role_id, status, invited_by, invited_at, accepted_at, last_seen_at, email")
                .eq("user_id", value: userId)
                .order("invited_at", ascending: false)
                .execute()
                .value
        }
    }
    
    private struct CoupleProfileRow: Decodable {
        let id: UUID
        let partner1_name: String
        let partner2_name: String?
        let wedding_date: String?
        
        var parsedWeddingDate: Date? {
            guard let dateString = wedding_date else { return nil }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            return formatter.date(from: dateString)
        }
    }
    
    private func fetchCoupleProfiles(
        coupleIds: [UUID],
        client: SupabaseClient
    ) async throws -> [UUID: (partner1: String, partner2: String?, weddingDate: Date?)] {
        guard !coupleIds.isEmpty else { return [:] }
        
        let profiles: [CoupleProfileRow] = try await RepositoryNetwork.withRetry {
            try await client
                .from("couple_profiles")
                .select("id, partner1_name, partner2_name, wedding_date")
                .in("id", values: coupleIds)
                .execute()
                .value
        }
        
        var result: [UUID: (partner1: String, partner2: String?, weddingDate: Date?)] = [:]
        for profile in profiles {
            result[profile.id] = (profile.partner1_name, profile.partner2_name, profile.parsedWeddingDate)
        }
        
        return result
    }
    
    private struct RoleRow: Decodable {
        let id: UUID
        let role_name: String
    }
    
    private func fetchRoleMap(roleIds: [UUID], client: SupabaseClient) async throws -> [UUID: String] {
        guard !roleIds.isEmpty else { return [:] }
        
        let roleRows: [RoleRow] = try await RepositoryNetwork.withRetry {
            try await client
                .from("collaboration_roles")
                .select("id, role_name")
                .in("id", values: roleIds)
                .execute()
                .value
        }
        
        var result: [UUID: String] = [:]
        for role in roleRows {
            result[role.id] = role.role_name
        }
        
        return result
    }
    
    private func buildUserCollaborations(
        rows: [CollaboratorRow],
        coupleProfiles: [UUID: (partner1: String, partner2: String?, weddingDate: Date?)],
        roles: [UUID: String],
        ownerCouples: Set<UUID>
    ) -> [UserCollaboration] {
        rows.compactMap { row in
            guard let coupleProfile = coupleProfiles[row.couple_id],
                  let roleNameString = roles[row.role_id],
                  let roleName = RoleName(rawValue: roleNameString),
                  let status = CollaboratorStatus(rawValue: row.status) else {
                logger.warning("Missing data for collaborator \(row.id.uuidString)")
                return nil
            }
            
            // Skip ALL collaborations for couples where user is an owner
            if ownerCouples.contains(row.couple_id) {
                logger.info("Skipping collaboration for couple \(row.couple_id.uuidString) - user is owner")
                return nil
            }
            
            let coupleName = [coupleProfile.partner1, coupleProfile.partner2]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " & ")
            
            return UserCollaboration(
                id: row.id,
                coupleId: row.couple_id,
                coupleName: coupleName,
                weddingDate: coupleProfile.weddingDate,
                role: roleName,
                status: status,
                invitedBy: nil,
                invitedAt: row.invited_at,
                acceptedAt: row.accepted_at,
                lastSeenAt: row.last_seen_at
            )
        }
    }
}

// MARK: - Collaboration Errors

enum CollaborationError: Error, LocalizedError {
    case fetchFailed(underlying: Error)
    case createFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case deleteFailed(underlying: Error)
    case roleNotFound
    case permissionDenied
    case tenantContextMissing
    case invitationNotFound
    case invitationExpired
    case lastOwnerCannotLeave
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch collaboration data: \(error.localizedDescription)"
        case .createFailed(let error):
            return "Failed to create collaborator: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update collaborator: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to remove collaborator: \(error.localizedDescription)"
        case .roleNotFound:
            return "Role not found"
        case .permissionDenied:
            return "Permission denied"
        case .tenantContextMissing:
            return "No couple selected. Please sign in."
        case .invitationNotFound:
            return "Invitation not found or already accepted"
        case .invitationExpired:
            return "This invitation has expired. Please request a new one."
        case .lastOwnerCannotLeave:
            return "Cannot leave - you are the last owner. Please assign another owner first."
        }
    }
}
