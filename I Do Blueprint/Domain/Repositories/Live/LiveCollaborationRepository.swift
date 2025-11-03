//
//  LiveCollaborationRepository.swift
//  I Do Blueprint
//
//  Production implementation of CollaborationRepositoryProtocol with caching
//

import Foundation
import Supabase

/// Production implementation of CollaborationRepositoryProtocol
actor LiveCollaborationRepository: CollaborationRepositoryProtocol {
    private let supabase: SupabaseClient?
    private let logger = AppLogger.repository

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
        do {
            let client = try getClient()
            let cacheKey = "collaboration_roles"
            let startTime = Date()

            // Check cache first (roles rarely change)
            if let cached: [CollaborationRole] = await RepositoryCache.shared.get(cacheKey, maxAge: 3600) {
                logger.info("Cache hit: collaboration roles")
                return cached
            }

            logger.info("Cache miss: fetching collaboration roles from database")

            // Fetch from Supabase
            let roles: [CollaborationRole] = try await RepositoryNetwork.withRetry {
                try await client
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

            // Query for collaborator - may return empty array if user is not a collaborator
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
        do {
            let client = try getClient()
            let startTime = Date()

            logger.info("Fetching invitation by token")

            // Query invitation table (no tenant filtering - token is globally unique)
            let invitations: [Invitation] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("invitations")
                    .select()
                    .eq("token", value: token)
                    .eq("status", value: "pending")
                    .limit(1)
                    .execute()
                    .value
            }

            guard let invitation = invitations.first else {
                logger.warning("Invitation not found or already accepted for token")
                throw CollaborationError.invitationNotFound
            }

            // Check if expired
            if invitation.isExpired {
                logger.warning("Invitation has expired")
                throw CollaborationError.invitationExpired
            }

            // Fetch role
            let roles = try await fetchRoles()
            guard let role = roles.first(where: { $0.id == invitation.roleId }) else {
                logger.error("Role not found for invitation")
                throw CollaborationError.roleNotFound
            }

            // Fetch couple name from couple_settings table
            // Note: Partner names are stored in the JSONB 'settings' field, not as columns
            struct CoupleSettingsRow: Decodable {
                let settings: CoupleSettingsJSON
            }

            struct CoupleSettingsJSON: Decodable {
                let global: GlobalSettingsJSON?
            }

            struct GlobalSettingsJSON: Decodable {
                let partner1FullName: String?
                let partner2FullName: String?
                let partner1Nickname: String?
                let partner2Nickname: String?

                enum CodingKeys: String, CodingKey {
                    case partner1FullName = "partner1_full_name"
                    case partner2FullName = "partner2_full_name"
                    case partner1Nickname = "partner1_nickname"
                    case partner2Nickname = "partner2_nickname"
                }
            }

            let settingsRows: [CoupleSettingsRow] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("couple_settings")
                    .select("settings")
                    .eq("couple_id", value: invitation.coupleId)
                    .limit(1)
                    .execute()
                    .value
            }

            let coupleName: String?
            if let settingsRow = settingsRows.first,
               let global = settingsRow.settings.global {
                // Use nickname if available, otherwise use full name
                let p1 = global.partner1Nickname?.isEmpty == false ? global.partner1Nickname : global.partner1FullName
                let p2 = global.partner2Nickname?.isEmpty == false ? global.partner2Nickname : global.partner2FullName
                coupleName = [p1, p2].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " & ")
            } else {
                coupleName = nil
            }

            // Fetch inviter email from auth.users (optional)
            let inviterEmail: String? = nil // We can't easily query auth.users from client

            let details = InvitationDetails(
                invitation: invitation,
                role: role,
                coupleId: invitation.coupleId,
                coupleName: coupleName,
                inviterEmail: inviterEmail
            )

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("fetchInvitationByToken", duration: duration)

            logger.info("Fetched invitation details in \(String(format: "%.2f", duration))s")

            return details
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

    // Helper to fetch couple display name from couple_settings
    private func fetchCoupleName(tenantId: UUID, client: SupabaseClient) async throws -> String? {
        struct CoupleSettingsRow: Decodable { let settings: CoupleSettingsJSON }
        struct CoupleSettingsJSON: Decodable { let global: GlobalSettingsJSON? }
        struct GlobalSettingsJSON: Decodable {
            let partner1FullName: String?; let partner2FullName: String?; let partner1Nickname: String?; let partner2Nickname: String?
            enum CodingKeys: String, CodingKey {
                case partner1FullName = "partner1_full_name"
                case partner2FullName = "partner2_full_name"
                case partner1Nickname = "partner1_nickname"
                case partner2Nickname = "partner2_nickname"
            }
        }
        let rows: [CoupleSettingsRow] = try await client
            .from("couple_settings")
            .select("settings")
            .eq("couple_id", value: tenantId)
            .limit(1)
            .execute()
            .value
        if let global = rows.first?.settings.global {
            let p1 = (global.partner1Nickname?.isEmpty == false ? global.partner1Nickname : global.partner1FullName) ?? ""
            let p2 = (global.partner2Nickname?.isEmpty == false ? global.partner2Nickname : global.partner2FullName) ?? ""
            let parts = [p1, p2].filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: " & ")
        }
        return nil
    }

    func inviteCollaborator(email: String, roleId: UUID, displayName: String?) async throws -> Collaborator {
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let userId = try await getUserId()
            let startTime = Date()

            // Create invitation (NOT collaborator) - pending users go in invitations table
            struct InvitationInsert: Encodable {
                let couple_id: UUID
                let email: String
                let role_id: UUID
                let invited_by: UUID
                let invited_at: Date
                let display_name: String?
                let status: String
            }

            let newInvitation = InvitationInsert(
                couple_id: tenantId,
                email: email,
                role_id: roleId,
                invited_by: userId,
                invited_at: Date(),
                display_name: displayName,
                status: "pending"
            )

            let created: Invitation = try await RepositoryNetwork.withRetry {
                try await client
                    .from("invitations")
                    .insert(newInvitation)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Invalidate invitations cache
            await RepositoryCache.shared.remove("invitations_\(tenantId.uuidString)")

            // Send invitation email via Resend
            do {
                // Get inviter's name and couple name
                let inviterEmail = try await UserContextProvider.shared.requireUserEmail()
                let inviterName = inviterEmail

                // Derive couple name from database settings (avoid MainActor access)
                let coupleName = try await fetchCoupleName(tenantId: tenantId, client: client) ?? "Your Wedding"

                // Get role name
                let roles = try await fetchRoles()
                let roleName = roles.first(where: { $0.id == roleId })?.roleName.displayName ?? "Collaborator"

                // Calculate expiry (7 days from now)
                let expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

                // Send email
                try await ResendEmailService.shared.sendInvitationEmail(
                    to: email,
                    inviterName: inviterName,
                    coupleName: coupleName,
                    role: roleName,
                    token: created.token,
                    expiresAt: expiresAt
                )

                logger.info("Sent invitation email to \(email) via Resend")
            } catch {
                // Log but don't fail - invitation was created successfully
                logger.warning("Failed to send invitation email to \(email): \(error.localizedDescription)")
                await SentryService.shared.captureError(error, context: [
                    "operation": "sendInvitationEmail",
                    "email": email
                ])
            }

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("inviteCollaborator", duration: duration)

            logger.info("Created invitation for \(email) in \(String(format: "%.2f", duration))s")
            AnalyticsService.trackNetwork(operation: "inviteCollaborator", outcome: .success, duration: duration)

            // Return a temporary collaborator representation for UI compatibility
            // The actual collaborator will be created when invitation is accepted
            return Collaborator(
                id: created.id,
                createdAt: created.createdAt,
                updatedAt: created.updatedAt,
                coupleId: created.coupleId,
                userId: UUID(), // Placeholder - will be set on acceptance
                roleId: created.roleId,
                invitedBy: created.invitedBy,
                invitedAt: created.invitedAt,
                acceptedAt: nil,
                status: .pending,
                email: created.email,
                displayName: created.displayName,
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
        do {
            let client = try getClient()
            let startTime = Date()

            logger.info("Accepting invitation via database function")

            // Call database function with SECURITY DEFINER to bypass RLS
            struct AcceptInvitationParams: Encodable {
                let p_invitation_id: UUID
            }

            let params = AcceptInvitationParams(p_invitation_id: id)

            // The function returns a single row with collaborator details
            struct AcceptInvitationResult: Decodable {
                let collaborator_id: UUID
                let couple_id: UUID
                let user_id: UUID
                let role_id: UUID
                let email: String
                let display_name: String?
                let status: String
            }

            let results: [AcceptInvitationResult] = try await RepositoryNetwork.withRetry {
                try await client
                    .rpc("accept_invitation", params: params)
                    .execute()
                    .value
            }

            guard let result = results.first else {
                logger.error("Database function returned no result")
                throw CollaborationError.updateFailed(underlying: NSError(
                    domain: "LiveCollaborationRepository",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Function returned no collaborator"]
                ))
            }

            // Construct Collaborator from result
            let collaborator = Collaborator(
                id: result.collaborator_id,
                createdAt: Date(),
                updatedAt: Date(),
                coupleId: result.couple_id,
                userId: result.user_id,
                roleId: result.role_id,
                invitedBy: result.user_id, // Self-invited (accepting user)
                invitedAt: Date(), // Use current date
                acceptedAt: Date(),
                status: .active,
                email: result.email,
                displayName: result.display_name,
                avatarUrl: nil,
                lastSeenAt: nil
            )

            // Invalidate caches
            await RepositoryCache.shared.remove("collaborators_\(result.couple_id.uuidString)")
            await RepositoryCache.shared.remove("invitations_\(result.couple_id.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("acceptInvitation", duration: duration)

            logger.info("Accepted invitation via database function in \(String(format: "%.2f", duration))s")

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
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            struct UpdatePayload: Encodable {
                let role_id: UUID
                let updated_at: Date
            }

            let updates = UpdatePayload(
                role_id: roleId,
                updated_at: Date()
            )

            let updated: Collaborator = try await RepositoryNetwork.withRetry {
                try await client
                    .from("collaborators")
                    .update(updates)
                    .eq("id", value: id)
                    .eq("couple_id", value: tenantId)
                    .select()
                    .single()
                    .execute()
                    .value
            }

            // Invalidate cache
            await RepositoryCache.shared.remove("collaborators_\(tenantId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("updateCollaboratorRole", duration: duration)

            logger.info("Updated collaborator role in \(String(format: "%.2f", duration))s")

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

            // Step 1: Fetch collaborators (no joins)
            struct CollaboratorRow: Decodable {
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

            let collaboratorRows: [CollaboratorRow] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("collaborators")
                    .select("id, couple_id, role_id, status, invited_by, invited_at, accepted_at, last_seen_at, email")
                    .eq("user_id", value: userId)
                    .order("invited_at", ascending: false)
                    .execute()
                    .value
            }

            logger.info("Fetched \(collaboratorRows.count) collaborator rows")

            // Step 2: Fetch couple profiles for all couple_ids
            let coupleIds = collaboratorRows.map { $0.couple_id }
            var coupleProfiles: [UUID: (partner1: String, partner2: String?, weddingDate: Date?)] = [:]

            if !coupleIds.isEmpty {
                struct CoupleProfileRow: Decodable {
                    let id: UUID
                    let partner1_name: String
                    let partner2_name: String?
                    let wedding_date: String?  // Supabase returns date as string

                    var parsedWeddingDate: Date? {
                        guard let dateString = wedding_date else { return nil }
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withFullDate]
                        return formatter.date(from: dateString)
                    }
                }

                let profiles: [CoupleProfileRow] = try await RepositoryNetwork.withRetry {
                    try await client
                        .from("couple_profiles")
                        .select("id, partner1_name, partner2_name, wedding_date")
                        .in("id", values: coupleIds)
                        .execute()
                        .value
                }

                for profile in profiles {
                    coupleProfiles[profile.id] = (profile.partner1_name, profile.partner2_name, profile.parsedWeddingDate)
                }

                logger.info("Fetched \(profiles.count) couple profiles")
            }

            // Step 3: Fetch roles for all role_ids
            let roleIds = collaboratorRows.map { $0.role_id }
            var roles: [UUID: String] = [:]

            if !roleIds.isEmpty {
                struct RoleRow: Decodable {
                    let id: UUID
                    let role_name: String
                }

                let roleRows: [RoleRow] = try await RepositoryNetwork.withRetry {
                    try await client
                        .from("collaboration_roles")
                        .select("id, role_name")
                        .in("id", values: roleIds)
                        .execute()
                        .value
                }

                for role in roleRows {
                    roles[role.id] = role.role_name
                }

                logger.info("Fetched \(roleRows.count) roles")
            }

            // Step 4: Identify couples where user is an owner
            // We need to filter out ALL collaborations for couples where user has owner role
            let ownerRoleId = roles.first(where: { $0.value == "owner" })?.key
            let couplesWhereUserIsOwner = Set(
                collaboratorRows
                    .filter { $0.role_id == ownerRoleId }
                    .map { $0.couple_id }
            )

            logger.info("User is owner of \(couplesWhereUserIsOwner.count) couples")

            // Step 5: Combine data into UserCollaboration objects
            // Filter out ALL collaborations for couples where user is an owner
            var collaborations = collaboratorRows.compactMap { row -> UserCollaboration? in
                guard let coupleProfile = coupleProfiles[row.couple_id],
                      let roleNameString = roles[row.role_id],
                      let roleName = RoleName(rawValue: roleNameString),
                      let status = CollaboratorStatus(rawValue: row.status) else {
                    logger.warning("Missing data for collaborator \(row.id.uuidString)")
                    return nil
                }

                // Skip ALL collaborations for couples where user is an owner
                // This handles cases where user might have multiple collaborator records
                if couplesWhereUserIsOwner.contains(row.couple_id) {
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
                    invitedBy: nil, // We'll skip inviter email for now
                    invitedAt: row.invited_at,
                    acceptedAt: row.accepted_at,
                    lastSeenAt: row.last_seen_at
                )
            }

            // Sort by wedding date (soonest first, nulls last)
            collaborations.sort { lhs, rhs in
                switch (lhs.weddingDate, rhs.weddingDate) {
                case (nil, nil):
                    return false
                case (nil, _):
                    return false
                case (_, nil):
                    return true
                case (let date1?, let date2?):
                    return date1 < date2
                }
            }

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("fetchUserCollaborations", duration: duration)

            // Cache the results (5 minute TTL)
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
        do {
            let client = try getClient()
            let userId = try await getUserId()
            let startTime = Date()

            logger.info("User leaving collaboration for couple: \(coupleId.uuidString)")

            // 1. Check if user is the last owner
            let owners: [Collaborator] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("collaborators")
                    .select("*, collaboration_roles!inner(role_name)")
                    .eq("couple_id", value: coupleId)
                    .eq("status", value: "active")
                    .eq("collaboration_roles.role_name", value: "owner")
                    .execute()
                    .value
            }

            let isUserOwner = owners.contains { $0.userId == userId }

            if isUserOwner && owners.count == 1 {
                logger.warning("Cannot leave - user is the last owner")
                throw CollaborationError.lastOwnerCannotLeave
            }

            // 2. Delete the collaborator record
            try await RepositoryNetwork.withRetry {
                try await client
                    .from("collaborators")
                    .delete()
                    .eq("couple_id", value: coupleId)
                    .eq("user_id", value: userId)
                    .execute()
            }

            // 3. Invalidate cache
            await RepositoryCache.shared.remove("collaborators_\(coupleId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("leaveCollaboration", duration: duration)

            logger.info("Left collaboration in \(String(format: "%.2f", duration))s")

            // 4. Track with Sentry
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
        do {
            let client = try getClient()
            let startTime = Date()

            logger.info("Declining invitation: \(id.uuidString)")

            // Update status to declined
            struct UpdatePayload: Encodable {
                let status: String
                let updated_at: Date
            }

            let updates = UpdatePayload(
                status: "declined",
                updated_at: Date()
            )

            try await RepositoryNetwork.withRetry {
                try await client
                    .from("collaborators")
                    .update(updates)
                    .eq("id", value: id)
                    .eq("status", value: "pending")
                    .execute()
            }

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("declineInvitation", duration: duration)

            logger.info("Declined invitation in \(String(format: "%.2f", duration))s")

            // Track with Sentry
            await SentryService.shared.trackAction(
                "invitation_declined",
                category: "collaboration",
                metadata: [
                    "invitation_id": id.uuidString
                ]
            )
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
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let startTime = Date()

            // Call database function
            struct PermissionParams: Encodable {
                let p_couple_id: UUID
                let p_permission: String
            }

            let params = PermissionParams(p_couple_id: tenantId, p_permission: permission)

            let result: [[String: Bool]] = try await RepositoryNetwork.withRetry {
                try await client
                    .rpc("user_has_permission", params: params)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("hasPermission", duration: duration)

            let hasPermission = result.first?["result"] ?? false
            logger.info("Permission check '\(permission)': \(hasPermission)")

            return hasPermission
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
        do {
            let client = try getClient()
            let tenantId = try await getTenantId()
            let userId = try await getUserId()
            let startTime = Date()

            // Query collaborator and join with role to get role name
            let collaborators: [Collaborator] = try await RepositoryNetwork.withRetry {
                try await client
                    .from("collaborators")
                    .select("*, collaboration_roles(*)")
                    .eq("couple_id", value: tenantId)
                    .eq("user_id", value: userId)
                    .eq("status", value: "active")
                    .limit(1)
                    .execute()
                    .value
            }

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("getCurrentUserRole", duration: duration)

            if let collaborator = collaborators.first {
                // Get the role from the roles we fetched earlier
                let roles = try await fetchRoles()
                if let role = roles.first(where: { $0.id == collaborator.roleId }) {
                    logger.info("Current user role: \(role.roleName.displayName)")
                    return role.roleName
                }
            }

            logger.info("No role found for current user")
            return nil
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

            // 1. Check if collaborator already exists (idempotency)
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

            // 2. Fetch owner role ID
            let roles = try await fetchRoles()
            guard let ownerRole = roles.first(where: { $0.roleName == .owner }) else {
                logger.error("Owner role not found in collaboration_roles table")
                throw CollaborationError.roleNotFound
            }

            logger.info("Found owner role: \(ownerRole.id.uuidString)")

            // 3. Call database function with SECURITY DEFINER to bypass RLS
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

            // 4. Invalidate cache
            await RepositoryCache.shared.remove("collaborators_\(coupleId.uuidString)")

            let duration = Date().timeIntervalSince(startTime)
            await PerformanceMonitor.shared.recordOperation("createOwnerCollaborator", duration: duration)

            logger.info("Created owner collaborator in \(String(format: "%.2f", duration))s")

            // 5. Track with Sentry
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
